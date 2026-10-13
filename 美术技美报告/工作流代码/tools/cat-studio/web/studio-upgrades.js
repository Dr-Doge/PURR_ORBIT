// Visible stages, reference directions and reversible local algorithm previews.
const directionLabels={side:'侧视图',up:'向上',down:'向下'};
const originalRender=render;
let speedRenderPending=false;
const speedSessions=new Set();
const cardSpeedTimers=new Set();
render=function(){
 if([...speedSessions].some(x=>x.project===pid)){speedRenderPending=true;return;}
 cardSpeedTimers.forEach(cancelAnimationFrame);cardSpeedTimers.clear();speedRenderPending=false;
 originalRender();const p=cat();if(!p)return;
 if(!portrait(p)){const drop=document.createElement('div');drop.className='project-drop';drop.innerHTML='<b>把角色图片拖到这里</b><small>或点击选择 · PNG / JPG / WebP · 每张最多25MB</small>';$('#character .hero').after(drop);bindImageDrop(drop,async files=>{drop.textContent='正在导入参考图…';try{await importProjectImages(p,files)}finally{await refresh();render()}});}
 $('#reference').textContent='参考图库 / 生图';$('#reference').onclick=safe(()=>referenceLibrary(p));
 const deck=document.createElement('div');deck.id='directionDeck';$('#character').append(deck);
 safe(async()=>{const refs=await api(`/studio/projects/${p.id}/references`);if(cat()?.id===p.id&&deck.isConnected)drawDirections(deck,p,refs)})();
 const tools=document.createElement('div');tools.className='row quality-toolbar';
 tools.innerHTML='<button id="motionAlgorithms">✦ 动画算法 · 连贯性 / 位置对齐</button><small>本地计算 → 前后预览 → 应用，原结果保留</small>';
 $('.section-heading').after(tools);$$('.quality-toolbar').slice(0,-1).forEach(x=>x.remove());
 $('#motionAlgorithms').onclick=()=>qualityForm(p);
 const exportLabel=document.createElement('label');exportLabel.className='export-size-choice';exportLabel.innerHTML='<input id="export320" type="checkbox" '+(localStorage.getItem('cat-export-320')==='true'?'checked':'')+'> 导出为每帧 320×320 <small>不勾选保持原尺寸</small>';tools.append(exportLabel);$('#export320').onchange=e=>localStorage.setItem('cat-export-320',String(e.target.checked));

 for(const a of motions(p)){
  const edit=$(`[data-edit="${a.id}"]`);if(!edit)continue;const card=edit.closest('.card');
  const rename=document.createElement('button');rename.className='rename-button';rename.textContent='✎ 改名';
  rename.onclick=()=>renameAction(p,a);card.querySelector('.card-head > span').replaceWith(rename);
  if(last(processor(p,a))){inlineSpeed(card,p,a);const link=card.querySelector('a[download]');if(link)link.onclick=safe(async e=>{if(localStorage.getItem('cat-export-320')!=='true')return;e.preventDefault();if(link.dataset.saving)return;link.dataset.saving='1';const label=link.textContent;link.textContent='正在导出320…';try{const ex=last(processor(p,a)),result=await api(`/studio/actions/${a.id}/export-sized`,'POST',{frame_size:320,export_id:ex.id});const download=document.createElement('a');download.href=result.url;download.download='spritesheet-320.zip';download.click()}finally{delete link.dataset.saving;link.textContent=label}});}
  const stages=document.createElement('div');stages.className='stage-buttons';
  stages.innerHTML=`<button data-stage="ref">① 参考图</button><button data-stage="video">② 原视频</button><button data-stage="edit">③ 透明处理</button><span>④ 导出 ↓</span>`;
  card.querySelector('.card-body').prepend(stages);
  stages.querySelector('[data-stage="ref"]').onclick=safe(()=>referenceLibrary(p));
  stages.querySelector('[data-stage="video"]').onclick=()=>videoDialog(p,a);
  stages.querySelector('[data-stage="edit"]').onclick=safe(()=>editor(p,a));
 }
};

