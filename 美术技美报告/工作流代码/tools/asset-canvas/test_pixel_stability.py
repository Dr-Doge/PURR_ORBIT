import unittest
import numpy as np
from PIL import Image
from pixel_stability import stabilize_frames


class PixelStabilityTests(unittest.TestCase):
    def test_motion_alpha_and_input_unchanged(self):
        frames=[]
        for x in (20,22,24):
            a=np.zeros((128,128,4),dtype=np.uint8);a[30:60,x:x+20]=(200,140,60,255)
            frames.append(Image.fromarray(a))
        original=[np.array(f).copy() for f in frames]
        result,report=stabilize_frames(frames,128,1,'gentle',False)
        for before,after,source in zip(original,result,frames):
            np.testing.assert_array_equal(before,np.array(after))
            np.testing.assert_array_equal(before,np.array(source))
        self.assertEqual(report['alpha_temporal_edits'],0)

    def test_isolated_color_change_reduced(self):
        a=np.zeros((128,128,4),dtype=np.uint8);a[24:80,24:80]=(150,100,50,255)
        b=a.copy();b[44:46,44:46,:3]+=20
        result,report=stabilize_frames([Image.fromarray(v) for v in (a,b,a)],128,1,'gentle',False)
        self.assertGreater(report['corrected_cells'],0)
        self.assertLess(np.abs(np.array(result[1]).astype(int)-a).sum(),np.abs(b.astype(int)-a).sum())

    def test_grid_and_count(self):
        rng=np.random.default_rng(4);a=rng.integers(0,256,(128,128,4),dtype=np.uint8)
        result,_=stabilize_frames([Image.fromarray(a)],256,4)
        b=np.array(result[0]);self.assertEqual(len(result),1)
        np.testing.assert_array_equal(b,np.repeat(np.repeat(b[::4,::4],4,axis=0),4,axis=1))

if __name__=='__main__':unittest.main()
