import os, tempfile, unittest
from unittest.mock import patch
os.environ['ASSET_CANVAS_DATA']=tempfile.mkdtemp(prefix='cat-studio-test-')
from fastapi.testclient import TestClient
import server as s

class WorkflowTests(unittest.TestCase):
    def setUp(self):
        s.STATE['projects']=[];s.STATE['jobs']=[]
        self.client=TestClient(s.app,headers={'X-Canvas-Request':'1'})
        self.p=s.create_project({'name':'三花猫'})
        self.q=s.create_project({'name':'橘猫'})
        self.p['reference']='/media/calico.png';self.q['reference']='/media/orange.png'
        self.a=s.add_action(self.p['id'],{'name':'舔爪','prompt':'舔爪'})
        self.b=s.add_action(self.q['id'],{'name':'翻肚皮','prompt':'翻肚皮'})

    def test_reuse_actions_uses_target_reference_and_preserves_source(self):
        self.a['video']='/media/old.mp4';self.a['exports']=[{'id':'old'}]
        endpoint=f"/api/studio/projects/{self.q['id']}/reuse-actions"
        body={'source_project':self.p['id'],'items':[{'id':self.a['id'],'name':'新猫舔爪','prompt':'新猫动作','frame_count':5,'reference_node':'reference'}]}
        with patch.object(s,'execute') as execute:
            result=self.client.post(endpoint,json=body)
        self.assertEqual(result.status_code,200,result.text);execute.assert_not_called()
        created=next(a for a in self.q['actions'] if a['id']==result.json()['results'][0]['id'])
        self.assertIsNone(created['video']);self.assertEqual(created['exports'],[])
        self.assertEqual(created['options']['target_frame_count'],5)
        self.assertEqual(s.video_image(self.q,created['id']),'/media/orange.png')
        self.assertEqual(created['prompt'],'新猫动作');self.assertEqual(self.a['prompt'],'舔爪')
        self.assertEqual(self.client.post(endpoint,json=body).json()['results'][0]['status'],'skipped')
        count=len(self.q['actions']);body['items'][0]['reference_node']='image-missing'
        self.assertEqual(self.client.post(endpoint,json=body).status_code,400)
        self.assertEqual(len(self.q['actions']),count)

    def test_individual_reference_and_prompt(self):
        with patch.object(s,'key',return_value='test'),patch.object(s,'execute'):
            r=self.client.post('/api/studio/batch',json={'items':[self.a['id'],self.b['id']],'paid_confirmed':True}).json()
        self.assertTrue(all(x['status']=='submitted' for x in r['results']))
        jobs={j['action']:j for j in s.STATE['jobs']}
        self.assertEqual(jobs[self.a['id']]['reference'],'/media/calico.png')
        self.assertEqual(jobs[self.b['id']]['reference'],'/media/orange.png')
        self.assertTrue(jobs[self.b['id']]['prompt'].startswith('翻肚皮'))

    def test_completed_skipped_and_existing_video_local(self):
        self.a['exports']=[{'id':'old'}];self.b['video']='/media/existing.mp4'
        with patch.object(s,'execute'),patch.object(s,'video_job') as gen:
            result=self.client.post('/api/studio/batch',json={'items':[self.a['id'],self.b['id']]}).json()
        self.assertEqual([r['status'] for r in result['results']],['skipped','submitted'])
        gen.assert_not_called();self.assertEqual(s.STATE['jobs'][0]['kind'],'process')

    def test_paid_confirmation_and_duplicate_protection(self):
        result=self.client.post('/api/studio/batch',json={'items':[self.a['id']]}).json()
        self.assertEqual(result['results'][0]['status'],'failed')
        with patch.object(s,'key',return_value='test'),patch.object(s,'execute'):
            self.client.post('/api/studio/batch',json={'items':[self.a['id']],'paid_confirmed':True})
            result=self.client.post('/api/studio/batch',json={'items':[self.a['id']],'paid_confirmed':True}).json()
        self.assertEqual(result['results'][0]['status'],'skipped');self.assertEqual(len(s.STATE['jobs']),1)

    def test_local_adjust_routes_to_connected_processor(self):
        self.a['video']='/media/video.mp4'
        s.prepare_video_pipeline(self.a['id'])
        with patch.object(s,'execute'),patch.object(s,'video_job') as gen:
            response=self.client.post('/api/studio/actions/'+self.a['id']+'/adjust',json={'process':True,'options':{'threshold':25,'pixel_stable':False}})
        self.assertEqual(response.status_code,200);gen.assert_not_called()
        self.assertEqual(response.json()['options']['threshold'],25)
        self.assertFalse(response.json()['options']['pixel_stable'])

    def test_restore_appends_and_preserves_history(self):
        self.a['exports']=[{'id':'v1','base':'/media/one','meta':{'settings':{'threshold':25}}},{'id':'v2','base':'/media/two','meta':{'settings':{'threshold':5}}}]
        r=self.client.post('/api/studio/actions/'+self.a['id']+'/adjust',json={'restore':'v1'})
        self.assertEqual(r.status_code,200);self.assertEqual(len(self.a['exports']),3)
        self.assertEqual(self.a['exports'][-1]['base'],'/media/one')
        self.assertEqual(self.a['options']['threshold'],25)

    def test_per_action_reference_and_archive(self):
        self.p['images']=[{'id':'back','name':'背面','source':'/media/back.png'}]
        r=self.client.post('/api/studio/projects/'+self.p['id']+'/actions',json={'name':'朝上走','prompt':'背面行走','reference_node':'image-back'})
        self.assertEqual(r.status_code,200)
        self.assertEqual(s.video_image(self.p,r.json()['id']),'/media/back.png')
        self.client.post('/api/studio/actions/'+self.a['id']+'/adjust',json={'archived':True})
        result=self.client.post('/api/studio/batch',json={'items':[self.a['id']]}).json()
        self.assertEqual(result['results'][0]['status'],'failed')
        self.client.post('/api/studio/actions/'+self.a['id']+'/adjust',json={'archived':False})
        self.assertFalse(self.a['studio_archived'])

    def test_real_local_pipeline_export(self):
        import shutil, zipfile
        source=s.HERE/'samples/golden/walk/golden-walk-1s.mp4'
        dest=s.DATA/'test-video.mp4';shutil.copyfile(source,dest)
        self.a['video']='/media/test-video.mp4'
        self.a['options'].update(size=64,duration=.5,fps=10,target_frame_count=5,color_mode='off',pixel_stable=False)
        with patch.object(s,'execute',side_effect=lambda j,fn: fn()):
            result=self.client.post('/api/studio/batch',json={'items':[self.a['id']]}).json()
        self.assertEqual(result['results'][0]['status'],'submitted')
        ex=self.a['exports'][-1]
        self.assertEqual(ex['meta']['frame_count'],5)
        with zipfile.ZipFile(s.path(ex['base'])/'spritesheet.zip') as z:
            self.assertIn('sprite_frames.tres',z.namelist())
            self.assertIn('frames/004.png',z.namelist())
        response=self.client.post('/api/exports/png',json={'items':[{'project':self.p['id'],'action':self.a['id'],'export':ex['id']}]})
        self.assertEqual(response.status_code,200)

if __name__=='__main__': unittest.main()