function drawDirections(container,p,refs){
 container.innerHTML=`<div class="direction-grid">${Object.entries(directionLabels).map(([key,label])=>{const item=refs.slots[key];return `<section class="direction-card"><b>${label}</b><div class="direction-preview direction-drop" data-drop-direction="${key}">${item?.source?`<img src="${esc(item.source)}" alt="${label}参考图" draggable="false">`:'拖入图片，或点击上传'}<span class="direction-drop-hint">${item?.source?'拖入图片替换':'PNG / JPG / WebP'}</span></div><small>${esc(item?.name||'尚未设置')}</small><div class="row"><button data-upload-direction="${key}">${item?.source?'替换':'上传'}</button><button data-generate-direction="${key}">生图 / 编辑</button></div></section>`}).join('')}</div><small>每个方向独立保存。原有参考图可在「参考图库」查看、指定方向；动作使用哪张图可在「调整 / 对照」中选择。</small>`;
 container.querySelectorAll('[data-drop-direction]').forEach(zone=>{
  const direction=zone.dataset.dropDirection,label=directionLabels[direction];
  bindImageDrop(zone,async files=>{
   const hint=zone.querySelector('.direction-drop-hint'),oldHint=hint.textContent;
   const buttons=zone.closest('section').querySelectorAll('button');buttons.forEach(b=>b.disabled=true);hint.textContent='正在导入…';
   try{const data=new FormData();data.append('file',files[0]);await api(`/studio/projects/${p.id}/references/${direction}/upload`,'POST',data);await refresh();
    if(container.isConnected){if(container.id==='libraryDirections')await referenceLibrary(state.projects.find(x=>x.id===p.id)||p);else drawDirections(container,p,await api(`/studio/projects/${p.id}/references`));}
    toast(label+'参考图已保存');
   }finally{if(zone.isConnected){hint.textContent=oldHint;buttons.forEach(b=>b.disabled=false);}}
  },{multiple:false,label:label+'参考图：拖入图片或点击上传'});
 });
 container.querySelectorAll('[data-upload-direction]').forEach(b=>b.onclick=()=>upload('image/png,image/jpeg,image/webp',`/studio/projects/${p.id}/references/${b.dataset.uploadDirection}/upload`));
 container.querySelectorAll('[data-generate-direction]').forEach(b=>b.onclick=()=>imageForm(p,b.dataset.generateDirection,refs));
}
async function referenceLibrary(p){
 const refs=await api(`/studio/projects/${p.id}/references`);
 const images=[...(p.reference?[{id:'reference',name:'角色主图',source:p.reference}]:[]),...(p.images||[])];
 show(p.name+' / 三方向参考图库',`<div id="libraryDirections"></div><h3>已有参考图 · ${images.length} 张</h3><div class="reference-library">${images.map(i=>`<section><div class="direction-preview">${i.source?`<a href="${esc(i.source)}" target="_blank"><img src="${esc(i.source)}" alt="${esc(i.name)}"></a>`:'暂无图片'}</div><b>${esc(i.name)}</b><div class="row">${Object.entries(directionLabels).map(([key,label])=>`<button data-bind-image="${i.id}" data-direction="${key}">设为${label}</button>`).join('')}</div></section>`).join('')}</div>`);
 drawDirections($('#libraryDirections'),p,refs);
 $$('[data-bind-image]').forEach(b=>b.onclick=safe(async()=>{await api(`/studio/projects/${p.id}/references/${b.dataset.direction}`,'POST',{image_id:b.dataset.bindImage});await refresh();await referenceLibrary(cat());toast('方向参考已设置；已有动作仍保留原参考图，可单独调整')}));
}
function imageForm(p,direction,refs){
 const images=[...(p.reference?[{id:'reference',name:'角色主图',source:p.reference}]:[]),...(p.images||[])].filter(x=>x.source);
 const current=refs.slots[direction]?.id;
 show(p.name+' / '+directionLabels[direction]+' · 生图与编辑',`<form id="imageGenerateForm"><p class="notice">生成结果保存到「${directionLabels[direction]}」槽位，旧图片保留在历史记录中。此操作使用 OpenAI 图像模型额度，不会自动生成动作视频。</p><label class="field">使用哪张图片保持角色外观<select name="reference_id"><option value="">不使用参考图 · 纯文本生图</option>${images.map(i=>`<option value="${i.id}" ${i.id===current?'selected':''}>${esc(i.name)}</option>`).join('')}</select></label><label class="field">图片描述<textarea name="prompt" required placeholder="例如：保持同一只猫的花纹和像素风格，制作清晰的背面站姿，完整显示四肢与尾巴。"></textarea></label><p class="muted">模型：${esc(state.settings.image_model)} · OpenAI：${state.connection.openai?'已配置':'待配置，请先打开连接设置'}</p><label><input name="paid" type="checkbox" required> 确认使用模型额度生成 1 张图片</label><div class="actions"><button class="primary">生成${directionLabels[direction]}</button></div></form>`);
 $('#imageGenerateForm').onsubmit=safe(async e=>{e.preventDefault();const b=e.submitter;b.disabled=true;try{const f=new FormData(e.target);await api(`/studio/projects/${p.id}/references/${direction}/generate`,'POST',{prompt:f.get('prompt'),reference_id:f.get('reference_id'),paid_confirmed:f.has('paid')});close();await refresh();toast('已提交生图，可在任务队列查看进度')}catch(err){b.disabled=false;throw err}});
}
function renameAction(p,a){
 show('修改动作名称',`<form id="renameForm"><label class="field">${esc(p.name)} 的动作名称<input name="name" maxlength="60" value="${esc(a.name)}" required></label><p class="muted">同步更新动作卡片、处理记录，以及当前导出包中的动画名称；不重新生成视频。</p><div class="actions"><button class="primary">保存名称</button></div></form>`);
 $('#renameForm').onsubmit=safe(async e=>{e.preventDefault();e.submitter.disabled=true;try{await api(`/studio/actions/${a.id}/rename`,'POST',{name:new FormData(e.target).get('name')});close();await refresh();toast('名称已保存，已有导出包在后台同步更新')}catch(err){e.submitter.disabled=false;throw err}});
}
function videoDialog(p,a){
 const ex=last(processor(p,a));
 show(p.name+' / '+a.name+' · 原视频',`<div class="video-compare"><section><h3>原视频 · 独立播放</h3>${a.video?`<video src="${esc(a.video)}" controls loop playsinline preload="metadata"></video><a href="${esc(a.video)}" target="_blank">在新标签打开视频 ↗</a>`:'<p>尚无视频，可导入已有视频或在动作卡片制作。</p>'}</section><section><h3>当前透明动画</h3>${ex?`<div class="preview"><img src="${ex.base}/preview.png" alt="当前透明动画"></div><p>${ex.meta.frame_count} 帧 · ${Number(ex.meta.fps).toFixed(1)} FPS</p>`:'尚无透明结果'}</section></div><div class="actions"><button id="videoImport">导入视频</button><button id="videoEditor" class="primary">打开同步逐帧对照</button></div>`);
 $('#videoImport').onclick=()=>upload('video/*',`/actions/${a.id}/video`);$('#videoEditor').onclick=safe(()=>editor(p,a));
}
$('#settings').onclick=()=>{
 show('模型连接设置',`<form id="modelForm"><p class="notice">留空保留已有密钥。视频和生图分别使用各自的模型额度。</p><div class="fields"><label class="field">ARK API Key · ${state.connection.ark?'已配置':'待配置'}<input name="ark_key" type="password" autocomplete="off"></label><label class="field">OpenAI API Key · ${state.connection.openai?'已配置':'待配置'}<input name="openai_key" type="password" autocomplete="off"></label></div><label class="field">视频模型<input name="video_model" value="${esc(state.settings.video_model)}" required></label><label class="field">图像模型<input name="image_model" value="${esc(state.settings.image_model)}" required></label><div class="actions"><button class="primary">保存连接</button></div></form>`);
 $('#modelForm').onsubmit=safe(async e=>{e.preventDefault();await api('/settings','POST',Object.fromEntries(new FormData(e.target)));close();await refresh();toast('连接设置已保存')});
};

