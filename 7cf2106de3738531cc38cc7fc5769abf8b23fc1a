from pathlib import Path
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

ROOT=Path(r'C:\Users\ruohaojing\Desktop\爽开')
OUT=ROOT/'blind-box-market/docs/《摆摊卖盲盒》/06_开发与验证/项目现状与3D美术新人上手报告_2026-09-07.docx'
doc=Document()
sec=doc.sections[0]
sec.page_width=Inches(8.5); sec.page_height=Inches(11)
sec.top_margin=Inches(.65); sec.bottom_margin=Inches(.65)
sec.left_margin=Inches(.7); sec.right_margin=Inches(.7)
sec.footer_distance=Inches(.3)
for name in ['Normal','Title','Subtitle','Heading 1','Heading 2','Heading 3','Caption','List Bullet','List Number']:
    s=doc.styles[name]; s.font.name='Microsoft YaHei'; s.font.color.rgb=RGBColor(0,0,0)
    s.element.get_or_add_rPr().get_or_add_rFonts().set(qn('w:eastAsia'),'Microsoft YaHei')
    s.font.size=Pt(11)
    s.paragraph_format.space_after=Pt(4)
    s.paragraph_format.line_spacing=1.10
for name,size in [('Title',27),('Heading 1',20),('Heading 2',13),('Subtitle',12),('Caption',9)]:
    doc.styles[name].font.size=Pt(size)
    doc.styles[name].paragraph_format.space_before=Pt(8 if name!='Title' else 0)
doc.styles['Normal'].paragraph_format.widow_control=True
footer=sec.footer.paragraphs[0]; footer.alignment=WD_ALIGN_PARAGRAPH.RIGHT
run=footer.add_run('项目新人上手报告  |  '); run.font.size=Pt(9)
field=OxmlElement('w:fldSimple'); field.set(qn('w:instr'),'PAGE'); footer._p.append(field)
doc.core_properties.title='盲盒摆摊项目现状与新人上手报告'
doc.core_properties.author='项目组'
doc.core_properties.subject='面向3D美术与游戏策划的交接和AI协作指南'

def p(t,style=None): return doc.add_paragraph(t,style)
def h(t): doc.add_heading(t,2)
def page(t):
    heading=doc.add_heading(t,1)
    heading.paragraph_format.page_break_before=True
def bullets(items):
    for t in items:p(t,'List Bullet')
def steps(items):
    for i,t in enumerate(items,1):p(f'{i}. {t}')
def table(headers,rows,widths):
    tab=doc.add_table(rows=1,cols=len(headers)); tab.alignment=WD_TABLE_ALIGNMENT.CENTER; tab.autofit=False
    for col,w in zip(tab.columns,widths):col.width=Inches(w)
    for c,t in zip(tab.rows[0].cells,headers): c.text=t
    for row in rows:
        cells=tab.add_row().cells
        for c,t in zip(cells,row):c.text=str(t)
    for ri,row in enumerate(tab.rows):
        trpr=row._tr.get_or_add_trPr(); no=OxmlElement('w:cantSplit'); trpr.append(no)
        if ri==0: rep=OxmlElement('w:tblHeader'); trpr.append(rep)
        for ci,c in enumerate(row.cells):
            c.width=Inches(widths[ci]); c.vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.CENTER
            pr=c._tc.get_or_add_tcPr(); sh=OxmlElement('w:shd'); sh.set(qn('w:fill'),'DDE8F0' if ri==0 else ('F5F7F9' if ri%2==0 else 'FFFFFF'));pr.append(sh)
            borders=OxmlElement('w:tcBorders')
            for side in ['top','left','bottom','right']:
                e=OxmlElement('w:'+side); e.set(qn('w:val'),'single'); e.set(qn('w:sz'),'4');e.set(qn('w:color'),'D9D9D9');borders.append(e)
            pr.append(borders)
            mar=OxmlElement('w:tcMar')
            for side in ['top','left','bottom','right']:
                e=OxmlElement('w:'+side);e.set(qn('w:w'),'75');e.set(qn('w:type'),'dxa');mar.append(e)
            pr.append(mar)
            for par in c.paragraphs:
                par.paragraph_format.space_after=Pt(2);par.paragraph_format.space_before=Pt(2)
                for r in par.runs:r.font.size=Pt(10);r.bold=ri==0
    spacer=p(''); spacer.paragraph_format.space_after=Pt(0); spacer.paragraph_format.line_spacing=Pt(4)
