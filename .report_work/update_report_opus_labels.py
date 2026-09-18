from pathlib import Path
import re
from lxml import html, etree

path=Path(r'C:/Users/ruohaojing/Desktop/爽开/地球盲盒考古/报告/GPT6_Astra综合评估报告_策划开发与三维建模.html')
doc=html.fromstring(path.read_text(encoding='utf-8'))
main=doc.xpath('//main')[0]
target=doc.get_element_by_id('s05')
assert '策划需求理解' in target.find('h2').text_content()
main.remove(target)
nav=main.find('header/nav')
for a in list(nav):
    if a.get('href')=='#s05':nav.remove(a)
pattern=re.compile(r'(?:5\.6\s*)?\bSol\b',re.I)
for old,new in [('s06','s05'),('s07','s06'),('s08','s07')]:
    section=doc.get_element_by_id(old)
    section.set('id',new)
    section.find('h2/span').text=new[1:]
    for node in section.iter():
        if node.text:node.text=pattern.sub('Opus 5',node.text)
        if node.tail:node.tail=pattern.sub('Opus 5',node.tail)
        for key in ('aria-label','title','alt'):
            if node.get(key):node.set(key,pattern.sub('Opus 5',node.get(key)))
    for a in nav:
        if a.get('href')=='#'+old:
            a.set('href','#'+new)
            a.text=new[1:]+a.text[2:]
note=etree.Element('p',attrib={'class':'note','id':'opus-comparison-status'})
note.text='Opus 5对照项待实验验证；当前对照图片与描述沿用旧版记录，尚非Opus 5实测结果。'
section=doc.get_element_by_id('s05')
section.insert(2,note)
main.find('header').xpath('./p')[1].text='我们结合道具、建筑和角色建模测试，以及游戏引擎原型与界面制作实践，观察Astra在实际生产中的适用范围。以下先展示三维建模评估，再介绍Demo实装与UI案例。'
assert len(main.findall('section'))==7
assert len(nav.findall('a'))==7
assert not any(pattern.search(t) for s in main.findall('section')[4:] for t in s.itertext())
path.write_text('<!doctype html>\n'+html.tostring(doc,encoding='unicode',method='html'),encoding='utf-8')
print('Removed planning section; updated remaining sections to 05–07; renamed comparison labels.')
