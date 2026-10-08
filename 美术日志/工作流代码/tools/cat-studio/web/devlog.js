function defaultDeveloperLog(){
 return `<article class="developer-log">
 <p class="devlog-date">FrameStudio · 动画资产工作台 · 更新于 2026 年 9 月 23 日</p>
 <section><h3>01 · 开发者说明</h3><p>此画布为单独一人制作。可能会有很多问题，后续会进行调试。</p><p>如果遇到问题，可以记录操作步骤、报错提示和截图，方便后续定位与修复。</p></section>
 <section><h3>02 · 目前加入的功能</h3><ul>
 <li><b>图片制作：</b>文字生图、参考图编辑、制作绿幕背景；支持上传图片、复制图片后粘贴到画布，以及 Image 连接 Image 继续生成。</li>
 <li><b>视频制作：</b>参考图连接 Seedance，选择视频模型并填写动作指令；支持拖入已有视频，直接下载图片和视频。</li>
 <li><b>透明动画与 Sprite Sheet：</b>去绿幕、抽帧、统一裁框、预览和筛选帧，导出透明精灵图、PNG 序列与 Godot 动画配置。一键制作前可填写总帧数并选择去绿幕强度。</li>
 <li><b>动画批量制作：</b>多个参考图接入同一个接口，也可批量上传。复用已有动作指令，在明细表中取消单项或单独填写总帧数；服务器依次处理，结果按角色分组，可展开继续编辑。</li>
 <li><b>精灵图改造：</b>导入现有 Sprite Sheet，连接外观参考图并填写提示词，制作新版精灵图。AI 生成的动作和外观仍需检查。</li>
 <li><b>画布操作：</b>拖动与缩放、自由连线、剪断连接、拉线新建兼容模块、框选、整体移动、复制粘贴、跨项目画布粘贴、多选删除和撤销。</li>
 <li><b>素材示例与任务管理：</b>招财猫、巨型猫示例工作流；任务进度、批量继续与重试、项目自动保存、右键改名与删除。</li>
 </ul></section>
 <section><h3>03 · 操作方式介绍</h3>
 <h4>完成一套动画</h4><ol>
 <li>创建或选择项目，添加 Image，上传、粘贴或生成参考图。</li>
 <li>从模块右侧输出点拖线到下游输入点；也可拖到空白处松开，选择新模块，自动创建并连接。</li>
 <li>在视频模块填写动作指令，展开右上角「⋯」选择模型及操作。已有视频可以直接拖入画布。</li>
 <li>点击「一键生成 Sprite Sheet」，填写整张精灵图的总帧数并选择去绿幕强度，确认后运行。有视频时直接处理，没有视频时先生成。</li>
 <li>查看透明动画、调整或删减帧，然后下载 Sprite Sheet 或游戏素材包。</li>
 </ol>
 <h4>一次制作多个角色</h4><ol>
 <li>添加「动画批量制作」，将多个 Image 连入左侧图片参考接口，或一次上传多张参考图。</li>
 <li>选择「沿用哪套动作」，默认勾选可用动画；按动作填写 Sprite Sheet 总帧数，并设置统一去绿幕强度。</li>
 <li>展开明细表，按角色取消不需要的动作，或覆盖单项总帧数。确认实际任务数后点击生成。</li>
 <li>结果按角色分组；点击「展开流程」，继续编辑视频、透明帧处理和 Sprite Sheet。修改设置后需要重新运行对应步骤，结果才会更新。</li>
 </ol><p class="hint-box">批量任务开始后会固定本批参考图与设置。复用的是动作指令，并不保证不同角色的逐帧姿势完全相同。</p>
 <h4>画布快捷操作</h4><table><tbody>
 <tr><th>移动画布</th><td>在空白处按住左键或中键拖动。</td></tr>
 <tr><th>缩放</th><td>鼠标滚轮；点击「适应画布」查看整体。</td></tr>
 <tr><th>添加模块</th><td>空白处右键，或从输出接口拉线到空白处。</td></tr>
 <tr><th>更多选项</th><td>点击模块右上角「⋯」展开或收起。</td></tr>
 <tr><th>断开连线</th><td>鼠标移到线上，出现剪断提示后点击；也可右键接口断开其连接。</td></tr>
 <tr><th>框选 / 多选</th><td>点击「框选」，或 Shift + 左键拖出选框；Shift / Ctrl + 点击模块增减选择。</td></tr>
 <tr><th>整体移动</th><td>拖动任意一个选中的模块。</td></tr>
 <tr><th>复制 / 粘贴</th><td>Ctrl+C / Ctrl+V，保留组内连线；切换项目后也可粘贴。文本框内仍按普通文字操作。</td></tr>
 <tr><th>删除模块</th><td>选中后按 Delete 或 Backspace；支持多选。</td></tr>
 <tr><th>撤销</th><td>Ctrl+Z 撤销支持的画布操作，如移动、连线、粘贴和删除模块；刷新后撤销历史清空，不撤销已提交的生成任务。</td></tr>
 <tr><th>项目改名</th><td>左侧项目上右键，选择「改名」，填写新名称后保存。</td></tr>
 <tr><th>删除项目</th><td>左侧项目上右键，选择删除并确认；项目删除不能用 Ctrl+Z 恢复。</td></tr>
 </tbody></table></section>
 </article>`;
}
async function openDeveloperLog(){
 const opener=$('#developerLogBtn');opener.disabled=true;
 try{
  let saved=await api('/developer-log'),editing=false,draft=saved.content;
  const view=()=>{
   $('#dialogBody').innerHTML=saved.content===null?defaultDeveloperLog():`<article class="developer-log developer-log-text">${esc(saved.content)}</article>`;
   $('#dialogFooter').innerHTML='<button type="button" id="editDeveloperLog">编辑日志</button><button type="button" data-close>关闭</button>';
   $('#editDeveloperLog').onclick=()=>{
    if(draft===null)draft=$('#dialogBody .developer-log').innerText;
    editing=true;
    $('#dialogBody').innerHTML=`<label class="field"><span>日志内容（保存后所有访问此网站的人可见）</span><textarea id="developerLogEditor" maxlength="50000" required>${esc(draft)}</textarea></label><p id="developerLogError" role="alert"></p>`;
    $('#dialogFooter').innerHTML='<button type="button" id="cancelLogEdit">取消编辑</button><button type="submit" class="primary">保存日志</button>';
    $('#developerLogEditor').oninput=e=>{draft=e.target.value};
    $('#cancelLogEdit').onclick=()=>{editing=false;draft=saved.content;view()};
    $('#developerLogEditor').focus();
   };
  };
  modal('开发者日志','','',true);view();
  $('#dialogForm').onsubmit=async e=>{
   e.preventDefault();if(!editing)return;
   const button=$('#dialogForm button[type=submit]');if(button.disabled)return;
   const content=$('#developerLogEditor').value;if(!content.trim()){$('#developerLogError').textContent='日志内容不能为空';return}
   button.disabled=true;
   try{saved=await api('/developer-log','PUT',{content,revision:saved.revision});draft=saved.content;editing=false;view();notify('开发者日志已保存')}
   catch(err){$('#developerLogError').textContent=err.message;button.disabled=false}
  };
 }catch(err){notify('无法打开开发者日志：'+err.message,true)}finally{opener.disabled=false}
}
$('#developerLogBtn').onclick=openDeveloperLog;
