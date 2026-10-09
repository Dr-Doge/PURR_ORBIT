extends Control
const C = preload("res://scripts/prototype_harvest/config.gd")
const FRAMES = {
 "normal":preload("res://Art/cat1new_animations.tres"),
 "fast":preload("res://Art/cat2new_animations.tres"),
 "special":preload("res://Art/cat5_animations.tres")
}
const INK = Color("263645")
var game
var model
var close_amount: float = 1.0
var selected: int = 1
var hovered: int = -1
var effects: Array = []
var sprites: Dictionary = {}
var samples: Dictionary = {}
var hair_mesh: ArrayMesh
var batches: Dictionary = {}
var kings: Dictionary = {}
var sample_revision: int = -1
var previous: Vector2 = Vector2(INF,INF)
var left_down: bool = false
var clock: float = 0.0
const DRAW_SAMPLE = 2400 # Render-only sampling. Every logical hair remains collectible.
func _ready() -> void:
 mouse_filter=MOUSE_FILTER_STOP;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 mouse_exited.connect(clear_input)
 hair_mesh=ArrayMesh.new()
 var arrays: Array=[];arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=PackedVector3Array([
  Vector3(-0.002,0.004,0),Vector3(0.002,0.004,0),Vector3(0.002,-0.014,0),
  Vector3(-0.002,0.004,0),Vector3(0.002,-0.014,0),Vector3(-0.002,-0.014,0),
  Vector3(-0.005,-0.01,0),Vector3(0.005,-0.01,0),Vector3(0,-0.02,0)])
 hair_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 for kind in FRAMES:
  var frames: SpriteFrames=FRAMES[kind]
  var clips: Dictionary={}
  for clip in ["idle","pet","produce"]:
   var textures: Array=[]
   var base: Texture2D=frames.get_frame_texture("idle",0)
   var base_image: Image=texture_image(base)
   var bounds: Rect2i=base_image.get_used_rect()
   var source_clip: String=clip if frames.has_animation(clip) else "produce"
   for i in frames.get_frame_count(source_clip):
    # Fixed crop across frames preserves authored motion and ground alignment.
    var img: Image=texture_image(frames.get_frame_texture(source_clip,i))
    textures.append(ImageTexture.create_from_image(img.get_region(bounds)))
   clips[clip]=textures
  sprites[kind]=clips
func texture_image(texture: Texture2D) -> Image:
 if texture is AtlasTexture:
  var image: Image=texture.atlas.get_image()
  if image.is_compressed():image.decompress()
  return image.get_region(Rect2i(texture.region))
 var image: Image=texture.get_image()
 if image.is_compressed():image.decompress()
 return image
func cabin_center(id: int) -> Vector2:
 return Vector2(size.x*(0.22+0.29*((id-1)%3)),size.y*(0.57+0.03*((id-1)%2)))
func center(id: int) -> Vector2:
 return cabin_center(id).lerp(Vector2(size.x*0.50,size.y*0.62),close_amount if id==selected else 0.0)
func body_width(id: int) -> float:
 return lerpf(minf(205.0,size.x*0.24),minf(size.x*0.70,size.y*0.65),close_amount if id==selected else 0.0)
func to_screen(id: int,at: Vector2) -> Vector2:return center(id)+at*body_width(id)
func to_local_body(id: int,at: Vector2) -> Vector2:return (at-center(id))/body_width(id)
func cat_at(at: Vector2) -> int:
 if model==null:return -1
 for c in model.cats:
  if Rect2(cabin_center(c.id)-Vector2(100,100),Vector2(200,190)).has_point(at):return c.id
 return -1
func step(dt: float) -> void:
 clock+=dt
 for e in effects:e.left-=dt
 effects=effects.filter(func(e):return e.left>0)
 if model!=null:
  for e in model.feedback:
   var fx: Dictionary=e.duplicate();fx.left=0.8;effects.append(fx)
  model.feedback.clear()
 queue_redraw()
func clear_input() -> void:previous=Vector2(INF,INF);left_down=false;hovered=-1
func _gui_input(event: InputEvent) -> void:
 if game==null:return
 if event is InputEventMouseMotion:
  hovered=cat_at(event.position)
  if game.blocked():previous=Vector2(INF,INF);return
  if close_amount>0.99 and previous.is_finite():model.move(selected,to_local_body(selected,previous),to_local_body(selected,event.position),left_down)
  previous=event.position
 elif event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_LEFT:
   left_down=event.pressed
   if event.pressed and not game.blocked():
    if close_amount>0.99:model.click(selected,to_local_body(selected,event.position))
    elif close_amount<0.01:
     var id: int=cat_at(event.position)
     if id>=0:game.select_cat(id)
  if event.pressed:
   if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:game.zoom(false,selected)
   if event.button_index==MOUSE_BUTTON_WHEEL_UP:
    var id: int=cat_at(event.position)
    if id>=0:game.zoom(true,id)
  accept_event()
