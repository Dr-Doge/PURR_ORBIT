function reusableActions(pr){return (pr.actions||[]).filter(a=>a.prompt?.trim()&&!(pr.deleted_nodes||[]).includes('action-'+a.id)&&(!pr.graph||pr.graph.nodes.includes('action-'+a.id)))}
function reuseAnimations(){
 const projects=state.projects.filter(pr=>reusableActions(pr).length);
 if(!projects.length)return notify('先制作一套动画，再用这个功能更换角色');
 const initial=projects.find(pr=>pr.id===pid)||projects[0];
 modal('换角色，生成同款动画',`<label class="field"><span>沿用哪一套动画？</span><select id="reuseSource">${projects.map(pr=>`<option value="${pr.id}" ${pr===initial?'selected':''}>${esc(pr.name)}</option>`).join('')}</select></label><div id="reuseActions"></div><label class="field"><span>上传新角色图片</span><input id="reuseFile" type="file" accept="image/png,image/jpeg,image/webp" required></label><label class="field"><span>新角色名称</span><input id="reuseName" placeholder="例如：白猫"></label><label class="checkfield"><input id="reuseProcess" type="checkbox" checked> 生成后自动去绿幕并导出 Sprite Sheet</label><p class="muted">复用勾选动作的指令、时长、模型和处理参数。外观以新图为准；不会复制旧视频和删帧记录。AI 动作可能略有差异。</p><p id="reuseCost" class="cost-note"></p><p id="reuseError" role="alert"></p>`, '<button type="button" data-close>取消</button><button type="submit" name="mode" value="prepare">只创建，稍后生成</button><button type="submit" name="mode" value="generate" class="primary">生成同款动画</button>');
 const updateCount=()=>{const count=$$('#reuseActions input:checked').length;$('#reuseCost').textContent=`点击生成将提交 ${count} 个收费视频任务，每个原始视频4秒；之后按各动作时长截取。`};
 const update=()=>{const pr=projects.find(pr=>pr.id===$('#reuseSource').value);$('#reuseActions').innerHTML=reusableActions(pr).map(a=>`<label class="checkfield"><input type="checkbox" value="${a.id}" checked> ${esc(a.name)} · ${a.options.duration}秒 · ${esc(videoModels[a.video_model||state.settings.video_model]||a.video_model||state.settings.video_model)}</label>`).join('');updateCount()};
 $('#reuseSource').onchange=update;$('#reuseActions').onchange=updateCount;update();
 let created=null,submitted=new Set();
 $('#dialogForm').onsubmit=async e=>{
  e.preventDefault();const generate=e.submitter?.value==='generate',ids=$$('#reuseActions input:checked').map(x=>x.value);
  if(!ids.length)return notify('至少选择一个动作',true);
  if(generate&&!state.connection.ark){$('#reuseError').textContent='Seedance 尚未配置。可先点“只创建，稍后生成”。';return}
  const controls=$$('#dialogForm button');controls.forEach(b=>b.disabled=true);
  try{
   if(!created){const data=new FormData();data.append('file',$('#reuseFile').files[0]);data.append('spec',JSON.stringify({name:$('#reuseName').value||$('#reuseFile').files[0].name.replace(/\.[^.]+$/,''),actions:ids}));created=await api('/projects/'+$('#reuseSource').value+'/reuse','POST',data)}
   if(generate){for(const act of reusableActions(created)){if(submitted.has(act.id))continue;await api('/actions/'+act.id+'/generate','POST',{auto_process:$('#reuseProcess').checked});submitted.add(act.id)}}
   pid=created.id;selected={type:'reference'};closeModal();await refresh(true);setView('canvas');fit();notify(generate?`已提交 ${submitted.size} 个动画任务`:'同款动画已创建，可检查后批量生成');
  }catch(err){
   if(created){pid=created.id;selected={type:'reference'};closeModal();await refresh(true);setView('canvas');fit();modal('部分任务尚未提交',`<p>${esc(err.message)}</p><p>新角色画布已保存，已提交 ${submitted.size} 个任务。请在任务队列检查状态，确认后使用顶部“批量生成”继续未提交的动作。</p>`,'<button type="button" data-close>知道了</button>');$('#dialogForm').onsubmit=e=>e.preventDefault()}
   else $('#reuseError').textContent=err.message;
  }finally{controls.forEach(b=>b.disabled=false)}
 };
}
$('#addImage').insertAdjacentHTML('beforebegin','<button id="reuseAnimations" title="换一张参考图，沿用上一套动作">换角色，生成同款动画</button>');
$('#reuseAnimations').onclick=reuseAnimations;
