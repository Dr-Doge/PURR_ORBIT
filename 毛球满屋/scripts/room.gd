extends Control
signal facility_selected(id: int)
signal worker_selected(id: int)
signal gacha_selected
signal build_requested(kind: String,at: Vector2)
signal notice(text: String)
const D = preload("res://scripts/data.gd")
const FEED_TEXTURE = preload("res://Art/Feed.png")
const LIGHT_TEXTURE = preload("res://Art/Light.png")
const Backdrop = preload("res://scripts/station_backdrop.gd")
# Only presentation coordinates change; simulation positions and ranges stay intact.
const ART_FLOOR = Rect2(94,151,934,574)
var backdrop
var harvest_art
var static_outlines
var token_effect
var model
var interactive: bool = false
var placing: String = ""
var moving_id: int = -1
var dragging: int = -1
var hover: int = -1
var pointer := Vector2.ZERO
var previous := Vector2.ZERO
var clock: float = 0.0
var effects: Array = []
var reduced: bool = false
var font := SystemFont.new()
const INK = Color("e3efef")
const MINT = Color("91e2c6")
const GOLD = Color("f3ca86")
const GACHA_POS = Vector2(1190,352)
var cat_visuals = preload("res://scripts/cat_visuals.gd").new()
func _ready() -> void:
 font.font_names = PackedStringArray(["Microsoft YaHei","Segoe UI"])
 clip_contents = true
 backdrop = Backdrop.new()
 backdrop.show_behind_parent = true
 add_child(backdrop)
 static_outlines=preload("res://scripts/static_cat_outline.gd").new()
 static_outlines.show_behind_parent=true
 add_child(static_outlines)
 resized.connect(layout_backdrop)
 layout_backdrop()
 harvest_art=preload("res://scripts/harvest_art.gd").new()
 add_child(harvest_art)
 var token_layer:=CanvasLayer.new();token_layer.layer=20;add_child(token_layer)
 token_effect=preload("res://scripts/token_effect.gd").new();token_effect.room=self;token_layer.add_child(token_effect)
 mouse_exited.connect(func(): hover = -1)
func stage_scale() -> float:
 return minf(size.x/Backdrop.DESIGN_SIZE.x,size.y/Backdrop.DESIGN_SIZE.y)
func stage_origin() -> Vector2:
 return (size-Backdrop.DESIGN_SIZE*stage_scale())/2.0
func layout_backdrop() -> void:
 backdrop.position=stage_origin()
 backdrop.size=Backdrop.DESIGN_SIZE*stage_scale()
func project(at: Vector2) -> Vector2:
 return ART_FLOOR.position+(at-D.FLOOR.position)*ART_FLOOR.size/D.FLOOR.size
func screen_position(at: Vector2) -> Vector2:
 return stage_origin()+project(at)*stage_scale()
func object_transform(at: Vector2) -> void:
 var scale_factor: float = stage_scale()*0.9
 draw_set_transform(screen_position(at)-at*scale_factor,0,Vector2.ONE*scale_factor)
func stage_transform() -> void:
 draw_set_transform(stage_origin(),0,Vector2.ONE*stage_scale())
func world(at: Vector2) -> Vector2:
 var stage: Vector2 = (at-stage_origin())/stage_scale()
 return D.FLOOR.position+(stage-ART_FLOOR.position)*D.FLOOR.size/ART_FLOOR.size
func text(at: Vector2,value: String,sz: int = 16,color: Color = INK) -> void:
 draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,color)
func panel(rect: Rect2,color: Color,border: Color = Color.TRANSPARENT,radius: int = 6) -> void:
 var style := StyleBoxFlat.new()
 style.bg_color = color; style.set_corner_radius_all(radius)
 if border.a > 0: style.border_color = border; style.set_border_width_all(2)
 draw_style_box(style,rect)
func ellipse(at: Vector2,radius: Vector2,color: Color) -> void:
 var pts := PackedVector2Array()
 for i in range(32): pts.append(at+Vector2(cos(TAU*i/32),sin(TAU*i/32))*radius)
 draw_colored_polygon(pts,color)
func consume_event(e: Dictionary) -> void:
 if e.kind == "ring":return # Static-cat feedback now lives on its flashing outline.
 var item: Dictionary = e.duplicate(true)
 item.age = 0.0
 effects.append(item)
func step(dt: float) -> void:
 clock += dt
 if backdrop != null: backdrop.step(dt)
 if model != null: cat_visuals.step(model,dt)
 if static_outlines != null and model != null:static_outlines.update_outlines(self)
 for e in effects.duplicate():
  e.age += dt
  if e.age > (2.1 if e.kind == "token" else 1.7): effects.erase(e)
 while effects.size() > 90: effects.pop_front()
 if harvest_art != null and model != null: harvest_art.update_art(self)
 if token_effect != null:token_effect.queue_redraw()
 queue_redraw()