def shot(name,caption,width=6.6):
    f=Path(r'C:\Users\ruohaojing\AppData\Roaming\Godot\app_userdata\blind-box-market')/(name+'.png')
    if f.exists():
        par=doc.add_paragraph();par.paragraph_format.keep_with_next=True
        par.add_run().add_picture(str(f),width=Inches(width))
        p(caption,'Caption')

p('盲盒摆摊项目现状\n与新人上手报告','Title')
p('面向 3D 美术主职与游戏策划次职成员','Subtitle')
p('整理日期 2026年9月7日  |  项目组交接资料')
p('我们正在制作一款固定桌面视角的盲盒模拟经营游戏。玩家通过开盒获得摆件，在动漫步行街摆摊、议价、收藏，并用隐藏款交换电脑配件。当前重点是经营取舍和发现新款的惊喜，不再是旧版的天文数字收益。')
p('你加入后的首要任务，是把一个模型从素材文件变成经过游戏内验证的可交付资产。先完成一件，再扩大到一个系列；同时用试玩记录协助策划调整辨识度、陈列和经营节奏。')
h('先知道这四件事')
bullets(['这是可运行的迭代 Demo，不等于已完成商业化内容、性能或授权验收。','实际工程位于仓库内的 blind-box-market 子目录。主入口是 scenes/frontend/main_menu.tscn，经营场景是 scenes/stall_demo/stall_demo.tscn。','新策划集在 docs/《摆摊卖盲盒》；docs/策划案 与 README 中有大量旧规则，不能直接照搬。','AI 可以读取工程、修改脚本并执行检查，但美术质量、交互手感和最终验收仍需要人判断。'])
h('阅读路线')
p('第2至4节了解当前玩法和产出；第5至8节用于找到工程并交付美术；第9至10节提供AI协作步骤和可直接复制的任务模板；第11至12节用于验收、安排第一周工作与排查风险。')
h('旧版本只需了解的背景')
p('早期版本围绕桌面物理开盒、空盒回收、幸运与熟练度升级、自动开盒机和吸尘器扩展。它留下了桌面、封条、聚焦揭晓和素材接入基础。摆摊版本保留这些基础体验中的有效部分，新增顾客、货架经营、手机应用、独立行情和装机剧情。看到旧代码并不代表该机制仍是现行玩法。')

page('2 当前游戏怎样玩')
p('游戏暂用长标题《为了赚钱配电脑我选择在动漫街摆摊卖盲盒》。主角为了玩 GDA6 想组装高端PC，从摆摊开始筹集货源和隐藏款。集齐八项电脑配件后触发结局：游戏竟然是主机独占。这个目标没有硬性的通关天数限制。')
steps(['营业前自由理货、进货、开盒和定价，不计时。左上角点击“开店”后，时间和街道客流才开始推进。','每天营业时间为10:00至20:00，默认约5分钟。临近19:00客流逐渐减少，也可提前闭店。','点击桌面盲盒进入聚焦，鼠标左键沿封条交互，撕完自动开盖和揭晓。摆件可旋转查看；选择上市或计入库存。当前不采用脱手阻碍。','新款只有选择上市时才要求定价；同款之后沿用已记住的挂牌价。上架商品可再次改价。','顾客从街道走近摊位，在头顶气泡报价。原价只需确认是否成交；砍价在同一气泡内完成。日结后继续下一天。'])
shot('customer_bubble','当前运行画面示例  顾客头顶交易气泡与三台阶梯展示台。截图用于识别系统，不作为最终美术质量标准。',6.5)
p('第一天闭店还有20段老王剧情。点击屏幕任意位置推进，结束后回到日结；完成状态随存档保存。老王提供隐藏款换配件的主线动机。')

