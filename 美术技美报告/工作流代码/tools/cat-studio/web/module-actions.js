const moduleDetailsOpen=new Set();
const inlineDrafts=new Map(),inlineSaves=new Map();
function inlinePromptKey(kind,id){return pid+':'+kind+':'+id}
function inlinePromptValue(kind,id,fallback){return inlineDrafts.get(inlinePromptKey(kind,id))??fallback??''}
function queueInlinePrompt(kind,id,value){
 const projectId=pid,key=inlinePromptKey(kind,id);
 inlineDrafts.set(key,value);
 const route=kind==='image'?'/projects/'+projectId+'/images/'+id:'/actions/'+id;
 const previous=inlineSaves.get(key)||Promise.resolve();
 const next=previous.catch(()=>{}).then(()=>api(route,'PATCH',{prompt:value}));
 inlineSaves.set(key,next);
 next.then(()=>{if(inlineSaves.get(key)===next)inlineSaves.delete(key)}).catch(err=>notify('指令保存失败：'+err.message,true));
 return next;
}
async function flushInlinePrompts(){await Promise.all([...inlineSaves.values()])}
function decorateModules(){
 $$('#nodes .node').forEach(node=>{
  const body=node.querySelector('.node-body'),button=node.querySelector('[data-module-more]');if(!body||!button)return;
  let extra=body.querySelector('.module-extra');
  if(!extra){
   extra=document.createElement('div');extra.className='module-extra';
   // Only the preview and inline prompt remain outside the expandable options.
   for(const child of [...body.children]){
    if(child.matches('.node-preview,.inline-node-prompt,.batch-controls,.sprite-playback,.node-status.running,.node-status.failed'))continue;
    extra.append(child);
   }
   const isImage=['reference','image'].includes(node.dataset.type),isVideo=node.dataset.node.startsWith('action-');
   if(isImage||isVideo){
    const id=node.dataset.aid||(isImage?'reference':null),record=isImage?imageItem(id):a(id),kind=isImage?'image':'video';
    const label=document.createElement(isVideo?'div':'label');label.className='inline-node-prompt';
    label.innerHTML=`<span>${isImage?'图片指令':'动作指令'}</span><textarea aria-label="${isImage?'图片指令':'动作指令 1'}" data-inline-kind="${kind}" data-inline-id="${esc(id)}" placeholder="${isImage?'描述想生成或修改的图片…':'描述动作、朝向和循环要求…'}">${esc(inlinePromptValue(kind,id,record?.prompt))}</textarea>`;
    body.append(label);
    if(isVideo)setupVideoPromptRows(label,record);
   }
   body.append(extra);
  }
  const open=moduleDetailsOpen.has(pid+':'+node.dataset.node);extra.hidden=!open;button.setAttribute('aria-expanded',String(open));
 });
 if(typeof setupSpritePlayback==='function')setupSpritePlayback();
 if(typeof setupColorQuality==='function')setupColorQuality();
 if(typeof fitBatchModules==='function')fitBatchModules();
 if(typeof syncCanvasSelection==='function')syncCanvasSelection();
 drawEdges();
}
document.addEventListener('input',e=>{
 const input=e.target;
 if(input.matches('[data-inline-kind]')){
  const kind=input.dataset.inlineKind,id=input.dataset.inlineId;
  inlineDrafts.set(inlinePromptKey(kind,id),input.value);
  const record=kind==='image'?imageItem(id):a(id);if(record)record.prompt=input.value;
  if((selected.aid||'reference')===id){const inspector=$(kind==='image'?'#imageNodePrompt':'#actionPrompt');if(inspector)inspector.value=input.value}
 }else if(input.matches('#imageNodePrompt,#actionPrompt')){
  const kind=input.id==='imageNodePrompt'?'image':'video',id=selected.aid||'reference';
  inlineDrafts.set(inlinePromptKey(kind,id),input.value);
  const nodeInput=$$('#nodes [data-inline-kind]').find(el=>el.dataset.inlineKind===kind&&el.dataset.inlineId===id);if(nodeInput)nodeInput.value=input.value;
 }
});
document.addEventListener('change',e=>{const input=e.target;if(input.matches('[data-inline-kind]'))queueInlinePrompt(input.dataset.inlineKind,input.dataset.inlineId,input.value)});
document.addEventListener('click',e=>{
 const button=e.target.closest('[data-module-more]');if(!button)return;
 e.preventDefault();e.stopImmediatePropagation();const node=button.closest('.node'),id=pid+':'+node.dataset.node;
 if(moduleDetailsOpen.has(id))moduleDetailsOpen.delete(id);else moduleDetailsOpen.add(id);
 decorateModules();
},true);
let videoDropBusy=false;
document.addEventListener('dragover',e=>{
 if(![...(e.dataTransfer?.types||[])].includes('Files'))return;
 e.preventDefault();e.dataTransfer.dropEffect='copy';document.body.classList.add('video-drop-ready');
});
document.addEventListener('dragleave',e=>{if(!e.relatedTarget)document.body.classList.remove('video-drop-ready')});
document.addEventListener('drop',async e=>{
 const files=[...(e.dataTransfer?.files||[])];if(!files.length)return;
 e.preventDefault();document.body.classList.remove('video-drop-ready');
 const videos=files.filter(f=>/\.(mp4|webm|mov)$/i.test(f.name));
 if(!videos.length)return notify('请拖入 MP4、WebM 或 MOV 视频',true);
 if(videoDropBusy)return notify('正在导入视频，请稍候');
 if($('#dialog').open)return notify('请先关闭当前弹窗，再拖入视频');
 const dropPosition=$('#viewport').contains(e.target)?canvasPoint(e):{x:395,y:65};
 videoDropBusy=true;let imported=0;
 try{
  await ensureImageProject();const projectId=pid;let layout=structuredClone(p().layout||{});
  for(let i=0;i<videos.length;i++){
   const file=videos[i];if(file.size>150*1024*1024)throw Error(file.name+' 超过150MB');
   notify(`正在导入 ${i+1}/${videos.length}：${file.name}`);
   const act=await api('/projects/'+projectId+'/actions','POST',{name:file.name.replace(/\.[^.]+$/,''),stage:'action',prompt:''});
   // A dropped file always creates a new node, so existing videos are never replaced.
   const data=new FormData();data.append('file',file);
   await api('/actions/'+act.id+'/video','POST',data);imported++;
   layout['action-'+act.id]={x:dropPosition.x+i*320,y:dropPosition.y};
   await api('/projects/'+projectId,'PATCH',{layout});
   selected={type:'action',aid:act.id};
  }
  await refresh(true);setView('canvas');notify(`已导入 ${imported} 个视频`);
 }catch(err){await refresh(true);notify(`已导入 ${imported} 个视频。${err.message}`,true)}
 finally{videoDropBusy=false}
});

