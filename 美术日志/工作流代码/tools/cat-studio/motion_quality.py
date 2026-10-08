"""Conservative temporal trimming and clip-level registration. No invented frames."""
import math
import numpy as np
from PIL import Image

def signature(frame):
    a=np.asarray(frame.convert('RGBA').resize((48,48),Image.Resampling.BOX),dtype=np.float32)/255
    a[:,:,:3]*=a[:,:,3:4]
    return a

def distance(a,b):
    mask=(a[:,:,3]>.02)|(b[:,:,3]>.02)
    if not mask.any():return 0.
    return float(np.abs(a-b)[mask].mean())

def continuity_report(frames):
    sig=[signature(f) for f in frames]
    transitions=[distance(a,b) for a,b in zip(sig,sig[1:])]
    return {'seam':round(distance(sig[-1],sig[0]),5),
            'largest_step':round(max(transitions,default=0),5),
            'mean_step':round(float(np.mean(transitions)) if transitions else 0,5),
            'near_duplicate_pairs':sum(d<.001 for d in transitions)}

def continuous_indices(frames,loop=False):
    """Only trim the edges; retain chronological samples and at least 65% of motion.

    Score the actual wrap transition and its velocity change. A stationary
    endpoint alone is not sufficient. Never trim non-looping actions.
    """
    n=len(frames);original=list(range(n));before=continuity_report(frames)
    report={'algorithm':'dense-sampling-loop-v1','before':before,'trimmed':False,
            'note':'使用真实顺序帧，不进行AI补帧或打乱动作。'}
    if not loop or n<8:
        report['after']=before;return original,report
    sig=[signature(f) for f in frames]
    def score(i,j):
        seam=distance(sig[j],sig[i])
        wrap=sig[i]-sig[j];v1=sig[j]-sig[j-1];v2=sig[i+1]-sig[i]
        mask=(sig[i][:,:,3]>.02)|(sig[j][:,:,3]>.02)
        velocity=float((np.abs(wrap-v1)[mask].mean()+np.abs(v2-wrap)[mask].mean())/2) if mask.any() else 0
        return seam+.3*velocity
    baseline=score(0,n-1);best=baseline;choice=(0,n-1)
    edge=max(1,int(n*.2));minlen=max(6,math.ceil(n*.65))
    for i in range(edge+1):
        for j in range(max(i+minlen-1,n-edge-1),n):
            penalty=.02*(i+n-1-j)/n
            cost=score(i,j)+penalty
            if cost<best*.999 and distance(sig[j],sig[i])<=before['seam']:
                best=cost;choice=(i,j)
    if best<baseline*.88:
        original=list(range(choice[0],choice[1]+1));report['trimmed']=True
    report.update(after=continuity_report([frames[i] for i in original]),
                  start_index=original[0],end_index=original[-1],kept_frames=len(original))
    return original,report

def walk_five_indices(frames,fps):
    """Search a roughly one-second gait, sampling five equally spaced phases.

    The closing endpoint is scored but never exported twice. Reject low-motion
    windows relative to the source so a pause cannot win by being motionless.
    """
    n=len(frames)
    if n<max(6,math.ceil(.8*fps)):raise ValueError('5帧走路需要至少0.8秒的有效视频')
    sig=[signature(f) for f in frames]
    # Give the lower half (legs) equal influence to the complete silhouette.
    def d(a,b):return .5*distance(a,b)+.5*distance(a[24:],b[24:])
    distances=np.zeros((n,n),dtype=float)
    for i in range(n):
        for j in range(i+1,n):distances[i,j]=distances[j,i]=d(sig[i],sig[j])
    candidates=[]
    for period in range(max(5,round(.8*fps)),min(n-1,round(1.2*fps))+1):
        for start in range(n-period):
            ids=[start+round(k*period/5) for k in range(5)]
            steps=np.array([distances[ids[k],ids[(k+1)%5]] for k in range(5)])
            amplitude=max(distances[a,b] for a in ids for b in ids)
            # Position and velocity should agree at the return to phase zero.
            closure=distances[start,start+period]
            velocity=float(np.abs((sig[start+1]-sig[start])-(sig[start+period]-sig[start+period-1])).mean())
            score=steps.max()+.6*steps.std()+.6*closure+.2*velocity
            candidates.append((score,amplitude,ids,period,steps))
    amplitude=max(c[1] for c in candidates)
    eligible=[c for c in candidates if c[1]>=amplitude*.65 and (c[4]>.001).all()]
    if not eligible:raise ValueError('视频里没有足够的连续运动，无法选出5个有效走路姿势')
    best=min(eligible,key=lambda c:c[0]);_,_,ids,period,steps=best
    return ids,{'algorithm':'five-phase-walk-v1','cycle_seconds':period/fps,
                'start_index':ids[0],'end_index':ids[-1],'kept_frames':5,
                'before':continuity_report(frames),'after':continuity_report([frames[i] for i in ids]),
                'cycle_steps':[round(float(x),5) for x in steps],
                'note':'在约1秒步态中等间隔选择5个真实姿势，包含末帧回首帧的比较；不复制闭合端点。'}

def anchor(frame):
    alpha=np.asarray(frame.convert('RGBA'))[:,:,3]
    ys,xs=np.where(alpha>=128)
    if not len(xs):raise ValueError('基准帧为空，请选择有主体的帧')
    # Trim only a very small tail of alpha mass for horizontal center robustness.
    left,right=np.quantile(xs,[.02,.98])
    return ((float(left)+float(right))/2,float(ys.max()+1),float(ys.max()-ys.min()+1))

def align_clips(clips,anchor_indices,size=256,normalize=False):
    """One fixed affine transform per clip; one shared fit for the entire set."""
    if not 2<=len(clips)<=30:raise ValueError('请选择2–30个动作')
    if size not in [128,256,512,1024]:raise ValueError('请选择有效统一尺寸')
    anchors=[anchor(frames[index]) for frames,index in zip(clips,anchor_indices)]
    target_height=anchors[0][2]
    ratios=[target_height/a[2] if normalize else 1. for a in anchors]
    left=right=up=down=0.
    for frames,(ax,ay,_),ratio in zip(clips,anchors,ratios):
        for f in frames:
            b=f.getbbox()
            if b:
                left=max(left,(ax-b[0])*ratio);right=max(right,(b[2]-ax)*ratio)
                up=max(up,(ay-b[1])*ratio);down=max(down,(b[3]-ay)*ratio)
    margin=max(8,round(size*.04));height=max(1,up+down)
    scale=min(1.,(size-2*margin)/max(1,2*max(left,right)),(size-2*margin)/height)
    origin=(size/2,size-margin-down*scale)
    result=[];transforms=[]
    for frames,(ax,ay,_),ratio in zip(clips,anchors,ratios):
        k=scale*ratio;tx=origin[0]-ax*k;ty=origin[1]-ay*k
        # Fixed translation across the clip preserves jump height and breathing.
        converted=[f.transform((size,size),Image.Transform.AFFINE,(1/k,0,-tx/k,0,1/k,-ty/k),
                               resample=Image.Resampling.NEAREST) for f in frames]
        result.append(converted);transforms.append({'scale':k,'x':tx,'y':ty,'anchor':[ax,ay]})
    return result,{'algorithm':'shared-anchor-v1','size':size,'origin':list(origin),'normalize_size':normalize,
                   'transforms':transforms,'anchor_frames':anchor_indices,'motion_preserved':True}
