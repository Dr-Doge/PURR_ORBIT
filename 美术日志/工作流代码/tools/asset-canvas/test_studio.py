import base64, io, json, os, tempfile, time, unittest, zipfile
from pathlib import Path
from unittest.mock import patch
import numpy as np
from PIL import Image
import imageio_ffmpeg
import httpx

# Tests are isolated from the real workspace and never call paid providers.
TEMP=tempfile.TemporaryDirectory(prefix='jominframe-test-')
os.environ['ASSET_CANVAS_DATA']=TEMP.name
import server
from fastapi.testclient import TestClient
from processor import process_video, remove_green, process_sheet

class StudioTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client=TestClient(server.app);cls.client.__enter__()
        cls.headers={'X-Canvas-Request':'1'}
        cls.source=Path(TEMP.name)/'synthetic.mp4'
        writer=imageio_ffmpeg.write_frames(str(cls.source),(128,128),fps=10,codec='libx264',pix_fmt_in='rgb24',output_params=['-crf','10'])
        writer.send(None)
        for i in range(20):
            f=np.full((128,128,3),(0,255,0),np.uint8)
            y=70-round(20*np.sin(np.pi*i/19));f[y:y+20,45:75]=(230,145,60);writer.send(f)
        writer.close()
    @classmethod
    def tearDownClass(cls):
        cls.client.__exit__(None,None,None)
        server.POOL.shutdown(wait=True)
        server.DB.close()
    def make_action(self):
        p=self.client.post('/api/projects',json={'name':'测试猫'},headers=self.headers).json()
        a=self.client.post('/api/projects/'+p['id']+'/actions',json={'name':'idle'},headers=self.headers).json()
        return p,a
    def test_edit_total_frames_persists_and_controls_export(self):
        _,a=self.make_action()
        url='/api/actions/'+a['id']
        for count in [7,15]:
            r=self.client.patch(url,json={'options':{'target_frame_count':count,'duration':1,'fps':10}},headers=self.headers)
            self.assertEqual(r.status_code,200)
            opts=r.json()['options']
            self.assertEqual(opts['target_frame_count'],count)
            out=Path(TEMP.name)/('total-'+str(count))
            result=process_video(self.source,out,opts)
            self.assertEqual(result['frame_count'],count)
        for invalid in [0,121,2.5,'12',True]:
            r=self.client.patch(url,json={'options':{'target_frame_count':invalid}},headers=self.headers)
            self.assertEqual(r.status_code,400)

    def test_pixel_preview_apply_restore_and_stale(self):
        from processor import pack_frames
        p,a=self.make_action()
        record=next(x for x in server.project(p['id'])['actions'] if x['id']==a['id'])
        dest=server.DATA/p['id']/'original-pixel-test'
        frames=[Image.new('RGBA',(128,128),(150+i,100,60,255)) for i in range(3)]
        meta=pack_frames(frames,dest,{'fps':5,'columns':3,'loop':True,'pingpong':False},apply_color=False)
        original={'id':'pixel-original','base':server.url(dest),'meta':meta,'created':0}
        record['exports'].append(original)
        route='/api/projects/'+p['id']+'/pixel-stability';payload={'source':'process-'+a['id']}
        response=self.client.post(route,json={**payload,'size':128,'cell':2},headers=self.headers)
        self.assertEqual(response.status_code,200,response.text);jid=response.json()['id']
        for _ in range(300):
            job=next(j for j in server.STATE['jobs'] if j['id']==jid)
            if job['status'] not in ('running','queued'):break
            time.sleep(.05)
        self.assertEqual(job['status'],'done',job)
        self.assertEqual(len(record['exports']),1)
        self.assertEqual(job['candidate']['meta']['duration'],meta['duration'])
        self.assertEqual(job['candidate']['meta']['kept_source_indices'],[0,1,2])
        r=self.client.post(route,json={**payload,'operation':'apply','job':jid},headers=self.headers)
        self.assertEqual(r.status_code,200,r.text);self.assertEqual(len(record['exports']),2)
        r=self.client.post(route,json={**payload,'operation':'apply','job':jid},headers=self.headers)
        self.assertEqual(r.status_code,409)
        r=self.client.post(route,json={**payload,'operation':'restore'},headers=self.headers)
        self.assertEqual(r.status_code,200,r.text);self.assertEqual(record['exports'][-1]['base'],original['base'])
    def test_extraction_does_not_apply_reverted_pixel_stability(self):
        p,a=self.make_action()
        opts={**server.DEFAULTS,'duration':.4,'fps':10,'name':'stable'}
        job=server.new_job('process',p['id'],a['id'],video=server.url(self.source),options=opts)
        server.process_action(job);server.update_job(job,status='done')
        record=next(x for x in server.project(p['id'])['actions'] if x['id']==a['id'])
        ex=record['exports'][-1]
        self.assertEqual(ex['meta']['frame_width'],256)
        self.assertNotIn('pixel_stability_report',ex['meta'])
        self.assertEqual(ex['meta']['frame_count'],4)
        self.assertEqual(len(record['exports']),1)
    def test_calico_nine_demo_is_complete_and_reusable(self):
        r=self.client.post('/api/demo',headers=self.headers,json={'kind':'calico-nine'})
        self.assertEqual(r.status_code,200,r.text)
        p=r.json();self.assertEqual(len(p['images']),3);self.assertEqual(len(p['actions']),9)
        self.assertEqual(self.client.post('/api/demo',headers=self.headers,json={'kind':'calico-nine'}).json()['id'],p['id'])
        for a in p['actions']:
            self.assertTrue(server.path(a['video']).is_file())
            ex=a['exports'][-1];self.assertTrue((server.path(ex['base'])/'spritesheet.png').is_file())
            total=round(a['options']['duration']*a['options']['fps'])
            removed={i for i in a['options'].get('excluded',[]) if 0<=i<total}
            self.assertEqual(ex['meta']['frame_count'],total-len(removed))
            self.assertIn({'from':'action-'+a['id'],'to':'process-'+a['id']},p['graph']['edges'])
            self.assertIn({'from':'process-'+a['id'],'to':'export-'+a['id']},p['graph']['edges'])

    def test_origin_and_host_boundary(self):
        self.assertEqual(self.client.post('/api/projects',json={}).status_code,403)
        self.assertEqual(self.client.post('/api/projects',json={},headers={**self.headers,'Origin':'https://evil.test'}).status_code,403)
        self.assertEqual(self.client.get('/api/state',headers={'Host':'evil.test'}).status_code,403)
        self.assertEqual(self.client.get('/media/studio.sqlite').status_code,404)

    def test_multiple_video_prompts_create_independent_connected_outputs(self):
        p,a=self.make_action();route='/api/actions/'+a['id']
        spec={'prompt':'walk','extra_prompts':['idle','jump'],'video_model':'test-model'}
        self.assertEqual(self.client.patch(route,json=spec,headers=self.headers).status_code,200)
        before=len(server.STATE['jobs'])
        r=self.client.post(route+'/expand-prompts',headers=self.headers)
        self.assertEqual(r.status_code,200,r.text)
        ids=r.json()['actions'];self.assertEqual(len(ids),3);self.assertEqual(ids[0],a['id'])
        pr=server.project(p['id']);g=server.canvas_graph(pr)
        for target,prompt in zip(ids[1:],['idle','jump']):
            rec=next(x for x in pr['actions'] if x['id']==target)
            self.assertEqual(rec['prompt'],prompt);self.assertEqual(rec['video_model'],'test-model')
            self.assertEqual(rec['options'],a['options']);self.assertIsNone(rec['video'])
            self.assertIn({'from':'reference','to':'action-'+target},g['edges'])
            self.assertNotIn('process-'+target,g['nodes']);self.assertNotIn('extra_prompts',rec)
        self.assertEqual(len(server.STATE['jobs']),before)
        self.client.patch(route,json={'extra_prompts':['']},headers=self.headers)
        count=len(pr['actions'])
        self.assertEqual(self.client.post(route+'/expand-prompts',headers=self.headers).status_code,400)
        self.assertEqual(len(pr['actions']),count)
        for invalid in ['text',[1],['a']*10]:
            self.assertEqual(self.client.patch(route,json={'extra_prompts':invalid},headers=self.headers).status_code,400)
    def test_keys_saved_separately_and_survive_memory_reset(self):
        with patch.dict(server.KEYS,clear=True):
            secret='dummy-test-secret'
            response=self.client.post('/api/settings',json={'openai_key':secret},headers=self.headers)
            self.assertNotIn(secret,response.text)
            self.assertNotIn(secret,server.DB.execute('SELECT value FROM store').fetchone()[0])
            server.KEYS.clear()
            with patch.dict(os.environ,{'OPENAI_API_KEY':''}):
                self.assertEqual(server.read_saved_keys()['OPENAI_API_KEY'],secret)
            self.client.post('/api/settings',json={'openai_key':'   '},headers=self.headers)
            self.assertEqual(server.read_saved_keys()['OPENAI_API_KEY'],secret)
            self.assertEqual(self.client.get('/media/.credentials').status_code,404)
    def test_public_keys_are_isolated_and_captured_by_workers(self):
        import threading
        with patch.dict(os.environ,{'ASSET_CANVAS_PUBLIC':'1','OPENAI_API_KEY':'host-secret','ARK_API_KEY':'host-ark'}):
            alice=TestClient(server.app);bob=TestClient(server.app)
            self.assertFalse(alice.get('/api/state').json()['connection']['openai'])
            self.assertFalse(bob.get('/api/state').json()['connection']['ark'])
            before=server.SECRET_FILE.read_bytes() if server.SECRET_FILE.exists() else None
            ar=alice.post('/api/settings',headers=self.headers,json={'openai_key':'alice-key','ark_key':'alice-ark','image_model':'alice-model'})
            self.assertEqual(ar.status_code,200)
            self.assertTrue(ar.json()['connection']['openai'])
            self.assertNotIn('alice-key',ar.text)
            self.assertFalse(bob.get('/api/state').json()['connection']['openai'])
            bob.post('/api/settings',headers=self.headers,json={'openai_key':'bob-key','image_model':'bob-model'})
            self.assertEqual(alice.get('/api/state').json()['settings']['image_model'],'alice-model')
            self.assertEqual(bob.get('/api/state').json()['settings']['image_model'],'bob-model')
            if before is not None:self.assertEqual(server.SECRET_FILE.read_bytes(),before)
            self.assertNotIn('alice-key',server.DB.execute('SELECT value FROM store').fetchone()[0])
            gate=threading.Event();done=threading.Event();seen=[]
            sid=alice.cookies.get(server.SESSION_COOKIE)
            token=server.SESSION_KEYS.set(dict(server.SESSIONS[sid]['keys']))
            try:
                job={'status':'queued'}
                def work():
                    gate.wait(5);seen.append(server.key('OPENAI_API_KEY'));done.set()
                server.start_context_thread(server.execute,job,work).join(5)
            finally:server.SESSION_KEYS.reset(token)
            alice.post('/api/settings',headers=self.headers,json={'openai_key':'alice-new-key'})
            gate.set();self.assertTrue(done.wait(5))
            self.assertEqual(seen,['alice-key'])
            alice.post('/api/settings',headers=self.headers,json={'clear_keys':True})
            self.assertFalse(alice.get('/api/state').json()['connection']['openai'])
            self.assertTrue(bob.get('/api/state').json()['connection']['openai'])
            server.SESSIONS.clear()
            self.assertFalse(bob.get('/api/state').json()['connection']['openai'])

    def test_color_spike_repair_preserves_motion_alpha_and_palette(self):
        from processor import stabilize_colors,pack_frames
        frames=[];expected=[]
        for i in range(10):
            a=np.zeros((64,64,4),np.uint8);x=4+i*2
            a[15:45,x:x+20]=(140,100,60,255)
            a[15:25,x:x+20]=(180,140,100,255)
            expected.append(a.copy())
            if i==4:a[a[:,:,3]>0,:3]+=30
            frames.append(Image.fromarray(a))
        fixed,report=stabilize_colors(frames)
        self.assertEqual(report['corrected'],[4])
        for i,im in enumerate(fixed):np.testing.assert_array_equal(np.array(im),expected[i])
        detected,report=stabilize_colors(frames,'detect')
        self.assertEqual(report['detected'],[4]);self.assertFalse(report['corrected'])
        np.testing.assert_array_equal(np.array(detected[4]),np.array(frames[4]))
        # Deliberately switching between two equally common palettes is ambiguous.
        altered=[Image.fromarray(np.where(a[:,:,3:4]>0,np.minimum(a.astype(int)+np.array([30,30,30,0]),255),a).astype(np.uint8)) if i>=5 else Image.fromarray(a) for i,a in enumerate(expected)]
        _,report=stabilize_colors(altered)
        self.assertFalse(report['corrected'])
        output=Path(TEMP.name)/'color-spike'
        meta=pack_frames(frames,output,{'fps':10,'columns':5})
        self.assertEqual(meta['frame_count'],10);self.assertEqual(meta['duration'],1)
        with Image.open(output/'color_original_frames/004.png') as im:np.testing.assert_array_equal(np.array(im),np.array(frames[4]))
        with Image.open(output/'frames/004.png') as im:np.testing.assert_array_equal(np.array(im),expected[4])

    def test_luminance_small_flash_and_exposure_change(self):
        from processor import stabilize_colors
        frames=[];baseline=[]
        for i in range(12):
            ar=np.zeros((64,64,4),np.uint8)
            ar[8:35,8:48]=(100,80,60,255);ar[35:55,8:48]=(180,160,140,255)
            baseline.append(ar.copy())
            mask=ar[:,:,3]>0
            if i==0:ar[mask,:3]+=8
            if i in [5,6]:ar[mask,:3]=np.rint(ar[mask,:3].astype(float)*1.15).astype(np.uint8)
            frames.append(Image.fromarray(ar))
        fixed,report=stabilize_colors(frames)
        self.assertEqual(report['algorithm'],'luminance-v3')
        self.assertEqual(report['corrected'],[0,5,6])
        for i in [0,5,6]:
            before=np.abs(np.array(frames[i]).astype(float)-baseline[i]).mean()
            after=np.abs(np.array(fixed[i]).astype(float)-baseline[i]).mean()
            self.assertLess(after,before*.15)
            np.testing.assert_array_equal(np.array(fixed[i])[:,:,3],baseline[i][:,:,3])
        again,_=stabilize_colors(frames)
        for a,b in zip(again,fixed):np.testing.assert_array_equal(np.array(a),np.array(b))

    def test_local_flash_preserves_healthy_dark_coat(self):
        from processor import stabilize_colors
        base=np.zeros((64,64,4),np.uint8)
        base[8:56,8:56]=(190,185,180,255)
        base[8:56,8:24]=(60,55,50,255)
        flash=base.copy();flash[8:56,24:56,:3]+=20
        frames=[Image.fromarray(flash)]+[Image.fromarray(base)]*7
        fixed,report=stabilize_colors(frames)
        self.assertEqual(report['corrected'],[0])
        np.testing.assert_array_equal(np.array(fixed[0]),base)
        self.assertEqual(len(fixed),len(frames))

    def test_palette_area_change_is_not_exposure(self):
        from processor import stabilize_colors
        frames=[]
        for i in range(8):
            ar=np.zeros((64,64,4),np.uint8)
            ar[8:56,8:56]=(190,185,180,255)
            ar[8:56,8:(38 if i==0 else 26)]=(60,55,50,255)
            frames.append(Image.fromarray(ar))
        fixed,report=stabilize_colors(frames)
        self.assertFalse(report['corrected'])
        for before,after in zip(frames,fixed):np.testing.assert_array_equal(before,after)

    def test_despill_preserves_opaque_interior(self):
        from processor import remove_green
        rgb=np.zeros((40,40,3),np.uint8);rgb[:]=(0,255,0)
        rgb[6:34,6:34]=(100,108,100)
        plain=remove_green(rgb,25,0,False);clean=remove_green(rgb,25,0,True)
        np.testing.assert_array_equal(clean[9:31,9:31],plain[9:31,9:31])
        np.testing.assert_array_equal(clean[:,:,3],plain[:,:,3])
        self.assertEqual(int(clean[6,20,1]),100)

    def test_color_quality_restore_and_selected_batch_export(self):
        from processor import pack_frames
        p,a=self.make_action();record=server.action(a['id'])[1]
        frames=[]
        for i in range(6):
            ar=np.zeros((64,64,4),np.uint8);ar[12:45,12:40]=(160+(30 if i==2 else 0),100+(30 if i==2 else 0),60+(30 if i==2 else 0),255)
            frames.append(Image.fromarray(ar))
        folder=server.DATA/p['id']/'baseline'
        meta=pack_frames(frames,folder,{'fps':10,'columns':3,'color_mode':'off'})
        record['exports']=[{'id':'baseline','base':server.url(folder),'meta':meta}];server.save()
        def wait(job):
            for _ in range(200):
                j=next(j for j in server.STATE['jobs'] if j['id']==job['id'])
                if j['status'] in ['done','failed']:break
                time.sleep(.02)
            self.assertEqual(j['status'],'done',j.get('message'))
        route='/api/projects/'+p['id']+'/color-quality'
        response=self.client.post(route,headers=self.headers,json={'source':'process-'+a['id'],'mode':'repair'})
        self.assertEqual(response.status_code,200,response.text);wait(response.json())
        self.assertEqual(record['exports'][-1]['meta']['color_report']['corrected'],[2])
        self.assertEqual(record['exports'][-1]['meta']['frame_count'],6)
        wait(self.client.post(route,headers=self.headers,json={'source':'process-'+a['id'],'quick':True}).json())
        self.assertLess(record['exports'][-1]['meta']['color_report']['threshold'],6)
        wait(self.client.post(route,headers=self.headers,json={'source':'process-'+a['id'],'mode':'off'}).json())
        with Image.open(server.path(record['exports'][-1]['base']+'/frames/002.png')) as im:np.testing.assert_array_equal(np.array(im),np.array(frames[2]))
        project=server.project(p['id']);project['batches']=[{'id':'chosen','outputs':[a['id']]}]
        route='/api/projects/'+p['id']+'/batches/chosen/export-selected'
        response=self.client.post(route,headers=self.headers,json={'actions':[a['id']]})
        self.assertEqual(response.status_code,200,response.text)
        with zipfile.ZipFile(server.path(response.json()['url'])) as z:
            manifest=json.loads(z.read('manifest.json'));self.assertEqual(len(manifest),1)
            self.assertEqual(manifest[0]['id'],a['id']);self.assertIn(manifest[0]['file'],z.namelist())
        self.assertEqual(self.client.post(route,headers=self.headers,json={'actions':['other-project']}).status_code,400)
        self.assertEqual(self.client.post(route,headers=self.headers,json={'actions':[a['id']],'exports':{a['id']:'old-version'}}).status_code,409)

    def test_empty_green_and_motion_export(self):
        a=np.full((10,10,3),(0,255,0),np.uint8)
        self.assertEqual(remove_green(a)[:,:,3].max(),0)
        target=Path(TEMP.name)/'export';m=process_video(self.source,target,{'fps':10,'duration':2,'size':128,'name':'idle'})
        self.assertEqual(m['frame_count'],20)
        frames=[np.array(Image.open(f)) for f in sorted((target/'frames').glob('*.png'))]
        self.assertEqual(frames[0].shape,(128,128,4))
        self.assertEqual(frames[0][0,0,3],0)
        tops=[np.where(a[:,:,3]>0)[0].min() for a in frames]
        self.assertGreater(max(tops)-min(tops),15,'Intentional vertical motion must remain')
        with zipfile.ZipFile(target/'spritesheet.zip') as z:
            self.assertIn('sprite_frames.tres',z.namelist());self.assertIn('frames/019.png',z.namelist())
        text=(target/'sprite_frames.tres').read_text();self.assertIn('"speed": 10.0',text)
    def test_exclusion_and_pingpong(self):
        m=process_video(self.source,Path(TEMP.name)/'filtered',{'fps':10,'duration':1,'size':64,'excluded':[0,9],'pingpong':True})
        self.assertEqual(m['frame_count'],14)
        self.assertEqual(m['kept_source_indices'],list(range(1,9)))
    def test_upload_process_and_duplicate_guard(self):
        p,a=self.make_action()
        response=self.client.post('/api/actions/'+a['id']+'/video',headers=self.headers,files={'file':('clip.mp4',self.source.read_bytes(),'video/mp4')})
        self.assertEqual(response.status_code,200)
        endpoint='/api/actions/'+a['id']+'/process'
        with patch.object(server.POOL,'submit'):
            r=self.client.post(endpoint,headers=self.headers);self.assertEqual(r.status_code,200)
            self.assertEqual(self.client.post(endpoint,headers=self.headers).status_code,409)
        j=next(j for j in server.STATE['jobs'] if j['id']==r.json()['id'])
        server.process_action(j)
        ex=server.action(a['id'])[1]['exports'][-1]
        self.assertEqual(self.client.get(ex['base']+'/spritesheet.zip').status_code,200)
    def test_seedance_submission_once_resume_only_polls(self):
        p,a=self.make_action();dest=Path(TEMP.name)/p['id'];dest.mkdir(exist_ok=True)
        Image.new('RGBA',(64,64),(20,50,80,255)).save(dest/'ref.png');p['reference']=server.url(dest/'ref.png')
        j=server.new_job('video',p['id'],a['id'],prompt='test',reference=p['reference'],model='test')
        with patch.object(server,'bridge',side_effect=[{'id':'task-test'},{'status':'failed','error':'test rejection'}]) as mock:
            with self.assertRaises(ValueError):server.generate_video(j)
            self.assertEqual(mock.call_count,2);self.assertEqual(j['task_id'],'task-test')
            self.assertEqual(mock.call_args_list[0].kwargs['Resolution'],'480p')
        with patch.object(server,'bridge',return_value={'status':'failed'}) as mock:
            with self.assertRaises(ValueError):server.generate_video(j)
            self.assertEqual(mock.call_args.args[0],'status')
    def test_video_resolution_saved_and_sent(self):
        p,a=self.make_action()
        self.assertEqual(a['options']['video_resolution'],'480p')
        route='/api/actions/'+a['id']
        self.assertEqual(self.client.patch(route,headers=self.headers,json={'options':{'video_resolution':'256p'}}).status_code,400)
        for resolution in ['480p','720p','1080p']:
            updated=self.client.patch(route,headers=self.headers,json={'options':{'video_resolution':resolution}}).json()
            dest=Path(TEMP.name)/p['id'];dest.mkdir(exist_ok=True)
            Image.new('RGB',(64,64)).save(dest/'reference-test.png')
            j=server.new_job('video',p['id'],a['id'],prompt='test',reference=server.url(dest/'reference-test.png'),model='test',options=updated['options'])
            with patch.object(server,'bridge',side_effect=[{'id':'mock-task'},{'status':'failed'}]) as bridge:
                with self.assertRaises(ValueError):server.generate_video(j)
                self.assertEqual(bridge.call_args_list[0].kwargs['Resolution'],resolution)
            server.update_job(j,status='failed')
    def test_sprite_sheet_import_and_generation_adapter(self):
        p,a=self.make_action();im=Image.new('RGBA',(128,64));im.paste((250,90,30,255),(10,10,30,40));im.paste((250,90,30,255),(80,20,100,50));buf=io.BytesIO();im.save(buf,format='PNG')
        spec={'name':'walk_new','columns':2,'rows':1,'count':2,'fps':10,'size':64,'prompt':'变成蓝色猫'}
        res=self.client.post('/api/projects/'+p['id']+'/sheets',headers=self.headers,data={'spec':json.dumps(spec)},files={'file':('sheet.png',buf.getvalue(),'image/png')})
        self.assertEqual(res.status_code,200,res.text);s=res.json()
        self.assertEqual(s['original']['meta']['frame_count'],2)
        j=server.new_job('sheet',p['id'],s['id'],source=s['source'],reference=None,prompt=spec['prompt'],options=s['options'],model='test')
        mock_response=httpx.Response(200,json={'data':[{'b64_json':base64.b64encode(buf.getvalue()).decode()}]})
        with patch.object(server.httpx.Client,'post',return_value=mock_response) as post:
            server.generate_sheet(j)
            self.assertEqual(post.call_count,1)
            self.assertEqual(post.call_args.kwargs['files'][0][0],'image[]')
        self.assertTrue(server.sheet(s['id'])[1]['exports'][-1]['generated'])
        bad={**spec,'count':5}
        self.assertEqual(self.client.post('/api/projects/'+p['id']+'/sheets',headers=self.headers,data={'spec':json.dumps(bad)},files={'file':('sheet.png',buf.getvalue(),'image/png')}).status_code,400)

    def test_independent_image_nodes_green_and_video_routing(self):
        p,a=self.make_action();base='/api/projects/'+p['id']
        im=self.client.post(base+'/images',headers=self.headers,json={'name':'机器人'}).json();route=base+'/images/'+im['id']
        png=Image.new('RGBA',(32,32));png.paste((255,80,40,255),(8,8,24,24));buf=io.BytesIO();png.save(buf,format='PNG')
        uploaded=self.client.post(route+'/upload',headers=self.headers,files={'file':('robot.png',buf.getvalue(),'image/png')})
        self.assertEqual(uploaded.status_code,200)
        self.assertIsNone(server.project(p['id'])['reference'])
        green=self.client.post(route+'/green',headers=self.headers,json={});self.assertTrue(green.json()['local'])
        with Image.open(server.path(green.json()['image']['source'])) as result:
            self.assertEqual(result.getpixel((0,0)),(0,255,0,255));self.assertEqual(result.getpixel((16,16)),(255,80,40,255))
        self.assertEqual(self.client.post(route+'/green',headers=self.headers,json={}).status_code,409)
        g={'nodes':['image-'+im['id'],'action-'+a['id']],'edges':[{'from':'image-'+im['id'],'to':'action-'+a['id']}]}
        self.assertEqual(self.client.patch(base,headers=self.headers,json={'graph':g}).status_code,200)
        with patch.dict(server.KEYS,{'ARK_API_KEY':'dummy-test'}),patch.object(server.POOL,'submit'):
            r=self.client.post('/api/actions/'+a['id']+'/generate',headers=self.headers,json={})
            # Supply a prompt; the source must be the connected independent Image.
            self.client.patch('/api/actions/'+a['id'],headers=self.headers,json={'prompt':'robot walk'})
            r=self.client.post('/api/actions/'+a['id']+'/generate',headers=self.headers,json={})
        self.assertEqual(r.status_code,200)
        self.assertEqual(r.json()['reference'],green.json()['image']['source'])
        with patch.dict(server.KEYS,{'OPENAI_API_KEY':'dummy-test'}),patch.object(server.POOL,'submit'):
            job=self.client.post(route+'/generate',headers=self.headers,json={'prompt':'a robot','background':'green'}).json()
        self.assertEqual(job['model'],'gpt-image-2');self.assertIsNone(job['reference']);self.assertEqual(job['background'],'opaque')
        mock_response=httpx.Response(200,json={'data':[{'b64_json':base64.b64encode(buf.getvalue()).decode()}]})
        with patch.object(server.httpx.Client,'post',return_value=mock_response) as post:
            server.generate_image(job)
            self.assertEqual(post.call_args.args[0],'https://api.openai.com/v1/images/generations')
        self.assertIsNone(server.project(p['id'])['reference'])
        self.assertNotEqual(server.image_item(server.project(p['id']),im['id'])['source'],green.json()['image']['source'])

    def test_spill_on_opaque_and_soft_edges(self):
        pixels=np.array([[[0,240,0],[70,90,70],[70,105,70],[230,170,50],[245,245,245]]],dtype=np.uint8)
        for softness in [0,20]:
            keyed=remove_green(pixels,25,softness,True)
            self.assertEqual(keyed[0,0,3],0)
            self.assertEqual(keyed[0,1].tolist(),[70,70,70,255])
            self.assertLessEqual(keyed[0,2,1],max(keyed[0,2,0],keyed[0,2,2]))
            self.assertEqual(keyed[0,3].tolist(),[230,170,50,255])
            self.assertEqual(keyed[0,4].tolist(),[245,245,245,255])
        gentle=remove_green(pixels,45,0,False)
        strong=remove_green(pixels,12,0,False)
        self.assertGreater(gentle[:,:,3].sum(),strong[:,:,3].sum())

    def test_twenty_fps_source_library_and_apng(self):
        target=Path(TEMP.name)/'twenty';m=process_video(self.source,target,{'fps':20,'duration':2,'size':64})
        self.assertEqual(m['frame_count'],40)
        self.assertEqual(len(list((target/'source_frames').glob('*.png'))),40)
        self.assertEqual(m['sample_times'],[i/20 for i in range(40)])
        apng=Image.open(target/'preview.png')
        # Pillow may coalesce identical adjacent frames, but every displayed image must
        # be a full frame, never pixels left behind by a previous transparent frame.
        source_arrays=[np.array(Image.open(target/'frames'/f'{i:03}.png')) for i in range(40)]
        for i in range(apng.n_frames):
            apng.seek(i);self.assertTrue(any(np.array_equal(np.array(apng.convert('RGBA')),f) for f in source_arrays))
        apng.close()
        filtered=Path(TEMP.name)/'twenty-filtered'
        n=process_video(self.source,filtered,{'fps':20,'duration':2,'size':64,'excluded':list(range(1,40,2)),'playback_fps':10})
        self.assertEqual(n['duration'],2)
        self.assertEqual(n['crop_box'],m['crop_box'])
        self.assertEqual(n['kept_source_indices'],list(range(0,40,2)))
        self.assertTrue((filtered/'source_frames/039.png').exists())

    def test_graph_routes_actual_video_and_rejects_invalid_edges(self):
        p,a=self.make_action()
        self.client.post('/api/actions/'+a['id']+'/video',headers=self.headers,files={'file':('clip.mp4',self.source.read_bytes(),'video/mp4')})
        b=self.client.post('/api/projects/'+p['id']+'/actions',headers=self.headers,json={'name':'processor','stage':'process'}).json()
        g=server.project(p['id'])['graph'];g=json.loads(json.dumps(g));g['edges'].append({'from':'action-'+a['id'],'to':'process-'+b['id']})
        r=self.client.patch('/api/projects/'+p['id'],headers=self.headers,json={'graph':g});self.assertEqual(r.status_code,200)
        with patch.object(server.POOL,'submit'):
            r=self.client.post('/api/actions/'+b['id']+'/process',headers=self.headers)
        self.assertEqual(r.status_code,200)
        self.assertEqual(r.json()['video'],server.action(a['id'])[1]['video'])
        self.assertEqual(r.json()['options']['fps'],10)
        g['edges'].append({'from':'process-'+b['id'],'to':'action-'+a['id']})
        self.assertEqual(self.client.patch('/api/projects/'+p['id'],headers=self.headers,json={'graph':g}).status_code,400)

    def test_video_node_model_selection_isolated_and_snapshotted(self):
        p,a=self.make_action()
        b=self.client.post('/api/projects/'+p['id']+'/actions',headers=self.headers,json={'name':'other'}).json()
        project=server.project(p['id']);project['reference']='/media/test.png'
        chosen='doubao-seedance-2-5-260628'
        self.assertEqual(self.client.patch('/api/actions/'+a['id'],headers=self.headers,json={'video_model':chosen,'prompt':'test'}).status_code,200)
        self.assertEqual(self.client.patch('/api/actions/'+b['id'],headers=self.headers,json={'video_model':'invalid value'}).status_code,400)
        with patch.dict(server.KEYS,{'ARK_API_KEY':'dummy-test'}),patch.object(server.POOL,'submit'):
            job=self.client.post('/api/actions/'+a['id']+'/generate',headers=self.headers,json={}).json()
        self.assertEqual(job['model'],chosen)
        self.assertNotIn('video_model',server.action(b['id'])[1])
        self.client.patch('/api/actions/'+a['id'],headers=self.headers,json={'video_model':'doubao-seedance-2-0-fast-260128'})
        self.assertEqual(job['model'],chosen,'Queued jobs retain the model chosen when submitted')

    def test_manual_video_pipeline_and_recoverable_node_deletion(self):
        p=self.client.post('/api/projects',headers=self.headers,json={'name':'graph'}).json()
        a=self.client.post('/api/projects/'+p['id']+'/actions',headers=self.headers,json={'stage':'action','name':'standalone'}).json()
        g=server.canvas_graph(server.project(p['id']))
        self.assertEqual(g['edges'],[])
        self.assertNotIn('process-'+a['id'],g['nodes'])
        self.client.patch('/api/projects/'+p['id'],headers=self.headers,json={'layout':{'action-'+a['id']:{'x':-700,'y':-900}}})
        first=self.client.post('/api/actions/'+a['id']+'/pipeline',headers=self.headers).json()
        again=self.client.post('/api/actions/'+a['id']+'/pipeline',headers=self.headers).json()
        self.assertEqual(first,again)
        self.assertEqual(server.project(p['id'])['layout'][first['process']]['x'],-350)
        record=server.action(first['process'][8:])[1]
        record['exports']=[{'base':'/media/kept','meta':{'frame_count':20}}]
        result=self.client.delete('/api/projects/'+p['id']+'/nodes/'+first['export'],headers=self.headers)
        self.assertTrue(result.json()['files_preserved'])
        self.assertNotIn(first['export'],server.canvas_graph(server.project(p['id']))['nodes'])
        self.assertTrue(record['exports'])

    def test_public_deployment_accepts_session_keys_and_caps_generation(self):
        p,a=self.make_action()
        with patch.dict(os.environ,{'ASSET_CANVAS_PUBLIC':'1','ASSET_CANVAS_DAILY_GENERATIONS':'0','RENDER_EXTERNAL_HOSTNAME':'jominframe.onrender.com'}):
            response=self.client.get('/api/state',headers={'host':'jominframe.onrender.com'})
            self.assertEqual(response.status_code,200)
            self.assertTrue(response.json()['public_mode'])
            self.assertEqual(self.client.post('/api/settings',headers=self.headers,json={'openai_key':'do-not-store'}).status_code,200)
            with self.assertRaises(server.HTTPException) as failure:server.new_job('image',p['id'],a['id'])
            self.assertEqual(failure.exception.status_code,429)

    def test_reuse_animations_preserves_source_and_resets_outputs(self):
        p,a=self.make_action();original=server.project(p['id'])
        a=original['actions'][0];a['prompt']='walk';a['options']['excluded']=[1,3];a['video']='/media/old.mp4'
        a['exports']=[{'id':'old'}];a['video_model']='custom-model'
        before=json.loads(json.dumps(original))
        buf=io.BytesIO();Image.new('RGBA',(32,32),(120,90,50,255)).save(buf,format='PNG')
        with patch.object(server.POOL,'submit') as submit:
            result=self.client.post('/api/projects/'+p['id']+'/reuse',headers=self.headers,data={'spec':json.dumps({'name':'new cat','actions':[a['id']]})},files={'file':('cat.png',buf.getvalue(),'image/png')})
        self.assertEqual(result.status_code,200);submit.assert_not_called()
        clone=result.json();video=clone['actions'][0]
        self.assertEqual(original,before)
        self.assertNotEqual(video['id'],a['id']);self.assertEqual(video['video_model'],'custom-model')
        self.assertIsNone(video['video']);self.assertEqual(video['exports'],[]);self.assertEqual(video['options']['excluded'],[])
        self.assertEqual(len(clone['graph']['edges']),3)
        self.assertTrue(server.path(clone['reference']).exists())

    def test_image_chain_routes_reference_and_rejects_cycle(self):
        p,a=self.make_action();base='/api/projects/'+p['id'];pr=server.project(p['id'])
        pr['reference']='/media/source.png'
        im=self.client.post(base+'/images',headers=self.headers,json={'name':'next'}).json()
        g=server.canvas_graph(pr);g['edges'].append({'from':'reference','to':'image-'+im['id']})
        self.assertEqual(self.client.patch(base,headers=self.headers,json={'graph':g}).status_code,200)
        with patch.dict(server.KEYS,{'OPENAI_API_KEY':'test'}),patch.object(server.POOL,'submit'):
            result=self.client.post(base+'/images/'+im['id']+'/generate',headers=self.headers,json={'prompt':'new look','use_reference':True})
        self.assertEqual(result.status_code,200);self.assertEqual(result.json()['reference'],'/media/source.png')
        g['edges'].append({'from':'image-'+im['id'],'to':'reference'})
        self.assertEqual(self.client.patch(base,headers=self.headers,json={'graph':g}).status_code,400)

    def test_undo_restores_deleted_node_edges_and_layout(self):
        p,a=self.make_action();base='/api/projects/'+p['id'];node='action-'+a['id']
        before=json.loads(json.dumps(server.canvas_graph(server.project(p['id']))))
        layout={node:{'x':-80,'y':120}}
        self.assertEqual(self.client.delete(base+'/nodes/'+node,headers=self.headers).status_code,200)
        self.assertNotIn(node,server.canvas_graph(server.project(p['id']))['nodes'])
        result=self.client.patch(base,headers=self.headers,json={'graph':before,'layout':layout,'restore_nodes':True})
        self.assertEqual(result.status_code,200)
        restored=server.canvas_graph(server.project(p['id']))
        self.assertEqual(restored['nodes'],before['nodes'])
        self.assertEqual(restored['edges'],before['edges'])
        self.assertEqual(server.project(p['id'])['layout'],layout)
        self.assertNotIn(node,server.project(p['id'])['deleted_nodes'])

    def test_remix_accepts_export_and_separate_image_and_rejects_cycles(self):
        p,a=self.make_action();base='/api/projects/'+p['id']
        im=Image.new('RGBA',(128,64));im.paste((230,140,40,255),(5,5,25,40));buf=io.BytesIO();im.save(buf,format='PNG')
        source=self.client.post(base+'/sheets',headers=self.headers,data={'spec':json.dumps({'name':'motion','columns':2,'rows':1,'count':2,'fps':20,'size':64})},files={'file':('source.png',buf.getvalue(),'image/png')}).json()
        server.action(a['id'])[1]['exports']=[source['original']]
        ref=self.client.post(base+'/images',headers=self.headers,json={'name':'new character'}).json()
        ref=self.client.post(base+'/images/'+ref['id']+'/upload',headers=self.headers,files={'file':('ref.png',buf.getvalue(),'image/png')}).json()
        target=self.client.post(base+'/remixes',headers=self.headers,json={}).json()
        project=server.project(p['id']);g=server.canvas_graph(project)
        g['edges']+=[{'from':'export-'+a['id'],'to':'sheet-edit-'+target['id']},{'from':'image-'+ref['id'],'to':'sheet-edit-'+target['id'],'slot':'image'}]
        self.assertEqual(self.client.patch(base,headers=self.headers,json={'graph':g}).status_code,200)
        with patch.dict(server.KEYS,{'OPENAI_API_KEY':'dummy-test'}),patch.object(server.POOL,'submit'):
            response=self.client.post('/api/sheets/'+target['id']+'/generate',headers=self.headers)
        self.assertEqual(response.status_code,200)
        job=response.json();self.assertEqual(job['source'],source['original']['base']+'/spritesheet.png');self.assertEqual(job['reference'],ref['source']);self.assertEqual(job['options']['count'],2)
        bad=json.loads(json.dumps(g));bad['edges']=[e for e in bad['edges'] if not(e['to']=='sheet-edit-'+target['id'] and e.get('slot','source')=='source')]
        bad['edges'].append({'from':'sheet-export-'+target['id'],'to':'sheet-edit-'+target['id']})
        self.assertEqual(self.client.patch(base,headers=self.headers,json={'graph':bad}).status_code,400)
        job_in_state=next(j for j in server.STATE['jobs'] if j['id']==job['id']);job_in_state['status']='done'
        self.assertEqual(self.client.delete(base+'/nodes/sheet-edit-'+target['id'],headers=self.headers).status_code,200)
        self.assertNotIn('sheet-edit-'+target['id'],server.canvas_graph(project)['nodes'])

    def test_batch_same_canvas_and_project_delete(self):
        p,a=self.make_action();base='/api/projects/'+p['id']
        png=io.BytesIO();Image.new('RGB',(32,32),'orange').save(png,format='PNG')
        self.client.post(base+'/images/reference/upload',headers=self.headers,files={'file':('cat.png',png.getvalue(),'image/png')})
        self.client.patch('/api/actions/'+a['id'],headers=self.headers,json={'prompt':'idle loop'})
        b=self.client.post(base+'/batches',headers=self.headers).json();route=base+'/batches/'+b['id']
        self.assertEqual(self.client.patch(route,headers=self.headers,json={'actions':[a['id']],'frame_count':10,'threshold':12}).status_code,200)
        before=len(server.STATE['projects']);job_count=len(server.STATE['jobs'])
        result=self.client.post(route+'/build',headers=self.headers)
        self.assertEqual(result.status_code,200,result.text)
        ids=result.json()['outputs'];self.assertEqual(len(ids),1)
        self.assertEqual(self.client.post(route+'/build',headers=self.headers).json()['outputs'],ids)
        self.assertEqual(len(server.STATE['projects']),before);self.assertEqual(len(server.STATE['jobs']),job_count)
        pr=server.project(p['id']);g=server.canvas_graph(pr)
        self.assertEqual(self.client.patch(base,headers=self.headers,json={'graph':g}).status_code,200)
        self.assertIn({'from':'action-'+ids[0],'to':'process-'+ids[0]},g['edges'])
        self.assertEqual(next(a for a in pr['actions'] if a['id']==ids[0])['options']['target_frame_count'],10)
        job={'id':'delete-guard','project':p['id'],'status':'running'};server.STATE['jobs'].append(job)
        self.assertEqual(self.client.delete(base,headers=self.headers).status_code,409)
        server.STATE['jobs'].remove(job)
        self.assertEqual(self.client.delete(base,headers=self.headers).status_code,200)
        self.assertNotIn(p['id'],[pr['id'] for pr in server.STATE['projects']])

    def test_copy_group_preserves_internal_edges_and_snapshot(self):
        p,a=self.make_action();base='/api/projects/'+p['id'];pr=server.project(p['id'])
        pr['layout']={'reference':{'x':-100,'y':40},'action-'+a['id']:{'x':300,'y':50}}
        original=server.canvas_graph(pr)
        nodes=['reference','action-'+a['id'],'process-'+a['id'],'export-'+a['id']]
        copied=self.client.post(base+'/copy',headers=self.headers,json={'nodes':nodes}).json()
        old_prompt=a['prompt'];self.client.patch('/api/actions/'+a['id'],headers=self.headers,json={'prompt':'changed after copy'})
        jobs=len(server.STATE['jobs'])
        result=self.client.post(base+'/paste',headers=self.headers,json={'clipboard':copied['clipboard'],'dx':60,'dy':80})
        self.assertEqual(result.status_code,200,result.text)
        mapped=result.json()['mapping'];g=server.canvas_graph(pr)
        self.assertEqual(len(set(mapped.values())),4)
        self.assertIn({'from':mapped['reference'],'to':mapped['action-'+a['id']]},g['edges'])
        self.assertIn({'from':mapped['action-'+a['id']],'to':mapped['process-'+a['id']]},g['edges'])
        self.assertEqual(pr['layout'][mapped['reference']],{'x':-40,'y':120})
        duplicate=server.action(mapped['action-'+a['id']][7:])[1]
        self.assertEqual(duplicate['prompt'],old_prompt)
        self.assertEqual(len(server.STATE['jobs']),jobs)
        self.assertEqual(self.client.patch(base,headers=self.headers,json={'graph':original,'restore_nodes':True}).status_code,200)
        self.assertFalse(set(mapped.values())&set(server.canvas_graph(pr)['nodes']))

    def test_cross_canvas_copy_keeps_assets_edges_and_independence(self):
        source,a=self.make_action();base='/api/projects/'+source['id']
        target=self.client.post('/api/projects',headers=self.headers,json={'name':'target'}).json()
        png=io.BytesIO();Image.new('RGB',(32,32),'orange').save(png,format='PNG')
        self.client.post(base+'/images/reference/upload',headers=self.headers,files={'file':('cat.png',png.getvalue(),'image/png')})
        nodes=['reference','action-'+a['id'],'process-'+a['id'],'export-'+a['id']]
        token='1'*32
        copied=self.client.post(base+'/copy',headers=self.headers,json={'nodes':nodes,'clipboard':token}).json()
        self.assertEqual(copied['clipboard'],token)
        result=self.client.post('/api/projects/'+target['id']+'/paste',headers=self.headers,json={'clipboard':token,'dx':0,'dy':0})
        self.assertEqual(result.status_code,200,result.text)
        mapping=result.json()['mapping'];pr=server.project(target['id'])
        self.assertEqual(len(server.canvas_graph(pr)['edges']),3)
        self.assertEqual(self.client.get(pr['images'][0]['source']).status_code,200)
        aid=mapping['action-'+a['id']][7:]
        self.client.patch('/api/actions/'+aid,headers=self.headers,json={'prompt':'new target prompt'})
        self.assertNotEqual(server.action(a['id'])[1]['prompt'],'new target prompt')
        self.assertEqual(self.client.patch('/api/projects/'+target['id'],headers=self.headers,json={'graph':server.canvas_graph(pr)}).status_code,200)

    def test_copy_partial_nodes_omits_external_edges(self):
        p,a=self.make_action();base='/api/projects/'+p['id']
        sh=self.client.post(base+'/remixes',headers=self.headers,json={}).json()
        clip=self.client.post(base+'/copy',headers=self.headers,json={'nodes':['action-'+a['id'],'sheet-export-'+sh['id']]}).json()
        result=self.client.post(base+'/paste',headers=self.headers,json={'clipboard':clip['clipboard']}).json()
        nodes=result['nodes'];g=server.canvas_graph(server.project(p['id']))
        self.assertFalse(any(e['to'] in nodes or e['from'] in nodes for e in g['edges']))
        sheet_id=result['mapping']['sheet-export-'+sh['id']].rsplit('-',1)[1]
        self.assertNotIn('sheet-edit-'+sheet_id,g['nodes'])
        self.assertEqual(self.client.post(base+'/copy',headers=self.headers,json={'nodes':['missing']}).status_code,400)

    def test_distinct_bundled_examples_without_generation(self):
        before=len(server.STATE['jobs'])
        golden=self.client.post('/api/demo',headers=self.headers,json={'kind':'golden'})
        giant=self.client.post('/api/demo',headers=self.headers,json={'kind':'giant'})
        self.assertEqual(golden.status_code,200,golden.text)
        self.assertEqual(giant.status_code,200,giant.text)
        g=giant.json();self.assertNotEqual(g['id'],golden.json()['id'])
        self.assertEqual(self.client.post('/api/demo',headers=self.headers,json={'kind':'giant'}).json()['id'],g['id'])
        self.assertEqual(self.client.post('/api/demo',headers=self.headers).json()['id'],golden.json()['id'])
        self.assertEqual([a['options']['duration'] for a in g['actions']],[1,2,2])
        for a in g['actions']:
            self.assertEqual(self.client.get(a['video']).status_code,200)
            self.assertTrue(a['prompt'])
        self.assertEqual(len(server.canvas_graph(g)['edges']),9)
        self.assertEqual(len(server.STATE['jobs']),before)

    def test_prepared_batch_demo_and_exports(self):
        before=len(server.STATE['jobs'])
        result=self.client.post('/api/demo',headers=self.headers,json={'kind':'batch'})
        self.assertEqual(result.status_code,200,result.text)
        pr=result.json()
        self.assertEqual(len(pr['actions']),12)
        self.assertEqual(len(pr['images']),5)
        self.assertEqual(self.client.post('/api/demo',headers=self.headers,json={'kind':'batch'}).json()['id'],pr['id'])
        for a in pr['actions']:
            self.assertTrue(server.path(a['video']).is_file())
            self.assertTrue(a['exports'])
            ex=a['exports'][-1]
            self.assertTrue(server.path(ex['base']+'/spritesheet.png').is_file())
            self.assertTrue(server.path(ex['base']+'/spritesheet.zip').is_file())
        for b in pr['batches']:
            source=server.project(b['source_project'])
            self.assertTrue(set(b['actions']).issubset({a['id'] for a in source['actions']}))
            self.assertFalse(b['running'])
        self.assertEqual(len(server.STATE['jobs']),before)
        for kind in ['golden','giant']:
            sample=self.client.post('/api/demo',headers=self.headers,json={'kind':kind}).json()
            self.assertTrue(all(a['exports'] for a in sample['actions']))
            action=server.project(sample['id'])['actions'][0]
            action['exports']=[];action['prompt']='Keep my edited prompt'
            sample=self.client.post('/api/demo',headers=self.headers,json={'kind':kind}).json()
            self.assertTrue(sample['actions'][0]['exports'])
            self.assertEqual(sample['actions'][0]['prompt'],'Keep my edited prompt')

    def test_pipeline_settings_apply_to_connected_processor(self):
        p,a=self.make_action();route='/api/actions/'+a['id']+'/pipeline'
        before=len(server.STATE['jobs'])
        response=self.client.post(route,headers=self.headers,json={'frame_count':10,'threshold':12})
        self.assertEqual(response.status_code,200,response.text)
        proc_id=response.json()['process'][8:]
        record=next(x for x in server.project(p['id'])['actions'] if x['id']==proc_id)
        self.assertEqual(record['options']['target_frame_count'],10)
        self.assertEqual(record['options']['threshold'],12)
        self.assertEqual(len(server.STATE['jobs']),before)
        self.assertEqual(self.client.post(route,headers=self.headers,json={'frame_count':0,'threshold':12}).status_code,400)
        self.assertEqual(record['options']['target_frame_count'],10)

    def make_multi_batch(self):
        p,a=self.make_action();base='/api/projects/'+p['id']
        self.client.patch('/api/actions/'+a['id'],headers=self.headers,json={'prompt':'walk loop'})
        second=self.client.post(base+'/actions',headers=self.headers,json={'name':'idle','prompt':'idle loop'}).json()
        images=[]
        for name in ['white','orange']:
            im=self.client.post(base+'/images',headers=self.headers,json={'name':name}).json()
            png=io.BytesIO();Image.new('RGB',(32,32),name).save(png,format='PNG')
            self.client.post(base+'/images/'+im['id']+'/upload',headers=self.headers,files={'file':('cat.png',png.getvalue(),'image/png')});images.append(im)
        b=self.client.post(base+'/batches',headers=self.headers).json();route=base+'/batches/'+b['id']
        self.client.patch(route,headers=self.headers,json={'actions':[a['id'],second['id']],'cells':{images[0]['id']+':'+a['id']:{'frame_count':13},images[1]['id']+':'+second['id']:{'enabled':False}}})
        g=server.canvas_graph(server.project(p['id']));g['edges'] += [{'from':'image-'+im['id'],'to':'batch-'+b['id'],'slot':'image'} for im in images]
        response=self.client.patch(base,headers=self.headers,json={'graph':g});self.assertEqual(response.status_code,200,response.text)
        b=self.client.post(route+'/build',headers=self.headers).json()
        return p,b,images

    def test_multi_reference_matrix_and_frozen_snapshot(self):
        p,b,images=self.make_multi_batch();pr=server.project(p['id'])
        self.assertEqual(len(b['outputs']),3);self.assertEqual([len(g['actions']) for g in b['groups']],[2,1])
        first=server.action(b['outputs'][0])[1]
        self.assertEqual(first['options']['target_frame_count'],13)
        frozen=first['batch_snapshot']['reference'];server.image_item(pr,images[0]['id'])['source']='/changed.png'
        self.assertEqual(first['batch_snapshot']['reference'],frozen)
        g=server.canvas_graph(pr);linked=[e for e in g['edges'] if e['to']=='batch-'+b['id']]
        self.assertEqual(len(linked),2)
        g['edges'].remove(linked[0]);self.assertEqual(self.client.patch('/api/projects/'+p['id'],headers=self.headers,json={'graph':g}).status_code,200)
        self.assertEqual(len([e for e in server.canvas_graph(pr)['edges'] if e['to']=='batch-'+b['id']]),1)

    def test_multi_batch_serial_queue_and_failed_only_retry(self):
        p,b,_=self.make_multi_batch();bid=b['id'];failed=b['outputs'][1];seen=[]
        def fake_execute(job,fn):
            seen.append((job['kind'],job['action']))
            act=server.action(job['action'])[1]
            if job['kind']=='video':act['video']='/fake-video.mp4';job['status']='done'
            elif job['action']==failed:job['status']='failed'
            else:act['exports']=[{'base':'/fake-export'}];job['status']='done'
        with patch.object(server,'execute',side_effect=fake_execute):server.run_batch_queue(p['id'],bid)
        self.assertEqual([kind for kind,_ in seen],['video','process']*3)
        self.assertFalse(next(b for b in server.project(p['id'])['batches'] if b['id']==bid)['running'])
        seen.clear()
        with patch.object(server,'execute',side_effect=fake_execute):server.run_batch_queue(p['id'],bid,True)
        self.assertEqual(seen,[('process',failed)])

    def test_build_only_is_free_and_queue_uses_node_edits(self):
        count=len(server.STATE['jobs'])
        p,b,_=self.make_multi_batch()
        self.assertEqual(len(server.STATE['jobs']),count)
        aid=b['outputs'][0]
        response=self.client.patch('/api/actions/'+aid,headers=self.headers,json={'prompt':'修改后的中文动作','video_model':'edited-model','options':{'threshold':12,'duration':1,'video_resolution':'720p'}})
        self.assertEqual(response.status_code,200,response.text)
        seen=[]
        def fake_execute(job,fn):
            seen.append(job.copy());act=server.action(job['action'])[1]
            if job['kind']=='video':act['video']='/fake.mp4'
            else:act['exports']=[{'base':'/fake-export'}]
            job['status']='done'
        with patch.object(server,'execute',side_effect=fake_execute):server.run_batch_queue(p['id'],b['id'])
        video=next(j for j in seen if j['action']==aid and j['kind']=='video')
        process=next(j for j in seen if j['action']==aid and j['kind']=='process')
        self.assertTrue(video['prompt'].startswith('修改后的中文动作'))
        self.assertEqual(video['model'],'edited-model')
        self.assertEqual(video['options']['video_resolution'],'720p')
        self.assertEqual(process['options']['threshold'],12)
        self.assertEqual(process['options']['duration'],1)

    def test_playback_speed_keeps_pixels_and_frame_count(self):
        p,a=self.make_action();pr,record=server.action(a['id'])
        dest=Path(TEMP.name)/p['id']/'speed-original'
        meta=process_video(self.source,dest,{**server.DEFAULTS,'size':64,'duration':1,'name':'speed_test'})
        record['exports']=[{'id':'original','base':server.url(dest),'meta':meta}]
        def immediate(job,fn):
            fn();job['status']='done'
        with patch.object(server,'execute',side_effect=immediate):
            response=self.client.post('/api/projects/'+p['id']+'/playback-speed',headers=self.headers,json={'source':'process-'+a['id'],'speed':.5})
        self.assertEqual(response.status_code,200,response.text)
        new=record['exports'][-1];self.assertEqual(new['meta']['frame_count'],meta['frame_count'])
        self.assertEqual(new['meta']['fps'],meta['fps']*.5)
        self.assertEqual(new['meta']['duration'],meta['duration']*2)
        self.assertTrue(np.array_equal(np.array(Image.open(dest/'spritesheet.png')),np.array(Image.open(server.path(new['base'])/'spritesheet.png'))))
        self.assertIn('"speed": 5.0',(server.path(new['base'])/'sprite_frames.tres').read_text())
        with patch.object(server,'execute',side_effect=immediate):
            response=self.client.post('/api/projects/'+p['id']+'/playback-speed',headers=self.headers,json={'source':'process-'+a['id'],'speed':2})
        self.assertEqual(response.status_code,200)
        self.assertEqual(record['exports'][-1]['meta']['fps'],meta['fps']*2)

    def test_developer_log_persistence_and_conflict(self):
        initial=self.client.get('/api/developer-log').json()
        text='开发者说明\n此画布为单独一人制作。\n<script>literal text</script>'
        response=self.client.put('/api/developer-log',headers=self.headers,json={'content':text,'revision':initial['revision']})
        self.assertEqual(response.status_code,200,response.text)
        self.assertEqual(self.client.get('/api/developer-log').json()['content'],text)
        persisted=json.loads(server.DB.execute('SELECT value FROM store WHERE key=?',('state',)).fetchone()[0])
        self.assertEqual(persisted['developer_log']['content'],text)
        self.assertEqual(self.client.put('/api/developer-log',headers=self.headers,json={'content':'outdated','revision':initial['revision']}).status_code,409)
        self.assertEqual(self.client.put('/api/developer-log',headers=self.headers,json={'content':'  ','revision':response.json()['revision']}).status_code,400)

    def test_create_connected_nodes_without_generation(self):
        p,a=self.make_action();base='/api/projects/'+p['id'];job_count=len(server.STATE['jobs'])
        def create(source,target):
            response=self.client.post(base+'/connected-node',headers=self.headers,json={'source':source,'target':target,'x':-100,'y':300})
            self.assertEqual(response.status_code,200,response.text)
            node=response.json()['node'];g=server.canvas_graph(server.project(p['id']))
            self.assertTrue(any(e['from']==source and e['to']==node for e in g['edges']))
            self.assertEqual(self.client.patch(base,headers=self.headers,json={'graph':g}).status_code,200)
            self.assertEqual(server.project(p['id'])['layout'][node],{'x':-100,'y':300})
            return node
        for target in ['image','action','batch','sheet-edit']:create('reference',target)
        proc=create('action-'+a['id'],'process');out=create(proc,'export');edit=create(out,'sheet-edit');create(edit,'sheet-export')
        before=server.canvas_graph(server.project(p['id']))
        self.assertEqual(self.client.post(base+'/connected-node',headers=self.headers,json={'source':'reference','target':'process','x':0,'y':0}).status_code,400)
        self.assertEqual(server.canvas_graph(server.project(p['id'])),before)
        self.assertEqual(len(server.STATE['jobs']),job_count)

    def test_bulk_delete_atomic_and_undo(self):
        p,a=self.make_action();base='/api/projects/'+p['id'];pr=server.project(p['id']);before=server.canvas_graph(pr)
        nodes=['reference','action-'+a['id'],'process-'+a['id']]
        job={'id':'bulk-delete-guard','project':p['id'],'action':a['id'],'status':'running'};server.STATE['jobs'].append(job)
        self.assertEqual(self.client.post(base+'/nodes/delete',headers=self.headers,json={'nodes':nodes}).status_code,409)
        self.assertEqual(server.canvas_graph(pr),before)
        server.STATE['jobs'].remove(job)
        self.assertEqual(self.client.post(base+'/nodes/delete',headers=self.headers,json={'nodes':nodes}).status_code,200)
        self.assertFalse(set(nodes)&set(server.canvas_graph(pr)['nodes']))
        self.assertFalse(server.canvas_graph(pr)['edges'])
        self.assertEqual(self.client.patch(base,headers=self.headers,json={'graph':before,'restore_nodes':True}).status_code,200)
        self.assertEqual(server.canvas_graph(pr),before)

    def test_batch_per_action_frame_counts(self):
        p,a=self.make_action();base='/api/projects/'+p['id']
        second=self.client.post(base+'/actions',headers=self.headers,json={'name':'second'}).json()
        png=io.BytesIO();Image.new('RGB',(32,32),'orange').save(png,format='PNG')
        self.client.post(base+'/images/reference/upload',headers=self.headers,files={'file':('cat.png',png.getvalue(),'image/png')})
        b=self.client.post(base+'/batches',headers=self.headers).json();route=base+'/batches/'+b['id']
        response=self.client.patch(route,headers=self.headers,json={'actions':[a['id'],second['id']],'action_frames':{a['id']:10,second['id']:40}})
        self.assertEqual(response.status_code,200,response.text)
        self.assertEqual(self.client.patch(route,headers=self.headers,json={'action_frames':{a['id']:0}}).status_code,400)
        result=self.client.post(route+'/build',headers=self.headers)
        self.assertEqual(result.status_code,200,result.text)
        self.assertEqual([server.action(aid)[1]['options']['target_frame_count'] for aid in result.json()['outputs']],[10,40])

    def test_batch_image_connection(self):
        p,a=self.make_action();base='/api/projects/'+p['id']
        b=self.client.post(base+'/batches',headers=self.headers).json();route=base+'/batches/'+b['id']
        self.client.patch(route,headers=self.headers,json={'actions':[a['id']]})
        im=self.client.post(base+'/images',headers=self.headers,json={'name':'connected reference'}).json()
        png=io.BytesIO();Image.new('RGB',(32,32),'orange').save(png,format='PNG')
        self.client.post(base+'/images/'+im['id']+'/upload',headers=self.headers,files={'file':('cat.png',png.getvalue(),'image/png')})
        g=server.canvas_graph(server.project(p['id']))
        edge={'from':'image-'+im['id'],'to':'batch-'+b['id'],'slot':'image'}
        g['edges'].append(edge)
        self.assertEqual(self.client.patch(base,headers=self.headers,json={'graph':g}).status_code,200)
        result=self.client.post(route+'/build',headers=self.headers)
        self.assertEqual(result.status_code,200,result.text)
        aid=result.json()['outputs'][0]
        self.assertIn({'from':'image-'+im['id'],'to':'action-'+aid},server.canvas_graph(server.project(p['id']))['edges'])
        g=server.canvas_graph(server.project(p['id']));g['edges'].remove(edge)
        self.assertEqual(self.client.patch(base,headers=self.headers,json={'graph':g}).status_code,200)
        g['edges'].append({'from':'action-'+a['id'],'to':'batch-'+b['id'],'slot':'image'})
        self.assertEqual(self.client.patch(base,headers=self.headers,json={'graph':g}).status_code,400)

    def test_exact_sheet_total_with_custom_count_and_upsampling(self):
        for count in [15,61]:
            dest=Path(TEMP.name)/('exact-total-'+str(count))
            meta=process_video(self.source,dest,{**server.DEFAULTS,'fps':20,'duration':2,'size':64,'target_frame_count':count,'pingpong':True})
            self.assertEqual(meta['frame_count'],count)
            self.assertEqual(len(meta['frames']),count)
            self.assertEqual(len(list((dest/'frames').glob('*.png'))),count)
            self.assertAlmostEqual(meta['duration'],2)
            self.assertEqual(json.loads((dest/'animations.json').read_text(encoding='utf-8'))['frame_count'],count)

    def test_target_frame_count_preserves_duration(self):
        opts={**server.DEFAULTS,'fps':20,'duration':2,'target_frame_count':10,'size':64}
        result=process_video(self.source,Path(TEMP.name)/'target-count',opts)
        self.assertEqual(result['frame_count'],10)
        self.assertAlmostEqual(result['duration'],2)
        self.assertEqual(len(set(result['kept_source_indices'])),10)

if __name__=='__main__':unittest.main()