func label_at(at: Vector2,text: String,color: Color=INK,sz: int=18) -> void:
 draw_string(ThemeDB.fallback_font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,color)
func ellipse(at: Vector2,radius: Vector2,color: Color) -> void:
 var polygon:=PackedVector2Array()
 for i in 64:polygon.append(at+Vector2(cos(TAU*i/64.0),sin(TAU*i/64.0))*radius)
 draw_colored_polygon(polygon,color)
func update_samples() -> void:
 if model.revision==sample_revision:return
 sample_revision=model.revision;samples.clear();batches.clear();kings.clear()
 for c in model.cats:
  var visible: Array=[];var stride: int=maxi(1,int(ceil(float(c.hairs.size())/DRAW_SAMPLE)));var index: int=0
  for h in c.hairs.values():
   if index%stride==0 or h.kind=="king" or model.locked(c,h.id):visible.append(h)
   index+=1
  samples[c.id]=visible
  var ordinary: Array=visible.filter(func(h):return h.kind!="king")
  kings[c.id]=visible.filter(func(h):return h.kind=="king")
  var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_2D;batch.use_colors=true;batch.mesh=hair_mesh;batch.instance_count=ordinary.size()
  for i in ordinary.size():
   var h: Dictionary=ordinary[i]
   batch.set_instance_transform_2d(i,Transform2D(0,h.pos))
   batch.set_instance_color(i,Color("bb6570") if model.locked(c,h.id) else Color("70604f"))
  batches[c.id]=batch
