"""Read-only PNG inspection and resource creation; generated PNGs stay unchanged."""
from pathlib import Path
from PIL import Image
import hashlib,json
root=Path(__file__).resolve().parents[1]/'Art/grooming_environment_v1'
manifest={}
for name in ['room_background','grooming_table','grey_paw']:
    path=root/(name+'.png')
    image=Image.open(path).convert('RGBA')
    alpha=image.getchannel('A')
    box=alpha.point(lambda a:255 if a>16 else 0).getbbox()
    manifest[name]={'file':path.name,'size':list(image.size),'visible_region':list(box),'alpha_range':list(alpha.getextrema()),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
    resource=root/'resources'/(name+'.tres');resource.parent.mkdir(exist_ok=True)
    resource.write_text('[gd_resource type="AtlasTexture" load_steps=2 format=3]\n[ext_resource type="Texture2D" path="res://Art/grooming_environment_v1/'+path.name+'" id="1"]\n[resource]\natlas = ExtResource("1")\nregion = Rect2(%d, %d, %d, %d)\nfilter_clip = true\n'%(box[0],box[1],box[2]-box[0],box[3]-box[1]),encoding='utf-8')
(root/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(manifest,ensure_ascii=False))
