// Independent opt-in preview. Existing extraction settings and outputs are untouched.
function setupPixelStability(){
 for(const node of $$('#nodes .node')){
  let source=node.dataset.node,record;
  if(source.startsWith('process-'))record=a(source.slice(8));
  else if(source.startsWith('sheet-edit-'))record=sheet(source.slice(11));
  else if(node.classList.contains('export')){const data=spriteOutput(source);if(data){source=data.source;record=source.startsWith('process-')?a(source.slice(8)):sheet(source.slice(11))}}
  const extra=node.querySelector('.module-extra');
  if(!record||!extra||extra.querySelector('[data-pixel-stability]'))continue;
  const button=document.createElement('button');button.type='button';button.dataset.pixelStability='';button.textContent='像素稳定';button.disabled=!last(record);
  const projectId=pid;button.onclick=e=>{e.stopPropagation();openPixelStability(projectId,source,record)};extra.append(button);
  const running=state.jobs.find(j=>j.kind==='pixel-stability'&&j.project===projectId&&j.action===record.id&&['queued','running'].includes(j.status));
  if(running){const status=document.createElement('div');status.className='node-status running';status.textContent='◈ 正在生成像素稳定对照预览';node.querySelector('.node-body').append(status)}
 }
}
function openPixelStability(projectId,source,record){
 const original=last(record);if(!original)return;
 modal('像素稳定 · 独立预览',`<p class="muted">视频透明帧提取后默认应用：256、1×1 像素块、标准强度。这里可以额外预览、调整或恢复。保留动作时序与整体位置；粗网格可能减少五官细节，不能保证消除所有形变。</p><div class="field-row"><label class="field">输出尺寸<select id="psSize"><option>128</option><option selected>256</option><option>512</option></select></label><label class="field">像素块<select id="psCell"><option value="1" selected>1 × 1 · 默认</option><option value="2">2 × 2</option><option value="4">4 × 4 · 粗像素</option></select></label></div><label class="field">修复强度<select id="psStrength"><option value="gentle">保守</option><option value="standard" selected>标准（默认）</option></select></label><div class="frame-controls"><button type="button" id="psPreview">生成对照预览</button><button type="button" id="psApply" disabled>应用到当前导出</button>${original.meta.pixel_restore_id?'<button type="button" id="psRestore">恢复处理前结果</button>':''}</div><p id="psStatus">未应用，不会改变现有结果。</p><div class="pixel-compare"><section><b>处理前</b><canvas id="psBefore" width="256" height="256"></canvas></section><section><b>处理后</b><canvas id="psAfter" width="256" height="256"></canvas></section></div><div class="frame-controls"><button type="button" id="psPlay">播放 / 暂停</button><input id="psFrame" aria-label="对照帧" type="range" min="0" max="${original.meta.frame_count-1}" value="0"><span id="psFrameLabel">1 / ${original.meta.frame_count}</span></div>`,'<button type="button" data-close>关闭</button>',true);
 const anchor=$('#psStatus'),apply=$('#psApply'),preview=$('#psPreview'),before=$('#psBefore'),after=$('#psAfter'),slider=$('#psFrame');
 let candidate=null,jobId=null,playing=true,index=0,imagesBefore=[],imagesAfter=[];
 const settingsBusy=value=>{for(const id of ['psSize','psCell','psStrength']){const el=$('#'+id);if(el)el.disabled=value}};
 const active=()=>anchor.isConnected&&$('#dialog').open;
 const load=base=>Promise.all(Array.from({length:original.meta.frame_count},(_,i)=>new Promise((resolve,reject)=>{const im=new Image();im.onload=()=>resolve(im);im.onerror=()=>reject(new Error('预览帧读取失败'));im.src=base+'/frames/'+String(i).padStart(3,'0')+'.png'})));
 function draw(){for(const [canvas,images] of [[before,imagesBefore],[after,imagesAfter]]){const ctx=canvas.getContext('2d');ctx.clearRect(0,0,256,256);ctx.imageSmoothingEnabled=false;if(images[index])ctx.drawImage(images[index],0,0,256,256)}slider.value=index;$('#psFrameLabel').textContent=`${index+1} / ${original.meta.frame_count}`}
 load(original.base).then(images=>{imagesBefore=images;if(active())draw()}).catch(e=>{if(active())anchor.textContent=e.message});
 const timer=setInterval(()=>{if(!active()){clearInterval(timer);return}if(playing){index=(index+1)%original.meta.frame_count;draw()}},1000/original.meta.fps);
 $('#psPlay').onclick=()=>{playing=!playing};slider.oninput=()=>{playing=false;index=Number(slider.value);draw()};
 async function poll(id){
  const result=await api('/state');if(!active())return;
  const job=result.jobs.find(j=>j.id===id);if(!job)throw new Error('找不到预览任务');
  if(job.status==='failed')throw new Error(job.message);
  if(job.status!=='done'){anchor.textContent=job.message;setTimeout(()=>{if(active())poll(id).catch(fail)},1000);return}
  candidate=job.candidate;jobId=id;imagesAfter=await load(candidate.base);if(!active())return;
  draw();apply.disabled=false;preview.disabled=false;settingsBusy(false);anchor.textContent=`预览完成：修正 ${candidate.meta.pixel_stability_report.corrected_cells} 个网格单元。请检查动作与细节，再决定是否应用。`;
 }
 function fail(e){if(active()){anchor.textContent=e.message;preview.disabled=false;settingsBusy(false)}}
 preview.onclick=async()=>{preview.disabled=true;apply.disabled=true;settingsBusy(true);try{const job=await api('/projects/'+projectId+'/pixel-stability','POST',{source,size:Number($('#psSize').value),cell:Number($('#psCell').value),strength:$('#psStrength').value});await poll(job.id)}catch(e){fail(e)}};
 apply.onclick=async()=>{apply.disabled=true;try{await api('/projects/'+projectId+'/pixel-stability','POST',{source,operation:'apply',job:jobId});$('#dialog').close();await refresh(true);notify('已应用像素稳定结果，可重新打开此功能恢复')}catch(e){fail(e)}};
 const restore=$('#psRestore');if(restore)restore.onclick=async()=>{restore.disabled=true;try{await api('/projects/'+projectId+'/pixel-stability','POST',{source,operation:'restore'});$('#dialog').close();await refresh(true);notify('已恢复处理前结果')}catch(e){fail(e);restore.disabled=false}};
 for(const id of ['psSize','psCell','psStrength'])$('#'+id).onchange=()=>{apply.disabled=true;anchor.textContent='设置已改变，请重新生成预览后应用。'};
 const previous=state.jobs.find(j=>j.kind==='pixel-stability'&&j.project===projectId&&j.action===record.id&&j.original?.id===original.id&&j.status!=='failed');
 if(previous){const report=previous.candidate?.meta.pixel_stability_report;if(report){$('#psSize').value=report.size;$('#psCell').value=report.cell;$('#psStrength').value=report.strength}preview.disabled=true;settingsBusy(true);poll(previous.id).catch(fail)}
}
