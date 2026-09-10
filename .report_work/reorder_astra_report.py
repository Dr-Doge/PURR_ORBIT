from pathlib import Path
from lxml import html, etree

path=Path(r'C:/Users/ruohaojing/Desktop/爽开/地球盲盒考古/报告/GPT6_Astra综合评估报告_策划开发与三维建模.html')
doc=html.fromstring(path.read_text(encoding='utf-8'))
main=doc.xpath('//main')[0]
header=main.find('header')
summary=header.xpath('./* [contains(concat(" ",normalize-space(@class)," ")," executive-summary ")]')[0]
replacement=etree.Element('div',attrib={'class':'intro claim executive-summary'})
ul=etree.SubElement(replacement,'ul')
points=[
('3D建模的适用范围：','Astra配合Blender MCP，在基础硬表面、模块化结构、自然语言控制和后续修改方面表现较好，适合辅助制作可调整的基础资产。'),
('复杂资产仍需专业美术：','本次测试中，复杂曲面、有机角色和参考图精确还原弱于Visvise等对照工具；过多独立网格也可能影响制作效率。'),
('Computer Use暂不适合正式建模：','通过电脑界面手动操作Blender的方式，在本次测试中的速度、质量与额度消耗尚不足以支持正式建模工作流。'),
('策划与开发协作有所改善：','Astra更能理解具体需求，将策划、交互界面和现有素材连接为可评审、可修改的结果；本轮使用中，问答与返工负担有所减轻。'),
('人的判断仍不可替代：','Astra适合辅助明确需求的设计与实现，玩法决策、审美取舍、精细资产制作和最终质量验收仍需由人负责。')]
for lead,text in points:
    li=etree.SubElement(ul,'li');strong=etree.SubElement(li,'strong');strong.text=lead;strong.tail=text
header.replace(summary,replacement)
intro=replacement.getnext()
intro.text='我们结合道具、建筑和角色建模测试，以及游戏策划、引擎原型与界面制作实践，观察Astra在实际生产中的适用范围。以下先展示三维建模评估，再介绍策划与开发中的四项使用观察。'
sections={s.get('id'):s for s in main.findall('section')}
order=['s05','s06','s07','s08','s01','s02','s03','s04']
labels=['建模结论','能力对比','MCP案例','界面操作建模','策划理解','Demo实装','交互布局','素材组合']
for s in sections.values():main.remove(s)
nav=header.find('nav');nav.clear();nav.set('aria-label','报告目录')
footer=main.find('footer');position=main.index(footer)
for i,(old,label) in enumerate(zip(order,labels),1):
    s=sections[old];number=f'{i:02}';s.set('id','s'+number)
    s.find('h2/span').text=number
    main.insert(position+i-1,s)
    a=etree.SubElement(nav,'a',href='#s'+number);a.text=number+' '+label
style=etree.SubElement(doc.find('head'),'style')
style.text='.executive-summary ul{margin:0;padding-left:1.35em}.executive-summary li{margin:10px 0;padding-left:4px}.executive-summary li:first-child{margin-top:0}.executive-summary li:last-child{margin-bottom:0}'
path.write_text('<!doctype html>\n'+html.tostring(doc,encoding='unicode',method='html'),encoding='utf-8')
assert len(doc.xpath('//main/header/div/ul/li'))==5
assert len(main.findall('section'))==8
print('Updated summary: 5 bullets; section order: 3D modeling first, planning and development second.')
