"""Local-only asset canvas. Keys stay server-side; generation is explicit, never retried."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
from contextlib import asynccontextmanager
from contextvars import ContextVar, copy_context
import secrets, zipfile, hashlib
import base64, hmac, io, json, os, re, shutil, sqlite3, subprocess, threading, time, uuid
import httpx
from PIL import Image
from fastapi import FastAPI, HTTPException, Request, UploadFile, File, Form
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from processor import process_video, process_sheet, pack_frames
from pixel_stability import stabilize_frames

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1] if len(HERE.parents)>1 else HERE
DATA=Path(os.environ.get('ASSET_CANVAS_DATA',ROOT/'output/cat-studio')).resolve()
DATA.mkdir(parents=True,exist_ok=True)
(DATA/'.gdignore').touch(exist_ok=True)
LOCK=threading.RLock();PROCESS_LOCK=threading.Lock()
POOL=ThreadPoolExecutor(max_workers=2)
DB=sqlite3.connect(DATA/'studio.sqlite',check_same_thread=False)
DB.execute('CREATE TABLE IF NOT EXISTS store (key TEXT PRIMARY KEY, value TEXT NOT NULL)');DB.commit()
row=DB.execute('SELECT value FROM store WHERE key=?',('state',)).fetchone()
STATE=json.loads(row[0]) if row else {'projects':[],'jobs':[],'settings':{'image_model':'gpt-image-2','video_model':'doubao-seedance-2-0-mini-260615'}}
KEYS={}
SECRET_FILE=DATA/'.credentials'
def read_saved_keys():
    if not SECRET_FILE.exists():return {}
    try:
        values=json.loads(SECRET_FILE.read_text(encoding='utf-8'))
        return {k:v for k,v in values.items() if k in ['OPENAI_API_KEY','ARK_API_KEY'] and isinstance(v,str)}
    except (ValueError,OSError):raise RuntimeError('无法读取已保存的连接密钥，请检查数据目录权限')

def persist_keys(updates):
    with LOCK:
        values=read_saved_keys();values.update(updates)
        temp=SECRET_FILE.with_name('.credentials-'+uuid.uuid4().hex)
        try:
            fd=os.open(str(temp),os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
            with os.fdopen(fd,'w',encoding='utf-8') as stream:
                json.dump(values,stream);stream.flush();os.fsync(stream.fileno())
            os.replace(temp,SECRET_FILE)
        finally:
            if temp.exists():temp.unlink()
        KEYS.update(updates)
def public_mode():return os.environ.get('ASSET_CANVAS_PUBLIC','')=='1'

# Public credentials are private to an anonymous browser session, never persisted.
SESSIONS={}
SESSION_ID=ContextVar('studio_session',default=None)
SESSION_KEYS=ContextVar('studio_keys',default=None)
SESSION_SETTINGS=ContextVar('studio_settings',default=None)
SESSION_COOKIE='framestudio_session'

def model_settings():
    return SESSION_SETTINGS.get() or STATE['settings']

def start_context_thread(fn,*args):
    ctx=copy_context()
    thread=threading.Thread(target=ctx.run,args=(fn,*args),daemon=True)
    thread.start()
    return thread

def save():
    with LOCK:
        DB.execute('INSERT OR REPLACE INTO store VALUES (?,?)',('state',json.dumps(STATE,ensure_ascii=False)));DB.commit()
def uid():return uuid.uuid4().hex[:16]

def canvas_graph(p):
    g=json.loads(json.dumps(p.get('graph',{'nodes':['reference']+[f'{t}-{a["id"]}' for a in p['actions'] for t in ['action','process','export']], 'edges':[e for a in p['actions'] for e in [{'from':'reference','to':'action-'+a['id']},{'from':'action-'+a['id'],'to':'process-'+a['id']},{'from':'process-'+a['id'],'to':'export-'+a['id']}]]})))
    for im in p.get('images',[]):
        if 'image-'+im['id'] not in g['nodes']:g['nodes'].append('image-'+im['id'])
    for s in p.get('sheets',[]):
        if 'sheet-edit-'+s['id'] not in g['nodes'] and 'sheet-edit-'+s['id'] not in p.get('deleted_nodes',[]):
            g['nodes']+=['sheet-edit-'+s['id'],'sheet-export-'+s['id']]
            g['edges'].append({'from':'sheet-edit-'+s['id'],'to':'sheet-export-'+s['id']})
            if s.get('source'):
                g['nodes'].append('sheet-source-'+s['id']);g['edges'].append({'from':'sheet-source-'+s['id'],'to':'sheet-edit-'+s['id']})
                g['edges'].append({'from':'reference','to':'sheet-edit-'+s['id'],'slot':'image'})
    if g.get('version')!=2:
        for s in p.get('sheets',[]):
            if s.get('source') and not any(e['to']=='sheet-edit-'+s['id'] and e.get('slot')=='image' for e in g['edges']):g['edges'].append({'from':'reference','to':'sheet-edit-'+s['id'],'slot':'image'})
    deleted=set(p.get('deleted_nodes',[]));g['nodes']=[n for n in g['nodes'] if n not in deleted]
    g['edges']=[e for e in g['edges'] if e['from'] in g['nodes'] and e['to'] in g['nodes']]
    g['version']=2
    return g

def sheet_input(p,node,seen=None):
    seen=set(seen or [])
    if node in seen:raise HTTPException(400,'连线不能形成循环')
    seen.add(node);g=canvas_graph(p)
    if node not in g['nodes']:raise HTTPException(400,'输入节点已移除')
    if node.startswith('export-') or node.startswith('sheet-export-'):
        edge=next((e for e in g['edges'] if e['to']==node),None)
        if not edge:raise HTTPException(400,'Sprite Sheet 输出尚未连接上游')
        return sheet_input(p,edge['from'],seen)
    if node.startswith('sheet-source-'):
        s=next(x for x in p.get('sheets',[]) if 'sheet-source-'+x['id']==node)
        return {'source':s['source'],'options':dict(s['options']),'original':s['original']}
    collection=p['actions'] if node.startswith('process-') else p.get('sheets',[])
    record=next((x for x in collection if node in ['process-'+x['id'],'sheet-edit-'+x['id']]),None)
    if not record or not record.get('exports'):raise HTTPException(400,'上游尚未产出 Sprite Sheet，请先完成上游处理')
    ex=record['exports'][-1];m=ex['meta']
    return {'source':ex['base']+'/spritesheet.png','original':ex,'options':{'columns':m['columns'],'rows':(m['frame_count']+m['columns']-1)//m['columns'],'count':m['frame_count'],'fps':m['fps'],'size':m['frame_width']}}

def image_item(p,iid):
    if iid=='reference':
        item=p.setdefault('base_image',{'id':'reference','name':'Image','source':p.get('reference'),'prompt':'','history':[]})
        item['source']=p.get('reference')
        return item
    item=next((x for x in p.get('images',[]) if x['id']==iid),None)
    if not item:raise HTTPException(404,'Image 节点不存在')
    return item

def store_image(p,item,source):
    with LOCK:
        if item.get('source'):item.setdefault('history',[]).append(item['source'])
        item['source']=source
        if item['id']=='reference':p['reference']=source;p.setdefault('references',[]).append(source)
        save()

def video_image(p,aid):
    if 'graph' not in p:return p.get('reference')
    edge=next((e for e in p['graph']['edges'] if e['to']=='action-'+aid),None)
    if not edge:raise HTTPException(400,'请先连接 Image 输出与视频生成输入')
    return image_item(p,'reference' if edge['from']=='reference' else edge['from'][6:]).get('source')
def key(name):
    if public_mode():return (SESSION_KEYS.get() or {}).get(name,'')
    if os.environ.get(name,'').strip():return os.environ[name].strip()
    if KEYS.get(name):return KEYS[name]
    value=os.environ.get(name,'')
    if not value and os.name=='nt':
        try:
            import winreg
            with winreg.OpenKey(winreg.HKEY_CURRENT_USER,'Environment') as k:value=winreg.QueryValueEx(k,name)[0]
        except OSError:pass
    return value or read_saved_keys().get(name,'')
def project(pid):
    p=next((p for p in STATE['projects'] if p['id']==pid),None)
    if not p:raise HTTPException(404,'项目不存在')
    return p
def action(aid):
    for p in STATE['projects']:
        for a in p['actions']:
            if a['id']==aid:return p,a
    raise HTTPException(404,'动作不存在')
def sheet(sid):
    for p in STATE['projects']:
        for s in p.get('sheets',[]):
            if s['id']==sid:return p,s
    raise HTTPException(404,'精灵图不存在')
def url(path):return '/media/'+str(Path(path).resolve().relative_to(DATA)).replace('\\','/')
def path(media):
    if not media or not media.startswith('/media/'):raise ValueError('素材路径无效')
    p=(DATA/media[7:]).resolve()
    if not p.is_relative_to(DATA):raise ValueError('素材路径越界')
    return p
def update_job(j,**changes):
    with LOCK:j.update(changes);save()
def public_state():
    with LOCK:
        data=json.loads(json.dumps(STATE))
    data['projects']=[p for p in data['projects'] if not p.get('archived')]
    data['connection']={'ark':bool(key('ARK_API_KEY')),'openai':bool(key('OPENAI_API_KEY'))}
    data['public_mode']=public_mode()
    data['settings']=dict(model_settings())
    return data
def error_text(exc):
    s=str(exc)
    for name in ['ARK_API_KEY','OPENAI_API_KEY']:
        secret=key(name)
        if secret:s=s.replace(secret,'[hidden]')
    return s[:800]
def new_job(kind,pid,aid=None,**extras):
    with LOCK:
        if public_mode():
            if sum(j['status'] in ['queued','running'] for j in STATE['jobs'])>=4:
                raise HTTPException(429,'工作室任务队列已满，请稍后再试')
            if kind in ['image','video','sheet']:
                limit=int(os.environ.get('ASSET_CANVAS_DAILY_GENERATIONS','20'))
                cutoff=time.time()-86400
                if sum(j['kind'] in ['image','video','sheet'] and j['created']>cutoff for j in STATE['jobs'])>=limit:
                    raise HTTPException(429,'工作室最近24小时生成次数已达上限，请稍后再试')
        if any(j['project']==pid and j.get('action')==aid and j['kind']==kind and j['status'] in ['queued','running'] for j in STATE['jobs']):
            raise HTTPException(409,'该任务已在队列中，请勿重复提交')
        j={'id':uid(),'kind':kind,'project':pid,'action':aid,'status':'queued','message':'等待处理','created':time.time(),**extras}
        STATE['jobs'].insert(0,j);save();return j
def execute(j,fn):
    def work():
        try:
            update_job(j,status='running');fn();update_job(j,status='done',message='已完成',finished=time.time())
        except Exception as exc:update_job(j,status='failed',message=error_text(exc),finished=time.time())
    POOL.submit(copy_context().run,work)

def bridge(mode,**params):
    if os.name!='nt':
        endpoint='https://ark.cn-beijing.volces.com/api/v3/contents/generations/tasks'
        headers={'Authorization':'Bearer '+key('ARK_API_KEY')}
        with httpx.Client(timeout=100) as client:
            if mode=='status':
                task_id=str(params['TaskId'])
                if not re.fullmatch(r'[a-zA-Z0-9_-]+',task_id):raise ValueError('任务编号无效')
                response=client.get(endpoint+'/'+task_id,headers=headers)
            elif mode=='submit':
                encoded=base64.b64encode(Path(params['Image']).read_bytes()).decode('ascii')
                response=client.post(endpoint,headers=headers,json={'model':params['Model'],'content':[{'type':'text','text':params['Prompt']},{'type':'image_url','image_url':{'url':'data:image/png;base64,'+encoded}}],'duration':int(params['Duration']),'resolution':params['Resolution'],'ratio':params['Ratio'],'generate_audio':False,'watermark':False})
            else:raise ValueError('不支持的视频操作')
        if response.status_code>=400:raise ValueError('Seedance '+str(response.status_code)+': '+response.text[:600])
        return response.json()
    shell=shutil.which('pwsh') or shutil.which('powershell')
    if not shell:raise ValueError('找不到 PowerShell，无法调用 Seedance 桥接脚本')
    cmd=[shell,'-NoProfile','-ExecutionPolicy','Bypass','-File',str(ROOT/'tools/seedance/seedance.ps1'),mode]
    for k,v in params.items():cmd += ['-'+k,str(v)]
    env=os.environ.copy();env['ARK_API_KEY']=key('ARK_API_KEY')
    result=subprocess.run(cmd,capture_output=True,encoding='utf-8',errors='replace',env=env,timeout=100,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
    if result.returncode:raise ValueError('Seedance 请求失败：'+result.stderr[-650:])
    text='\n'.join(l for l in result.stdout.splitlines() if not l.startswith('SUBMITTING'))
    return json.loads(text)

def generate_video(j):
    p,a=action(j['action'])
    if not j.get('task_id'):
        ref=path(j['reference']);im=Image.open(ref).convert('RGBA')
        # Seedance receives an opaque chroma reference. Keep original reference untouched.
        canvas=Image.new('RGBA',im.size,(0,255,0,255));canvas.alpha_composite(im)
        target=DATA/p['id']/j['id'];target.mkdir(parents=True,exist_ok=True)
        chroma=target/'seedance-reference.png';canvas.convert('RGB').save(chroma)
        update_job(j,message='提交 Seedance（收费生成）',submission_started=True)
        result=bridge('submit',Model=j['model'],Prompt=j['prompt'],Image=chroma,Duration=4,Resolution=j.get('options',{}).get('video_resolution','480p'),Ratio='1:1')
        if not result.get('id'):raise ValueError('接口未返回任务编号；请核对平台记录，勿直接重复提交')
        update_job(j,task_id=result['id'],message='Seedance 正在生成')
    for _ in range(180):
        result=bridge('status',TaskId=j['task_id']);phase=result.get('status')
        if phase=='succeeded':
            target=DATA/p['id']/j['id'];target.mkdir(parents=True,exist_ok=True)
            with httpx.stream('GET',result['content']['video_url'],timeout=120,follow_redirects=True) as response:
                response.raise_for_status()
                with (target/'video.mp4').open('wb') as f:
                    for chunk in response.iter_bytes():f.write(chunk)
            with LOCK:
                a['video']=url(target/'video.mp4');a['video_version']=j['id'];save()
            update_job(j,usage=result.get('usage'),message='视频已下载，待透明处理',video=url(target/'video.mp4'))
            if j.get('auto_process'):
                if 'graph' not in p:process_action(j)
                else:
                    targets=[e['to'][8:] for e in p['graph']['edges'] if e['from']=='action-'+a['id'] and e['to'].startswith('process-')]
                    for target_id in targets:
                        process_job(target_id)
            return
        if phase in ['failed','cancelled','expired']:
            update_job(j,provider_terminal=True)
            raise ValueError('Seedance '+phase+': '+str(result.get('error','')))
        if phase not in ['queued','running']:raise ValueError('未知任务状态：'+str(phase))
        update_job(j,message='Seedance '+('排队中' if phase=='queued' else '生成中'))
        time.sleep(10)
    raise ValueError('等待超时，已保留任务编号；可继续查询，不会重复生成')

def generate_image(j):
    p=project(j['project']);target=DATA/p['id']/j['id'];target.mkdir(parents=True,exist_ok=True)
    headers={'Authorization':'Bearer '+key('OPENAI_API_KEY')}
    payload={'model':j['model'],'prompt':j['prompt'],'size':'1024x1024','quality':'medium','background':j.get('background','auto'),'output_format':'png','n':1}
    update_job(j,message='GPT 正在生成图片（收费生成）',submission_started=True)
    with httpx.Client(timeout=300) as client:
        if j.get('reference'):
            with path(j['reference']).open('rb') as f:
                res=client.post('https://api.openai.com/v1/images/edits',headers=headers,data={k:str(v) for k,v in payload.items()},files={'image':('reference.png',f,'image/png')})
        else:res=client.post('https://api.openai.com/v1/images/generations',headers=headers,json=payload)
    if res.status_code>=400:raise ValueError('OpenAI '+str(res.status_code)+': '+res.text[:600])
    data=res.json();encoded=data['data'][0].get('b64_json')
    if not encoded:raise ValueError('生图接口未返回 PNG 数据')
    image_bytes=base64.b64decode(encoded);Image.open(io.BytesIO(image_bytes)).verify()
    (target/'reference.png').write_bytes(image_bytes)
    if j.get('image_id'):store_image(p,image_item(p,j['image_id']),url(target/'reference.png'))
    else:
        with LOCK:
            p.setdefault('references',[]).append(url(target/'reference.png'));p['reference']=url(target/'reference.png');save()
    update_job(j,usage=data.get('usage'))

def process_action(j):
    p,a=action(j['action']);target=DATA/p['id']/j['id'];target.mkdir(parents=True,exist_ok=True)
    with PROCESS_LOCK:
        update_job(j,message='正在抽帧与去除绿幕')
        meta=process_video(path(j['video']),target,j['options'],lambda msg:update_job(j,message=msg))
    export={'id':j['id'],'base':url(target),'meta':meta,'created':time.time(),'source_video':j['video']}
    with LOCK:a.setdefault('exports',[]).append(export);save()


def generate_sheet(j):
    p,s=sheet(j['action']);target=DATA/p['id']/j['id'];target.mkdir(parents=True,exist_ok=True)
    opts=j['options']
    prompt=(f'IMAGE 1 is an animation sprite sheet, the motion and layout blueprint. Preserve EXACTLY {opts["columns"]} columns and {opts["rows"]} rows, with {opts["count"]} animation frames in row-major order. '
            'Every frame must keep the corresponding pose, limb placement, facing direction, silhouette scale and foot anchor from image 1. No missing, extra, merged or duplicated frames. '
            'Replace ONLY the character appearance using IMAGE 2 as character reference when supplied. Keep pose progression and timing implicit in frame order. '
            'Clean pixel art, consistent palette and hard pixel edges. Transparent background, no checkerboard, labels, grid lines or text. Keep empty cells transparent. User changes: '+j['prompt'])
    files=[('image[]',('motion-sheet.png',path(j['source']).read_bytes(),'image/png'))]
    if j.get('reference'):files.append(('image[]',('character-reference.png',path(j['reference']).read_bytes(),'image/png')))
    update_job(j,message='GPT 正在按原动作改造精灵图（收费生成）',submission_started=True)
    with httpx.Client(timeout=300) as client:
        result=client.post('https://api.openai.com/v1/images/edits',headers={'Authorization':'Bearer '+key('OPENAI_API_KEY')},data={'model':j['model'],'prompt':prompt,'size':'auto','quality':'high','background':'transparent','output_format':'png','n':'1'},files=files)
    if result.status_code>=400:raise ValueError('OpenAI '+str(result.status_code)+': '+result.text[:600])
    data=result.json();encoded=data['data'][0].get('b64_json')
    if not encoded:raise ValueError('接口没有返回图像数据')
    raw=target/'generated-original.png';raw.write_bytes(base64.b64decode(encoded));Image.open(raw).verify()
    update_job(j,message='正在切分新版精灵图并打包')
    with PROCESS_LOCK:meta=process_sheet(raw,target,{**opts,'ai_review':True})
    ex={'id':j['id'],'base':url(target),'meta':meta,'created':time.time(),'generated':True}
    with LOCK:s['exports'].append(ex);save()
    update_job(j,usage=data.get('usage'))

@asynccontextmanager
async def lifespan(app):
    for j in STATE['jobs']:
        if j['status'] in ['queued','running']:
            j['status']='interrupted';j['message']='服务曾重启；已有任务可继续查询，未自动重新提交'
    for pr in STATE['projects']:
        for b in pr.get('batches',[]):
            if b.get('running'):b.update(running=False,run_message='服务重启，点击继续运行；已提交的任务不会重复生成')
    save();yield

def access_config():
    """Resolve the public origin and the host names allowed to reach this instance."""
    public_origin=os.environ.get('ASSET_CANVAS_PUBLIC_ORIGIN','').rstrip('/')
    if not public_origin and os.environ.get('RENDER_EXTERNAL_HOSTNAME'):
        public_origin='https://'+os.environ['RENDER_EXTERNAL_HOSTNAME']
    hosts=['127.0.0.1','localhost','testserver']
    if public_origin:
        from urllib.parse import urlsplit
        parsed=urlsplit(public_origin).hostname
        if parsed:hosts.append(parsed)
    for extra in os.environ.get('ASSET_CANVAS_ALLOWED_HOSTS','').split(','):
        extra=extra.strip()
        if extra:hosts.append(extra)
    return public_origin,hosts

def login_gate(req:Request):
    """Optional shared password for LAN deployments; disabled when unset."""
    expected=os.environ.get('ASSET_CANVAS_PASSWORD','')
    if not expected:return None
    header=req.headers.get('authorization','')
    challenge={'WWW-Authenticate':'Basic realm="FrameStudio"'}
    if not header.startswith('Basic '):
        return JSONResponse({'detail':'需要登录'},401,headers=challenge)
    try:supplied=base64.b64decode(header[6:]).decode('utf-8','ignore')
    except Exception:supplied=''
    user=os.environ.get('ASSET_CANVAS_USER','jomin')
    if not hmac.compare_digest(supplied,f'{user}:{expected}'):
        return JSONResponse({'detail':'用户名或密码错误'},401,headers=challenge)
    return None

app=FastAPI(title='FrameStudio · 动画资产工作台',lifespan=lifespan)
@app.middleware('http')
async def local_only(req:Request,call_next):
    host_header=req.headers.get('host','')
    host=host_header.split(':')[0]
    port=host_header.split(':')[1] if host_header.count(':')==1 else ''
    public_origin,allowed_hosts=access_config()
    open_hosts='*' in allowed_hosts
    if not open_hosts and host not in allowed_hosts:return JSONResponse({'detail':'访问地址未配置'},403)
    denied=login_gate(req)
    if denied:return denied
    if req.method not in ['GET','HEAD','OPTIONS']:
        origin=req.headers.get('origin')
        allowed_origins={public_origin} if public_origin else set()
        for name in allowed_hosts:
            if name in ['testserver','*']:continue
            suffix=':'+port if port else ''
            allowed_origins.add('http://'+name+suffix)
            allowed_origins.add('https://'+name+suffix)
        for scheme in ['http','https']:
            allowed_origins.add(scheme+'://'+host_header)
        if (origin and origin not in allowed_origins) or req.headers.get('x-canvas-request')!='1':
            return JSONResponse({'detail':'请求来源无效'},403)
    tokens=[];sid=None
    if public_mode() and req.url.path.startswith('/api/'):
        now=time.time()
        with LOCK:
            for old in list(SESSIONS):
                if now-SESSIONS[old]['seen']>86400:del SESSIONS[old]
            sid=req.cookies.get(SESSION_COOKIE)
            if sid not in SESSIONS:
                sid=secrets.token_urlsafe(32)
                SESSIONS[sid]={'keys':{},'settings':{},'seen':now}
            session=SESSIONS[sid];session['seen']=now
            tokens=[(SESSION_ID,SESSION_ID.set(sid)),(SESSION_KEYS,SESSION_KEYS.set(dict(session['keys']))),
                    (SESSION_SETTINGS,SESSION_SETTINGS.set({**STATE['settings'],**session['settings']}))]
    try:response=await call_next(req)
    finally:
        for variable,token in reversed(tokens):variable.reset(token)
    if sid:
        response.set_cookie(SESSION_COOKIE,sid,httponly=True,samesite='strict',
                            secure=req.url.scheme=='https' or public_origin.startswith('https://'),max_age=86400)
        if req.url.path.startswith('/api/'):
            response.headers['Cache-Control']='no-store'
    response.headers['X-Content-Type-Options']='nosniff'
    response.headers['Referrer-Policy']='no-referrer'
    return response

@app.get('/healthz')
def health():return {'status':'ok','version':'framestudio-online-keys-1'}

@app.get('/api/state')
def state():return public_state()

@app.get('/api/developer-log')
def get_developer_log():
    with LOCK:return dict(STATE.get('developer_log',{'content':None,'revision':0}))

@app.post('/api/projects/{pid}/playback-speed')
def change_playback_speed(pid:str,body:dict):
    with LOCK:
        p=project(pid);node=body.get('source','')
        if node not in canvas_graph(p)['nodes'] or not node.startswith(('process-','sheet-edit-')):raise HTTPException(400,'请选择已生成的 Sprite Sheet')
        records=p['actions'] if node.startswith('process-') else p.get('sheets',[])
        rec=next((r for r in records if node.rsplit('-',1)[-1]==r['id']),None)
        if not rec or not rec.get('exports'):raise HTTPException(400,'尚未生成 Sprite Sheet')
        try:
            speed=float(body['speed'])
            if not .25<=speed<=2:raise ValueError()
        except (ValueError,TypeError,KeyError):raise HTTPException(400,'速度范围为0.25–2倍')
        if any(j['project']==pid and j.get('action')==rec['id'] and j['status'] in ['queued','running'] for j in STATE['jobs']):raise HTTPException(409,'此素材正在处理，请稍后保存速度')
        ex=json.loads(json.dumps(rec['exports'][-1]));base_fps=ex['meta'].get('base_fps',ex['meta']['fps']);fps=base_fps*speed
        if fps>1200:raise HTTPException(400,'播放速度过高')
        job=new_job('retime',pid,rec['id'],speed=speed)
        def work():
            with PROCESS_LOCK:
                update_job(job,message='正在保存播放速度，不重新生成画面')
                source=path(ex['base']);dest=DATA/pid/job['id'];dest.mkdir(parents=True,exist_ok=True)
                frames=[]
                for i in range(ex['meta']['frame_count']):
                    with Image.open(source/'frames'/f'{i:03}.png') as im:frames.append(im.convert('RGBA'))
                opts={**ex['meta'].get('settings',{}),'name':rec['name'],'fps':fps,'playback_fps':fps,'pingpong':False,'loop':ex['meta']['loop'],'columns':ex['meta']['columns']}
                extra={k:v for k,v in ex['meta'].items() if k in ['crop_box','source_frame_count','kept_source_indices','source_frames_available','sample_fps','sample_times']}
                if extra.get('source_frames_available'):
                    if (source/'source_frames').exists():shutil.copytree(source/'source_frames',dest/'source_frames')
                    else:extra['source_frames_available']=False
                for folder in ['color_original_frames']:
                    if (source/folder).exists():shutil.copytree(source/folder,dest/folder)
                for field in ['color_report','color_original_available','pixel_stability_report','pixel_restore_id','pixel_before_base']:
                    if field in ex['meta']:extra[field]=ex['meta'][field]
                meta=pack_frames(frames,dest,opts,extra={**extra,'base_fps':base_fps,'playback_speed':speed},apply_color=False)
                with LOCK:
                    rec['exports'].append({'id':job['id'],'base':url(dest),'meta':meta,'created':time.time()});save()
        execute(job,work);return job

@app.post('/api/projects/{pid}/color-quality')
def color_quality(pid:str,body:dict):
    with LOCK:
        p=project(pid);node=str(body.get('source',''))
        if node not in canvas_graph(p)['nodes'] or not node.startswith(('process-','sheet-edit-')):raise HTTPException(400,'请连接有效的透明帧或精灵图')
        records=p['actions'] if node.startswith('process-') else p.get('sheets',[])
        rec=next((a for a in records if a['id']==node.rsplit('-',1)[-1]),None)
        if not rec:raise HTTPException(404,'素材不存在')
        mode=body.get('mode','repair')
        try:
            threshold=float(body.get('threshold',6))
            if body.get('quick'):
                previous=(rec.get('exports') or [{}])[-1].get('meta',{}).get('color_report',{})
                threshold=max(2,min(6,float(previous.get('threshold',6))*.7)) if previous.get('algorithm')=='luminance-v3' else 6
            if mode not in ['off','detect','repair'] or not 2<=threshold<=50:raise ValueError()
        except (ValueError,TypeError):raise HTTPException(400,'请检查颜色修正模式和阈值')
        if any(j['project']==pid and j.get('action')==rec['id'] and j['status'] in ['queued','running'] for j in STATE['jobs']):raise HTTPException(409,'此素材正在处理，请稍后重试')
        rec.setdefault('options',{}).update(color_mode=mode,color_threshold=threshold,color_algorithm='luminance-v3');save()
        if not rec.get('exports'):return {'saved':True}
        ex=json.loads(json.dumps(rec['exports'][-1]));job=new_job('colorfix',pid,rec['id'])
        def work():
            with PROCESS_LOCK:
                update_job(job,message='检测亮度 / 明度跳变并修复，保留帧数与动作')
                source=path(ex['base']);dest=DATA/pid/job['id']
                frames=[];original=source/'color_original_frames'
                if not original.is_dir():original=source/'frames'
                for i in range(ex['meta']['frame_count']):
                    with Image.open(original/f'{i:03}.png') as im:frames.append(im.convert('RGBA'))
                opts={**ex['meta'].get('settings',{}),'name':rec['name'],'playback_fps':ex['meta']['fps'],'columns':ex['meta']['columns'],'loop':ex['meta']['loop'],'pingpong':False,'color_mode':mode,'color_threshold':threshold,'color_algorithm':'luminance-v3'}
                extra={k:v for k,v in ex['meta'].items() if k in ['crop_box','source_frame_count','kept_source_indices','source_frames_available','sample_fps','sample_times','base_fps','playback_speed']}
                dest.mkdir(parents=True,exist_ok=True)
                if (source/'source_frames').exists():shutil.copytree(source/'source_frames',dest/'source_frames')
                else:extra['source_frames_available']=False
                meta=pack_frames(frames,dest,opts,extra=extra)
                with LOCK:
                    rec['exports'].append({'id':job['id'],'base':url(dest),'meta':meta,'created':time.time()});save()
        execute(job,work);return job

@app.post('/api/projects/{pid}/pixel-stability')
def pixel_stability(pid:str,body:dict):
    with LOCK:
        p=project(pid);node=str(body.get('source',''))
        if node not in canvas_graph(p)['nodes'] or not node.startswith(('process-','sheet-edit-')):raise HTTPException(400,'请选择透明帧或精灵图模块')
        records=p['actions'] if node.startswith('process-') else p.get('sheets',[])
        rec=next((r for r in records if r['id']==node.rsplit('-',1)[-1]),None)
        if not rec or not rec.get('exports'):raise HTTPException(400,'请先生成透明帧')
        if any(j['project']==pid and j.get('action')==rec['id'] and j['status'] in ['queued','running'] for j in STATE['jobs']):raise HTTPException(409,'此素材正在处理，请稍后重试')
        ex=json.loads(json.dumps(rec['exports'][-1]));operation=body.get('operation','preview')
        if operation=='apply':
            j=next((j for j in STATE['jobs'] if j['id']==body.get('job') and j['project']==pid and j.get('action')==rec['id'] and j['kind']=='pixel-stability'),None)
            if not j or j['status']!='done' or not j.get('candidate'):raise HTTPException(400,'预览尚未完成')
            if j['original']['id']!=ex['id']:raise HTTPException(409,'素材已经更新，请重新生成预览')
            candidate=json.loads(json.dumps(j['candidate']));candidate['meta']['pixel_restore_id']=ex['id']
            rec['exports'].append(candidate);save();return {'applied':True}
        if operation=='restore':
            original=next((e for e in rec['exports'] if e['id']==ex['meta'].get('pixel_restore_id')),None)
            if not original:raise HTTPException(400,'当前结果没有像素稳定恢复记录')
            restored=json.loads(json.dumps(original));restored.update(id=uid(),created=time.time())
            rec['exports'].append(restored);save();return {'restored':True}
        if operation!='preview':raise HTTPException(400,'无效操作')
        try:
            size=int(body.get('size',256));cell=int(body.get('cell',1));strength=body.get('strength','standard')
            if size not in (128,256,512) or cell not in (1,2,4) or strength not in ('gentle','standard'):raise ValueError()
        except (TypeError,ValueError):raise HTTPException(400,'请检查输出尺寸、像素网格和修复强度')
        job=new_job('pixel-stability',pid,rec['id'],original=ex)
        def work():
            with PROCESS_LOCK:
                update_job(job,message='正在统一像素网格并对齐相邻帧；原结果保持不变')
                source=path(ex['base']);dest=DATA/pid/job['id'];frames=[]
                for i in range(ex['meta']['frame_count']):
                    with Image.open(source/'frames'/f'{i:03}.png') as im:frames.append(im.convert('RGBA'))
                fixed,report=stabilize_frames(frames,size,cell,strength,ex['meta']['loop'])
                opts={**ex['meta'].get('settings',{}),'name':rec['name'],'size':size,'playback_fps':ex['meta']['fps'],'columns':ex['meta']['columns'],'pingpong':False,'loop':ex['meta']['loop']}
                # Intentionally do not advertise old-size source frames as editable new-size frames.
                extra={k:v for k,v in ex['meta'].items() if k in ['source_frame_count','kept_source_indices','sample_fps','sample_times','base_fps','playback_speed']}
                extra.setdefault('kept_source_indices',list(range(len(frames))))
                extra.update(pixel_stability_report=report,source_frames_available=False,pixel_before_base=ex['base'])
                meta=pack_frames(fixed,dest,opts,extra=extra,apply_color=False)
                update_job(job,candidate={'id':job['id'],'base':url(dest),'meta':meta,'created':time.time()})
        execute(job,work);return job

@app.post('/api/projects/{pid}/batches/{bid}/export-selected')
def export_batch_selected(pid:str,bid:str,body:dict):
    with LOCK:
        p=project(pid);batch=next((b for b in p.get('batches',[]) if b['id']==bid),None)
        ids=body.get('actions')
        if not batch or not isinstance(ids,list) or not ids or len(ids)>120 or any(not isinstance(i,str) for i in ids):raise HTTPException(400,'请选择1–120个已完成动画')
        ids=list(dict.fromkeys(ids));records=[]
        for aid in ids:
            if aid not in batch['outputs']:raise HTTPException(400,'选择包含其他批次的动画')
            a=next((a for a in p['actions'] if a['id']==aid),None)
            if not a or not a.get('exports'):raise HTTPException(400,'所选动画尚未完成')
            ex=a['exports'][-1]
            expected=body.get('exports',{})
            if not isinstance(expected,dict):raise HTTPException(400,'无效导出版本')
            if aid in expected and expected[aid]!=ex['id']:raise HTTPException(409,'动画已更新，请重新打开预览后导出')
            f=path(ex['base']+'/spritesheet.zip')
            if not f.is_file():raise HTTPException(400,'素材包缺失，请重新处理')
            records.append((aid,a['name'],f,ex['meta']['frame_count']))
    dest=DATA/pid/uid();dest.mkdir(parents=True);archive=dest/'selected-animations.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_STORED) as z:
        manifest=[]
        for i,(aid,name,f,count) in enumerate(records):
            safe=re.sub(r'[^\w\- ]','_',name)[:60] or 'animation'
            filename=f'{i+1:02}-{safe}-{aid[:6]}.zip';z.write(f,filename)
            manifest.append({'id':aid,'name':name,'file':filename,'frame_count':count})
        z.writestr('manifest.json',json.dumps(manifest,ensure_ascii=False,indent=2))
    return {'url':url(archive),'count':len(records)}

@app.post('/api/exports/png')
def export_selected_png(body:dict):
    items=body.get('items')
    export_size=body.get('frame_size',0)
    if type(export_size)!=int or export_size not in [0,320]:raise HTTPException(400,'请选择原尺寸或320像素')
    if not isinstance(items,list) or not 1<=len(items)<=120:raise HTTPException(400,'请选择1–120个动画')
    records=[];seen=set()
    with LOCK:
        for item in items:
            if not isinstance(item,dict) or any(not isinstance(item.get(k),str) for k in ['project','action','export']):raise HTTPException(400,'无效的素材选择')
            p=project(item['project']);identity=(p['id'],item['action'])
            if identity in seen:continue
            seen.add(identity)
            rec=next((r for r in p['actions']+p.get('sheets',[]) if r['id']==item['action']),None)
            if not rec or not rec.get('exports'):raise HTTPException(400,'所选素材尚未完成')
            ex=rec['exports'][-1]
            if ex['id']!=item['export']:raise HTTPException(409,'素材已更新，请刷新后重新选择')
            f=path(ex['base']+'/spritesheet.png')
            if not f.is_file():raise HTTPException(400,'PNG缺失，请重新处理')
            safe=re.sub(r'[\\/:*?"<>|\x00-\x1f]','_',p['name']+'-'+rec['name'])[:160].rstrip('. ') or 'spritesheet'
            records.append((f,safe,ex['meta']))
    dest=DATA/'downloads'/uid();dest.mkdir(parents=True);archive=dest/'spritesheets-png.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_STORED) as z:
        used=set()
        for f,name,meta in records:
            filename=name+'.png';suffix=2
            while filename.casefold() in used:
                filename=f'{name} ({suffix}).png';suffix+=1
            used.add(filename.casefold())
            if export_size:
                with Image.open(f) as source:
                    cols=meta['columns'];rows=(meta['frame_count']+cols-1)//cols
                    sheet=Image.new('RGBA',(cols*export_size,rows*export_size))
                    for frame in meta['frames']:
                        tile=source.crop((frame['x'],frame['y'],frame['x']+frame['w'],frame['y']+frame['h'])).resize((export_size,export_size),Image.Resampling.NEAREST)
                        i=frame['index'];sheet.paste(tile,((i%cols)*export_size,(i//cols)*export_size))
                    data=io.BytesIO();sheet.save(data,format='PNG');z.writestr(filename,data.getvalue())
            else:z.write(f,filename)
    return {'url':url(archive),'count':len(records)}

@app.put('/api/developer-log')
def edit_developer_log(body:dict):
    content=body.get('content')
    if not isinstance(content,str) or not content.strip() or len(content)>50000:raise HTTPException(400,'日志不能为空，最多50000个字符')
    with LOCK:
        previous=STATE.get('developer_log',{'revision':0})
        if body.get('revision')!=previous['revision']:raise HTTPException(409,'日志已被其他页面修改，请复制当前文字后重新打开日志再保存')
        STATE['developer_log']={'content':content,'revision':previous['revision']+1,'updated':time.time()};save()
        return dict(STATE['developer_log'])
@app.post('/api/settings')
def settings(body:dict):
    updates={name:str(body[field]).strip() for name,field in [('OPENAI_API_KEY','openai_key'),('ARK_API_KEY','ark_key')] if body.get(field) and str(body[field]).strip()}
    models={}
    for field in ['image_model','video_model']:
        if field in body:
            if not re.fullmatch(r'[a-zA-Z0-9._-]{1,100}',str(body[field])):raise HTTPException(400,'模型名称无效')
            models[field]=body[field]
    if public_mode():
        with LOCK:
            session=SESSIONS.get(SESSION_ID.get())
            if session is None:raise HTTPException(401,'会话已过期，请刷新页面')
            if body.get('clear_keys'):session['keys']={}
            session['keys'].update(updates);session['settings'].update(models)
            SESSION_KEYS.set(dict(session['keys']))
            SESSION_SETTINGS.set({**STATE['settings'],**session['settings']})
        return public_state()
    for name,value in updates.items():
        managed=os.environ.get(name,'').strip()
        if managed and managed!=value:raise HTTPException(409,'该密钥由服务器环境变量管理，请到部署平台修改，网页不能覆盖')
    if updates:persist_keys(updates)
    with LOCK:
        for field in ['image_model','video_model']:
            if field in body:
                if not re.fullmatch(r'[a-zA-Z0-9._-]{1,100}',str(body[field])):raise HTTPException(400,'模型名称无效')
                STATE['settings'][field]=body[field]
        save()
    return public_state()
@app.post('/api/projects')
def create_project(body:dict):
    with LOCK:
        p={'id':uid(),'name':str(body.get('name','未命名角色'))[:80],'reference':None,'references':[],'actions':[],'layout':{},'created':time.time()}
        STATE['projects'].append(p);save();return p
@app.delete('/api/projects/{pid}')
def delete_project(pid:str):
    with LOCK:
        p=project(pid)
        if any(b.get('running') for b in p.get('batches',[])):raise HTTPException(409,'批量队列正在运行，请结束后删除')
        if any(j['project']==pid and j['status'] in ['queued','running'] for j in STATE['jobs']):raise HTTPException(409,'项目正在制作中，请完成后删除')
        STATE['projects'].remove(p)
        STATE['jobs'][:]=[j for j in STATE['jobs'] if j['project']!=pid]
        save()
        return {'deleted':pid,'files_preserved':True}

@app.post('/api/projects/{pid}/batches')
def create_batch(pid:str):
    with LOCK:
        p=project(pid);g=canvas_graph(p)
        b={'id':uid(),'source_project':pid,'actions':[a['id'] for a in p['actions'] if a.get('prompt','').strip() and 'action-'+a['id'] in g['nodes']],'image_id':'reference','frame_count':20,'threshold':5,'outputs':[]}
        p.setdefault('batches',[]).append(b);g['nodes'].append('batch-'+b['id']);p['graph']=g
        p['layout']['batch-'+b['id']]={'x':45,'y':max([v.get('y',0) for v in p['layout'].values()]+[0])+650}
        save();return b

@app.patch('/api/projects/{pid}/batches/{bid}')
def edit_batch(pid:str,bid:str,body:dict):
    with LOCK:
        p=project(pid);b=next((b for b in p.get('batches',[]) if b['id']==bid),None)
        if not b:raise HTTPException(404,'批量模块不存在')
        if b['outputs']:raise HTTPException(409,'流程已创建，请新建批量模块设置另一套动画')
        updated={**b,**{k:v for k,v in body.items() if k in ['source_project','actions','image_id','frame_count','action_frames','threshold','image_ids','cells']}}
        if updated['source_project']!=b['source_project'] and 'action_frames' not in body:updated['action_frames']={}
        try:
            if not 1<=int(updated['frame_count'])<=120 or not 0<=int(updated['threshold'])<=255:raise ValueError()
            if not isinstance(updated['actions'],list) or len(updated['actions'])>30 or len(set(updated['actions']))!=len(updated['actions']):raise ValueError()
            frames=updated.get('action_frames',{})
            if not isinstance(frames,dict) or len(frames)>600 or any(type(n) is not int or not 1<=n<=120 for n in frames.values()):raise ValueError()
        except (ValueError,TypeError):raise HTTPException(400,'请检查帧数、动作和去绿幕强度')
        image_item(p,updated['image_id']);project(updated['source_project'])
        images=updated.get('image_ids',[]);cells=updated.get('cells',{})
        if not isinstance(images,list) or len(images)>30 or any(not isinstance(i,str) for i in images):raise HTTPException(400,'最多选择30个角色')
        for iid in images:image_item(p,iid)
        if not isinstance(cells,dict) or len(cells)>900:raise HTTPException(400,'明细表无效')
        for cell in cells.values():
            if not isinstance(cell,dict) or type(cell.get('enabled',True)) is not bool or ('frame_count' in cell and (type(cell['frame_count']) is not int or not 1<=cell['frame_count']<=120)):raise HTTPException(400,'明细帧数须为1–120整数')
        if updated['source_project']!=b['source_project']:updated['cells']={}
        b.update(updated);save();return b

@app.post('/api/projects/{pid}/batches/{bid}/build')
def build_batch(pid:str,bid:str):
    with LOCK:
        p=project(pid);b=next((b for b in p.get('batches',[]) if b['id']==bid),None)
        if not b or 'batch-'+bid not in canvas_graph(p)['nodes']:raise HTTPException(404,'批量模块不存在')
        # Repeated clicks resume the same branches rather than duplicating paid tasks.
        if b['outputs']:return b
        g=canvas_graph(p)
        linked=['reference' if e['from']=='reference' else e['from'][6:] for e in g['edges'] if e['to']=='batch-'+bid and e.get('slot')=='image']
        image_ids=list(dict.fromkeys(linked+b.get('image_ids',[])))
        if not image_ids and 'image_ids' not in b:image_ids=[b['image_id']]
        if not image_ids:raise HTTPException(400,'请至少接入或选择一个角色参考图')
        if len(image_ids)>30:raise HTTPException(400,'最多30个角色')
        images=[image_item(p,iid) for iid in image_ids]
        if any(not im.get('source') or ('reference' if im['id']=='reference' else 'image-'+im['id']) not in g['nodes'] for im in images):raise HTTPException(400,'请检查所有角色参考图是否存在并已就绪')
        source=project(b['source_project']);sg=canvas_graph(source)
        actions=[a for a in source['actions'] if a['id'] in b['actions'] and 'action-'+a['id'] in sg['nodes']]
        if not actions or len(actions)!=len(b['actions']):raise HTTPException(400,'请选择仍然存在的动作')
        planned=[(im,old,b.get('cells',{}).get(im['id']+':'+old['id'],{})) for im in images for old in actions]
        planned=[row for row in planned if row[2].get('enabled',True)]
        if not planned:raise HTTPException(400,'至少启用一个角色动作')
        if len(g['nodes'])+3*len(planned)>600:raise HTTPException(400,'整套流程超过画布600个模块上限，请减少角色或动作')
        pos=p['layout'].get('batch-'+bid,{'x':45,'y':95});b['groups']=[]
        groups={}
        for i,(im,old,cell) in enumerate(planned):
            if im['id'] not in groups:
                group={'image_id':im['id'],'name':im['name'],'reference':im['source'],'actions':[]};groups[im['id']]=group;b['groups'].append(group)
            edge=next((e for e in sg['edges'] if e['from']=='action-'+old['id'] and e['to'].startswith('process-')),None)
            proc=next((a for a in source['actions'] if edge and 'process-'+a['id']==edge['to']),old)
            opts=json.loads(json.dumps(proc['options']));opts.update(excluded=[],playback_fps=None,target_frame_count=int(cell.get('frame_count',b.get('action_frames',{}).get(old['id'],b['frame_count']))),threshold=int(b['threshold']),pingpong=False,fps=10)
            aid=uid();act={'id':aid,'name':im['name']+' · '+old['name'],'prompt':old['prompt'],'video':None,'exports':[],'options':opts,'video_model':old.get('video_model') or model_settings()['video_model']}
            act['batch_snapshot']={'reference':im['source'],'prompt':old['prompt'],'model':act['video_model'],'options':{**opts,'name':act['name']}}
            p['actions'].append(act);b['outputs'].append(aid);groups[im['id']]['actions'].append(aid)
            image_node='reference' if im['id']=='reference' else 'image-'+im['id']
            nodes=[t+'-'+aid for t in ['action','process','export']];g['nodes']+=nodes
            g['edges'] += [{'from':image_node,'to':nodes[0]},{'from':nodes[0],'to':nodes[1]},{'from':nodes[1],'to':nodes[2]}]
            for j,node in enumerate(nodes):p['layout'][node]={'x':pos['x']+350*(j+1),'y':pos['y']+i*650}
        p['graph']=g;save();return b

def batch_wait(job):
    while job['status'] in ['queued','running']:time.sleep(.5)
    return job['status']=='done'

def run_batch_queue(pid,bid,retry=False):
    b=next(b for b in project(pid).get('batches',[]) if b['id']==bid)
    try:
        for aid in list(b['outputs']):
            p,a=action(aid)
            if 'action-'+aid not in canvas_graph(p)['nodes']:continue
            if a.get('exports'):continue
            snapshot=a.get('batch_snapshot') or {'reference':video_image(p,aid),'prompt':a['prompt'],'model':a.get('video_model') or model_settings()['video_model'],'options':{**a['options'],'name':a['name']}}
            # Editable build-only branches must use current node settings when first submitted.
            snapshot={**snapshot,'prompt':a['prompt'],'model':a.get('video_model') or snapshot['model'],'options':{**snapshot['options'],**a['options'],'name':a['name']}}
            previous=next((j for j in STATE['jobs'] if j['project']==pid and j.get('action')==aid and j['kind']=='video'),None)
            if not a.get('video'):
                if previous and previous['status'] in ['queued','running']:
                    if not batch_wait(previous):continue
                elif previous and not retry:continue
                else:
                    if previous and previous.get('task_id') and not previous.get('provider_terminal'):
                        update_job(previous,status='queued');execute(previous,lambda j=previous:generate_video(j));job=previous
                    elif previous and previous.get('submission_started') and not previous.get('task_id'):
                        b['run_message']='有任务未返回编号，请先到平台核对，未重复提交';save();continue
                    else:
                        job=new_job('video',pid,aid,reference=snapshot['reference'],prompt=snapshot['prompt']+' Fixed camera. Preserve subject colors and proportions. Uniform pure green background RGB(0,255,0). No added objects or text.',model=snapshot['model'],options={**snapshot['options'],'video_resolution':a['options'].get('video_resolution','480p')},auto_process=False)
                        execute(job,lambda j=job:generate_video(j))
                    if not batch_wait(job):continue
            if not a.get('video'):continue
            processing=next((j for j in STATE['jobs'] if j['project']==pid and j.get('action')==aid and j['kind']=='process'),None)
            if processing and processing['status'] in ['queued','running']:batch_wait(processing);continue
            if processing and processing['status']!='done' and not retry:continue
            job=new_job('process',pid,aid,video=a['video'],options=snapshot['options']);execute(job,lambda j=job:process_action(j));batch_wait(job)
        if not b.get('run_message'):b['run_message']='队列已结束；未完成项可单独重试'
    except HTTPException as exc:b['run_message']=str(exc.detail)+'；点击继续运行处理尚未提交的任务'
    except Exception as exc:b['run_message']=error_text(exc)
    finally:
        with LOCK:b['running']=False;save()

@app.post('/api/projects/{pid}/batches/{bid}/run')
def start_batch_queue(pid:str,bid:str,body:dict=None):
    with LOCK:
        if not key('ARK_API_KEY'):raise HTTPException(400,'请先配置 Seedance API Key')
        b=build_batch(pid,bid)
        if b.get('running'):return b
        # A separate coordinator avoids occupying a generation worker while waiting.
        b.update(running=True,run_message='');save()
        start_context_thread(run_batch_queue,pid,bid,bool((body or {}).get('retry')))
        return b

@app.post('/api/projects/{pid}/reuse')
async def reuse_animations(pid:str,file:UploadFile=File(...),spec:str=Form(...)):
    try:
        settings=json.loads(spec)
        requested=settings['actions']
        if not isinstance(requested,list) or not requested or len(requested)>30 or len(set(requested))!=len(requested):raise ValueError()
        data=await file.read(25*1024*1024+1)
        if len(data)>25*1024*1024:raise ValueError()
        im=Image.open(io.BytesIO(data))
        if im.width*im.height>20000000:raise ValueError()
        im.load();im=im.convert('RGBA')
    except Exception:raise HTTPException(400,'请选择有效参考图和至少一个动作（图片不超过25MB）')
    with LOCK:
        source=project(pid);g=canvas_graph(source)
        actions=[a for a in source['actions'] if a['id'] in requested and 'action-'+a['id'] in g['nodes']]
        if len(actions)!=len(requested):raise HTTPException(400,'选中的动作已删除，请重新选择')
        fresh={'id':uid(),'name':str(settings.get('name') or '新角色 · 同款动画')[:80],'reference':None,'references':[],'actions':[],'layout':{'reference':{'x':45,'y':95}},'created':time.time(),'reused_from':pid,'graph':{'version':2,'nodes':['reference'],'edges':[]}}
        target=DATA/fresh['id'];target.mkdir(parents=True)
        im.save(target/'reference.png');fresh['reference']=url(target/'reference.png');fresh['references']=[fresh['reference']]
        for index,old in enumerate(actions):
            aid=uid();node='action-'+aid
            options=json.loads(json.dumps(old['options']))
            # Frame exclusions belong to the old video, not the reusable animation settings.
            options.update(excluded=[],playback_fps=None)
            act={'id':aid,'name':old['name'],'prompt':old['prompt'],'video':None,'exports':[],'options':options,'video_model':old.get('video_model') or model_settings()['video_model']}
            fresh['actions'].append(act);fresh['graph']['nodes'].append(node);fresh['graph']['edges'].append({'from':'reference','to':node});fresh['layout'][node]={'x':395,'y':65+index*560}
            edge=next((e for e in g['edges'] if e['from']=='action-'+old['id'] and e['to'].startswith('process-')),None)
            processor=next((a for a in source['actions'] if edge and 'process-'+a['id']==edge['to']),old)
            proc_id=uid();proc_opts=json.loads(json.dumps(processor['options']));proc_opts.update(excluded=[],playback_fps=None)
            fresh['actions'].append({'id':proc_id,'name':old['name'],'prompt':'','video':None,'exports':[],'options':proc_opts})
            proc='process-'+proc_id;out='export-'+proc_id
            fresh['graph']['nodes'] += [proc,out];fresh['graph']['edges'] += [{'from':node,'to':proc},{'from':proc,'to':out}]
            fresh['layout'][proc]={'x':745,'y':65+index*560};fresh['layout'][out]={'x':1095,'y':65+index*560}
        STATE['projects'].append(fresh);save()
        return fresh

CLIPBOARDS={}

@app.post('/api/projects/{pid}/connected-node')
def create_connected_node(pid:str,body:dict):
    with LOCK:
        p=project(pid);g=canvas_graph(p);source=body.get('source');target=body.get('target')
        if source not in g['nodes']:raise HTTPException(400,'来源模块不存在')
        kind=source.rsplit('-',1)[0] if source.startswith('sheet-') else source.split('-')[0]
        allowed={'reference':['image','action','batch','sheet-edit'],'image':['image','action','batch','sheet-edit'],'action':['process'],'process':['export'],'export':['sheet-edit'],'sheet-source':['sheet-edit'],'sheet-edit':['sheet-export'],'sheet-export':['sheet-edit']}
        if target not in allowed.get(kind,[]):raise HTTPException(400,'连接类型不匹配')
        if len(g['nodes'])>=599:raise HTTPException(400,'画布模块数量已达上限')
        try:
            x=float(body['x']);y=float(body['y'])
            if not abs(x)<1e7 or not abs(y)<1e7:raise ValueError()
        except (KeyError,ValueError,TypeError):raise HTTPException(400,'模块位置无效')
        nid=uid();node=target+'-'+nid
        slot='image' if target in ['batch','sheet-edit'] and kind in ['reference','image'] else 'source'
        if target=='image':p.setdefault('images',[]).append({'id':nid,'name':'Image','source':None,'prompt':'','history':[]})
        elif target=='batch':p.setdefault('batches',[]).append({'id':nid,'source_project':pid,'actions':[a['id'] for a in p['actions'] if a.get('prompt','').strip() and 'action-'+a['id'] in g['nodes']],'image_id':'reference' if source=='reference' else source[6:],'frame_count':20,'threshold':5,'outputs':[]})
        elif target.startswith('sheet-'):
            p.setdefault('sheets',[]).append({'id':nid,'name':'Sprite Sheet 改造','source':None,'prompt':'','options':{'columns':10,'rows':2,'count':20,'fps':10,'size':256},'original':None,'exports':[]})
            if target=='sheet-edit':
                output='sheet-export-'+nid;g['nodes'].append(output);g['edges'].append({'from':node,'to':output});p['layout'][output]={'x':x+350,'y':y}
            else:p.setdefault('deleted_nodes',[]).extend(['sheet-edit-'+nid,'sheet-source-'+nid])
        else:
            opts=dict(DEFAULTS)
            if target=='process':opts=json.loads(json.dumps(next(a for a in p['actions'] if 'action-'+a['id']==source)['options']))
            p['actions'].append({'id':nid,'name':{'action':'新动作','process':'透明帧','export':'导出'}[target],'prompt':'','video':None,'exports':[],'options':opts})
        g['nodes'].append(node);g['edges'].append({'from':source,'to':node,'slot':slot});p['layout'][node]={'x':x,'y':y};p['graph']=g;save()
        return {'node':node,'id':nid,'type':target}

@app.post('/api/projects/{pid}/copy')
def copy_nodes(pid:str,body:dict):
    with LOCK:
        p=project(pid);g=canvas_graph(p);nodes=body.get('nodes',[])
        if not isinstance(nodes,list) or not nodes or len(nodes)>200 or any(n not in g['nodes'] for n in nodes):raise HTTPException(400,'请选择有效模块，最多200个')
        snapshot=json.loads(json.dumps(p))
        for node,pos in body.get('layout',{}).items():
            if node not in nodes:continue
            try:
                x=float(pos['x']);y=float(pos['y'])
                if not abs(x)<1e7 or not abs(y)<1e7:raise ValueError()
            except (KeyError,TypeError,ValueError):raise HTTPException(400,'复制位置无效')
            snapshot['layout'][node]={'x':x,'y':y}
        token=body.get('clipboard') or uid()
        if not isinstance(token,str) or not re.fullmatch(r'[a-f0-9]{16,32}',token) or token in CLIPBOARDS:raise HTTPException(400,'复制标识无效，请重新复制')
        CLIPBOARDS[token]={'project':snapshot,'nodes':list(dict.fromkeys(nodes)),'graph':g}
        while len(CLIPBOARDS)>30:CLIPBOARDS.pop(next(iter(CLIPBOARDS)))
        return {'clipboard':token,'count':len(set(nodes))}

@app.post('/api/projects/{pid}/paste')
def paste_nodes(pid:str,body:dict):
    with LOCK:
        p=project(pid);clip=CLIPBOARDS.get(body.get('clipboard'))
        if not clip:raise HTTPException(400,'复制内容已过期，请重新复制')
        g=canvas_graph(p)
        if len(g['nodes'])+len(clip['nodes'])>600:raise HTTPException(400,'画布最多600个模块')
        try:
            dx=float(body.get('dx',60));dy=float(body.get('dy',60))
            if not abs(dx)<1e7 or not abs(dy)<1e7:raise ValueError()
        except (TypeError,ValueError):raise HTTPException(400,'粘贴位置无效')
        src=clip['project'];mapping={};records={};created=[]
        for node in clip['nodes']:
            kind=node.rsplit('-',1)[0] if node.startswith('sheet-') else node.split('-')[0]
            oldid='reference' if node=='reference' else node.rsplit('-',1)[1]
            family='images' if kind in ['reference','image'] else 'sheets' if kind.startswith('sheet-') else 'batches' if kind=='batch' else 'actions'
            record_key=(family,oldid)
            if record_key not in records:
                original=image_item(src,oldid) if family=='images' else next(x for x in src.get(family,[]) if x['id']==oldid)
                record=json.loads(json.dumps(original));record['id']=uid();record['name']=str(record.get('name','同款动画'))+' · 副本'
                if family=='batches':
                    record['outputs']=[];record['groups']=[];record['running']=False;record.pop('run_message',None)
                records[record_key]=record;p.setdefault(family,[]).append(record)
            new_id=records[record_key]['id'];new=('image' if kind=='reference' else kind)+'-'+new_id;mapping[node]=new;created.append(new)
            pos=src.get('layout',{}).get(node)
            if not pos:
                index=next((i for i,a in enumerate(src['actions']) if a['id']==oldid),0)
                pos={'x':{'reference':45,'image':45,'action':395,'process':745,'export':1095}.get(kind,45),'y':95 if family=='images' else 65+index*480}
            p['layout'][new]={'x':pos['x']+dx,'y':pos['y']+dy}
        for (family,oldid),record in records.items():
            if family=='sheets':
                for kind in ['sheet-source','sheet-edit','sheet-export']:
                    key=kind+'-'+record['id']
                    if key not in created:p.setdefault('deleted_nodes',[]).append(key)
            if family=='batches':
                if 'image_ids' in record:record['image_ids']=[records[('images',iid)]['id'] if ('images',iid) in records else iid for iid in record['image_ids'] if ('images',iid) in records or src['id']==pid]
                remapped_cells={}
                for cell_key,cell in record.get('cells',{}).items():
                    old_image,sep,old_action=cell_key.partition(':')
                    if not sep:continue
                    image_id=records[('images',old_image)]['id'] if ('images',old_image) in records else old_image
                    action_id=records[('actions',old_action)]['id'] if record['source_project']==src['id'] and all(('actions',aid) in records for aid in record['actions']) and ('actions',old_action) in records else old_action
                    remapped_cells[image_id+':'+action_id]=cell
                record['cells']=remapped_cells
                image=records.get(('images',record['image_id']))
                if image:record['image_id']=image['id']
                elif src['id']!=pid:record['image_id']='reference'
                if record['source_project']==src['id'] and all(('actions',aid) in records for aid in record['actions']):
                    record['action_frames']={records[('actions',aid)]['id']:n for aid,n in record.get('action_frames',{}).items() if ('actions',aid) in records}
                    record['source_project']=pid;record['actions']=[records[('actions',aid)]['id'] for aid in record['actions']]
        g['nodes']+=created
        g['edges'] += [{**e,'from':mapping[e['from']],'to':mapping[e['to']]} for e in clip['graph']['edges'] if e['from'] in mapping and e['to'] in mapping]
        p['graph']=g;save();return {'nodes':created,'mapping':mapping}

@app.patch('/api/projects/{pid}')
def edit_project(pid:str,body:dict):
    with LOCK:
        p=project(pid)
        if 'name' in body:p['name']=str(body['name'])[:80]
        if 'layout' in body:p['layout']=body['layout']
        if 'graph' in body:
            g=body['graph'];valid={'reference'}|{'batch-'+x['id'] for x in p.get('batches',[])}|{'image-'+x['id'] for x in p.get('images',[])}|{f'{t}-{a["id"]}' for a in p['actions'] for t in ['action','process','export']}|{f'sheet-{t}-{x["id"]}' for x in p.get('sheets',[]) for t in ['source','edit','export']}
            if not isinstance(g,dict) or not isinstance(g.get('nodes'),list) or not isinstance(g.get('edges'),list):raise HTTPException(400,'无效画布')
            if len(g['nodes'])>600 or any(n not in valid for n in g['nodes']):raise HTTPException(400,'节点不属于当前项目')
            targets=set()
            for e in g['edges']:
                f,t=e.get('from'),e.get('to')
                kind=lambda n:n.rsplit('-',1)[0] if n.startswith('sheet-') else n.split('-')[0]
                slot=e.get('slot','source');target=(t,slot,f) if isinstance(t,str) and t.startswith('batch-') and slot=='image' else (t,slot)
                pairs=[('reference','reference'),('reference','image'),('image','reference'),('image','image'),('reference','action'),('image','action'),('action','process'),('process','export'),('sheet-source','sheet-edit'),('sheet-edit','sheet-export'),('export','sheet-edit'),('sheet-export','sheet-edit')]
                if slot=='image':pairs=[('reference','sheet-edit'),('image','sheet-edit'),('reference','batch'),('image','batch')]
                if f not in g['nodes'] or t not in g['nodes'] or slot not in ['source','image'] or (kind(f),kind(t)) not in pairs or target in targets:raise HTTPException(400,'连接类型不匹配，或输入已有连接')
                targets.add(target)
            def visit(node,path,done):
                if node in path:raise HTTPException(400,'连线不能形成循环，请创建新的改造节点')
                if node in done:return
                for e in g['edges']:
                    if e['from']==node:visit(e['to'],path|{node},done)
                done.add(node)
            done=set()
            for node in g['nodes']:visit(node,set(),done)
            previous_nodes=canvas_graph(p)['nodes']
            p['graph']=g
            if body.get('restore_nodes'):
                p['deleted_nodes']=list((set(p.get('deleted_nodes',[]))|set(previous_nodes))-set(g['nodes']))
        save();return p
@app.post('/api/projects/{pid}/reference')
async def upload_ref(pid:str,file:UploadFile=File(...)):
    p=project(pid);data=await file.read(25*1024*1024+1)
    if len(data)>25*1024*1024:raise HTTPException(413,'图片不能超过25MB')
    try:
        im=Image.open(io.BytesIO(data));im.load()
        if im.width*im.height>20000000:raise ValueError()
        im=im.convert('RGBA');im.thumbnail((2048,2048),Image.Resampling.NEAREST)
    except Exception:raise HTTPException(400,'请选择有效的PNG、JPG或WebP图片')
    target=DATA/pid/uid();target.mkdir(parents=True);im.save(target/'reference.png')
    with LOCK:p['reference']=url(target/'reference.png');p['references'].append(p['reference']);save()
    return p

@app.delete('/api/projects/{pid}/nodes/{node}')
def delete_canvas_node(pid:str,node:str):
    with LOCK:
        p=project(pid);g=canvas_graph(p)
        if node not in g['nodes']:raise HTTPException(404,'节点不存在')
        aid=node.rsplit('-',1)[-1] if node!='reference' else 'reference'
        if any(j['project']==pid and (j.get('action')==aid or j.get('image_id')==aid) and j['status'] in ['running','queued'] for j in STATE['jobs']):raise HTTPException(409,'此节点正在运行，请完成后删除')
        p.setdefault('deleted_nodes',[]).append(node)
        g['nodes'].remove(node);g['edges']=[e for e in g['edges'] if e['from']!=node and e['to']!=node];g['version']=2
        p['graph']=g;save();return {'deleted':node,'files_preserved':True}

@app.post('/api/projects/{pid}/nodes/delete')
def delete_canvas_nodes(pid:str,body:dict):
    with LOCK:
        p=project(pid);g=canvas_graph(p);nodes=body.get('nodes')
        if not isinstance(nodes,list) or not nodes or any(not isinstance(n,str) or n not in g['nodes'] for n in nodes):raise HTTPException(400,'请选择有效模块')
        remove=set(nodes);ids={n.rsplit('-',1)[-1] for n in remove}
        for b in p.get('batches',[]):
            if b.get('running') and ('batch-'+b['id'] in remove or any(n.rsplit('-',1)[-1] in b.get('outputs',[]) for n in remove)):raise HTTPException(409,'批量队列正在运行，请结束后删除')
            if 'batch-'+b['id'] in remove:ids.update(b.get('outputs',[]))
        if any(j['project']==pid and (j.get('action') in ids or j.get('image_id') in ids) and j['status'] in ['queued','running'] for j in STATE['jobs']):raise HTTPException(409,'选中的模块仍在制作中，未删除任何模块，请完成后重试')
        p['deleted_nodes']=list(set(p.get('deleted_nodes',[]))|remove)
        g['nodes']=[n for n in g['nodes'] if n not in remove]
        g['edges']=[e for e in g['edges'] if e['from'] not in remove and e['to'] not in remove]
        p['graph']=g;save();return {'deleted':list(remove),'files_preserved':True}

@app.post('/api/projects/{pid}/remixes')
def create_remix(pid:str,body:dict):
    with LOCK:
        p=project(pid);g=canvas_graph(p);sid=uid()
        s={'id':sid,'name':str(body.get('name','精灵图改造'))[:60],'source':None,'original':None,'options':{},'prompt':'保留输入精灵图的逐帧动作、帧数、排列与朝向。根据 Image 参考和提示词修改外观，透明背景。','exports':[]}
        p.setdefault('sheets',[]).append(s);g['nodes']+=['sheet-edit-'+sid,'sheet-export-'+sid];g['edges'].append({'from':'sheet-edit-'+sid,'to':'sheet-export-'+sid});g['version']=2;p['graph']=g;save();return s
@app.post('/api/projects/{pid}/image')
def image_job(pid:str,body:dict):
    p=project(pid)
    if not key('OPENAI_API_KEY'):raise HTTPException(400,'请先在连接设置中配置 OpenAI API Key')
    prompt=str(body.get('prompt','')).strip()
    if not prompt or len(prompt)>20000:raise HTTPException(400,'请输入生图指令（最多20000字）')
    j=new_job('image',pid,prompt=prompt,reference=p['reference'] if body.get('use_reference',True) else None,model=model_settings()['image_model']);execute(j,lambda:generate_image(j));return j

DEFAULTS={'continuity_mode':None,'target_frame_count':None,'motion_pixel_stable':False,'motion_pixel_size':256,'motion_pixel_cell':1,'motion_pixel_strength':'standard','video_resolution':'480p','pixel_stable':True,'fps':10,'playback_fps':None,'duration':2,'start':0,'size':256,'columns':10,'threshold':5,'softness':0,'despill':True,'crop':True,'pingpong':False,'loop':True,'excluded':[],'color_mode':'repair','color_threshold':6,'color_algorithm':'luminance-v3'}

@app.post('/api/projects/{pid}/images')
def create_image_node(pid:str,body:dict):
    p=project(pid);item={'id':uid(),'name':str(body.get('name','Image'))[:80],'source':None,'prompt':'','history':[]}
    with LOCK:
        p.setdefault('images',[]).append(item)
        if 'graph' in p:p['graph']['nodes'].append('image-'+item['id'])
        save()
    return item

@app.patch('/api/projects/{pid}/images/{iid}')
def update_image_node(pid:str,iid:str,body:dict):
    p=project(pid);item=image_item(p,iid)
    with LOCK:
        for k,limit in [('name',80),('prompt',20000)]:
            if k in body:item[k]=str(body[k])[:limit]
        save()
    return item

@app.post('/api/projects/{pid}/images/{iid}/upload')
async def upload_image_node(pid:str,iid:str,file:UploadFile=File(...)):
    p=project(pid);item=image_item(p,iid)
    if any(j.get('image_id')==iid and j['project']==pid and j['status'] in ['running','queued'] for j in STATE['jobs']):raise HTTPException(409,'请等待此 Image 生成结束')
    data=await file.read(25*1024*1024+1)
    if len(data)>25*1024*1024:raise HTTPException(413,'图片不能超过25MB')
    try:
        im=Image.open(io.BytesIO(data))
        if im.width*im.height>20000000:raise ValueError()
        im.load();im=im.convert('RGBA')
    except Exception:raise HTTPException(400,'请选择有效图片')
    target=DATA/pid/uid();target.mkdir(parents=True);im.save(target/'image.png')
    store_image(p,item,url(target/'image.png'));return item

@app.post('/api/projects/{pid}/images/{iid}/generate')
def generate_image_node(pid:str,iid:str,body:dict):
    p=project(pid);item=image_item(p,iid)
    if not key('OPENAI_API_KEY'):raise HTTPException(400,'请先配置 OpenAI API Key')
    prompt=str(body.get('prompt',item['prompt'])).strip()
    if not prompt or len(prompt)>20000:raise HTTPException(400,'请输入生图指令，最多20000字')
    background=body.get('background','auto')
    if background not in ['auto','transparent','green']:raise HTTPException(400,'无效背景选项')
    if background=='green':prompt+='\nUniform flat pure green background RGB(0,255,0), no gradients, shadows or green reflected light on the subject.'
    node='reference' if iid=='reference' else 'image-'+iid
    edge=next((e for e in canvas_graph(p)['edges'] if e['to']==node and e.get('slot','source')=='source'),None)
    if body.get('reference_current'):edge=None
    reference=None
    if body.get('use_reference',bool(edge)):
        upstream=image_item(p,'reference' if edge['from']=='reference' else edge['from'][6:]) if edge else item
        reference=upstream.get('source')
        if not reference:raise HTTPException(400,'参考图片尚未生成或上传，请先完成上游 Image')
    if body.get('use_reference') and not reference:raise HTTPException(400,'请先导入图片再使用图片编辑')
    j=new_job('image',pid,iid,image_id=iid,prompt=prompt,reference=reference,model=model_settings()['image_model'],background='opaque' if background=='green' else background)
    execute(j,lambda:generate_image(j));return j

@app.post('/api/projects/{pid}/images/{iid}/green')
def green_image_node(pid:str,iid:str,body:dict=None):
    p=project(pid);item=image_item(p,iid)
    if not item.get('source'):raise HTTPException(400,'请先导入或生成图片')
    if any(j.get('image_id')==iid and j['project']==pid and j['status'] in ['running','queued'] for j in STATE['jobs']):raise HTTPException(409,'请等待此 Image 生成结束')
    im=Image.open(path(item['source'])).convert('RGBA')
    if im.getchannel('A').getextrema()[0]<255:
        result=Image.new('RGBA',im.size,(0,255,0,255));result.alpha_composite(im)
        target=DATA/pid/uid();target.mkdir(parents=True);result.save(target/'green.png')
        store_image(p,item,url(target/'green.png'));return {'local':True,'image':item}
    if not (body or {}).get('allow_ai'):raise HTTPException(409,'需要AI换背景：此图片没有透明区域')
    return generate_image_node(pid,iid,{'use_reference':True,'reference_current':True,'background':'green','prompt':'Replace only the background with solid pure green RGB(0,255,0). Preserve the complete foreground subject, pose, colors, outlines, texture and art style. No new objects or cast shadows. Do not crop the subject.'})

@app.post('/api/projects/{pid}/actions')
def add_action(pid:str,body:dict):
    with LOCK:
        p=project(pid);a={'id':uid(),'name':str(body.get('name','idle'))[:60],'prompt':str(body.get('prompt',''))[:20000],'video':None,'exports':[],'options':dict(DEFAULTS)}
        if body.get('stage') not in [None,'action','process','export']:raise HTTPException(400,'无效步骤')
        if body.get('stage') and 'graph' not in p:
            p['graph']={'nodes':['reference']+[f'{t}-{x["id"]}' for x in p['actions'] for t in ['action','process','export']], 'edges':[e for x in p['actions'] for e in [{'from':'reference','to':'action-'+x['id']},{'from':'action-'+x['id'],'to':'process-'+x['id']},{'from':'process-'+x['id'],'to':'export-'+x['id']}]]}
        if 'duration' in body:a['options']['duration']=float(body['duration'])
        p['actions'].append(a)
        if 'graph' in p:
            stages=[body['stage']] if body.get('stage') else ['action','process','export']
            p['graph']['nodes'].extend(t+'-'+a['id'] for t in stages)
            if not body.get('stage'):p['graph']['edges'].extend([{'from':'reference','to':'action-'+a['id']},{'from':'action-'+a['id'],'to':'process-'+a['id']},{'from':'process-'+a['id'],'to':'export-'+a['id']}])
        save();return a
@app.patch('/api/actions/{aid}')
def edit_action(aid:str,body:dict):
    with LOCK:
        p,a=action(aid)
        resolution=body.get('options',{}).get('video_resolution','480p')
        if resolution not in ['480p','720p','1080p']:raise HTTPException(400,'请选择480p、720p或1080p分辨率')
        if 'extra_prompts' in body:
            prompts=body['extra_prompts']
            if not isinstance(prompts,list) or len(prompts)>9 or any(not isinstance(x,str) or len(x)>20000 for x in prompts):
                raise HTTPException(400,'最多10条视频指令，每条不超过20000字')
        if 'video_model' in body:
            model=str(body['video_model'])
            if not re.fullmatch(r'[a-zA-Z0-9._-]{1,100}',model):raise HTTPException(400,'视频模型名称无效')
            a['video_model']=model
        if 'name' in body:a['name']=str(body['name'])[:60]
        if 'prompt' in body:a['prompt']=str(body['prompt'])[:20000]
        if 'extra_prompts' in body:a['extra_prompts']=list(body['extra_prompts'])
        count=body.get('options',{}).get('target_frame_count')
        if count is not None and (isinstance(count,bool) or not isinstance(count,(int,float)) or not 1<=count<=120 or int(count)!=count):raise HTTPException(400,'输出总帧数必须为1–120的整数')
        if 'options' in body and any(k in body['options'] and body['options'][k]!=a['options'].get(k) for k in ['fps','start','duration','target_frame_count']):a['options'].update(excluded=[],playback_fps=None)
        if 'options' in body:a['options'].update({k:v for k,v in body['options'].items() if k in DEFAULTS})
        save();return a

@app.post('/api/actions/{aid}/expand-prompts')
def expand_video_prompts(aid:str):
    """Materialize independent editable outputs; never submit a paid job here."""
    with LOCK:
        p,a=action(aid);g=canvas_graph(p)
        if 'action-'+aid not in g['nodes']:raise HTTPException(400,'视频模块已删除')
        prompts=[a.get('prompt','')]+a.get('extra_prompts',[])
        if any(not x.strip() for x in prompts):raise HTTPException(400,'请填写每条视频指令，或删除空白指令')
        if any(j.get('action')==aid and j['status'] in ['queued','running'] for j in STATE['jobs']):
            raise HTTPException(409,'此视频正在生成，请稍后再试')
        incoming=[e for e in g['edges'] if e['to']=='action-'+aid]
        ids=[aid];layout=p.setdefault('layout',{})
        origin=layout.get('action-'+aid,{'x':395,'y':65})
        bottom=max([float(pos.get('y',0)) for pos in layout.values()]+[origin['y']])+700
        for i,prompt in enumerate(prompts[1:],2):
            nid=uid();node='action-'+nid
            record={'id':nid,'name':(a['name']+' · 指令 '+str(i))[:60],
                    'prompt':prompt,'video':None,'exports':[],
                    'options':json.loads(json.dumps(a['options'])),'prompt_source':aid}
            if a.get('video_model'):record['video_model']=a['video_model']
            p['actions'].append(record);g['nodes'].append(node)
            g['edges'].extend({'from':e['from'],'to':node} for e in incoming)
            layout[node]={'x':origin['x'],'y':bottom+(i-2)*700};ids.append(nid)
        p['graph']=g;save();return {'actions':ids}
@app.post('/api/actions/{aid}/video')
async def upload_video(aid:str,file:UploadFile=File(...)):
    p,a=action(aid)
    if any(j.get('action')==aid and j['status'] in ['queued','running'] for j in STATE['jobs']):raise HTTPException(409,'请等待当前任务完成')
    ext=Path(file.filename or '').suffix.lower()
    if ext not in ['.mp4','.webm','.mov']:raise HTTPException(400,'支持 MP4、WebM 和 MOV')
    target=DATA/p['id']/uid();target.mkdir(parents=True);f=target/('video'+ext)
    total=0
    with f.open('wb') as dest:
        while chunk:=await file.read(1024*1024):
            total+=len(chunk)
            if total>150*1024*1024:raise HTTPException(413,'视频不能超过150MB')
            dest.write(chunk)
    with LOCK:a['video']=url(f);save()
    return a
@app.post('/api/actions/{aid}/generate')
def video_job(aid:str,body:dict=None):
    p,a=action(aid)
    if not key('ARK_API_KEY'):raise HTTPException(400,'请配置 ARK API Key')
    source=video_image(p,aid)
    if not source:raise HTTPException(400,'连接的 Image 节点尚无图片，请先粘贴、上传或生成')
    if not a['prompt'].strip():raise HTTPException(400,'请填写动作指令')
    constraints=' Fixed camera. Preserve the input subject, art style, colors and proportions. Uniform pure green background RGB(0,255,0). No camera movement, no added text or objects. '
    j=new_job('video',p['id'],aid,prompt=a['prompt']+constraints,reference=source,model=a.get('video_model') or model_settings()['video_model'],auto_process=bool((body or {}).get('auto_process',False)),options={**a['options'],'name':a['name']})
    execute(j,lambda:generate_video(j));return j
@app.post('/api/actions/{aid}/process')
def process_job(aid:str):
    p,a=action(aid)
    source=a
    if 'graph' in p:
        edge=next((e for e in p['graph']['edges'] if e['to']=='process-'+aid),None)
        if not edge:raise HTTPException(400,'请先连接视频输出与透明处理输入')
        source=next(x for x in p['actions'] if 'action-'+x['id']==edge['from'])
    if not source['video']:raise HTTPException(400,'连接的视频尚未导入或生成')
    opts={**a['options'],'name':a['name']}
    j=new_job('process',p['id'],aid,video=source['video'],options=opts);execute(j,lambda:process_action(j));return j

@app.post('/api/actions/{aid}/pipeline')
def prepare_video_pipeline(aid:str,body:dict=None):
    with LOCK:
        p,a=action(aid);g=canvas_graph(p);source='action-'+aid
        if source not in g['nodes']:raise HTTPException(400,'视频节点已删除')
        options=None
        if body:
            try:
                if type(body['frame_count']) is not int:raise ValueError()
                count=body['frame_count'];threshold=int(body['threshold'])
                if not 1<=count<=120 or not 0<=threshold<=255:raise ValueError()
            except (KeyError,ValueError,TypeError):raise HTTPException(400,'请检查输出帧数和去绿幕强度')
            options={'target_frame_count':count,'threshold':threshold,'fps':10,'excluded':[],'playback_fps':None,'pingpong':False,'despill':True,'softness':0}
        edge=next((e for e in g['edges'] if e['from']==source and e['to'].startswith('process-')),None)
        if edge:processor=edge['to']
        else:
            rec={'id':uid(),'name':a['name'],'prompt':'','video':None,'exports':[],'options':dict(a['options'])}
            p['actions'].append(rec);processor='process-'+rec['id'];g['nodes'].append(processor);g['edges'].append({'from':source,'to':processor})
        if options:
            record=next(x for x in p['actions'] if 'process-'+x['id']==processor)
            if any(j.get('action')==record['id'] and j['status'] in ['queued','running'] for j in STATE['jobs']):raise HTTPException(409,'透明处理正在运行，请完成后重试')
            record['options'].update(options)
        export_edge=next((e for e in g['edges'] if e['from']==processor and e['to'].startswith('export-')),None)
        output=export_edge['to'] if export_edge else 'export-'+processor[8:]
        if not export_edge:
            if output not in g['nodes']:g['nodes'].append(output)
            g['edges'].append({'from':processor,'to':output})
            p['deleted_nodes']=[n for n in p.get('deleted_nodes',[]) if n!=output]
        origin=p['layout'].get(source,{'x':395,'y':65});p['layout'].setdefault(processor,{'x':origin['x']+350,'y':origin['y']});p['layout'].setdefault(output,{'x':origin['x']+700,'y':origin['y']})
        g['version']=2;p['graph']=g;save();return {'process':processor,'export':output}
@app.post('/api/jobs/{jid}/resume')
def resume(jid:str):
    j=next((j for j in STATE['jobs'] if j['id']==jid),None)
    if not j or j['kind']!='video' or not j.get('task_id'):raise HTTPException(400,'只有已取得任务编号的视频可继续查询')
    if j['status'] in ['queued','running','done']:raise HTTPException(409,'该任务不需要恢复')
    update_job(j,status='queued');execute(j,lambda:generate_video(j));return j
def load_prepared_demo(kind,existing=None):
    folder=HERE/'samples'/kind
    manifest=json.loads((folder/'project.json').read_text(encoding='utf-8'))
    template=manifest['project'];mapping={}
    if existing and all(a.get('exports') for a in existing['actions']):return existing
    for dep in manifest.get('dependencies',[]):
        source=demo({'kind':dep['kind']});mapping[dep['project_id']]=source['id']
        for old,name in dep['actions'].items():
            match=next((a for a in source['actions'] if a['name']==name),None)
            if not match:raise HTTPException(400,'示例依赖动作被修改，请先恢复对应示例')
            mapping[old]=match['id']
    def collect(value):
        if isinstance(value,dict):
            if isinstance(value.get('id'),str):mapping.setdefault(value['id'],uid())
            for v in value.values():collect(v)
        elif isinstance(value,list):
            for v in value:collect(v)
    collect(template)
    if existing:
        mapping[template['id']]=existing['id']
        for a in template['actions']:
            match=next((v for v in existing['actions'] if v['name']==a['name']),None)
            if match:mapping[a['id']]=match['id']
    dest=DATA/mapping[template['id']]/('sample-'+uid());dest.mkdir(parents=True)
    for archive in manifest['archives']:
        archive_path=(folder/archive).resolve()
        if not archive_path.is_relative_to(folder.resolve()):raise ValueError('无效示例路径')
        with zipfile.ZipFile(archive_path) as z:
            for entry in z.infolist():
                target=(dest/entry.filename).resolve()
                if not target.is_relative_to(dest.resolve()):raise ValueError('无效示例素材路径')
                z.extract(entry,dest)
    def rewrite(value):
        if isinstance(value,dict):return {rewrite(k):rewrite(v) for k,v in value.items()}
        if isinstance(value,list):return [rewrite(v) for v in value]
        if isinstance(value,str):
            if value.startswith('/media/'):return url(dest/'assets'/value[7:])
            for old,new in mapping.items():value=value.replace(old,new)
        return value
    prepared=rewrite(template)
    if existing:
        for old in template['actions']:
            target=next((a for a in existing['actions'] if a['id']==mapping[old['id']]),None)
            expected=manifest.get('video_hashes',{}).get(old['id'])
            if target and not target.get('exports') and target.get('video') and expected:
                if hashlib.sha256(path(target['video']).read_bytes()).hexdigest()==expected:
                    target['exports']=rewrite(old.get('exports',[]))
        save();return existing
    prepared.update(demo=True,demo_kind=kind,archived=False,created=time.time())
    for batch in prepared.get('batches',[]):batch.update(running=False,run_message='示例结果已准备好，可展开工作流继续编辑')
    STATE['projects'].append(prepared);save();return prepared

@app.post('/api/demo')
def demo(body:dict=None):
    kind=(body or {}).get('kind','golden')
    if kind not in ['golden','giant','batch','calico-nine']:raise HTTPException(400,'未知示例')
    title={'golden':'金色招财猫 · 示例','giant':'巨型猫 · 示例','batch':'批量化尝试','calico-nine':'三花猫 · 三向九动作范例'}[kind]
    with LOCK:
        existing=next((p for p in STATE['projects'] if p.get('demo_kind')==kind or p['name']==title or (kind=='golden' and p.get('demo') and not p.get('demo_kind'))),None)
        if existing:
            existing.update(demo=True,demo_kind=kind,archived=False);save()
            if kind in ['golden','giant'] and (HERE/'samples'/kind/'project.json').exists():return load_prepared_demo(kind,existing)
            return existing
        if (HERE/'samples'/kind/'project.json').exists():return load_prepared_demo(kind)
        source=HERE/'samples'/kind
        if not source.exists():source=ROOT/'output/seedance'/('cat2' if kind=='giant' else 'golden')
        clips={}
        for name in ['walk','idle','fur']:
            seconds=1 if name=='walk' else 2
            folder='fur-v2' if kind=='giant' and name=='fur' else name
            prefix='cat2-'+folder if kind=='giant' else 'golden-'+name
            clips[name]=source/folder/f'{prefix}-{seconds}s.mp4'
        if not (source/'reference.png').exists() or not all(f.exists() for f in clips.values()):raise HTTPException(404,'示例素材不完整，请上传包含 samples 文件夹的更新包')
        p=create_project({'name':title});p.update(demo=True,demo_kind=kind)
        dest=DATA/p['id'];dest.mkdir(parents=True,exist_ok=True);shutil.copy2(source/'reference.png',dest/'reference.png')
        p['reference']=url(dest/'reference.png');p['references']=[p['reference']]
        prompts={'walk':'原地向左行走，四肢交替，身体轻微起伏，表情不变，1秒循环。','idle':'站立不动，轻微呼吸，尾巴小幅缓慢晃动，禁止眨眼，2秒循环。','fur':'保持侧面朝向，迅速坐下，抬落左前爪招财，回站，2秒循环。'}
        if kind=='giant':prompts['fur']='保持侧面朝向，前身俯下、抬高臀部，眯眼后回到站姿。T形鼻子不变，不增加嘴巴或毛球，2秒循环。'
        for name,src in clips.items():
            prompt_file=source/('fur-v2.txt' if kind=='giant' and name=='fur' else name+'.txt')
            prompt=prompt_file.read_text(encoding='utf-8-sig').strip() if prompt_file.exists() else prompts[name]
            seconds=1 if name=='walk' else 2
            a=add_action(p['id'],{'name':name,'prompt':prompt,'duration':seconds})
            ad=dest/a['id'];ad.mkdir();shutil.copy2(src,ad/'video.mp4');a['video']=url(ad/'video.mp4')
        save();return p

@app.post('/api/projects/{pid}/sheets')
async def upload_sheet(pid:str,file:UploadFile=File(...),spec:str=Form(...)):
    p=project(pid)
    try:
        opts=json.loads(spec)
        options={'columns':int(opts.get('columns',10)),'rows':int(opts.get('rows',2)),'count':int(opts.get('count',20)),'fps':int(opts.get('fps',10)),'size':int(opts.get('size',256)),'name':str(opts.get('name','reskin'))[:60]}
        data=await file.read(40*1024*1024+1)
        if len(data)>40*1024*1024:raise ValueError('精灵图不能超过40MB')
        im=Image.open(io.BytesIO(data));im.load()
        if im.width*im.height>32000000:raise ValueError('精灵图尺寸过大')
        im=im.convert('RGBA')
    except Exception as exc:raise HTTPException(400,'请检查图片和网格参数：'+str(exc)[:160])
    sid=uid();target=DATA/pid/sid;target.mkdir(parents=True);im.save(target/'source.png')
    try:meta=process_sheet(target/'source.png',target/'original',options)
    except Exception as exc:raise HTTPException(400,str(exc))
    s={'id':sid,'name':options['name'],'source':url(target/'source.png'),'prompt':str(opts.get('prompt',''))[:16000],'options':options,'original':{'base':url(target/'original'),'meta':meta},'exports':[]}
    with LOCK:p.setdefault('sheets',[]).append(s);save()
    return s
@app.patch('/api/sheets/{sid}')
def edit_sheet(sid:str,body:dict):
    p,s=sheet(sid)
    with LOCK:
        if 'prompt' in body:s['prompt']=str(body['prompt'])[:16000]
        save()
    return s
@app.post('/api/sheets/{sid}/generate')
def sheet_job(sid:str):
    p,s=sheet(sid)
    if not key('OPENAI_API_KEY'):raise HTTPException(400,'请先配置 OpenAI API Key；原图预览和本地打包仍可使用')
    if not s['prompt'].strip():raise HTTPException(400,'请填写改造提示词')
    g=canvas_graph(p)
    edge=next((e for e in g['edges'] if e['to']=='sheet-edit-'+sid and e.get('slot','source')=='source'),None)
    if not edge:raise HTTPException(400,'请连接 Sprite Sheet 到动作输入端口')
    src=sheet_input(p,edge['from'])
    image_edge=next((e for e in g['edges'] if e['to']=='sheet-edit-'+sid and e.get('slot')=='image'),None)
    reference=None
    if image_edge:
        reference=image_item(p,'reference' if image_edge['from']=='reference' else image_edge['from'][6:]).get('source')
        if not reference:raise HTTPException(400,'连接的 Image 尚无图片')
    j=new_job('sheet',p['id'],sid,source=src['source'],reference=reference,prompt=s['prompt'],options={**src['options'],**{k:v for k,v in s.get('options',{}).items() if k in ['color_mode','color_threshold','color_algorithm']},'name':s['name']},model=model_settings()['image_model'])
    execute(j,lambda:generate_sheet(j));return j

@app.get('/media/{resource:path}')
def media(resource:str):
    f=(DATA/resource).resolve()
    if not f.is_relative_to(DATA) or f.suffix.lower() not in ['.png','.gif','.mp4','.webm','.mov','.zip','.json','.tres','.txt'] or not f.is_file():raise HTTPException(404)
    download=f.name if f.suffix in ['.zip','.tres','.json'] else None
    return FileResponse(f,filename=download)
import sys
from studio_api import install
install(sys.modules[__name__])

app.mount('/',StaticFiles(directory=HERE/'web',html=True),name='web')

if __name__=='__main__':
    import uvicorn
    uvicorn.run(app,host=os.environ.get('ASSET_CANVAS_HOST','127.0.0.1'),port=int(os.environ.get('ASSET_CANVAS_PORT','8766')),access_log=False)
