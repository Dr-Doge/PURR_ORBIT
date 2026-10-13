function spritePngName(canvas,animation){return (canvas+'-'+animation).replace(/[\\/:*?"<>|]/g,'_').replace(/[. ]+$/,'')+'.png'}
const pngSelection=new Set();
let pngExportItems=[],pngExportBusy=false,pngExportResult=null;
function renderPngExports(items){
 pngExportItems=items;
 const key=({pr,ac,ex})=>pr.id+':'+ac.id+':'+ex.id;
 const valid=new Set(items.map(key));for(const id of pngSelection)if(!valid.has(id))pngSelection.delete(id);
 $('#exportsView').innerHTML=`<div class="view-heading"><div><h2>导出资源</h2><p>单个下载透明 Sprite Sheet PNG；多选打包仅包含 PNG。点击动画卡片选中，再次点击取消。</p></div><span class="count-badge">${items.length} 个动画</span></div><div class="frame-controls"><button id="pngSelectAll">全选</button><button id="pngSelectProject">选择当前项目</button><button id="pngSelectNone">取消选择</button><span id="pngSelectedCount"></span><button id="pngDownloadSelected" class="primary">下载所选 PNG</button></div><div id="pngExportResult">${pngExportResult?`<a class="download" href="${esc(pngExportResult.url)}" download>下载 ${pngExportResult.count} 张 PNG（ZIP）</a>`:''}</div><div class="export-grid">${items.map(item=>{const {pr,ac,ex}=item;return `<article class="export-card" data-png-card="${esc(key(item))}" tabindex="0" aria-label="${esc(pr.name)} - ${esc(ac.name)}，按空格切换选择"><label class="checkfield"><input type="checkbox" data-png-select="${esc(key(item))}" ${pngSelection.has(key(item))?'checked':''}>选择此动画</label><img class="checker" src="${ex.base}/preview.png" alt="${esc(ac.name)}"><h3>${esc(pr.name)} - ${esc(ac.name)}</h3><p>${ex.meta.frame_count} 帧 · ${ex.meta.frame_width}px</p><a class="download" href="${ex.base}/spritesheet.png" download="${esc(spritePngName(pr.name,ac.name))}">↓ 下载 PNG</a></article>`}).join('')}</div>${items.length?'':'<p class="empty-state">完成透明帧处理后，即可在这里下载 PNG。</p>'}`;
 const update=()=>{$('#pngSelectedCount').textContent='已选 '+pngSelection.size+' 个';$('#pngDownloadSelected').disabled=pngExportBusy||!pngSelection.size;$$('[data-png-select]').forEach(el=>{el.checked=pngSelection.has(el.dataset.pngSelect);el.closest('.export-card').classList.toggle('png-selected',el.checked)})};
 $$('[data-png-select]').forEach(el=>el.onchange=()=>{el.checked?pngSelection.add(el.dataset.pngSelect):pngSelection.delete(el.dataset.pngSelect);update()});
 $$('[data-png-card]').forEach(card=>{
  const toggle=()=>{const id=card.dataset.pngCard;pngSelection.has(id)?pngSelection.delete(id):pngSelection.add(id);update()};
  card.onclick=e=>{if(e.target.closest('a,button,input,label,video,select,textarea'))return;toggle()};
  card.onkeydown=e=>{if(e.target===card&&[' ','Enter'].includes(e.key)){e.preventDefault();toggle()}};
 });
 $('#pngSelectAll').onclick=()=>{items.forEach(item=>pngSelection.add(key(item)));update()};
 $('#pngSelectProject').onclick=()=>{pngSelection.clear();items.filter(item=>item.pr.id===pid).forEach(item=>pngSelection.add(key(item)));update()};
 $('#pngSelectNone').onclick=()=>{pngSelection.clear();update()};
 $('#pngDownloadSelected').onclick=async()=>{
  pngExportBusy=true;update();
  try{
   const selected=items.filter(item=>pngSelection.has(key(item)));
   const result=await api('/exports/png','POST',{items:selected.map(({pr,ac,ex})=>({project:pr.id,action:ac.id,export:ex.id}))});
   pngExportResult=result;const box=$('#pngExportResult');box.innerHTML=`<a class="download" href="${esc(result.url)}" download>下载 ${result.count} 张 PNG（ZIP）</a>`;box.querySelector('a').click();
  }catch(e){notify(e.message,true)}finally{pngExportBusy=false;update()}
 };update();
}

// Apply the same live names to downloads from canvas nodes and inspectors.
document.addEventListener('click',event=>{
 const link=event.target.closest('a[download]');if(!link||!link.getAttribute('href')?.endsWith('/spritesheet.png'))return;
 for(const pr of state.projects)for(const ac of [...pr.actions,...(pr.sheets||[])]){
  if((ac.exports||[]).some(ex=>ex.base+'/spritesheet.png'===link.getAttribute('href'))){link.download=spritePngName(pr.name,ac.name);return}
 }
},true);
