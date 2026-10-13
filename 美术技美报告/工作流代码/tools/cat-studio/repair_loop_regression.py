"""Offline, backed-up repair of proven continuity loop-flag regressions."""
from pathlib import Path
import datetime, json, shutil, sqlite3, struct, sys, zlib, zipfile

root=Path(__file__).resolve().parents[2]
data=root/'output/cat-studio'
db=sqlite3.connect(data/'studio.sqlite')
state=json.loads(db.execute("SELECT value FROM store WHERE key='state'").fetchone()[0])
if any(j['status'] in ['queued','running'] for j in state['jobs']):
    raise SystemExit('Active jobs exist; stop and finish them before repair.')
expected={};affected={}
for job in sorted(state['jobs'],key=lambda j:j['created']):
    if job['kind']!='quality-preview' or job.get('quality_mode')!='continuity':continue
    for c in job.get('candidates',[]):
        before,after=c['before'],c['after']
        original=expected.get(before['base'],before['meta']['loop'])
        expected[after['base']]=original
        if original and not after['meta']['loop'] and after['meta']['settings'].get('continuity_mode')=='sequence':
            affected[after['base']]=c['name']
print(json.dumps({'affected':affected},ensure_ascii=False))
if '--apply' not in sys.argv:raise SystemExit(0)
backup=root/'output/cat-studio-backups'/('loop-repair-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
backup.mkdir(parents=True)
with sqlite3.connect(backup/'studio.sqlite') as dst:db.backup(dst)

def looping_png(blob):
    result=bytearray(blob[:8]);pos=8
    while pos<len(blob):
        n=struct.unpack('>I',blob[pos:pos+4])[0];kind=blob[pos+4:pos+8];payload=blob[pos+8:pos+8+n]
        if kind==b'acTL':payload=payload[:4]+struct.pack('>I',0)
        result+=struct.pack('>I',len(payload))+kind+payload+struct.pack('>I',zlib.crc32(kind+payload)&0xffffffff)
        pos+=12+n
    return bytes(result)

for base in affected:
    folder=(data/base.removeprefix('/media/')).resolve()
    if not folder.is_relative_to(data.resolve()):raise ValueError('Invalid output path')
    saved=backup/folder.relative_to(data.resolve());saved.mkdir(parents=True)
    for name in ['animations.json','sprite_frames.tres','preview.png','spritesheet.zip']:
        shutil.copy2(folder/name,saved/name)
    meta=json.loads((folder/'animations.json').read_text(encoding='utf-8'))
    meta['loop']=True;meta['settings']['loop']=True
    (folder/'animations.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
    tres=folder/'sprite_frames.tres';tres.write_text(tres.read_text(encoding='utf-8').replace('"loop": false','"loop": true'),encoding='utf-8')
    png=folder/'preview.png';png.write_bytes(looping_png(png.read_bytes()))
    temp=folder/'spritesheet.loop-repair.zip'
    replacements={'animations.json','sprite_frames.tres','preview.png'}
    with zipfile.ZipFile(folder/'spritesheet.zip') as old,zipfile.ZipFile(temp,'w',zipfile.ZIP_DEFLATED) as new:
        for entry in old.infolist():
            new.writestr(entry,(folder/entry.filename).read_bytes() if entry.filename in replacements else old.read(entry.filename))
    temp.replace(folder/'spritesheet.zip')

def update(value):
    if isinstance(value,dict):
        if value.get('base') in affected and 'meta' in value:
            value['meta']['loop']=True;value['meta']['settings']['loop']=True
        for v in value.values():update(v)
    elif isinstance(value,list):
        for v in value:update(v)
update(state)
for p in state['projects']:
    for a in p.get('actions',[]):
        if a.get('exports') and a['exports'][-1]['base'] in affected and a['options'].get('continuity_mode')=='sequence':
            a['options']['loop']=True
db.execute("UPDATE store SET value=? WHERE key='state'",(json.dumps(state,ensure_ascii=False),));db.commit();db.close()
print('Repaired',len(affected),'outputs; backup:',backup)