func _draw() -> void:
 if model==null or sprites.is_empty():return
 update_samples()
 draw_rect(Rect2(Vector2.ZERO,size),Color(0.93,0.96,0.94,close_amount*0.24))
 for c in model.cats:
  if c.id!=selected and close_amount>0.01:continue
  var at: Vector2=center(c.id)
  var width: float=body_width(c.id)
  var close: float=close_amount if c.id==selected else 0.0
  var reaction: float=sin(c.feedback*PI/0.4)*0.035
  ellipse(at+Vector2(0,width*0.31),Vector2(width*0.49,width*0.09),Color(0.08,0.13,0.18,0.22))
  var clip: String="pet" if c.feedback>0 else "idle"
  var frames: Array=sprites[c.kind][clip]
  var texture: Texture2D=frames[int(clock*6)%frames.size()]
  var cat_rect:=Rect2(at+Vector2(-width*0.68,-width*0.72),Vector2(width*1.08,width*0.98))
  var squash: float=sin(close_amount*PI)*0.045+reaction
  cat_rect.position.y+=width*squash;cat_rect.size.y-=width*squash
  draw_texture_rect(texture,cat_rect,false)
  # A clearly labeled prototype body patch keeps every hair on a readable cat surface.
  var body_color: Color=Color("f3dcb5") if c.kind=="normal" else (Color("d7ebed") if c.kind=="fast" else Color("edd4e7"))
  ellipse(at,C.BODY_RADIUS*width,Color("b2a18d"))
  ellipse(at,C.BODY_RADIUS*width-Vector2(3,3),body_color)
  if c.kind=="special":
   for i in 7:
    var p: Vector2=at+Vector2((i-3)*width*0.105,-width*0.13)
    draw_line(p,p+Vector2(width*0.04,width*0.08),Color("c090b6"),3)
  if close>0.6:
   draw_set_transform(at,0,Vector2(width,width));draw_multimesh(batches[c.id],null);draw_set_transform(Vector2.ZERO)
   for h in kings[c.id]:
    var p: Vector2=to_screen(c.id,h.pos)
    var king: bool=h.kind=="king"
    var color: Color=Color("be7417") if king else Color("70604f")
    if model.locked(c,h.id):color=Color("bb6570")
    var length: float=16 if king else 7
    draw_line(p+Vector2(0,5),p-Vector2(2,length),color,4 if king else 2)
    draw_circle(p,9 if king else 3,color)
    if king:
     draw_arc(p,15,-PI/2,-PI/2+TAU*float(h.hits)/C.KING_CLICKS,20,Color("ffd45d"),4)
     label_at(p+Vector2(15,-5),"毛王 %d/%d"%[h.hits,C.KING_CLICKS],Color("8f5613"),16)
  else:
   var representative: int=mini(25,c.hairs.size())
   var drawn: int=0
   for h in samples[c.id]:
    draw_line(to_screen(c.id,h.pos),to_screen(c.id,h.pos)-Vector2(1,5),Color("81644b"),2)
    drawn+=1
    if drawn>=representative:break
  if not c.knot.is_empty():
   var k: Dictionary=c.knot
   var p: Vector2=to_screen(c.id,k.pos)
   draw_circle(p,C.KNOT_RADIUS*width,Color(0.77,0.28,0.39,0.18))
   draw_arc(p,C.KNOT_RADIUS*width,0,TAU,32,Color("b04462"),3)
   if close>0.6:
    label_at(p+Vector2(-45,-C.KNOT_RADIUS*width-10),"毛结 %d%% · 往返 %d/2"%[mini(100,int(k.distance/C.KNOT_DISTANCE*100)),k.reversals],Color("8c2246"),16)
  if not c.flea.is_empty():
   var f: Dictionary=c.flea;var p: Vector2=to_screen(c.id,f.pos)
   draw_circle(p,C.FLEA_RADIUS*width,Color("673a53"))
   draw_circle(p+Vector2(-4,-3),3,Color.WHITE);draw_circle(p+Vector2(5,-3),3,Color.WHITE)
   for side in [-1,1]:
    for y in [-8,0,8]:draw_line(p+Vector2(side*9,y),p+Vector2(side*20,y+5),Color("673a53"),3)
   label_at(at+Vector2(-width*0.43,width*0.36),"偷毛贼！ %.1fs · %d/6 · 赃物 %d"%[f.left,f.hits,f.bag],Color("a41f42"),20 if close>0.6 else 16)
  elif close<0.5:
   label_at(at+Vector2(-95,width*0.44),"%d 根 · 待摘 %d"%[c.hairs.size(),c.pending],INK,17)
   label_at(at+Vector2(-95,width*0.44+23),"%.2f 根/s · 自动 %.1f/s"%[model.rate(c),model.auto_rate(c)],INK,15)
  for w in model.workers:
   if w.cat!=c.id:continue
   var p: Vector2=to_screen(c.id,w.pos)+Vector2(sin(clock*5+w.id)*4,-12)
   draw_circle(p,10 if close>0.5 else 6,Color("397e7b"))
   draw_line(p,p+Vector2(12,12 if w.flash>0 else 3),Color("215955"),3)
   if close>0.6:label_at(p-Vector2(16,17),"帮手%d"%w.id,Color("215955"),14)
  if close<0.5:label_at(at-Vector2(95,width*0.70),c.name,INK,18)
 draw_rect(Rect2(12,10,size.x-24,142),Color(0.96,0.97,0.94,0.94))
 draw_rect(Rect2(12,size.y-68,size.x-24,60),Color(0.96,0.97,0.94,0.94))
 if close_amount<0.01:
  var facility_y: float=size.y-85
  if model.buff_owned:
   draw_circle(Vector2(90,facility_y),22,Color("f0ca64"))
   label_at(Vector2(124,facility_y+5),"生长灯 → "+("未指派" if model.buff_target<0 else model.cat(model.buff_target).name),INK,17)
  if model.decor:
   draw_rect(Rect2(size.x-130,facility_y-20,28,35),Color("b4d4c4"))
   label_at(Vector2(size.x-185,facility_y+40),"盆栽 · 无属性",INK,16)
  if hovered>=0:
   var c: Dictionary=model.cat(hovered)
   draw_rect(Rect2(28,90,minf(550,size.x-56),86),Color(0.96,0.97,0.94,0.96))
   label_at(Vector2(44,118),c.name+"  ·  滚轮向上进入",INK,20)
   label_at(Vector2(44,145),"生长 %.2f 根/s · 理论普通毛 %.2f/s · 实际自动 %.2f/s"%[model.rate(c),model.rate(c)*model.value(c),model.auto_rate(c)],INK,16)
 else:
  var c: Dictionary=model.cat(selected)
  label_at(Vector2(28,100),c.name+"  /  猫身近景",INK,24)
  label_at(Vector2(28,128),"%d 根 · 待摘 %d 毛球 · 生长 %.2f 根/s"%[c.hairs.size(),c.pending,model.rate(c)],INK,18)
  if c.hairs.size()>DRAW_SAMPLE:label_at(Vector2(28,size.y-70),"密集显示已抽样；全部 %d 根仍可采集、继续生长"%c.hairs.size(),INK,16)
  label_at(Vector2(28,size.y-42),"点击毛头 · 移动触碰需升级 · 滚轮向下返回船舱",INK,18)
 for e in effects:
  if close_amount>0.5 and e.cat!=selected:continue
  var p: Vector2=to_screen(e.cat,e.pos)+Vector2(0,-45*(1-e.left/0.8))
  var color: Color=Color("a3265f") if e.value<0 else Color("277d71")
  color.a=clampf(e.left*2,0,1)
  if e.kind=="king" or e.kind=="knot" or (model.cat(e.cat).kind=="special" and e.value>0):
   for i in 8:draw_circle(p+Vector2.from_angle(i*TAU/8)*(1-e.left/0.8)*75,4,color)
  label_at(p,("+" if e.value>0 else "")+str(e.value) if e.value!=0 else "松动！",color,24)