page('3 当前系列与经济规则')
p('截至本报告，代码中配置5个系列、共59款。常规款在各自系列内等概率；小隐藏总概率5%，含大隐藏的系列另有1%大隐藏。品质内部索引仍为0、4、5，不要把它们误当成六个有效品质。')
table(['系列','款数构成','盒价','解锁条件'],[
['肥嘟嘟伙伴','9常规＋1小隐藏','20元','初始'],['高雅企鹅','9常规＋1小隐藏','48元','上一系列开8盒'],['奶蛙 生肖系列','12常规＋1小隐藏','120元','上一系列开12盒'],['牛来','10常规＋1小隐藏＋1大隐藏','260元','上一系列开18盒'],['胖企鹅系列','12常规＋1小隐藏＋1大隐藏','520元','上一系列开25盒']],[1.25,2.1,.7,2.95])
h('价格不是固定收益')
p('普通款初始市价约为盒价1.5倍，但此后每件拥有独立的合成行情。走势可连续下跌、反弹或受新闻冲击，同系列也可能一涨一跌。普通款底线为盒价15%，隐藏款市价底线为盒价105%。这不是接入真实股票报价；相同日期读档不会重新抽取走势。顾客预算会参考当日市价，旧的高挂牌价不保证能卖出。')
p('扭扭按当日市价60%即时回收，适合清理重复款，不是保本渠道。现金、库存市值、实际成交收入是三件不同的事。试玩时要记录成交价与买盒成本，而不只看库存估值。')
h('成长和主线')
p('亚克力展示台初始两层，每次升级加一层和两个栏位；每台最多四层，之后增设旁边一台，最多三台、24栏。其余实体化升级包括运动型背包、给市场主管买的烟、十九子作剪刀和《演员的自我修养》。')
p('配件顺序为机箱、水冷、电源、硬盘、主板、CPU、内存、显卡。配件主要通过指定隐藏款任务交换，不能继续沿用早期“只攒现金逐件买电脑”的策划。')

page('4 已形成的项目产出')
table(['模块','当前落地情况','新成员应关注'],[
['桌面与街道','复用桌面和开盒；可视街道已接入城市建筑资产','保持已有尺度和固定视角，不重建整座城市'],['开盒与揭晓','封条交互、自动开盖、摆件聚焦、spritesheet特效及NEW演出','检验脸朝镜头、VFX不穿模、文字不遮物'],['展示与库存','最多3台4层；中央5列库存，静态正面图和未知剪影','摆件底部贴台，缩略图仍能辨识款式'],['顾客与客流','五类顾客各3款，另有9款专用路人；分向、避让和升级客流','分类不混用模型，检查停步和变道观感'],['交易与行情','头顶气泡内成交和还价；逐件独立行情','观察低价与高价商品是否都有合理成交机会'],['手机与成长','进货、社交、订单、二手、行情及升级等应用','不把独立背包重新塞回手机'],['剧情与存档','序章、首日老王对白、装机结局；手动保存和读取','首日NPC立绘仍为明确的可替换占位']],[1.0,3.0,3.0])
h('界面入口')
p('“大蓝书”用于帖子和隐藏款照片揽客；“毒”用于订单；“扭扭”用于回收；“集换处”用于走势图；“超级小狗”承载装机配件相关页面；“基米”承载金钱升级。社交、订单、二手与行情按现金和系列进度分阶段解锁，开店按钮已在左上HUD。')
h('哪些不能当成完成项')
p('设置仍有占位。批量进货和连开相关代码已经存在，但“抽卡式完整连开演出”不能仅凭升级名称视为最终验收完成。社交帖子和新闻以脚本内容驱动，并非真实联网平台。当前的回归脚本通过，不代表长时间游玩、所有旧存档、全部硬件和正式发行构建已经验证。')

