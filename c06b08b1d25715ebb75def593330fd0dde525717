from pathlib import Path
base = Path(__file__).with_name('build_astra_report.py').read_text(encoding='utf-8')
exec(base.split("p('GPT6 Astra实际使用表现汇报','Title')")[0])
OUT=ROOT/'blind-box-market/docs/《摆摊卖盲盒》/06_开发与验证/GPT6_Astra与GPT5.6_Sol实际使用对比汇报_2026-09-09.docx'
doc.core_properties.title='GPT6 Astra与GPT5.6 Sol实际使用对比汇报'
doc.styles['Normal'].font.size=Pt(11)
doc.styles['Title'].font.size=Pt(22)
doc.styles['Heading 2'].paragraph_format.space_before=Pt(10)
BEFORE=ROOT/'.report_work/astra_comparison'

def image_path(par,path,width,crop=None):
    par.paragraph_format.line_spacing=1.0
    s=par.add_run().add_picture(str(path),width=Inches(width))
    s._inline.docPr.set('descr',path.stem+' 历史实机截图')
    if crop:
        l,t,r,b=crop; w,hh=Image.open(path).size
        rect=OxmlElement('a:srcRect')
        for k,v in zip(['l','t','r','b'],crop):rect.set(k,str(v))
        s._inline.graphic.graphicData.pic.blipFill.insert(1,rect)
        s.height=Inches(width*hh*(100000-t-b)/(w*(100000-l-r)))
def pair(left,right,caption,leftcrop=None,rightcrop=None,width=3.25):
    x=p();x.alignment=WD_ALIGN_PARAGRAPH.CENTER;x.paragraph_format.keep_with_next=True
    image_path(x,left,width,leftcrop);x.add_run('   ');image_path(x,right,width,rightcrop)
    p(caption,'Caption')

p('GPT6 Astra与GPT5.6 Sol\n实际使用对比汇报','Title')
p('面向管理层  |  对比对象 5.6 Sol与6.0 Astra  |  2026年9月9日','Subtitle')
p('我们的总体判断是：从5.6 Sol切换到6.0 Astra后，最明显的进步是它更能理解游戏界面的整体关系，并把素材、文字和操作组合成接近需求的结果。Sol阶段反复调整仍不理想的面板错位、文字越界和视觉层级问题，在Astra阶段得到了进一步改善。提效主要体现在减少逐项解释和局部返工，让负责人更快拿到可评审的画面。Astra仍需要人工纠正与验收，尚不足以承担玩法目标制定和“好不好玩”的判断。')
p('对比口径：按项目负责人的实际使用阶段归为Sol与Astra；早期证据来自9月4日反馈截图，后期来自9月7日运行截图。这是同一工程的连续迭代，包含需求细化和人工调整，不能视为同条件模型竞赛；本次不估算节省工时或提效百分比。','Caption')
h('一  从局部改动走向整体交互编排')
p('结论：Astra更能同时处理面板尺寸、信息层级和操作路径，改善了Sol阶段“功能有了，但界面仍不好用”的问题。',lead='结论：')
p('论据：此前已经要求按功能选用素材、匹配文字与边框，但后续反馈仍是“大量错位，文字超出按键”。旧议价框标题越出装饰区域，面板中间大面积空白，底部按钮偏小。Astra阶段把报价、滑块和成交操作收进同一个紧凑气泡，信息与操作更集中。气泡式议价由人提出，Astra的贡献在于将其落地并适配布局。')
pair(BEFORE/'before-1.png',SHOTS/'ui_bargain.png',
     '图1  左：Sol阶段反馈，标题超框、按钮偏小。右：Astra阶段结果，报价与操作集中在顾客气泡内。局部裁切，按各自面板宽度展示。',
     (30800,15100,31000,13900),(40500,1000,27800,61300),2.7)
p('提效点：把“标题挪一点、按钮再大一点”的反复修补，推进为对整个交易界面的统一调整。负责人可以围绕一套可操作画面给反馈。')

doc.add_page_break()
h('二  对素材用途与视觉层级的理解更好')
p('结论：Astra在现成美术资源的组合上表现出更好的判断，特别是文字、装饰和功能区域之间的关系；它仍需沿着人工确定的风格方向迭代。',lead='结论：')
p('论据：Sol阶段曾大量复用单一按键资产，负责人要求参考不同功能的Preview重新组合，之后仍出现标题低对比度、文字偏离标题框、底部提示与主体面板挤在一起的问题。Astra阶段进一步整理了出货面板的标题、说明和双操作按钮；主菜单也使用同类纸张资产统一三个入口，保留悬停和点击反馈。')
p('Sol阶段  出货面板局部','Caption')
x=p();x.paragraph_format.keep_with_next=True;image_path(x,BEFORE/'before-3.png',6.6)
p('Astra阶段  出货面板局部','Caption')
x=p();x.paragraph_format.keep_with_next=True;image_path(x,SHOTS/'kangaroo_revealed.png',6.6,(22500,70800,22500,0))
p('图2  上：标题偏离装饰框，浅色字对比不足。下：名称、说明与操作形成清晰层级。两图展示不同摆件；概率、熟练度等信息删减由负责人提出，不能单独归为模型提升。','Caption')
p('提效点：模型能把“选择素材”和“安排文字及按钮”连起来处理，减少负责人逐项指定素材和坐标的负担。这里观察到的是结果质量改善，不代表一次生成即可定稿。')

doc.add_page_break()
h('三  能把特殊展示要求做成可用的界面')
p('结论：Astra的另一项实际价值，是能把包含多种条件的展示需求拆解并实现。库存与商城体现了这点，但它们属于新增需求，不能据此断言Sol曾经实现失败。',lead='结论：')
p('论据：库存要求已发现款显示模型静帧、未发现款显示剪影，并配上名称和数量；手机商城要求两列商品卡、图片完整容纳模型；回收页还要区分持有数、可售数与保留收藏。Astra将这些要求接入了实际数据和操作，产出可继续评审的界面。')
shot('inventory_grid','图3  库存结果。已发现款与未知剪影直接对照，展示规则和数据状态一起实现。',4.2)
x=p();x.alignment=WD_ALIGN_PARAGRAPH.CENTER;x.paragraph_format.keep_with_next=True
pic(x,'phone_frame_supply',1.25,(72400,3000,500,1000));x.add_run('        ');pic(x,'shopping_resale',1.25,(72400,3000,500,1000))
p('图4  左为进货，右为回收，均为Astra阶段。右图是较早过程版本。手机外入口由人手工调整，不计为Astra独立成果。','Caption')
p('提效点：可以直接描述“玩家应该看到什么、能做什么”，由模型把取景、布局、数据和按钮状态串起来。收益来自把多项实现工作放进同一轮协作，尚无工时数据支持倍数结论。')
h('仍应保留人的主导位置')
p('Astra继续出现过手机边框越界、尺寸与展示效果需要修正的情况，因此优势应理解为更强的需求落实能力，而非免返工。建议由人负责玩法目标、审美标准和试玩判断，让Astra承担明确需求的实现与迭代。它可以帮助我们把设计做出来，但不能替我们决定游戏值得做什么、玩家是否觉得好玩。')
OUT.parent.mkdir(parents=True,exist_ok=True);doc.save(OUT);print(OUT)
