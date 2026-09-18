extends Control
signal facility_selected(id: int)
signal worker_selected(id: int)
signal gacha_selected
signal build_requested(kind: String,at: Vector2)
signal notice(text: String)
const D = preload("res://scripts/data.gd")
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
const CAT_PIXELS = ["  BB      BB  "," BBBB    BBBB "," BBBBBBBBBBBB ","BBBBBBBBBBBBBB","BBBBBBBBBBBBBB","BBEEBBBBEEBBBB","BBEEBBBBEEBBBB","BBBBBBNNBBBBBB"," BBBBBBBBBBBB "," BBBBBBBBBBBB ","BBBBBBBBBBBBBB","BBBBBBBBBBBBBB","  BBBB  BBBB  "]
func _ready() -> void:
 font.font_names = PackedStringArray(["Microsoft YaHei","Segoe UI"])
 clip_contents = true
 mouse_exited.connect(func(): hover = -1)
func world(at: Vector2) -> Vector2:
 return at*D.WORLD/size
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
 var item: Dictionary = e.duplicate(true)
 item.age = 0.0
 effects.append(item)
func step(dt: float) -> void:
 clock += dt
 for e in effects.duplicate():
  e.age += dt
  if e.age > (0.8 if e.kind == "ring" else 1.7): effects.erase(e)
 while effects.size() > 90: effects.pop_front()
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
 draw_set_transform(Vector2.ZERO,0,size/D.WORLD)
 draw_rect(Rect2(Vector2.ZERO,D.WORLD),Color("101b28"))
 # Deep space behind the station's broad observation window.
 panel(Rect2(45,96,1350,181),Color("080e1b"),Color("355267"),18)
 for i in range(95):
  var at := Vector2(65+fmod(i*157.7,1305),110+fmod(i*43.37,148))
  var alpha: float = 0.25+0.35*(sin(clock*0.7+i)*0.5+0.5)
  draw_rect(Rect2(at,Vector2(2,2)),Color(0.73,0.87,0.99,alpha))
 ellipse(Vector2(1130,202),Vector2(79,54),Color("294b61"))
 ellipse(Vector2(1118,186),Vector2(53,24),Color("387582"))
 draw_arc(Vector2(1130,200),101,-0.15,2.7,40,Color("7193a3"),3)
 for x in [315,715,1035]: draw_rect(Rect2(x,99,12,176),Color("273c4f"))
 text(Vector2(91,154),"喵 星 驻 留 站",27)
 text(Vector2(93,180),"P U R R   /   O R B I T A L   H A B I T A T",13,Color("7392a9"))
 text(Vector2(93,234),["01  /  初次停留","02  /  不速之客","03  /  猫咪的密语"][model.round_no-1],18,MINT)
 panel(Rect2(48,283,1344,479),Color("233445"),Color("43576a"),16)
 for y in range(300,748,48):
  for x in range(66,1380,64):
   var shade: Color = Color("293d4f") if int(x/64+y/48) % 2 == 0 else Color("2b4052")
   draw_rect(Rect2(x,y,61,45).intersection(Rect2(62,300,1316,445)),shade)
 for x in [78,1358]:
  for y in range(308,738,40): draw_rect(Rect2(x,y,4,18),Color("577080"))
 panel(Rect2(354,358,645,312),Color("34575d"),Color("608781"),12)
 for y in range(376,657,20): draw_line(Vector2(372,y),Vector2(983,y),Color(0.53,0.74,0.69,0.06),1)
 text(Vector2(389,640),"HABITAT  /  请善待你的奇妙室友",12,Color("7baba6"))
 # Station furniture lives inside the same full-screen world.
 for i in range(4):
  var at := Vector2(110+i*100,719)
  panel(Rect2(at,Vector2(68,20)),Color("3b5663"),Color("6f8d92"),3)
  for j in range(4): draw_rect(Rect2(at+Vector2(9+j*13,6),Vector2(6,4)),MINT if j==i else Color("68828b"))
 for f in model.facilities: draw_facility(f)
 if model.gacha_ready: draw_gacha()
 var ordered: Array = model.cats.duplicate()
 ordered.sort_custom(func(a: Dictionary,b: Dictionary): return a.pos.y < b.pos.y)
 for c in ordered: draw_cat(c)
 for w in model.workers: draw_worker(w)
 if interactive and model.harvests<2 and not model.cats.is_empty():
  var at: Vector2=model.cats[0].pos+Vector2(0,-80)
  text(at+Vector2(-57,-8),"← 来回摸我 →",18,GOLD)
  draw_line(at+Vector2(0,8),at+Vector2(0,26+sin(clock*4)*5),GOLD,3)
 for e in effects:
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
   if not reduced and e.kind == "money":
    for i in range(3):
     var at: Vector2 = e.pos.lerp(Vector2(320,32),minf(1,e.age/1.1))+Vector2(sin(i+e.age*5)*13,0)
     draw_rect(Rect2(at,Vector2(5,5)),Color(GOLD,alpha))
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
   panel(Rect2(520,752,470,32),Color("101f2b"),Color("52796e"))
   text(Vector2(535,774),desc,16,MINT)
