(()=>{'use strict';
const VERSION='2026-05-12 json-xlsx-v13-indexeddb-large-workspace';
function $(id){return document.getElementById(id)}
function stat(msg){const s=$('status');if(s)s.textContent=msg}
function bind(){['downloadJson','downloadXlsx','downloadJsonParts','downloadXlsxParts'].forEach(id=>{const b=$(id);if(b&&!b.dataset.v13ExportBound){b.dataset.v13ExportBound='1';b.onclick=()=>stat('v13 IndexedDB 匯出尚未進入本階段；請先完成第二、三階段審閱資料確認。')}})}
window.DagoCorpusExportV13={VERSION};
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',bind);else bind();
})();