page('5 找到正确的工程入口')
p('仓库根目录是“爽开”，Godot工程在其下的 blind-box-market。下面的路径均相对于这个Godot工程目录。res:// 也指向这个目录；user:// 指向本机的游戏用户数据目录。')
table(['要找什么','从这里开始'],[
['项目与运行入口','project.godot\nscenes/frontend/main_menu.tscn'],['经营场景与主逻辑','scenes/stall_demo/stall_demo.tscn\nscripts/stall_demo/stall_demo.gd'],['共享开盒与模型映射','scripts/ui/main.gd\nscenes/entities/physical_box.tscn'],['人物与展示台','scripts/stall_demo/city_pedestrian.gd\nscripts/stall_demo/acrylic_display.gd'],['行情与库存','scripts/stall_demo/item_market.gd\nscripts/stall_demo/inventory_grid.gd'],['剧情与UI','scenes/stall_demo/day_one_story.tscn\nscenes/ui/stall_ui_layout.tscn'],['正式内容物资源','assets/3D assets/各系列目录'],['文档与回归','docs/《摆摊卖盲盒》/\ntests/']],[1.6,5.4])
h('第一次启动')
steps(['请负责人提供同步好的工程、约定的Godot版本和素材访问权限。先保留一份不修改的基线，首次导入等待资源处理完成。','在Godot中导入 project.godot，运行主菜单，再进入新游戏。只运行某个子场景会绕过主菜单、序章或加载流程。','确认能完成一次开盒、存入背包、上架、成交和闭店。先报告原有问题，再开始替换资产。'])

page('6 一件3D资产怎样交付')
p('AI生成的初模只是中间产物。你负责让它符合系列风格、具备可控的技术成本，并在开盒、展示台和库存三个场景中都成立。建议先做一件“金样”，确认后再批量生产。')
steps(['领取明确任务卡：系列、款式、品质、姿势、参考图、禁止修改项和验收截图。先确认是替换既有款，还是新增款。','确定系列造型规则：头身比例、眼睛、配色、道具与底座。常规款靠轮廓和姿态区分，不只换颜色。','用已获授权的参考制作概念图，再生成或搭建3D初模。记录工具、提示词、版本和来源；当前不绑定某一家3D生成服务。','在Blender等DCC工具中检查脸、手、附件、破面、悬浮碎片、法线、UV和贴图；清理网格和材质。DCC指建模、贴图等内容制作软件。','导出一件样品，保留源工程与贴图。请AI先检查它与当前导入约定是否一致，不要直接批量旋转或缩放全系列。','在游戏中验证正面揭晓、左键旋转、台面落点、静态缩略图和未知剪影。发现异常先定位是源模型、导入还是运行时变换。','交付截图、简短记录、模型与贴图、对应ID和改动清单。验收通过后再替换下一批。'])
h('建议交付包')
p('保留源工程文件、导出模型、全部贴图、正侧背截图、游戏内三场景截图，以及一份说明。说明应记录series_id、item_id、显示名、品质、模型路径、作者或来源、生成工具与提示词版本、授权状态、面数、材质槽、贴图尺寸、朝向和额外展示角。当前工程没有证据表明 metadata.json 已被自动读取，因此它首先是交接记录。')
h('美术与AI各自负责什么')
p('AI适合核对路径、批量列出缺失贴图、修改映射和生成验证脚本。你负责风格一致性、造型吸引力、轮廓辨识和实际游戏观感。AI说“模型加载成功”，不等于脸朝对了、底部贴台了或能作为最终商业素材。')

