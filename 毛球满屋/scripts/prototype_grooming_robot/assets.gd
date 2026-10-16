extends "res://scripts/prototype_grooming/assets.gd"
## Reuse original robot/cloth/dirt atlas, with the current leather table environment.
const ENV="res://Art/grooming_environment_v1/"
func image(name: String) -> Image:
 if name in ["room_background","grooming_table"]:
  if not images.has(name):
   var texture: Texture2D=load(ENV+name+".png")
   var raw: Image=texture.get_image()
   if raw.is_compressed():raw.decompress()
   images[name]=raw
  return images[name]
 return super.image(name)
func body_rect(cat_kind: String) -> Rect2:
 var raw: Image=image(cat_kind+"_clean")
 var box:=Rect2(100,105,1720,870)
 var scale_factor: float=minf(box.size.x/raw.get_width(),box.size.y/raw.get_height())
 var drawn: Vector2=Vector2(raw.get_size())*scale_factor
 return Rect2(box.position+Vector2((box.size.x-drawn.x)*.5,box.size.y-drawn.y),drawn)
