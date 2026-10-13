function renameCanvas(projectId){
 const pr=state.projects.find(p=>p.id===projectId);if(!pr)return;
  modal('画布改名',`<label class="field"><span>画布名称</span><input id="renameProjectInput" value="${esc(pr.name)}" maxlength="80" required></label><p id="renameProjectError" role="alert"></p>`,'<button type="button" data-close>取消</button><button type="submit" class="primary">保存名称</button>');
  const input=$('#renameProjectInput');input.focus();input.select();
  $('#dialogForm').onsubmit=async e=>{e.preventDefault();const name=input.value.trim();if(!name){$('#renameProjectError').textContent='请输入画布名称';input.focus();return}const save=$('#dialogForm button[type=submit]');save.disabled=true;try{await api('/projects/'+projectId,'PATCH',{name});closeModal();if(typeof pngExportResult!=='undefined')pngExportResult=null;await refresh(true);notify('画布已改名，导出名称已同步')}catch(err){$('#renameProjectError').textContent=err.message;save.disabled=false}};
}
$('#projects').addEventListener('contextmenu',e=>{
 const item=e.target.closest('[data-project]');if(!item)return;e.preventDefault();dismissMenu();
 const projectId=item.dataset.project,pr=state.projects.find(p=>p.id===projectId),menu=document.createElement('div');
 menu.id='canvasMenu';menu.className='canvas-menu';menu.style.left=Math.max(0,Math.min(e.clientX,innerWidth-240))+'px';menu.style.top=Math.max(0,Math.min(e.clientY,innerHeight-130))+'px';menu.innerHTML='<button data-project-menu="rename">改名</button><button data-project-menu="delete">删除项目</button>';document.body.append(menu);
 menu.querySelector('[data-project-menu="rename"]').onclick=()=>{
  dismissMenu();renameCanvas(projectId);
 };
 menu.querySelector('[data-project-menu="delete"]').onclick=()=>{dismissMenu();modal('删除项目',`<p>删除「${esc(pr.name)}」及其画布？此操作不可撤销，已生成的本地文件保留。</p>`,'<button type="button" data-close>取消</button><button type="submit" class="primary">删除项目</button>');$('#dialogForm').onsubmit=async e=>{e.preventDefault();try{await api('/projects/'+projectId,'DELETE');closeModal();canvasUndo.delete(projectId);if(pid===projectId){pid=null;selected={type:'none'}}await refresh(true);notify('项目已删除')}catch(err){notify(err.message,true)}}};
});

$('#renameCanvas').onclick=()=>renameCanvas(pid);
$('#canvasTitle').ondblclick=()=>renameCanvas(pid);
