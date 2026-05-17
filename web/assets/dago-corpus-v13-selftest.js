(()=>{'use strict';
const enabled=new URLSearchParams(location.search).get('selftest')==='1';
if(!enabled)return;
function $(id){return document.getElementById(id)}
function stat(msg){const s=$('status');if(s)s.textContent=msg;console.log('[v13 selftest]',msg)}
window.addEventListener('error',e=>stat('v13 script error：'+(e.error&&e.error.message?e.error.message:e.message)));
window.addEventListener('unhandledrejection',e=>stat('v13 promise error：'+(e.reason&&e.reason.message?e.reason.message:e.reason)));
function assert(cond,msg){if(!cond)throw new Error(msg)}
async function run(){
  stat('v13 selftest 啟動。');
  const core=window.DagoCorpusV13Core;
  const workspace=window.DagoCorpusWorkspaceV13;
  const parser=window.DagoCorpusParserV13;
  const inputOps=window.DagoCorpusInputOpsV13;
  const exportApi=window.DagoCorpusExportV13;
  const mappingIo=window.DagoCorpusMappingIoV13;
  const mappingValidation=window.DagoCorpusMappingValidationV13;
  assert(core,'DagoCorpusV13Core missing');
  assert(workspace,'DagoCorpusWorkspaceV13 missing');
  assert(parser,'DagoCorpusParserV13 missing');
  assert(inputOps,'DagoCorpusInputOpsV13 missing');
  assert(exportApi,'DagoCorpusExportV13 missing');
  assert(mappingIo,'DagoCorpusMappingIoV13 missing');
  assert(mappingValidation,'DagoCorpusMappingValidationV13 missing');
  const previousWorkspaceId=workspace.getCurrentWorkspaceId?workspace.getCurrentWorkspaceId():null;
  let ws=null;
  try{
    assert(core.UTT_FIELDS&&core.UTT_FIELDS.includes('utterance_text_raw'),'UTT_FIELDS missing utterance_text_raw');
    assert(core.MAP_FIELDS&&core.MAP_FIELDS.includes('raw_speaker_label'),'MAP_FIELDS missing raw_speaker_label');
    assert(core.BATCH_FIELDS&&core.BATCH_FIELDS.includes('import_batch_code'),'BATCH_FIELDS missing import_batch_code');
    assert(typeof workspace.getRowsChunkByCursor==='function','workspace.getRowsChunkByCursor missing');
    assert(typeof workspace.updateRowsByCursor==='function','workspace.updateRowsByCursor missing');
    assert(typeof parser.buildUtteranceRowByNo==='function','parser.buildUtteranceRowByNo missing');
    assert(typeof exportApi.downloadJsonParts==='function','downloadJsonParts missing');
    assert(typeof exportApi.downloadTsvParts==='function','downloadTsvParts missing');
    assert(typeof mappingIo.checkMappingJsonRoundTrip==='function','mapping JSON roundtrip missing');
    assert(typeof mappingIo.checkMappingTsvRoundTrip==='function','mapping TSV roundtrip missing');
    assert(typeof mappingValidation.validateSpeakerMappingRows==='function','mapping validation missing');
    const meta={project_code:'SELFTEST',team_code:'SELFTEST-T01',session_code:'SELFTEST-S01',batch_code:'SELFTEST-B01',source_file_name:'selftest.txt',source_url:''};
    const sample='GM：你們抵達石門前。\n陽月：我查看門縫。\n楚服：我問這裡安全嗎？';
    const rows=parser.parseTextToRows(sample,meta);
    assert(rows.length===3,'parser should produce 3 rows');
    assert(rows[0].speaker_type==='GM','first row speaker_type should be GM');
    assert(rows[1].speaker_type==='PC','second row speaker_type should be PC');
    const maps=parser.makeMappingRows(rows);
    assert(maps.length>=2,'mapping rows should be generated');
    mappingIo.checkMappingJsonRoundTrip(maps);
    mappingIo.checkMappingTsvRoundTrip(maps);
    const jsonText=mappingIo.serializeMappingJson(maps,'SELFTEST');
    const jsonRows=mappingIo.parseMappingJson(jsonText);
    assert(jsonRows.length===maps.length,'mapping JSON parse row count mismatch');
    const tsvText=mappingIo.serializeMappingTsv(maps);
    const tsvRows=mappingIo.parseMappingTsv(tsvText);
    assert(tsvRows.length===maps.length,'mapping TSV parse row count mismatch');
    ws=await workspace.createWorkspace({...meta,total_row_count:rows.length,last_page_size:100});
    await workspace.saveRows(ws.workspace_id,rows);
    await workspace.saveMaps(ws.workspace_id,maps);
    const count=await workspace.getRowCount(ws.workspace_id);
    assert(count===3,'workspace row count should be 3');
    const chunk=await workspace.getRowsChunkByCursor(ws.workspace_id,0,2);
    assert(chunk.length===2,'cursor chunk should return 2 rows');
    await workspace.updateRowsByCursor(ws.workspace_id,(row)=>({...row,frontend_validation_warning:row.frontend_validation_warning||'selftest warning'}));
    const check=await workspace.getRowsChunkByCursor(ws.workspace_id,0,1);
    assert(check[0].frontend_validation_warning==='selftest warning','updateRowsByCursor should update warning');
    await mappingIo.replaceWorkspaceMaps(jsonRows);
    const savedMaps=await workspace.getAllMaps(ws.workspace_id);
    assert(savedMaps.length===jsonRows.length,'replaceWorkspaceMaps should save parsed mapping rows');
    const mismatchRows=await workspace.getAllRows(ws.workspace_id);
    const targetRow=mismatchRows.find(r=>r.speaker_label_raw==='陽月');
    assert(targetRow,'陽月 row missing');
    await workspace.updateRow(ws.workspace_id,targetRow.source_row_no,{...targetRow,speaker_code:'WRONG_CODE',speaker_type:'PC',is_in_character_text:'1'});
    const validation=await mappingValidation.validateSpeakerMappingRows();
    assert(validation.observer_mismatch_count>=1,'observer mismatch count should be >= 1');
    const afterRows=await workspace.getAllRows(ws.workspace_id);
    const afterTarget=afterRows.find(r=>r.speaker_label_raw==='陽月');
    assert(afterTarget.speaker_type==='Observer','mismatch row speaker_type should be Observer');
    assert(afterTarget.speaker_code==='OBS_MISMATCH','mismatch row speaker_code should be OBS_MISMATCH');
    assert(String(afterTarget.is_in_character_text)==='0','mismatch row is_in_character_text should be 0');
    assert(/OBS_MISMATCH/.test(String(afterTarget.frontend_validation_warning||'')),'mismatch warning should mention OBS_MISMATCH');
    stat('v13 selftest 通過。');
  }finally{
    if(ws&&ws.workspace_id)await workspace.clearWorkspace(ws.workspace_id);
    if(previousWorkspaceId&&workspace.setCurrentWorkspace){workspace.setCurrentWorkspace(previousWorkspaceId);if(inputOps.refresh)await inputOps.refresh({forceSpeakerFilter:true,forceMappings:true,status:false});}
    else if(inputOps.refreshWorkspaceStatus)await inputOps.refreshWorkspaceStatus();
  }
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',()=>run().catch(e=>stat('v13 selftest 失敗：'+e.message)));else run().catch(e=>stat('v13 selftest 失敗：'+e.message));
})();
