"""Deterministic green-screen video -> RGBA frames, atlas and portable Godot resource."""
from pathlib import Path
import io, json, math, re, subprocess, zipfile
import numpy as np
from PIL import Image
import imageio_ffmpeg
from motion_quality import continuous_indices, walk_five_indices

FF = imageio_ffmpeg.get_ffmpeg_exe()

def spatial_brightness_repair(current, references, threshold):
    """Require same-region photometric evidence, never normalize whole-frame histograms."""
    a=np.array(current.convert('RGBA'));rgb=a[:,:,:3].astype(float)
    weights=np.array([.2126,.7152,.0722]);lum=rgb@weights
    def interior(ar):
        m=ar[:,:,3]>=240
        padded=np.pad(m,1,constant_values=False)
        for dy in range(3):
            for dx in range(3):m=m&padded[dy:dy+m.shape[0],dx:dx+m.shape[1]]
        y=ar[:,:,:3].astype(float)@weights
        # Flat local regions reduce errors from moving edges and occlusions.
        gy=np.abs(np.diff(y,axis=0,prepend=y[:1]));gx=np.abs(np.diff(y,axis=1,prepend=y[:,:1]))
        return m&(gx<12)&(gy<12)&(y>24)
    cm=interior(a);bbox=current.getbbox()
    if not bbox:return current,{}
    diffs=[];lights=[]
    for ref in references:
        b=np.array(ref.convert('RGBA'));box=ref.getbbox()
        if not box:continue
        dx=round((bbox[0]+bbox[2]-box[0]-box[2])/2);dy=round((bbox[1]+bbox[3]-box[1]-box[3])/2)
        shifted=np.zeros_like(b);h,w=b.shape[:2]
        if abs(dx)>=w or abs(dy)>=h:continue
        shifted[max(0,dy):min(h,h+dy),max(0,dx):min(w,w+dx)]=b[max(0,-dy):min(h,h-dy),max(0,-dx):min(w,w-dx)]
        mask=cm&interior(shifted)
        diff=shifted[:,:,:3].astype(float)-rgb
        # Matched material may change brightness, but wildly different hues are occlusions.
        chroma=diff-(diff@weights)[:,:,None]
        mask&=np.max(np.abs(chroma),axis=2)<18
        diffs.append(diff[mask]);lights.append(lum[mask])
    if not diffs:return current,{}
    delta=np.concatenate(diffs);ys=np.concatenate(lights);output=rgb.copy();changes={}
    for band in range(8):
        take=(ys>=band*32)&(ys<(band+1)*32)
        if np.count_nonzero(take)<32:continue
        values=delta[take];shift=np.median(values,axis=0);brightness=float(shift@weights)
        # Most corresponding pixels must independently agree on the correction.
        agreement=float(np.mean(np.max(np.abs(values-shift),axis=1)<=max(4,threshold)))
        if agreement<.7 or np.max(np.abs(shift))>64:continue
        if abs(brightness)<threshold and np.max(np.abs(shift))<max(12,threshold*2):continue
        mask=(a[:,:,3]>0)&(lum>=band*32)&(lum<(band+1)*32)&(lum>24)
        output[mask]=np.clip(rgb[mask]+shift,0,255)
        changes[str(band)]={'rgb_offset':shift.tolist(),'agreement':round(agreement,3)}
    a[:,:,:3]=np.rint(output).astype(np.uint8)
    return Image.fromarray(a),changes