function qualityForm(p){
 const list=motions(p).filter(a=>last(processor(p,a)));
 show(p.name+' / 动画算法',`<form id="qualityForm"><label class="field">优化项目<select name="mode" id="qualityMode"><option value="continuity">连贯性优化 · 原视频密集抽帧 / 循环接缝</option><option value="alignment">跨动作位置对齐 · 统一画布与基准点</option></select></label><div class="notice" id="qualityExplain"></div><div id="temporalOptions"><label><input type="checkbox" name="walk_five" id="walkFive"> 5 帧走路 · 从视频前4秒寻找约1秒的完整步态</label><p class="muted">固定输出5帧，比较全部相邻姿势及第5帧回第1帧；适合约1秒重复的走路视频，播放速度随选中的周期匹配。</p><label><input type="checkbox" name="loop"> 优化循环接缝：允许微调片段首尾（不改变原有循环播放设置）</label><p class="muted">不勾选时完整保留当前片段，原来循环的动作仍会循环播放。重新取帧会恢复手动排除的源帧；不会创造缺失的中间动作。</p></div><div id="alignOptions" hidden><div class="fields"><label class="field">统一画布尺寸<select name="size"><option>128</option><option selected>256</option><option>512</option><option>1024</option></select></label><label><input type="checkbox" name="normalize"> 同时统一基准姿势高度</label></div><p class="muted">为每个动作选择站立/落地的基准帧（从1开始）。整段采用同一个位移，保留跳跃起伏；统一高度仅适合各动作基准帧姿势相近时使用。排序最前的勾选动作为尺寸基准。</p></div><div class="quality-selection">${list.map(a=>{const ex=last(processor(p,a));return `<label class="batch-row"><input data-quality-id="${a.id}" type="checkbox" ${picked.size?picked.has(a.id)?'checked':'':'checked'}><img src="${ex.base}/frames/000.png" alt="${esc(a.name)}首帧"><span class="grow"><b>${esc(a.name)}</b><small style="display:block">${ex.meta.frame_count} 帧 / ${Number(ex.meta.fps).toFixed(1)} FPS</small></span><span class="anchor-input">基准帧 <input data-anchor="${a.id}" type="number" value="1" min="1" max="${ex.meta.frame_count}"></span></label>`}).join('')||'<p>请先完成至少一个动作的透明处理。</p>'}</div><div class="actions"><button class="primary" ${!list.length?'disabled':''}>生成算法对照 · 免费</button></div></form>`);
 const update=()=>{const align=$('#qualityMode').value==='alignment';$('#alignOptions').hidden=!align;$('#temporalOptions').hidden=align;$$('.anchor-input').forEach(x=>x.hidden=!align);$('#qualityExplain').textContent=align?'选择同一只猫需要衔接的动作。根据基准帧的主体底部中心对齐，共用一个画布和缩放空间，避免逐动作裁框造成切换跳位。':'重新从当前片段提取最多20 FPS的真实视频帧，避免低帧数抽样造成跳帧。循环模式会结合首尾姿势和运动方向寻找接缝，最多裁掉35%的片段。所有结果先预览，不直接覆盖。'};$('#qualityMode').onchange=update;update();$('#walkFive').onchange=()=>{const loop=$('#qualityForm input[name=loop]');loop.disabled=$('#walkFive').checked;update();if($('#walkFive').checked)$('#qualityExplain').textContent='扫描视频前4秒，在约0.8–1.2秒的步态中选择5个顺序姿势；同时比较相邻帧和首尾接缝，避免挑中静止片段。固定输出5帧，保留原循环设置。';};
 $('#qualityForm').onsubmit=safe(async e=>{e.preventDefault();const f=new FormData(e.target),items=$$('[data-quality-id]:checked').map(x=>({id:x.dataset.qualityId,anchor:Number($(`[data-anchor="${x.dataset.qualityId}"]`).value)-1}));if(!items.length)return toast('请选择需要处理的动作');const button=e.submitter;button.disabled=true;try{const j=await api(`/studio/projects/${p.id}/quality-preview`,'POST',{mode:f.get('mode'),items,loop:f.has('loop'),walk_five:f.has('walk_five'),normalize:f.has('normalize'),size:Number(f.get('size'))});qualityProgress(p,j.id)}catch(err){button.disabled=false;throw err}});
 $$('[data-anchor]').forEach(input=>input.oninput=()=>{const a=list.find(a=>a.id===input.dataset.anchor),ex=last(processor(p,a)),index=Number(input.value)-1;if(Number.isInteger(index)&&index>=0&&index<ex.meta.frame_count)input.closest('.batch-row').querySelector('img').src=ex.base+'/frames/'+String(index).padStart(3,'0')+'.png'});
 const pending=state.jobs.filter(j=>j.project===p.id&&j.kind==='quality-preview'&&!j.applied&&j.status==='done'&&j.candidates).slice(0,5);
 for(const job of pending){const b=document.createElement('button');b.textContent=`查看未应用预览 · ${job.quality_mode==='alignment'?'位置对齐':'连贯性'} · ${new Date(job.created*1000).toLocaleTimeString()}`;b.onclick=()=>qualityResults(p,job);$('#dialogBody').prepend(b)}
}
function qualityProgress(p,id){
 show('算法正在本地处理','<p id="qualityProgress" class="notice">正在准备源素材…</p><p class="muted">可以关闭窗口，后台任务会继续。完成后在「动画算法」里查看未应用的预览。</p>');
 const marker=$('#qualityProgress');
 const poll=safe(async()=>{const next=await api('/state'),j=next.jobs.find(x=>x.id===id);if(!marker.isConnected)return;if(!j)throw Error('找不到算法任务');marker.textContent=j.message;if(j.status==='done'){await refresh();qualityResults(p,j)}else if(j.status==='failed'||j.status==='interrupted'){marker.textContent='处理未完成：'+j.message}else setTimeout(poll,1200)});poll();
}
function reportText(c,mode){
 const m=c.after.meta;
 if(mode==='alignment')return `统一到 ${m.frame_width}px；基准点 ${m.alignment_report.origin.map(x=>Math.round(x)).join(', ')}。每个动作整段平移，原有位移保留。`;
 const r=m.continuity_report;return `${c.before.meta.frame_count} → ${m.frame_count} 帧，${Number(m.fps).toFixed(1)} FPS。${r.algorithm==='five-phase-walk-v1'?`已选取 ${r.cycle_seconds.toFixed(2)} 秒的5相位步态。`:r.trimmed?'已微调循环片段首尾。':'保留所选片段。'} 首尾差异 ${(100*(r.previous_export?.seam||0)).toFixed(1)}% → ${(100*r.after.seam).toFixed(1)}%（越低越接近，仍需检查动作）。相邻近似重复帧 ${r.after.near_duplicate_pairs} 对。${(m.warnings||[]).map(esc).join('；')}`;
}
function qualityResults(p,j){
 show('算法预览 · '+p.name,`<p class="notice">预览持续循环，方便对照；导出保留动作原有的循环设置。先检查结果，再应用，原始导出保留在历史版本中。${j.quality_mode==='alignment'?'点「同步对照 / 切换动作」在同一画布切换，检查位置衔接。':'密集取帧无法修复模型已经生成的错误肢体或缺失动作。'}</p><div class="quality-results">${j.candidates.map((c,i)=>`<section><h3>${esc(c.name)}</h3><div class="compare-pair"><div><small>当前结果</small><div class="preview"><img src="${c.before.base}/preview.png" alt="${esc(c.name)}优化前"></div></div><div><small>算法预览</small><div class="preview"><img src="${c.after.base}/preview.png" alt="${esc(c.name)}优化后"></div></div></div><p class="muted">${reportText(c,j.quality_mode)}</p><button data-quality-compare="${i}">同步对照 / 切换动作</button></section>`).join('')}</div><div class="actions"><button id="applyQuality" class="primary" ${j.applied?'disabled':''}>${j.applied?'已应用':'应用这批结果'}</button></div>`);
 $$('[data-quality-compare]').forEach(b=>b.onclick=safe(()=>qualityCompare(p,j,Number(b.dataset.qualityCompare))));
 $('#applyQuality').onclick=safe(async e=>{e.target.disabled=true;try{await api(`/studio/projects/${p.id}/quality-apply`,'POST',{job:j.id});close();await refresh();toast('算法结果已应用；可在动作历史中恢复')}catch(err){e.target.disabled=false;throw err}});
}
async function qualityCompare(p,j,index){
 const c=j.candidates[index];show('算法同步对照 / '+c.name,`<label class="field">切换动作<select id="compareAction">${j.candidates.map((x,i)=>`<option value="${i}" ${i===index?'selected':''}>${esc(x.name)}</option>`).join('')}</select></label><div class="compare-pair"><section><h3>处理前</h3><canvas id="qualityBefore" width="512" height="512"></canvas></section><section><h3>处理后</h3><canvas id="qualityAfter" width="512" height="512"></canvas></section></div><input id="qualityScrub" class="timeline" type="range" min="0" max="1000" value="0"><p id="qualityFrame" class="muted">正在加载帧…</p><div class="row"><button id="qualityPlay" disabled>播放</button><button id="backResults">返回结果 / 应用</button></div><p class="notice">${reportText(c,j.quality_mode)}</p>`);
 const marker=$('#qualityBefore');let progress=0,playing=false;
 $('#compareAction').onchange=safe(e=>qualityCompare(p,j,Number(e.target.value)));$('#backResults').onclick=()=>qualityResults(p,j);
 const load=ex=>Promise.all(Array.from({length:ex.meta.frame_count},(_,i)=>new Promise((res,rej)=>{const im=new Image();im.onload=()=>res(im);im.onerror=()=>rej(Error('预览帧读取失败'));im.src=ex.base+'/frames/'+String(i).padStart(3,'0')+'.png'})));
 const [before,after]=await Promise.all([load(c.before),load(c.after)]);if(!marker.isConnected)return;
 const draw=()=>{for(const [id,arr] of [['qualityBefore',before],['qualityAfter',after]]){const cv=$('#'+id),ctx=cv.getContext('2d'),im=arr[Math.min(arr.length-1,Math.floor(progress*arr.length))];ctx.clearRect(0,0,512,512);ctx.imageSmoothingEnabled=false;ctx.drawImage(im,0,0,512,512);ctx.strokeStyle='#d89937';ctx.beginPath();ctx.moveTo(256,0);ctx.lineTo(256,512);ctx.stroke();}$('#qualityScrub').value=Math.round(progress*1000);$('#qualityFrame').textContent=`片段进度 ${Math.round(progress*100)}% · 前 ${Math.floor(progress*before.length)+1}/${before.length} 帧 · 后 ${Math.floor(progress*after.length)+1}/${after.length} 帧`;};
 $('#qualityPlay').disabled=false;$('#qualityPlay').onclick=()=>{playing=!playing;$('#qualityPlay').textContent=playing?'暂停':'播放'};$('#qualityScrub').oninput=()=>{playing=false;$('#qualityPlay').textContent='播放';progress=Math.min(.999,Number($('#qualityScrub').value)/1000);draw()};draw();
 const duration=c.after.meta.duration;previewTimer=setInterval(()=>{if(playing&&marker.isConnected){progress=(progress+.04/duration)%1;draw()}},40);
}
if(cat())render();

