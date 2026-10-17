extends "res://scripts/prototype_grooming/assets.gd"
const FUR_ROOT="res://Art/grooming_fur_v1/"
const ENV_ROOT="res://Art/grooming_environment_v1/"
var fur_index: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(FUR_ROOT+"atlas_index.json"))
var fall_index: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(FUR_ROOT+"fall_variants.json"))
var environment_index: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ENV_ROOT+"manifest.json"))
var subject_scale: float=1.0
var pigment: ImageTexture
var authored_sources: Dictionary={}
var presentation: Resource=preload("res://Art/grooming_environment_v1/grooming_presentation.tres")

func configure_presentation(value: Resource) -> void:
 presentation=value;images.clear();textures.clear();authored_sources.clear();pigment=null

func coat_reference() -> Texture2D:
 if pigment!=null:return pigment
 # Runtime-only pigment field. Keep source PNG untouched; exclude its black
 # outline from colour matching and smoothly extend nearby actual fur colours.
 var field: Image=image("calico_clean").duplicate()
 field.resize(256,128,Image.INTERPOLATE_BILINEAR)
 var known:=PackedByteArray();known.resize(256*128)
 for y in range(128):
  for x in range(256):
   var p: Color=field.get_pixel(x,y)
   var valid: bool=p.a>.75 and maxf(p.r,maxf(p.g,p.b))>.46
   known[y*256+x]=int(valid);p.a=float(valid);field.set_pixel(x,y,p)
 for iteration in range(24):
  var next: Image=field.duplicate();var next_known: PackedByteArray=known.duplicate();var changed: int=0
  for y in range(128):
   for x in range(256):
    if known[y*256+x]:continue
    var color:=Color(0,0,0,0);var count: int=0
    for dy in range(-1,2):
     for dx in range(-1,2):
      var at:=Vector2i(x+dx,y+dy)
      if at.x<0 or at.y<0 or at.x>=256 or at.y>=128 or known[at.y*256+at.x]==0:continue
      color+=field.get_pixelv(at);count+=1
    if count>0:
     color/=float(count);color.a=1;next.set_pixel(x,y,color);next_known[y*256+x]=1;changed+=1
  field=next;known=next_known
  if changed==0:break
 pigment=ImageTexture.create_from_image(field)
 return pigment

func image(name: String) -> Image:
 var replacement: Texture2D=null
 if name.begins_with("calico_") or name=="cat_clean":replacement=presentation.cat_texture
 elif name=="room_background":replacement=presentation.room_texture
 elif name=="grooming_table":replacement=presentation.table_texture
 if replacement!=null:
  if not images.has(name):
   var raw: Image=replacement.get_image()
   if raw.is_compressed():raw.decompress()
   images[name]=raw
  return images[name]
 if fall_index.sprites.has(name):
  if not images.has(name):
   var r: Array=fall_index.sprites[name].region
   images[name]=read_sheet(FUR_ROOT+"fur_fall_fx.png").get_region(Rect2i(r[0],r[1],r[2],r[3]))
  return images[name]
 var key: String="cat_clean" if name.begins_with("calico_") else name
 if name=="paw_base":key="grey_paw"
 if fur_index.has("sprites") and fur_index.sprites.has(key):
  if not images.has(name):
   var e: Dictionary=fur_index.sprites[key];var r: Array=e.region
   if e.role in ["body_patch","contour_overlay"]:
    # Recut resources keep the original canvas; their alpha excludes fragments
    # of neighbouring sprites that a rectangular atlas region used to include.
    var cut: Image=load(FUR_ROOT+e.resource).get_image()
    if cut.is_compressed():cut.decompress()
    images[name]=cut
   else:
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

func fall_variants(palette: String,role: String) -> Array:
 var names: Array=[]
 for name in fall_index.sprites:
  var entry: Dictionary=fall_index.sprites[name]
  if entry.palette==palette and entry.role==role:names.append(name)
 return names

func read_sheet(path: String) -> Image:
 if not sheets.has(path):
  var tex: Texture2D=load(path);var raw: Image=tex.get_image()
  if raw.is_compressed():raw.decompress()
  sheets[path]=raw
 return sheets[path]

func body_rect(cat_kind: String) -> Rect2:
 var raw: Image=image(cat_kind+"_clean")
 var box: Rect2=presentation.cat_fit_rect
 var factor: float=minf(box.size.x/raw.get_width(),box.size.y/raw.get_height())
 var drawn:=Vector2(raw.get_size())*factor*subject_scale
 return Rect2(box.position+Vector2((box.size.x-drawn.x)/2.0,box.size.y-drawn.y),drawn)
