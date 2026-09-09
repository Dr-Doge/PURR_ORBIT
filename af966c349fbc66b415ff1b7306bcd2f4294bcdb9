from pathlib import Path
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from PIL import Image

ROOT=Path(r'C:/Users/ruohaojing/Desktop/爽开')
SHOTS=Path(r'C:/Users/ruohaojing/AppData/Roaming/Godot/app_userdata/blind-box-market')
OUT=ROOT/'blind-box-market/docs/《摆摊卖盲盒》/06_开发与验证/GPT6_Astra实际使用表现汇报_2026-09-07.docx'
doc=Document(); sec=doc.sections[0]
sec.page_width=Inches(8.5); sec.page_height=Inches(11)
sec.top_margin=sec.bottom_margin=Inches(.62); sec.left_margin=sec.right_margin=Inches(.75)
for n in ['Normal','Title','Subtitle','Heading 1','Heading 2','Caption']:
    s=doc.styles[n]; s.font.name='Microsoft YaHei'; s.font.color.rgb=RGBColor(0,0,0)
    s.element.get_or_add_rPr().get_or_add_rFonts().set(qn('w:eastAsia'),'Microsoft YaHei')
    s.paragraph_format.space_after=Pt(6); s.paragraph_format.line_spacing=Pt(16)
    for border in list(s.element.xpath('.//w:pBdr')): border.getparent().remove(border)
    snap=OxmlElement('w:snapToGrid'); snap.set(qn('w:val'),'0'); s.element.get_or_add_pPr().append(snap)
doc.styles['Normal'].font.size=Pt(10.5)
doc.styles['Title'].font.size=Pt(23); doc.styles['Title'].paragraph_format.line_spacing=Pt(29)
doc.styles['Subtitle'].font.size=Pt(9.5); doc.styles['Subtitle'].font.italic=False
doc.styles['Heading 1'].font.size=Pt(16); doc.styles['Heading 2'].font.size=Pt(12.5)
doc.styles['Caption'].font.size=Pt(8.5); doc.styles['Caption'].font.bold=False
doc.core_properties.title='GPT6 Astra实际使用表现汇报'; doc.core_properties.author='项目组'

def p(text='',style=None,lead=None):
    x=doc.add_paragraph(style=style)
    if lead and text.startswith(lead): x.add_run(lead).bold=True; x.add_run(text[len(lead):])
    else: x.add_run(text)
    return x
def h(text): doc.add_heading(text,2)
def pic(par,name,width,crop=None):
    par.paragraph_format.line_spacing=1.0
    s=par.add_run().add_picture(str(SHOTS/(name+'.png')),width=Inches(width))
    s._inline.docPr.set('descr',name+' 项目运行截图')
    if crop:
        l,t,r,b=crop; w,hh=Image.open(SHOTS/(name+'.png')).size
        rect=OxmlElement('a:srcRect')
        for k,v in zip(['l','t','r','b'],crop): rect.set(k,str(v))
        s._inline.graphic.graphicData.pic.blipFill.insert(1,rect)
        s.height=Inches(width*hh*(100000-t-b)/(w*(100000-l-r)))
def shot(name,caption,width=5.5,crop=None):
    x=p(); x.alignment=WD_ALIGN_PARAGRAPH.CENTER; x.paragraph_format.keep_with_next=True
    pic(x,name,width,crop); p(caption,'Caption')

p('GPT6 Astra实际使用表现汇报','Title')
p('盲盒模拟经营项目实测  |  使用日期 2026年9月7日  |  汇报日期 2026年9月8日','Subtitle')
p('结论：GPT6 Astra在理解具体游戏需求、组织现有美术资产和完成复杂界面方面，较此前工作流表现出明显进步。它已经能承担“需求明确后的实现与迭代”工作，并缩短设计意图到可运行画面的距离；但它仍不能独立判断游戏是否好玩，也不能取代策划负责人提出目标和完成最终验收。',lead='结论：')
h('观察范围')
p('本次评估来自一天内对同一Godot游戏版本的连续协作，重点观察主菜单、手机应用、库存与商城界面的设计和落地。以下判断属于真实项目体验，不是标准化模型测评，也不以代码改动数量作为能力结论。')
h('更理解游戏化界面的交互逻辑')
p('Astra能够把界面理解为一套连续操作，而不是若干独立按钮。主菜单的入口样式、手机主页的三列应用、应用内HOME导航和手机收起入口，都围绕玩家下一步要做什么来安排。这个能力使它更适合参与游戏UI迭代。')
shot('city_menu','图1  主菜单案例。截图用于说明Astra对入口层级、按钮一致性和交互反馈的理解。',5.25)
h('更能根据视觉效果组织已有素材')
p('在给定多套UI资产后，Astra不只读取文件名，也会结合素材的形状、边框、图标和视觉风格选择用途，再调整尺寸和文字区域。手机边框、安全区、状态栏、应用图标和页面卡片因此形成了较统一的结构。实际协作中仍需要人指出错位和风格偏差，模型能够根据反馈继续修正。')

doc.add_page_break()
h('能够落实非标准的展示需求')
p('库存、进货和回收页面最能说明这一点。需求涉及3D模型静帧、未知物品剪影、数量状态、价格和按钮状态，不是套用普通菜单即可完成。Astra能够拆解这些条件并接入游戏数据，形成可以运行和继续修改的界面。')
shot('inventory_grid','图2  库存案例。已获得款显示模型和数量，未获得款显示剪影与未知名称。',5.25)
x=p(); x.alignment=WD_ALIGN_PARAGRAPH.CENTER; x.paragraph_format.keep_with_next=True
for i,n in enumerate(['phone_frame_home','phone_frame_supply','shopping_resale']):
    if i:x.add_run('     ')
    pic(x,n,1.38,(72400,3000,500,1000))
p('图3  手机主页、进货和回收页面。截图展示了应用导航、实体商品图和两列卡片等特殊需求。','Caption')
h('对实际生产的价值')
p('本轮最明显的价值是沟通链条缩短。负责人可以用自然语言描述界面目标、提供素材和参考画面，Astra随后在同一工程内完成素材检索、布局、代码接入和基础检查。遇到文字超框、图标错误、展示方向不对等反馈时，它能继续定位和修正，不必重新解释整个系统。')
p('本次没有建立人工基线和工时记录，因此不宜用单次产出速度或修改文件数量化收益。可以确认的是，模型能够交付可运行、可截图、可继续人工调整的中间结果；这比只生成建议或孤立代码更接近真实制作流程。')
h('局限和适用边界')
p('Astra仍依赖明确需求和持续反馈。首次结果可能出现素材误用、比例不合适、文字越界或交互位置不自然；规则多次变化后也可能残留旧逻辑。它可以检查功能是否运行，却无法可靠判断节奏是否有趣、开盒是否有惊喜感、经营循环是否值得持续游玩。')
p('因此，这次结果不能说明模型可以整体接管游戏产出。玩法目标、审美方向、优先级、试玩判断和最终质量责任仍应由人承担。')
h('建议定位')
p('建议将GPT6 Astra定位为游戏团队的具体需求实现工具：策划或负责人提出目标、参考和验收条件，模型负责快速实现、接入素材并响应修改。近期适合用于UI搭建、资产替换、规则明确的系统开发和重复性检查；玩法创新、乐趣判断和最终发行质量继续由人主导。')
p('说明  本报告仅依据本项目2026年9月7日的实际协作和运行截图，结论反映该工作场景中的表现，不外推为GPT6 Astra在所有项目中的普遍能力。','Caption')
OUT.parent.mkdir(parents=True,exist_ok=True); doc.save(OUT); print(OUT)