async function speedDialog(p,a){
 const ex=last(processor(p,a)),initial=ex.meta.fps;
 show(a.name+' / 播放速度',`<canvas id="speedPreview" width="320" height="320" style="display:block;margin:auto;background:#303640;max-width:100%"></canvas><form id="speedForm"><label class="field">播放速度 / FPS<input id="speedFps" name="fps" type="number" min="0.1" max="120" step="any" value="${initial}" required></label><div class="row">${[.5,1,1.5,2].map(x=>`<button type="button" data-speed="${x}">${x}×</button>`).join('')}</div><p id="speedInfo" class="notice"></p><p class="muted">数值越大播放越快。上方实时预览动画速度，保存后同步更新预览与导出包；帧数与画面保持不变，旧版本保留。</p><div class="actions"><button class="primary" id="saveSpeed" disabled>保存播放速度</button></div></form>`);
 const canvas=$('#speedPreview'),input=$('#speedFps'),info=$('#speedInfo');let frames=[],frame=0;
 const draw=()=>{const ctx=canvas.getContext('2d'),im=frames[frame];if(!im)return;ctx.clearRect(0,0,320,320);ctx.imageSmoothingEnabled=false;const scale=Math.min(320/im.width,320/im.height);ctx.drawImage(im,(320-im.width*scale)/2,(320-im.height*scale)/2,im.width*scale,im.height*scale)};
 const update=()=>{clearInterval(previewTimer);const fps=Number(input.value),valid=input.validity.valid&&fps>=.1&&fps<=120;$('#saveSpeed').disabled=!valid||!frames.length;info.textContent=valid?`${ex.meta.frame_count} 帧 · 每轮 ${(ex.meta.frame_count/fps).toFixed(2)} 秒 · ${(fps/initial).toFixed(2)}× 当前速度`:'请输入0.1–120 FPS';if(valid&&frames.length)previewTimer=setInterval(()=>{frame=(frame+1)%frames.length;draw()},1000/fps)};
 input.oninput=update;$$('[data-speed]').forEach(b=>b.onclick=()=>{input.value=Number((initial*Number(b.dataset.speed)).toFixed(3));update()});update();
 $('#speedForm').onsubmit=safe(async e=>{e.preventDefault();$('#saveSpeed').disabled=true;try{await api(`/studio/actions/${a.id}/speed`,'POST',{fps:Number(input.value),export_id:ex.id});close();await refresh();toast('速度已提交，预览与导出包正在更新')}catch(err){update();throw err}});
 frames=await Promise.all(Array.from({length:ex.meta.frame_count},(_,i)=>new Promise((resolve,reject)=>{const im=new Image();im.onload=()=>resolve(im);im.onerror=()=>reject(Error('预览帧加载失败'));im.src=ex.base+'/frames/'+String(i).padStart(3,'0')+'.png'})));
 if(!canvas.isConnected)return;draw();update();
}

