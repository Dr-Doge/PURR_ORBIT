from pathlib import Path
import base64, html
from PIL import Image

ROOT=Path(r'C:/Users/ruohaojing/Desktop/爽开')
OUT=ROOT/'地球盲盒考古/报告/GPT6_Astra实际使用报告_模型对比.html'
SHOTS=Path(r'C:/Users/ruohaojing/AppData/Roaming/Godot/app_userdata/blind-box-market')
PLAN=ROOT/'.report_work/earth_archaeology/render'
EA=ROOT/'地球盲盒考古/考古刮地皮/test_captures'
BEFORE=ROOT/'.report_work/astra_comparison'

def pic(path,caption,crop=None,phone=False):
    w,h=Image.open(path).size
    l,t,r,b=crop or (0,0,0,0)
    x,y,cw,ch=w*l/100000,h*t/100000,w*(100000-l-r)/100000,h*(100000-t-b)/100000
    src='data:image/png;base64,'+base64.b64encode(path.read_bytes()).decode()
    return f'''<figure class="{'phone' if phone else ''}"><button class="zoom" aria-label="放大查看 {html.escape(caption)}"><svg role="img" aria-label="{html.escape(caption)}" viewBox="{x} {y} {cw} {ch}" xmlns="http://www.w3.org/2000/svg"><image href="{src}" width="{w}" height="{h}"/></svg></button><figcaption>{html.escape(caption)}</figcaption></figure>'''

def missing(text):
    return '<div class="missing"><span>无对应历史截图</span><p>'+text+'</p></div>'
def table(rows):
    return '<div class="table-scroll"><table><colgroup><col class="scene"><col><col></colgroup><thead><tr><th scope="col">具体运用场景</th><th scope="col">5.6 Sol</th><th scope="col">6.0 Astra</th></tr></thead><tbody>'+''.join('<tr><th scope="row">'+name+'</th><td>'+left+'</td><td>'+right+'</td></tr>' for name,left,right in rows)+'</tbody></table></div>'
def section(num,title,claim,rows,paras):
    return f'<section id="s{num}"><h2><span>{num}</span> {title}</h2><p class="claim"><strong>{claim}</strong></p>'+table(rows)+''.join('<p class="evidence">'+p+'</p>' for p in paras)+'</section>'

