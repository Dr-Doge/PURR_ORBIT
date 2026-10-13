function reusableActions(pr){return (pr?.actions||[]).filter(a=>a.prompt?.trim()&&!(pr.deleted_nodes||[]).includes('action-'+a.id)&&(!pr.graph||pr.graph.nodes.includes('action-'+a.id)))}
const batchBusy=new Set(),batchSaves=new Map();
async function reuseAnimations(){try{await ensureImageProject();const b=await api('/projects/'+pid+'/batches','POST');selected={type:'batch',aid:b.id};await refresh(true);fit()}catch(err){notify(err.message,true)}}
function renderBatchNodes(){return (p()?.batches||[]).map(b=>{
 const edge=graph().edges.find(e=>e.to==='batch-'+b.id&&e.slot==='image'),imageId=edge?(edge.from==='reference'?'reference':edge.from.slice(6)):b.image_id;
 const source=state.projects.find(pr=>pr.id===b.source_project),im=imageItem(imageId),locked=b.outputs.length>0;
 const active=state.jobs.find(j=>j.project===pid&&b.outputs.includes(j.action)&&['running','queued'].includes(j.status));
 return card('batch','batch-'+b.id,p().layout['batch-'+b.id]||{x:45,y:650},'动画批量制作','BATCH',`${statusHtml(active,locked?'流程已创建':'设置后生成整套流程')}<div class="batch-controls" data-batch="${b.id}">
 ${im?.source?`<div class="node-preview"><img src="${esc(im.source)}" alt="角色参考图"></div>`:''}
 <label class="field"><span>${edge?'图片参考 · 已连接 Image':'图片参考 · 可从左侧接口连接'}</span><select data-batch-field="image_id" ${locked||edge?'disabled':''}>${imageItems().filter(im=>graph().nodes.includes(im.id==='reference'?'reference':'image-'+im.id)).map(im=>`<option value="${im.id}" ${im.id===imageId?'selected':''}>${esc(im.name)}</option>`).join('')}</select></label>
 ${edge?'<p class="muted">使用连线图片；断开后可选择或上传参考图。已创建的流程保持原参考图。</p>':''}<label class="field"><span>或上传新角色</span><input type="file" data-batch-upload accept="image/png,image/jpeg,image/webp" ${locked||edge?'disabled':''}></label>
 <label class="field"><span>沿用哪套动作</span><select data-batch-field="source_project" ${locked?'disabled':''}>${state.projects.map(pr=>`<option value="${pr.id}" ${pr.id===b.source_project?'selected':''}>${esc(pr.name)}</option>`).join('')}</select></label>
 <div class="batch-action-list">${reusableActions(source).map(a=>{const count=Number(b.action_frames?.[a.id]??b.frame_count??20);return `<div class="batch-action-row"><label class="checkfield"><input type="checkbox" data-batch-action value="${a.id}" ${b.actions.includes(a.id)?'checked':''} ${locked?'disabled':''}>${esc(a.name)} · ${a.options.duration}秒</label><label class="field"><span>总帧数</span><input type="number" min="1" max="120" step="1" required data-action-frames="${a.id}" aria-label="${esc(a.name)} Sprite Sheet 总帧数" value="${count}" ${locked?'disabled':''}></label></div>`}).join('')||'<p>请先添加动作，或选择已有动作的项目。</p>'}</div>
 <label class="field"><span>去绿幕强度</span><select data-batch-field="threshold" ${locked?'disabled':''}>${[[45,'温和 · 保细节'],[25,'标准'],[12,'强力 · 清残绿'],[5,'最强 · 默认']].map(([v,n])=>`<option value="${v}" ${v===Number(b.threshold)?'selected':''}>${n}</option>`).join('')}</select></label>
 <p class="muted">${b.actions.length} 个收费视频任务，各生成4秒原片，自动截取、去绿幕并导出。每项填入该动画 Sprite Sheet 的总帧数（1–120），不是 FPS。帧数不足时重复采样补足。</p>
 <button class="primary" data-batch-generate ${batchBusy.has(b.id)?'disabled':''}>${locked?'继续提交未生成动作':'生成整套流程'}</button>
 ${locked?'<p class="muted">设置已固定。新一套请添加新的批量模块；失败任务在视频节点检查后重试。</p>':''}</div>`,b.id)
 }).join('')}
