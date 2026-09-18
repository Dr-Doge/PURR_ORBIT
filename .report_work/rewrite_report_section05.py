from pathlib import Path
from lxml import html, etree

path=Path(r'C:/Users/ruohaojing/Desktop/爽开/地球盲盒考古/报告/GPT6_Astra综合评估报告_策划开发与三维建模.html')
doc=html.fromstring(path.read_text(encoding='utf-8'))
section=doc.get_element_by_id('s05')
for child in list(section):section.remove(child)
def paragraph(text,cls='evidence'):
    node=etree.SubElement(section,'p',attrib={'class':cls});node.text=text;return node
h=etree.SubElement(section,'h2');span=etree.SubElement(h,'span');span.text='05';span.tail=' 从零散策划到完整游戏流程'
p=paragraph('','claim')
etree.SubElement(p,'strong').text='Astra更能把零散的策划想法整理、补全并落实为完整的游戏逻辑闭环。相较Sol阶段更依赖我们逐项指出遗漏与衔接问题，Astra在本轮协作中更会检查“玩家为什么继续、操作如何衔接、收益如何支持下一步”，并提出配套改进，让Demo更接近可连续游玩的整体。'
paragraph('这里的逻辑闭环，是指玩家的操作带来发现或收益，收益用于升级，升级又推动下一轮探索。策划往往分多次提出，例如先决定挖掘和收藏，再增加自动化与成长门槛；模型不仅要实现每个要求，还要处理这些要求之间的连接与冲突。')
etree.SubElement(section,'h3').text='Astra与Sol的主要表现区别'
wrap=etree.SubElement(section,'div',attrib={'class':'table-scroll'})
table=etree.SubElement(wrap,'table',attrib={'class':'workflow-comparison'})
cols=etree.SubElement(table,'colgroup')
for width in ('18%','41%','41%'):etree.SubElement(cols,'col',style='width:'+width)
thead=etree.SubElement(table,'thead');tr=etree.SubElement(thead,'tr')
for label in ('观察维度','5.6 Sol','6.0 Astra'):etree.SubElement(tr,'th',scope='col').text=label
tbody=etree.SubElement(table,'tbody')
rows=[
('零散要求的整合','能够编写策划与实现功能，但曾出现既有文档的内容数量、组合条件遗漏，需要负责人补充纠正。','更会把新机制放回整体流程，联动整理库存、价格显示、鉴定及解锁条件，减少只改一处而遗漏相关规则的情况。'),
('闭环缺口的处理','在已记录的旧阶段案例中，负责人需要继续指出规则遗漏、继承范围和流程衔接问题。','会提出配套方案，例如让收藏登记与出售并存、为必要升级预留资金，处理“想收藏却缺钱推进”等规则冲突。'),
('从功能到连续操作','旧版转向新玩法时，曾需要重复强调沿用原场景、开盒交互与展示手感，避免功能迁移偏离预期。','本轮将先入库、后台处理和手动接管后的进度保留接入同一流程，更关注玩家操作中断后能否顺利继续。'),
('负责人投入的重点','较多精力用于逐项纠正遗漏、解释继承关系，以及检查实现是否符合原意。','可以更多围绕整体体验和关键规则给反馈。我们的使用感受是问答与返工负担减轻，但尚未进行统一的次数和工时统计。')]
for label,left,right in rows:
    tr=etree.SubElement(tbody,'tr');etree.SubElement(tr,'th',scope='row').text=label
    etree.SubElement(tr,'td').text=left;etree.SubElement(tr,'td').text=right
etree.SubElement(section,'h3').text='具体体现在哪里'
ul=etree.SubElement(section,'ul',attrib={'class':'workflow-examples'})
for lead,text in [
('让收藏与经济推进兼容。','收藏登记与物品出售分开考虑，避免玩家为了保留发现记录而必须长期占用所有物品。其价值在于同时照顾收集动机与资金循环，而不只是增加一个收藏按钮。'),
('补上升级门槛的资金条件。','当下一层需要更高工具强度时，Astra提出必要升级资金预留方案，防止玩家先把资源花在可选升级上，之后难以推进。这是模型提出的配套建议，仍需人工确认与试玩。'),
('处理操作之间的过渡。','发现物品后可先入库，后台处理可以持续运行，手动接管保留已有进度。这些安排减少重复操作和不必要的打断，使挖掘、清理与奖励之间更连贯。')]:
    li=etree.SubElement(ul,'li');strong=etree.SubElement(li,'strong');strong.text=lead;strong.tail=text
paragraph('因此，本轮观察到的进步，不只是单个功能完成得更快，而是模型更能协助负责人发现规则之间缺少什么、补充之后会影响什么，再将其接成可验证的流程。Sol也具备策划和开发能力；上述区别来自本项目不同阶段的实际协作表现，而非同输入下的受控测试。')
paragraph('Astra仍不能独立判断闭环是否真正有趣。它曾出现首稿偏重数值、升级门槛未达到预期等问题；补全规则不等于完成玩法平衡。负责人仍需决定哪些建议采用，并通过连续试玩验证节奏、手感和推进成本。')
for a in doc.xpath('//main/header/nav/a'):
    if a.get('href')=='#s05':a.text='05 策划闭环与实装'
style=etree.SubElement(doc.find('head'),'style')
style.text='#s05 h3{font-size:19px;color:#243c54;margin:27px 0 14px}#s05 .workflow-comparison td{font-size:15px;line-height:1.85;vertical-align:top}#s05 .workflow-examples{padding-left:24px}#s05 .workflow-examples li{margin:14px 0;line-height:1.9}#s05 .workflow-comparison thead th:first-child{font-size:16px}'
assert not section.xpath('.//svg|.//img')
assert len(section.xpath('.//tbody/tr'))==4
path.write_text('<!doctype html>\n'+html.tostring(doc,encoding='unicode',method='html'),encoding='utf-8')
print('Section 05 rewritten: conclusion, four comparison dimensions, three concrete examples, limitations. Images removed.')
