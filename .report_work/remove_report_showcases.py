from pathlib import Path
from lxml import html

path=Path(r'C:/Users/ruohaojing/Desktop/爽开/地球盲盒考古/报告/GPT6_Astra综合评估报告_策划开发与三维建模.html')
doc=html.fromstring(path.read_text(encoding='utf-8'))
targets={'s06':{'库存的模型与未知款展示','手机内的商品卡片'},'s07':{'主菜单的素材与入口组合'}}
removed=[]
before=len(doc.xpath('//main/section'))
for sid,titles in targets.items():
    section=doc.get_element_by_id(sid)
    for title in titles:
        matches=[n for n in section.findall('div') if n.get('class')=='case' and n.find('h3') is not None and n.find('h3').text_content().strip()==title]
        assert len(matches)==1,(sid,title,len(matches))
        section.remove(matches[0]);removed.append(title)
assert len(doc.xpath('//main/section'))==before
path.write_text('<!doctype html>\n'+html.tostring(doc,encoding='unicode',method='html'),encoding='utf-8')
print('Removed showcases: '+ '、'.join(removed))
