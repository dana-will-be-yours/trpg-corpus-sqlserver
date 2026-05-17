(()=>{'use strict';
const core=window.DagoCorpusV14Core;
if(!core)throw new Error('DagoCorpusV14Core 尚未載入');
const VERSION=core.VERSION;
const UTT_FIELDS=core.UTT_FIELDS;
const MAP_FIELDS=core.MAP_FIELDS;
const BATCH_FIELDS=core.BATCH_FIELDS;
function $(id){return document.getElementById(id)}
function stat(msg){const s=$('status');if(s)s.textContent=msg}
function api(){if(!window.DagoCorpusWorkspaceV14)throw new Error('DagoCorpusWorkspaceV14 尚未載入');return window.DagoCorpusWorkspaceV14}
function workspaceId(){const id=api().getCurrentWorkspaceId();if(!id)throw new Error('尚未建立 v1.4 workspace，請先解析或匯入 Word。');return id}
function pad(n,w=5){return core.padNo(n,w)}
function formMeta(){const f=$('sourceForm');return f?Object.fromEntries(new FormData(f).entries()):{}}
function filename(base,ext){return core.makeTimestampedFilename(base,ext)}
function downloadBlob(name,blob){return core.downloadBlob(name,blob)}
async function getRowsChunk(id,start,size){if(api().getRowsChunkByCursor)return await api().getRowsChunkByCursor(id,start,size);return (await api().getAllRows(id)).slice(start,start+size)}
function normalizeRows(rows,baseIndex=0){return rows.map((r,i)=>{const n=baseIndex+i+1;const session=r.session_code||formMeta().session_code||'';return{...r,source_row_no:n,turn_no_text:String(n),utterance_code:(r.utterance_code&&/UTT-/.test(r.utterance_code))?String(r.utterance_code).replace(/-\d{5}$/,'-'+pad(n)):core.normalizeUtteranceCode(session,n),utterance_text_clean:r.utterance_text_clean||String(r.utterance_text_raw||'').replace(/\s+/g,' ').trim(),language_code:r.language_code||'zh-TW',review_status:r.review_status||'draft',include_in_analysis_text:r.include_in_analysis_text||'1',import_status:r.import_status||'raw'}})}
function buildBatch(workspace,rows,partNo,partCount,start,end,total){const meta=formMeta();return[{import_batch_code:meta.batch_code||workspace.batch_code||'',project_code:meta.project_code||workspace.project_code||'',team_code:meta.team_code||workspace.team_code||'',session_code:meta.session_code||workspace.session_code||'',source_file_name:meta.source_file_name||workspace.source_file_name||'',source_url:meta.source_url||workspace.source_url||'',version_name:VERSION,row_count:rows.length,created_at:new Date().toISOString(),note:`v1.4 cursor XLSX part ${partNo}/${partCount}; global rows ${start}-${end}; total ${total}`}]}
async function downloadXlsxParts(){if(!window.DagoCorpusXlsxCoreV14)throw new Error('dago-corpus-xlsx-core-v1-4.js 尚未載入，無法產生分批 XLSX。');const id=workspaceId();const maps=await api().getAllMaps(id);const workspace=await api().getWorkspace(id)||{};const total=await api().getRowCount(id);let size=Math.max(100,Number($('partSize')?.value||1000));if(size>5000){stat('partSize 大於 5000，已改為 5000；大檔建議使用 1000 或 2000。');size=5000}const partCount=Math.max(1,Math.ceil(total/size));for(let startIndex=0,partNo=1;startIndex<total;startIndex+=size,partNo++){const start=startIndex+1;const rows0=await getRowsChunk(id,startIndex,size);const partRows=normalizeRows(rows0,startIndex);const utteranceRows=partRows.map(r=>core.objectFromFields(UTT_FIELDS,r,null));const mapRows=maps.map(m=>core.objectFromFields(MAP_FIELDS,m,''));const end=startIndex+partRows.length;const metaRows=[{key:'version',value:VERSION},{key:'workspace_id',value:id},{key:'export_strategy',value:'cursor_chunked'},{key:'part_no',value:partNo},{key:'part_count',value:partCount},{key:'part_size',value:size},{key:'row_start',value:start},{key:'row_end',value:end},{key:'total_row_count',value:total},{key:'exported_at',value:new Date().toISOString()}];const batchRows=buildBatch(workspace,partRows,partNo,partCount,start,end,total);const blob=window.DagoCorpusXlsxCoreV14.buildXlsxBlob({batchFields:BATCH_FIELDS,batchRows,utteranceFields:UTT_FIELDS,utteranceRows,mapFields:MAP_FIELDS,mapRows,metadataRows:metaRows});downloadBlob(filename(`trpg_corpus_v1_4_cursor_part${pad(partNo,3)}`,'xlsx'),blob);stat(`分批 XLSX cursor 已產生 ${partNo}/${partCount}：rows ${start}-${end}`);await new Promise(r=>setTimeout(r,80))}stat(`分批 XLSX cursor 匯出完成：rows=${total}，partSize=${size}，parts=${partCount}`)}
function bind(){const b=$('downloadXlsxParts');if(b)b.onclick=()=>downloadXlsxParts().catch(e=>stat('v1.4 分批 XLSX 匯出失敗：'+e.message))}
window.DagoCorpusXlsxPartsV14={VERSION,downloadXlsxParts};
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',bind);else bind();
})();