function inlineSpeed(card,p,a){
 let ex=last(processor(p,a)),saved=ex.meta.fps,fps=saved;
 const preview=card.querySelector('.preview'),control=document.createElement('div');control.className='speed-control';
 const blocked=busy(p,a)||state.jobs.some(j=>['queued','running'].includes(j.status)&&j.quality_actions?.includes(a.id));
 control.innerHTML=`<label for="speed-${a.id}">播放速度 <output></output></label><input id="speed-${a.id}" aria-label="${esc(a.name)}播放速度" type="range" min="0" max="1000" step="1" ${blocked?'disabled':''}><small>${blocked?'处理中…':'慢 ← 拖动调整 → 快 · 自动保存'}</small>`;
 preview.after(control);const input=control.querySelector('input'),output=control.querySelector('output'),hint=control.querySelector('small');
 const encode=f=>1000*Math.log(f/.1)/Math.log(1200),decode=v=>Math.round(.1*Math.pow(1200,v/1000)*10)/10;
 input.value=encode(fps);let dragging=false,saving=false,saveTimer=null,loading=null,atlas=null,canvas=null,raf=null,phase=0,previous=0,shown=-1;
 const session={project:p.id};
 const hold=()=>speedSessions.add(session);
 const release=()=>{if(dragging||saving||saveTimer)return;speedSessions.delete(session);if(speedRenderPending&&!speedSessions.size){speedRenderPending=false;render()}};
 const describe=()=>{output.textContent=`${fps.toFixed(1)} FPS · ${(ex.meta.frame_count/fps).toFixed(2)}秒/轮`;input.setAttribute('aria-valuetext',`${fps.toFixed(1)} FPS`)};describe();
 const tick=now=>{cardSpeedTimers.delete(raf);if(!control.isConnected)return;
  if(previous)phase+=Math.min(now-previous,100)*fps/1000;previous=now;
  const index=Math.floor(phase)%ex.meta.frame_count;
  if(index!==shown){shown=index;const r=ex.meta.frames[index],ctx=canvas.getContext('2d');ctx.clearRect(0,0,canvas.width,canvas.height);ctx.drawImage(atlas,r.x,r.y,r.w,r.h,0,0,canvas.width,canvas.height)}
  raf=requestAnimationFrame(tick);cardSpeedTimers.add(raf);
 };
 // Decode one sheet before interaction instead of loading N individual frames on input.
 const prepare=()=>{if(loading)return loading;loading=new Promise((resolve,reject)=>{const im=new Image();im.onload=async()=>{try{await im.decode();atlas=im;resolve()}catch(e){reject(e)}};im.onerror=()=>reject(Error('预览加载失败'));im.src=ex.base+'/spritesheet.png'}).catch(e=>{loading=null;throw e});return loading};
 const live=async()=>{try{await prepare();if(!control.isConnected||canvas)return;canvas=document.createElement('canvas');canvas.width=Math.min(384,ex.meta.frame_width);canvas.height=Math.round(canvas.width*ex.meta.frame_height/ex.meta.frame_width);canvas.style.cssText='max-width:100%;max-height:100%;object-fit:contain;image-rendering:pixelated';canvas.getContext('2d').imageSmoothingEnabled=false;preview.replaceChildren(canvas);raf=requestAnimationFrame(tick);cardSpeedTimers.add(raf)}catch(err){toast(err.message)}};
 input.onpointerenter=()=>prepare().catch(()=>{});input.onfocus=()=>prepare().catch(()=>{});
 const observer=new IntersectionObserver(entries=>{if(entries.some(e=>e.isIntersecting)){observer.disconnect();prepare().catch(()=>{})}},{rootMargin:'150px'});observer.observe(control);
 const wait=ms=>new Promise(resolve=>setTimeout(resolve,ms));
 const save=async()=>{
  saveTimer=null;if(dragging||saving)return;hold();
  if(Math.abs(fps-saved)<.0001){release();return;}saving=true;const wanted=fps;
  hint.textContent='后台保存中，可继续拖动';
  try{
   const job=await api(`/studio/actions/${a.id}/speed`,'POST',{fps:wanted,export_id:ex.id});
   for(;;){await wait(600);const next=await api('/state'),j=next.jobs.find(x=>x.id===job.id);state=next;speedRenderPending=true;
    if(!j||['failed','interrupted'].includes(j.status))throw Error(j?.message||'保存任务丢失');
    if(j.status==='done'){const project=next.projects.find(x=>x.id===p.id),action=project?.actions.find(x=>x.id===a.id);ex=last(processor(project,action));saved=wanted;break;}
   }
   hint.textContent='已保存 · 拖动可继续调整';
  }catch(err){hint.textContent='保存失败，重新拖动可重试';toast(err.message);saving=false;release();return;}
  saving=false;
  if(Math.abs(fps-saved)>.0001){if(!dragging&&!saveTimer)saveTimer=setTimeout(save,450);}
  release();
 };
 const schedule=()=>{clearTimeout(saveTimer);hold();saveTimer=setTimeout(save,450)};
 input.onpointerdown=e=>{dragging=true;hold();clearTimeout(saveTimer);saveTimer=null;input.setPointerCapture(e.pointerId);live()};
 input.oninput=()=>{fps=decode(Number(input.value));describe();live();hint.textContent='实时预览 · 停止调整后自动保存';schedule()};
 const finish=()=>{dragging=false;schedule()};
 input.onpointerup=finish;input.onpointercancel=finish;input.onlostpointercapture=()=>{if(dragging)finish()};input.onchange=()=>{if(!dragging)schedule()};
 input.onblur=()=>{if(dragging)finish()};
}

