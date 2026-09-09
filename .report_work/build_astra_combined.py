from pathlib import Path
from copy import deepcopy
from lxml import html, etree

ROOT=Path(r'C:/Users/ruohaojing/Desktop/爽开')
REPORT=ROOT/'地球盲盒考古/报告'
SOURCE=Path(r'C:/Users/ruohaojing/Documents/WXWork/1688855188862276/Cache/File/2026-09/GPT-6 Astra三维建模能力评估_分享版.html')
doc=html.fromstring((REPORT/'GPT6_Astra实际使用报告_模型对比.html').read_text(encoding='utf-8'))
model=html.fromstring(SOURCE.read_text(encoding='utf-8'))
main=doc.xpath('//main')[0]

def el(tag,text=None,**attrs):
    node=etree.Element(tag,attrib=attrs)
    node.text=text
    return node

def highlight(text):
    p=el('p',**{'class':'claim'})
    p.append(el('strong',text))
    return p

# Align captions independently of the image heights in the existing comparison tables.
for table in main.xpath('.//table'):
    table.set('class','image-comparison')
    for row in list(table.xpath('./tbody/tr')):
        cells=row.findall('td')
        captions=[]
        for cell in cells:
            caption=cell.find('.//figcaption')
            captions.append(''.join(caption.itertext()) if caption is not None else '')
            if caption is not None:
                caption.getparent().remove(caption)
        row.find('th').set('rowspan','2')
        caprow=el('tr',**{'class':'caption-row'})
        for text in captions:
            caprow.append(el('td',text))
        row.addnext(caprow)

title='GPT6 Astra实际使用综合报告'
doc.xpath('//title')[0].text=title
main.find('header/h1').text=title
intro=main.find('header/p[@class="intro"]')
intro.clear()
intro.set('class','intro claim executive-summary')
intro.append(el('strong','综合两份报告，Astra的主要进步在于更好地理解具体需求，并将策划、交互界面和现有素材连接为可评审、可修改的结果；本轮使用中，问答与返工负担有所减轻。三维制作方面，配合Blender MCP时，它在基础硬表面、模块化结构、自然语言控制和后续修改上表现较好，但复杂曲面、有机角色和参考图精确还原仍弱于本次对照的Visvise等工具，建模效率也可能受到过多独立网格的影响。通过Computer Use手动操作Blender的方式，在本次测试中的速度、质量与额度消耗尚不适合正式建模工作流。因此，Astra适合辅助明确需求的设计与实现，仍不能代替人进行玩法决策、审美取舍、精细资产制作和最终质量验收。'))
intro.getnext().text='我们用AI辅助游戏策划、引擎原型与界面制作，并结合另一组道具、建筑和角色建模测试，观察Astra在实际生产中的适用范围。以下先介绍原有四项使用观察，再展示三维建模结果。'
footer=main.find('footer')
main.remove(footer)
nav=main.find('header/nav')
for num,label in [('05','建模结论'),('06','能力对比'),('07','MCP案例'),('08','界面操作建模')]:
    nav.append(el('a',num+' '+label,href='#s'+num))

