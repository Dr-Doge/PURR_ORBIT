extends RefCounted
const ROOT := "res://Art/grooming_demo_v1/"
var index: Dictionary
var images: Dictionary = {}
var textures: Dictionary = {}
var sheets: Dictionary = {}

func _init() -> void:
 index=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"atlas_index.json"))

func source(name: String) -> Rect2i:
 var entry: Dictionary=index.sprites[name]
 var r: Array=entry.region
 var b: Array=entry.alpha_bbox_local
 return Rect2i(int(r[0])+int(b[0]),int(r[1])+int(b[1]),int(b[2])-int(b[0]),int(b[3])-int(b[1]))

func image(name: String) -> Image:
 if not images.has(name):
  var entry: Dictionary=index.sprites[name]
  var path: String=ROOT+str(entry.file)
  if not sheets.has(path):
   var imported: Texture2D=load(path)
   var pixels: Image=imported.get_image()
   if pixels.is_compressed():pixels.decompress()
   sheets[path]=pixels
  var raw: Image=sheets[path]
  images[name]=raw.get_region(source(name))
 return images[name]

func texture(name: String) -> Texture2D:
 if not textures.has(name): textures[name]=ImageTexture.create_from_image(image(name))
 return textures[name]

func body_rect(kind: String) -> Rect2:
 var raw: Image=image(kind+"_clean")
 var box: Rect2=preload("res://scripts/prototype_grooming/config.gd").BODY_BOX
 var factor: float=minf(box.size.x/raw.get_width(),box.size.y/raw.get_height())
 var size: Vector2=Vector2(raw.get_size())*factor
 return Rect2(box.position+Vector2((box.size.x-size.x)/2.0,box.size.y-size.y),size)
