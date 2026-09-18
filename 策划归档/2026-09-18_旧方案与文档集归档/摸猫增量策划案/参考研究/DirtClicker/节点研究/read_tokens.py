from pathlib import Path
import sys,struct,re,json,collections
r=Path(__file__).parent;sys.path.insert(0,str(r/'python_deps'));import zstandard
from parse_scene import Reader
class ConstReader(Reader):
 def variant(self):
  t=self.u();kind=t&255;wide=bool(t&0x10000)
  if kind==0:return None
  if kind==1:return bool(self.u())
  if kind==2:return self.num('q' if wide else 'i')
  if kind==3:return self.num('d' if wide else 'f')
  if kind in (4,21):
   n=self.u();s=self.read(n).decode();self.read((-n)%4);return s
  if kind in (5,6,7,8,9,10,20):
   n={5:2,6:2,7:4,8:4,9:3,10:3,20:4}[kind];return [self.num('i' if kind in (6,8,10) else 'f') for _ in range(n)]
  raise ValueError(('constant',kind,t,self.p))
names=re.findall(r'^\s*"(.*?)",', (r/'gdscript_tokenizer.cpp').read_text().split('static const char *token_names[] = {')[1].split('};')[0],re.M)
for path in r.glob('*.gdc'):
 raw=path.read_bytes();assert raw[:4]==b'GDSC' and struct.unpack_from('<I',raw,4)[0]==101
 size=struct.unpack_from('<I',raw,8)[0];raw=zstandard.ZstdDecompressor().decompress(raw[12:]) if size else raw[12:];assert not size or len(raw)==size
 f=ConstReader(raw);ic,cc,lc,tc=[f.u() for _ in range(4)];ids=[]
 for _ in range(ic):ids.append(bytes(b^0xb6 for b in f.read(f.u()*4)).decode('utf-32le'))
 const=[f.variant() for _ in range(cc)];lines={};cols={}
 for _ in range(lc):k=f.u();lines[k]=f.u()
 for _ in range(lc):k=f.u();cols[k]=f.u()
 tokens=[];linebuf=collections.defaultdict(list);linecols={}
 for i in range(tc):
  k=f.u() if f.b[f.p]&0x80 else f.num('B');line=f.u();typ=k&127;index=k>>8
  val=ids[index] if typ in (1,2) else json.dumps(const[index],ensure_ascii=False) if typ==3 else names[typ]
  tokens.append({'line':line,'type':typ,'text':val})
  if i in cols:linecols[line]=cols[i]
  linebuf[line].append(val)
 assert f.p==len(raw),(path,f.p,len(raw))
 out=['# Reconstructed token text for research; not original source formatting.']
 for line in range(1,max(linebuf)+1):out.append((' '*max(0,linecols.get(line,1)-1))+' '.join(linebuf[line]))
 (r/(path.stem+'.tokens.gd.txt')).write_text('\n'.join(out)+'\n',encoding='utf-8');(r/(path.stem+'.tokens.json')).write_text(json.dumps(tokens,ensure_ascii=False,indent=2),encoding='utf-8');print(path.name,tc,'tokens')
