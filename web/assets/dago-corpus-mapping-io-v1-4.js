(()=>{'use strict';
const core=window.DagoCorpusV14Core;
if(!core)throw new Error('DagoCorpusV14Core 尚未載入');
const VERSION=core.VERSION;
const MAP_FIELDS=core.MAP_FIELDS;
const enc=new TextEncoder();
const dec=new TextDecoder('utf-8');
function $(id){return document.getElementById(id)}
function stat(msg){const s=$('status');if(s)s.textContent=msg}
function api(){if(!window.DagoCorpusWorkspaceV14)throw new Error('DagoCorpusWorkspaceV14 尚未載入');return window.DagoCorpusWorkspaceV14}
function ops(){if(!window.DagoCorpusWorkspaceOpsV14)throw new Error('DagoCorpusWorkspaceOpsV14 尚未載入');return window.DagoCorpusWorkspaceOpsV14}
function formMeta(){const f=$('sourceForm');return f?Object.fromEntries(new FormData(f).entries()):{}}
function currentWorkspaceId(){try{return api().getCurrentWorkspaceId()||''}catch(e){return''}}
async function ensureWorkspaceForImport(){let id=currentWorkspaceId();if(id)return id;const m=formMeta();const ws=await api().createWorkspace({project_code:m.project_code||'DAGO',team_code:m.team_code||'DAGO-T01',session_code:m.session_code||'MAPPING-IMPORT',batch_code:m.batch_code||'MAPPING_IMPORT',source_file_name:m.source_file_name||'speaker_mapping_import',source_url:m.source_url||'',total_row_count:0,last_page_size:Number($('pageSize')?.value||100)||100});return ws.workspace_id}
function workspaceId(){const id=currentWorkspaceId();if(!id)throw new Error('尚未建立 v1.4 workspace，請先解析或匯入逐字稿。');return id}
function filename(base,ext){return core.makeTimestampedFilename(base,ext)}
function downloadBlob(name,blob){return core.downloadBlob(name,blob)}
function targetForType(type){return core.targetTableForSpeakerType(type)}
function stripBom(s){return String(s||'').replace(/^\uFEFF/,'')}
function templateRows(){return[{raw_speaker_label:'',speaker_type:'PC',speaker_code:'',target_table:'Player_Character',note:'template row; fill raw_speaker_label and speaker_code before import'}]}
function normalizeOne(row,index=0){const raw=String(row?.raw_speaker_label??row?.speaker_label_raw??row?.raw??'').trim();const type=String(row?.speaker_type??'').trim();const code=String(row?.speaker_code??'').trim();const target=String(row?.target_table??'').trim()||targetForType(type);const note=String(row?.note??'').trim();return{raw_speaker_label:raw,speaker_type:type,speaker_code:code,target_table:target,note}}
function normalizeMappingRows(rows=[]){return rows.map(normalizeOne).filter(r=>r.raw_speaker_label||r.speaker_type||r.speaker_code||r.target_table||r.note)}
function normalizeImportRows(rows=[]){return rows.map(normalizeOne).filter(r=>r.raw_speaker_label||r.speaker_code)}
function exportRows(rows=[]){const normalized=normalizeMappingRows(rows);return normalized.length?normalized.map(r=>core.objectFromFields(MAP_FIELDS,r,'')):templateRows().map(r=>core.objectFromFields(MAP_FIELDS,r,''))}
function validateMappingRows(rows=[]){const errors=[],warnings=[],seen=new Set();rows.forEach((r,i)=>{const no=i+1;if(!r.raw_speaker_label)errors.push(`mapping row ${no}: raw_speaker_label 必填`);if(!r.speaker_type)errors.push(`mapping row ${no}: speaker_type 必填`);else if(!core.SPEAKER_TYPES.includes(r.speaker_type))errors.push(`mapping row ${no}: speaker_type 非法：${r.speaker_type}`);if(!r.speaker_code)errors.push(`mapping row ${no}: speaker_code 必填`);const expected=targetForType(r.speaker_type);if(expected&&!r.target_table)warnings.push(`mapping row ${no}: target_table 空白，將補為 ${expected}`);if(expected&&r.target_table&&r.target_table!==expected)warnings.push(`mapping row ${no}: target_table 應為 ${expected}，目前為 ${r.target_table}`);const key=r.raw_speaker_label;if(key){if(seen.has(key))warnings.push(`mapping row ${no}: raw_speaker_label 重複：${key}`);seen.add(key)}});return{version:VERSION,checked_at:new Date().toISOString(),row_count:rows.length,error_count:errors.length,warning_count:warnings.length,errors,warnings}}
async function getMapsOptional(){const id=currentWorkspaceId();if(!id)return{workspace_id:'',rows:[],used_template:true};const rows=await api().getAllMaps(id);return{workspace_id:id,rows,used_template:!rows.length}}
async function getMaps(){const id=workspaceId();return await api().getAllMaps(id)}
function payload(maps,workspace_id='',used_template=false){const rows=exportRows(maps);const summary=validateMappingRows(rows);return{metadata:{version:VERSION,export_type:'Speaker_Mapping',workspace_id,exported_at:new Date().toISOString(),used_template:!!used_template,validation_summary:summary},Speaker_Mapping:rows}}
function serializeMappingJson(maps,workspace_id=''){return JSON.stringify(payload(maps,workspace_id,!normalizeMappingRows(maps).length),null,2)}
async function downloadMappingJson(){const ctx=await getMapsOptional();const p=payload(ctx.rows,ctx.workspace_id,ctx.used_template);downloadBlob(filename(ctx.used_template?'speaker_mapping_v1_4_template':'speaker_mapping_v1_4','json'),new Blob([JSON.stringify(p,null,2)],{type:'application/json;charset=utf-8'}));stat(ctx.used_template?`Speaker Mapping JSON 範本匯出完成：${p.Speaker_Mapping.length} 筆。`:`Speaker Mapping JSON 匯出完成：${p.Speaker_Mapping.length} 筆。`);return p}
function tsvEscape(v){return core.csvEscape(v)}
function serializeMappingTsv(rows=[]){const normalized=exportRows(rows);return[MAP_FIELDS.join('\t'),...normalized.map(r=>MAP_FIELDS.map(f=>tsvEscape(r[f])).join('\t'))].join('\r\n')}
async function downloadMappingTsv(){const ctx=await getMapsOptional();const rows=exportRows(ctx.rows);downloadBlob(filename(ctx.used_template?'speaker_mapping_v1_4_template':'speaker_mapping_v1_4','tsv'),core.utf16leBlob(serializeMappingTsv(rows)));stat(ctx.used_template?`Speaker Mapping UTF-16LE TSV 範本匯出完成：${rows.length} 筆。`:`Speaker Mapping UTF-16LE TSV 匯出完成：${rows.length} 筆。`);return rows}
function metadataRows(workspace_id,rows,summary,used_template=false){return[{key:'version',value:VERSION},{key:'export_type',value:'Speaker_Mapping'},{key:'workspace_id',value:workspace_id},{key:'exported_at',value:new Date().toISOString()},{key:'used_template',value:String(!!used_template)},{key:'row_count',value:rows.length},{key:'error_count',value:summary.error_count},{key:'warning_count',value:summary.warning_count}]}
function workbookXml(sheetNames){const tags=sheetNames.map((n,i)=>`<sheet name="${core.xmlEscape(n)}" sheetId="${i+1}" r:id="rId${i+1}"/>`).join('');return`<?xml version="1.0" encoding="UTF-8"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>${tags}</sheets></workbook>`}
function workbookRels(sheetNames){const rels=sheetNames.map((_,i)=>`<Relationship Id="rId${i+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${i+1}.xml"/>`).join('');return`<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">${rels}</Relationships>`}
function contentTypes(sheetNames){const overrides=sheetNames.map((_,i)=>`<Override PartName="/xl/worksheets/sheet${i+1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>`).join('');return`<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>${overrides}</Types>`}
function buildMappingXlsxBlob(rows,metaRows){if(!window.DagoCorpusXlsxCoreV14)throw new Error('dago-corpus-xlsx-core-v1-4.js 尚未載入，無法匯出 Mapping XLSX。');const xlsx=window.DagoCorpusXlsxCoreV14;const sheetNames=['Speaker_Mapping','Metadata'];const files=[{name:'[Content_Types].xml',text:contentTypes(sheetNames)},{name:'_rels/.rels',text:'<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>'},{name:'xl/_rels/workbook.xml.rels',text:workbookRels(sheetNames)},{name:'xl/workbook.xml',text:workbookXml(sheetNames)},{name:'xl/worksheets/sheet1.xml',text:xlsx.sheetXml(MAP_FIELDS,rows)},{name:'xl/worksheets/sheet2.xml',text:xlsx.sheetXml(['key','value'],metaRows)}];return xlsx.zipStore(files)}
async function downloadMappingXlsx(){const ctx=await getMapsOptional();const rows=exportRows(ctx.rows);const summary=validateMappingRows(rows);const blob=buildMappingXlsxBlob(rows,metadataRows(ctx.workspace_id,rows,summary,ctx.used_template));downloadBlob(filename(ctx.used_template?'speaker_mapping_v1_4_template':'speaker_mapping_v1_4','xlsx'),blob);stat(ctx.used_template?`Speaker Mapping XLSX 範本匯出完成：${rows.length} 筆。`:`Speaker Mapping XLSX 匯出完成：${rows.length} 筆。`);return rows}
function extractMappingArray(obj){if(Array.isArray(obj))return obj;const keys=['Speaker_Mapping','speaker_mapping','Code_Mapping','code_mapping','maps','Mappings','mapping_rows'];for(const k of keys){if(Array.isArray(obj?.[k]))return obj[k]}return[]}
function parseMappingJson(text){let obj;try{obj=JSON.parse(stripBom(text))}catch(e){throw new Error('Mapping JSON 解析失敗：'+e.message)}const rows=extractMappingArray(obj);if(!Array.isArray(rows)||!rows.length)throw new Error('JSON 中找不到 Speaker_Mapping 陣列。');const parsed=normalizeImportRows(rows);if(!parsed.length)throw new Error('JSON 中沒有可匯入的 Speaker Mapping 資料列。');return parsed}
function checkMappingJsonRoundTrip(rows=[]){const normalized=normalizeImportRows(rows);const json=serializeMappingJson(normalized,'SELFTEST');const parsed=parseMappingJson(json);const a=JSON.stringify(exportRows(normalized));const b=JSON.stringify(exportRows(parsed));if(a!==b)throw new Error('Mapping JSON roundtrip 不一致。');return{ok:true,row_count:parsed.length}}
function parseTsvLine(line){const out=[];let cur='',q=false;for(let i=0;i<line.length;i++){const ch=line[i];if(ch==='"'){if(q&&line[i+1]==='"'){cur+='"';i++;}else q=!q;continue}if(ch==='\t'&&!q){out.push(cur);cur='';continue}cur+=ch}out.push(cur);return out}
function parseMappingTsv(text){const lines=stripBom(text).split(/\r?\n/).filter(x=>x.trim().length>0);if(lines.length<2)throw new Error('TSV 至少需要表頭與一筆資料。');const headers=parseTsvLine(lines[0]).map(h=>h.trim());const missing=['raw_speaker_label','speaker_type','speaker_code'].filter(f=>!headers.includes(f));if(missing.length)throw new Error('TSV 缺少必要欄位：'+missing.join(', '));const rows=lines.slice(1).map(line=>{const cells=parseTsvLine(line);const r={};headers.forEach((h,i)=>r[h]=cells[i]??'');return r});const parsed=normalizeImportRows(rows);if(!parsed.length)throw new Error('TSV 中沒有可匯入的 Speaker Mapping 資料列。');return parsed}
function checkMappingTsvRoundTrip(rows=[]){const normalized=normalizeImportRows(rows);const tsv=serializeMappingTsv(normalized);const parsed=parseMappingTsv(tsv);const a=JSON.stringify(exportRows(normalized));const b=JSON.stringify(exportRows(parsed));if(a!==b)throw new Error('Mapping TSV roundtrip 不一致。');return{ok:true,row_count:parsed.length}}
async function readTextFile(file){if(!file)throw new Error('尚未選擇 Mapping 檔案。');const buf=await file.arrayBuffer();const bytes=new Uint8Array(buf);if(bytes.length>=2&&bytes[0]===0xFF&&bytes[1]===0xFE)return new TextDecoder('utf-16le').decode(bytes.subarray(2));if(bytes.length>=2&&bytes[0]===0xFE&&bytes[1]===0xFF)return new TextDecoder('utf-16be').decode(bytes.subarray(2));if(bytes.length>=3&&bytes[0]===0xEF&&bytes[1]===0xBB&&bytes[2]===0xBF)return new TextDecoder('utf-8').decode(bytes.subarray(3));return new TextDecoder('utf-8').decode(bytes)}
function le16(b,p){return b[p]|(b[p+1]<<8)}
function le32(b,p){return(b[p]|(b[p+1]<<8)|(b[p+2]<<16)|(b[p+3]<<24))>>>0}
async function inflateZipData(data,method,name){if(method===0)return data;if(method!==8)throw new Error(`XLSX 內 ${name} 使用不支援的 ZIP 壓縮方式：${method}`);if(!('DecompressionStream'in window))throw new Error('此瀏覽器不支援解壓縮 Excel 另存後的 XLSX；請使用 Chrome/Edge 新版，或另存 UTF-16LE TSV。');try{const stream=new Blob([data]).stream().pipeThrough(new DecompressionStream('deflate-raw'));return new Uint8Array(await new Response(stream).arrayBuffer())}catch(e){throw new Error(`XLSX 內 ${name} 解壓縮失敗：${e.message}`)}}
async function readZipEntries(file){const bytes=new Uint8Array(await file.arrayBuffer());let eocd=-1;for(let i=bytes.length-22;i>=0;i--){if(le32(bytes,i)===0x06054b50){eocd=i;break}}if(eocd<0)throw new Error('XLSX 不是合法 ZIP 檔，找不到 EOCD。');const count=le16(bytes,eocd+10);let p=le32(bytes,eocd+16);const out=new Map();for(let i=0;i<count;i++){if(le32(bytes,p)!==0x02014b50)throw new Error('XLSX central directory 損毀。');const method=le16(bytes,p+10);const compSize=le32(bytes,p+20);const nameLen=le16(bytes,p+28);const extraLen=le16(bytes,p+30);const commentLen=le16(bytes,p+32);const localOffset=le32(bytes,p+42);const name=dec.decode(bytes.subarray(p+46,p+46+nameLen));if(le32(bytes,localOffset)!==0x04034b50)throw new Error(`XLSX local header 損毀：${name}`);const ln=le16(bytes,localOffset+26),le=le16(bytes,localOffset+28);const dataStart=localOffset+30+ln+le;const comp=bytes.subarray(dataStart,dataStart+compSize);out.set(name.replace(/^\//,''),await inflateZipData(comp,method,name));p+=46+nameLen+extraLen+commentLen}return out}
function xmlText(bytes){return dec.decode(bytes)}
function unxml(s){return String(s||'').replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&quot;/g,'"').replace(/&apos;/g,"'").replace(/&amp;/g,'&')}
function attrs(s){const o={};String(s||'').replace(/([A-Za-z_:][\w:.-]*)="([^"]*)"/g,(_,k,v)=>{o[k]=unxml(v);return''});return o}
function colIndex(ref){const m=String(ref||'').match(/[A-Z]+/);if(!m)return null;let n=0;for(const ch of m[0])n=n*26+(ch.charCodeAt(0)-64);return n-1}
function sharedStrings(entries){const b=entries.get('xl/sharedStrings.xml');if(!b)return[];const xml=xmlText(b),out=[];for(const m of xml.matchAll(/<si\b[^>]*>([\s\S]*?)<\/si>/g)){let s='';for(const t of m[1].matchAll(/<t\b[^>]*>([\s\S]*?)<\/t>/g))s+=unxml(t[1]);out.push(s)}return out}
function sheetPath(entries){const wb=entries.get('xl/workbook.xml'),rels=entries.get('xl/_rels/workbook.xml.rels');if(wb&&rels){const w=xmlText(wb),r=xmlText(rels);let rid='';for(const m of w.matchAll(/<sheet\b([^>]*)\/>/g)){const a=attrs(m[1]);if(a.name==='Speaker_Mapping'||a.name==='Code_Mapping'||/mapping/i.test(a.name||'')){rid=a['r:id'];break}}if(rid){for(const m of r.matchAll(/<Relationship\b([^>]*)\/>/g)){const a=attrs(m[1]);if(a.Id===rid){let t=a.Target||'';if(t.startsWith('/'))return t.replace(/^\//,'');return 'xl/'+t.replace(/^\.\//,'')}}}}
return entries.has('xl/worksheets/sheet1.xml')?'xl/worksheets/sheet1.xml':Array.from(entries.keys()).find(k=>/^xl\/worksheets\/sheet\d+\.xml$/.test(k))}
function cellValue(cAttrs,inner,shared){if(cAttrs.t==='inlineStr'){let s='';for(const m of inner.matchAll(/<t\b[^>]*>([\s\S]*?)<\/t>/g))s+=unxml(m[1]);return s}const vm=inner.match(/<v[^>]*>([\s\S]*?)<\/v>/);if(!vm)return'';const v=unxml(vm[1]);return cAttrs.t==='s'?(shared[Number(v)]||''):v}
function worksheetRows(xml,shared){const rows=[];for(const rm of xml.matchAll(/<row\b[^>]*>([\s\S]*?)<\/row>/g)){const cells=[];let seq=0;for(const cm of rm[1].matchAll(/<c\b([^>]*)>([\s\S]*?)<\/c>/g)){const a=attrs(cm[1]);const idx=colIndex(a.r);const pos=idx==null?seq:idx;cells[pos]=cellValue(a,cm[2],shared);seq=pos+1}if(cells.some(v=>String(v||'').trim()!==''))rows.push(cells)}return rows}
async function parseMappingXlsx(file){if(!file)throw new Error('尚未選擇 Mapping XLSX 檔案。');const entries=await readZipEntries(file);const sp=sheetPath(entries);if(!sp||!entries.has(sp))throw new Error('XLSX 中找不到 Speaker_Mapping 工作表。');const rows=worksheetRows(xmlText(entries.get(sp)),sharedStrings(entries));if(rows.length<2)throw new Error('XLSX Speaker_Mapping 至少需要表頭與一筆資料。');const headers=rows[0].map(h=>String(h||'').trim());const missing=['raw_speaker_label','speaker_type','speaker_code'].filter(f=>!headers.includes(f));if(missing.length)throw new Error('XLSX 缺少必要欄位：'+missing.join(', '));const objects=rows.slice(1).map(cells=>{const r={};headers.forEach((h,i)=>r[h]=cells[i]??'');return r});const parsed=normalizeImportRows(objects);if(!parsed.length)throw new Error('XLSX 中沒有可匯入的 Speaker Mapping 資料列。');return parsed}
const OBS_MISMATCH_CODE='OBS_MISMATCH';
function inCharacterForType(type){return(type==='PC'||type==='NPC')?'1':'0'}
function appendImportWarning(old,msg){
    const a=String(old||'').split(/\n+/).filter(Boolean);
    if(msg&&!a.includes(msg))a.push(msg);
    return a.join('\n')||null
}
async function applyImportedMapsToRows(workspace_id,maps=[]){
    const byRaw=new Map();
    normalizeImportRows(maps).forEach(m=>{
        const raw=String(m.raw_speaker_label||'').trim();
        if(raw)byRaw.set(raw,m);
    });

    let scanned=0;
    let updated=0;
    let mismatchObserverCount=0;
    let filledFromMappingCount=0;
    let typeFixedFromMappingCount=0;

    await api().updateRowsByCursor(workspace_id,(row)=>{
        scanned++;
        const raw=String(row.speaker_label_raw||'').trim();
        const m=byRaw.get(raw);
        if(!m)return null;

        const next={...row};
        let changed=false;

        const currentCode=String(next.speaker_code||'').trim();
        const mappingCode=String(m.speaker_code||'').trim();
        const mappingType=String(m.speaker_type||'').trim();

        if(mappingCode&&currentCode&&currentCode!==mappingCode){
            next.speaker_type='Observer';
            next.speaker_code=OBS_MISMATCH_CODE;
            next.is_in_character_text='0';
            next.frontend_validation_warning=appendImportWarning(
                next.frontend_validation_warning,
                `Speaker Mapping 驗證：row ${next.source_row_no||next.turn_no_text||'?'} speaker_code 應為 ${mappingCode}，目前為 ${currentCode}；偵測發話人未知，待確認；已以 Observer / ${OBS_MISMATCH_CODE} 處理。`
            );
            changed=true;
            mismatchObserverCount++;
        }else{
            if(mappingCode&&currentCode!==mappingCode){
                next.speaker_code=mappingCode;
                changed=true;
                filledFromMappingCount++;
            }
            if(mappingType&&next.speaker_type!==mappingType){
                next.speaker_type=mappingType;
                next.is_in_character_text=inCharacterForType(mappingType);
                changed=true;
                typeFixedFromMappingCount++;
            }
        }

        if(changed){
            updated++;
            return next;
        }
        return null;
    });

    return{
        scanned,
        updated,
        observer_mismatch_count:mismatchObserverCount,
        filled_from_mapping_count:filledFromMappingCount,
        type_fixed_from_mapping_count:typeFixedFromMappingCount
    }
}
async function replaceWorkspaceMaps(rows){const id=await ensureWorkspaceForImport();const normalized=normalizeImportRows(rows);const summary=validateMappingRows(normalized);if(summary.error_count>0)throw new Error('Speaker Mapping 匯入失敗：\n'+summary.errors.join('\n'));await ops().replaceMaps(id,normalized);if(window.DagoCorpusInputOpsV14&&window.DagoCorpusInputOpsV14.refresh)await window.DagoCorpusInputOpsV14.refresh({forceMappings:true,forceSpeakerFilter:true});else if(window.DagoCorpusInputOpsV14&&window.DagoCorpusInputOpsV14.refreshMappings)await window.DagoCorpusInputOpsV14.refreshMappings(true);if(api().updateWorkspaceStatusElement)await api().updateWorkspaceStatusElement();stat(`Speaker Mapping 匯入完成：${normalized.length} 筆；warnings=${summary.warning_count}。請按「前端驗證」。`);return{rows:normalized,summary}}
async function importMappingFile(file){if(!file){const input=$('mappingImportFile');file=input&&input.files&&input.files[0];}if(!file)throw new Error('尚未選擇 Mapping 檔案。');const name=String(file.name||'').toLowerCase();if(name.endsWith('.xlsx'))return replaceWorkspaceMaps(await parseMappingXlsx(file));const text=await readTextFile(file);if(name.endsWith('.json'))return replaceWorkspaceMaps(parseMappingJson(text));if(name.endsWith('.tsv')||name.endsWith('.txt')||name.endsWith('.csv'))return replaceWorkspaceMaps(parseMappingTsv(text));throw new Error('不支援的 Mapping 檔案格式，請使用 .json、.xlsx、.tsv、.txt 或 .csv。')}
function bind(){const importBtn=$('importMapping');if(importBtn&&!importBtn.dataset.boundMappingIo){importBtn.dataset.boundMappingIo='1';importBtn.onclick=()=>importMappingFile().catch(e=>stat('Speaker Mapping 匯入失敗：'+e.message))}const json=$('downloadMappingJson');if(json&&!json.dataset.boundMappingIo){json.dataset.boundMappingIo='1';json.onclick=()=>downloadMappingJson().catch(e=>stat('Speaker Mapping JSON 匯出失敗：'+e.message))}const tsv=$('downloadMappingTsv');if(tsv&&!tsv.dataset.boundMappingIo){tsv.dataset.boundMappingIo='1';tsv.onclick=()=>downloadMappingTsv().catch(e=>stat('Speaker Mapping TSV 匯出失敗：'+e.message))}const xlsx=$('downloadMappingXlsx');if(xlsx&&!xlsx.dataset.boundMappingIo){xlsx.dataset.boundMappingIo='1';xlsx.onclick=()=>downloadMappingXlsx().catch(e=>stat('Speaker Mapping XLSX 匯出失敗：'+e.message))}}
window.DagoCorpusMappingIoV14={VERSION,MAP_FIELDS,normalizeMappingRows,normalizeImportRows,validateMappingRows,downloadMappingJson,downloadMappingTsv,downloadMappingXlsx,serializeMappingJson,parseMappingJson,checkMappingJsonRoundTrip,serializeMappingTsv,parseMappingTsv,checkMappingTsvRoundTrip,buildMappingXlsxBlob,templateRows,exportRows,parseMappingXlsx,replaceWorkspaceMaps,applyImportedMapsToRows,importMappingFile};
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',bind);else bind();
})();
