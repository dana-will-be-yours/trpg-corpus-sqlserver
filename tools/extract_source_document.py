#!/usr/bin/env python3
"""
Extract TRPG source documents into JSON accepted by
stg.usp_Load_Source_Document_Json.

Supported input:
- .docx through WordprocessingML
- .html / .htm through the standard library HTML parser
- .txt / .md as plain text
"""

from __future__ import annotations

import argparse
import hashlib
import html.parser
import json
import re
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any
from xml.etree import ElementTree as ET
from zipfile import ZipFile


WORD_NS = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
DICE_RE = re.compile(r"(擲骰|\b\d+[dD]\d+@|^\[?\d+[dD]\d+[:：])")
SPEAKER_RE = re.compile(r"^([^:：]{1,40})[:：]\s*(.*)$")
CHAPTER_RE = re.compile(r"^(第[一二三四五六七八九十百〇零0-9]+[章回節幕]|楔子|前言|後記|尾聲|番外|序章|終章|【.*】)")


@dataclass
class TextUnit:
    paragraph_no: int
    line_no: int
    style_name: str | None
    text: str


class TextHTMLParser(html.parser.HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.parts: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag.lower() in {"br", "p", "div", "li", "tr", "h1", "h2", "h3", "h4", "blockquote"}:
            self.parts.append("\n")

    def handle_endtag(self, tag: str) -> None:
        if tag.lower() in {"p", "div", "li", "tr", "h1", "h2", "h3", "h4", "blockquote"}:
            self.parts.append("\n")

    def handle_data(self, data: str) -> None:
        self.parts.append(data)

    def text(self) -> str:
        return "".join(self.parts)


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def paragraph_text(paragraph: ET.Element) -> str:
    parts: list[str] = []
    for node in paragraph.iter():
        tag = node.tag.rsplit("}", 1)[-1]
        if tag == "t" and node.text:
            parts.append(node.text)
        elif tag == "tab":
            parts.append("\t")
        elif tag == "br":
            parts.append("\n")
    return "".join(parts)


def paragraph_style(paragraph: ET.Element) -> str | None:
    ppr = paragraph.find("w:pPr", WORD_NS)
    if ppr is None:
        return None
    style = ppr.find("w:pStyle", WORD_NS)
    if style is None:
        return None
    return style.attrib.get(f"{{{WORD_NS['w']}}}val")


def parse_docx(path: Path) -> tuple[list[TextUnit], dict[str, Any], str, int]:
    with ZipFile(path) as archive:
        root = ET.fromstring(archive.read("word/document.xml"))
        paragraphs = root.findall(".//w:p", WORD_NS)
        units: list[TextUnit] = []
        text_parts: list[str] = []
        for paragraph_no, paragraph in enumerate(paragraphs, 1):
            text = paragraph_text(paragraph).strip()
            style_name = paragraph_style(paragraph)
            if not text:
                continue
            text_parts.append(text)
            for line_no, line in enumerate(text.splitlines(), 1):
                clean = line.strip()
                if clean:
                    units.append(TextUnit(paragraph_no, line_no, style_name, clean))

        core = parse_docx_core(archive)
        table_count = len(root.findall(".//w:tbl", WORD_NS))
        return units, core, "\n".join(text_parts), table_count


def parse_docx_core(archive: ZipFile) -> dict[str, Any]:
    result: dict[str, Any] = {}
    try:
        root = ET.fromstring(archive.read("docProps/core.xml"))
    except Exception:
        return result

    for child in root:
        key = child.tag.rsplit("}", 1)[-1]
        result[key] = child.text
    return result


def parse_html(path: Path) -> tuple[list[TextUnit], dict[str, Any], str, int]:
    raw = path.read_text(encoding="utf-8", errors="replace")
    parser = TextHTMLParser()
    parser.feed(raw)
    text = parser.text()
    units = plain_text_units(text)
    return units, {}, text, 0


def parse_plain(path: Path) -> tuple[list[TextUnit], dict[str, Any], str, int]:
    text = path.read_text(encoding="utf-8", errors="replace")
    return plain_text_units(text), {}, text, 0


def plain_text_units(text: str) -> list[TextUnit]:
    units: list[TextUnit] = []
    paragraph_no = 0
    for block in re.split(r"\n\s*\n", text):
        paragraph_no += 1
        for line_no, line in enumerate(block.splitlines(), 1):
            clean = line.strip()
            if clean:
                units.append(TextUnit(paragraph_no, line_no, None, clean))
    return units


def infer_document_type(path: Path, units: list[TextUnit], explicit: str | None) -> str:
    if explicit and explicit != "auto":
        return explicit

    folder_text = str(path.parent)
    speaker_count = sum(1 for unit in units if SPEAKER_RE.match(unit.text))
    dice_count = sum(1 for unit in units if DICE_RE.search(unit.text))

    if "二創" in folder_text:
        if dice_count > 20:
            return "hybrid_creation"
        return "extended_creation"

    if path.suffix.lower() in {".html", ".htm"}:
        return "forum_html"

    if speaker_count > max(20, len(units) * 0.08):
        return "trpg_transcript"

    return "researcher_note"


def infer_title(path: Path, units: list[TextUnit]) -> str:
    for unit in units[:20]:
        text = unit.text.strip()
        if text and len(text) <= 80:
            return text
    return path.stem


def pc_labels_from_filename(path: Path) -> set[str]:
    labels: set[str] = set()
    match = re.search(r"PC(.+?)(?:[)）.]|$)", path.name)
    if not match:
        return labels
    for part in re.split(r"[&、,，/／\s]+", match.group(1)):
        clean = part.strip("-－_()（） ")
        if clean:
            labels.add(clean)
    return labels


def classify_block(unit: TextUnit, pc_labels: set[str]) -> dict[str, Any]:
    text = unit.text.strip()
    speaker_match = SPEAKER_RE.match(text)
    speaker_label = None
    speaker_type = None
    speaker_code = None
    function = None
    block_type = "prose"
    is_in_character = None
    review_status = "needs_review"

    if CHAPTER_RE.match(text):
        block_type = "chapter_heading"
        review_status = "reviewed"
    elif DICE_RE.search(text):
        block_type = "dice_roll" if "擲骰" in text or "@" in text else "dice_result"
        function = "rule_check"
        review_status = "needs_review"
    elif speaker_match:
        speaker_label = speaker_match.group(1).strip()
        body = speaker_match.group(2).strip()
        if speaker_label in {"GM", "主持", "黑大拿", "大拿"}:
            speaker_type = "GM"
            speaker_code = "TM-GM"
            function = "narration"
            is_in_character = "0"
            block_type = "narration"
        elif speaker_label in pc_labels:
            speaker_type = "PC"
            speaker_code = f"PC-{speaker_label}"
            function = "dialogue"
            is_in_character = "1"
            block_type = "utterance"
        else:
            speaker_type = "Unknown"
            function = "dialogue"
            is_in_character = None
            block_type = "utterance"

        if body.startswith("(") or body.startswith("（"):
            function = "action"
            block_type = "action_note"
    elif text.startswith("(") or text.startswith("（"):
        block_type = "action_note"
        function = "action"

    return {
        "paragraph_no": unit.paragraph_no,
        "line_no": unit.line_no,
        "style_name": unit.style_name,
        "block_type_candidate": block_type,
        "scene_code_candidate": None,
        "turn_no_text": None,
        "speaker_type_candidate": speaker_type,
        "speaker_code_candidate": speaker_code,
        "speaker_label_candidate": speaker_label,
        "utterance_function_candidate": function,
        "is_in_character_text": is_in_character,
        "text_raw": text,
        "text_clean": text,
        "extraction_note": None,
        "ai_annotation_json": json.dumps(
            {
                "extractor": "extract_source_document.py",
                "speaker_label_from_filename": sorted(pc_labels),
            },
            ensure_ascii=False,
        ),
        "review_status": review_status,
        "include_in_analysis_text": "1",
    }


def build_document_json(path: Path, args: argparse.Namespace) -> dict[str, Any]:
    suffix = path.suffix.lower()
    if suffix == ".docx":
        units, core, extracted_text, table_count = parse_docx(path)
        mime_type = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    elif suffix in {".html", ".htm"}:
        units, core, extracted_text, table_count = parse_html(path)
        mime_type = "text/html"
    elif suffix in {".txt", ".md"}:
        units, core, extracted_text, table_count = parse_plain(path)
        mime_type = "text/plain"
    else:
        raise ValueError(f"Unsupported file extension: {path.suffix}")

    pc_labels = pc_labels_from_filename(path)
    pc_labels.update(args.pc_label or [])
    source_type = infer_document_type(path, units, args.source_document_type)
    blocks = []
    for index, unit in enumerate(units, 1):
        row = classify_block(unit, pc_labels)
        row["source_block_no"] = index
        if row["turn_no_text"] is None and row["block_type_candidate"] in {
            "utterance",
            "action_note",
            "dice_roll",
            "dice_result",
            "narration",
        }:
            row["turn_no_text"] = str(index)
        blocks.append(row)

    speaker_line_count = sum(1 for unit in units if SPEAKER_RE.match(unit.text))
    dice_line_count = sum(1 for unit in units if DICE_RE.search(unit.text))
    file_hash = sha256_file(path)
    code_base = re.sub(r"[^0-9A-Za-z_-]+", "_", path.stem).strip("_")
    if not code_base:
        code_base = file_hash[:12]
    source_document_code = args.source_document_code or f"SRC-{code_base}-{file_hash[:8]}"

    source_document = {
        "source_document_code": source_document_code[:100],
        "project_code": args.project_code,
        "team_code": args.team_code,
        "session_code": args.session_code,
        "source_document_type": source_type,
        "source_title": args.source_title or infer_title(path, units),
        "source_author_label": core.get("creator"),
        "source_url": args.source_url,
        "source_folder_label": path.parent.name,
        "file_name": path.name,
        "file_extension": suffix.lstrip("."),
        "mime_type": mime_type,
        "file_size_bytes": path.stat().st_size,
        "file_sha256": file_hash,
        "storage_mode": "text_only",
        "storage_uri": None,
        "extracted_text_raw": extracted_text,
        "parser_name": "tools/extract_source_document.py",
        "parser_version": "1.0.0",
        "docx_core_title": core.get("title"),
        "docx_core_creator": core.get("creator"),
        "docx_core_created_at": normalize_datetime(core.get("created")),
        "docx_core_modified_at": normalize_datetime(core.get("modified")),
        "paragraph_count": max((unit.paragraph_no for unit in units), default=0),
        "text_unit_count": len(units),
        "speaker_line_count": speaker_line_count,
        "dice_line_count": dice_line_count,
        "table_count": table_count,
    }

    output = {
        "metadata": {
            "export_format": "trpg_source_document_json_v1",
            "exported_at": datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
        },
        "source_document": source_document,
        "source_text_blocks": blocks,
    }

    if source_type in {"extended_creation", "hybrid_creation"}:
        output["extended_creation_import"] = {
            "project_code": args.project_code,
            "team_code": args.team_code,
            "session_code": args.session_code,
            "scene_code": None,
            "creation_code": f"ECT-{file_hash[:12]}",
            "creation_no_text": "1",
            "creation_title": source_document["source_title"],
            "creation_type": "novel_excerpt" if source_type == "extended_creation" else "campaign_summary",
            "creation_stage": "draft",
            "authoring_mode": "unknown",
            "author_member_code": None,
            "source_material_note": f"Imported from {path.name}",
            "creation_text_raw": extracted_text,
            "creation_text_clean": extracted_text,
            "creation_summary": None,
            "word_count_text": str(len(re.sub(r"\s+", "", extracted_text))),
            "version_no_text": "1",
            "is_final_version_text": "0",
            "source_type": "trpg_derived",
            "extraction_method": "imported",
            "review_status": "draft",
            "include_in_analysis_text": "1",
        }

    return output


def normalize_datetime(value: str | None) -> str | None:
    if not value:
        return None
    return value.replace("Z", "")


def write_output(data: dict[str, Any], out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("inputs", nargs="+", type=Path)
    parser.add_argument("--out-dir", type=Path, default=Path("exports/source_documents"))
    parser.add_argument("--project-code", default="DAGO")
    parser.add_argument("--team-code", default="DAGO-T01")
    parser.add_argument("--session-code", default=None)
    parser.add_argument(
        "--source-document-type",
        choices=[
            "auto",
            "trpg_transcript",
            "extended_creation",
            "hybrid_creation",
            "forum_html",
            "da_go_playlog",
            "researcher_note",
            "other",
        ],
        default="auto",
    )
    parser.add_argument("--source-title", default=None)
    parser.add_argument("--source-url", default=None)
    parser.add_argument("--source-document-code", default=None)
    parser.add_argument("--pc-label", action="append", default=[])
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    for path in args.inputs:
        resolved = path.resolve()
        data = build_document_json(resolved, args)
        code = data["source_document"]["source_document_code"]
        out_path = args.out_dir / f"{code}.json"
        write_output(data, out_path)
        print(out_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
