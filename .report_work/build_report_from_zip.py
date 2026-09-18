from pathlib import Path
from copy import deepcopy
import zipfile, posixpath, mimetypes, base64, hashlib, json
from lxml import html, etree

root = Path(r'C:/Users/ruohaojing/Desktop/爽开/地球盲盒考古/报告')
original = root / 'GPT6_Astra综合评估报告_策划开发与三维建模.html'
output = root / 'GPT6_Astra综合报告_新版建模与游戏开发.html'
archive = Path(r'C:/Users/ruohaojing/Documents/WXWork/1688855188862276/Cache/File/2026-09/GPT-Blender.zip')
before = original.read_bytes()
old = html.fromstring(before)
with zipfile.ZipFile(archive) as z:
    report = next(n for n in z.namelist() if n.endswith('.html'))
    doc = html.fromstring(z.read(report))
    embedded = 0
    for img in doc.xpath('//img[@src]'):
        src = img.get('src')
        if not src or src.startswith('data:'):
            continue
        asset = posixpath.normpath(posixpath.join(posixpath.dirname(report), src))
        assert asset.startswith('jhjg/assets/') and asset in z.namelist(), asset
        mime = mimetypes.guess_type(asset)[0] or 'application/octet-stream'
        img.set('src', 'data:' + mime + ';base64,' + base64.b64encode(z.read(asset)).decode())
        embedded += 1

for script in doc.xpath('//script'):
    script.getparent().remove(script)
for dialog in doc.xpath('//dialog'):
    wrapper = dialog.getparent()
    if wrapper.tag == 'div' and len(wrapper) == 1:
        wrapper.getparent().remove(wrapper)
    else:
        wrapper.remove(dialog)
for node in doc.iter():
    for key in list(node.attrib):
        if key.lower().startswith('on') or key.startswith('data-page-'):
            del node.attrib[key]

title = 'Astra 综合汇报｜三维建模与游戏开发'
doc.xpath('//title')[0].text = title
doc.xpath('//header/h1')[0].text = title
doc.xpath('//header/*[@class="eyebrow"]')[0].text = 'ASTRA · BLENDER & GAME DEVELOPMENT · 2026.09'
lead = doc.xpath('//header/p[@class="lead"]')[0]
lead.clear()
lead.set('class', 'lead')
lead.text = '本报告介绍我们如何使用 Astra 完成三维建模与游戏开发工作。前半部分按建筑、道具、角色三个模块展示建模实测及公开作品对照；后半部分保留游戏项目中从零散策划到完整流程、界面布局与美术资源组合的使用观察。报告重点关注实际产出、协作方式与当前能力边界。'
nav = doc.xpath('//nav')[0]
nav.xpath('./strong')[0].text = 'ASTRA 综合汇报'
for anchor in nav.xpath('./a'):
    if anchor.get('href') in ('#cat-arch', '#cat-props', '#cat-char'):
        anchor.text = anchor.text.split(' ', 1)[-1]
for target, label in [('s05', '⑤ 策划实装'), ('s06', '⑥ 界面与素材')]:
    anchor = etree.Element('a', href='#' + target)
    anchor.text = label
    nav.insert(len(nav) - 1, anchor)

summary = doc.xpath('//*[@id="conclusion-top"]')[0]
box = summary.xpath('.//*[contains(concat(" ",normalize-space(@class)," ")," conclusion-box ")]')[0]
for node in box.iter():
    if node.text:
        node.text = node.text.replace('本次汇报合计', '建模部分合计')
    if node.tail:
        node.tail = node.tail.replace('本次汇报合计', '建模部分合计')
extra = etree.SubElement(box, 'p')
extra.text = '游戏开发方面，Astra在本项目中更善于将零散需求串成可运行的流程，并结合交互目的安排界面与素材。它减少了逐项解释和局部修补的负担，但玩法方向、体验判断和最终验收仍由人工负责；具体与 Sol 的表现差异见后半部分。'

footer = doc.xpath('//footer')[0]
preserved = []
for section_id in ('s05', 's06'):
    section = deepcopy(old.xpath(f'//*[@id="{section_id}"]')[0])
    preserved.append((''.join(section.itertext()), section_id))
    section.set('class', (section.get('class', '') + ' cat dev-report').strip())
    footer.addprevious(section)
footer.clear()
footer.set('class', 'doc-footer')
footer.text = '建模部分采用《Astra x Blender 汇报》的内容与版式；策划实装及界面部分保留原综合报告05、06。图片已内嵌，可离线阅读；点击图片可放大。原报告未覆盖。'

