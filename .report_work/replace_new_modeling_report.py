from pathlib import Path
from copy import deepcopy
from lxml import html, etree
import base64

folder = Path(r'C:/Users/ruohaojing/Desktop/爽开/地球盲盒考古/报告')
target = folder / 'GPT6_Astra综合报告_新版建模与游戏开发.html'
incoming = Path(r'C:/Users/ruohaojing/Documents/WXWork/1688855188862276/Cache/File/2026-09/GPT-Astra 汇报.html')
reference = Path(r'C:/Users/ruohaojing/Desktop/1/企业微信截图_17890973816787.png')
previous = target.read_bytes()
old = html.fromstring(previous)
new = html.fromstring(incoming.read_bytes())
body = new.xpath('//body')[0]
for node in new.xpath('//script|//dialog'):
    parent = node.getparent()
    if node.tag == 'dialog' and parent.tag == 'div' and len(parent) == 1:
        parent.getparent().remove(parent)
    else:
        parent.remove(node)
for node in new.iter():
    for attr in list(node.attrib):
        if attr.lower().startswith('on'):
            del node.attrib[attr]

new.xpath('//title')[0].text = old.xpath('//title')[0].text
new.xpath('//nav')[0].getparent().replace(new.xpath('//nav')[0], deepcopy(old.xpath('//nav')[0]))
new.xpath('//header')[0].getparent().replace(new.xpath('//header')[0], deepcopy(old.xpath('//header')[0]))
# Retain only the combined report's scoped development/preview styles.
style = next(s for s in old.xpath('//head/style') if '.dev-report{' in (s.text or ''))
new.xpath('//head')[0].append(deepcopy(style))
footer = new.xpath('//footer')[0]
for sid in ('s05', 's06'):
    footer.addprevious(deepcopy(old.get_element_by_id(sid)))
footer.clear()
footer.set('class', 'doc-footer')
footer.text = '建模部分采用《GPT-Astra 汇报》；后续保留游戏策划实装与UI素材组合评估。模块化防御塔参考图由项目负责人提供。图片已内嵌，可离线阅读，点击可放大。'
body.append(deepcopy(old.get_element_by_id('report-zoom')))
for script in old.xpath('//body/script'):
    body.append(deepcopy(script))

heading = next(n for n in new.xpath('//h2') if n.text_content().strip() == '建筑 1 · 模块化防御塔')
figure = etree.Element('figure', attrib={'class':'tower-design-reference', 'id':'tower-design-reference'})
img = etree.SubElement(figure, 'img', alt='模块化防御塔建模参考图：正面、右侧、背面与剖切结构', loading='lazy', decoding='async')
img.set('src', 'data:image/png;base64,' + base64.b64encode(reference.read_bytes()).decode('ascii'))
etree.SubElement(figure, 'figcaption').text = '本模型的建模参考图｜三视图（正面、右侧、背面）及剖切结构。此图用于指导模块化防御塔的造型与结构制作，不是Astra的建模输出。'
heading.addnext(figure)
css = etree.SubElement(new.xpath('//head')[0], 'style')
css.text = '.tower-design-reference{margin:24px 0!important;padding:16px;background:#fff;border:1px solid #dce4ef;border-radius:12px}.tower-design-reference img{display:block;width:100%!important;height:auto!important;max-height:none!important;object-fit:contain}.tower-design-reference figcaption{padding:12px 4px 0;color:#5d6d82;font-size:14px;line-height:1.8}'

for sid in ('s05', 's06'):
    assert etree.tostring(new.get_element_by_id(sid)) == etree.tostring(old.get_element_by_id(sid))
assert not new.xpath('//img[@src and not(starts-with(@src,"data:"))]')
assert len(new.xpath('//@id')) == len(set(new.xpath('//@id')))
backup = folder / 'GPT6_Astra综合报告_替换建模前备份_20260911.html'
if not backup.exists():
    backup.write_bytes(previous)
target.write_text('<!DOCTYPE html>\n' + html.tostring(new, encoding='unicode', method='html'), encoding='utf-8')
print('Updated:', target)
print('Preserved both development sections exactly; embedded reference image; backup:', backup)
