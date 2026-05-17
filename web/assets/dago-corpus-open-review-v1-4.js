(()=>{'use strict';
const VERSION='2026-05-12 json-xlsx-v1-4-indexeddb-large-workspace';
function $(id){return document.getElementById(id)}
function stat(msg){const s=$('status');if(s)s.textContent=msg}
async function openReviewV14(){const ws=window.DagoCorpusWorkspaceV14;if(!ws){stat('v1.4 workspace 尚未載入，無法開啟審閱頁。');return}let workspace_id=ws.getCurrentWorkspaceId();if(!workspace_id&&$('sourceText')?.value.trim()&&window.DagoCorpusParserV14){const result=await window.DagoCorpusParserV14.parseAndSaveToIndexedDB();workspace_id=result?.workspace?.workspace_id||ws.getCurrentWorkspaceId()}if(!workspace_id){stat('尚未建立 v1.4 IndexedDB 工作區。請先解析或匯入 .docx。');return}const count=await ws.getRowCount(workspace_id);if(!count){stat('v1.4 IndexedDB 工作區沒有 rows，未開啟空白審閱頁。');return}const url=new URL('dago-corpus-review.html',window.location.href);url.searchParams.set('v','20260512-v1-4-indexeddb-large-workspace');const win=window.open(url.toString(),'_blank');if(!win)stat('瀏覽器阻擋新分頁，請允許彈出式視窗或手動開啟審閱工作頁。');else stat(`已開啟 v1.4 審閱頁：workspace=${workspace_id}，rows=${count}`)}
function bind(){const btn=$('openReview');if(btn&&!btn.dataset.v14Bound){btn.dataset.v14Bound='1';btn.onclick=()=>openReviewV14().catch(e=>stat('v1.4 開啟審閱頁失敗：'+e.message))}}
window.DagoCorpusOpenReviewV14={VERSION,openReviewV14};
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',bind);else bind();
})();