page('7 资产技术约定与朝向避坑')
table(['项目','当前依据或建议'],[
['正式模型路径','assets/3D assets/；当前映射主要为FBX，不再接入旧 Bind_Box_Fever美术 路径'],['文件命名','系列标识-显示名称（款式标识）.fbx；前缀与括号内容不进入显示名'],['面数与贴图建议','常规款5k至15k三角面；隐藏款建议不超过30k；默认1K，必要时2K'],['材质与原点建议','常规1至3个材质槽，尽量不超过5个；源模型原点置于底部中心'],['当前原始FBX约定','共享适配器按原始+Z为脸、+Y为头顶，绕X轴转90度'],['运行时统一约定','转换后-Y为脸、+Z为上；不要把两个坐标约定混在一起'],['额外展示角','肥嘟嘟伙伴仅聚焦时在正面基础上向左25度；不烘焙到原始网格']],[1.3,5.7])
p('美术规范文档写的是运行时统一朝向，而共享脚本目前还会转换原始FBX。若你导出时已经改成-Y正面，又沿用原适配器，就可能二次旋转，让头顶朝镜头。每次新导出流程都先验证一件，并明确报告“原始模型轴向”和“游戏中实际脸朝向”。')
h('替换款与新增款不能混为一谈')
p('只替换同一款：保持系列和item_index顺序，修改对应模型引用即可。新增款：必须同时维护 SERIES 中的名称、品质等数据、COLLECTIBLE_MODEL_PATHS，以及摆摊版数值数组和回归检查。文件改名不会自动完成所有同步。')
p('存档和发现记录使用系列与物品索引识别款式。不要为了文件排序好看就重排数组，否则旧库存可能对应到另一件摆件。FBX导入文件和UID也有引用关系，不要让AI一键删除全项目导入配置。')
h('验收尺寸')
p('加载器会按模型包围盒居中并归一化，展示台再应用1.44倍显示缩放；这不是直接使用建模软件里的绝对尺寸。库存采用192×192离屏截图后缓存，游戏格子不持续渲染模型。悬浮碎片会扩大包围盒，使主体显得很小，必须先清理。')

page('8 场景人物与特效协作')
h('街道与人物')
p('只优先打磨固定视角内能看见的街边。建筑来自 Cartoon City Massive Megapack；人物在其 Characters 资产中按类别分池，统一复用骨骼行走与待机动画。五类顾客各3款，另有9款纯路人，装机店老板另有独立模型池。新增角色不能只换文件路径而不检查骨骼和动画。')
p('顾客必须从正常步行路线变道靠近摊位。检查正反向行走、头脚朝向、停步、回流、模型间距和绕行；程序的间距断言不能替代查看手臂或附件是否穿插。街道根节点的缩放是现有尺度基准，勿单独把人物放大到桌面坐标。')
h('哪些可以在编辑器中改')
table(['编辑目标','操作位置与边界'],[
['主菜单','main_menu.tscn；按钮和标题均有实体节点，保留悬停和按下状态'],['常驻HUD和手机外框','stall_ui_layout.tscn；保持具名节点不改名'],['顾客交易气泡','位置跟随头顶投影，由脚本控制；旧固定BargainPanel坐标不再是位置权威'],['展示台','acrylic_display.gd 为工具脚本；编辑器可预览升级，但运行时由存档等级决定'],['老王立绘','day_one_story.tscn 的 PortraitArea/Portrait，替换Texture并调整区域'],['独立库存','inventory_grid.gd动态生成网格；不能只改旧手机库存页面']],[1.45,5.55])
h('特效资产')
p('当前使用 assets/VFX 下的透明PNG序列图，规范为8×8共64帧。开出、待机、收入和解锁礼花分别接入专用播放器，不要把整张图当单帧。摆件应位于VFX之前，背景效果不能跟着摆件旋转。文档曾记录多次倍数调整，最终应以脚本常量和当前截图验收，不再机械重复“放大两倍”。')
p('替换任何UI或VFX时，都提交16:9实际运行截图。只看素材预览图无法检查文字越界、透明叠加、材质过曝和前后遮挡。')

