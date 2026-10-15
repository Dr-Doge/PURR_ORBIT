extends Control
## Art assembly inspector, NOT the customer-service gameplay controller.
@export_enum("calico", "robot", "nails") var view: String = "calico"
const ART := "res://Art/grooming_demo_v1/"
const CANVAS := Vector2(1920, 1080)
var state: String = "dirty"
var cleaned: float = 0.0
var background_only: bool = false
var index: Dictionary = {}
var textures: Dictionary = {}
var toolbar: HBoxContainer

func _ready() -> void:
 texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
 index = JSON.parse_string(FileAccess.get_file_as_string(ART + "atlas_index.json"))
 for id in index.images:
  var entry: Dictionary = index.images[id]
  textures[entry.file] = load(ART + str(entry.file))
 toolbar = HBoxContainer.new()
 toolbar.position = Vector2(16, 16)
 add_child(toolbar)
 for choice in ["calico", "robot", "nails"]:
  var button := Button.new()
  button.text = {"calico":"三花猫", "robot":"机器猫", "nails":"猫爪修甲"}[choice]
  button.pressed.connect(select_view.bind(choice))
  toolbar.add_child(button)
 for option in ["dirty", "half", "clean", "happy", "discomfort", "reference"]:
  var button := Button.new()
  button.text = {"dirty":"待处理", "half":"局部清理", "clean":"干净", "happy":"满意", "discomfort":"不适", "reference":"整图脏态参考"}[option]
  button.pressed.connect(select_state.bind(option))
  toolbar.add_child(button)
 resized.connect(queue_redraw)
 queue_redraw()

func select_view(value: String) -> void:
 view = value
 select_state("dirty")

func select_state(value: String) -> void:
 state = value
 cleaned = 0.5 if value == "half" else (1.0 if value in ["clean", "happy"] else 0.0)
 queue_redraw()

func sprite_info(name: String) -> Dictionary:
 return index.sprites[name]

func sprite_source(name: String) -> Rect2:
 var item: Dictionary = sprite_info(name)
 var r: Array = item.region
 var b: Array = item.alpha_bbox_local
 return Rect2(float(r[0])+float(b[0]), float(r[1])+float(b[1]), float(b[2])-float(b[0]), float(b[3])-float(b[1]))

func sprite_texture(name: String) -> Texture2D:
 return textures[str(sprite_info(name).file)]

func fit_sprite(name: String, box: Rect2) -> Rect2:
 var source: Rect2 = sprite_source(name)
 var factor: float = minf(box.size.x/source.size.x, box.size.y/source.size.y)
 var drawn: Vector2 = source.size * factor
 var dest := Rect2(box.position + Vector2((box.size.x-drawn.x)/2.0, box.size.y-drawn.y), drawn)
 draw_texture_rect_region(sprite_texture(name), dest, source)
 return dest

func stamp(name: String, center: Vector2, width: float, cutoff: float = -1.0) -> void:
 var source := sprite_source(name)
 var height: float = width * source.size.y / source.size.x
 var dest := Rect2(center-Vector2(width,height)/2.0, Vector2(width,height))
 if cutoff >= 0.0:
  var remaining := dest.intersection(Rect2(cutoff,0.0,1920.0-cutoff,1080.0))
  if not remaining.has_area(): return
  var scale_factor: Vector2 = source.size / dest.size
  source = Rect2(source.position+(remaining.position-dest.position)*scale_factor, remaining.size*scale_factor)
  dest = remaining
 draw_texture_rect_region(sprite_texture(name),dest,source)

func _draw() -> void:
 if index.is_empty(): return
 draw_set_transform(Vector2.ZERO,0.0,size/CANVAS)
 draw_texture_rect(textures["background_1920x1080.png"],Rect2(Vector2.ZERO,CANVAS),false)
 if background_only: return
 if view == "nails":
  draw_paw()
 else:
  draw_body()
 var font: Font = ThemeDB.fallback_font
 draw_string(font,Vector2(40,1025),"素材组装预览 · 不含服务判定、评分或报酬结算",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color.WHITE)

func draw_body() -> void:
 var name: String = view + "_clean"
 if state in ["happy", "discomfort"]: name = view + "_" + state
 elif state == "reference": name = view + "_dirty_reference"
 var box := Rect2(160,140,1600,780)
 var actor: Rect2 = fit_sprite(name,box)
 if state in ["dirty", "half"]:
  var names: Array = ["dust","dust","knot","trash","dust","dust"] if view == "calico" else ["oil","fingerprints","soot","tar","oil","fingerprints"]
  var points: Array = [Vector2(0.46,0.57),Vector2(0.62,0.59),Vector2(0.70,0.46),Vector2(0.78,0.65),Vector2(0.53,0.76),Vector2(0.73,0.76)]
  var cutoff: float = actor.position.x + actor.size.x * cleaned
  for i in range(names.size()):
   stamp(str(names[i]),actor.position+actor.size*points[i],140.0 if i in [2,3] else 210.0,cutoff)
  var contact := actor.position + actor.size*Vector2(0.56 if state == "half" else 0.90,0.53)
  stamp("comb" if view == "calico" else "cloth",contact,170.0)
  if state == "half":
   stamp("fur_white" if view == "calico" else "oil_fleck",contact+Vector2(-110,-100),65.0)
 elif state in ["clean", "happy"]:
  stamp("sparkle",actor.position+actor.size*Vector2(0.84,0.23),80.0)

func draw_paw() -> void:
 fit_sprite("paw_base",Rect2(490,240,930,780))
 var name: String = "claw_long"
 if state == "half": name = "claw_shallow"
 elif state in ["clean", "happy"]: name = "claw_perfect"
 elif state == "discomfort": name = "claw_deep"
 var roots: Array = [Vector2(655,595),Vector2(855,444),Vector2(1070,444),Vector2(1260,595)]
 var base_height: float = sprite_source("claw_long").size.y
 var factor: float = 280.0/base_height
 for root in roots:
  var source := sprite_source(name)
  var drawn: Vector2 = source.size * factor
  draw_texture_rect_region(sprite_texture(name),Rect2(root-Vector2(drawn.x/2.0,drawn.y),drawn),source)
  if state in ["dirty", "half"]:
   var a: Vector2 = root+Vector2(-70,-140)
   for j in range(7):
    draw_line(a+Vector2(j*20,0),a+Vector2(j*20+10,0),Color(0.25,0.9,0.7),4.0)
  else:
   stamp("nail_tip",root+Vector2(-110,90),55.0)
 stamp("clipper",Vector2(1560,580),240.0)