document.addEventListener('change',e=>{
 const node=e.target.closest('[data-batch]');if(!node)return;if(e.target.matches('[data-action-frames]')&&!e.target.reportValidity())return;const bid=node.dataset.batch,projectId=pid;
 const task=(batchSaves.get(bid)||Promise.resolve()).catch(()=>{}).then(async()=>{
 try{
  const pr=state.projects.find(pr=>pr.id===projectId),b=pr.batches.find(b=>b.id===bid);let changes={};
  if(e.target.matches('[data-batch-upload]')){
   const file=e.target.files[0];if(!file)return;
   const im=await api('/projects/'+projectId+'/images','POST',{name:file.name.replace(/\.[^.]+$/,'')});
   const data=new FormData();data.append('file',file);await api('/projects/'+projectId+'/images/'+im.id+'/upload','POST',data);changes.image_id=im.id;
   const pos=pr.layout['batch-'+bid];await api('/projects/'+projectId,'PATCH',{layout:{...pr.layout,['image-'+im.id]:{x:pos.x-350,y:pos.y}}});
  }else if(e.target.matches('[data-batch-action]'))changes.actions=[...node.querySelectorAll('[data-batch-action]:checked')].map(x=>x.value);
  else if(e.target.dataset.actionFrames)changes.action_frames={...(b.action_frames||{}),[e.target.dataset.actionFrames]:Number(e.target.value)};
  else if(e.target.dataset.batchField){const k=e.target.dataset.batchField;changes[k]=['frame_count','threshold'].includes(k)?Number(e.target.value):e.target.value;if(k==='source_project')changes.actions=[]}
  else return;
  Object.assign(b,await api('/projects/'+projectId+'/batches/'+bid,'PATCH',changes));await refresh(true);
 }catch(err){notify(err.message,true);throw err}
 });batchSaves.set(bid,task);task.then(()=>{if(batchSaves.get(bid)===task)batchSaves.delete(bid)}).catch(()=>{});
});
document.addEventListener('click',async e=>{
 const button=e.target.closest('[data-batch-generate]');if(!button)return;
 const bid=button.closest('[data-batch]').dataset.batch,projectId=pid;if(batchBusy.has(bid))return;
 for(const input of button.closest('[data-batch]').querySelectorAll('[data-action-frames]'))if(!input.reportValidity())return;
 batchBusy.add(bid);button.disabled=true;
 try{
  if(!state.connection.ark)throw Error('请先在连接设置中配置 Seedance');
  await Promise.all([...batchSaves.values()]);await flushInlinePrompts();const b=await api('/projects/'+projectId+'/batches/'+bid+'/build','POST');await refresh(true);
  for(const id of b.outputs){const latest=await api('/state');if(latest.jobs.some(j=>j.project===projectId&&j.action===id&&j.kind==='video'))continue;await api('/actions/'+id+'/generate','POST',{auto_process:true})}
  notify('整套流程已提交，制作进度直接显示在模块上');
 }catch(err){notify(err.message+'；已创建的流程已保存，可继续提交未生成动作',true)}
 finally{batchBusy.delete(bid);await refresh(true)}
});
$('#addImage').insertAdjacentHTML('beforebegin','<button id="reuseAnimations" title="在当前画布添加批量模块">动画批量制作</button>');
$('#reuseAnimations').onclick=reuseAnimations;
$('#projects').addEventListener('contextmenu',e=>{
 const item=e.target.closest('[data-project]');if(!item)return;e.preventDefault();dismissMenu();
 const projectId=item.dataset.project,pr=state.projects.find(p=>p.id===projectId),menu=document.createElement('div');
 menu.id='canvasMenu';menu.className='canvas-menu';menu.style.left=Math.min(e.clientX,innerWidth-240)+'px';menu.style.top=Math.min(e.clientY,innerHeight-100)+'px';menu.innerHTML='<button>删除项目</button>';document.body.append(menu);
 menu.querySelector('button').onclick=()=>{dismissMenu();modal('删除项目',`<p>删除「${esc(pr.name)}」及其画布？此操作不可撤销，已生成的本地文件保留。</p>`,'<button type="button" data-close>取消</button><button type="submit" class="primary">删除项目</button>');$('#dialogForm').onsubmit=async e=>{e.preventDefault();try{await api('/projects/'+projectId,'DELETE');closeModal();canvasUndo.delete(projectId);if(pid===projectId){pid=null;selected={type:'none'}}await refresh(true);notify('项目已删除')}catch(err){notify(err.message,true)}}};
});