func reset_pointer() -> void:
 hover = -1
 if dragging >= 0:
  var c: Dictionary = model.cat(dragging)
  if not c.is_empty(): c.dragging = false
 dragging = -1
func cat_at(at: Vector2) -> int:
 var nearest: float = 42
 var found: int = -1
 for c in model.cats:
  var distance: float = c.pos.distance_to(at)
  if distance < nearest: found = c.id; nearest = distance
 return found
func station_at(at: Vector2) -> int:
 for f in model.facilities:
  if f.pos.distance_to(at) <= (88 if f.kind == "sun" else 58): return f.id
 return -1
func _get_cursor_shape(at: Vector2) -> int:
 if not interactive or model == null or dragging >= 0 or placing != "" or moving_id >= 0:
  return CURSOR_ARROW
 var id: int=cat_at(world(at))
 if id>=0:
  var c: Dictionary=model.cat(id)
  if c.station == -1 and not c.dragging:return CURSOR_CROSS
 return CURSOR_ARROW
func _gui_input(event: InputEvent) -> void:
 if not interactive: return
 if event is InputEventMouseMotion:
  pointer = world(event.position)
  if dragging >= 0:
   var c: Dictionary = model.cat(dragging)
   if not c.is_empty(): c.pos = model.clamp_position(pointer)
  elif placing == "" and moving_id < 0:
   var id: int = cat_at(pointer)
   if id >= 0 and id == hover: model.pet(id,pointer.distance_to(previous))
   hover = id
  previous = pointer
 elif event is InputEventMouseButton:
  pointer = world(event.position)
  if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
   placing = ""; moving_id = -1; reset_pointer(); notice.emit("已取消操作"); accept_event(); return
  if event.button_index != MOUSE_BUTTON_LEFT: return
  if event.pressed:
   if placing != "" or moving_id >= 0:
    if not D.FLOOR.has_point(pointer): notice.emit("请放在舱室地板范围内"); return
    for f in model.facilities:
     if f.id != moving_id and f.pos.distance_to(pointer) < 120: notice.emit("设备之间留一点空间"); return
    if moving_id >= 0:
     var f: Dictionary = model.facility(moving_id)
     f.pos = model.clamp_position(pointer)
     for c in model.occupants(f.id): c.pos = f.pos+Vector2(0,40); c.dest = c.pos
     moving_id = -1
    else:
     var key: String = placing; placing = ""; build_requested.emit(key,pointer)
    accept_event(); return
   var id: int = cat_at(pointer)
   if id >= 0:
    dragging = id
    var c: Dictionary = model.cat(id)
    c.dragging = true; c.pet = 0.0
    accept_event(); return
   for w in model.workers:
    if w.pos.distance_to(pointer) < 25: worker_selected.emit(w.id); accept_event(); return
   var fid: int = station_at(pointer)
   if fid >= 0: facility_selected.emit(fid); accept_event(); return
   if model.gacha_ready and pointer.distance_to(GACHA_POS) < 64: gacha_selected.emit(); accept_event(); return
  elif dragging >= 0:
   var id: int = dragging; dragging = -1
   var fid: int = station_at(pointer)
   model.move_cat(id,pointer)
   if fid >= 0:
    var f: Dictionary = model.facility(fid)
    if f.kind in ["sun","arcade","altar"]:
     if not model.assign(id,fid): notice.emit(model.error)
   accept_event()
 queue_redraw()