page('9 从零开始使用AI协作')
p('本项目使用AI助手协助工程和文档工作。对新人而言，最有效的起点不是学习复杂接口，而是明确工作目录、任务范围和验收方式。下面是项目组建议采用的流程。')
steps(['把AI连接到这份项目的本地工作目录。先让它只读项目文件，报告主入口、当前模块与相关资产，不立刻改动。Codex可围绕本地项目开展任务并检查改动；具体界面和账户能力以官方说明为准。[A]','一次只给一个可验收的小任务。例如“替换骑士一款的模型并验证三种展示”，而不是“把全游戏美术做完”。','同时提供目标截图、素材路径、正确与错误示例、不能修改的节点和预期输出。图片里的文案不是自动授权指令。','让AI先解释将改哪些文件，再实施。首次配合时，遇到大范围改名、删除或改轴向，要求停下来确认。','看差异和运行画面。要求AI给出实际测试命令、结果和截图；遇到报错要保留完整日志，不只转述“有问题”。','确认有效后再允许提交或推送。记录这次替换的原因、结果和剩余问题，方便另一个人接手。'])
h('术语快速理解')
table(['术语','对你的实际意义'],[['上下文','AI能看到的说明、代码、图片和文件；别假设新对话记得全部历史'],['提示词','你的任务说明；要写目标、范围、限制和验收条件'],['Diff','文件修改前后的差异；用它确认没有误改别的系列'],['MCP','连接工具的一种机制；本项目有Godot相关插件，但端口或连接失败时仍应检查实际运行'],['回归测试','确认旧功能未被新修改破坏；通过脚本后仍要人工试玩']],[1.05,5.95])
p('不要上传密钥、私人聊天记录或无权分享的素材。不要把“AI判断可以商用”当成授权凭证。需要付费生成、上传第三方平台或公开发布时，先由负责人确认。')
p('[A] 官方说明 https://learn.chatgpt.com/docs/app ；任务描述参考 https://learn.chatgpt.com/docs/prompting 。访问日期2026年9月7日。','Caption')

page('10 可以直接复制的任务模板')
h('模板一 接手工程时先只读')
p('请读取当前Godot工程，重点检查 scenes/stall_demo/stall_demo.tscn、scripts/stall_demo/stall_demo.gd、scripts/ui/main.gd，以及 docs/《摆摊卖盲盒》。现在不要改文件。请说明当前玩法、模型映射位置、哪些UI由脚本生成、哪些历史文档已不适用，并列出我替换一款摆件前必须确认的信息。')
h('模板二 替换一款模型')
p('目标：仅替换【系列】【款式】的3D模型。资源路径：【填入路径】。附图A为预期正面，附图B为当前错误效果。保留系列ID、item_index、显示名、概率、价格及其他款式；不要删除旧源文件，也不要修改其他UI。先核对原始模型轴向与当前适配器，再修改引用。请验证聚焦正面、旋转、2倍展示台尺寸、底部贴台和库存静态缩略图，返回文件清单与截图。未经我确认不要commit或push。')
h('模板三 提交可复现的问题')
p('环境：【引擎版本】【窗口比例】【新游戏或存档】。步骤：1.【操作】；2.【操作】；3.【操作】。期望：【具体画面或数值】。实际：【具体问题】。发生概率：【必现或约几次一次】。附件：【截图、视频或完整报错】。请先判断问题属于模型、导入设置、运行时变换还是UI布局，再提出最小改动。')
h('模板四 用策划思路提出改动')
p('现象：【例如重复款总卖不掉】。希望改变的体验：【例如允许玩家及时止损】。假设规则：【明确阈值或交互】。保持不变：【价格底线、品质爆率或既有布局】。请先列影响到的玩法、存档和美术资产，不直接实现；给出一份小规模试玩验证方案。')
h('每次向负责人交付时回答')
bullets(['我改了哪件东西，为什么改；哪些内容明确没有改。','它在游戏内哪里可见，怎样复现验收。','哪些检查确实执行过，哪些没有条件执行。','还有哪些风险或待定项，需要谁拍板。'])
p('避免“感觉不对”“整体优化一下”这样的孤立反馈。可改成“脸应正对镜头，但当前头顶占据正中央；只修这一个系列的聚焦朝向”。明确的边界能减少AI误改。')