func draw_cat(c: Dictionary) -> void:
 var at: Vector2 = c.pos-Vector2(0,sin(minf(1,c.pop)*PI)*10)
 var px: float = 4.0*(1.35 if c.kind=="giant" else 1.0)*(1+minf(c.layers,8)*0.026)
 var color: Color = [Color("edbd8b"),Color("e5e5d3"),Color("baa0ce")][int(c.color)]
 if c.kind == "alien": color = Color("8cdf8e")
 if c.kind == "lucky": color = Color("f6e6b8")
 ellipse(c.pos+Vector2(0,26),Vector2(31*px/4,10),Color(0.02,0.08,0.13,0.25))
 if c.kind == "static":
  for i in range(16):
   var tip: Vector2 = at+Vector2.from_angle(i*TAU/16)*34*px/4
   draw_rect(Rect2(tip,Vector2(9,9)),color)
 for y in range(CAT_PIXELS.size()):
  for x in range(CAT_PIXELS[y].length()):
   var ch: String = CAT_PIXELS[y][x]
   if ch == " ": continue
   var col: Color = color
   if ch == "E": col = Color("142c33")
   if ch == "N": col = Color("d1838b")
   if ch == "B" and c.kind == "short" and c.color == 0 and x<5 and y<4: col = Color("936953")
   draw_rect(Rect2(at+Vector2((x-7)*px,(y-7)*px),Vector2(px+0.2,px+0.2)),col)
 if c.kind == "alien":
  for side in [-1,1]:
   draw_line(at+Vector2(side*18,-22),at+Vector2(side*25,-45),color,3)
   draw_circle(at+Vector2(side*25,-46),5,color)
   draw_circle(at+Vector2(side*13,-9),7,Color("071e1e"))
 if c.kind == "lucky":
  draw_rect(Rect2(at+Vector2(-13,15),Vector2(26,7)),Color("c86865"))
  draw_circle(at+Vector2(0,22),5,GOLD)
  draw_rect(Rect2(at+Vector2(31,-21),Vector2(8,22)),color)
 if c.layers > 0:
  panel(Rect2(c.pos+Vector2(18,-43),Vector2(29,23)),GOLD if c.layers>=model.harvest_target else Color("65887c"),Color.TRANSPARENT,4)
  text(c.pos+Vector2(24,-26),str(c.layers),14,Color("173432"))
 if c.id == hover:
  draw_arc(c.pos,43*px/4,0,TAU,32,MINT,2)
  if c.pet > 0: draw_arc(c.pos,47*px/4,-PI/2,-PI/2+TAU*minf(1,c.pet/D.PET_DISTANCE),32,GOLD,3)
  if c.kind == "alien": draw_arc(c.pos,180,0,TAU,50,Color(MINT,0.25),1)
 if c.station >= 0: text(c.pos+Vector2(-25,47),"设施使用中",11,Color("8dadaf"))
func draw_facility(f: Dictionary) -> void:
 var at: Vector2 = f.pos
 ellipse(at+Vector2(0,40),Vector2(64,15),Color(0.01,0.05,0.09,0.3))
 if f.kind == "feeder":
  draw_circle(at,200,Color(0.63,0.82,0.57,0.035))
  panel(Rect2(at-Vector2(40,46),Vector2(80,76)),Color("8aa18b"),Color("bad4ba"))
  panel(Rect2(at-Vector2(25,34),Vector2(50,35)),Color("304b45"))
  draw_rect(Rect2(at+Vector2(-20,-29),Vector2(40*float(f.grain)/40,25)),GOLD)
  panel(Rect2(at+Vector2(-46,16),Vector2(92,24)),Color("556d6b"),Color("8fa997"))
  text(at+Vector2(-27,11),"FEED",13,Color("203c39"))
  text(at+Vector2(-47,70),"猫粮 %d/40" % f.grain,13,GOLD)
  if f.bugs > 0:
   panel(Rect2(at+Vector2(23,-57),Vector2(36,27)),Color("c96f78"))
   text(at+Vector2(29,-37),"虫！",14)
 elif f.kind == "sun":
  ellipse(at,Vector2(87,47),Color("65757a"))
  ellipse(at,Vector2(77,38),Color("ac9876"))
  for i in range(5): draw_line(at+Vector2(-62+i*30,-27),at+Vector2(-45+i*23,27),Color("f4d499"),3)
  draw_arc(at,85,0,TAU,40,Color(GOLD,0.4),2)
  text(at+Vector2(-62,67),"日光浴  %d/%d" % [model.occupants(f.id).size(),model.capacity(f)],14,GOLD)
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
 panel(Rect2(at-Vector2(41,58),Vector2(82,110)),Color("667b79"),GOLD,9)
 draw_colored_polygon(PackedVector2Array([at+Vector2(-40,-45),at+Vector2(-32,-78),at+Vector2(-10,-59),at+Vector2(15,-59),at+Vector2(34,-79),at+Vector2(42,-44)]),Color("82958a"))
 for x in [-19,19]: draw_rect(Rect2(at+Vector2(x-5,-32),Vector2(10,6)),GOLD)
 draw_rect(Rect2(at+Vector2(-23,-8),Vector2(46,5)),Color("152c36"))
 draw_circle(at+Vector2(0,18),15,GOLD)
 draw_line(at+Vector2(-10,18),at+Vector2(10,18),Color("536561"),4)
 panel(Rect2(at+Vector2(-19,37),Vector2(38,11)),Color("162d35"))
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
