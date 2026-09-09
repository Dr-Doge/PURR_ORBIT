from pathlib import Path
base=Path(__file__).with_name('build_astra_comparison.py').read_text(encoding='utf-8')
exec(base.split("p('GPT6 Astra与GPT5.6 Sol\\n实际使用对比汇报','Title')")[0])
OUT=ROOT/'地球盲盒考古/报告/GPT6_Astra实际使用报告_四项观点图文版_2026-09-09.docx'
doc.core_properties.title='GPT6 Astra实际使用报告'
doc.styles['Title'].font.size=Pt(21)
doc.styles['Normal'].font.size=Pt(10.5)
EA=ROOT/'地球盲盒考古/考古刮地皮/test_captures'
PLAN=ROOT/'.report_work/earth_archaeology/render'
def visual(path,width=6.5,crop=None):
 x=p();x.alignment=WD_ALIGN_PARAGRAPH.CENTER;x.paragraph_format.keep_with_next=True;image_path(x,path,width,crop)
def claim(s):
 x=p(s);x.runs[0].bold=True;x.paragraph_format.keep_with_next=True

p('GPT6 Astra实际使用报告','Title')
p('策划与游戏原型制作中的四项观察    对比 GPT5.6 Sol    2026年9月9日','Subtitle')
claim('Astra在理解策划意图、落实可玩流程和组织视觉界面方面，比此前使用Sol时表现更好，但仍不能代替人决定玩法价值和验收体验。')
p('我们用AI辅助制作小型游戏：人提出想实现的效果、提供素材，模型编写策划并在引擎中搭建可操作的原型，随后由人试玩和反馈。以下以真实产出说明这种工作方式的收益与边界。')
h('01 策划需求理解')
claim('Astra在策划案编写上更能够理解我们的需求和想要得到的效果。')
visual(PLAN/'page-14.png',5.2,(7500,9800,7500,65100))
p('图1  策划原文节选。Astra查询同类游戏后，将参考对象、可借鉴特征和拟采用方式逐项对应，而非只罗列游戏名称。','Caption')
p('检索记录显示，它查阅了Leaf it Alone、Smash Hit Museum、刮个爽和Dirt Clicker等游戏资料，再围绕操作反馈、发现过程和自动化转折整理思路。部分参考由人指定；模型的贡献是继续查证并提炼用途，不是所有灵感都由它独立提出。')
visual(PLAN/'page-2.png',4.5,(7500,23400,7500,49000))
p('图2  早期策划中的操作闭环建议。寻找、清理、发现、出售与升级被连接起来；表内时间是设计目标，不是实际游玩测量结果。','Caption')
p('它还补充了收藏与出售并存、必要升级资金预留等规则，帮助构建闭环。相较Sol阶段的内容数量和组合条件遗漏，Astra更能协助核对系统关系。但补充建议仍需人确认，首稿也曾偏重数值、没有讲清操作。')

doc.add_page_break()
h('02 策划到可玩原型')
claim('Astra将策划实装为引擎内Demo的流程更加准确，也更会照顾整体游玩的连续性。')
visual(EA/'ea_01_field.png',5.15)
p('图3  原型中的主要操作区。玩家持续清理地表，发现物品后可先入库，不必每次立刻打断操作进入处理界面。','Caption')
visual(EA/'ea_05_reveal.png',5.15)
p('图4  处理后的模型展示。沿用已有模型与特效，并将收藏、继续操作和追加处理接在同一流程中。两图为9月9日v0.2记录。','Caption')
p('我们的使用感受是：实现策划所需的来回问答、修改和debug比此前更少。可观察的实例是，Astra把物品入库、后台自动处理、手动接管后保留进度等关系一并接通，减少无必要的打断；不只是逐条增加功能按钮。')
p('这一判断尚无统一的次数统计，不报告减少百分比。早期原型也有Sol参与；Astra仍出现过升级门槛不符合预期的情况，说明“流程更完整”不等于“节奏已正确”，仍要试玩验证。')

doc.add_page_break()
h('03 界面布局与复杂展示')
claim('Astra更能同时处理面板尺寸、信息层级和操作路径，改善Sol阶段“功能有了，但界面仍不好用”的问题，也能将包含多种条件的展示需求拆解并实现。')
pair(BEFORE/'before-1.png',SHOTS/'ui_bargain.png',
 '图5  左为Sol阶段反馈，标题越框、操作偏小；右为Astra阶段结果，报价、调整与成交集中在同一气泡。按面板范围裁切展示。',
 (30800,15100,31000,13900),(40500,1000,27800,61300),2.65)
p('此前我们已多次要求匹配文字和边框，仍需反复指出错位。Astra阶段进一步把相关操作统一编排，减少界面之间来回切换。气泡式交互由人提出，模型负责将其落实为可操作的布局。')
x=p();x.alignment=WD_ALIGN_PARAGRAPH.CENTER;x.paragraph_format.keep_with_next=True
image_path(x,SHOTS/'inventory_grid.png',4.85,(8000,4000,7000,5000));x.add_run('   ')
image_path(x,SHOTS/'phone_frame_supply.png',1.1,(72400,3000,500,1000))
p('图6  Astra阶段的库存和手机商城。获得款显示模型，未知款显示剪影；商品按两列排布，图像、名称与按钮对应。','Caption')
p('这类要求同时涉及模型取景、发现状态、数量和操作权限。Astra能把它们接入同一界面，让负责人主要审核最终效果。库存与商城属于新增需求，不能据此声称Sol曾实现失败。')

doc.add_page_break()
h('04 现有美术资源的组合判断')
claim('Astra在现成美术资源的组合上表现出更好的判断，特别是文字、装饰和功能区域之间的关系；它仍需沿着人工确定的风格方向迭代。')
p('Sol阶段的展示面板','Caption')
visual(BEFORE/'before-3.png',5.6)
p('Astra阶段的展示面板','Caption')
visual(SHOTS/'kangaroo_revealed.png',5.6,(22500,70800,22500,0))
p('图7  上图名称偏离标题装饰区、浅色字对比不足；下图名称、说明与双按钮形成清楚的分区。两图为不同物品，文字删减和方向调整也包含人工要求。','Caption')
visual(SHOTS/'city_menu.png',3.5)
p('图8  主菜单案例。沿用给定背景与纸张风格素材，把装饰和功能入口组合在同一画面；不是由模型重新生成整套美术。','Caption')
p('在我们指定视觉方向后，Astra能够结合素材形状和用途选择、缩放与排列资源，减少逐项指定坐标的负担。但文字适配、风格一致性与审美取舍仍需人工把关。')
p('Astra适合承担具体需求的整理与实现，仍不适合独立接管游戏产出。它不能替我们判断游戏是否好玩、哪些玩法值得做，也不能仅凭代码测试承担最终质量责任。',lead='Astra适合承担具体需求的整理与实现，仍不适合独立接管游戏产出。')
p('对比口径：8月31日至9月9日的对话、模型记录、策划与原型产出；UI图片沿用此前报告。连续迭代包含人工调整和需求变化，并非同输入受控测试。次数减少属于负责人使用观察，无工时或debug次数统计支持。','Caption')
OUT.parent.mkdir(parents=True,exist_ok=True);doc.save(OUT);print(OUT)
