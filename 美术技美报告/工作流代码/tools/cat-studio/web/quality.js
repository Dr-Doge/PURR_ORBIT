function setupColorQuality(){
 for(const node of $$('#nodes .node')){
  let source=null,record=null;
  if(node.dataset.node.startsWith('process-')){source=node.dataset.node;record=a(source.slice(8))}
  else if(node.dataset.node.startsWith('sheet-edit-')){source=node.dataset.node;record=sheet(source.slice(11))}
  else if(node.classList.contains('export')){const data=spriteOutput(node.dataset.node);if(data){source=data.source;record=source.startsWith('process-')?a(source.slice(8)):sheet(source.slice(11))}}
  if(!source||!record)continue;
  const extra=node.querySelector('.module-extra');if(!extra||extra.querySelector('.color-quality'))continue;
  const running=state.jobs.find(j=>j.project===pid&&j.action===record.id&&j.kind==='colorfix'&&['running','queued'].includes(j.status));
  if(running){const status=document.createElement('div');status.className='node-status running';status.textContent='◈ '+running.message;node.querySelector('.node-body').append(status)}
  const report=last(record)?.meta.color_report,panel=document.createElement('div');panel.className='color-quality';
  panel.innerHTML=`<button type="button" data-quick-quality ${running?'disabled':''}>一键检测并修复</button><small>${report?`检测 ${report.detected.length} 帧 · 修正 ${report.corrected.length} 帧 · 待检查 ${report.review.length} 帧`:'首次提取自动处理；仍有闪烁时，点击再次检测修复。'}</small>`;
  const projectId=pid;panel.querySelector('[data-quick-quality]').onclick=async e=>{e.stopPropagation();e.target.disabled=true;try{await api('/projects/'+projectId+'/color-quality','POST',{source,mode:'repair',quick:true});await refresh(true);notify(last(record)?'正在一键检测并修复亮度跳变':'已启用首次提取自动修复')}catch(err){notify(err.message,true);e.target.disabled=false}};extra.append(panel);
 }
}
function previewBatch(bid){
 const projectId=pid,b=p().batches.find(b=>b.id===bid);if(!b)return;
 const items=b.outputs.map(id=>a(id)).filter(Boolean);
 if(!items.length)return notify('请先生成或创建批量流程',true);
 modal('批量动画预览与导出',`<p class="muted">同时预览本批 ${items.length} 段动画。透明结果按各自播放速度循环；只有视频的项目显示原视频。勾选已完成动画后导出合集。</p><div class="frame-controls"><button type="button" id="previewSelectAll">全选已完成</button><button type="button" id="previewSelectNone">全不选</button><span id="previewSelectedCount"></span></div><div class="batch-preview-grid">${items.map(act=>{const ex=last(act);return `<section class="batch-preview-item"><label><input type="checkbox" data-preview-id="${act.id}" ${ex?'checked':'disabled'}><b>${esc(act.name)}</b></label><div class="checker">${ex?`<img loading="lazy" src="${ex.base}/preview.png" alt="${esc(act.name)}透明动画">`:act.video?`<video src="${esc(act.video)}" controls autoplay loop muted playsinline preload="metadata"></video>`:'<p>等待生成</p>'}</div><small>${ex?`${ex.meta.frame_count} 帧 · ${Number(ex.meta.fps).toFixed(1)} FPS · 透明 PNG`:act.video?'仅原视频，需完成透明帧处理后导出':'尚未完成'}</small></section>`}).join('')}</div><p id="batchDownloadResult"></p>`,'<button type="button" data-close>关闭</button><button type="submit" class="primary">导出勾选动画</button>',true);
 const selected=()=>$$('[data-preview-id]:checked').map(el=>el.dataset.previewId);
 const update=()=>{$('#previewSelectedCount').textContent='已选 '+selected().length+' 段';$('#dialogForm button[type=submit]').disabled=!selected().length};
 $$('[data-preview-id]').forEach(el=>el.onchange=update);
 $('#previewSelectAll').onclick=()=>{$$('[data-preview-id]:not(:disabled)').forEach(el=>el.checked=true);update()};$('#previewSelectNone').onclick=()=>{$$('[data-preview-id]').forEach(el=>el.checked=false);update()};update();
 $('#dialogForm').onsubmit=async e=>{e.preventDefault();const button=e.submitter,ids=selected();button.disabled=true;try{const exports=Object.fromEntries(items.filter(a=>ids.includes(a.id)).map(a=>[a.id,last(a).id]));const result=await api('/exports/png','POST',{items:ids.map(id=>({project:projectId,action:id,export:exports[id]}))});const box=$('#batchDownloadResult');if(!box)return;box.innerHTML=`<a class="download" href="${esc(result.url)}" download>下载 ${result.count} 张 PNG（ZIP）</a>`;box.querySelector('a').click()}catch(err){notify(err.message,true)}finally{if(button.isConnected)update()}};
}
