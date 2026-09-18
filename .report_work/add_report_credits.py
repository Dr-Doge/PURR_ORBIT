from pathlib import Path
import re
from lxml import html

path = Path(r'C:/Users/ruohaojing/Desktop/爽开/地球盲盒考古/报告/GPT6_Astra综合报告_新版建模与游戏开发.html')
source = path.read_text(encoding='utf-8')
credit = '本次报告整合了外部对GPT6 Astra能力的测试，以及内部Visvise团队对GPT6 Astra的测试结果。'
assert 'id="report-credits"' not in source
match = re.search(r'<header\b[^>]*>.*?<p\b[^>]*class="lead"[^>]*>.*?</p>', source, re.S)
assert match, 'Introduction not found'
addition = '\n<p id="report-credits" style="margin:16px 0;color:#5d6d82;font-size:15px;line-height:1.8">' + credit + '</p>'
updated = source[:match.end()] + addition + source[match.end():]
doc = html.fromstring(updated)
assert doc.get_element_by_id('report-credits').text_content() == credit
assert doc.get_element_by_id('report-credits').getparent().tag == 'header'
path.write_text(updated, encoding='utf-8')
print('Added credits immediately after the opening introduction; all other content unchanged.')
