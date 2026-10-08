let advancedCanvas=false;
try{advancedCanvas=localStorage.getItem('jominframe-canvas-mode-v2')==='advanced'}catch{}
const expandedModules=new Set();
function applyCanvasMode(){
 document.body.classList.toggle('simple-canvas',!advancedCanvas);
 const toggle=$('#canvasMode');
 if(toggle){toggle.textContent=advancedCanvas?'切换简洁画布':'切换高级画布';toggle.setAttribute('aria-pressed',String(advancedCanvas))}
 $$('#nodes .node').forEach(n=>{
  const expanded=expandedModules.has(pid+':'+n.dataset.node);
  n.classList.toggle('adjust-open',expanded);
  const button=n.querySelector('.node-adjust');
  button?.setAttribute('aria-expanded',String(expanded));
  if(button)button.title=expanded?'收起调整':'展开调整（详细参数在右侧）';
  n.querySelector('.simple-result')?.remove();
  if(!advancedCanvas&&n.dataset.node.startsWith('action-')){
   const edge=graph().edges.find(e=>e.from===n.dataset.node&&e.to.startsWith('process-'));
   const processor=edge?a(edge.to.slice(8)):null,result=last(processor);
   if(result){n.querySelector('.node-body').insertAdjacentHTML('beforeend',`<div class="simple-result"><p>透明动画已完成</p><a class="download" href="${esc(result.base)}/spritesheet.zip" download>↓ 下载 Sprite Sheet</a><button data-command="frames" data-aid="${processor.id}">调整透明帧</button></div>`)}
  }
 });
 document.body.classList.toggle('module-settings-open',advancedCanvas||$$('#nodes .node.adjust-open').some(n=>n.classList.contains('selected')));
 const hint=$('.stage-hint');if(hint)hint.textContent=advancedCanvas?'左键 / 中键拖动画布 · 右键添加步骤 · 拖动端口连接':'简洁模式 · 上传图片 → 生成动画 → 下载 · 点击 ⋯ 调整';
}
$('#fitCanvas').insertAdjacentHTML('afterend','<button id="canvasMode" type="button" aria-pressed="false">切换高级画布</button>');
$('#canvasMode').onclick=()=>{
 advancedCanvas=!advancedCanvas;
 try{localStorage.setItem('jominframe-canvas-mode-v2',advancedCanvas?'advanced':'simple')}catch{}
 applyCanvasMode();drawEdges();
};
// Capture before the existing node selection handler; toggling never starts a drag.
document.addEventListener('click',e=>{
 const button=e.target.closest('[data-adjust]');if(!button)return;
 e.preventDefault();e.stopImmediatePropagation();
 const node=button.closest('.node'),key=pid+':'+node.dataset.node;
 if(expandedModules.has(key))expandedModules.delete(key);else expandedModules.add(key);
 selected={type:node.dataset.type,aid:node.dataset.aid};
 $$('#nodes .node').forEach(n=>n.classList.toggle('selected',n===node));
 renderInspector();applyCanvasMode();drawEdges();
},true);
applyCanvasMode();
$('.inspector-title').insertAdjacentHTML('beforeend','<button type="button" id="closeModuleSettings" aria-label="收起模块设置">×</button>');
$('#closeModuleSettings').onclick=()=>{for(const n of $$('#nodes .node'))expandedModules.delete(pid+':'+n.dataset.node);applyCanvasMode()};
// In simple mode cards form a scrolling workspace; blueprint gestures remain advanced-only.
for(const event of ['pointerdown','wheel','contextmenu'])$('#viewport').addEventListener(event,e=>{
 if(advancedCanvas)return;
 if(event==='contextmenu')e.preventDefault();
 e.stopImmediatePropagation();
},true);
