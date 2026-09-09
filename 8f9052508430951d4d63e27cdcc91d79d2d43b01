from pathlib import Path
import pypdfium2 as pdfium
from PIL import Image, ImageOps, ImageDraw
p=Path(__file__).parent/'render'
pdf=pdfium.PdfDocument(p/'plan.pdf')
thumbs=[]
for n,page in enumerate(pdf,1):
    im=page.render(scale=1.4).to_pil().convert('RGB')
    im.save(p/f'page-{n}.png')
    txt=page.get_textpage().get_text_range()
    (p/f'page-{n}.txt').write_text(txt,encoding='utf-8')
    print(n,len(txt),txt[:55].encode('ascii','backslashreplace').decode())
    im.thumbnail((420,595)); card=Image.new('RGB',(440,630),'#dedede');card.paste(im,((440-im.width)//2,20)); ImageDraw.Draw(card).text((12,608),str(n),fill='black');thumbs.append(card)
for batch in range(0,len(thumbs),4):
    sheet=Image.new('RGB',(880,1260),'white')
    for j,im in enumerate(thumbs[batch:batch+4]):sheet.paste(im,((j%2)*440,(j//2)*630))
    sheet.save(p/f'contact-{batch//4+1}.png')
