function nodeKind(key){return key.startsWith('sheet-')?key.slice(0,key.lastIndexOf('-')):key.split('-')[0]}
function sheetSource(s){const edge=graph().edges.find(e=>e.to==='sheet-edit-'+s.id&&(e.slot||'source')==='source');return edge?resolveSheet(edge.from):null}
function resolveSheet(key,seen=new Set()){if(seen.has(key)||!graph().nodes.includes(key))return null;seen.add(key);const kind=nodeKind(key);if(kind==='export'||kind==='sheet-export'){const edge=graph().edges.find(e=>e.to===key);return edge?resolveSheet(edge.from,seen):null}if(kind==='sheet-source')return sheet(key.slice(13));const record=kind==='process'?a(key.slice(8)):kind==='sheet-edit'?sheet(key.slice(11)):null,ex=last(record);if(!ex)return null;return {source:ex.base+'/spritesheet.png',original:ex,options:{columns:ex.meta.columns,rows:Math.ceil(ex.meta.frame_count/ex.meta.columns),count:ex.meta.frame_count,fps:ex.meta.fps,size:ex.meta.frame_width}}}
function sheetReference(s){const edge=graph().edges.find(e=>e.to==='sheet-edit-'+s.id&&e.slot==='image');return edge?imageItem(edge.from==='reference'?'reference':edge.from.slice(6)):null}
function sheetExport(s){const edge=graph().edges.find(e=>e.to==='sheet-export-'+s.id);return edge?last(sheet(edge.from.slice(11))):null}
// Typed connections are stored with the project and resolve the actual video input.
function graph(){const pr=p();const g=pr?.graph?structuredClone(pr.graph):{nodes:['reference',...(pr?.actions||[]).flatMap(x=>['action','process','export'].map(t=>t+'-'+x.id))],edges:(pr?.actions||[]).flatMap(x=>[{from:'reference',to:'action-'+x.id},{from:'action-'+x.id,to:'process-'+x.id},{from:'process-'+x.id,to:'export-'+x.id}])};const deleted=new Set(pr?.deleted_nodes||[]);for(const sh of pr?.sheets||[]){if(!g.nodes.includes('sheet-edit-'+sh.id)&&!deleted.has('sheet-edit-'+sh.id)){g.nodes.push('sheet-edit-'+sh.id,'sheet-export-'+sh.id);g.edges.push({from:'sheet-edit-'+sh.id,to:'sheet-export-'+sh.id});if(sh.source){g.nodes.push('sheet-source-'+sh.id);g.edges.push({from:'sheet-source-'+sh.id,to:'sheet-edit-'+sh.id})}}if(g.version!==2&&sh.source&&!g.edges.some(e=>e.to==='sheet-edit-'+sh.id&&e.slot==='image'))g.edges.push({from:'reference',to:'sheet-edit-'+sh.id,slot:'image'})}for(const im of pr?.images||[])if(!g.nodes.includes('image-'+im.id))g.nodes.push('image-'+im.id);g.nodes=g.nodes.filter(n=>!deleted.has(n));g.edges=g.edges.filter(e=>g.nodes.includes(e.from)&&g.nodes.includes(e.to));g.version=2;return g}
function processSource(act){const edge=graph().edges.find(e=>e.to==='process-'+act.id);return edge?a(edge.from.slice(7)):null}
function exportResult(act){const edge=graph().edges.find(e=>e.to==='export-'+act.id);return edge?last(a(edge.from.slice(8))):null}
function exportSourceId(id){return graph().edges.find(e=>e.to==='export-'+id)?.from.slice(8)||id}
function enhanceGraph(){updateUndoButton();const g=graph();$$('#nodes .node').forEach(n=>{const key=n.dataset.node;if(!g.nodes.includes(key)||(typeof batchNodeHidden==='function'&&batchNodeHidden(key))){n.remove();return}const kind=nodeKind(key),edit=kind==='sheet-edit';if(kind==='batch'){n.insertAdjacentHTML('beforeend',`<button class="port input image-input" data-port="in" data-slot="image" title="图片参考输入：连接 Image（右键断开）" aria-label="图片参考输入"></button><span class="port-caption image-caption">图片参考</span>`);return;}if(kind!=='sheet-source')n.insertAdjacentHTML('beforeend',`<button class="port input" data-port="in" data-slot="source" title="${edit?'Sprite Sheet 动作输入':'输入'}（右键断开）" aria-label="${esc(key)} 输入"></button>`);if(edit)n.insertAdjacentHTML('beforeend',`<button class="port input image-input" data-port="in" data-slot="image" title="Image 外观参考输入" aria-label="${esc(key)} Image 输入"></button><span class="port-caption">动作</span><span class="port-caption image-caption">Image</span>`);n.insertAdjacentHTML('beforeend',`<button class="port output" data-port="out" title="拖动连接下游输入" aria-label="${esc(key)} 输出"></button>`)});drawEdges()}
function nodeEl(key){return $$('#nodes .node').find(n=>n.dataset.node===key)}
function socket(key,out,slot='source'){const n=nodeEl(key);if(!n)return null;return {x:parseFloat(n.style.left)+(out?n.offsetWidth:0),y:parseFloat(n.style.top)+(slot==='image'?83:33)}}
function curve(f,t){const bend=Math.max(70,Math.abs(t.x-f.x)*.45);return `M ${f.x} ${f.y} C ${f.x+bend} ${f.y}, ${t.x-bend} ${t.y}, ${t.x} ${t.y}`}
function drawEdges(){hideEdgeCut();const svg=$('#edges');if(!svg)return;const ns=$$('#nodes .node');const left=Math.min(0,...ns.map(n=>parseFloat(n.style.left)))-250,top=Math.min(0,...ns.map(n=>parseFloat(n.style.top)))-250,right=Math.max(800,...ns.map(n=>parseFloat(n.style.left)+n.offsetWidth))+250,bottom=Math.max(600,...ns.map(n=>parseFloat(n.style.top)+n.offsetHeight))+250;svg.style.left=left+'px';svg.style.top=top+'px';svg.style.width=(right-left)+'px';svg.style.height=(bottom-top)+'px';svg.setAttribute('viewBox',`${left} ${top} ${right-left} ${bottom-top}`);svg.innerHTML=graph().edges.map((e,i)=>{const f=socket(e.from,true),t=socket(e.to,false,e.slot);return f&&t?`<g class="edge-group" data-edge="${i}"><path class="edge-hit" d="${curve(f,t)}"/><path class="graph-edge" d="${curve(f,t)}"/></g>`:''}).join('');if(drag?.kind==='wire'&&drag.end){const f=socket(drag.key,true);if(f)svg.innerHTML+=`<path class="wire-preview" d="${curve(f,drag.end)}"/>`}}
async function persistGraph(g){const before=canvasSnapshot();await api('/projects/'+pid,'PATCH',{graph:g});rememberCanvas(before);p().graph=g;render(true)}
function canvasPoint(e){const r=$('#viewport').getBoundingClientRect();return{x:(e.clientX-r.left-transform.x)/transform.z,y:(e.clientY-r.top-transform.y)/transform.z}}
let contextPoint={x:50,y:50};
function dismissMenu(){$('#canvasMenu')?.remove()}
function openConnectedMenu(e,source){
 dismissMenu();const projectId=pid,position=canvasPoint(e),kind=nodeKind(source);
 const options={reference:['image','action','batch','sheet-edit'],image:['image','action','batch','sheet-edit'],action:['process'],process:['export'],export:['sheet-edit'],'sheet-source':['sheet-edit'],'sheet-edit':['sheet-export'],'sheet-export':['sheet-edit']}[kind]||[];
 if(!options.length)return;
 const labels={image:'✧ Image · 参考图生成',action:'▷ 视频生成',batch:'✦ 动画批量制作',process:'◈ 透明帧处理',export:'▦ Sprite Sheet 导出','sheet-edit':kind==='image'||kind==='reference'?'✦ Sprite Sheet 改造 · 外观参考':'✦ Sprite Sheet 改造','sheet-export':'▦ Sprite Sheet 导出'};
 const menu=document.createElement('div');menu.id='canvasMenu';menu.className='canvas-menu';menu.style.left=Math.max(0,Math.min(e.clientX,innerWidth-250))+'px';menu.style.top=Math.max(0,Math.min(e.clientY,innerHeight-280))+'px';menu.innerHTML='<small>创建并连接模块</small>'+options.map(t=>`<button data-connected-type="${t}">${labels[t]}</button>`).join('');document.body.append(menu);
 menu.querySelectorAll('button').forEach(button=>button.onclick=async()=>{
  if(pid!==projectId){dismissMenu();return}const before=canvasSnapshot();menu.querySelectorAll('button').forEach(b=>b.disabled=true);
  try{const result=await api('/projects/'+projectId+'/connected-node','POST',{source,target:button.dataset.connectedType,...position});if(result.type==='batch')await api('/projects/'+projectId+'/batches/'+result.id,'PATCH',{actions:reusableActions(state.projects.find(pr=>pr.id===projectId)).map(a=>a.id)});rememberCanvas(before);dismissMenu();if(pid===projectId){selected={type:result.type.startsWith('sheet-')?(result.type==='sheet-edit'?'process':'export'):result.type,aid:result.id};if(typeof selectedNodes!=='undefined')selectedNodes.clear();await refresh(true)}notify('模块已创建并连接')}
  catch(err){notify(err.message,true);menu.querySelectorAll('button').forEach(b=>b.disabled=false)}
 });
}
function openCanvasMenu(e){dismissMenu();contextPoint=canvasPoint(e);const menu=document.createElement('div');menu.id='canvasMenu';menu.className='canvas-menu';menu.style.left=Math.min(e.clientX,innerWidth-240)+'px';menu.style.top=Math.min(e.clientY,innerHeight-320)+'px';menu.innerHTML='<small>添加步骤</small>'+[['image','✧ Image / GPT Image 2'],['action','▷ 视频生成 / 导入'],['process','◈ 透明帧提取 · 10 FPS'],['export','▦ Sprite Sheet 导出'],['remix','✦ Sprite Sheet 改造'],['sheet','↑ 导入 Sprite Sheet']].map(([t,n])=>`<button data-stage="${t}">${n}</button>`).join('');document.body.append(menu);menu.querySelectorAll('button').forEach(b=>b.onclick=async()=>{dismissMenu();if(!p())return newProject();if(b.dataset.stage==='sheet')return importSheetModal();try{let key;if(b.dataset.stage==='remix'){const sh=await api('/projects/'+pid+'/remixes','POST',{});key='sheet-edit-'+sh.id;selected={type:'process',aid:sh.id};await refresh()}else if(b.dataset.stage==='image'){const im=await api('/projects/'+pid+'/images','POST',{name:'Image'});key='image-'+im.id;selected={type:'image',aid:im.id};await refresh()}else{const type=b.dataset.stage;const created=await api('/projects/'+pid+'/actions','POST',{name:{action:'新动作',process:'透明帧',export:'导出'}[type],stage:type,prompt:''});key=type+'-'+created.id;selected={type,aid:created.id};await refresh()}const layout={...p().layout,[key]:{x:contextPoint.x,y:contextPoint.y}};if(b.dataset.stage==='remix')layout['sheet-export-'+selected.aid]={x:contextPoint.x+350,y:contextPoint.y};await api('/projects/'+pid,'PATCH',{layout});await refresh(true)}catch(err){notify(err.message,true)}})}
document.addEventListener('pointerdown',e=>{if(!e.target.closest('#canvasMenu'))dismissMenu()});
document.addEventListener('keydown',e=>{if(e.key==='Escape'){dismissMenu();drag=null;drawEdges()}});
$('#viewport').addEventListener('contextmenu',async e=>{e.preventDefault();const edge=e.target.closest('[data-edge]'),port=e.target.closest('[data-port]');if(edge||port){const g=graph();g.edges=g.edges.filter((x,i)=>edge?i!==Number(edge.dataset.edge):port.dataset.port==='in'?(x.to!==port.closest('.node').dataset.node||(x.slot||'source')!==(port.dataset.slot||'source')):x.from!==port.closest('.node').dataset.node);try{await persistGraph(g);notify('连接已断开')}catch(err){notify(err.message,true)}return}if(!e.target.closest('.node'))openCanvasMenu(e)});
$('#viewport').addEventListener('auxclick',e=>{if(e.button===1)e.preventDefault()});
$('#viewport').addEventListener('pointerdown',e=>{if(![0,1].includes(e.button)||!p()||undoPending)return;hideEdgeCut();if(e.button===0&&e.target.closest('[data-edge]')){e.preventDefault();return}const port=e.target.closest('[data-port]');if(e.button===0&&port){e.preventDefault();if(port.dataset.port!=='out')return;drag={kind:'wire',key:port.closest('.node').dataset.node,end:canvasPoint(e)};$('#viewport').setPointerCapture(e.pointerId);return}if(e.button===0&&e.target.closest('button,a,input,textarea,video,select,label,summary'))return;const node=e.button===0?e.target.closest('.node'):null;$('#viewport').focus({preventScroll:true});e.preventDefault();drag={before:node?canvasSnapshot():null,kind:node?'node':'pan',key:node?.dataset.node,startX:e.clientX,startY:e.clientY,x:node?parseFloat(node.style.left):transform.x,y:node?parseFloat(node.style.top):transform.y,node,moved:false};$('#viewport').setPointerCapture(e.pointerId);if(!node)$('#viewport').classList.add('panning')});
$('#viewport').addEventListener('pointermove',e=>{if(!drag)return;if(drag.kind==='wire'){drag.end=canvasPoint(e);drawEdges();return}const dx=e.clientX-drag.startX,dy=e.clientY-drag.startY;if(Math.abs(dx)+Math.abs(dy)>4)drag.moved=true;if(drag.kind==='pan'){transform.x=drag.x+dx;transform.y=drag.y+dy;applyTransform()}else{drag.node.style.left=(drag.x+dx/transform.z)+'px';drag.node.style.top=(drag.y+dy/transform.z)+'px';drawEdges()}});
$('#viewport').addEventListener('pointerup',async e=>{if(!drag)return;const d=drag;drag=null;$('#viewport').classList.remove('panning');if($('#viewport').hasPointerCapture(e.pointerId))$('#viewport').releasePointerCapture(e.pointerId);try{if(d.kind==='wire'){const port=document.elementFromPoint(e.clientX,e.clientY)?.closest('[data-port="in"]');if(port){const to=port.closest('.node').dataset.node,slot=port.dataset.slot||'source',fromKind=nodeKind(d.key),toKind=nodeKind(to);const allowed=slot==='image'?['reference>sheet-edit','image>sheet-edit','reference>batch','image>batch']:['reference>reference','reference>image','image>reference','image>image','reference>action','image>action','action>process','process>export','sheet-source>sheet-edit','sheet-edit>sheet-export','export>sheet-edit','sheet-export>sheet-edit'];if(!allowed.includes(fromKind+'>'+toKind)){notify('请选择匹配的输入：精灵图接动作，Image 接外观',true)}else{const g=graph();g.edges=g.edges.filter(x=>toKind==='batch'&&slot==='image'?!(x.to===to&&x.from===d.key&&x.slot===slot):x.to!==to||(x.slot||'source')!==slot);g.edges.push({from:d.key,to,slot});await persistGraph(g);notify('连接已保存；运行下游步骤时使用此输入')}}else{const hit=document.elementFromPoint(e.clientX,e.clientY);if(hit&&$('#viewport').contains(hit)&&!hit.closest('.node'))openConnectedMenu(e,d.key)}drawEdges()}else if(d.kind==='node'){if(d.moved){p().layout[d.key]={x:parseFloat(d.node.style.left),y:parseFloat(d.node.style.top)};await api('/projects/'+pid,'PATCH',{layout:p().layout});rememberCanvas(d.before)}selected={type:d.node.dataset.type,aid:d.node.dataset.aid};render(true)}}catch(err){notify(err.message,true);await refresh(true)}});
$('#viewport').addEventListener('pointercancel',()=>{drag=null;$('#viewport').classList.remove('panning');drawEdges()});
document.addEventListener('keydown',async e=>{if(!['Delete','Backspace'].includes(e.key)||e.target.closest('input,textarea,select,[contenteditable="true"]')||$('#dialog').open||view!=='canvas')return;const node=$('#nodes .node.selected');if(!node)return;e.preventDefault();if(e.repeat||undoPending)return;const before=canvasSnapshot();try{await api('/projects/'+pid+'/nodes/'+node.dataset.node,'DELETE');rememberCanvas(before);selected={type:'none'};await refresh(true);notify('模块及连线已移除，已生成文件保留')}catch(err){notify(err.message,true)}});
function hideEdgeCut(){document.getElementById('edgeCutHint')?.remove()}
let cuttingEdge=false;
$('#viewport').addEventListener('pointermove',e=>{
  const edge=e.target.closest('[data-edge]');
  if(drag||cuttingEdge||!edge){hideEdgeCut();return}
  let hint=document.getElementById('edgeCutHint');
  if(!hint){hint=document.createElement('div');hint.id='edgeCutHint';hint.textContent='✂ 点击断开';document.body.append(hint)}
  hint.style.left=Math.min(e.clientX+14,innerWidth-115)+'px';
  hint.style.top=Math.min(e.clientY+14,innerHeight-40)+'px';
});
$('#viewport').addEventListener('pointerleave',hideEdgeCut);
$('#viewport').addEventListener('wheel',hideEdgeCut,{passive:true});
window.addEventListener('blur',hideEdgeCut);
$('#viewport').addEventListener('click',async e=>{
  const edge=e.target.closest('[data-edge]');
  if(!edge||drag||cuttingEdge||e.button!==0)return;
  e.preventDefault();e.stopPropagation();hideEdgeCut();
  const g=graph(),index=Number(edge.dataset.edge);
  if(!g.edges[index])return;
  g.edges.splice(index,1);cuttingEdge=true;
  try{await persistGraph(g);notify('连接已断开')}
  catch(err){notify(err.message,true)}
  finally{cuttingEdge=false}
});
const canvasUndo=new Map();
let undoPending=false;
function canvasSnapshot(){return {project:pid,graph:graph(),layout:structuredClone(p().layout||{}),selected:structuredClone(selected)}}
function rememberCanvas(snapshot){if(!snapshot)return;const stack=canvasUndo.get(snapshot.project)||[];stack.push(snapshot);if(stack.length>50)stack.shift();canvasUndo.set(snapshot.project,stack);updateUndoButton()}
function updateUndoButton(){const b=$('#undoCanvas');if(b)b.disabled=undoPending||!canvasUndo.get(pid)?.length}
async function undoCanvas(){
  const stack=canvasUndo.get(pid),snapshot=stack?.at(-1);
  if(!snapshot||undoPending||drag)return;
  undoPending=true;updateUndoButton();
  try{await api('/projects/'+pid,'PATCH',{graph:snapshot.graph,layout:snapshot.layout,restore_nodes:true});stack.pop();selected=snapshot.selected;await refresh(true);notify('已撤销上一步画布操作')}
  catch(err){notify(err.message,true)}
  finally{undoPending=false;updateUndoButton()}
}
$('#fitCanvas').insertAdjacentHTML('afterend','<button id="undoCanvas" disabled title="撤销移动、连线、断线或删除（Ctrl+Z）；刷新后历史清空">↶ 撤销</button>');
$('#undoCanvas').onclick=undoCanvas;
document.addEventListener('keydown',e=>{
  if(!(e.ctrlKey||e.metaKey)||e.key.toLowerCase()!=='z'||e.shiftKey||e.altKey||e.target.closest('input,textarea,select,[contenteditable="true"]')||$('#dialog').open||view!=='canvas')return;
  e.preventDefault();if(!e.repeat)undoCanvas();
});
