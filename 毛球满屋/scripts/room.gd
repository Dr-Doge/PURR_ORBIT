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
var pointer_focused: bool = true
var hover_model
var viewport_pointer := Vector2.ZERO
var pointer_known: bool = false

var pointer := Vector2.ZERO
var previous := Vector2.ZERO
var progress_style: StyleBoxFlat = StyleBoxFlat.new()
var clock: float = 0.0
var effects: Array = []
var reduced: bool = false
var font := SystemFont.new()
const INK = Color("e3efef")
const MINT = Color("91e2c6")
const GOLD = Color("f3ca86")
const GACHA_POS = Vector2(1362,300)
var gacha_position: Vector2=GACHA_POS
var cat_visuals = preload("res://scripts/cat_visuals.gd").new()
const CAT_SCENES={"short":preload("res://scenes/cats/short_cat.tscn"),"giant":preload("res://scenes/cats/giant_cat.tscn"),"static":preload("res://scenes/cats/static_cat.tscn"),"lucky":preload("res://scenes/cats/lucky_cat.tscn"),"alien":preload("res://scenes/cats/alien_cat.tscn")}
var cat_nodes: Dictionary={}
var facility_nodes: Dictionary={}
var worker_nodes: Dictionary={}
var initial_cats: Array=[]
var actors_model
func apply_initial_layout(target_model) -> void:
 for i in range(mini(initial_cats.size(),target_model.cats.size())):
  target_model.cats[i].pos=initial_cats[i].pos
  target_model.cats[i].dest=initial_cats[i].pos
  target_model.cats[i].kind=initial_cats[i].kind
func sync_actors() -> void:
 if actors_model!=model:
  cat_nodes.clear();facility_nodes.clear();worker_nodes.clear();actors_model=model
  for layer in [$Cats,$Facilities,$Workers]:
   for node in layer.get_children():layer.remove_child(node);node.queue_free()
 var alive: Dictionary={}
 var ordered: Array=model.cats.duplicate()
 ordered.sort_custom(func(a,b):return a.pos.y<b.pos.y)
 for c in ordered:
  alive[c.id]=true
  if cat_nodes.has(c.id) and cat_nodes[c.id].kind!=c.kind:
   var previous_actor=cat_nodes[c.id]
   $Cats.remove_child(previous_actor);previous_actor.queue_free();cat_nodes.erase(c.id)
  if not cat_nodes.has(c.id):
   var actor=CAT_SCENES[c.kind].instantiate();actor.name="Cat_%d_%s" % [c.id,c.kind]
   $Cats.add_child(actor);cat_nodes[c.id]=actor
  var actor=cat_nodes[c.id];actor.apply(self,c);$Cats.move_child(actor,$Cats.get_child_count()-1)
 for id in cat_nodes.keys():
  if not alive.has(id):cat_nodes[id].queue_free();cat_nodes.erase(id)
 sync_entities(model.facilities,facility_nodes,$Facilities,false)
 sync_entities(model.workers,worker_nodes,$Workers,true)
func sync_entities(items: Array,views: Dictionary,layer: Node,workers: bool) -> void:
 var alive: Dictionary={}
 for item in items:
  alive[item.id]=true
  if not views.has(item.id):
   var path: String="res://scenes/facilities/"+("worker" if workers else item.kind)+".tscn"
   var view=load(path).instantiate();view.name=("Worker" if workers else item.kind.capitalize())+"_"+str(item.id)
   layer.add_child(view);views[item.id]=view
  views[item.id].apply(self,item)
 for id in views.keys():
  if not alive.has(id):views[id].queue_free();views.erase(id)
func _ready() -> void:
 for actor in $Cats.get_children():
  var simulation_pos: Vector2=D.FLOOR.position+(actor.position-ART_FLOOR.position)*D.FLOOR.size/ART_FLOOR.size
  initial_cats.append({"pos":simulation_pos,"kind":actor.kind})
 progress_style.bg_color=Color("243b4c");progress_style.set_corner_radius_all(2)
 font.font_names = PackedStringArray(["Microsoft YaHei","Segoe UI"])
 clip_contents = true
 backdrop=$Backdrop
 static_outlines=$StaticOutlines
 harvest_art=$HarvestEffects
 token_effect=$TokenLayer/TokenEffect;token_effect.room=self
 resized.connect(layout_backdrop)
 layout_backdrop()
 mouse_exited.connect(clear_hover)
 get_window().focus_exited.connect(lose_pointer_focus)
 get_window().focus_entered.connect(gain_pointer_focus)
func _input(event: InputEvent) -> void:
 if event is InputEventMouseMotion or event is InputEventMouseButton:
  viewport_pointer=event.position;pointer_known=true
func _process(_dt: float) -> void:
 refresh_hover()
func _exit_tree() -> void:
 clear_hover()
