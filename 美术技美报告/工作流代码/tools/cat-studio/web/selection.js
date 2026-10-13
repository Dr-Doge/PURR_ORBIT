let selectionProject=null,selectedNodes=new Set(),groupDrag=null,boxMode=false,canvasClipboard=null,pasteCount=0,pasting=false,suppressCanvasClick=false;
let deletingSelection=false;
document.addEventListener('keydown',async e=>{
 if(!['Delete','Backspace'].includes(e.key)||selectionBlocked(e))return;
 const nodes=chosenNodes();if(!nodes.length)return;
 e.preventDefault();e.stopImmediatePropagation();
 if(e.repeat||deletingSelection||undoPending||pasting||drag)return;
 const target=pid,before=canvasSnapshot();deletingSelection=true;
 try{await api('/projects/'+target+'/nodes/delete','POST',{nodes});rememberCanvas(before);if(pid===target){selectedNodes.clear();selected={type:'none'};await refresh(true)}notify(`已删除 ${nodes.length} 个模块及连线，Ctrl+Z 可撤销`)}
 catch(err){notify(err.message,true)}finally{deletingSelection=false}
},true);
function syncCanvasSelection(){
 if(selectionProject!==pid){selectionProject=pid;selectedNodes.clear()}
 const valid=new Set(graph().nodes);selectedNodes=new Set([...selectedNodes].filter(n=>valid.has(n)));
 for(const node of $$('#nodes .node'))node.classList.toggle('multi-selected',selectedNodes.has(node.dataset.node));
}
function chosenNodes(){syncCanvasSelection();return selectedNodes.size?[...selectedNodes]:$$('#nodes .node.selected').map(n=>n.dataset.node)}
function selectionBlocked(e){return e.target.closest('input,textarea,select,[contenteditable="true"]')||$('#dialog').open||view!=='canvas'||!p()}
$('#fitCanvas').insertAdjacentHTML('beforebegin','<button id="boxSelect" title="框选模式；也可按 Shift+左键拖动" aria-pressed="false">▧ 框选</button>');
$('#boxSelect').onclick=()=>{boxMode=!boxMode;$('#boxSelect').setAttribute('aria-pressed',String(boxMode));$('#viewport').classList.toggle('box-select-mode',boxMode)};
$('#viewport').addEventListener('pointerdown',e=>{
 if(e.button!==0||!p()||undoPending||pasting||e.target.closest('button,a,input,textarea,video,select,label,summary,[data-port],[data-edge]'))return;
 syncCanvasSelection();const node=e.target.closest('.node');
 if(!node&&(e.shiftKey||boxMode)){
  e.preventDefault();e.stopImmediatePropagation();$('#viewport').focus();
  groupDrag={kind:'box',start:canvasPoint(e),base:e.ctrlKey?new Set(selectedNodes):new Set()};drag={kind:'selection'};
  const box=document.createElement('div');box.id='selectionBox';$('#world').append(box);$('#viewport').setPointerCapture(e.pointerId);return;
 }
 if(node&&(e.shiftKey||e.ctrlKey||e.metaKey)){
  e.preventDefault();e.stopImmediatePropagation();const key=node.dataset.node;
  if(selectedNodes.has(key))selectedNodes.delete(key);else selectedNodes.add(key);
  selected={type:'none'};syncCanvasSelection();suppressCanvasClick=true;return;
 }
 if(node&&selectedNodes.has(node.dataset.node)&&selectedNodes.size>1){
  e.preventDefault();e.stopImmediatePropagation();$('#viewport').focus();
  groupDrag={kind:'move',start:canvasPoint(e),before:canvasSnapshot(),items:[...selectedNodes].map(key=>{const n=nodeEl(key);return {key,node:n,x:parseFloat(n.style.left),y:parseFloat(n.style.top)}})};
  drag={kind:'selection'};$('#viewport').setPointerCapture(e.pointerId);return;
 }
 selectedNodes=new Set(node?[node.dataset.node]:[]);syncCanvasSelection();
},true);
$('#viewport').addEventListener('pointermove',e=>{
 if(!groupDrag)return;e.stopImmediatePropagation();const at=canvasPoint(e),d=groupDrag;
 if(d.kind==='box'){
  const x=Math.min(d.start.x,at.x),y=Math.min(d.start.y,at.y),r=Math.max(d.start.x,at.x),b=Math.max(d.start.y,at.y);
  Object.assign($('#selectionBox').style,{left:x+'px',top:y+'px',width:(r-x)+'px',height:(b-y)+'px'});
  selectedNodes=new Set(d.base);
  for(const n of $$('#nodes .node')){const nx=parseFloat(n.style.left),ny=parseFloat(n.style.top);if(nx>=x&&ny>=y&&nx+n.offsetWidth<=r&&ny+n.offsetHeight<=b)selectedNodes.add(n.dataset.node)}
  selected={type:'none'};syncCanvasSelection();
 }else{for(const item of d.items){item.node.style.left=(item.x+at.x-d.start.x)+'px';item.node.style.top=(item.y+at.y-d.start.y)+'px'}drawEdges()}
},true);
$('#viewport').addEventListener('pointerup',async e=>{
 if(!groupDrag)return;e.preventDefault();e.stopImmediatePropagation();const d=groupDrag;groupDrag=null;drag=null;suppressCanvasClick=true;$('#selectionBox')?.remove();
 if($('#viewport').hasPointerCapture(e.pointerId))$('#viewport').releasePointerCapture(e.pointerId);
 if(d.kind==='move'){
  const layout=structuredClone(p().layout||{});for(const i of d.items)layout[i.key]={x:parseFloat(i.node.style.left),y:parseFloat(i.node.style.top)};
  try{await api('/projects/'+pid,'PATCH',{layout});p().layout=layout;rememberCanvas(d.before)}catch(err){notify(err.message,true)}
 }
 await refresh(true);syncCanvasSelection();
},true);
function cancelGroupDrag(){if(!groupDrag)return;groupDrag=null;drag=null;$('#selectionBox')?.remove();renderCanvas();syncCanvasSelection()}
$('#viewport').addEventListener('pointercancel',cancelGroupDrag,true);
window.addEventListener('blur',cancelGroupDrag);
document.addEventListener('keydown',e=>{if(e.key==='Escape'){cancelGroupDrag();selectedNodes.clear();syncCanvasSelection()}},true);
$('#viewport').addEventListener('click',e=>{if(suppressCanvasClick){suppressCanvasClick=false;e.stopImmediatePropagation();e.preventDefault()}},true);
document.addEventListener('copy',e=>{
 if(selectionBlocked(e))return;const nodes=chosenNodes();if(!nodes.length)return;
 e.preventDefault();e.stopImmediatePropagation();
 const projectId=pid,layout=Object.fromEntries(nodes.map(key=>{const n=nodeEl(key);return [key,{x:parseFloat(n.style.left),y:parseFloat(n.style.top)}]}));pasteCount=0;
 const bounds={x:Math.min(...Object.values(layout).map(n=>n.x)),y:Math.min(...Object.values(layout).map(n=>n.y))};
 const clipboard=Array.from(crypto.getRandomValues(new Uint8Array(16)),n=>n.toString(16).padStart(2,'0')).join(''),marker=JSON.stringify({type:'jominframe-nodes',origin:location.origin,clipboard,project:projectId,bounds});e.clipboardData.setData('text/plain',marker);
 const promise=(async()=>{await flushInlinePrompts();await Promise.all([...batchSaves.values()]);return api('/projects/'+projectId+'/copy','POST',{nodes,layout,clipboard})})();
 canvasClipboard={marker,promise};promise.then(()=>notify(`已复制 ${nodes.length} 个模块和组内连线`)).catch(err=>notify(err.message,true));
},true);
document.addEventListener('paste',async e=>{
 if(selectionBlocked(e))return;
 const text=e.clipboardData.getData('text/plain');let content;try{content=JSON.parse(text)}catch{return}
 if(content?.type!=='jominframe-nodes'||content.origin!==location.origin||!content.clipboard)return;
 e.preventDefault();e.stopImmediatePropagation();if(pasting||drag)return;pasting=true;
 const target=pid,before=canvasSnapshot();
 try{
  const clip=canvasClipboard?.marker===text?await canvasClipboard.promise:content;pasteCount++;
  const cross=content.project!==target;
  const dx=cross?(50-transform.x)/transform.z-content.bounds.x:60*pasteCount,dy=cross?(50-transform.y)/transform.z-content.bounds.y:60*pasteCount;
  const result=await api('/projects/'+target+'/paste','POST',{clipboard:clip.clipboard,dx,dy});rememberCanvas(before);
  if(pid===target){selectionProject=target;selectedNodes=new Set(result.nodes);selected={type:'none'};await refresh(true);syncCanvasSelection()}
  notify(`已${cross?'跨画布':''}粘贴 ${result.nodes.length} 个模块，组内连线已保留`)
 }
 catch(err){notify(err.message,true)}finally{pasting=false}
},true);