page('11 验收与第一次交付')
h('一件资产的人工验收清单')
bullets(['源模型和贴图齐全，文件名、款式和品质对应；无悬浮碎片、破面或明显错误法线。','开盒揭晓时脸朝玩家，能自由查看，主体不与VFX共面；特殊展示角只作用于对应场景。','上架时脸朝顾客，底部准确落在对应台阶；最高4层与新增展示台没有错位。','库存正面图清楚，未知剪影可辨识且无名称泄漏；同款数量和上架减少数量正确。','关闭UI、成交、保存再读取后引用仍正确；未破坏其他系列或手工布局。'])
h('可以让AI执行的回归')
table(['脚本','主要检查范围'],[['tests/validate_campaign_flow.gd','主菜单、经济、应用、配件、存档与暂停'],['tests/validate_city_presentation.gd','人物动画、由行人转顾客、朝向与展示相关流程'],['tests/validate_crowd_story.gd','模型池、客流增长、间距避让、首日剧情和点击'],['tests/validate_market_inventory.gd','行情亏损与底线、展示上限、静态库存和气泡']],[3.5,3.5])
p('示例命令：Godot控制台程序 --path 项目目录 --script res://tests/validate_market_inventory.gd。无界面模式可用于部分逻辑测试，但库存截图和VFX必须在有图形渲染的运行中验证。近期这些回归已通过；替换素材后需要重新运行，不能引用旧通过记录。')
h('建议的前三天')
p('第一天：运行一轮游戏，找到资产映射、现场UI和新策划；输出一页理解笔记。第二天：只替换一款样品，完成开盒、上架、库存三组对照截图。第三天：修复反馈，交付可回归的金样和同系列后续清单。该安排是建议练习，不是已经约定的排期。')
p('提交前先查看Git状态，确认哪些改动属于你。commit只是本地记录，push才上传，build才导出程序。首次交付请负责人审查；不要用全量暂存或强制重置掩盖不理解的改动。大素材的Git LFS策略由负责人确认，不自行迁移仓库。')

page('12 当前风险与交接优先级')
table(['优先级','问题','建议处理'],[['先确认','引擎与版本标记不一致','统一Godot程序和导出模板；记录构建对应commit和未提交差异'],['先确认','旧README和旧13号文档仍在','当前规则先核对摆摊代码及新策划，历史数值仅供回溯'],['先确认','模型朝向约定存在转换层','先验证一件导出样品，不批量烘焙展示旋转'],['优先制作','老王立绘仍为占位','按day_one_story场景的预留区域制作并验证长对白'],['持续打磨','高层展示台和高客流可读性','检查遮脸、遮挡、模型附件碰撞、帧率与气泡边界'],['持续打磨','经济和内容规模仍在迭代','试玩不同价格与库存策略，避免只测开发者大额现金'],['发行前确认','角色概念与第三方素材授权','负责人统一核对授权记录、品牌或IP相似性，不能默认可商用']],[.9,2.2,3.9])
h('信息冲突时怎么判断')
p('实际程序决定“现在发生了什么”，最新确认需求决定“应该改成什么”。二者不一致时记录差异并请负责人确认，不擅自把旧文档覆盖回新代码。当前系列共59款，较早文档中的57款不可直接作为验收数量；旧六品质、幸运升级和七天限制也不能恢复为摆摊版规则。')
h('查证入口')
p('本报告的工程状态依据：project.godot、export_presets.cfg、scripts/stall_demo 下的经营与新增模块、scripts/ui/main.gd 的系列和模型映射、scripts/core/game_session.gd、scenes/frontend 与 scenes/stall_demo，以及新策划集中的资产规范、UI指南和最新行情展示库存说明。')
p('日志定位：当前仓库最近记录包括80ef29da（2026-09-07，change）、2f301ee8（2026-09-02，同步工作区）和b470d9f0（2026-09-02，0.2.2构建）。这些记录仅用于定位，不代表本报告涵盖的所有后续工作区改动已经推送或重新构建。')
h('你第一次完成交付的标准')
p('能够解释当前摆摊循环；能独立找到并替换一款资产；能给AI清楚的范围和验收要求；能用实际运行截图证明结果；知道哪些数值、索引和手工布局不能顺手改动。做到这些后，再扩大到整系列制作。')

OUT.parent.mkdir(parents=True,exist_ok=True)
doc.save(OUT)
print(OUT)