func clear_hover() -> void:
 hover=-1
 if model!=null:model.set_hovered_cat(-1)
 if hover_model!=null:hover_model.set_hovered_cat(-1)
func lose_pointer_focus() -> void:
 pointer_focused=false;reset_pointer()
func gain_pointer_focus() -> void:
 pointer_focused=true
func cat_at_screen(at: Vector2) -> int:
 # Reverse draw order: the frontmost displayed cat owns an overlapping hit.
 var ordered: Array=model.cats.duplicate()
 ordered.sort_custom(func(a: Dictionary,b: Dictionary):return a.pos.y<b.pos.y)
 ordered.reverse()
 for c in ordered:
  if c.station!=-1 or c.dragging:continue
  var rect: Rect2=cat_rect(c)
  var factor: float=object_scale(c.pos)
  var hit:=Rect2(screen_position(c.pos)+(rect.position-c.pos)*factor,rect.size*factor)
  if hit.has_point(at):return c.id
 return -1
func ui_obstructs(node: Node,at: Vector2) -> bool:
 if node==self:return false
 if node is CanvasItem and not node.is_visible_in_tree():return false
 # A newly shown/moved UI can precede Godot's next mouse-motion GUI pick.
 if node is Control and node.is_greater_than(self):
  var local: Vector2=node.get_global_transform_with_canvas().affine_inverse()*at
  if node.clip_contents and not Rect2(Vector2.ZERO,node.size).has_point(local):return false
  if node.mouse_filter!=MOUSE_FILTER_IGNORE and Rect2(Vector2.ZERO,node.size).has_point(local):return true
 for child in node.get_children():
  if ui_obstructs(child,at):return true
 return false
func refresh_hover() -> void:
 if hover_model!=model:
  clear_hover();hover_model=model
 if model==null:return
 if not pointer_known or not interactive or not pointer_focused or not is_visible_in_tree() or dragging>=0 or placing!="" or moving_id>=0:
  clear_hover();return
 # GUI routing catches HUD/overlays even when no mouse-motion event occurs.
 if get_viewport().gui_get_hovered_control()!=self or ui_obstructs(get_tree().root,viewport_pointer):
  clear_hover();return
 var at: Vector2=get_global_transform_with_canvas().affine_inverse()*viewport_pointer
 if not Rect2(Vector2.ZERO,size).has_point(at):clear_hover();return
 pointer=world(at)
 hover=cat_at_screen(at)
 model.set_hovered_cat(hover)
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
 var scale_factor: float = object_scale(at)
 draw_set_transform(screen_position(at)-at*scale_factor,0,Vector2.ONE*scale_factor)
func object_scale(_at: Vector2) -> float:
 return stage_scale()*0.9
func reward_target(token: bool=false) -> Vector2:
 return stage_origin()+Vector2(1250 if token else 1140,137)*stage_scale()
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
 refresh_hover()
 clock += dt
 if backdrop != null: backdrop.step(dt)
 if model != null:
  cat_visuals.step(model,dt)
  sync_actors()
 if static_outlines != null and model != null:static_outlines.update_outlines(self)
 for e in effects.duplicate():
  e.age += dt
  if e.age > (2.1 if e.kind == "token" else 1.7): effects.erase(e)
 while effects.size() > 90: effects.pop_front()
 if harvest_art != null and model != null: harvest_art.update_art(self)
 if token_effect != null:token_effect.queue_redraw()
 queue_redraw()
func reset_pointer() -> void:
 if model!=null:
  pass # Leaving the room/UI keeps progress until model-time grace expires.
 clear_hover()
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
 var id: int=cat_at_screen(at)
 if id>=0:
  var c: Dictionary=model.cat(id)
  if c.station == -1 and not c.dragging and not model.reacting(c):return CURSOR_CROSS
 return CURSOR_ARROW
func _gui_input(event: InputEvent) -> void:
 if not interactive: return
 if event is InputEventMouseMotion:
  pointer = world(event.position)
  if dragging >= 0:
   var c: Dictionary = model.cat(dragging)
   if not c.is_empty(): c.pos = model.clamp_position(pointer)
  elif placing == "" and moving_id < 0:
   var last_hover: int=hover
   refresh_hover()
   var id: int=hover
   if id >= 0 and id == last_hover:model.pet(id,pointer.distance_to(previous))
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
   var id: int = cat_at_screen(event.position)
   if id<0:id=cat_at(pointer) # Preserve explicit dragging out of facilities.
   if id >= 0:
    dragging = id
    var c: Dictionary = model.cat(id)
    c.dragging = true; model.cancel_pet(c);clear_hover()
    accept_event(); return
   for w in model.workers:
    if w.pos.distance_to(pointer) < 25: worker_selected.emit(w.id); accept_event(); return
   var fid: int = station_at(pointer)
   if fid >= 0: facility_selected.emit(fid); accept_event(); return
   if model.gacha_ready and pointer.distance_to(gacha_position) < 64: gacha_selected.emit(); accept_event(); return
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
func draw_entities() -> void:
 if model.gacha_ready:
  object_transform(gacha_position); draw_gacha()
 var ordered: Array = model.cats.duplicate()
 ordered.sort_custom(func(a: Dictionary,b: Dictionary): return a.pos.y < b.pos.y)
 for c in ordered:
  object_transform(c.pos); draw_cat(c)