function validateDropImages(files){
 const list=Array.from(files);if(!list.length)throw Error('请选择本地图片文件');
 if(list.length>20)throw Error('一次最多导入20张图片');
 for(const f of list){if(!/\.(png|jpe?g|webp)$/i.test(f.name))throw Error('请使用PNG、JPG或WebP图片');if(f.size>25*1024*1024)throw Error(f.name+' 超过25MB');}
 return list;
}
function bindImageDrop(zone,receive,options={}){
 zone.tabIndex=0;zone.setAttribute('role','button');zone.setAttribute('aria-label',options.label||'拖入或选择角色参考图片');let uploading=false,depth=0;
 const accept=safe(async files=>{if(uploading)return;const list=validateDropImages(files);if(options.multiple===false&&list.length!==1)throw Error('每个方向请拖入一张图片');uploading=true;zone.setAttribute('aria-busy','true');try{await receive(list)}finally{uploading=false;zone.removeAttribute('aria-busy')}});
 const select=()=>{if(uploading)return;const picker=document.createElement('input');picker.type='file';picker.accept='image/png,image/jpeg,image/webp';picker.multiple=options.multiple!==false;picker.onchange=()=>accept(picker.files);picker.click()};
 zone.onclick=select;zone.onkeydown=e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();select()}};
 zone.ondragenter=e=>{e.preventDefault();depth++;zone.classList.add('drag-over')};
 zone.ondragover=e=>{e.preventDefault();e.dataTransfer.dropEffect=uploading?'none':'copy'};
 zone.ondragleave=e=>{e.preventDefault();if(--depth<=0){depth=0;zone.classList.remove('drag-over')}};
 zone.ondrop=e=>{e.preventDefault();e.stopPropagation();depth=0;zone.classList.remove('drag-over');accept(e.dataTransfer.files)};
}
async function importProjectImages(p,files){
 let main=!!p.reference,count=0;
 try{for(const file of files){const data=new FormData();data.append('file',file);
  if(!main){await api(`/projects/${p.id}/reference`,'POST',data);main=true;}
  else{const node=await api(`/projects/${p.id}/images`,'POST',{name:file.name.replace(/\.[^.]+$/,'')});await api(`/projects/${p.id}/images/${node.id}/upload`,'POST',data);}
  count++;
 }}catch(err){throw Error(`已导入 ${count} 张；${err.message}`)}
 toast(`已导入 ${count} 张参考图；可在参考图库指定方向`);
}
$('#addCat').onclick=()=>{
 show('添加猫咪',`<form id="catForm"><label class="field">猫咪名称<input name="name" required placeholder="例如：橘猫 · 团子"></label><div class="project-drop" id="newProjectDrop"><b>把图片拖到这里，创建时一起导入</b><small>也可点击选择 · 支持多张 · 第一张作为角色主图</small></div><p id="newImageList" class="muted"></p><div class="actions"><button class="primary">创建猫咪</button></div></form>`);
 let files=[],created=null;
 bindImageDrop($('#newProjectDrop'),async chosen=>{files=chosen;$('#newImageList').textContent=chosen.map(x=>x.name).join('、');const name=$('#catForm input[name=name]');if(!name.value.trim())name.value=chosen[0].name.replace(/\.[^.]+$/,'');});
 $('#catForm').onsubmit=safe(async e=>{e.preventDefault();const button=e.submitter;button.disabled=true;button.textContent='正在创建…';try{created=created||await api('/projects','POST',{name:new FormData(e.target).get('name')});pid=created.id;localStorage.setItem('cat-studio-cat',pid);if(files.length)await importProjectImages(created,files);close();await refresh()}catch(err){if(created){close();await refresh();render();}throw err}finally{button.disabled=false;button.textContent='创建猫咪'}});
};
// A missed drop must not navigate away from the project to the local image.
document.addEventListener('dragover',e=>{if(Array.from(e.dataTransfer.types).includes('Files'))e.preventDefault()});
document.addEventListener('drop',e=>{if(Array.from(e.dataTransfer.types).includes('Files'))e.preventDefault()});

