(() => {
  'use strict';

  const schema = window.TRPG_TRANSCRIPT_SCHEMA;
  const allowedSpeakerTypes = new Set(schema.speakerTypes);
  const allowedFunctions = new Set(schema.utteranceFunctions);
  const allowedReviewStatuses = new Set(schema.reviewStatuses);

  let rows = [];

  const el = id => document.getElementById(id);

  function getDefaults() {
    return {
      batch_code: el('batchCode').value.trim() || 'BATCH_TRPG_UTTERANCE_001',
      project_code: el('projectCode').value.trim() || 'TRPG_COCREATION',
      team_code: el('teamCode').value.trim() || 'TEAM01',
      session_code: el('sessionCode').value.trim() || 'S01',
      scene_code: el('sceneCode').value.trim() || null,
      imported_by: el('importedBy').value.trim() || 'researcher'
    };
  }

  function normalizeTimecode(value) {
    if (!value) return null;
    const parts = String(value).trim().split(':');
    if (parts.length === 2) return `00:${parts[0].padStart(2, '0')}:${parts[1].padStart(2, '0')}`;
    if (parts.length === 3) return `${parts[0].padStart(2, '0')}:${parts[1].padStart(2, '0')}:${parts[2].padStart(2, '0')}`;
    return String(value).trim();
  }

  function inferSpeakerType(label) {
    const raw = String(label || '').trim();
    const upper = raw.toUpperCase();
    if (upper === 'GM' || raw.includes('主持') || raw.includes('守密人') || raw.includes('導入')) return 'GM';
    if (upper === 'PL' || raw.includes('玩家') || raw.includes('PL')) return 'PL';
    if (upper.includes('NPC') || raw.includes('村民') || raw.includes('店主')) return 'NPC';
    if (raw.includes('觀察')) return 'Observer';
    if (raw.includes('研究')) return 'Researcher';
    return 'PC';
  }

  function inferUtteranceFunction(speakerType, text) {
    const body = String(text || '');
    if (speakerType === 'GM') return 'narration';
    if (/擲骰|骰|檢定|規則|技能|成功|失敗|難度|DC|判定/i.test(body)) return 'rule_check';
    if (/決定|我選|我們要|同意|不同意|就這樣|採用|投票/.test(body)) return 'decision';
    if (/但是|可是|我不同意|衝突|爭議|不對/.test(body)) return 'conflict';
    if (/為什麼|嗎|是不是|可不可以|如何|哪裡|誰|何時|？|\?$/.test(body)) return 'question';
    if (/我想|我要|我去|嘗試|檢查|攻擊|移動|打開|拿起/.test(body)) return 'action';
    return 'dialogue';
  }

  function baseRow(index, defaults, overrides = {}) {
    const turnNo = index + 1;
    return {
      source_row_no: turnNo,
      project_code: defaults.project_code,
      team_code: defaults.team_code,
      session_code: defaults.session_code,
      scene_code: defaults.scene_code,
      turn_no_text: String(turnNo),
      sub_turn_no_text: null,
      utterance_code: `${defaults.session_code}_T${String(turnNo).padStart(4, '0')}`,
      speaker_type: 'PC',
      speaker_code: '',
      speaker_label_raw: '',
      utterance_function: 'dialogue',
      is_in_character_text: '1',
      is_gm_narration_text: '0',
      is_rule_related_text: '0',
      is_decision_related_text: '0',
      is_knowledge_related_text: '0',
      start_timecode: null,
      end_timecode: null,
      duration_sec_text: null,
      utterance_text_raw: '',
      utterance_text_clean: '',
      utterance_text_verified: '',
      language_code: 'zh-TW',
      emotion_label: 'neutral',
      interaction_target_type: '',
      interaction_target_code: null,
      related_rule_code: null,
      related_world_setting_code: null,
      related_item_code: null,
      ai_summary: null,
      ai_annotation_json: null,
      human_annotation_note: null,
      transcription_confidence_text: null,
      review_status: 'draft',
      include_in_analysis_text: '1',
      exclusion_reason: null,
      validation_error: null,
      ...overrides
    };
  }

  function parseTranscriptText(text, defaults) {
    const lines = String(text || '').split(/\r?\n/).map(x => x.trim()).filter(Boolean);
    return lines.map((line, index) => {
      let startTimecode = null;
      let speakerRaw = 'UNKNOWN';
      let body = line;

      const withTime = line.match(/^\[?(\d{1,2}:\d{2}(?::\d{2})?)\]?\s*([^:：]+)[:：]\s*(.+)$/);
      const noTime = line.match(/^([^:：]+)[:：]\s*(.+)$/);

      if (withTime) {
        startTimecode = normalizeTimecode(withTime[1]);
        speakerRaw = withTime[2].trim();
        body = withTime[3].trim();
      } else if (noTime) {
        speakerRaw = noTime[1].trim();
        body = noTime[2].trim();
      }

      const speakerType = inferSpeakerType(speakerRaw);
      const utteranceFunction = inferUtteranceFunction(speakerType, body);
      const isInCharacter = speakerType === 'PC' || speakerType === 'NPC' ? '1' : '0';

      return baseRow(index, defaults, {
        speaker_type: speakerType,
        speaker_code: speakerRaw,
        speaker_label_raw: speakerRaw,
        utterance_function: utteranceFunction,
        is_in_character_text: isInCharacter,
        is_gm_narration_text: speakerType === 'GM' && utteranceFunction === 'narration' ? '1' : '0',
        is_rule_related_text: utteranceFunction === 'rule_check' ? '1' : '0',
        is_decision_related_text: utteranceFunction === 'decision' ? '1' : '0',
        is_knowledge_related_text: ['question', 'clarification', 'summary'].includes(utteranceFunction) ? '1' : '0',
        start_timecode: startTimecode,
        utterance_text_raw: body,
        utterance_text_clean: body,
        utterance_text_verified: '',
        review_status: 'draft'
      });
    });
  }

  function parseCsv(text, defaults) {
    const records = csvToArrays(text);
    if (records.length < 2) return [];
    const header = records[0].map(x => x.trim());
    return records.slice(1).filter(r => r.some(v => String(v || '').trim())).map((record, index) => {
      const obj = baseRow(index, defaults);
      header.forEach((name, i) => {
        if (name in obj) obj[name] = record[i] === '' ? null : record[i];
      });
      obj.source_row_no = Number(obj.source_row_no || index + 1);
      return obj;
    });
  }

  function csvToArrays(text) {
    const rowsOut = [];
    let row = [];
    let cell = '';
    let inQuotes = false;
    const s = String(text || '');
    for (let i = 0; i < s.length; i++) {
      const ch = s[i];
      const next = s[i + 1];
      if (ch === '"' && inQuotes && next === '"') {
        cell += '"';
        i++;
      } else if (ch === '"') {
        inQuotes = !inQuotes;
      } else if (ch === ',' && !inQuotes) {
        row.push(cell);
        cell = '';
      } else if ((ch === '\n' || ch === '\r') && !inQuotes) {
        if (ch === '\r' && next === '\n') i++;
        row.push(cell);
        rowsOut.push(row);
        row = [];
        cell = '';
      } else {
        cell += ch;
      }
    }
    row.push(cell);
    rowsOut.push(row);
    return rowsOut;
  }

  function parseJson(text, defaults) {
    const data = JSON.parse(text);
    const list = Array.isArray(data) ? data : Array.isArray(data.utterances) ? data.utterances : [];
    return list.map((item, index) => ({ ...baseRow(index, defaults), ...item, source_row_no: Number(item.source_row_no || index + 1) }));
  }

  function validateRows(data) {
    const seenTurns = new Set();
    const seenCodes = new Set();
    return data.map(row => {
      const errors = [];
      const session = String(row.session_code || '').trim();
      const turn = String(row.turn_no_text || '').trim();
      const code = String(row.utterance_code || '').trim();

      if (!String(row.project_code || '').trim()) errors.push('project_code 不可空白');
      if (!String(row.team_code || '').trim()) errors.push('team_code 不可空白');
      if (!session) errors.push('session_code 不可空白');
      if (!/^[1-9]\d*$/.test(turn)) errors.push('turn_no_text 必須為正整數');
      if (!String(row.utterance_text_raw || '').trim()) errors.push('utterance_text_raw 不可空白');
      if (!allowedSpeakerTypes.has(row.speaker_type)) errors.push('speaker_type 不合法');
      if (!allowedFunctions.has(row.utterance_function)) errors.push('utterance_function 不合法');
      if (!allowedReviewStatuses.has(row.review_status || 'draft')) errors.push('review_status 不合法');

      const turnKey = `${session}::${turn}`;
      if (seenTurns.has(turnKey)) errors.push('同一 session_code 下 turn_no 重複');
      seenTurns.add(turnKey);

      const codeKey = `${session}::${code}`;
      if (!code) errors.push('utterance_code 不可空白');
      if (code && seenCodes.has(codeKey)) errors.push('同一 session_code 下 utterance_code 重複');
      seenCodes.add(codeKey);

      if ((row.speaker_type === 'PC' || row.speaker_type === 'NPC') && row.is_in_character_text !== '1') {
        errors.push('PC/NPC 必須 is_in_character_text = 1');
      }
      if (['GM', 'PL', 'Observer', 'Researcher'].includes(row.speaker_type) && row.is_in_character_text !== '0') {
        errors.push('GM/PL/Observer/Researcher 必須 is_in_character_text = 0');
      }
      if (row.is_gm_narration_text === '1' && !(row.speaker_type === 'GM' && row.utterance_function === 'narration')) {
        errors.push('GM旁白必須 speaker_type=GM 且 function=narration');
      }
      if (row.is_rule_related_text === '1' && row.utterance_function !== 'rule_check' && !String(row.related_rule_code || '').trim()) {
        errors.push('規則相關列需 function=rule_check 或填 related_rule_code');
      }
      if (row.is_decision_related_text === '1' && !['decision', 'negotiation', 'clarification'].includes(row.utterance_function)) {
        errors.push('決策相關列需 function=decision/negotiation/clarification');
      }
      if (row.include_in_analysis_text === '0' && !String(row.exclusion_reason || '').trim()) {
        errors.push('include_in_analysis_text=0 時必須填 exclusion_reason');
      }
      if (String(row.transcription_confidence_text || '').trim()) {
        const n = Number(row.transcription_confidence_text);
        if (!Number.isFinite(n) || n < 0 || n > 1) errors.push('transcription_confidence_text 必須介於 0 到 1');
      }

      return { ...row, validation_error: errors.length ? errors.join('；') : null };
    });
  }

  function render() {
    const tbody = document.querySelector('#utteranceTable tbody');
    tbody.innerHTML = '';
    rows.forEach((row, index) => {
      const tr = document.createElement('tr');
      tr.className = row.validation_error ? 'row-error' : 'row-ok';
      tr.appendChild(staticCell(String(row.source_row_no || index + 1), 'cell-small'));
      tr.appendChild(inputCell(index, 'turn_no_text', 'cell-small'));
      tr.appendChild(inputCell(index, 'scene_code', 'cell-medium'));
      tr.appendChild(selectCell(index, 'speaker_type', schema.speakerTypes, 'cell-medium'));
      tr.appendChild(inputCell(index, 'speaker_code', 'cell-medium'));
      tr.appendChild(selectCell(index, 'utterance_function', schema.utteranceFunctions, 'cell-medium'));
      tr.appendChild(selectCell(index, 'is_in_character_text', ['0', '1'], 'cell-small'));
      tr.appendChild(selectCell(index, 'is_gm_narration_text', ['0', '1'], 'cell-small'));
      tr.appendChild(selectCell(index, 'is_rule_related_text', ['0', '1'], 'cell-small'));
      tr.appendChild(selectCell(index, 'is_decision_related_text', ['0', '1'], 'cell-small'));
      tr.appendChild(selectCell(index, 'is_knowledge_related_text', ['0', '1'], 'cell-small'));
      tr.appendChild(inputCell(index, 'start_timecode', 'cell-medium'));
      tr.appendChild(textareaCell(index, 'utterance_text_raw'));
      tr.appendChild(textareaCell(index, 'utterance_text_clean'));
      tr.appendChild(textareaCell(index, 'utterance_text_verified'));
      tr.appendChild(selectCell(index, 'review_status', schema.reviewStatuses, 'cell-medium'));
      tr.appendChild(selectCell(index, 'include_in_analysis_text', ['0', '1'], 'cell-small'));
      tr.appendChild(staticCell(row.validation_error || '', 'error-cell'));
      tr.appendChild(actionCell(index));
      tbody.appendChild(tr);
    });
    updateStatus();
  }

  function staticCell(text, className) {
    const td = document.createElement('td');
    td.className = className || '';
    td.textContent = text;
    return td;
  }

  function inputCell(index, key, className) {
    const td = document.createElement('td');
    td.className = className || '';
    const input = document.createElement('input');
    input.className = 'table-input';
    input.value = rows[index][key] || '';
    input.addEventListener('input', () => rows[index][key] = input.value || null);
    td.appendChild(input);
    return td;
  }

  function textareaCell(index, key) {
    const td = document.createElement('td');
    td.className = 'cell-text';
    const textarea = document.createElement('textarea');
    textarea.className = 'table-textarea';
    textarea.value = rows[index][key] || '';
    textarea.addEventListener('input', () => rows[index][key] = textarea.value || null);
    td.appendChild(textarea);
    return td;
  }

  function selectCell(index, key, options, className) {
    const td = document.createElement('td');
    td.className = className || '';
    const select = document.createElement('select');
    select.className = 'table-select';
    options.forEach(opt => {
      const o = document.createElement('option');
      o.value = opt;
      o.textContent = opt;
      select.appendChild(o);
    });
    select.value = rows[index][key] ?? options[0];
    select.addEventListener('change', () => rows[index][key] = select.value);
    td.appendChild(select);
    return td;
  }

  function actionCell(index) {
    const td = document.createElement('td');
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'delete-btn';
    btn.textContent = '刪除';
    btn.addEventListener('click', () => {
      rows.splice(index, 1);
      renumberRows();
      rows = validateRows(rows);
      render();
    });
    td.appendChild(btn);
    return td;
  }

  function renumberRows() {
    const defaults = getDefaults();
    rows.forEach((row, index) => {
      const n = index + 1;
      row.source_row_no = n;
      if (!row.turn_no_text) row.turn_no_text = String(n);
      if (!row.utterance_code) row.utterance_code = `${defaults.session_code}_T${String(n).padStart(4, '0')}`;
    });
  }

  function updateStatus() {
    const bar = el('statusBar');
    const total = rows.length;
    const errors = rows.filter(r => r.validation_error).length;
    if (!total) {
      bar.className = 'status';
      bar.textContent = '尚未載入資料。';
    } else if (errors) {
      bar.className = 'status bad';
      bar.textContent = `共 ${total} 列，${errors} 列有錯誤。請修正後再匯出給 SSMS 匯入。`;
    } else {
      bar.className = 'status ok';
      bar.textContent = `共 ${total} 列，前端檢查通過。`;
    }
  }

  function toExportRows() {
    rows = validateRows(rows);
    render();
    return rows.map(row => {
      const out = {};
      schema.stgColumns.forEach(col => out[col] = row[col] ?? null);
      return out;
    });
  }

  function exportJson() {
    const defaults = getDefaults();
    const checked = toExportRows();
    const payload = {
      import_batch: {
        batch_code: defaults.batch_code,
        project_code: defaults.project_code,
        source_table_name: 'stg.Utterance_Import',
        source_file_name: `${defaults.batch_code}.json`,
        source_file_type: 'json',
        import_purpose: 'TRPG逐字稿審閱後匯入',
        imported_by: defaults.imported_by
      },
      utterances: checked
    };
    downloadText(`${defaults.batch_code}.json`, JSON.stringify(payload, null, 2), 'application/json;charset=utf-8');
  }

  function exportCsv() {
    const defaults = getDefaults();
    const checked = toExportRows();
    const header = schema.stgColumns;
    const lines = [header.join(',')];
    checked.forEach(row => lines.push(header.map(col => csvEscape(row[col])).join(',')));
    downloadText(`${defaults.batch_code}.csv`, '\uFEFF' + lines.join('\r\n'), 'text/csv;charset=utf-8');
  }

  function csvEscape(value) {
    if (value === null || value === undefined) return '';
    const s = String(value);
    if (/[",\r\n]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
    return s;
  }

  function downloadText(filename, content, mimeType) {
    const blob = new Blob([content], { type: mimeType });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  }

  function loadSample() {
    el('rawText').value = [
      '[00:01:03] GM：你們來到荒廢的祠堂，門上貼著褪色的符紙。',
      '[00:01:12] 陽月：我想檢查門上的符咒。',
      '[00:01:20] 楚服：我在旁邊戒備，看有沒有人跟蹤。',
      '[00:01:31] GM：請陽月進行一次民俗知識檢定。',
      '[00:01:40] 陽月：我擲骰，成功。',
      '[00:01:52] 花瓊瑤：我們先不要進去，先記下符紙樣式。'
    ].join('\n');
  }

  async function handleFile(file) {
    const text = await file.text();
    const defaults = getDefaults();
    const name = file.name.toLowerCase();
    if (name.endsWith('.json')) rows = parseJson(text, defaults);
    else if (name.endsWith('.csv')) rows = parseCsv(text, defaults);
    else rows = parseTranscriptText(text, defaults);
    rows = validateRows(rows);
    render();
  }

  function bind() {
    el('loadSampleBtn').addEventListener('click', loadSample);
    el('parseBtn').addEventListener('click', () => {
      rows = parseTranscriptText(el('rawText').value, getDefaults());
      rows = validateRows(rows);
      render();
    });
    el('validateBtn').addEventListener('click', () => {
      rows = validateRows(rows);
      render();
    });
    el('addRowBtn').addEventListener('click', () => {
      rows.push(baseRow(rows.length, getDefaults()));
      rows = validateRows(rows);
      render();
    });
    el('clearBtn').addEventListener('click', () => {
      rows = [];
      el('rawText').value = '';
      render();
    });
    el('exportJsonBtn').addEventListener('click', exportJson);
    el('exportCsvBtn').addEventListener('click', exportCsv);
    el('fileInput').addEventListener('change', event => {
      const file = event.target.files && event.target.files[0];
      if (file) handleFile(file).catch(err => {
        const bar = el('statusBar');
        bar.className = 'status bad';
        bar.textContent = `讀檔失敗：${err.message}`;
      });
    });
  }

  bind();
  render();
})();
