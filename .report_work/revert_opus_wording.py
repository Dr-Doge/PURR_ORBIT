from pathlib import Path
import re
from lxml import html

p=Path(r'C:/Users/ruohaojing/Desktop/爽开/地球盲盒考古/报告/GPT6_Astra综合评估报告_策划开发与三维建模.html')
d=html.fromstring(p.read_text(encoding='utf-8'))
count=0
for section in d.xpath('//main/section')[4:]:
    for n in section.iter():
        if n.text:
            original=n.text
            n.text=re.sub(r'Opus\s*5','5.6 Sol' if n.tag=='th' else 'Sol',n.text)
            count+=int(original!=n.text)
        if n.tail:n.tail=re.sub(r'Opus\s*5','Sol',n.tail)
        for attr in ('aria-label','alt','title'):
            if n.get(attr):n.set(attr,re.sub(r'Opus\s*5','Sol',n.get(attr)))
assert len(d.xpath('//main/section'))==7
assert len(d.xpath('//th[text()="5.6 Sol"]'))==2
assert not any(re.search(r'Opus\s*5',s.text_content()) for s in d.xpath('//main/section')[4:])
p.write_text('<!doctype html>\n'+html.tostring(d,encoding='unicode',method='html'),encoding='utf-8')
print(f'Restored original model wording in {count} text nodes; retained 7 sections and 2 comparison headers.')
