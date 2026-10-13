function reusableActions(pr){return (pr?.actions||[]).filter(a=>a.prompt?.trim()&&!(pr.deleted_nodes||[]).includes('action-'+a.id)&&(!pr.graph||pr.graph.nodes.includes('action-'+a.id)))}
const batchBusy=new Set(),batchSaves=new Map(),batchDetails=new Set(),batchExpanded=new Set();
function fitBatchModules(){
 for(const node of $$('#nodes .node.batch')){
  node.style.width='280px';
  const table=node.querySelector('details[data-batch-details="cells"][open] .batch-table');
  if(table){const body=node.querySelector('.node-body'),style=getComputedStyle(body);const padding=parseFloat(style.paddingLeft)+parseFloat(style.paddingRight);node.style.width=Math.ceil(Math.max(280,table.scrollWidth+padding+4))+'px'}
 }
}
document.addEventListener('focusout',e=>{if(e.target.matches('[data-batch] input[type=number]'))setTimeout(()=>renderCanvas(),0)});
async function reuseAnimations(){try{await ensureImageProject();const b=await api('/projects/'+pid+'/batches','POST');await api('/projects/'+pid+'/batches/'+b.id,'PATCH',{actions:reusableActions(p()).map(a=>a.id)});selected={type:'batch',aid:b.id};await refresh(true);fit()}catch(err){notify(err.message,true)}}
function batchImages(b){const linked=graph().edges.filter(e=>e.to==='batch-'+b.id&&e.slot==='image').map(e=>e.from==='reference'?'reference':e.from.slice(6));const ids=[...new Set([...linked,...(b.image_ids||[])])];return (ids.length||Array.isArray(b.image_ids)?ids:[b.image_id]).map(imageItem).filter(Boolean)}
function batchNodeHidden(key){return (p()?.batches||[]).some(b=>graph().nodes.includes('batch-'+b.id)&&(b.groups||[]).some(g=>!batchExpanded.has(pid+':'+b.id+':'+g.image_id)&&g.actions.some(id=>['action-','process-','export-'].some(t=>key===t+id))))}
function batchItemState(id){const act=a(id);if(act?.exports?.length)return '完成';const job=state.jobs.find(j=>j.project===pid&&j.action===id);if(!job)return '待提交';return {queued:'排队中',running:'制作中',failed:'失败',interrupted:'待恢复',done:'等待处理'}[job.status]||job.status}
function renderBatchNodes(){return (p()?.batches||[]).map(b=>{
 const images=batchImages(b),source=state.projects.find(pr=>pr.id===b.source_project),actions=reusableActions(source),chosen=actions.filter(a=>b.actions.includes(a.id)),locked=b.outputs.length>0;
 const count=images.reduce((n,im)=>n+chosen.filter(a=>b.cells?.[im.id+':'+a.id]?.enabled!==false).length,0);
 const active=state.jobs.find(j=>j.project===pid&&b.outputs.includes(j.action)&&['running','queued'].includes(j.status));
 const summary=b.running?{status:'running',message:active?.message||'批量任务排队中'}:active;
 return card('batch','batch-'+b.id,p().layout['batch-'+b.id]||{x:45,y:650},'动画批量制作','MULTI CHARACTER',`${statusHtml(summary,locked?'流程已创建':'设置后生成整套流程')}<div class="batch-controls" data-batch="${b.id}">
 <div class="batch-thumbs">${(locked&&b.groups?.length?b.groups:images).map(im=>`<figure>${im.source||im.reference?`<img src="${esc(im.source||im.reference)}" alt="${esc(im.name)}">`:''}<figcaption>${esc(im.name)}</figcaption></figure>`).join('')}</div>
 ${!locked?`<p class="muted">多个 Image 可连到左侧同一个接口，也可在下方多选或批量上传。</p><details ${batchDetails.has(pid+':'+b.id+':images')?'open':''} data-batch-details="images"><summary>选择画布图片</summary>${imageItems().filter(im=>graph().nodes.includes(im.id==='reference'?'reference':'image-'+im.id)).map(im=>`<label class="checkfield"><input type="checkbox" data-batch-image value="${im.id}" ${(b.image_ids||[]).includes(im.id)?'checked':''}>${esc(im.name)}</label>`).join('')}</details><label class="field"><span>批量上传参考图</span><input type="file" multiple data-batch-upload accept="image/png,image/jpeg,image/webp"></label>`:''}
 <label class="field"><span>沿用哪套动作</span><select data-batch-field="source_project" ${locked?'disabled':''}>${state.projects.map(pr=>`<option value="${pr.id}" ${pr.id===b.source_project?'selected':''}>${esc(pr.name)}</option>`).join('')}</select></label>
 <div class="batch-action-list">${actions.map(a=>`<div class="batch-action-row"><label class="checkfield"><input type="checkbox" data-batch-action value="${a.id}" ${b.actions.includes(a.id)?'checked':''} ${locked?'disabled':''}>${esc(a.name)} · ${a.options.duration}秒</label><label class="field"><span>总帧数</span><input type="number" min="1" max="120" step="1" required data-action-frames="${a.id}" value="${Number(b.action_frames?.[a.id]??b.frame_count??20)}" ${locked?'disabled':''}></label></div>`).join('')||'<p>请选择已有动作的项目。</p>'}</div>
 <label class="field"><span>统一去绿幕强度</span><select data-batch-field="threshold" ${locked?'disabled':''}>${[[45,'温和 · 保细节'],[25,'标准'],[12,'强力 · 清残绿'],[5,'最强 · 默认']].map(([v,n])=>`<option value="${v}" ${v===Number(b.threshold)?'selected':''}>${n}</option>`).join('')}</select></label>
 ${!locked?`<details data-batch-details="cells" ${batchDetails.has(pid+':'+b.id+':cells')?'open':''}><summary>展开明细 · 单项开关与帧数</summary><p class="muted">10的倍数的总帧数最稳定。</p><div class="batch-table-scroll"><table class="batch-table"><thead><tr><th>角色</th>${chosen.map(a=>`<th>${esc(a.name)}</th>`).join('')}</tr></thead><tbody>${images.map(im=>`<tr><th>${esc(im.name)}</th>${chosen.map(a=>{const key=im.id+':'+a.id,c=b.cells?.[key]||{},value=c.frame_count??b.action_frames?.[a.id]??b.frame_count??20;return `<td><label><input type="checkbox" data-cell-enabled="${key}" ${c.enabled===false?'':'checked'}>选中</label><input type="number" min="1" max="120" step="1" required data-cell-frames="${key}" value="${value}" aria-label="${esc(im.name+' '+a.name)} 总帧数"><small>总帧数${c.frame_count?' · 单独设置':''}</small></td>`}).join('')}</tr>`).join('')}</tbody></table></div><button type="button" data-reset-cells>恢复共用设置</button><button type="button" data-batch-build ${batchBusy.has(b.id)||!count?'disabled':''}>仅创建所选流程（不生成）</button><p class="muted">创建后可逐项修改指令和参数；不会调用模型或产生生成费用。</p></details><p class="muted">${images.length} 个角色 × ${chosen.length} 个动作，实际 ${count} 个收费视频任务。帧数为每张 Sprite Sheet 的总帧数；不足时重复采样补足。</p>`:''}
 <button class="primary" data-batch-generate ${b.running||batchBusy.has(b.id)?'disabled':''}>${b.running?'服务器正在依次制作…':locked?'继续运行未提交项':'生成全部 · '+count+' 项'}</button>
 ${locked?`<button type="button" data-batch-preview>▷ 预览全部 / 勾选导出</button><button data-batch-retry ${b.running?'disabled':''}>仅重试未完成项</button><p class="muted">本批动作清单已固定。展开流程可逐项修改指令和参数，之后继续运行会使用修改后的设置。重试可能产生视频生成费用；已有视频只重试处理。</p>${b.run_message?`<p class="muted">${esc(b.run_message)}</p>`:''}<div class="batch-groups">${(b.groups||[]).map(g=>`<section><b>${esc(g.name)}</b><button data-batch-expand="${g.image_id}">${batchExpanded.has(pid+':'+b.id+':'+g.image_id)?'收起流程':'展开流程'}</button>${g.actions.map(id=>{const act=a(id),ex=last(act);return `<div class="batch-result"><span>${esc(act?.name||'已删除')} · ${batchItemState(id)}</span>${ex?`<a href="${ex.base}/spritesheet.zip" download>下载</a>`:''}</div>`}).join('')}</section>`).join('')}</div>`:''}
 </div>`,b.id)
 }).join('')}
