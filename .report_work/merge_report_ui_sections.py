from pathlib import Path
from lxml import html, etree

path=Path(r'C:/Users/ruohaojing/Desktop/爽开/地球盲盒考古/报告/GPT6_Astra综合评估报告_策划开发与三维建模.html')
doc=html.fromstring(path.read_text(encoding='utf-8'))
main=doc.xpath('//main')[0]
first=doc.get_element_by_id('s06');second=doc.get_element_by_id('s07')
first.find('h2/span').tail=' 界面布局与美术资源组合'
claim=first.find('p[@class="claim"]')
claim.clear();claim.set('class','claim')
etree.SubElement(claim,'strong').text='Astra更能同时处理面板尺寸、信息层级、操作路径与美术素材之间的关系，改善Sol阶段“功能有了，但界面仍不好用”的问题。它能够将交互要求与素材用途结合起来，合理安排文字、装饰和功能区域；但仍需沿着人工确定的风格方向迭代。'
body=first.find('.//tbody')
source=second.find('.//tbody')
assert first.find('.//thead').text_content()==second.find('.//thead').text_content()
for row in list(source):body.append(row)
for p in list(first.findall('p[@class="evidence"]')):first.remove(p)
for text in [
 '在议价界面中，Astra把报价、调价和成交集中到同一气泡内；在物品展示面板中，它进一步理顺名称、说明与操作按钮的层级。这些案例体现了交互编排与素材组合的共同改善。',
 '模型会结合素材形状、文字区域和功能用途进行选择、缩放及排列，减少逐项指定坐标的负担。交互目标、信息删减和展示方向仍包含人工要求，最终效果需要人工验收。']:
    p=etree.SubElement(first,'p',attrib={'class':'evidence'});p.text=text
main.remove(second)
for a in list(main.find('header/nav')):
    if a.get('href')=='#s07':a.getparent().remove(a)
    elif a.get('href')=='#s06':a.text='06 界面与素材组合'
assert len(main.findall('section'))==6
assert len(first.xpath('.//table'))==1
assert len(body.findall('tr'))==4
assert len(body.xpath('./tr[@class="caption-row"]'))==2
ids=set(doc.xpath('//@id'))
assert all(a.get('href')[1:] in ids for a in main.find('header/nav'))
path.write_text('<!doctype html>\n'+html.tostring(doc,encoding='unicode',method='html'),encoding='utf-8')
print('Merged sections 06 and 07; one table with two image rows and two caption rows; navigation verified.')
