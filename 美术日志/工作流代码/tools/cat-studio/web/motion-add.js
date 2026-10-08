// Structured prompts follow the detailed static-cat workflow without copying its identity.
const motionRecipes={
 '待机':{seconds:2,action:'保持参考图中的站姿，仅有非常轻微的呼吸起伏和缓慢、小幅度的尾巴摆动。四脚固定在原地，不抬脚、不转身、不前进。身体比例不随呼吸膨胀。',face:'眼睛保持睁开，不眨眼，不改变表情；全程闭嘴。'},
 '走路':{seconds:1,action:'严格沿参考图朝向原地行走，四条腿交替迈步，明确区分近侧与远侧腿及重叠遮挡。完成支撑、抬脚、前摆、落地的连续步态，前后腿配合合理。身体只有轻微起伏，脚底接触地面时不滑动，角色不在画面中平移。',face:'眼睛保持睁开，表情稳定，全程闭嘴。'},
 '舔爪':{seconds:2,action:'保持坐姿，一只前爪缓慢抬向嘴边，头部轻轻靠近，短促舔爪后收回舌头并将前爪放回原位。其余三肢稳定支撑，头部和爪子不融合，爪子的大小、数量与连接关系稳定。',face:'只在舔爪接触时小幅张嘴、短暂露出舌尖，完成后闭嘴。鼻子与嘴巴保持独立，不打哈欠、不露出夸张牙齿。'},
 '趴睡':{seconds:2,action:'第一帧已经安静趴卧，四肢自然收拢，全程维持同一睡姿，仅有很轻微的呼吸。不要加入从站立趴下或醒来站起的过程；尾巴保持自然静置，不抽动。',face:'眼睛始终轻闭，眼皮形状稳定，闭嘴，不眨眼、不打哈欠。'},
 '翻肚皮':{seconds:2,action:'从侧卧开始，缓慢翻身露出肚皮，再沿原路径回到侧卧。身体与四肢作为一个连续结构转动，四爪自然弯曲，肚皮花纹随身体旋转保持连续。保持头尾方向，不翻滚离开原位。',face:'表情放松，眼睛轻眯，全程闭嘴，不改变鼻子形状。'},
 '跳跃':{seconds:2,action:'从稳定站姿开始，屈腿蓄力、四脚离地向上跳起、自然下落、屈腿缓冲，再恢复站姿。只沿竖直方向移动，不向左右漂移；保留真实离地高度，不把身体锁在地面。四脚落地顺序自然，身体不拉长、不穿地。',face:'眼睛保持睁开，全程闭嘴，表情稳定。'},
 '产毛 / 炸毛':{seconds:2,action:'从参考站姿开始，头部抬起、尾巴高举并小幅左右摇动，四脚保持落地。颈部、背部、身体两侧和尾巴上的毛束从贴伏逐渐向外竖起，形成蓬松、锯齿状的像素轮廓。只有外层毛束展开，头骨、躯干与四肢不膨胀。毛束始终连接在身体上，位置连续，不随机闪现，不脱落，不生成飞散毛屑、电弧、火花、烟雾或爆炸。后半段尾巴减速、毛束重新贴伏，头尾回到开始姿势。',face:'保持参考图眼睛、鼻子和胡须，闭嘴，不伸舌头、不喷出毛球。'},
 '被抚摸':{seconds:2,action:'第一帧已经低头、前半身压低、屁股高高撅起。全程保持这一舒服的姿势，仅让尾巴轻柔、连续地小幅左右摇晃。四脚落地，不加入从站姿低下或站回去的过程，不反复蹲起，不额外炸毛。画面中不出现抚摸它的人或手。',face:'眼睛轻轻眯着，表情不变化，闭嘴、不伸舌头。'},
 '休息 / 伸展':{seconds:2,action:'四脚保持落地，背部缓慢向上拱起，形成自然弧线，同时轻轻抬起尾巴；短暂舒展后背部慢慢放松、尾巴回落，回到开始姿势。动作舒缓，脚底不滑动，不跳跃、不前进、不快速摇尾，身体体积不膨胀。',face:'眼睛逐渐轻眯，放松时恢复开始状态。只改变眼皮形状，鼻子与胡须不变，全程闭嘴。'}
};
function detailedMotionPrompt(key){
 const r=motionRecipes[key];
 return `角色与画面要求：
画面中只有一只猫，外观、毛色、花纹、眼睛、鼻子、胡须和像素艺术风格严格保持所选参考图一致，不套用其他猫的特征。保持清晰块状像素，不变成平滑插画。每一帧使用一致的色板、曝光和光照，不闪烁、不随机增减细节。

镜头与朝向：
固定镜头，保持参考图的视角、朝向和角色比例，不推拉、不旋转镜头。朝上参考图始终保持背面，后脑勺不能长出脸或眼睛；朝下保持正面；侧视保持原侧向。除动作要求明确涉及身体翻转外，不主动转身。
背景始终是纯绿色 RGB(0,255,0)，没有阴影、文字、额外物品、人物或人手。

动作要求：
${r.action}

循环与节奏：
每 ${r.seconds} 秒完成一次完整循环，在 4 秒原视频中重复 ${4/r.seconds} 次相同步骤。首尾姿势、身体位置、四肢相位和尾巴摆动方向连续，完成后自然进入下一轮，不停住、不突然跳回第一帧，不重复插入静止画面。

面部约束：
${r.face}鼻子不能变成嘴巴，不新增眼睛、耳朵或五官；参考图没有的面部细节不添加。

肢体与遮挡：
始终只有四条腿和一条尾巴，关节、爪子、尾根连接稳定，前后遮挡合理。运动过程中不长出多余肢体，不融合、不穿插、不突然消失。

最高优先级：完整入镜与尾巴安全范围
完整猫体、耳尖、爪子、全部尾巴及毛尖在每一帧都处于画面内，边缘至少保留画幅 8% 的纯绿色安全距离。尾根固定，尾巴保持自然弯曲，不拉长、不甩成圆圈，不碰边或出框。宁可减小动作幅度，也不能截断身体或尾巴；全程保持同一角色比例，不靠缩放镜头隐藏出框。`;
}
Object.keys(motionRecipes).forEach(key=>templates[key]=detailedMotionPrompt(key));
function addMotionDialog(tab='single'){
 const p=cat();if(!p)return $('#addCat').click();
 show('为 '+p.name+' 添加动作',`<div class="motion-tabs" role="tablist" aria-label="添加动作方式"><button id="singleTab" role="tab" aria-controls="singleMotionPanel">单个动作</button><button id="batchTab" role="tab" aria-controls="batchMotionPanel">批量生成</button></div><section id="singleMotionPanel" role="tabpanel" aria-labelledby="singleTab"><p class="muted">选择模板填入完整描述，再按这只猫的特点修改。切换上方选项会保留当前填写内容。</p><div class="row" style="flex-wrap:wrap">${Object.keys(motionRecipes).map(k=>`<button type="button" data-detailed-template="${esc(k)}">${esc(k)}</button>`).join('')}</div><form id="motionForm" style="margin-top:20px">${refSelect(p)}<label class="field">动作名称<input name="name" id="motionName" required maxlength="60"></label><label class="field">专属动作描述<textarea name="prompt" id="motionPrompt" required style="min-height:320px"></textarea></label><div class="actions"><button class="primary">添加到这只猫</button></div></form></section><section id="batchMotionPanel" role="tabpanel" aria-labelledby="batchTab" hidden></section>`);
 let initialized=false;
 const select=async mode=>{for(const key of ['single','batch']){const active=key===mode;$('#'+key+'Tab').setAttribute('aria-selected',String(active));$('#'+key+'Tab').tabIndex=active?0:-1;$('#'+key+'MotionPanel').hidden=!active;}if(mode==='batch'&&!initialized){initialized=true;const host=$('#batchMotionPanel');host.textContent='正在加载旧项目动作…';try{await reuseProjectActions(p,host)}catch(err){initialized=false;if(host.isConnected)host.textContent=err.message;}}};
 $('#singleTab').onclick=()=>select('single');$('#batchTab').onclick=()=>select('batch');
 for(const key of ['single','batch'])$('#'+key+'Tab').onkeydown=e=>{if(['ArrowLeft','ArrowRight','Home','End'].includes(e.key)){e.preventDefault();const next=e.key==='Home'?'single':e.key==='End'?'batch':key==='single'?'batch':'single';select(next);$('#'+next+'Tab').focus()}};
 $$('[data-detailed-template]').forEach(b=>b.onclick=()=>{$('#motionName').value=b.dataset.detailedTemplate;$('#motionPrompt').value=detailedMotionPrompt(b.dataset.detailedTemplate)});
 $('#motionForm').onsubmit=safe(async e=>{e.preventDefault();const button=e.submitter;button.disabled=true;try{const f=new FormData(e.target);await api(`/studio/projects/${p.id}/actions`,'POST',{name:f.get('name'),prompt:f.get('prompt'),reference_node:f.get('reference_node')});close();await refresh()}catch(err){button.disabled=false;throw err}});
 select(tab);
}
$('#addMotion').onclick=()=>addMotionDialog();