func _draw() -> void:
 if model == null or size.x <= 0: return
 for f in model.facilities:
  object_transform(f.pos); draw_facility(f)
 if model.gacha_ready:
  object_transform(GACHA_POS); draw_gacha()
 var ordered: Array = model.cats.duplicate()
 ordered.sort_custom(func(a: Dictionary,b: Dictionary): return a.pos.y < b.pos.y)
 for c in ordered:
  object_transform(c.pos); draw_cat(c)
 for w in model.workers:
  object_transform(w.pos); draw_worker(w)
 if interactive and model.harvests<2 and not model.cats.is_empty():
  object_transform(model.cats[0].pos)
  var at: Vector2=model.cats[0].pos+Vector2(0,-80)
  text(at+Vector2(-57,-8),"← 来回摸我 →",18,GOLD)
  draw_line(at+Vector2(0,8),at+Vector2(0,26+sin(clock*4)*5),GOLD,3)
 for e in effects:
  if e.kind == "token":continue
  object_transform(e.pos)
  var alpha: float = clampf(1.0-e.age/1.7,0,1)
  if e.kind == "ring": draw_arc(e.pos,e.radius*minf(1,e.age*3),0,TAU,50,Color(MINT,1-e.age/0.8),3)
  elif e.kind == "coin":
   var at: Vector2=e.pos+Vector2(0,-60-sin(minf(1,e.age)*PI)*35)
   var width: float=14*maxf(0.12,absf(cos(e.age*18))) if e.age<0.65 else 14.0
   ellipse(at,Vector2(width,14),Color(GOLD,alpha))
   if e.age>=0.65:text(at+Vector2(-65,-25),e.text,16,Color(GOLD,alpha))
  elif e.kind == "hit":
   draw_line(e.pos+Vector2(-25,-35),e.pos+Vector2(25,5),Color(GOLD,alpha),4)
   draw_line(e.pos+Vector2(25,-35),e.pos+Vector2(-25,5),Color(GOLD,alpha),4)
  else:
   var color: Color = GOLD if e.kind in ["token","coin","prize"] else MINT
   text(e.pos+Vector2(-25,-48-e.age*34),e.get("text",""),17,Color(color,alpha))
 object_transform(pointer)
 if dragging >= 0: text(pointer+Vector2(28,-30),"松开：放下 / 送入设施",16,GOLD)
 if placing != "" or moving_id >= 0:
  var kind: String = placing if placing != "" else model.facility(moving_id).kind
  draw_arc(pointer,200 if kind=="feeder" else 80,0,TAU,50,MINT,2)
  panel(Rect2(pointer-Vector2(45,35),Vector2(90,70)),Color(0.5,0.9,0.8,0.18),MINT)
  text(pointer+Vector2(-65,-48),D.title(kind)+" · 点击摆放",17,MINT)
 elif hover >= 0:
  var c: Dictionary = model.cat(hover)
  if not c.is_empty():
   var desc: String = "%s · %d 层 · 收割 %.1f 毛球" % [D.title(c.kind),c.layers,model.harvest_value(c)]
   stage_transform()
   panel(Rect2(295,735,690,32),Color("101f2b"),Color("52796e"))
   text(Vector2(310,757),desc,16,MINT)
func cat_extent(c: Dictionary, animate: bool = true) -> float:
 var extent: float=100.0*(1.35 if c.kind=="giant" else 1.0)*(1+minf(c.layers,D.MAX_LAYERS)*D.CAT_LAYER_SIZE_STEP)
 if c.kind=="lucky":extent*=1.342
 if animate:extent*=1.0+D.CAT_PULSE_AMOUNT*sin(PI*clampf(c.pop/D.CAT_PULSE_DURATION,0.0,1.0))
 return extent
func cat_rect(c: Dictionary) -> Rect2:
 var extent: float=cat_extent(c)
 # Anchor the opaque foot pixels, including during the growth pulse.
 return Rect2(c.pos+Vector2(-extent/2.0,26.0-extent*cat_visuals.foot_anchor(c.id)),Vector2.ONE*extent)
func draw_cat(c: Dictionary) -> void:
 var at: Vector2=c.pos
 var px: float=4.0*cat_extent(c)/100.0
 var color:=Color("8cdf8e") if c.kind=="alien" else Color.WHITE
 ellipse(c.pos+Vector2(0,26),Vector2(31*cat_extent(c,false)/100.0,10),Color(0.02,0.08,0.13,0.25))
 var image: Texture2D=cat_visuals.texture(c.id)
 var rect: Rect2=cat_rect(c)
 if cat_visuals.flipped(c.id):rect.size.x=-rect.size.x
 draw_texture_rect(image,rect,false,color)
 if c.kind == "alien":
  for side in [-1,1]:
   draw_line(at+Vector2(side*18,-22),at+Vector2(side*25,-45),color,3)
   draw_circle(at+Vector2(side*25,-46),5,color)
   draw_circle(at+Vector2(side*13,-9),7,Color("071e1e"))
 if c.id == hover:
  draw_arc(c.pos,43*px/4,0,TAU,32,MINT,2)
  if c.pet > 0: draw_arc(c.pos,47*px/4,-PI/2,-PI/2+TAU*minf(1,c.pet/D.PET_DISTANCE),32,GOLD,3)
  if c.kind == "alien": draw_arc(c.pos,180,0,TAU,50,Color(MINT,0.25),1)
 if c.station >= 0: text(c.pos+Vector2(-25,47),"设施使用中",11,Color("8dadaf"))