document.addEventListener('toggle',e=>{const detail=e.target;if(!detail.matches?.('[data-batch-details]'))return;const key=pid+':'+detail.closest('[data-batch]').dataset.batch+':'+detail.dataset.batchDetails;if(detail.open)batchDetails.add(key);else batchDetails.delete(key);fitBatchModules();drawEdges()},true);
document.addEventListener('change',e=>{
 const node=e.target.closest('[data-batch]');if(!node)return;if(e.target.type==='number'&&!e.target.reportValidity())return;
 const bid=node.dataset.batch,projectId=pid,target=e.target,value=target.value,checked=target.checked,files=[...(target.files||[])];
 const selectedActions=[...node.querySelectorAll('[data-batch-action]:checked')].map(x=>x.value),selectedImages=[...node.querySelectorAll('[data-batch-image]:checked')].map(x=>x.value);
 const task=(batchSaves.get(bid)||Promise.resolve()).catch(()=>{}).then(async()=>{
  const pr=state.projects.find(pr=>pr.id===projectId),b=pr.batches.find(b=>b.id===bid);let changes={};
  if(target.matches('[data-batch-upload]')){
   const added=[];for(const [i,file] of files.entries()){
    const im=await api('/projects/'+projectId+'/images','POST',{name:file.name.replace(/\.[^.]+$/,'')});const data=new FormData();data.append('file',file);await api('/projects/'+projectId+'/images/'+im.id+'/upload','POST',data);added.push(im.id);
    const pos=pr.layout['batch-'+bid];pr.layout['image-'+im.id]={x:pos.x-350,y:pos.y+i*450};
    Object.assign(b,await api('/projects/'+projectId+'/batches/'+bid,'PATCH',{image_ids:[...new Set([...(b.image_ids||[]),im.id])]}));
   }await api('/projects/'+projectId,'PATCH',{layout:pr.layout});if(pid===projectId)await refresh(true);return;
  }else if(target.matches('[data-batch-image]'))changes.image_ids=selectedImages;
  else if(target.matches('[data-batch-action]'))changes.actions=selectedActions;
  else if(target.dataset.actionFrames)changes.action_frames={...(b.action_frames||{}),[target.dataset.actionFrames]:Number(value)};
  else if(target.dataset.cellEnabled||target.dataset.cellFrames){const key=target.dataset.cellEnabled||target.dataset.cellFrames;changes.cells={...(b.cells||{}),[key]:{...(b.cells?.[key]||{}),...(target.dataset.cellEnabled?{enabled:checked}:{frame_count:Number(value)})}}}
  else if(target.dataset.batchField){const k=target.dataset.batchField;changes[k]=k==='threshold'?Number(value):value;if(k==='source_project'){changes.actions=reusableActions(state.projects.find(pr=>pr.id===value)).map(a=>a.id);changes.cells={}}}
  else return;
  Object.assign(b,await api('/projects/'+projectId+'/batches/'+bid,'PATCH',changes));if(pid===projectId)await refresh(true);
 });batchSaves.set(bid,task);task.then(()=>{if(batchSaves.get(bid)===task)batchSaves.delete(bid)}).catch(err=>notify(err.message,true));
});
document.addEventListener('click',async e=>{
 const node=e.target.closest('[data-batch]');if(!node)return;const bid=node.dataset.batch,projectId=pid;
 if(e.target.closest('[data-batch-preview]')){previewBatch(bid);return}
 const expand=e.target.closest('[data-batch-expand]');if(expand){const key=pid+':'+bid+':'+expand.dataset.batchExpand;if(batchExpanded.has(key))batchExpanded.delete(key);else batchExpanded.add(key);renderCanvas();return}
 if(e.target.closest('[data-reset-cells]')){try{await Promise.all([...batchSaves.values()]);await api('/projects/'+pid+'/batches/'+bid,'PATCH',{cells:{}});await refresh(true)}catch(err){notify(err.message,true)}return}
 const buildButton=e.target.closest('[data-batch-build]');
 if(buildButton){
  if(batchBusy.has(bid))return;
  for(const input of node.querySelectorAll('input[type=number]'))if(!input.reportValidity())return;
  batchBusy.add(bid);buildButton.disabled=true;
  try{await Promise.all([...batchSaves.values()]);await flushInlinePrompts();const built=await api('/projects/'+projectId+'/batches/'+bid+'/build','POST');for(const group of built.groups||[])batchExpanded.add(projectId+':'+bid+':'+group.image_id);await refresh(true);notify('已创建 '+built.outputs.length+' 套可编辑流程，未启动生成')}
  catch(err){notify(err.message,true)}finally{batchBusy.delete(bid);if(pid===projectId)await refresh(true)}
  return;
 }
 const button=e.target.closest('[data-batch-generate],[data-batch-retry]');if(!button||batchBusy.has(bid))return;
 for(const input of node.querySelectorAll('input[type=number]'))if(!input.reportValidity())return;
 const retry=button.hasAttribute('data-batch-retry');batchBusy.add(bid);button.disabled=true;
 try{if(!state.connection.ark)throw Error('请先配置 Seedance');await Promise.all([...batchSaves.values()]);await flushInlinePrompts();await api('/projects/'+projectId+'/batches/'+bid+'/run','POST',{retry});notify('已启动服务器批量队列，可关闭页面，稍后查看结果')}
 catch(err){notify(err.message,true)}finally{batchBusy.delete(bid);await refresh(true)}
});
$('#addImage').insertAdjacentHTML('beforebegin','<button id="reuseAnimations">动画批量制作</button>');$('#reuseAnimations').onclick=reuseAnimations;
