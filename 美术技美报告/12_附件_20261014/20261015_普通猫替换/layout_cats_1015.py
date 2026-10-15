from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
import numpy as np
import re, json, shutil, hashlib

root=Path(r'C:/Users/jominchen/Documents/ChatGPT/Purr Orbit')
src=root/'github-repo-sparse/美术技美报告/12_附件_20261014/原图'
out=root/'output/Cats_20261015'; out.mkdir(exist_ok=True)
names=['普通猫','长毛猫','Gigachad猫','良子猫','猫猫虫','招财猫','鹰头猫','高猫','机械猫','克苏鲁猫','太空猫']
factors=[.82,1,1.08,1.25,1.25,.92,1.08,1,1.12,1.12,.88]
files=sorted(src.glob('*.jpg'),key=lambda p:int(re.match(r'\d+',p.name)[0]))
files[0]=Path(r'C:/Users/jominchen/Downloads/猫/1普通猫.jpg')
font=lambda n:ImageFont.truetype('C:/Windows/Fonts/msyh.ttc',n)
canvas=Image.new('RGB',(4200,3700),'#fcfaf6'); d=ImageDraw.Draw(canvas)
d.text((150,85),'毛球计划 · 猫咪形象总览',font=font(82),fill='#342b29')
d.text((155,205),'2026.10.15  /  11 款角色 · 当前选图',font=font(34),fill='#887b73')
baselines=[1020,2450,3480]; records=[]
for i,p in enumerate(files):
 im=Image.open(p).convert('RGB'); a=np.asarray(im).astype(np.int16)
 bg=np.median(np.concatenate([a[:12].reshape(-1,3),a[-12:].reshape(-1,3),a[:,:12].reshape(-1,3),a[:,-12:].reshape(-1,3)]),axis=0)
 candidate=(np.max(abs(a-bg),axis=2)<42)&(a.min(axis=2)>200)
 mask=Image.fromarray(np.where(candidate,255,0).astype('uint8')).copy()
 for pt in [(0,0),(im.width-1,0),(0,im.height-1),(im.width-1,im.height-1)]:
  ImageDraw.floodfill(mask,pt,128,thresh=0)
 alpha=np.where(np.asarray(mask)==128,0,255).astype('uint8')
 rgba=im.convert('RGBA');rgba.putalpha(Image.fromarray(alpha))
 bbox=rgba.getbbox();rgba=rgba.crop(bbox)
 rgba.save(out/f'{i+1:02d}_{names[i]}_cutout.png')
 if i==7: scale=min(650/rgba.width,1140/rgba.height)
 else: scale=min(760/rgba.width,570/rgba.height)*factors[i]
 size=(round(rgba.width*scale),round(rgba.height*scale)); tile=rgba.resize(size,Image.Resampling.LANCZOS)
 row=i//4;col=i%4; count=4 if row<2 else 3
 cell=980; start=(4200-count*cell)//2
 x=start+col*cell+(cell-size[0])//2;y=baselines[row]-size[1]
 canvas.paste(tile,(x,y),tile)
 label=f'{i+1:02d}  {names[i]}'
 d.text((start+col*cell+cell//2,baselines[row]+65),label,font=font(43),fill='#342b29',anchor='mt')
 records.append(dict(number=i+1,name=names[i],source=p.name,source_sha256=hashlib.sha256(p.read_bytes()).hexdigest(),bbox=bbox,position=[x,y],size=size,baseline=baselines[row],scale=scale))
canvas.save(out/'猫咪形象总览_20261015.png')
preview=canvas.copy();preview.thumbnail((1680,1480));preview.save(out/'preview.jpg',quality=94)
(out/'layout.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
print(out)

