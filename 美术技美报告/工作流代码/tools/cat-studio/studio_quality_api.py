"""Preview/apply local algorithms and visible direction image slots."""
import math, re
from PIL import Image
from motion_quality import align_clips, continuity_report

def install(s,records):
    app=s.app
    labels={'side':'侧视图','up':'向上','down':'向下'}

    def directions(p):
        result=dict(p.get('direction_images',{}))
        for direction,pattern in [('side',r'侧|side'),('up',r'上|up|背面'),('down',r'下|down|正面')]:
            if direction not in result:
                match=next((i for i in p.get('images',[]) if re.search(pattern,i['name'],re.I)),None)
                if match:result[direction]=match['id']
        if 'side' not in result and p.get('reference'):result['side']='reference'
        return result

    def ensure_slot(p,direction):
        if direction not in labels:raise s.HTTPException(400,'无效方向')
        iid=directions(p).get(direction)
        if not iid:iid=s.create_image_node(p['id'],{'name':labels[direction]})['id']
        p.setdefault('direction_images',{})[direction]=iid;s.save()
        return iid

    @app.get('/api/studio/projects/{pid}/references')
    def references(pid:str):
        p=s.project(pid);mapping=directions(p)
        return {'slots':{k:({'id':mapping[k],**s.image_item(p,mapping[k])} if k in mapping else None) for k in labels},
                'images':p.get('images',[])}

    @app.post('/api/studio/projects/{pid}/references/{direction}')
    def bind_reference(pid:str,direction:str,body:dict):
        p=s.project(pid)
        if direction not in labels:raise s.HTTPException(400,'无效方向')
        iid=str(body.get('image_id',''));s.image_item(p,iid)
        with s.LOCK:p.setdefault('direction_images',{})[direction]=iid;s.save()
        return {'id':iid}

    @app.post('/api/studio/projects/{pid}/references/{direction}/upload')
    async def upload_direction(pid:str,direction:str,file:s.UploadFile=s.File(...)):
        p=s.project(pid)
        with s.LOCK:iid=ensure_slot(p,direction)
        return await s.upload_image_node(pid,iid,file)

    @app.post('/api/studio/projects/{pid}/references/{direction}/generate')
    def generate_direction(pid:str,direction:str,body:dict):
        p=s.project(pid);prompt=str(body.get('prompt','')).strip()
        if not body.get('paid_confirmed'):raise s.HTTPException(400,'请确认生图使用模型额度')
        if not s.key('OPENAI_API_KEY'):raise s.HTTPException(400,'请在连接设置填写 OpenAI API Key')
        if not prompt or len(prompt)>20000:raise s.HTTPException(400,'请填写生图描述，最多20000字')
        ref=None
        if body.get('reference_id'):
            ref=s.image_item(p,str(body['reference_id'])).get('source')
            if not ref:raise s.HTTPException(400,'选中的参考图还没有图片')
        with s.LOCK:
            iid=ensure_slot(p,direction)
            if any(j.get('image_id')==iid and j['project']==pid and j['status'] in ['queued','running'] for j in s.STATE['jobs']):
                raise s.HTTPException(409,'这张参考图正在生成')
            prompt+='\n'+{'side':'Side view.','up':'Facing upward, back view.','down':'Facing downward, front view.'}[direction]
            prompt+=' Uniform pure green background RGB(0,255,0). Preserve character identity, palette and pixel art style.'
            j=s.new_job('image',pid,iid,image_id=iid,prompt=prompt,reference=ref,model=s.model_settings()['image_model'],background='opaque')
            s.execute(j,lambda:s.generate_image(j));return j

    def load_frames(ex):
        n=int(ex['meta']['frame_count']);base=s.path(ex['base'])
        if n>450:raise ValueError('单个动画最多支持450帧')
        return [Image.open(base/'frames'/f'{i:03}.png').convert('RGBA') for i in range(n)]

    def geometry_extra(ex):
        return {k:v for k,v in ex['meta'].items() if k in ['source_frame_count','kept_source_indices','sample_fps','sample_times','continuity_report','alignment_report','pivot']}

    @app.post('/api/studio/actions/{aid}/export-sized')
    def export_sized(aid:str,body:dict):
        if type(body.get('frame_size'))!=int or body['frame_size']!=320:raise s.HTTPException(400,'请选择320像素')
        with s.LOCK:
            p,a,proc=records(aid)
            if not proc.get('exports'):raise s.HTTPException(400,'尚无可导出结果')
            ex=s.json.loads(s.json.dumps(proc['exports'][-1]))
            if ex['id']!=body.get('export_id'):raise s.HTTPException(409,'素材已更新，请重试')
        dest=s.DATA/'downloads'/s.uid()
        with s.PROCESS_LOCK:
            frames=[im.resize((320,320),Image.Resampling.NEAREST) for im in load_frames(ex)]
            extra={'source_frames_available':False,'color_original_available':False,'export_source':ex['id']}
            if ex['meta'].get('pivot'):
                extra['pivot']=[ex['meta']['pivot'][0]*320/ex['meta']['frame_width'],ex['meta']['pivot'][1]*320/ex['meta']['frame_height']]
            meta=s.pack_frames(frames,dest,{**ex['meta']['settings'],'name':a['name'],'size':320,
                'playback_fps':ex['meta']['fps'],'loop':ex['meta']['loop'],'pingpong':False},extra=extra,apply_color=False)
        return {'url':s.url(dest/'spritesheet.zip'),'frame_size':320,'frame_count':meta['frame_count']}

    @app.post('/api/studio/actions/{aid}/speed')
    def speed(aid:str,body:dict):
        fps=body.get('fps')
        if type(fps) not in [int,float] or not math.isfinite(fps) or not .1<=fps<=120:
            raise s.HTTPException(400,'播放速度必须为0.1–120 FPS')
        with s.LOCK:
            p,a,proc=records(aid)
            if any(j['status'] in ['queued','running'] and (j.get('action') in [aid,proc['id']] or aid in j.get('quality_actions',[])) for j in s.STATE['jobs']):
                raise s.HTTPException(409,'请等待当前任务完成后调整速度')
            if not proc.get('exports'):raise s.HTTPException(400,'请先完成透明处理')
            old=s.json.loads(s.json.dumps(proc['exports'][-1]))
            if body.get('export_id')!=old['id']:raise s.HTTPException(409,'动作结果已更新，请重新打开播放速度')
            j=s.new_job('speed',p['id'],proc['id'])
            def work():
                with s.PROCESS_LOCK:
                    dest=s.DATA/p['id']/j['id'];dest.mkdir(parents=True)
                    for folder in ['source_frames','color_original_frames']:
                        source=s.path(old['base'])/folder
                        if source.exists():s.shutil.copytree(source,dest/folder)
                    extra={k:v for k,v in old['meta'].items() if k not in ['settings','frames','warnings','name','fps','duration','frame_count','columns','loop','frame_width','frame_height']}
                    meta=s.pack_frames(load_frames(old),dest,{**old['meta']['settings'],'name':a['name'],
                        'playback_fps':fps,'pingpong':False},old['meta'].get('warnings',[]),extra=extra,apply_color=False)
                    ex={'id':j['id'],'base':s.url(dest),'meta':meta,'created':s.time.time(),'source_video':old.get('source_video') or a.get('video')}
                    with s.LOCK:
                        proc['exports'].append(ex);proc['options']['playback_fps']=fps;s.save()
            s.execute(j,work);return j

    @app.post('/api/studio/actions/{aid}/rename')
    def rename(aid:str,body:dict):
        name=str(body.get('name','')).strip()
        if not name or len(name)>60:raise s.HTTPException(400,'动作名称为1–60个字符')
        with s.LOCK:
            p,a,proc=records(aid)
            if any(j['status'] in ['queued','running'] and (j.get('action') in [aid,proc['id']] or aid in j.get('quality_actions',[])) for j in s.STATE['jobs']):
                raise s.HTTPException(409,'请等待当前任务完成后改名')
            a['name']=proc['name']=name;s.save()
            if not proc.get('exports'):return {'name':name}
            old=s.json.loads(s.json.dumps(proc['exports'][-1]));j=s.new_job('rename',p['id'],proc['id'])
            def work():
                with s.PROCESS_LOCK:
                    dest=s.DATA/p['id']/j['id'];dest.mkdir(parents=True)
                    for folder in ['source_frames','color_original_frames']:
                        source=s.path(old['base'])/folder
                        if source.exists():s.shutil.copytree(source,dest/folder)
                    meta=s.pack_frames(load_frames(old),dest,{**old['meta']['settings'],'name':name,
                        'playback_fps':old['meta']['fps'],'pingpong':False},
                        extra={**geometry_extra(old),'source_frames_available':(dest/'source_frames').exists(),
                               'color_original_available':(dest/'color_original_frames').exists()},apply_color=False)
                    ex={'id':j['id'],'base':s.url(dest),'meta':meta,'created':s.time.time(),'source_video':old.get('source_video') or a.get('video')}
                    with s.LOCK:proc['exports'].append(ex);s.save()
            s.execute(j,work);return j

    @app.post('/api/studio/projects/{pid}/quality-preview')
    def preview(pid:str,body:dict):
        mode=body.get('mode');items=body.get('items',[])
        if mode not in ['continuity','alignment']:raise s.HTTPException(400,'请选择连贯性或位置对齐')
        if not isinstance(items,list) or not 1<=len(items)<=30:raise s.HTTPException(400,'请选择1–30个动作')
        if mode=='alignment' and len(items)<2:raise s.HTTPException(400,'对齐至少需要两个动作')
        ids=[item.get('id') for item in items if isinstance(item,dict)]
        if len(ids)!=len(items) or len(set(ids))!=len(ids):raise s.HTTPException(400,'动作选择无效或重复')
        size=body.get('size',256)
        if size not in [128,256,512,1024]:raise s.HTTPException(400,'统一尺寸无效')
        tasks=[];total_pixels=0
        with s.LOCK:
            p=s.project(pid)
            for item in items:
                pr,a,proc=records(item['id'])
                if pr['id']!=pid:raise s.HTTPException(400,'只能处理同一只猫的动作')
                if any(j['status'] in ['queued','running'] and (j.get('action') in [a['id'],proc['id']] or a['id'] in j.get('quality_actions',[])) for j in s.STATE['jobs']):
                    raise s.HTTPException(409,'所选动作正在处理，请等待完成')
                ex=proc.get('exports',[])[-1] if proc.get('exports') else None
                if not ex:raise s.HTTPException(400,'请先完成基础透明处理')
                index=item.get('anchor',0)
                if type(index)!=int or not 0<=index<ex['meta']['frame_count']:raise s.HTTPException(400,'基准帧超出范围')
                total_pixels+=(ex['meta']['frame_width']**2+size**2)*ex['meta']['frame_count']
                if mode=='continuity' and not a.get('video'):raise s.HTTPException(400,'连贯性优化需要原视频')
                tasks.append(s.json.loads(s.json.dumps({'id':a['id'],'processor':proc['id'],'name':a['name'],
                    'old':ex,'video':a.get('video'),'options':proc['options'],'anchor':index})))
            if mode=='alignment' and total_pixels*8>512*1024*1024:raise s.HTTPException(400,'素材过大，请减少动作数量或先降低尺寸')
            j=s.new_job('quality-preview',pid,quality_actions=ids,quality_mode=mode)
            def work():
                candidates=[]
                with s.PROCESS_LOCK:
                    if mode=='alignment':
                        clips=[load_frames(t['old']) for t in tasks]
                        aligned,report=align_clips(clips,[t['anchor'] for t in tasks],size,bool(body.get('normalize')))
                    for at,t in enumerate(tasks):
                        s.update_job(j,message=f'本地算法：{at+1}/{len(tasks)} · '+t['name'])
                        dest=s.DATA/pid/j['id']/t['id'];opts={**t['options'],'name':t['name'],'pingpong':False}
                        if mode=='continuity':
                            opts.update(continuity_mode='loop' if body.get('loop') else 'sequence',target_frame_count=None,playback_fps=None,excluded=[],loop=t['old']['meta']['loop'])
                            if body.get('walk_five'):
                                opts.update(continuity_mode='walk5',start=0,duration=4,target_frame_count=5,columns=5)
                            meta=s.process_video(s.path(t['video']),dest,opts)
                            meta['continuity_report']['previous_export']=continuity_report(load_frames(t['old']))
                            # Repack only metadata and containers; no second color correction.
                            extra={k:v for k,v in meta.items() if k not in ['settings','frames','warnings','name','fps','duration','frame_count','columns','loop','frame_width','frame_height']}
                            frames=[Image.open(dest/'frames'/f'{i:03}.png').convert('RGBA') for i in range(meta['frame_count'])]
                            extra['continuity_report']['after']=continuity_report(frames)
                            meta=s.pack_frames(frames,dest,meta['settings'],meta['warnings'],extra=extra,apply_color=False)
                            video=t['video']
                        else:
                            opts.update(size=size,playback_fps=t['old']['meta']['fps'],loop=t['old']['meta']['loop'])
                            extra={**geometry_extra(t['old']),'source_frames_available':False,'color_original_available':False,
                                   'alignment_report':report,'pivot':report['origin']}
                            meta=s.pack_frames(aligned[at],dest,opts,extra=extra,apply_color=False)
                            video=t['old'].get('source_video') or t['video']
                        ex={'id':s.uid(),'base':s.url(dest),'meta':meta,'created':s.time.time(),'source_video':video}
                        candidates.append({'action':t['id'],'processor':t['processor'],'name':t['name'],'before':t['old'],'after':ex})
                s.update_job(j,candidates=candidates,message='对照预览完成，等待应用')
            s.execute(j,work);return j

    @app.post('/api/studio/projects/{pid}/quality-apply')
    def apply(pid:str,body:dict):
        with s.LOCK:
            j=next((j for j in s.STATE['jobs'] if j['id']==body.get('job') and j['project']==pid and j['kind']=='quality-preview'),None)
            if not j or j['status']!='done' or not j.get('candidates'):raise s.HTTPException(400,'预览尚未完成')
            if j.get('applied'):return {'applied':True}
            targets=[]
            for c in j['candidates']:
                _,a,proc=records(c['action'])
                if not proc.get('exports') or proc['exports'][-1]['id']!=c['before']['id'] or a['name']!=c['name']:
                    raise s.HTTPException(409,'动作结果已变化，请重新生成预览')
                if any(x['status'] in ['running','queued'] and (x.get('action') in [a['id'],proc['id']] or a['id'] in x.get('quality_actions',[])) for x in s.STATE['jobs']):
                    raise s.HTTPException(409,'动作仍在处理中')
                targets.append((proc,c['after']))
            for proc,ex in targets:
                proc['exports'].append(ex)
                # Alignment is a versioned export transform, not a new per-video crop recipe.
                if j['quality_mode']=='continuity':proc['options'].update(ex['meta']['settings'])
            j['applied']=True;s.save();return {'applied':True,'count':len(targets)}
