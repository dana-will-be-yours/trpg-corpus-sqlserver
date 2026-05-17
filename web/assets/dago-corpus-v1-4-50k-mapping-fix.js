(()=>{'use strict';
const BUILD='20260517-row50k-mapping-authority-v1';
const OBS_CODE='OBS_MISMATCH';

function $(id){return document.getElementById(id)}
function stat(msg){const s=$('status');if(s)s.textContent=msg}
function api(){if(!window.DagoCorpusWorkspaceV14)throw new Error('DagoCorpusWorkspaceV14 尚未載入');return window.DagoCorpusWorkspaceV14}
function ops(){if(!window.DagoCorpusWorkspaceOpsV14)throw new Error('DagoCorpusWorkspaceOpsV14 尚未載入');return window.DagoCorpusWorkspaceOpsV14}
function parser(){if(!window.DagoCorpusParserV14)throw new Error('DagoCorpusParserV14 尚未載入');return window.DagoCorpusParserV14}
function mappingIo(){if(!window.DagoCorpusMappingIoV14)throw new Error('DagoCorpusMappingIoV14 尚未載入');return window.DagoCorpusMappingIoV14}
function inputOps(){return window.DagoCorpusInputOpsV14||null}
function workspaceId(){const id=api().getCurrentWorkspaceId();if(!id)throw new Error('尚未建立 v1.4 workspace');return id}
function now(){return new Date().toISOString()}
function inCharacterForType(type){return(type==='PC'||type==='NPC')?'1':'0'}
function rowRange(workspace_id){return IDBKeyRange.bound([workspace_id,Number.NEGATIVE_INFINITY],[workspace_id,Number.POSITIVE_INFINITY])}
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

async function saveRowsChunked(workspace_id,rows,chunkSize=5000){
    const db=await api().openWorkspaceDb();
    const total=rows.length;
    let written=0;

    for(let start=0;start<total;start+=chunkSize){
        const end=Math.min(start+chunkSize,total);
        const tx=db.transaction('rows','readwrite');
        const store=tx.objectStore('rows');

        for(let i=start;i<end;i++){
            store.put(normalizeRecord(workspace_id,rows[i],i));
        }

        await txDone(tx);
        written=end;
        stat(`v1.4 50k 匯入中：已寫入 ${written} / ${total} rows`);
        await new Promise(r=>setTimeout(r,0));
    }

    return written;
}

function makeMapIndex(maps){
    const byRaw=new Map();
    for(const m of maps||[]){
        const raw=String(m.raw_speaker_label||'').trim();
        if(raw)byRaw.set(raw,m);
    }
    return byRaw;
}

async function applyCurrentSpeakerMappingToRows(options={}){
    const workspace_id=workspaceId();
    const maps=await api().getAllMaps(workspace_id);
    const byRaw=makeMapIndex(maps);

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

                if(newCode && oldCode!==newCode){
                    next.speaker_code=newCode;
                    changed=true;
                    changedByMapping++;
                    if(oldCode){
                        next.frontend_validation_warning=appendWarning(
                            next.frontend_validation_warning,
                            `Speaker Mapping 驗證：row ${next.source_row_no||next.turn_no_text||'?'} 已依當下 Speaker Mapping 將 speaker_code 由 ${oldCode} 改為 ${newCode}。`
                        );
                    }
                }

                if(newType && oldType!==newType){
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
                    const oldCode=String(next.speaker_code||'').trim();
                    const oldType=String(next.speaker_type||'').trim();

                    if(oldCode!==OBS_CODE || oldType!=='Observer'){
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

            if(scanned%2000===0){
                stat(`Speaker Mapping 同步中：scanned=${scanned}，updated=${updated}`);
            }

            c.continue();
        }
    });

    await txDone(tx);

    return{
        scanned,
        updated,
        unmapped,
        changed_by_mapping:changedByMapping,
        unmapped_observer:unmappedObserver
    };
}

async function refreshAfterMapping(){
    const io=inputOps();
    if(!io)return;

    const sf=$('speakerFilter');
    if(sf)sf.value='__ALL__';

    if(io.refreshRows)await io.refreshRows({status:false});
    if(io.refreshSpeakerFilter)await io.refreshSpeakerFilter(true);
    if(io.refreshWorkspaceStatus)await io.refreshWorkspaceStatus();

    stat('v1.4 Speaker Mapping 同步完成，預覽與顯示發話者已更新。');
}

async function validateSpeakerMappingRowsAuthority(){
    stat('前端驗證中：先依當下 Speaker Mapping 同步 stg.Utterance_Import rows。');
    const applySummary=await applyCurrentSpeakerMappingToRows({unmappedToObserver:true});

    let baseResult=null;
    const original=window.DagoCorpusMappingValidationV14;
    if(original && original.validateSpeakerMappingRows && original.validateSpeakerMappingRows!==validateSpeakerMappingRowsAuthority){
        baseResult=await original.validateSpeakerMappingRows();
    }

    await refreshAfterMapping();

    return{
        build:BUILD,
        apply_summary:applySummary,
        validation_result:baseResult
    };
}

async function applySpeakerMappingAuthority(){
    stat('套用 Speaker Mapping 中：依當下 Speaker Mapping 覆寫 rows speaker_type / speaker_code。');

    if(inputOps() && inputOps().saveMapsFromDom){
        await inputOps().saveMapsFromDom();
    }

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

async function importMappingAuthority(file){
    if(!file){
        const input=$('mappingImportFile');
        file=input&&input.files&&input.files[0];
    }
    if(!file)throw new Error('尚未選擇 Mapping 檔案。');

    const id=workspaceId();
    const name=String(file.name||'').toLowerCase();
    let rows;

    if(name.endsWith('.xlsx')){
        rows=await mappingIo().parseMappingXlsx(file);
    }else{
        const text=await readTextFile(file);
        if(name.endsWith('.json'))rows=mappingIo().parseMappingJson(text);
        else rows=mappingIo().parseMappingTsv(text);
    }

    await ops().replaceMaps(id,rows);

    stat(`Speaker Mapping 匯入完成：${rows.length} 筆；正在同步 rows。`);
    const applySummary=await applyCurrentSpeakerMappingToRows({unmappedToObserver:false});
    await refreshAfterMapping();

    stat(`Speaker Mapping 匯入完成：${rows.length} 筆；已同步 rows=${applySummary.updated}。`);
    return{rows,applySummary};
}

async function fastParseAndSave(){
    const t0=performance.now();
    const text=$('sourceText')?.value||'';
    if(!text.trim())throw new Error('沒有可解析的逐字稿文字。');

    const meta=metaFromForm();
    stat('v1.4 50k 模式：解析文字中。');

    const rows=parser().parseTextToRows(text,meta);
    const mappingRows=parser().makeMappingRows(rows);

    const workspace=await api().createWorkspace({
        ...meta,
        total_row_count:rows.length,
        last_page_size:Number($('pageSize')?.value||100)||100
    });

    stat(`v1.4 50k 模式：解析完成 ${rows.length} rows，開始分批寫入 IndexedDB。`);

    await saveRowsChunked(workspace.workspace_id,rows,5000);
    await api().saveMaps(workspace.workspace_id,mappingRows);

    if(parser().renderMappingsPreview)parser().renderMappingsPreview(mappingRows);

    const io=inputOps();
    if(io && io.refreshRows)await io.refreshRows({status:false});
    if(api().updateWorkspaceStatusElement)await api().updateWorkspaceStatusElement();

    setTimeout(()=>{
        if(inputOps()&&inputOps().refreshSpeakerFilter){
            inputOps().refreshSpeakerFilter(true).catch(e=>stat('顯示發話者延後更新失敗：'+e.message));
        }
    },0);

    const sec=((performance.now()-t0)/1000).toFixed(2);
    stat(`v1.4 50k 模式完成：rows=${rows.length}，maps=${mappingRows.length}，耗時=${sec} 秒。`);
    return{workspace,rows_count:rows.length,maps_count:mappingRows.length,seconds:Number(sec)};
}

function bindHotfix(){
    const parseBtn=$('parseText');
    if(parseBtn){
        parseBtn.onclick=()=>fastParseAndSave().catch(e=>stat('v1.4 50k 匯入失敗：'+e.message));
    }

    const importBtn=$('importMapping');
    if(importBtn){
        importBtn.onclick=()=>importMappingAuthority().catch(e=>stat('Speaker Mapping 匯入失敗：'+e.message));
    }

    const applyBtn=$('applyMapping');
    if(applyBtn){
        applyBtn.onclick=()=>applySpeakerMappingAuthority().catch(e=>stat('套用 Speaker Mapping 失敗：'+e.message));
    }

    const validateBtn=$('validateBtn');
    if(validateBtn){
        validateBtn.onclick=()=>validateSpeakerMappingRowsAuthority().catch(e=>stat('前端驗證失敗：'+e.message));
    }

    window.DagoCorpusV14Hotfix50kMapping={
        BUILD,
        fastParseAndSave,
        saveRowsChunked,
        applyCurrentSpeakerMappingToRows,
        applySpeakerMappingAuthority,
        validateSpeakerMappingRowsAuthority,
        importMappingAuthority
    };

    stat(`v1.4 hotfix loaded：${BUILD}`);
}

if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',bindHotfix);
else bindHotfix();
})();