style = etree.SubElement(doc.xpath('//head')[0], 'style')
style.text = '''
.dev-report{padding-top:38px!important;padding-bottom:44px!important}
section[id]{scroll-margin-top:76px}
.dev-report h2{margin:0 0 22px;font-size:30px;line-height:1.4;color:var(--ink)}
.dev-report h2 span{color:var(--blue);margin-right:12px}
.dev-report .claim{background:#eaf1ff;border:1px solid #d4e1f8;border-radius:12px;padding:26px 28px;font-size:17px;line-height:1.8;margin:20px 0}
.dev-report .claim strong{color:#245ec5;font-size:19px}
.dev-report .evidence{color:var(--dim);margin:18px 0;line-height:1.85}
.dev-report .table-scroll{overflow-x:auto;border:1px solid var(--line);border-radius:12px;margin:24px 0;background:white}
.dev-report table{width:100%;border-collapse:collapse;background:white;font-size:15px;table-layout:fixed}
.dev-report .image-comparison{min-width:680px}
.dev-report .image-comparison col.scene{width:18%}
.dev-report .image-comparison col:not(.scene){width:41%}
.dev-report .table-scroll .workflow-comparison{margin:0}
.dev-report th,.dev-report td{border:1px solid var(--line);padding:18px;vertical-align:top;overflow-wrap:anywhere}
.dev-report thead th{background:#eaf0f8;color:var(--ink);font-weight:700;text-align:left}
.dev-report tbody th{background:#f4f7fb;text-align:left;color:var(--ink)}
.dev-report figure{margin:0}
.dev-report button.zoom{display:block;width:100%;padding:0;border:0;background:#f4f7fb;cursor:zoom-in;border-radius:8px;overflow:hidden}
.dev-report button.zoom svg{display:block;width:100%;height:auto;max-height:540px}
.dev-report .caption-row td{font-size:14px;color:var(--dim);background:#fbfcfe;line-height:1.8}
.dev-report .workflow-comparison{border:1px solid var(--line);margin:24px 0}
.dev-report .workflow-examples{background:white;border:1px solid var(--line);border-radius:12px;padding:24px 30px 24px 48px}
.dev-report li{margin:12px 0}
#report-zoom{padding:52px 16px 16px;background:#101b2c;border:1px solid #456080;border-radius:12px;max-width:96vw;max-height:96vh;color:white;overflow:auto}
#report-zoom::backdrop{background:rgba(4,11,23,.85)}
#report-zoom .zoom-content img,#report-zoom .zoom-content svg{display:block;width:auto;height:auto;max-width:90vw;max-height:80vh;margin:auto;object-fit:contain}
#report-zoom .zoom-close{position:absolute;right:14px;top:10px;background:#fff;border:0;border-radius:6px;padding:7px 14px;cursor:pointer}
@media(max-width:680px){.dev-report{padding-left:18px!important;padding-right:18px!important}.dev-report .claim{padding:20px}.dev-report h2{font-size:25px}.dev-report th,.dev-report td{padding:10px}.dev-report .workflow-comparison{font-size:13px}}
'''
body = doc.xpath('//body')[0]
dialog = html.fragment_fromstring('<dialog id="report-zoom" aria-label="图片放大预览"><button class="zoom-close" aria-label="关闭大图">关闭 ×</button><div class="zoom-content"></div></dialog>')
body.append(dialog)
script = etree.SubElement(body, 'script')
script.text = '''
const modal=document.getElementById('report-zoom');
const content=modal.querySelector('.zoom-content');
function showImage(source){content.replaceChildren(source.cloneNode(true));const copy=content.firstElementChild;copy.removeAttribute('tabindex');copy.removeAttribute('role');copy.removeAttribute('id');if(copy.tagName==='IMG')copy.loading='eager';modal.showModal();}
document.querySelectorAll('figure img').forEach(img=>{img.tabIndex=0;img.setAttribute('role','button');img.setAttribute('aria-label','放大图片：'+(img.alt||'报告配图'));img.style.cursor='zoom-in';img.addEventListener('click',()=>showImage(img));img.addEventListener('keydown',e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();showImage(img)}})});
document.querySelectorAll('button.zoom').forEach(button=>{button.type='button';button.setAttribute('aria-label','放大对比图片');button.addEventListener('click',()=>showImage(button.querySelector('svg,img')))});
modal.querySelector('.zoom-close').onclick=()=>modal.close();
modal.addEventListener('click',e=>{if(e.target===modal)modal.close()});
'''

ids = doc.xpath('//@id')
assert len(ids) == len(set(ids)), 'duplicate ids'
for text, sid in preserved:
    assert ''.join(doc.xpath(f'//*[@id="{sid}"]')[0].itertext()) == text
assert not doc.xpath('//img[@src and not(starts-with(@src,"data:"))]')
assert original.read_bytes() == before
output.write_text('<!DOCTYPE html>\n' + html.tostring(doc, encoding='unicode', method='html'), encoding='utf-8')
print(json.dumps({'output':str(output),'bytes':output.stat().st_size,'zip_images':embedded,'retained_svg_images':len(doc.xpath('//*[@id="s06"]//*[local-name()="image"]')),'original_sha256':hashlib.sha256(before).hexdigest()},ensure_ascii=False))
