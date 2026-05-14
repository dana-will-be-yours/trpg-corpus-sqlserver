(()=>{'use strict';
const VERSION='2026-05-12 json-xlsx-v13-indexeddb-large-workspace';
const SPEAKER_TYPES=Object.freeze(['GM','PL','PC','NPC','Observer','Researcher']);
const UTTERANCE_FUNCTIONS=Object.freeze(['narration','dialogue','action','rule_check','decision','negotiation','question','clarification','conflict','summary']);
const UTT_FIELDS=Object.freeze(['import_batch_code','import_batch_id','source_row_no','project_code','team_code','session_code','scene_code','turn_no_text','sub_turn_no_text','utterance_code','speaker_type','speaker_code','speaker_label_raw','utterance_function','is_in_character_text','is_gm_narration_text','is_rule_related_text','is_decision_related_text','is_knowledge_related_text','start_timecode','end_timecode','duration_sec_text','utterance_text_raw','utterance_text_clean','utterance_text_verified','language_code','emotion_label','interaction_target_type','interaction_target_code','related_rule_code','related_world_setting_code','related_item_code','ai_summary','ai_annotation_json','human_annotation_note','transcription_confidence_text','review_status','include_in_analysis_text','exclusion_reason','import_status','frontend_validation_error','frontend_validation_warning']);
const MAP_FIELDS=Object.freeze(['raw_speaker_label','speaker_type','speaker_code','target_table','note']);
const BATCH_FIELDS=Object.freeze(['import_batch_code','project_code','team_code','session_code','source_file_name','source_url','version_name','row_count','created_at','note']);
function nowIso(){return new Date().toISOString()}
function padNo(n,width=5){return String(n).padStart(width,'0')}
function cleanValue(v){return v==null?'':String(v)}
function escapeHtml(v){return cleanValue(v).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}
function xmlEscape(v){return cleanValue(v).replace(/[<>&"']/g,c=>({'<':'&lt;','>':'&gt;','&':'&amp;','"':'&quot;',"'":'&apos;'}[c]))}
function csvEscape(v){const s=cleanValue(v);return /[\t\r\n"]/.test(s)?'"'+s.replace(/"/g,'""')+'"':s}
function targetTableForSpeakerType(type){if(['GM','PL','Observer','Researcher'].includes(type))return'Team_Member';if(type==='PC')return'Player_Character';if(type==='NPC')return'NPC';return''}
function legacyTargetTableForSpeakerType(type){const t=targetTableForSpeakerType(type);return t?`dbo.${t}`:''}
function safeSpeakerCode(label,fallback='SPK'){return String(label||fallback).trim().replace(/\s+/g,'_').replace(/[\/:*?"<>|]+/g,'_').slice(0,60)||fallback}
function isSpeakerType(type){return SPEAKER_TYPES.includes(type)}
function isUtteranceFunction(fn){return UTTERANCE_FUNCTIONS.includes(fn)}
function normalizeUtteranceCode(sessionCode,rowNo){return `UTT-${sessionCode||'SESSION'}-${padNo(rowNo)}`.slice(0,80)}
function downloadBlob(name,blob){const a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download=name;document.body.appendChild(a);a.click();setTimeout(()=>{URL.revokeObjectURL(a.href);a.remove()},1000)}
function makeTimestampedFilename(base,ext){const stamp=nowIso().replace(/[-:.TZ]/g,'').slice(0,14);return `${base}_${stamp}.${ext}`}
function utf16leBlob(text){const s=String(text||'');const buf=new Uint8Array(2+s.length*2);buf[0]=0xFF;buf[1]=0xFE;for(let i=0;i<s.length;i++){const c=s.charCodeAt(i);buf[2+i*2]=c&255;buf[3+i*2]=c>>8}return new Blob([buf],{type:'text/tab-separated-values;charset=utf-16le'})}
function objectFromFields(fields,row,emptyValue=null){return Object.fromEntries(fields.map(f=>[f,row&&row[f]!==undefined?row[f]:emptyValue]))}
function ensureCoreVersion(expected=VERSION){if(expected!==VERSION)throw new Error(`v13 core version mismatch: expected ${expected}, actual ${VERSION}`);return VERSION}
window.DagoCorpusV13Core={VERSION,SPEAKER_TYPES,UTTERANCE_FUNCTIONS,UTT_FIELDS,MAP_FIELDS,BATCH_FIELDS,nowIso,padNo,cleanValue,escapeHtml,xmlEscape,csvEscape,targetTableForSpeakerType,legacyTargetTableForSpeakerType,safeSpeakerCode,isSpeakerType,isUtteranceFunction,normalizeUtteranceCode,downloadBlob,makeTimestampedFilename,utf16leBlob,objectFromFields,ensureCoreVersion};
})();