func _draw() -> void:
 if model == null or size.x <= 0:return
 draw_entities()
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
  draw_arc(pointer,58 if kind=="feeder" else 80,0,TAU,50,MINT,2)
  panel(Rect2(pointer-Vector2(45,35),Vector2(90,70)),Color(0.5,0.9,0.8,0.18),MINT)
  text(pointer+Vector2(-65,-48),D.title(kind)+" · 点击摆放",17,MINT)
 elif hover >= 0:
  var c: Dictionary = model.cat(hover)
  if not c.is_empty():
   var desc: String = "%s · %d 层 · 收割 %.1f 毛球" % [D.title(c.kind),c.layers,model.harvest_value(c)]
   if model.reacting(c):desc+=" · 收获中 %.1f秒" % c.reaction_left
   if c.fed>0:desc+=" · 饱食 %.0f秒" % c.fed
   elif c.get("feed_target",-1)>=0:desc+=" · "+("进食中" if c.get("eat_time",0)>0 else "正在觅食")
   stage_transform()
   panel(Rect2(295,735,690,32),Color("101f2b"),Color("52796e"))
   text(Vector2(310,757),desc,16,MINT)
func cat_extent(c: Dictionary, animate: bool = true) -> float:
 var extent: float=100.0*(1.35 if c.kind=="giant" else 1.0)*(1+minf(c.layers,D.MAX_LAYERS)*D.CAT_LAYER_SIZE_STEP)
 if c.kind=="lucky":extent*=1.342
 if c.kind=="alien":extent*=1.25
 if animate:extent*=1.0+D.CAT_PULSE_AMOUNT*sin(PI*clampf(c.pop/D.CAT_PULSE_DURATION,0.0,1.0))
 return extent
func cat_rect(c: Dictionary) -> Rect2:
 var extent: float=cat_extent(c)
 if cat_visuals.states.get(c.id,{}).get("frames")==cat_visuals.Short.FRAMES:
  extent*=0.8
  if cat_visuals.states[c.id].get("clip","") in ["walk_up","idle_up"]:extent*=0.88
 # Anchor the opaque foot pixels, including during the growth pulse.
 var variant: int=int(c.get("variant",c.id%4))
 var progress: float=model.pet_progress(c)
 var touch: float=sin(clock*(10+variant*2))*0.025 if model.elapsed-c.get("pet_stamp",-10.0)<0.15 else 0.0
 var squeeze: float=progress*(0.07+variant*0.018)+touch if not model.reacting(c) else sin(clampf(1.0-c.reaction_left/1.1,0,1)*PI)*(0.07+variant*0.02)
 var dimensions: Vector2=Vector2(extent*(1+squeeze),extent*(1-squeeze))
 return Rect2(c.pos+cat_visuals.visual_offset(c.id)+Vector2(-dimensions.x/2.0,26.0-dimensions.y*cat_visuals.foot_anchor(c.id)),dimensions)
func draw_cat(c: Dictionary) -> void:
 ellipse(c.pos+Vector2(0,26),Vector2(31*cat_extent(c,false)/100.0,10),Color(0.02,0.08,0.13,0.25))
 draw_cat_feedback(c)
func draw_cat_feedback(c: Dictionary) -> void:
 var progress: float=model.pet_progress(c)
 if progress>0 or c.id==hover:
  var bar: Rect2=Rect2(c.pos+Vector2(-26,37),Vector2(52,5))
  draw_style_box(progress_style,bar)
  if progress>0:draw_rect(Rect2(bar.position,Vector2(52*progress,5)),GOLD)
  if c.id==hover:text(c.pos+Vector2(-21,57),"%d%%" % roundi(progress*100),11,GOLD)
 if not c.get("charges",[]).is_empty():text(c.pos+Vector2(-20,72),"蓄养 %d" % c.charges.size(),11,MINT)
 if c.station >= 0: text(c.pos+Vector2(-25,47),"设施使用中",11,Color("8dadaf"))
func draw_gacha() -> void:
 var at := gacha_position
 draw_arc(at,73,0,TAU,60,Color(GOLD,0.16+0.08*sin(clock)),2)
 text(at+Vector2(-66,80),"未知文明的仪器",14,GOLD)
