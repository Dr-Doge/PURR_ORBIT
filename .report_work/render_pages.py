from pathlib import Path
import pypdfium2 as pdfium
folder=Path(__file__).parent/'render'
pdf=pdfium.PdfDocument(folder/'report.pdf')
for n,page in enumerate(pdf,1):
    page.render(scale=1.5).to_pil().save(folder/f'page-{n}.png')
    text=page.get_textpage().get_text_range()
    print(n, len(text), text[:70].replace('\n',' | ').encode('ascii','backslashreplace').decode())
