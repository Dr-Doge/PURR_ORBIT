"""Match video colors to the approved walk clip; retain source timing and geometry."""
from pathlib import Path
import argparse, json, subprocess
import numpy as np
import imageio_ffmpeg

ROOT = Path(__file__).resolve().parents[2]
FF = imageio_ffmpeg.get_ffmpeg_exe()
REFERENCE = ROOT/'output/seedance/cat1-walk/cat1-walk-1s.mp4'

def decode(path, size=192):
    raw = subprocess.check_output([FF,'-v','error','-i',str(path),'-vf',f'fps=10,scale={size}:{size}','-f','rawvideo','-pix_fmt','rgb24','-'])
    return np.frombuffer(raw,np.uint8).reshape(-1,3).astype(np.float32)

def anchors(p):
    r,g,b=p.T
    hi=p.max(1); lo=p.min(1)
    green=(g>r*1.35)&(g>b*1.35)&(g>90)
    masks=[(~green)&(hi<42), (~green)&(lo>45)&(hi<130)&(hi-lo<32),
           (~green)&(lo>170)&(hi-lo<35),
           (~green)&(r>150)&(g>90)&(g<r*.85)&(b<g*.8),
           (~green)&(r>175)&(g>125)&(b>110)&(r-g>20)&(g-b<35), green]
    return np.array([np.median(p[m],axis=0) for m in masks],np.float32)

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('source'); ap.add_argument('output')
    args=ap.parse_args()
    src=Path(args.source); out=Path(args.output); out.parent.mkdir(parents=True,exist_ok=True)
    source=anchors(decode(src)); target=anchors(decode(REFERENCE))
    # A smooth color correction field anchored to outline, gray, white, orange,
    # pink and green. No geometry, time, silhouette, or facial feature edits.
    delta=target-source
    grid=np.stack(np.meshgrid(*([np.linspace(0,255,33)]*3),indexing='ij'),axis=-1)
    dist=((grid[...,None,:]-source)**2).sum(-1)
    weights=1/np.maximum(dist,1)**2
    weights/=weights.sum(-1,keepdims=True)
    lut=np.clip((grid+(weights[...,None]*delta).sum(-2))/255,0,1)
    cube=out.with_suffix('.cube')
    with cube.open('w',encoding='ascii') as f:
        f.write('TITLE "Approved walk color match"\nLUT_3D_SIZE 33\nDOMAIN_MIN 0 0 0\nDOMAIN_MAX 1 1 1\n')
        for bi in range(33):
            for gi in range(33):
                for ri in range(33):
                    f.write('%.7f %.7f %.7f\n'%tuple(lut[ri,gi,bi]))
    # Run in output directory to avoid Windows colon escaping inside filters.
    subprocess.run([FF,'-v','error','-i',str(src.resolve()),'-vf',f'lut3d=file={cube.name}:interp=tetrahedral,scale=out_color_matrix=bt709:out_range=tv',
                    '-an','-c:v','libx264','-crf','14','-pix_fmt','yuv420p','-colorspace','bt709','-color_primaries','bt709','-color_trc','bt709','-color_range','tv','-movflags','+faststart','-y',out.name],cwd=out.parent,check=True)
    # Compensate for the RGB-to-YUV rounding introduced by MP4 encoding.
    for _ in range(2):
        residual=target-anchors(decode(out))
        delta+=residual
        lut=np.clip((grid+(weights[...,None]*delta).sum(-2))/255,0,1)
        with cube.open('w',encoding='ascii') as f:
            f.write('LUT_3D_SIZE 33\nDOMAIN_MIN 0 0 0\nDOMAIN_MAX 1 1 1\n')
            for bi in range(33):
                for gi in range(33):
                    for ri in range(33):
                        f.write('%.7f %.7f %.7f\n'%tuple(lut[ri,gi,bi]))
        subprocess.run([FF,'-v','error','-i',str(src.resolve()),'-vf',f'lut3d=file={cube.name}:interp=tetrahedral,scale=out_color_matrix=bt709:out_range=tv',
                        '-an','-c:v','libx264','-crf','14','-pix_fmt','yuv420p','-colorspace','bt709','-color_primaries','bt709','-color_trc','bt709','-color_range','tv','-movflags','+faststart','-y',out.name],cwd=out.parent,check=True)
    result={'reference':str(REFERENCE),'source':str(src),'output':str(out),
            'anchor_names':['outline','gray','white','orange','pink','green'],
            'source_rgb':source.tolist(),'target_rgb':target.tolist(),
            'result_rgb':anchors(decode(out)).tolist()}
    out.with_suffix('.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result))

if __name__=='__main__': main()
