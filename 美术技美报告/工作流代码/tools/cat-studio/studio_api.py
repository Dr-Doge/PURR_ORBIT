"""Action-centric adapter over the existing rendering pipeline."""
def install(s):
    app = s.app
    def records(aid):
        p, a = s.action(aid)
        graph = s.canvas_graph(p)
        edge = next((e for e in graph['edges'] if e['from']=='action-'+aid and e['to'].startswith('process-')), None)
        proc = next((x for x in p['actions'] if edge and x['id']==edge['to'][8:]), a)
        return p, a, proc

    from studio_quality_api import install as install_quality
    install_quality(s,records)

    def set_reference(p,a,node):
        allowed={'reference'}|{'image-'+im['id'] for im in p.get('images',[])}
        if node not in allowed: raise s.HTTPException(400,'请选择这只猫自己的参考图')
        g=s.canvas_graph(p)
        g['edges']=[e for e in g['edges'] if e['to']!='action-'+a['id']]
        g['edges'].append({'from':node,'to':'action-'+a['id']})
        p['graph']=g

    @app.post('/api/studio/projects/{pid}/actions')
    def create_action(pid:str,body:dict):
        with s.LOCK:
            p=s.project(pid)
            node=body.get('reference_node','reference')
            if node not in {'reference'}|{'image-'+im['id'] for im in p.get('images',[])}:
                raise s.HTTPException(400,'无效参考图')
            a=s.add_action(pid,body);set_reference(p,a,node);s.save();return a

    @app.post('/api/studio/projects/{pid}/reuse-actions')
    def reuse_actions(pid:str,body:dict):
        items=body.get('items')
        if not isinstance(items,list) or not 1<=len(items)<=100:raise s.HTTPException(400,'请选择1–100个动作')
        with s.LOCK:
            target=s.project(pid);source=s.project(str(body.get('source_project','')))
            if source['id']==pid:raise s.HTTPException(400,'请选择其他项目作为动作来源')
            plan=[];seen=set()
            for item in items:
                if not isinstance(item,dict):raise s.HTTPException(400,'动作设置无效')
                aid=item.get('id');pr,a,proc=records(aid)
                if pr['id']!=source['id'] or a.get('studio_archived') or 'action-'+aid not in s.canvas_graph(pr)['nodes'] or aid in seen:
                    raise s.HTTPException(400,'来源动作无效或重复')
                seen.add(aid);node=item.get('reference_node')
                image=target.get('reference') if node=='reference' else next((im.get('source') for im in target.get('images',[]) if node=='image-'+im['id']),None)
                if not image:raise s.HTTPException(400,'请为每个动作选择新项目中已上传的参考图')
                count=item.get('frame_count');name=str(item.get('name',a['name'])).strip();prompt=str(item.get('prompt',a['prompt'])).strip()
                if type(count)!=int or not 1<=count<=120 or not name or len(name)>60 or not prompt or len(prompt)>20000:
                    raise s.HTTPException(400,'请检查名称、动作描述与帧数（1–120）')
                options={**a['options'],**proc['options'],'target_frame_count':count,'continuity_mode':None,'excluded':[]}
                plan.append((a,name,prompt,node,options))
            results=[]
            for original,name,prompt,node,options in plan:
                previous=next((a for a in target['actions'] if a.get('reused_from')=={'project':source['id'],'action':original['id']} and not a.get('studio_archived') and 'action-'+a['id'] in s.canvas_graph(target)['nodes']),None)
                if previous:results.append({'id':previous['id'],'status':'skipped'});continue
                a=s.add_action(pid,{'name':name,'prompt':prompt});a['options']=s.json.loads(s.json.dumps(options))
                a['reused_from']={'project':source['id'],'action':original['id']}
                set_reference(target,a,node);results.append({'id':a['id'],'status':'created'})
            s.save();return {'results':results}

    @app.post('/api/studio/batch')
    def batch(body:dict):
        items=body.get('items',[])
        if not items or len(items)>100: raise s.HTTPException(400,'请选择1–100个动作')
        results=[]
        with s.LOCK:
            for aid in dict.fromkeys(items):
                try:
                    p,a,proc=records(aid)
                    if a.get('studio_archived'): raise s.HTTPException(400,'动作已收起，请先恢复')
                    if 'action-'+aid not in s.canvas_graph(p)['nodes']: raise s.HTTPException(400,'动作已移除')
                    if any((j.get('action') in {aid,proc['id']} or aid in j.get('quality_actions',[])) and j['status'] in ['queued','running'] for j in s.STATE['jobs']):
                        results.append({'id':aid,'status':'skipped','message':'已在队列中'});continue
                    force=bool(body.get('regenerate'))
                    if proc.get('exports') and not force:
                        results.append({'id':aid,'status':'skipped','message':'已有完成结果'});continue
                    if not a.get('video') or force:
                        if not body.get('paid_confirmed'): raise s.HTTPException(400,'模型生成需要确认费用')
                        if not s.key('ARK_API_KEY'): raise s.HTTPException(400,'请先配置 ARK API Key')
                        if not s.video_image(p,aid): raise s.HTTPException(400,'请先上传参考图')
                        if not a['prompt'].strip(): raise s.HTTPException(400,'请填写动作描述')
                        s.prepare_video_pipeline(aid)
                        j=s.video_job(aid,{'auto_process':True})
                    else:
                        prepared=s.prepare_video_pipeline(aid)
                        j=s.process_job(prepared['process'][8:])
                    results.append({'id':aid,'status':'submitted','job':j['id']})
                except Exception as exc:
                    results.append({'id':aid,'status':'failed','message':str(getattr(exc,'detail',exc))})
        return {'results':results}

    @app.post('/api/studio/actions/{aid}/adjust')
    def adjust(aid:str,body:dict):
        with s.LOCK:
            p,a,proc=records(aid)
            if any((j.get('action') in {aid,proc['id']} or aid in j.get('quality_actions',[])) and j['status'] in ['queued','running'] for j in s.STATE['jobs']):
                raise s.HTTPException(409,'请等待当前任务完成')
            if 'archived' in body:
                a['studio_archived']=bool(body['archived']);s.save();return a
            if 'reference_node' in body: set_reference(p,a,body['reference_node'])
            if body.get('restore'):
                ex=next((e for e in proc['exports'] if e['id']==body['restore']),None)
                if not ex: raise s.HTTPException(404,'版本不存在')
                restored=s.json.loads(s.json.dumps(ex));restored['id']=s.uid();restored['created']=s.time.time()
                proc['exports'].append(restored);proc['options'].update(ex['meta']['settings']);s.save()
                return {'restored':True}
            s.edit_action(aid,{k:body[k] for k in ['name','prompt'] if k in body})
            if 'name' in body:
                proc['name']=a['name'];s.save()
            if body.get('process'):
                prepared=s.prepare_video_pipeline(aid)
                procid=prepared['process'][8:]
                s.edit_action(procid,{'options':body.get('options',{})})
                return s.process_job(procid)
            return a
