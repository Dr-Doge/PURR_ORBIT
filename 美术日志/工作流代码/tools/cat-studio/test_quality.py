import unittest, tempfile, os, io
from pathlib import Path
from unittest.mock import patch
os.environ['ASSET_CANVAS_DATA']=tempfile.mkdtemp(prefix='cat-quality-test-')
import server as s
from fastapi.testclient import TestClient
from PIL import Image, ImageDraw
from motion_quality import continuous_indices, align_clips, walk_five_indices

def sprite(x,y,size=64):
    im=Image.new('RGBA',(size,size));ImageDraw.Draw(im).rectangle((x,y,x+11,y+17),fill=(180,70,20,255));return im

class AlgorithmTests(unittest.TestCase):
    def test_walk_five_has_five_unique_phases_and_no_frozen_window(self):
        import math
        frames=[sprite(20+round(10*math.sin(i*math.pi/10)),20) for i in range(80)]
        ids,report=walk_five_indices(frames,20)
        self.assertEqual(len(ids),5)
        self.assertEqual(ids,sorted(set(ids)))
        self.assertTrue(.8<=report['cycle_seconds']<=1.2)
        self.assertGreaterEqual(ids[-1]-ids[0],12)
        self.assertEqual(report['after']['near_duplicate_pairs'],0)
        with self.assertRaises(ValueError):walk_five_indices([sprite(20,20)]*80,20)

    def test_nonloop_preserves_all_motion_including_pauses(self):
        frames=[sprite(x,20) for x in [5,5,5,9,13,20,22,22,22]]
        ids,r=continuous_indices(frames,False)
        self.assertEqual(ids,list(range(len(frames))))

    def test_loop_only_trims_edges_in_chronological_order(self):
        frames=[sprite(x,20) for x in [5,7,9,11,13,15,13,11,9,7,5,7,9,11,13,15]]
        ids,r=continuous_indices(frames,True)
        self.assertEqual(ids,list(range(ids[0],ids[-1]+1)))
        self.assertGreaterEqual(len(ids),int(len(frames)*.65))
        self.assertLessEqual(r['after']['seam'],r['before']['seam'])

    def test_shared_anchor_and_jump_preserved(self):
        clips=[[sprite(10,30),sprite(10,20)],[sprite(35,10),sprite(35,0)]]
        out,r=align_clips(clips,[0,0],128)
        self.assertEqual(out[0][0].getbbox(),out[1][0].getbbox())
        self.assertEqual(out[0][0].getbbox()[1]-out[0][1].getbbox()[1],10)
        self.assertEqual(out[1][0].getbbox()[1]-out[1][1].getbbox()[1],10)
        self.assertTrue(r['motion_preserved'])

    def test_fit_does_not_clip_large_motion(self):
        clips=[[sprite(0,0,256),sprite(230,230,256)],[sprite(40,30,256),sprite(100,0,256)]]
        out,r=align_clips(clips,[0,0],128)
        for frames in out:
            for im in frames:
                b=im.getbbox();self.assertIsNotNone(b)
                self.assertGreaterEqual(min(b[:2]),4);self.assertLessEqual(max(b[2:]),124)