const videoPromptDrafts=new Map();
function extraVideoPrompts(id){return videoPromptDrafts.get(inlinePromptKey('video',id))??a(id)?.extra_prompts??[]}
function setupVideoPromptRows(container,record){
 record.extra_prompts=[...extraVideoPrompts(record.id)];
 const controls=document.createElement('div');controls.className='video-prompt-controls';
 const draw=()=>{
  controls.innerHTML=(record.extra_prompts||[]).map((text,i)=>`<div class="video-prompt-row"><div><span>动作指令 ${i+2}</span><button type="button" data-remove-prompt="${i}" aria-label="删除动作指令 ${i+2}">−</button></div><textarea data-extra-prompt="${i}" aria-label="动作指令 ${i+2}" placeholder="每条指令生成一个独立视频…">${esc(text)}</textarea></div>`).join('')+`<button type="button" data-add-prompt ${(record.extra_prompts||[]).length>=9?'disabled':''}>＋ 添加指令</button><small>共 ${1+(record.extra_prompts||[]).length} 条指令 · 每条生成一个视频</small>`;
  drawEdges();
 };
 const save=()=>{
  const key=inlinePromptKey('video',record.id),values=[...(record.extra_prompts||[])];
  videoPromptDrafts.set(key,values);if(a(record.id))a(record.id).extra_prompts=values;
  const previous=inlineSaves.get(key)||Promise.resolve();
  const next=previous.catch(()=>{}).then(()=>api('/actions/'+record.id,'PATCH',{extra_prompts:values}));
  inlineSaves.set(key,next);
  next.then(()=>{if(inlineSaves.get(key)===next)inlineSaves.delete(key)}).catch(e=>notify('指令保存失败：'+e.message,true));
  return next;
 };
 controls.oninput=e=>{if(e.target.matches('[data-extra-prompt]')){record.extra_prompts[Number(e.target.dataset.extraPrompt)]=e.target.value;save()}};
 controls.onclick=e=>{
  const add=e.target.closest('[data-add-prompt]'),remove=e.target.closest('[data-remove-prompt]');if(!add&&!remove)return;
  e.preventDefault();e.stopPropagation();record.extra_prompts||=[];
  if(add){if(record.extra_prompts.length>=9)return;record.extra_prompts.push('')}else record.extra_prompts.splice(Number(remove.dataset.removePrompt),1);
  save();draw();if(add)controls.querySelector('.video-prompt-row:last-of-type textarea')?.focus();
 };
 container.append(controls);draw();
}