def stabilize_colors(frames, mode='repair', threshold=6):
    """Brightness detection with spatial verification. Preserve geometry, alpha and order.

    Foreground quantiles nominate outliers; spatial material agreement verifies
    each brightness band. No whole-frame exposure transform is applied.
    All measurements are taken before correction, so repeated runs are stable.
    """
    if mode not in ['off','detect','repair']:raise ValueError('无效颜色检测模式')
    threshold=float(threshold)
    if not 2<=threshold<=50:raise ValueError('亮度异常阈值必须为2–50')
    report={'algorithm':'luminance-v3','mode':mode,'threshold':threshold,'detected':[],
            'corrected':[],'review':[],'scores':[],'offsets':{},'reference':'主体亮度稳定的多数帧'}
    if mode=='off':return list(frames),report
    signatures=[];colors=[];valid=[];weights=np.array([.2126,.7152,.0722])
    for i,im in enumerate(frames):
        a=np.asarray(im.convert('RGBA'));rgb=a[:,:,:3]
        mask=(a[:,:,3]>=240)&(rgb.max(axis=2)>24)
        pixels=rgb[mask].astype(float)
        if len(pixels)<32:continue
        signatures.append(np.quantile(pixels@weights,[.5,.65,.8,.9]))
        colors.append(np.quantile(pixels,[.5,.65,.8,.9],axis=0));valid.append(i)
    if len(valid)<3:
        report['note']='有效主体帧不足3帧，未自动修正';return list(frames),report
    sig=np.array(signatures);csig=np.array(colors);reference=np.median(sig,axis=0)
    brightness=np.median(sig-reference,axis=1)
    stable_indices=np.abs(brightness)<max(threshold*1.5,8)
    stable=float(np.mean(stable_indices))>=.6
    if stable:
        reference=np.median(sig[stable_indices],axis=0)
        cref=np.median(csig[stable_indices],axis=0)
    else:cref=np.median(csig,axis=0)
    result=list(frames)
    for at,i in enumerate(valid):
        current=sig[at];delta=reference-current
        shift=float(np.median(delta));color_shift=np.median(cref-csig[at],axis=0)
        luma_score=abs(shift);color_score=float(np.max(np.abs(color_shift)))
        report['scores'].append({'frame':i,'score':round(luma_score,2),'brightness':round(float(current[2]),2),'target':round(float(reference[2]),2)})
        if luma_score<threshold and color_score<max(12,threshold*2):continue
        report['detected'].append(i)
        # Reject large distribution changes caused by pose/palette rather than exposure.
        gain=1.;offset=shift;error=float(np.mean(np.abs(current+offset-reference)))
        if np.ptp(current)>12:
            slope,intercept=np.polyfit(current,reference,1)
            candidate_error=float(np.mean(np.abs(current*slope+intercept-reference)))
            if .65<=slope<=1.55 and abs(intercept)<=40 and candidate_error+1<error:
                gain=float(slope);offset=float(intercept);error=candidate_error
        coherent=np.mean(np.sign(delta)==np.sign(shift))>=.75 or luma_score<threshold
        if not stable or error>max(10,threshold*2) or abs(offset)>64 or not coherent:
            report['review'].append(i);continue
        if mode!='repair':continue
        neighbors=sorted([v for k,v in enumerate(valid) if stable_indices[k] and v!=i],key=lambda v:abs(v-i))[:3]
        repaired,patches=spatial_brightness_repair(frames[i],[frames[v] for v in neighbors],threshold)
        if not patches:
            report['review'].append(i);continue
        result[i]=repaired;report['corrected'].append(i)
        report['offsets'][str(i)]={'regions':patches}
    if not stable:report['note']='亮度分布没有稳定多数帧，建议人工确认是否为刻意变化'
    return result,report


def remove_green(a, threshold=5, softness=0, despill=True):
    f=a[:,:,:3].astype(np.float32)
    dominance=f[:,:,1]-np.maximum(f[:,:,0],f[:,:,2])
    if softness:
        alpha=np.clip((threshold+softness-dominance)/softness,0,1)*255
    else:
        alpha=np.where(dominance>threshold,0,255)
    if a.shape[2]==4: alpha=np.minimum(alpha,a[:,:,3])
    if despill:
        # Compression spill also occurs on fully opaque outline pixels. Removing
        # only semi-transparent spill left a visible green fringe with soft keys.
        background=alpha<250
        near=np.zeros_like(background)
        padded=np.pad(background,2,constant_values=False)
        for dy in range(5):
            for dx in range(5):near|=padded[dy:dy+near.shape[0],dx:dx+near.shape[1]]
        edge=(dominance>0)&(alpha>0)&near
        f[:,:,1]=np.where(edge,np.minimum(f[:,:,1],np.maximum(f[:,:,0],f[:,:,2])),f[:,:,1])
    rgba=np.dstack([f.astype(np.uint8),alpha.astype(np.uint8)])
    rgba[rgba[:,:,3]==0,:3]=0
    return rgba