mapping={
 'overview':('05','三维建模的适用范围','Astra配合Blender MCP适合辅助基础建模和模块化制作，优势在于语言控制、可修改性和结构可控性；复杂形体与精细还原仍需专业美术主导。通过Computer Use手动操作的方式，目前尚不足以支撑正式建模工作流。'),
 'comparison':('06','三维建模能力对比','Astra配合Blender MCP在模块化、语言控制和模型修改上表现较好；Visvise等传统AI 3D工具在本次测试中的软表面、复杂形状、建模速度及参考图还原方面更占优势。两类工具适合承担不同的制作任务。'),
 'mcp':('07','Blender MCP建模案例','Astra能够制作较清楚的基础结构，并落实可拆解等定制要求；结构越复杂、造型越有机，错误与还原不足越明显。它更适合作为人工建模的辅助，而不是直接交付所有类型的成品资产。'),
 'computer':('08','Computer Use建模案例','Astra通过Computer Use可以操作Blender搭建基础形体，但本次测试中的速度、细节与结构完成度仍不足。长时间操作的额度消耗也限制了这种方式用于正式建模流程。')
}
for source_id,(num,heading,conclusion) in mapping.items():
    section=deepcopy(model.get_element_by_id(source_id))
    section.set('id','s'+num)
    section.set('class','model-section')
    first=section.find('div')
    if first is not None and first.get('class')=='section-title':
        section.remove(first)
    h2=el('h2')
    span=el('span',num);span.tail=' '+heading;h2.append(span)
    section.insert(0,h2)
    section.insert(1,highlight(conclusion))
    if source_id=='overview':
        attribution=el('p','本部分整理自《GPT-6 Astra三维建模能力评估》补充测试报告。Blender MCP指通过工具接口驱动Blender；Computer Use指通过电脑界面进行操作。建模对照对象为Visvise等AI 3D工具。',**{'class':'evidence'})
        section.insert(2,attribution)
    for item in section.xpath('.//*[@id]'):
        item.set('id','model-'+item.get('id'))
    # Retain prompt text as reference material only; never run scripts from the attachment.
    for script in section.xpath('.//script'):
        script.getparent().remove(script)
    for node in section.iter():
        for key in list(node.attrib):
            if key.lower().startswith('on'):
                del node.attrib[key]
    for p in section.xpath('.//p[@class="case-copy"]'):
        text=''.join(p.itertext())
        p.clear();p.set('class','claim case-copy');p.append(el('strong',text))
    for p in section.xpath('.//p[@class="conclusion"]'):
        p.set('class','claim')
    for button in section.xpath('.//button[@class="image-button"]'):
        button.set('class','zoom')
    # Real reference/result comparisons use tables. The tower's four views remain a gallery.
    for gallery in list(section.xpath('.//div[contains(@class,"gallery")]')):
        article=gallery.getparent()
        if article.get('id')=='model-tower':
            gallery.set('class','model-gallery')
            gallery.attrib.pop('style',None)
            continue
        figures=list(gallery.findall('figure'))
        table=el('table',**{'class':'model-images image-comparison'})
        thead=el('thead');headerrow=el('tr');thead.append(headerrow);table.append(thead)
        tbody=el('tbody');imgrow=el('tr');caprow=el('tr',**{'class':'caption-row'})
        for figure in figures:
            caption=figure.find('figcaption')
            label=''.join(caption.itertext())
            headerrow.append(el('th',label,scope='col'))
            figure.remove(caption)
            td=el('td');td.append(figure);imgrow.append(td)
            caprow.append(el('td',label))
        tbody.extend([imgrow,caprow]);table.append(tbody)
        wrapper=el('div',**{'class':'table-scroll'});wrapper.append(table)
        article.replace(gallery,wrapper)
    main.append(section)

footer.find('h2').text='综合使用建议与资料说明'
footer.find('p').clear()
footer.find('p').append(el('strong','建议由人确定目标与质量标准，Astra承担策划整理、规则实装、界面组合和基础模型辅助制作；复杂资产、玩法体验和最终交付继续由专业人员把关。'))
footer.append(el('p','三维部分保留补充报告的16张图片、6组原始提示词与定性评价。高塔约30分钟、Computer Use一个多小时及额度占用均为原测试记录；额度描述不等同于可核实的实际付费金额。两份报告属于实际使用观察，不是同条件的标准化模型排名。'))
main.append(footer)