func draw_facility(f: Dictionary) -> void:
 var at: Vector2 = f.pos
 ellipse(at+Vector2(0,40),Vector2(64,15),Color(0.01,0.05,0.09,0.3))
 if f.kind == "feeder":
  if pointer.distance_to(at)<70:draw_circle(at,200,Color(0.63,0.82,0.57,0.055))
  draw_texture_rect(FEED_TEXTURE,Rect2(at-Vector2(78,101),Vector2(156,156)),false)
  text(at+Vector2(-47,70),"猫粮 %d/%d" % [f.grain,model.feed_capacity()],13,GOLD)
  if f.bugs > 0:
   panel(Rect2(at+Vector2(23,-57),Vector2(36,27)),Color("c96f78"))
   text(at+Vector2(29,-37),"虫！",14)
 elif f.kind == "sun":
  draw_texture_rect(LIGHT_TEXTURE,Rect2(at-Vector2(100,110),Vector2(200,200)),false)
  for side in [-1,1]:
   # New 1024px artwork: apertures at (306,165)/(718,165), platform center near (512,620).
   var bulb: Vector2=at+Vector2(side*40.234375,-77.7734375)
   var mouth:=Vector2(8.5,-side*1.8)
   var landing: Vector2=at+Vector2(side*16,11.09375)
   for spread in [1.25,1.0,0.75]:
    var points:=PackedVector2Array([bulb-mouth,bulb+mouth,landing+Vector2(24*spread,0),landing-Vector2(24*spread,0)])
    var colors:=PackedColorArray([Color(1.0,0.90,0.58,0.16),Color(1.0,0.90,0.58,0.16),Color(1.0,0.88,0.53,0.015),Color(1.0,0.88,0.53,0.015)])
    draw_polygon(points,colors)
   ellipse(landing,Vector2(26,15),Color(1.0,0.88,0.53,0.18))
   draw_line(bulb-mouth,bulb+mouth,Color(1.0,0.96,0.75,0.4),2.5)
  text(at+Vector2(-62,82),"日光浴  %d/%d" % [model.occupants(f.id).size(),model.capacity(f)],14,GOLD)
 elif f.kind == "arcade":
  panel(Rect2(at-Vector2(42,65),Vector2(84,111)),Color("766a9c"),Color("b7a5da"))
  panel(Rect2(at-Vector2(31,53),Vector2(62,51)),Color("101522") if f.broken else Color("32586a"))
  if not f.broken:
   text(at+Vector2(-23,-20),"=^.^=",17,MINT)
   draw_circle(at+Vector2(sin(clock)*15,-40),3,GOLD)
  draw_line(at+Vector2(17,23),at+Vector2(30,4),Color("c5cad6"),5)
  draw_circle(at+Vector2(30,4),7,Color("dc999b"))
  text(at+Vector2(-40,70),"黑屏 · 捶打" if f.broken else "猫用娱乐",14,Color("ee9da1") if f.broken else INK)
 elif f.kind == "altar":
  ellipse(at+Vector2(0,16),Vector2(80,45),Color("596780"))
  draw_arc(at,79,0,TAU,45,Color("b6a2e7"),3)
  for i in range(6):
   var q: Vector2 = at+Vector2.from_angle(i*TAU/6)*58
   draw_rect(Rect2(q-Vector2(5,5),Vector2(10,10)),Color("a9c8d2"))
  draw_colored_polygon(PackedVector2Array([at+Vector2(-25,5),at+Vector2(-18,-61),at+Vector2(0,-42),at+Vector2(19,-61),at+Vector2(27,5)]),Color("82aeaf"))
  for side in [-1,1]: draw_circle(at+Vector2(side*10,-20),5,Color("112d39"))
  text(at+Vector2(-64,76),"密语祭坛 %d/%d" % [model.occupants(f.id).size(),model.capacity(f)],14,Color("c6b0eb"))
 if pointer.distance_to(at) < 70 and interactive:
  draw_arc(at,85,0,TAU,40,Color(MINT,0.65),2)
func draw_gacha() -> void:
 var at := GACHA_POS
 draw_arc(at,73,0,TAU,60,Color(GOLD,0.16+0.08*sin(clock)),2)
 text(at+Vector2(-66,80),"未知文明的仪器",14,GOLD)
func draw_worker(w: Dictionary) -> void:
 var at: Vector2 = w.pos
 ellipse(at+Vector2(0,18),Vector2(18,6),Color(0.02,0.06,0.1,0.2))
 var color := Color("b7cad5")
 draw_rect(Rect2(at+Vector2(-11,-13),Vector2(22,22)),color)
 draw_rect(Rect2(at+Vector2(-8,8),Vector2(16,13)),color.darkened(0.12))
 for side in [-1,1]:
  draw_rect(Rect2(at+Vector2(side*7-3,-5),Vector2(4,4)),Color("193944"))
  draw_line(at+Vector2(side*9,10),at+Vector2(side*17,4+sin(clock*5)*6),color,4)
 if w.role != "general":
  draw_rect(Rect2(at+Vector2(-15,-18),Vector2(30,5)),GOLD)
  draw_rect(Rect2(at+Vector2(-10,-27),Vector2(20,10)),GOLD)
 text(at+Vector2(-25,39),w.status,11,Color("a1b8c7"))