def resize_sprite_stable(im, size, hard_alpha=True):
    """Area coverage avoids nearest-neighbor phase jumps on shrinking outlines.

    Premultiplied alpha keeps transparent RGB from darkening the silhouette.
    A single fixed alpha cutoff keeps pixel-art exports on an opaque pixel grid.
    """
    shrinking=size[0]<im.width or size[1]<im.height
    if not shrinking:return im.resize(size,Image.Resampling.NEAREST)
    result=im.convert('RGBa').resize(size,Image.Resampling.BOX).convert('RGBA')
    pixels=np.array(result)
    if hard_alpha:pixels[:,:,3]=np.where(pixels[:,:,3]>=128,255,0)
    pixels[pixels[:,:,3]==0,:3]=0
    return Image.fromarray(pixels)

def process_video(source, outdir, opts, progress=lambda _:None):
    outdir=Path(outdir);outdir.mkdir(parents=True,exist_ok=True)
    fps=int(opts.get('fps',10));duration=float(opts.get('duration',2));start=float(opts.get('start',0))
    size=int(opts.get('size',256));cols=int(opts.get('columns',10))
    if not 1<=fps<=30 or not .1<=duration<=15 or not 0<=start<=600 or size not in [0,64,128,256,512] or not 1<=cols<=20:
        raise ValueError('帧率、时长、开始时间或尺寸超出允许范围')
    # A total count is the public control; sample densely enough before selecting frames.
    if opts.get('continuity_mode'):
        fps=min(20,max(1,int(120/duration)))
    if opts.get('target_frame_count') and not opts.get('continuity_mode'):
        fps=max(fps,min(30,int(np.ceil(float(opts['target_frame_count'])/duration))))
    frames_n=round(fps*duration)
    native=size==0
    reader=imageio_ffmpeg.read_frames(str(source),pix_fmt='rgb24')
    try:dimensions=next(reader)['size']
    finally:reader.close()
    work=max(dimensions)
    if native:size=work
    sampling_note=None
    if opts.get('continuity_mode') and work<=2048:
        budget_fps=int((192*1024*1024)//(work*work*3)/duration)
        if 1<=budget_fps<fps:
            fps=budget_fps;frames_n=round(fps*duration)
            sampling_note=f'根据原视频尺寸及内存预算，密集采样调整为 {fps} FPS'
    if work>2048 or frames_n*work*work*3>192*1024*1024:
        raise ValueError('原始像素处理超过内存预算，请缩短片段或降低提取帧率')
    filters=f'fps={fps},'
    filters+=f'pad={work}:{work}:(ow-iw)/2:(oh-ih)/2:color=0x00ff00'
    cmd=[FF,'-v','error','-ss',str(start),'-i',str(source),'-t',str(duration),'-vf',filters,'-frames:v',str(frames_n),'-f','rawvideo','-pix_fmt','rgb24','-']
    result=subprocess.run(cmd,capture_output=True,timeout=90)
    if result.returncode: raise ValueError('无法读取视频：'+result.stderr.decode(errors='replace')[-400:])
    if len(result.stdout)% (work*work*3): raise ValueError('视频解码返回了不完整的帧')
    raw=np.frombuffer(result.stdout,np.uint8).reshape(-1,work,work,3)
    if not len(raw):raise ValueError('所选时间范围没有画面，请调整开始时间')
    warnings=[]
    if sampling_note:warnings.append(sampling_note)
    if len(raw)<frames_n:warnings.append(f'所选片段仅有{len(raw)}帧，已按实际帧数导出')
    rgba=[remove_green(a,float(opts.get('threshold',5)),float(opts.get('softness',0)),bool(opts.get('despill',True))) for a in raw]
    boxes=[Image.fromarray(a).getbbox() for a in rgba]
    if not any(boxes):raise ValueError('所有像素都被移除，请降低去绿强度（增大高级阈值）或检查视频')
    keep=[i for i in range(len(rgba)) if i not in set(opts.get('excluded',[]))]
    if not keep:raise ValueError('至少保留一帧')
    temporal={}
    if opts.get('continuity_mode'):
        # Preview explicitly re-extracts the chosen time interval, so old indexes
        # at a different sampling rate must not silently exclude unrelated frames.
        if opts.get('continuity_mode')=='walk5':
            keep,temporal=walk_five_indices([Image.fromarray(x) for x in rgba],fps)
            opts={**opts,'playback_fps':5/temporal['cycle_seconds'],'fps':fps,
                  'target_frame_count':5,'columns':5,'excluded':[],'pingpong':False}
        else:
            keep,temporal=continuous_indices([Image.fromarray(x) for x in rgba],opts.get('continuity_mode')=='loop')
            opts={**opts,'playback_fps':fps,'fps':fps,'target_frame_count':None,'excluded':[],
                  'pingpong':False}
    elif opts.get('target_frame_count'):
        count=int(opts['target_frame_count'])
        if not 1<=count<=120:raise ValueError('输出帧数必须为1–120')
        if count>len(keep):warnings.append(f'可用帧少于{count}帧，已均匀重复采样补足至{count}帧；重复画面不会增加新动作')
        keep=[keep[int(i)] for i in np.floor(np.arange(count)*len(keep)/count).astype(int)]
        opts={**opts,'playback_fps':opts.get('playback_fps') or count/(len(raw)/fps),'pingpong':False}
    progress('正在统一画布与透明边缘')
    # One bounding box for the whole clip avoids erasing intentional jumping/floating.
    valid=[b for b in boxes if b]
    if not valid:raise ValueError('保留的帧均为空')
    bbox=(min(b[0] for b in valid),min(b[1] for b in valid),max(b[2] for b in valid),max(b[3] for b in valid))
    if native or not opts.get('crop',True):bbox=(0,0,work,work)
    bw,bh=bbox[2]-bbox[0],bbox[3]-bbox[1];scale=min((size-16)/bw,(size-16)/bh)
    tw,th=max(1,round(bw*scale)),max(1,round(bh*scale))
    frames=[];allframes=[]
    source_dir=outdir/'source_frames';source_dir.mkdir(exist_ok=True)
    fd=outdir/'frames';fd.mkdir(exist_ok=True)
    for i in range(len(rgba)):
        if native:c=Image.fromarray(rgba[i])
        else:
            im=resize_sprite_stable(Image.fromarray(rgba[i]).crop(bbox),(tw,th),not opts.get('softness',0))
            c=Image.new('RGBA',(size,size));c.alpha_composite(im,((size-tw)//2,size-8-th))
        allframes.append(c)
        c.save(source_dir/f'{i:03}.png')
    frames=[allframes[i] for i in keep]
    duplicates=sum(np.array_equal(raw[i],raw[i-1]) for i in range(1,len(raw)))
    if duplicates:warnings.append(f'采样序列中有 {duplicates} 对相邻重复画面，提高帧率不会创造新的动作')
    return pack_frames(frames,outdir,opts,warnings,{'continuity_report':temporal,'resampling':'native-no-resize' if native else 'single-scale-stable-v1','crop_box':bbox,'source_frame_count':len(raw),'kept_source_indices':keep,'source_frames_available':True,'sample_fps':fps,'sample_times':[start+i/fps for i in range(len(raw))]})

def stabilize_pixel_palette(frames, loop=True):
    """One clip palette, no dithering; only replace small, isolated color deviations.

    Alpha and geometry are immutable. High-contrast moving edges are excluded.
    All decisions use original frames, never previously repaired output.
    """
    arrays=[np.array(im.convert('RGBA')) for im in frames]
    samples=[]
    for a in arrays:
        pixels=a[:,:,:3][a[:,:,3]>=240]
        if len(pixels):samples.append(pixels[::max(1,len(pixels)//8192)])
    if not samples:return frames,{'algorithm':'shared-palette-v1','colors':0,'stabilized_pixels':0}
    pixels=np.concatenate(samples)
    palette=Image.fromarray(pixels.reshape(1,-1,3)).quantize(colors=32,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
    quantized=[]
    for a in arrays:
        rgb=Image.fromarray(a[:,:,:3]).quantize(palette=palette,dither=Image.Dither.NONE).convert('RGB')
        b=np.dstack([np.array(rgb),a[:,:,3]]);b[b[:,:,3]==0,:3]=0;quantized.append(b)
    output=[];changed=0
    for i,current in enumerate(quantized):
        result=current.copy()
        if len(arrays)>=3 and (loop or 0<i<len(arrays)-1):
            prev=quantized[(i-1)%len(arrays)];nxt=quantized[(i+1)%len(arrays)]
            before=arrays[(i-1)%len(arrays)];after=arrays[(i+1)%len(arrays)];original=arrays[i]
            agreement=np.all(prev[:,:,:3]==nxt[:,:,:3],axis=2)
            opaque=(before[:,:,3]==255)&(original[:,:,3]==255)&(after[:,:,3]==255)
            close=np.max(np.abs(before[:,:,:3].astype(int)-after[:,:,:3].astype(int)),axis=2)<=10
            small=np.max(np.abs(original[:,:,:3].astype(int)-before[:,:,:3].astype(int)),axis=2)<=18
            mask=agreement&opaque&close&small
            changed+=int(np.count_nonzero(mask&np.any(result!=prev,axis=2)))
            result[mask,:3]=prev[mask,:3]
        output.append(Image.fromarray(result))
    return output,{'algorithm':'shared-palette-v1','colors':32,'stabilized_pixels':changed,'geometry_preserved':True}

def pack_frames(frames,outdir,opts,warnings=None,extra=None,apply_color=True):
    outdir=Path(outdir);outdir.mkdir(parents=True,exist_ok=True)
    fd=outdir/'frames';fd.mkdir(exist_ok=True)
    fps=float(opts.get('playback_fps') or opts.get('fps',10));size=frames[0].width
    if not .01<=fps<=1200:raise ValueError('播放帧率超出允许范围')
    cols=int(opts.get('columns',10))
    warnings=list(warnings or [])
    if opts.get('pingpong') and len(frames)>2: frames+=frames[-2:0:-1]
    if apply_color:
        if opts.get('color_algorithm')!='luminance-v3':
            opts={**opts,'color_threshold':min(float(opts.get('color_threshold',6)),6),'color_algorithm':'luminance-v3'}
        original=outdir/'color_original_frames';original.mkdir(exist_ok=True)
        for i,im in enumerate(frames):im.save(original/f'{i:03}.png')
        frames,report=stabilize_colors(frames,opts.get('color_mode','repair'),opts.get('color_threshold',6))
        extra={**(extra or {}),'color_report':report,'color_original_available':True}
        (outdir/'color_report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
        if report['corrected']:warnings.append(f'已修正 {len(report["corrected"])} 个颜色异常帧；可对照原始帧检查')
        if report['review']:warnings.append(f'{len(report["review"])} 个疑似异常帧无法可靠自动修正，已保留原样')
    if apply_color and opts.get('pixel_stable',True) and int(opts.get('size',256))!=0:
        frames,pixel_report=stabilize_pixel_palette(frames,bool(opts.get('loop',True)))
        extra={**(extra or {}),'pixel_report':pixel_report}
    for i,im in enumerate(frames):im.save(fd/f'{i:03}.png')
    atlas=Image.new('RGBA',(min(cols,len(frames))*size,math.ceil(len(frames)/cols)*size))
    cols=min(cols,len(frames))
    records=[]
    for i,im in enumerate(frames):
        x,y=(i%cols)*size,(i//cols)*size;atlas.paste(im,(x,y));records.append({'index':i,'x':x,'y':y,'w':size,'h':size})
    atlas.save(outdir/'spritesheet.png')
    name=re.sub(r'[^\w-]','_',opts.get('name','animation'))[:60] or 'animation'
    loop=bool(opts.get('loop',True))
    preview=[]
    yy,xx=np.indices((size,size));checker=np.where(((xx//16+yy//16)%2)[:,:,None],np.array([39,43,54]),np.array([31,35,45])).astype(np.uint8)
    for im in frames:
        c=Image.fromarray(checker).convert('RGBA');c.alpha_composite(im);preview.append(c.convert('RGB'))
    preview[0].save(outdir/'preview.gif',save_all=True,append_images=preview[1:],duration=round(1000/fps),loop=0 if loop else 1)
    # APNG retains true alpha for the canvas preview; GIF is a checkerboard convenience preview.
    # Browser previews repeat independently of the engine animation's loop flag.
    frames[0].save(outdir/'preview.png',save_all=True,append_images=frames[1:],duration=1000/fps,loop=0,disposal=0,blend=0)
    seam=float(np.mean(np.abs(np.array(frames[0],float)-np.array(frames[-1],float))))
    if seam>15:warnings.append('首尾画面差异较大，建议检查循环衔接或使用往返播放')
    if any(im.getbbox() is None for im in frames):warnings.append('存在透明空帧，请检查并排除')
    meta={'name':name,'fps':fps,'loop':loop,'frame_count':len(frames),'duration':len(frames)/fps,'frame_width':size,'frame_height':size,'columns':cols,'frames':records,'warnings':warnings,'settings':opts,**(extra or {})}
    (outdir/'animations.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
    lines=[f'[gd_resource type="SpriteFrames" load_steps={len(frames)+2} format=3]','', '[ext_resource type="Texture2D" path="spritesheet.png" id="1"]','']
    for rec in records:
        i=rec['index'];lines +=[f'[sub_resource type="AtlasTexture" id="Atlas_{i}"]','atlas = ExtResource("1")',f'region = Rect2({rec["x"]}, {rec["y"]}, {size}, {size})','']
    entries=',\n'.join('{"duration": 1.0, "texture": SubResource("Atlas_%d")}'%i for i in range(len(frames)))
    lines +=['[resource]',f'animations = [{{"frames": [{entries}], "loop": {str(loop).lower()}, "name": &"{name}", "speed": {float(fps)}}}]']
    (outdir/'sprite_frames.tres').write_text('\n'.join(lines),encoding='utf-8')
    (outdir/'README.txt').write_text('将整个文件夹一起放入 Godot 项目。把 sprite_frames.tres 赋给 AnimatedSprite2D.sprite_frames；纹理过滤设为 Nearest。PNG/JSON 也可用于其他引擎。透明图像采用固定整体裁框，保留原有漂浮与跳跃。\n请人工检查肢体、循环及绿色主体误抠。',encoding='utf-8')
    with zipfile.ZipFile(outdir/'spritesheet.zip','w',zipfile.ZIP_DEFLATED) as z:
        for f in outdir.iterdir():
            if f.is_file() and f.suffix!='.zip':z.write(f,f.name)
        for f in fd.glob('*.png'):z.write(f,'frames/'+f.name)
    return meta

def process_sheet(source,outdir,opts):
    cols=int(opts['columns']);rows=int(opts['rows']);count=int(opts['count']);size=int(opts.get('size',256));fps=int(opts.get('fps',10))
    if not 1<=cols<=20 or not 1<=rows<=20 or not 1<=count<=min(200,cols*rows) or size not in [0,64,128,256,512] or not 1<=fps<=30:raise ValueError('请检查行列、帧数、尺寸和帧率')
    im=Image.open(source).convert('RGBA');warnings=[]
    if im.getchannel('A').getextrema()[0]==255:warnings.append('图像没有透明像素，请检查背景是否需要额外处理')
    if opts.get('ai_review'):warnings.append('AI 改造结果，请对照原版检查逐帧动作、跨格和角色一致性')
    if im.width<cols*8 or im.height<rows*8:raise ValueError('精灵图分辨率过低')
    if im.width%cols or im.height%rows:warnings.append('图像尺寸不能整除网格，已按等比例边界切分；请逐帧检查是否跨格')
    frames=[]
    for i in range(count):
        x,y=i%cols,i//cols
        tile=im.crop((round(x*im.width/cols),round(y*im.height/rows),round((x+1)*im.width/cols),round((y+1)*im.height/rows)))
        tile.thumbnail((size,size),Image.Resampling.NEAREST)
        frame=Image.new('RGBA',(size,size));frame.alpha_composite(tile,((size-tile.width)//2,(size-tile.height)//2));frames.append(frame)
    return pack_frames(frames,outdir,{**opts,'loop':True},warnings,{'source_frame_count':count,'kept_source_indices':list(range(count))})