css='''
/* Consolidated report: highlighted conclusions and aligned caption rows. */
.claim{background:#eef4fa;border:1px solid #dce7f2;border-radius:7px;padding:19px 23px;color:#243c54;line-height:1.85;white-space:normal}
.executive-summary{background:#edf5f1;border-color:#d6e7df;color:#243c32;margin:22px 0;font-size:18px}
.caption-row td{background:#f7f9fc;color:#586675;font-size:13px;line-height:1.7;text-align:left;padding:13px 18px;vertical-align:top}
.image-comparison td{vertical-align:middle}.image-comparison .zoom{background:transparent}
.model-section .scope{display:grid;grid-template-columns:repeat(3,1fr);gap:20px;margin:20px 0}
.model-section .scope p{font-size:14px;color:#586675}
.model-section .summary-grid{display:grid;grid-template-columns:1fr 1fr;gap:30px}
.model-section h3{font-size:21px;color:#243c54}.model-section li{margin:8px 0}
.model-section .summary-grid .claim{font-size:16px}
.model-section .case{border-top:1px solid #e0e5eb;padding-top:24px;margin-top:30px}
.model-section .case-copy{font-size:17px}
.model-section .case figure{max-width:none;margin:0}
.model-section .case .zoom{padding:10px;min-height:240px;display:flex;align-items:center;justify-content:center;background:#f4f6f8}
.model-section img{width:auto;height:auto;max-width:100%;max-height:400px;object-fit:contain;display:block}
.model-section .model-images{min-width:620px}
.model-section .model-images th{font-size:15px}
.model-section .model-images td{padding:12px}
.model-section .model-images .caption-row td{text-align:center;font-size:13px}
.model-gallery{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:20px;margin:20px 0}
.model-gallery .zoom{height:380px}.model-gallery img{max-height:350px}
.model-gallery figcaption{text-align:center}
.model-section details{background:#f6f8fa;border:1px solid #e0e5eb;border-radius:6px;padding:14px 18px;margin-top:20px}
.model-section summary{cursor:pointer;font-weight:600}.model-section details p{font-size:14px;line-height:1.9}
.model-section .legend{display:flex;align-items:center;gap:10px;flex-wrap:wrap;margin:12px 0}
.model-section .legend span{padding:2px 12px;border-radius:4px}
.model-section .strong{background:#d6efde}.model-section .medium{background:#fff0b3}.model-section .weak{background:#f8d4d6}
.model-section .rating{text-align:center;font-weight:bold}
.model-section .table-wrap{overflow-x:auto;max-width:100%}
.model-section table caption{text-align:left;font-size:14px;color:#586675;padding:0 0 12px}
dialog .content img{max-width:100%;max-height:76vh;width:auto;height:auto;object-fit:contain;display:block;margin:auto}
dialog .zoom{display:flex;align-items:center;justify-content:center}dialog .content figure{margin:0}
@media(max-width:700px){.claim{padding:15px 17px}.model-section .scope,.model-section .summary-grid,.model-gallery{grid-template-columns:1fr}.model-section .case .zoom{min-height:180px}}
@media print{.claim{break-inside:avoid;-webkit-print-color-adjust:exact;print-color-adjust:exact}.caption-row{break-before:avoid}.model-section .summary-grid{display:block}.model-section details{break-inside:avoid}.model-section img{max-height:250px}.model-gallery .zoom{height:250px}.model-section .model-images{min-width:0}}
'''
doc.find('head').append(el('style',css))
# Single shared preview handler supports both source formats, without importing their scripts.
script=doc.find('body/script')
script.text='''const modal=document.querySelector('dialog');let opener=null;document.querySelectorAll('figure > button.zoom').forEach(button=>button.addEventListener('click',()=>{opener=button;const f=button.parentElement.cloneNode(true);const b=f.querySelector('button');const holder=document.createElement('div');holder.className='zoom';while(b.firstChild)holder.append(b.firstChild);b.replaceWith(holder);modal.querySelector('.content').replaceChildren(f);modal.showModal();}));modal.querySelector('.close').addEventListener('click',()=>modal.close());modal.addEventListener('click',event=>{if(event.target===modal)modal.close();});modal.addEventListener('close',()=>{if(opener)opener.focus();});'''
output=REPORT/'GPT6_Astra综合评估报告_策划开发与三维建模.html'
output.write_text('<!doctype html>\n'+html.tostring(doc,encoding='unicode',method='html'),encoding='utf-8')
assert len(main.findall('section'))==8
assert len(main.xpath('.//svg'))==11
assert len(main.xpath('.//img'))==16
assert len(main.xpath('.//details'))==6
assert len(main.xpath('.//tr[@class="caption-row"]'))==7
ids=doc.xpath('//@id');assert len(ids)==len(set(ids))
print(output)
print('Sections: 8; original images: 11; modeling images: 16; retained prompts: 6; caption rows: 7')
