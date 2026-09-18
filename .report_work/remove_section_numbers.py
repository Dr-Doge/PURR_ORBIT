from pathlib import Path
import re
from lxml import html

path = Path(r'C:/Users/ruohaojing/Desktop/爽开/地球盲盒考古/报告/GPT6_Astra综合报告_新版建模与游戏开发.html')
text = path.read_text(encoding='utf-8')
for sid, number in [('s05', '05'), ('s06', '06')]:
    pattern = rf'(<section\b[^>]*\bid="{sid}"[^>]*>\s*<h2[^>]*>)\s*<span[^>]*>{number}</span>\s*'
    text, count = re.subn(pattern, r'\1', text, count=1)
    assert count == 1, (sid, 'heading not found')
    pattern = rf'(<a\b[^>]*href="#{sid}"[^>]*>)\s*(?:{number}|[⑤⑥])\s*'
    text, count = re.subn(pattern, r'\1', text)
    assert count == 1, (sid, 'navigation not found')
doc = html.fromstring(text)
for sid in ('s05', 's06'):
    print(sid, doc.get_element_by_id(sid).xpath('./h2')[0].text_content())
    print('navigation:', doc.xpath(f'//a[@href="#{sid}"]')[0].text_content())
path.write_text(text, encoding='utf-8')