body='''<header><p class="eyebrow">实际使用观察 · 2026年9月9日</p><h1>GPT6 Astra实际使用报告</h1><p class="intro"><strong>Astra在策划理解、原型实装和视觉组织方面表现出进步，但仍需要人确定目标并验收体验。</strong></p><p>我们用AI辅助制作小型游戏：人描述想要的效果、提供素材，模型编写策划并搭建可操作的原型。以下按具体应用场景，对照此前使用Sol与当前使用Astra的结果。</p><nav aria-label="报告目录"><a href="#s01">01 策划理解</a><a href="#s02">02 Demo实装</a><a href="#s03">03 交互布局</a><a href="#s04">04 素材组合</a></nav><p class="note">图文以既有报告及项目记录为依据。无成对截图的场景明确留空，不以不同任务画面冒充模型对照。点击图片可放大。</p></header>'''
body+=section('01','策划需求理解',
'Astra在策划案编写上更能够理解我们的需求和想要得到的效果。它能够根据描述的游戏策划内容查找类似游戏的信息，并将参考玩法组织为更完整的Demo流程设计。',[
('同类游戏检索与借鉴',missing('旧阶段没有保留可用于本场景的截图，不能据此断言Sol不具备检索能力。'),pic(PLAN/'page-14.png','策划原文：参考游戏、玩法特征与可借鉴方式逐项对应。',(7500,9800,7500,65100))),
('首次游玩流程与逻辑闭环',missing('历史对话曾反馈内容数量与既有文档不符、组合条件遗漏；这是文字记录，不是同任务的截图对照。'),pic(PLAN/'page-2.png','策划原文：寻找、清理、发现、出售与升级组成流程；时间为建议目标。',(7500,23400,7500,49000)))],
['检索记录显示，Astra查阅了Leaf it Alone、Smash Hit Museum、刮个爽和Dirt Clicker等资料，再提炼操作反馈与自动化转折。部分参考由人指定，模型继续查证和整理，而非所有灵感均由它独立提出。',
'它还补充收藏登记与出售并存、必要升级资金预留等配套规则，协助填补闭环缺口。补充方案需人工确认；Astra首稿也曾偏重数值、没有讲清核心操作。'])
body+=section('02','策划到可玩原型',
'Astra将策划实装为引擎内Demo的流程更加准确，也更会照顾整体游玩的连续性。它会针对策划中的闭环缺口提出并接入适当补充；相较此前Sol阶段更依赖我们逐项指出衔接问题，本轮更能同时处理功能之间的关系。',[
('持续操作与物品入库',missing('旧阶段曾需反复强调沿用场景和开盒交互；没有同一挖掘流程的可比Sol截图。'),pic(EA/'ea_01_field.png','v0.2原型：持续清理，物品可先入库，避免每次发现都强制打断。')),
('处理完成后的展示与下一步',missing('早期原型及素材迁移也有Sol参与，不将共同成果全部归于Astra。'),pic(EA/'ea_05_reveal.png','v0.2原型：揭晓、收藏、继续操作与追加处理接在同一流程中。'))],
['我们的实际使用感受是，来回问答、修改和debug比此前更少。可观察的例子包括后台自动处理、手动接管后保留进度和发现物品后先入库，让功能衔接而非单纯堆叠按钮。',
'以上尚无统一次数统计，不报告减少百分比，也不将Sol概括为只能机械执行。Astra仍出现过升级门槛不符合预期的问题；画面和代码检查不能代替连续试玩。'])
body+=section('03','界面布局与复杂展示',
'Astra更能同时处理面板尺寸、信息层级和操作路径，改善Sol阶段“功能有了，但界面仍不好用”的问题，也能将包含多种条件的展示需求拆解并实现。它在本轮中更好地落实了此前反复沟通仍不理想的UI交互逻辑和视觉层级。',[
('报价与成交界面的交互编排',pic(BEFORE/'before-1.png','旧反馈：标题越框，中间留白较多，操作按钮偏小。',(30800,15100,31000,13900)),pic(SHOTS/'ui_bargain.png','改进结果：报价、调整和成交集中在顾客气泡内。',(40500,1000,27800,61300))),
('库存的模型与未知款展示',missing('此项为新增展示需求，没有同条件的旧版结果，不作为Sol实现失败的证据。'),pic(SHOTS/'inventory_grid.png','已发现款显示模型和数量，未知款显示剪影，并匹配按钮状态。',(8000,4000,7000,5000))),
('手机内的商品卡片',missing('没有对应的旧版商品卡片截图。'),pic(SHOTS/'phone_frame_supply.png','两列商品图、名称、价格和购买入口容纳于手机界面。',(72400,3000,500,1000),True))],
['气泡式交互、未知剪影和两列商品布局由人提出，Astra负责把模型取景、数据状态、素材与按钮权限接入同一界面。改进体现于实际结果，而不是认定Sol普遍无法理解这些需求。'])
body+=section('04','现有美术资源的组合判断',
'Astra在现成美术资源的组合上表现出更好的判断，特别是文字、装饰和功能区域之间的关系。它在本轮中比Sol阶段更好地识别了素材用途与合适的占位；然而它仍需沿着人工确定的风格方向迭代。',[
('物品展示面板的文字与装饰',pic(BEFORE/'before-3.png','旧反馈：名称偏离装饰区域，浅色标题对比不足。'),pic(SHOTS/'kangaroo_revealed.png','改进结果：名称、说明与双操作按钮分区更清楚。',(22500,70800,22500,0))),
('主菜单的素材与入口组合',missing('没有同构图的Sol菜单截图，右侧仅展示Astra阶段的组合结果。'),pic(SHOTS/'city_menu.png','沿用给定背景与纸张风格资源，统一主要入口。'))],
['模型会结合素材形状、文字区域和功能用途进行选择、缩放及排列，减少逐项指定坐标的负担。展示对比中还包含人工要求的信息删减和方向调整，不能全部归为模型自主审美决策。'])
body+='''<footer><h2>能力边界与对比口径</h2><p><strong>Astra适合承担具体需求的整理、实现与迭代，仍不能独立接管游戏产出。</strong> 它不能替我们判断游戏是否好玩、哪些玩法值得做，也不能仅凭自动检查承担最终质量责任。</p><p>依据为8月31日至9月9日的对话、模型记录、策划与原型产出；UI沿用此前报告图片。连续迭代包含需求变化、人工调整及两种模型共同工作，并非同输入受控测试。“问答和返工更少”为负责人使用观察，尚无工时或debug次数统计。</p></footer>'''
css='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f3f5f7;color:#202732;font:16px/1.8 "Microsoft YaHei",system-ui,sans-serif}main{max-width:1240px;margin:auto;padding:44px 36px 70px;background:white}h1{font-size:36px;line-height:1.3;margin:8px 0 22px;color:#17202c}h2{font-size:23px;line-height:1.5;margin:0 0 16px}h2 span{color:#506582;margin-right:12px}.eyebrow,.note,figcaption,footer{color:#586675}.eyebrow{font-size:13px;letter-spacing:1px}.intro{font-size:19px}nav{display:flex;gap:10px;flex-wrap:wrap;margin:22px 0}nav a{color:#284d71;background:#edf2f7;text-decoration:none;padding:7px 15px;border-radius:6px}section{margin-top:50px;scroll-margin-top:20px}.claim{font-size:19px;line-height:1.85;margin:0 0 24px}.note{font-size:13px}.table-scroll{overflow-x:auto}table{border-collapse:collapse;width:100%;table-layout:fixed;margin:12px 0 22px;min-width:660px}col.scene{width:14%}th,td{border:1px solid #d6dee7;padding:18px;vertical-align:top}thead th{background:#243c54;color:#fff;font-size:18px;text-align:center}thead th:first-child{font-size:14px}tbody th{background:#f3f6f9;font-size:15px;font-weight:600;text-align:left;vertical-align:middle}figure{margin:0}svg{display:block;width:100%;height:auto;max-height:540px}figcaption{font-size:13px;line-height:1.7;margin-top:10px}.zoom{border:0;background:#f6f7f8;display:block;width:100%;padding:0;cursor:zoom-in}.zoom:focus-visible,button:focus-visible,a:focus-visible{outline:3px solid #dc8800;outline-offset:3px}.phone{max-width:210px;margin:auto}.missing{padding:24px 8px;color:#677484;font-size:14px}.missing span{font-weight:700;color:#4e6074}.missing p{margin:8px 0 0}.evidence{margin:12px 0;font-size:15px}footer{border-top:1px solid #dae0e7;margin-top:44px;padding-top:24px;font-size:13px}footer h2{font-size:19px;color:#222}dialog{border:0;border-radius:8px;max-width:96vw;width:1120px;max-height:95vh;padding:45px 20px 20px}dialog::backdrop{background:#000b}dialog svg{max-height:79vh;width:100%}dialog .phone{max-width:100%}dialog .close{position:absolute;right:14px;top:10px;border:0;background:#e9edf1;padding:6px 14px;cursor:pointer;font-size:16px}dialog .zoom{cursor:default}dialog figcaption{text-align:center}@media(max-width:700px){main{padding:25px 16px}h1{font-size:28px}.claim{font-size:17px}th,td{padding:12px}section{margin-top:36px}}@media print{body,main{background:white}main{max-width:none;padding:0}nav,.note,dialog{display:none}section{break-before:page;margin-top:15px}section:first-of-type{break-before:auto}.table-scroll{overflow:visible}table{min-width:0}thead{display:table-header-group}tr{break-inside:avoid}th,td{padding:10px}svg{max-height:320px}.claim{font-size:14px}p,td,th{font-size:11px}figcaption{font-size:10px}}'''
js='''const modal=document.querySelector('dialog');document.querySelectorAll('figure .zoom').forEach(button=>button.addEventListener('click',()=>{modal.querySelector('.content').replaceChildren(button.parentElement.cloneNode(true));modal.showModal();}));modal.querySelector('.close').addEventListener('click',()=>modal.close());modal.addEventListener('click',event=>{if(event.target===modal)modal.close();});'''
result='<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>GPT6 Astra实际使用报告</title><style>'+css+'</style></head><body><main>'+body+'</main><dialog aria-label="图片放大预览"><button class="close" autofocus>关闭 ×</button><div class="content"></div></dialog><script>'+js+'</script></body></html>'
OUT.write_text(result,encoding='utf-8')
assert result.count('<table>')==4
assert result.count('scope="row"')==9
assert result.count('<svg ')==11
print(str(OUT));print('Tables: 4; scenarios: 9; embedded images: 11; bytes:',OUT.stat().st_size)
