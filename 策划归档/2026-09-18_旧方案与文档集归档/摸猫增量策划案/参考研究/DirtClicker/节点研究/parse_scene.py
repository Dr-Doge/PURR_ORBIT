"""Read Godot RSRC data without running the game. Format reference: Godot 4.6 resource_format_binary.cpp and packed_scene.cpp (MIT)."""
from pathlib import Path
import struct,json
class Reader:
 def __init__(self,b): self.b=b;self.p=0
 def read(self,n):
  b=self.b[self.p:self.p+n];assert len(b)==n;self.p+=n;return b
 def num(self,fmt):return struct.unpack('<'+fmt,self.read(struct.calcsize('<'+fmt)))[0]
 def u(self):return self.num('I')
 def string(self):return self.read(self.u()).rstrip(b'\0').decode('utf-8')
 def sref(self):
  x=self.u();return self.read(x&0x7fffffff).rstrip(b'\0').decode() if x&0x80000000 else self.strings[x]
 def variant(self):
  t=self.u()
  if t==1:return None
  if t==2:return bool(self.u())
  if t==3:return self.num('i')
  if t==40:return self.num('q')
  if t in (4,41):return self.num('d' if t==41 or self.double else 'f')
  if t in (5,44):return self.string()
  if t in (10,11,12,13,14,15,16,17,18,20):
   n={10:2,11:4,12:3,13:4,14:4,15:6,16:9,17:12,18:6,20:4}[t];return [self.num('f' if t==20 or not self.double else 'd') for _ in range(n)]
  if t==22:
   n=self.num('H');m=self.num('H');a=[self.sref() for _ in range(n)];b=[self.sref() for _ in range(m&0x7fff)];return {'nodepath':('/' if m&0x8000 else '')+'/'.join(a)+(':'+':'.join(b) if b else '')}
  if t==24:
   sub=self.u()
   if sub==0:return None
   if sub in (2,3):return {'resource':('internal' if sub==2 else 'external'),'index':self.u()}
   raise ValueError(('object',sub))
  if t==26:
   n=self.u()&0x7fffffff;d={}
   for _ in range(n):k=self.variant();v=self.variant();d[k]=v
   return d
  if t==30:return [self.variant() for _ in range(self.u()&0x7fffffff)]
  if t==31:
   n=self.u();v=list(self.read(n));self.read((-n)%4);return v
  if t in (32,33,48,49):
   n=self.u();fmt={32:'i',33:'f',48:'q',49:'d'}[t];return [self.num(fmt) for _ in range(n)]
  if t==34:return [self.string() for _ in range(self.u())]
  if t in (35,36,37):
   n=self.u();dim={35:3,36:4,37:2}[t];return [[self.num('f') for _ in range(dim)] for _ in range(n)]
  raise ValueError(('variant',t,self.p))
 def parse(self):
  assert self.read(4)==b'RSRC';assert self.u()==0;self.u();self.version=[self.u(),self.u(),self.u()];self.type=self.string();self.num('Q');flags=self.u();self.double=bool(flags&4);self.num('Q')
  if flags&8:self.string()
  self.read(44);self.strings=[self.string() for _ in range(self.u())];self.ext=[]
  for _ in range(self.u()):
   d={'type':self.string(),'path':self.string()}
   if flags&2:d['uid']=self.num('Q')
   self.ext.append(d)
  self.ints=[{'path':self.string(),'offset':self.num('Q')} for _ in range(self.u())]
  for r in self.ints:
   self.p=r['offset'];r['type']=self.string();n=self.u();d={}
   for _ in range(n):name=self.sref();d[name]=self.variant()
   r['properties']=d
  return {'external':self.ext,'internal':self.ints}
def unpack_scene(resource):
 b=resource['internal'][-1]['properties']['_bundled'];names=b['names'];vals=b['variants'];raw=b['nodes'];out=[];idx=0
 for i in range(b['node_count']):
  parent,owner,typ,name,inst,pc=raw[idx:idx+6];idx+=6;props={}
  for _ in range(pc):pn,pv=raw[idx:idx+2];idx+=2;props[names[pn&0x3fffffff]]=vals[pv]
  gc=raw[idx];idx+=1;groups=raw[idx:idx+gc];idx+=gc
  out.append({'index':i,'parent':parent,'type':names[typ] if 0<=typ<len(names) else typ,'name':names[name&0x3ffff],'instance':vals[inst] if 0<=inst<len(vals) else inst,'properties':props})
 assert idx==len(raw),(idx,len(raw))
 return out
if __name__=='__main__':
 here=Path(__file__).parent
 for p in here.glob('*.scn'):
  r=Reader(p.read_bytes()).parse();(here/(p.stem+'.parsed.json')).write_text(json.dumps(r,ensure_ascii=False,indent=2),encoding='utf-8')
  ns=unpack_scene(r);(here/(p.stem+'.nodes.json')).write_text(json.dumps(ns,ensure_ascii=False,indent=2),encoding='utf-8');print(p.name,len(ns))
  for n in ns:
   if any(k in str(n['properties']) for k in ['key_node','key_stat','KEY_NODE','key_upgrade']):print(n)
