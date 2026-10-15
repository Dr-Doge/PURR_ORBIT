extends "res://scripts/prototype_grooming/assets.gd"
const FUR_ROOT="res://Art/grooming_fur_v1/"
const ENV_ROOT="res://Art/grooming_environment_v1/"
var fur_index: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(FUR_ROOT+"atlas_index.json"))
var environment_index: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ENV_ROOT+"manifest.json"))
var subject_scale: float=1.0

func image(name: String) -> Image:
 var key: String="cat_clean" if name.begins_with("calico_") else name
 if name=="paw_base":key="grey_paw"
 if fur_index.has("sprites") and fur_index.sprites.has(key):
  if not images.has(name):
   var e: Dictionary=fur_index.sprites[key];var r: Array=e.region
   var raw: Image=read_sheet(FUR_ROOT+str(e.file))
   images[name]=raw.get_region(Rect2i(r[0],r[1],r[2],r[3]))
  return images[name]
 if key in ["room_background","grooming_table","grey_paw"]:
  if not images.has(name):
   var raw: Image=read_sheet(ENV_ROOT+key+".png")
   if key=="grey_paw":
    var r: Array=environment_index.grey_paw.visible_region
    images[name]=raw.get_region(Rect2i(r[0],r[1],r[2]-r[0],r[3]-r[1]))
   else:images[name]=raw
  return images[name]
 return super.image(name)

func read_sheet(path: String) -> Image:
 if not sheets.has(path):
  var tex: Texture2D=load(path);var raw: Image=tex.get_image()
  if raw.is_compressed():raw.decompress()
  sheets[path]=raw
 return sheets[path]

func body_rect(cat_kind: String) -> Rect2:
 var raw: Image=image(cat_kind+"_clean")
 var box:=Rect2(100,105,1720,870)
 var factor: float=minf(box.size.x/raw.get_width(),box.size.y/raw.get_height())
 var drawn:=Vector2(raw.get_size())*factor*subject_scale
 return Rect2(box.position+Vector2((box.size.x-drawn.x)/2.0,box.size.y-drawn.y),drawn)