class QualityApiTests(unittest.TestCase):
    def setUp(self):
        s.STATE['projects']=[];s.STATE['jobs']=[]
        self.client=TestClient(s.app,headers={'X-Canvas-Request':'1'})
        self.p=s.create_project({'name':'测试猫'})
        self.actions=[]
        for i in range(2):
            a=s.add_action(self.p['id'],{'name':f'动作{i}','prompt':'小动作'})
            a['options'].update(size=64,color_mode='off',pixel_stable=False,loop=False)
            dest=s.DATA/self.p['id']/a['id']
            meta=s.pack_frames([sprite(10+i*12,20),sprite(10+i*12,15)],dest,a['options'])
            a['exports']=[{'id':s.uid(),'base':s.url(dest),'meta':meta,'created':s.time.time()}]
            self.actions.append(a)

    def execute(self,j,fn):
        fn();j['status']='done'

    def test_preview_apply_stale_guard_and_idempotency(self):
        counts=[len(a['exports']) for a in self.actions]
        with patch.object(s,'execute',side_effect=self.execute):
            r=self.client.post(f"/api/studio/projects/{self.p['id']}/quality-preview",json={'mode':'alignment','items':[{'id':a['id'],'anchor':0} for a in self.actions],'size':128})
        self.assertEqual(r.status_code,200,r.text)
        self.assertEqual([len(a['exports']) for a in self.actions],counts)
        j=r.json();self.assertEqual(len(j['candidates']),2)
        endpoint=f"/api/studio/projects/{self.p['id']}/quality-apply"
        self.assertEqual(self.client.post(endpoint,json={'job':j['id']}).status_code,200)
        self.assertEqual(self.client.post(endpoint,json={'job':j['id']}).status_code,200)
        self.assertEqual([len(a['exports']) for a in self.actions],[2,2])

    def test_stale_preview_cannot_overwrite_newer_export(self):
        with patch.object(s,'execute',side_effect=self.execute):
            r=self.client.post(f"/api/studio/projects/{self.p['id']}/quality-preview",json={'mode':'alignment','items':[{'id':a['id'],'anchor':0} for a in self.actions]})
        self.actions[0]['exports'][-1]['id']='newer'
        result=self.client.post(f"/api/studio/projects/{self.p['id']}/quality-apply",json={'job':r.json()['id']})
        self.assertEqual(result.status_code,409)
        self.assertEqual(len(self.actions[1]['exports']),1)

    def test_direction_discovery_upload_and_mock_image_generation(self):
        im=s.create_image_node(self.p['id'],{'name':'cat2up'})
        mapping=self.client.get(f"/api/studio/projects/{self.p['id']}/references").json()
        self.assertEqual(mapping['slots']['up']['id'],im['id'])
        data=io.BytesIO();sprite(10,10).save(data,format='PNG')
        endpoint=f"/api/studio/projects/{self.p['id']}/references/up"
        result=self.client.post(endpoint+'/upload',files={'file':('up.png',data.getvalue(),'image/png')})
        self.assertEqual(result.status_code,200,result.text)
        self.assertTrue(s.image_item(self.p,im['id'])['source'])
        with patch.object(s,'key',return_value='test'),patch.object(s,'execute'):
            result=self.client.post(endpoint+'/generate',json={'prompt':'同一只猫的背面','reference_id':im['id'],'paid_confirmed':True})
        self.assertEqual(result.status_code,200,result.text)
        self.assertEqual(result.json()['reference'],s.image_item(self.p,im['id'])['source'])
        self.assertEqual(result.json()['image_id'],im['id'])

    def test_optional_320_export_preserves_original_and_timing(self):
        import zipfile,json
        a=self.actions[0];ex=a['exports'][-1];original=(s.path(ex['base'])/'spritesheet.png').read_bytes()
        result=self.client.post('/api/studio/actions/'+a['id']+'/export-sized',json={'frame_size':320,'export_id':ex['id']})
        self.assertEqual(result.status_code,200,result.text)
        with zipfile.ZipFile(s.path(result.json()['url'])) as z:
            meta=json.loads(z.read('animations.json'));self.assertEqual(meta['frame_width'],320)
            self.assertEqual(meta['frame_count'],ex['meta']['frame_count']);self.assertEqual(meta['fps'],ex['meta']['fps'])
            self.assertEqual(meta['loop'],ex['meta']['loop'])
        items=[{'project':self.p['id'],'action':a['id'],'export':ex['id']}]
        for size in [0,320]:
            result=self.client.post('/api/exports/png',json={'items':items,'frame_size':size})
            self.assertEqual(result.status_code,200,result.text)
            with zipfile.ZipFile(s.path(result.json()['url'])) as z:
                data=z.read(z.namelist()[0])
                if not size:self.assertEqual(data,original)
                else:
                    with Image.open(io.BytesIO(data)) as im:self.assertEqual(im.width,320*ex['meta']['columns'])
        self.assertEqual(len(a['exports']),1)
        self.assertEqual((s.path(ex['base'])/'spritesheet.png').read_bytes(),original)

    def test_speed_preserves_frames_and_updates_all_timing(self):
        a=self.actions[0];old=a['exports'][-1];endpoint='/api/studio/actions/'+a['id']+'/speed'
        for fps in [0,-1,121,'fast',True]:
            self.assertEqual(self.client.post(endpoint,json={'fps':fps,'export_id':old['id']}).status_code,400)
        self.assertEqual(self.client.post(endpoint,json={'fps':4,'export_id':'stale'}).status_code,409)
        with patch.object(s,'execute',side_effect=self.execute),patch.object(s,'process_video') as process:
            result=self.client.post(endpoint,json={'fps':4,'export_id':old['id']})
        self.assertEqual(result.status_code,200,result.text);process.assert_not_called()
        ex=a['exports'][-1];m=ex['meta'];self.assertEqual(m['fps'],4)
        self.assertEqual(m['frame_count'],old['meta']['frame_count'])
        self.assertEqual(m['duration'],m['frame_count']/4)
        self.assertEqual(len(a['exports']),2)
        self.assertEqual(a['options']['playback_fps'],4)
        for i in range(m['frame_count']):
            with Image.open(s.path(old['base'])/'frames'/f'{i:03}.png') as before,Image.open(s.path(ex['base'])/'frames'/f'{i:03}.png') as after:
                self.assertEqual(before.tobytes(),after.tobytes())
        with Image.open(s.path(ex['base'])/'preview.png') as im:self.assertAlmostEqual(im.info['duration'],250,places=1)
        self.assertIn('"speed": 4.0',(s.path(ex['base'])/'sprite_frames.tres').read_text(encoding='utf-8'))
        self.assertEqual(self.client.post(endpoint,json={'fps':8,'export_id':old['id']}).status_code,409)

    def test_rename_updates_export_metadata_without_generation(self):
        a=self.actions[0]
        with patch.object(s,'execute',side_effect=self.execute),patch.object(s,'generate_video') as gen:
            result=self.client.post('/api/studio/actions/'+a['id']+'/rename',json={'name':'侧面待机'})
        self.assertEqual(result.status_code,200,result.text);gen.assert_not_called()
        ex=a['exports'][-1];self.assertEqual(ex['meta']['name'],'侧面待机')
        self.assertIn('侧面待机',(s.path(ex['base'])/'sprite_frames.tres').read_text(encoding='utf-8'))

    def test_continuity_uses_real_video_and_respects_playback_fps(self):
        import shutil
        a=self.actions[0];dest=s.DATA/'quality-input.mp4'
        shutil.copyfile(s.HERE/'samples/golden/walk/golden-walk-1s.mp4',dest)
        a['video']=s.url(dest);a['options'].update(duration=1,target_frame_count=5,playback_fps=5)
        with patch.object(s,'execute',side_effect=self.execute):
            r=self.client.post(f"/api/studio/projects/{self.p['id']}/quality-preview",json={'mode':'continuity','items':[{'id':a['id']}],'loop':False})
        self.assertEqual(r.status_code,200,r.text)
        ex=r.json()['candidates'][0]['after'];self.assertEqual(ex['meta']['frame_count'],20)
        self.assertEqual(ex['meta']['fps'],20);self.assertEqual(len(a['exports']),1)
        meta=s.process_video(dest,s.DATA/'speed-test',{**a['options'],'playback_fps':7})
        self.assertEqual(meta['fps'],7)

    def test_seam_optimization_never_changes_playback_loop(self):
        source=s.HERE/'samples/golden/walk/golden-walk-1s.mp4'
        for looping,mode in [(True,'sequence'),(False,'sequence'),(False,'loop'),(True,'loop')]:
            options={**self.actions[0]['options'],'duration':.5,'loop':looping,'continuity_mode':mode}
            dest=s.DATA/s.uid()
            meta=s.process_video(source,dest,options)
            self.assertEqual(meta['loop'],looping)
            self.assertEqual(meta['settings']['loop'],looping)
            with Image.open(dest/'preview.png') as im:self.assertEqual(im.info['loop'],0)
            text=(dest/'sprite_frames.tres').read_text(encoding='utf-8')
            self.assertIn('"loop": '+str(looping).lower(),text)

if __name__=='__main__':unittest.main()