async function reuseProjectActions(target,host=null){
 const sources=state.projects.filter(p=>p.id!==target.id&&motions(p).length),refs=await api(`/studio/projects/${target.id}/references`);
 const choices=[...(target.reference?[{node:'reference',name:'角色主图'}]:[]),...(target.images||[]).filter(x=>x.source).map(x=>({node:'image-'+x.id,name:x.name}))];
 if(host&&!host.isConnected)return;
 const empty=!sources.length?'其他项目还没有可沿用的动作':!choices.length?'请先为这只猫拖入参考图，再沿用项目动作':null;
 if(empty){if(host)host.textContent=empty;else toast(empty);return;}
 const display=html=>host?host.innerHTML=html:show(target.name+' / 沿用项目动作',html);
 display(`<p class="notice">选择旧项目的动作，在下方为新猫调整描述、帧数和参考图。导入的是动作配置；使用新猫的图片重新生成。已导入的同一来源动作会跳过。</p><label class="field">沿用哪套动作<select id="reuseSource">${sources.map(p=>`<option value="${p.id}">${esc(p.name)}</option>`).join('')}</select></label><form id="reuseForm"><div id="reuseRows"></div><div class="actions"><button type="submit" value="import">仅导入动作</button><button type="submit" value="batch" class="primary">导入并进入批量生成</button></div></form>`);
 const draw=()=>{const source=sources.find(p=>p.id===$('#reuseSource').value);$('#reuseRows').innerHTML=motions(source).map(a=>{
  const sourceNode=source.graph?.edges.find(e=>e.to==='action-'+a.id)?.from;
  const image=source.images?.find(i=>'image-'+i.id===sourceNode);
  const text=a.name+' '+(image?.name||'');
  const direction=Object.keys(directionLabels).find(k=>source.direction_images?.[k]&&(source.direction_images[k]==='reference'?'reference':'image-'+source.direction_images[k])===sourceNode)||(/下|down/i.test(text)?'down':/上|up|背面/i.test(text)?'up':/侧|side/i.test(text)?'side':null);
  const slot=direction&&refs.slots[direction],node=slot?.source?(slot.id==='reference'?'reference':'image-'+slot.id):choices.length===1?choices[0].node:'';
  const proc=processor(source,a),count=proc.options.target_frame_count||last(proc)?.meta.frame_count||20;
  const existing=motions(target).some(x=>x.reused_from?.project===source.id&&x.reused_from?.action===a.id);
  return `<section class="batch-cat" data-reuse-row="${a.id}"><label><input type="checkbox" data-reuse-check ${existing?'disabled':'checked'}> ${esc(a.name)} ${existing?'（已导入）':''}</label><div class="fields"><label class="field">动作名称<input data-reuse-name value="${esc(a.name)}" maxlength="60"></label><label class="field">新猫参考图<select data-reuse-ref><option value="">请选择对应参考图</option>${choices.map(x=>`<option value="${x.node}" ${x.node===node?'selected':''}>${esc(x.name)}</option>`).join('')}</select></label><label class="field">输出帧数<input data-reuse-count type="number" min="1" max="120" value="${count}"></label></div><details><summary>查看 / 修改动作描述</summary><textarea data-reuse-prompt style="width:100%;min-height:140px">${esc(a.prompt)}</textarea></details></section>`;
 }).join('')};$('#reuseSource').onchange=draw;draw();
 $('#reuseForm').onsubmit=safe(async e=>{e.preventDefault();const items=$$('[data-reuse-row]').filter(x=>x.querySelector('[data-reuse-check]').checked&&!x.querySelector('[data-reuse-check]').disabled).map(x=>({id:x.dataset.reuseRow,name:x.querySelector('[data-reuse-name]').value,prompt:x.querySelector('[data-reuse-prompt]').value,reference_node:x.querySelector('[data-reuse-ref]').value,frame_count:Number(x.querySelector('[data-reuse-count]').value)}));
  if(!items.length)return toast('请选择尚未导入的动作');if(items.some(x=>!x.reference_node))return toast('请为每个勾选动作指定新猫的参考图');
  const button=e.submitter;button.disabled=true;try{const result=await api(`/studio/projects/${target.id}/reuse-actions`,'POST',{source_project:$('#reuseSource').value,items});await refresh();const ids=result.results.filter(x=>x.status==='created').map(x=>x.id);if(button.value==='batch'&&ids.length)batchDialog(ids);else{close();toast(`已导入 ${ids.length} 个动作，可分别修改或批量制作`)}}catch(err){button.disabled=false;throw err}
 });
}
const existingBatchDialog=batchDialog;
batchDialog=function(ids=null,regenerate=false){existingBatchDialog(ids,regenerate);if(!ids&&cat()){const b=document.createElement('button');b.textContent='为当前猫沿用旧项目动作';b.onclick=()=>addMotionDialog('batch');$('#dialogBody').prepend(b)}};
