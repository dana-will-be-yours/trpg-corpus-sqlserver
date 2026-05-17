(()=>{'use strict';
const BUILD='20260517-row50k-mapping-authority-v2';
const OBS_CODE='OBS_MISMATCH';

function $(id){return document.getElementById(id)}
function stat(msg){const s=$('status');if(s)s.textContent=msg}
function api(){if(!window.DagoCorpusWorkspaceV14)throw new Error('DagoCorpusWorkspaceV14 尚未載入');return window.DagoCorpusWorkspaceV14}
function ops(){if(!window.DagoCorpusWorkspaceOpsV14)throw new Error('DagoCorpusWorkspaceOpsV14 尚未載入');return window.DagoCorpusWorkspaceOpsV14}
function mappingIo(){if(!window.DagoCorpusMappingIoV14)throw new Error('DagoCorpusMappingIoV14 尚未載入');return window.DagoCorpusMappingIoV14}
function inputOps(){return window.DagoCorpusInputOpsV14||null}
function workspaceId(){const id=api().getCurrentWorkspaceId();if(!id)throw new Error('尚未建立 v1.4 workspace');return id}
function now(){return new Date().toISOString()}
function inCharacterForType(type){return(type==='PC'||type==='NPC')?'1':'0'}
function rowRange(workspace_id){return IDBKeyRange.bound([workspace_id,Number.NEGATIVE_INFINITY],[workspace_id,Number.POSITIVE_INFINITY])}
function escId(s){return String(s||'SPK').trim().replace(/\s+/g,'_').replace(/[\\/:*?"<>|]+/g,'_').slice(0,60)||'SPK'}
function appendWarning(old,msg){
    const a=String(old||'').split(/\n+/).filter(Boolean);
    if(msg&&!a.includes(msg))a.push(msg);
    return a.join('\n')||null
}
function txDone(tx){
    return new Promise((resolve,reject)=>{
        tx.oncomplete=()=>resolve();
        tx.onerror=()=>reject(tx.error||new Error('IndexedDB transaction failed'));
        tx.onabort=()=>reject(tx.error||new Error('IndexedDB transaction aborted'));
    })
}
function metaFromForm(){
    const f=$('sourceForm');
    return f?Object.fromEntries(new FormData(f).entries()):{};
}
function guessSpeakerType(label){
    const s=String(label||'').trim().toLowerCase();
    if(['gm','kp','dm','主持','主持人','敘事者'].includes(s))return'GM';
    if(['observer','觀察者'].includes(s))return'Observer';
    if(['researcher','研究者'].includes(s))return'Researcher';
    return'PC';
}
function inferFn(raw,type){
    if(type==='GM')return'narration';
    if(/規則|檢定|擲骰|骰|判定|技能/.test(raw))return'rule_check';
    if(/決定|同意|選擇|投票/.test(raw))return'decision';
    if(/[？?]\s*$/.test(raw))return'question';
    if(/^[（(]/.test(String(raw||'')))return'action';
    return'dialogue';
}
function parseSpeakerLine(line){
    const m=String(line||'').trim().match(/^([^：:\s][^：:]{0,39})[：:]\s*(.*)$/);
    if(!m)return null;
    const label=m[1].trim();
    const text=m[2]||'';
    if(!label||label.length>40)return null;
    return{label,text};
}
function normalizeRecord(workspace_id,row,index){
    const source=Number(row.source_row_no||index+1);
    const order=Number(row.row_order||source);
    return{
        id:`${workspace_id}:${source}`,
        workspace_id,
        source_row_no:source,
        row_order:order,
        speaker_code:row.speaker_code||'',
        speaker_type:row.speaker_type||'',
        turn_no_text:String(row.turn_no_text||source),
        row_json:{...row,source_row_no:source,row_order:order,turn_no_text:String(row.turn_no_text||source)},
        updated_at:now()
    }
}
function buildMinimalRow(meta,n,label,raw){
    const type=guessSpeakerType(label);
    const code=escId(label);
    const session=meta.session_code||'';
    const text=String(raw||'').trim();
    return{
        import_batch_code:meta.batch_code||'',
        import_batch_id:null,
        source_row_no:n,
        project_code:meta.project_code||'',
        team_code:meta.team_code||'',
        session_code:session,
        scene_code:'',
        turn_no_text:String(n),
        sub_turn_no_text:null,
        utterance_code:`UTT-${session||'SESSION'}-${String(n).padStart(5,'0')}`.slice(0,80),
        speaker_type:type,
        speaker_code:code,
        speaker_label_raw:label||'Unknown',
        utterance_function:inferFn(text,type),
        is_in_character_text:inCharacterForType(type),
        is_gm_narration_text:(type==='GM')?'1':'0',
        is_rule_related_text:'0',
        is_decision_related_text:'0',
        is_knowledge_related_text:'0',
        start_timecode:null,
        end_timecode:null,
        duration_sec_text:null,
        utterance_text_raw:text,
        utterance_text_clean:text,
        utterance_text_verified:null,
        language_code:'zh-TW',
        emotion_label:null,
        interaction_target_type:null,
        interaction_target_code:null,
        related_rule_code:null,
        related_world_setting_code:null,
        related_item_code:null,
        ai_summary:null,
        ai_annotation_json:null,
        human_annotation_note:null,
        transcription_confidence_text:null,
        review_status:'draft',
        include_in_analysis_text:'1',
        exclusion_reason:null,
        import_status:'raw',
        frontend_validation_error:null,
        frontend_validation_warning:null,
        row_order:n
    };
}
function parseTranscriptTurbo(text,meta){
    const lines=String(text||'').split(/\r?\n/);
    const rows=[];
    let label='Unknown';
    let buf=[];
    function flush(){
        const raw=buf.join('\n').trim();
        if(!raw)return;
        rows.push(buildMinimalRow(meta,rows.length+1,label,raw));
        buf=[];
    }
    for(const line0 of lines){
        const line=String(line0||'').trim();
        if(!line)continue;
        const sp=parseSpeakerLine(line);
        if(sp){
            flush();
            label=sp.label;
            buf=[sp.text].filter(Boolean);
        }else{
            buf.push(line);
        }
    }
    flush();
    return rows;
}
function makeMaps(rows){
    const m=new Map();
    for(const r of rows){
        const raw=r.speaker_label_raw||'Unknown';
        if(!m.has(raw)){
            m.set(raw,{
                raw_speaker_label:raw,
                speaker_type:r.speaker_type||'PC',
                speaker_code:r.speaker_code||escId(raw),
                target_table:(r.speaker_type==='GM')?'Team_Member':'Player_Character',
                note:'v1.4 turbo mapping draft'
            });
        }
    }
    return Array.from(m.values());
}
async function saveRowsChunked(workspace_id,rows,chunkSize=10000){
    const db=await api().openWorkspaceDb();
    const total=rows.length;
    for(let start=0;start<total;start+=chunkSize){
        const end=Math.min(start+chunkSize,total);
        const tx=db.transaction('rows','readwrite');
        const store=tx.objectStore('rows');
        for(let i=start;i<end;i++){
            store.put(normalizeRecord(workspace_id,rows[i],i));
        }
        await txDone(tx);
        stat(`v1.4 turbo 匯入中：已寫入 ${end} / ${total} rows`);
        await new Promise(r=>setTimeout(r,0));
    }
    return total;
}
async function saveMapsFast(workspace_id,maps){
    await ops().replaceMaps(workspace_id,maps);
    return maps.length;
}
async function getCurrentRowLabels(workspace_id){
    const labels=new Map();
    const db=await api().openWorkspaceDb();
    const tx=db.transaction('rows','readonly');
    const idx=tx.objectStore('rows').index('workspace_row_order');
    const req=idx.openCursor(rowRange(workspace_id));
    await new Promise((resolve,reject)=>{
        req.onerror=()=>reject(req.error);
        req.onsuccess=e=>{
            const c=e.target.result;
            if(!c){resolve();return}
            const r=c.value.row_json||{};
            const raw=String(r.speaker_label_raw||'').trim();
            if(raw)labels.set(raw,(labels.get(raw)||0)+1);
            c.continue();
        }
    });
    return labels;
}
function mappingCoverage(maps,rowLabels){
    let matched=0;
    const imported=[];
    for(const m of maps||[]){
        const raw=String(m.raw_speaker_label||'').trim();
        if(raw)imported.push(raw);
        if(raw&&rowLabels.has(raw))matched++;
    }
    return{
        matched,
        total:maps.length,
        row_label_count:rowLabels.size,
        imported_examples:imported.slice(0,10),
        row_examples:Array.from(rowLabels.keys()).slice(0,10)
    };
}
function mapIndex(maps){
    const byRaw=new Map();
    for(const m of maps||[]){
        const raw=String(m.raw_speaker_label||'').trim();
        if(raw)byRaw.set(raw,m);
    }
    return byRaw;
}
async function saveMapsFromDomIfAny(){
    if(inputOps()&&inputOps().saveMapsFromDom&&document.querySelector('#mappingRows tr[data-map-index]')){
        await inputOps().saveMapsFromDom();
    }
}
async function applyCurrentSpeakerMappingToRows(options={}){
    const workspace_id=workspaceId();
    const maps=await api().getAllMaps(workspace_id);
    const byRaw=mapIndex(maps);

    const db=await api().openWorkspaceDb();
    const tx=db.transaction('rows','readwrite');
    const idx=tx.objectStore('rows').index('workspace_row_order');
    const req=idx.openCursor(rowRange(workspace_id));

    let scanned=0,updated=0,unmapped=0,changedByMapping=0,unmappedObserver=0;

    await new Promise((resolve,reject)=>{
        req.onerror=()=>reject(req.error);
        req.onsuccess=e=>{
            const c=e.target.result;
            if(!c){resolve();return}
            const rec=c.value;
            const row=rec.row_json||{};
            const raw=String(row.speaker_label_raw||'').trim();
            const m=byRaw.get(raw);
            scanned++;

            if(m){
                const next={...row};
                const oldCode=String(next.speaker_code||'').trim();
                const oldType=String(next.speaker_type||'').trim();
                const newCode=String(m.speaker_code||'').trim();
                const newType=String(m.speaker_type||'').trim();
                let changed=false;

                if(newCode&&oldCode!==newCode){
                    next.speaker_code=newCode;
                    changed=true;
                    changedByMapping++;
                }
                if(newType&&oldType!==newType){
                    next.speaker_type=newType;
                    next.is_in_character_text=inCharacterForType(newType);
                    changed=true;
                }
                if(changed){
                    rec.speaker_code=next.speaker_code||'';
                    rec.speaker_type=next.speaker_type||'';
                    rec.row_json=next;
                    rec.updated_at=now();
                    c.update(rec);
                    updated++;
                }
            }else{
                unmapped++;
                if(options.unmappedToObserver){
                    const next={...row};
                    if(next.speaker_code!==OBS_CODE||next.speaker_type!=='Observer'){
                        next.speaker_type='Observer';
                        next.speaker_code=OBS_CODE;
                        next.is_in_character_text='0';
                        next.frontend_validation_warning=appendWarning(
                            next.frontend_validation_warning,
                            `Speaker Mapping 驗證：row ${next.source_row_no||next.turn_no_text||'?'} 找不到當下 Speaker Mapping；偵測發話人未知，待確認；已以 Observer / ${OBS_CODE} 處理。`
                        );
                        rec.speaker_code=next.speaker_code;
                        rec.speaker_type=next.speaker_type;
                        rec.row_json=next;
                        rec.updated_at=now();
                        c.update(rec);
                        updated++;
                        unmappedObserver++;
                    }
                }
            }

            if(scanned%5000===0)stat(`Speaker Mapping 同步中：scanned=${scanned}，updated=${updated}`);
            c.continue();
        }
    });

    await txDone(tx);
    return{scanned,updated,unmapped,changed_by_mapping:changedByMapping,unmapped_observer:unmappedObserver};
}
async function refreshAfterMapping(){
    const io=inputOps();
    const sf=$('speakerFilter');
    if(sf)sf.value='__ALL__';
    if(io&&io.refreshRows)await io.refreshRows({status:false});
    if(io&&io.refreshSpeakerFilter)await io.refreshSpeakerFilter(true);
    if(io&&io.refreshWorkspaceStatus)await io.refreshWorkspaceStatus();
}
async function validateSpeakerMappingRowsAuthority(){
    stat('前端驗證中：先儲存當下 Speaker Mapping，並同步 rows。');
    await saveMapsFromDomIfAny();
    const applySummary=await applyCurrentSpeakerMappingToRows({unmappedToObserver:true});
    await refreshAfterMapping();
    stat(`前端驗證完成：scanned=${applySummary.scanned}，updated=${applySummary.updated}，unmapped=${applySummary.unmapped}。`);
    return{build:BUILD,apply_summary:applySummary};
}
async function applySpeakerMappingAuthority(){
    stat('套用 Speaker Mapping 中：儲存畫面上的當下 mapping，並覆寫 rows。');
    await saveMapsFromDomIfAny();
    const applySummary=await applyCurrentSpeakerMappingToRows({unmappedToObserver:false});
    await refreshAfterMapping();
    stat(`套用 Speaker Mapping 完成：scanned=${applySummary.scanned}，updated=${applySummary.updated}。`);
    return applySummary;
}
async function readTextFile(file){
    const buf=await file.arrayBuffer();
    const bytes=new Uint8Array(buf);
    if(bytes.length>=2&&bytes[0]===0xFF&&bytes[1]===0xFE)return new TextDecoder('utf-16le').decode(bytes.subarray(2));
    if(bytes.length>=3&&bytes[0]===0xEF&&bytes[1]===0xBB&&bytes[2]===0xBF)return new TextDecoder('utf-8').decode(bytes.subarray(3));
    return new TextDecoder('utf-8').decode(bytes);
}
async function parseMappingFile(file){
    const name=String(file.name||'').toLowerCase();
    if(name.endsWith('.xlsx'))return await mappingIo().parseMappingXlsx(file);
    const text=await readTextFile(file);
    if(name.endsWith('.json'))return mappingIo().parseMappingJson(text);
    return mappingIo().parseMappingTsv(text);
}
async function importMappingAuthority(file){
    if(!file){
        const input=$('mappingImportFile');
        file=input&&input.files&&input.files[0];
    }
    if(!file)throw new Error('尚未選擇 Mapping 檔案。');

    const id=workspaceId();
    const rows=await parseMappingFile(file);
    const labels=await getCurrentRowLabels(id);
    const cov=mappingCoverage(rows,labels);

    if(labels.size>0&&cov.matched===0){
        stat(
            'Speaker Mapping 匯入中止：mapping 的 raw_speaker_label 與目前 rows 完全無法匹配。' +
            ' rows 發話者範例=' + cov.row_examples.join('、') +
            '；mapping 範例=' + cov.imported_examples.join('、')
        );
        return{rows,coverage:cov,blocked:true};
    }

    await ops().replaceMaps(id,rows);
    stat(`Speaker Mapping 匯入完成：${rows.length} 筆；匹配 ${cov.matched}/${cov.total}；正在同步 rows。`);
    const applySummary=await applyCurrentSpeakerMappingToRows({unmappedToObserver:false});
    await refreshAfterMapping();
    stat(`Speaker Mapping 匯入完成：${rows.length} 筆；匹配 ${cov.matched}/${cov.total}；已同步 rows=${applySummary.updated}。`);
    return{rows,coverage:cov,applySummary};
}
async function fastParseAndSave(){
    const t0=performance.now();
    const text=$('sourceText')?.value||'';
    if(!text.trim())throw new Error('沒有可解析的逐字稿文字。');

    const meta=metaFromForm();
    stat('v1.4 turbo 模式：快速解析文字中。');

    const rows=parseTranscriptTurbo(text,meta);
    const mappingRows=makeMaps(rows);

    const workspace=await api().createWorkspace({
        ...meta,
        total_row_count:rows.length,
        last_page_size:Number($('pageSize')?.value||100)||100
    });

    stat(`v1.4 turbo 模式：解析完成 ${rows.length} rows，開始分批寫入 IndexedDB。`);
    await saveRowsChunked(workspace.workspace_id,rows,10000);
    await saveMapsFast(workspace.workspace_id,mappingRows);

    if(inputOps()&&inputOps().refreshRows)await inputOps().refreshRows({status:false});
    if(api().updateWorkspaceStatusElement)await api().updateWorkspaceStatusElement();

    setTimeout(()=>{
        if(inputOps()&&inputOps().refreshSpeakerFilter){
            inputOps().refreshSpeakerFilter(true).catch(e=>stat('顯示發話者延後更新失敗：'+e.message));
        }
    },0);

    const sec=((performance.now()-t0)/1000).toFixed(2);
    stat(`v1.4 turbo 模式完成：rows=${rows.length}，maps=${mappingRows.length}，耗時=${sec} 秒。`);
    return{workspace,rows_count:rows.length,maps_count:mappingRows.length,seconds:Number(sec)};
}
function bindHotfix(){
    const parseBtn=$('parseText');
    if(parseBtn)parseBtn.onclick=()=>fastParseAndSave().catch(e=>stat('v1.4 turbo 匯入失敗：'+e.message));

    const importBtn=$('importMapping');
    if(importBtn)importBtn.onclick=()=>importMappingAuthority().catch(e=>stat('Speaker Mapping 匯入失敗：'+e.message));

    const applyBtn=$('applyMapping');
    if(applyBtn)applyBtn.onclick=()=>applySpeakerMappingAuthority().catch(e=>stat('套用 Speaker Mapping 失敗：'+e.message));

    const validateBtn=$('validateBtn');
    if(validateBtn)validateBtn.onclick=()=>validateSpeakerMappingRowsAuthority().catch(e=>stat('前端驗證失敗：'+e.message));

    window.DagoCorpusV14Hotfix50kMapping={
        BUILD,
        fastParseAndSave,
        parseTranscriptTurbo,
        saveRowsChunked,
        importMappingAuthority,
        applyCurrentSpeakerMappingToRows,
        applySpeakerMappingAuthority,
        validateSpeakerMappingRowsAuthority,
        getCurrentRowLabels,
        mappingCoverage
    };

    stat(`v1.4 hotfix loaded：${BUILD}`);
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',bindHotfix);
else bindHotfix();
})();