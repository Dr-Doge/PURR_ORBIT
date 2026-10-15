"""Read generated PNGs; write atlas metadata/resources without editing any image."""
from pathlib import Path
from collections import deque, Counter
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / 'Art' / 'grooming_fur_v1'
SHEETS = {
 'cat_clean.png':(1,1,['cat_clean'],'base'),
 'body_tufts.png':(4,3,['gray_ruffle','gray_wide','gray_fold','gray_cross','cream_ruffle','cream_wide','cream_fold','cream_cross','mixed_ruffle','mixed_wide','mixed_fold','mixed_cross'],'body_patch'),
 'contour_tufts.png':(4,2,['edge_gray_shoulder','edge_gray_back','edge_gray_flank','edge_gray_tail','edge_cream_cheek','edge_cream_belly','edge_cream_leg','edge_cream_tail'],'contour_overlay'),
 'specials.png':(3,2,['knot_gray','knot_cream','flea_idle','dust_gray','dust_cream','flea_hop'],'special'),
 'fur_fall_fx.png':(4,2,['fall_gray_peel','fall_gray_curl','fall_mixed_peel','fall_gray_wisps','fall_cream_peel','fall_cream_curl','fall_mixed_flip','fall_cream_wisps'],'visual_only'),
}

def components(alpha, width, height):
 # Only detect visible connected islands, leaving original alpha/RGB untouched.
 values=bytearray(alpha)
 result=[]
 for origin in range(len(values)):
  if values[origin]<=16:continue
  values[origin]=0; todo=deque([origin]); count=0
  left=width;top=height;right=bottom=0;sx=sy=0
  while todo:
   at=todo.popleft();y,x=divmod(at,width)
   count+=1;sx+=x;sy+=y
   left=min(left,x);top=min(top,y);right=max(right,x);bottom=max(bottom,y)
   for nxt in ((at-1 if x else -1),(at+1 if x+1<width else -1),(at-width if y else -1),(at+width if y+1<height else -1)):
    if nxt>=0 and values[nxt]>16:values[nxt]=0;todo.append(nxt)
  if count>=128:result.append((left,top,right+1,bottom+1,sx/count,sy/count,count))
 return result

def main():
 (ROOT/'resources').mkdir(exist_ok=True)
 manifest={'status':'candidate art; not integrated into Demo','method':'built-in imagegen; PNGs unmodified','alpha_component_threshold':16,'sprites':{},'files':{}}
 for file,(cols,rows,names,role) in SHEETS.items():
  im=Image.open(ROOT/file).convert('RGBA');width,height=im.size
  alpha=im.getchannel('A').tobytes()
  assert min(alpha)==0 and max(alpha)>=250, file+' lacks usable alpha range'
  islands=components(alpha,width,height)
  groups=[[] for _ in names]
  for island in islands:
   col=min(cols-1,int(island[4]/width*cols));row=min(rows-1,int(island[5]/height*rows))
   groups[row*cols+col].append(island)
  for name,group in zip(names,groups):
   assert group, (file,name,'empty cell')
   # Keep actual silhouette even when it extends beyond the nominal AI grid cell.
   left=max(0,min(x[0] for x in group)-4);top=max(0,min(x[1] for x in group)-4)
   right=min(width,max(x[2] for x in group)+4);bottom=min(height,max(x[3] for x in group)+4)
   rect=[left,top,right-left,bottom-top]
   manifest['sprites'][name]={'file':file,'region':rect,'role':role,'resource':'resources/'+name+'.tres','anchor':'center' if role!='contour_overlay' else 'attach edge inward; outer hair tips outward'}
   resource='[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n[ext_resource type="Texture2D" path="res://Art/grooming_fur_v1/'+file+'" id="1"]\n\n[resource]\natlas = ExtResource("1")\nregion = Rect2('+', '.join(map(str,rect))+')\nfilter_clip = true\n'
   (ROOT/'resources'/f'{name}.tres').write_text(resource,encoding='utf-8',newline='\n')
  colors=Counter()
  for pixel in im.get_flattened_data():
   if pixel[3]>=220:colors[tuple((v//8)*8 for v in pixel[:3])]+=1
  manifest['files'][file]={'size':[width,height],'mode':im.mode,'alpha_range':[min(alpha),max(alpha)],'transparent_pixels':alpha.count(0),'opaque_pixels':alpha.count(255),'detected_islands':len(islands),'sprite_count':len(names),'main_colors':[list(c) for c,_ in colors.most_common(8)]}
 manifest['sprite_count']=len(manifest['sprites'])
 (ROOT/'atlas_index.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
 print('Generated',manifest['sprite_count'],'AtlasTexture resources; all 5 PNGs have true alpha. No PNG pixels changed.')

if __name__=='__main__':main()
