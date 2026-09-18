from pathlib import Path
import re
from lxml import html

p=Path(r'C:/Users/ruohaojing/Desktop/爽开/地球盲盒考古/报告/GPT6_Astra综合评估报告_策划开发与三维建模.html')
d=html.fromstring(p.read_text(encoding='utf-8'))
for n in d.xpath('//*[@id="opus-comparison-status"]'):
    n.getparent().remove(n)
pattern=re.compile(r'(?:5\.6\s*)?\bSol\b|Opus\s*5',re.I)
sections=d.xpath('//main/section')[4:]
for section in sections:
    for n in section.iter():
        if n.text:n.text=pattern.sub('Opus5',n.text)
        if n.tail:n.tail=pattern.sub('Opus5',n.tail)
        for attr in ('aria-label','alt','title'):
            if n.get(attr):n.set(attr,pattern.sub('Opus5',n.get(attr)))
assert not d.xpath('//*[@id="opus-comparison-status"]')
assert all(not re.search(r'\bSol\b|Opus\s+5',s.text_content(),re.I) for s in sections)
p.write_text('<!doctype html>\n'+html.tostring(d,encoding='unicode',method='html'),encoding='utf-8')
print('Updated sections:')
for s in sections:print(s.find('h2').text_content())
print('Opus5 headers:',len(d.xpath('//th[text()="Opus5"]')))
