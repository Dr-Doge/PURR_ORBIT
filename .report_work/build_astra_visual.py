from pathlib import Path
base=Path(__file__).with_name('build_astra_comparison.py').read_text(encoding='utf-8')
exec(base.split("p('GPT6 Astra与GPT5.6 Sol\\n实际使用对比汇报','Title')")[0])
OUT=ROOT/'地球盲盒考古/报告/GPT6_Astra实际使用观察_图文版_2026-09-09.docx'
doc.core_properties.title='GPT6 Astra实际使用观察图文报告'
doc.styles['Title'].font.size=Pt(21)
doc.styles['Normal'].font.size=Pt(10.5)
doc.styles['Normal'].paragraph_format.space_after=Pt(7)
EA=ROOT/'地球盲盒考古/考古刮地皮/test_captures'

def visual(path,width=6.4,crop=None):
    x=p();x.alignment=WD_ALIGN_PARAGRAPH.CENTER;x.paragraph_format.keep_with_next=True
    image_path(x,path,width,crop)

p('GPT6 Astra实际使用观察','Title')
p('策划编写与原型制作的图文案例    对比 GPT5.6 Sol    2026年9月9日','Subtitle')
p('总体判断：Astra更适合把具体想法整理成规则，再把规则接入可运行的游戏原型。相较此前使用Sol的经历，我们观察到它在关联规则处理和界面组织方面有所改善；但首稿仍可能偏题，玩法取舍、操作手感和最终质量仍需人判断。',lead='总体判断：')
p('我们正在用AI辅助制作一款小型游戏，用它验证“发现物品、清理并收集”的体验。人的工作是提出效果、提供素材和试玩；Astra负责整理策划、编写程序并根据反馈修改。以下展示这种协作如何发生，不要求读者了解游戏项目。')
h('01 把口头想法写成可以交给开发的操作说明')
p('希望实现：不只写背景和数值，还要说明玩家按哪里、如何操作、会看到什么变化。')
visual(ROOT/'.report_work/earth_archaeology/render_v02/page-2.png',6.7,(7000,5800,7000,63300))
p('图1  Astra经反馈修订后的策划原文节选。按住拖动、轮廓显露和刷除泥壳被分别写清；这是历史策划片段，不代表当前版本的全部规则。','Caption')
p('实际表现：后续Astra还能按系统拆分文集，并随新规则同步库存、价格显示和解锁条件。相比Sol阶段曾出现内容物数量与既有文档不符、合体条件遗漏，这种联动维护更便于人工审核。文档结构和约束由人提出，并非模型自行决定。',lead='实际表现：')
p('同时存在短板：图中的清晰说明并非首稿即得。Astra首次输出仍偏重数值、没有讲清核心操作，需要我们指出问题后重写。它能帮助完善规则，但仍需要人控制策划重点。',lead='同时存在短板：')

doc.add_page_break()
h('02 让模型读取策划文集 做出可以操作的验证原型')
p('希望实现：交给模型已有规则和素材，让它把“寻找物品”与“处理后展示物品”接成完整流程，而不是只写方案。')
visual(EA/'ea_01_field.png',5.15)
p('图2  寻找阶段的运行画面。玩家在大区域内拖动清理，右侧显示地层和工具入口。','Caption')
visual(EA/'ea_05_reveal.png',5.15)
p('图3  处理后的展示画面。同一流程接入现有3D模型、特效、收藏及后续操作。两图为9月9日v0.2原型截图。','Caption')
p('实际表现：Astra按文集接入多个系统，并补充存档、流程及物品保护检查。相较旧阶段反复提醒沿用场景与交互，这轮更接近一次交付可评审的完整流程。早期原型及素材迁移也有Sol参与，不能把全部成果归于Astra。',lead='实际表现：')
p('人工仍不可省：原型曾出现“不升级也能继续挖掘”的体验偏差。程序能运行、截图能展示，不等于成长节奏合理，更不等于游戏好玩；这些仍需试玩发现。',lead='人工仍不可省：')

doc.add_page_break()
h('03 补充案例 将素材组合成适合操作的界面')
p('希望实现的效果包括：将报价和成交放在同一处操作；已收集物品显示模型，未知款显示剪影；手机商城用商品图而非长文字列表。Astra能结合素材与数据完成这些组合，改善了此前反复出现的文字超框和层级混乱。不过具体布局目标由人提出，比例和手感仍需人工验收。')
pair(BEFORE/'before-1.png',SHOTS/'ui_bargain.png',
     '图4  左为Sol阶段反馈截图，标题越框、操作偏小；右为Astra阶段结果，报价与按钮集中。图片经局部裁切，按各自面板宽度展示。',
     (30800,15100,31000,13900),(40500,1000,27800,61300),2.45)
x=p();x.alignment=WD_ALIGN_PARAGRAPH.CENTER;x.paragraph_format.keep_with_next=True
image_path(x,SHOTS/'inventory_grid.png',4.85,(8000,4000,7000,5000));x.add_run('   ')
image_path(x,SHOTS/'phone_frame_supply.png',1.1,(72400,3000,500,1000))
p('图5  Astra阶段的库存与手机进货页。模型静帧、未知剪影和商品卡片对应具体使用场景；这组属于新增需求，不作为Sol曾实现失败的证据。','Caption')
p('使用边界：这些案例支持将Astra用于明确需求的整理、实现和迭代，尚不足以让它独立决定“应该做什么游戏”。它不能替代玩法负责人，也不能仅凭自检确认玩家是否觉得有趣。',lead='使用边界：')
p('观察口径：对比8月31日至9月3日的Sol协作与9月8日至9日的Astra策划及开发记录，UI沿用此前报告中的9月4日和9月7日截图。各阶段包含需求变化与人工调整，并非同条件测试；没有足够工时数据支持提效倍数。证据来自对话记录、实际策划文档和原型截图。','Caption')
OUT.parent.mkdir(parents=True,exist_ok=True);doc.save(OUT);print(OUT)
