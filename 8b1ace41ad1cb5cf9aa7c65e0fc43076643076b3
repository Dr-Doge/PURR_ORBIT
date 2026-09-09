from pathlib import Path
import re
from docx import Document
from docx.shared import Cm, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.opc.constants import RELATIONSHIP_TYPE as RT

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '地球盲盒考古' / '策划案'
source = OUT / '地球盲盒考古_基础策划案_v0.1.md'
doc = Document()
sec = doc.sections[0]
sec.page_width, sec.page_height = Cm(21), Cm(29.7)
sec.top_margin, sec.bottom_margin = Cm(1.8), Cm(1.7)
sec.left_margin, sec.right_margin = Cm(1.9), Cm(1.9)
sec.footer_distance = Cm(.8)
for name in ['Normal', 'Title', 'Subtitle', 'Heading 1', 'Heading 2', 'Heading 3']:
    s = doc.styles[name]
    s.font.name = 'Microsoft YaHei'
    s.font.color.rgb = RGBColor(0,0,0)
    s._element.get_or_add_rPr().rFonts.set(qn('w:eastAsia'), 'Microsoft YaHei')
    s.paragraph_format.space_after = Pt(6)
    s.paragraph_format.line_spacing = Pt(15.8)
doc.styles['Normal'].font.size = Pt(10.5)
doc.styles['Title'].font.size = Pt(23)
doc.styles['Title'].paragraph_format.line_spacing = Pt(30)
doc.styles['Title'].paragraph_format.space_after = Pt(9)
doc.styles['Heading 1'].font.size = Pt(16)
doc.styles['Heading 1'].paragraph_format.line_spacing = Pt(23)
doc.styles['Heading 1'].paragraph_format.space_before = Pt(0)
doc.styles['Heading 1'].paragraph_format.space_after = Pt(11)
doc.styles['Heading 2'].font.size = Pt(12)
doc.styles['Heading 2'].paragraph_format.line_spacing = Pt(18)
doc.styles['Heading 2'].paragraph_format.space_before = Pt(9)
doc.styles['Heading 2'].paragraph_format.space_after = Pt(5)
doc.core_properties.title = '地球盲盒考古基础策划案'
doc.core_properties.subject = '基础玩法改版与团队讨论'
doc.core_properties.author = ''
doc.core_properties.keywords = '考古 盲盒 增量 自动化 游戏策划'
for style in doc.styles:
    for border in list(style.element.iter(qn('w:pBdr'))):
        border.getparent().remove(border)

def inline(p, text):
    pattern = r'(\*\*.*?\*\*|\[.*?\]\(.*?\))'
    for t in re.split(pattern, text):
        if not t: continue
        if t.startswith('**'):
            p.add_run(t[2:-2]).bold = True
        elif t.startswith('[') and '](' in t:
            m = re.fullmatch(r'\[(.*?)\]\((.*?)\)',t)
            h=OxmlElement('w:hyperlink')
            h.set(qn('r:id'),p.part.relate_to(m[2],RT.HYPERLINK,is_external=True))
            r=OxmlElement('w:r'); pr=OxmlElement('w:rPr')
            color=OxmlElement('w:color'); color.set(qn('w:val'),'285D75'); pr.append(color)
            r.append(pr); tx=OxmlElement('w:t'); tx.text=m[1]; r.append(tx); h.append(r); p._p.append(h)
        else: p.add_run(t)

def table(lines):
    data = [[x.strip() for x in l.strip('|').split('|')] for l in lines]
    data = [r for r in data if not all(re.fullmatch(r':?-+:?', c) for c in r)]
    n=len(data[0]); t=doc.add_table(rows=0,cols=n)
    t.alignment=WD_TABLE_ALIGNMENT.CENTER; t.autofit=False
    if n==4: widths=[3.1,4.0,5.0,5.1]
    elif n==3: widths=[3.5,6.5,7.2]
    else: widths=[17.2/n]*n
    for c,w in zip(t.columns,widths): c.width=Cm(w)
    borders=OxmlElement('w:tblBorders')
    for edge in ['top','left','bottom','right','insideH','insideV']:
        el=OxmlElement('w:'+edge); el.set(qn('w:val'),'single'); el.set(qn('w:sz'),'4'); el.set(qn('w:color'),'D9D9D9'); borders.append(el)
    t._tbl.tblPr.append(borders)
    for i,row in enumerate(data):
        cells=t.add_row().cells
        trpr=t.rows[-1]._tr.get_or_add_trPr()
        trpr.append(OxmlElement('w:cantSplit'))
        if i==0: trpr.append(OxmlElement('w:tblHeader'))
        for j,(cell,txt) in enumerate(zip(cells,row)):
            cell.width=Cm(widths[j]); cell.vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.CENTER
            tcpr=cell._tc.get_or_add_tcPr()
            shade=OxmlElement('w:shd'); shade.set(qn('w:fill'),'DCE8EE' if i==0 else ('F5F7F8' if i%2==0 else 'FFFFFF')); tcpr.append(shade)
            margins=OxmlElement('w:tcMar')
            for edge,v in [('top','75'),('bottom','75'),('left','95'),('right','95')]:
                e=OxmlElement('w:'+edge); e.set(qn('w:w'),v); e.set(qn('w:type'),'dxa'); margins.append(e)
            tcpr.append(margins)
            p=cell.paragraphs[0]; p.paragraph_format.space_after=Pt(0); p.paragraph_format.line_spacing=Pt(13.5)
            inline(p,txt)
            for r in p.runs:
                r.font.size=Pt(9.3); r.bold=(i==0)
            if len(txt)<10: p.alignment=WD_ALIGN_PARAGRAPH.CENTER
    doc.add_paragraph().paragraph_format.space_after=Pt(0)

lines=source.read_text(encoding='utf-8').splitlines(); i=0; next_page=False
while i<len(lines):
    line=lines[i].strip()
    if not line: i+=1; continue
    if line=='<!-- page -->': next_page=True
    elif line.startswith('|'):
        rows=[]
        while i<len(lines) and lines[i].strip().startswith('|'):
            rows.append(lines[i].strip()); i+=1
        table(rows); continue
    elif line.startswith('# '): inline(doc.add_paragraph(style='Title'),line[2:])
    elif line.startswith('## '):
        p=doc.add_paragraph(style='Heading 1'); p.paragraph_format.page_break_before=next_page; next_page=False; inline(p,line[3:])
    elif line.startswith('### '): inline(doc.add_paragraph(style='Heading 2'),line[4:])
    elif line.startswith('- '):
        p=doc.add_paragraph(); p.paragraph_format.left_indent=Cm(.25); p.paragraph_format.first_line_indent=Cm(-.25)
        inline(p,'• '+line[2:])
    else: inline(doc.add_paragraph(),line)
    i+=1
footer=sec.footer.paragraphs[0]; footer.alignment=WD_ALIGN_PARAGRAPH.CENTER
r=footer.add_run('地球盲盒考古  v0.1  ·  '); r.font.size=Pt(8)
field=OxmlElement('w:fldSimple'); field.set(qn('w:instr'),'PAGE'); footer._p.append(field)
path=OUT/'地球盲盒考古_基础策划案_v0.1.docx'
doc.save(path)
print(path)
print('Characters:',len(source.read_text(encoding='utf-8')))
