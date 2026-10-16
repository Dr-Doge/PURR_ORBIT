extends Control
const C=preload("res://scripts/prototype_grooming/config.gd")
const CleaningShader=preload("res://scripts/prototype_grooming_fur/coat_cleaning.gdshader")
const Tool=preload("res://scripts/prototype_grooming_fur/tool_geometry.gd")
var game: Control
var model: RefCounted
var subject: Node2D
var base: Sprite2D
var dirt: Node2D
var claw_root: Node2D
var claw_sprites: Array=[]
var object_sprites: Dictionary={}
var particles: Array=[]
var tool: Sprite2D
var model_version: int=-1
var mouse: Vector2=Vector2(1470,550)
var trail:=PackedVector2Array()
var body_texture: ImageTexture
var actor_transform:=Transform2D.IDENTITY
var last_stage: String=""
var foreground: Node2D

func _ready() -> void:
 var preview: Node=get_parent().get_node_or_null("EditorPreview")
 if preview!=null:preview.hide()
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 mouse_filter=Control.MOUSE_FILTER_STOP
 subject=Node2D.new();subject.name="SubjectRoot";add_child(subject)
 base=Sprite2D.new();base.name="CleanSubject";subject.add_child(base)
 dirt=Node2D.new();dirt.name="RemovableDirt";subject.add_child(dirt)
 claw_root=Node2D.new();claw_root.name="Claws";subject.add_child(claw_root)
 subject.move_child(claw_root,0)
 for i in range(4):
  var sprite:=Sprite2D.new();sprite.centered=false;claw_root.add_child(sprite);claw_sprites.append(sprite)
 tool=Sprite2D.new();tool.name="ToolCursor";add_child(tool);tool.z_index=20
 foreground=Node2D.new();foreground.name="InteractionGuides";foreground.set_script(preload("res://scripts/prototype_grooming/foreground.gd"));foreground.view=self;foreground.z_index=30;add_child(foreground)
 for i in range(C.PARTICLE_LIMIT):
  var sprite:=Sprite2D.new();sprite.visible=false;sprite.z_index=25;add_child(sprite)
  particles.append({"sprite":sprite,"left":0.0,"total":C.PARTICLE_TIME,"velocity":Vector2.ZERO})
 resized.connect(layout)
 layout()

func layout() -> void:
 var scale_factor: Vector2=size/C.CANVAS
 subject.scale=scale_factor;tool.scale=scale_factor
 queue_redraw()

func to_logical(point: Vector2) -> Vector2:return point/size*C.CANVAS
func model_point(point: Vector2) -> Vector2:return actor_transform.affine_inverse()*to_logical(point)

func attach(value: RefCounted) -> void:
 model=value;model_version=-1;sync()

func sync() -> void:
 if model==null:return
 if model_version!=model.version:
  model_version=model.version
  for child in dirt.get_children():child.free()
  object_sprites.clear()
  body_texture=ImageTexture.create_from_image(model.body_mask)
  for obj in model.objects:
   var sprite:=Sprite2D.new();sprite.name="Dirt_"+str(obj.id);sprite.texture=model.assets.texture(obj.type)
   var mask_texture:=ImageTexture.create_from_image(obj.mask)
   var material:=ShaderMaterial.new();material.shader=CleaningShader
   material.set_shader_parameter("remaining_mask",mask_texture)
   material.set_shader_parameter("body_mask",body_texture)
   material.set_shader_parameter("coat_map",model.assets.coat_reference() if model.kind=="calico" else model.assets.texture(model.kind+"_clean"))
   material.set_shader_parameter("body_dimensions",model.body_rect.size)
   material.set_shader_parameter("match_coat",model.kind=="calico" and obj.rule in ["patch","edge","knot"])
   material.set_shader_parameter("preserve_outline",obj.rule in ["edge","knot"])
   if model.kind=="calico":
    var white:=Image.create(2,2,false,Image.FORMAT_RGBA8);white.fill(Color.WHITE)
    material.set_shader_parameter("body_mask",ImageTexture.create_from_image(white))
   var uv: Vector2=(obj.rect.position-model.body_rect.position)/model.body_rect.size
   var uv_size: Vector2=obj.rect.size/model.body_rect.size
   material.set_shader_parameter("region_in_body",Vector4(uv.x,uv.y,uv_size.x,uv_size.y))
   material.set_shader_parameter("patch_angle",obj.get("draw_angle",0.0))
   material.set_shader_parameter("complete_sprite",model.kind=="calico")
   sprite.rotation=obj.get("draw_angle",0.0)
   sprite.material=material;sprite.position=obj.rect.get_center();sprite.scale=obj.rect.size/Vector2(sprite.texture.get_size())
   dirt.add_child(sprite)
   object_sprites[obj.id]={"sprite":sprite,"texture":mask_texture,"version":-1}
  for p in particles:p.left=0.0;p.sprite.visible=false
  trail=PackedVector2Array()
 var nails_visible: bool=model.stage in ["to_nails","nails"] or (model.needs_nails and model.stage in ["reward","departure"])
 claw_root.visible=nails_visible;dirt.visible=not nails_visible
 var name: String=model.kind+"_clean"
 if nails_visible:
  name="paw_base"
 elif model.stage in ["reward","departure"]:
  name=model.kind+"_happy" if model.score>=75 else model.kind+"_discomfort"
 base.texture=model.assets.texture(name)
 base.material=null
 var box: Rect2=C.PAW_BOX if nails_visible else C.BODY_BOX
 var factor: float=minf(box.size.x/base.texture.get_width(),box.size.y/base.texture.get_height())
 var drawn: Vector2=Vector2(base.texture.get_size())*factor
 var rect: Rect2=model.body_rect if not nails_visible else Rect2(box.position+Vector2((box.size.x-drawn.x)/2.0,box.size.y-drawn.y),drawn)
 base.position=rect.get_center();base.scale=rect.size/Vector2(base.texture.get_size())
 for obj in model.objects:
  var entry: Dictionary=object_sprites[obj.id]
  if entry.sprite.visible and obj.done and obj.rule in ["patch","edge","knot"]:detach_patch(obj)
  entry.sprite.position=obj.rect.get_center()
  entry.sprite.visible=not obj.done
  if entry.version!=obj.version:
   entry.texture.update(obj.mask);entry.version=obj.version
   entry.sprite.material.set_shader_parameter("loosen",1.0)
 for i in range(4):
  var nail: Dictionary=model.nails[i];var sprite: Sprite2D=claw_sprites[i]
  sprite.texture=model.assets.texture("claw_long");sprite.region_enabled=true
  var y: float=maxf(0.0,sprite.texture.get_height()-nail.height/model.claw_scale)
  sprite.region_rect=Rect2(0,y,sprite.texture.get_width(),sprite.texture.get_height()-y)
  sprite.position=nail.root-Vector2(model.claw_anchor_x*model.claw_scale,nail.height)
  sprite.scale=Vector2.ONE*model.claw_scale
  sprite.modulate=Color(1,0.85,0.85) if nail.result=="deep" else Color.WHITE
 tool.texture=model.assets.texture("clipper" if nails_visible else ("comb" if model.kind=="calico" else "cloth"))
 tool.visible=model.stage in ["cleaning","nails"] and not model.paused
 var tool_width: float=140.0 if nails_visible else 130.0
 tool.scale=Vector2.ONE*(tool_width/tool.texture.get_width())*(size/C.CANVAS)
 tool.position=(mouse+Vector2(40,-35))*size/C.CANVAS
 tool.rotation=0.0
 tool.flip_h=false
 if not nails_visible and model.kind=="calico":
  var active: bool=game!=null and game.dragging and not model.paused
  tool.rotation=-Tool.rotation_angle();tool.flip_h=true
  tool.scale=Vector2.ONE*Tool.texture_scale()*(size/C.CANVAS)
  var offset: Vector2=Tool.center_offset(Vector2(tool.texture.get_size()))
  if not active:tool.rotation+=Tool.IDLE_TILT;offset=offset.rotated(Tool.IDLE_TILT)+Tool.IDLE_LIFT
  tool.position=(mouse+offset)*(size/C.CANVAS)
 var shake:=Vector2.ZERO
 if model.reaction>0.0:shake=Vector2(sin(model.now*85.0)*6.0,cos(model.now*71.0)*3.0)
 actor_transform=Transform2D(0.0,shake)
 subject.transform=Transform2D(0.0,Vector2.ZERO).scaled(size/C.CANVAS)*actor_transform
 if model.stage=="arrival":subject.modulate.a=clampf(1.0-model.stage_left/C.ARRIVAL_TIME,0.0,1.0)
 elif model.stage=="departure":subject.modulate.a=clampf(model.stage_left/C.DEPARTURE_TIME,0.0,1.0)
 else:subject.modulate.a=1.0
 subject.modulate=Color(1,0.83,0.80,subject.modulate.a) if model.reaction>0.0 else Color(1,1,1,subject.modulate.a)
 last_stage=model.stage
 foreground.queue_redraw()
 queue_redraw()

func animate(dt: float) -> void:
 for p in particles:
  if p.left<=0.0:continue
  p.left=maxf(0.0,p.left-dt)
  p.velocity+=Vector2(0,260)*dt
  p.sprite.position+=p.velocity*dt*(size/C.CANVAS)
  p.sprite.rotation+=dt*2.0
  p.sprite.modulate.a=p.left/p.total
  p.sprite.visible=p.left>0.0
 sync()

func burst(name: String,at: Vector2,count: int=3) -> void:
 for p in particles:
  if count<=0:break
  if p.left>0.0:continue
  var sprite: Sprite2D=p.sprite;sprite.texture=model.assets.texture(name);sprite.material=null
  var width: float=randf_range(22,42)
  sprite.scale=Vector2.ONE*(width/sprite.texture.get_width())*(size/C.CANVAS)
  sprite.position=at*(size/C.CANVAS);sprite.rotation=randf_range(-1,1);sprite.modulate=Color.WHITE;sprite.visible=true
  p.left=C.PARTICLE_TIME;p.total=C.PARTICLE_TIME;p.velocity=Vector2(randf_range(-170,100),randf_range(-220,-60))
  count-=1

func _gui_input(event: InputEvent) -> void:
 if game!=null:game.surface_input(event)

func _draw() -> void:
 if model==null:return
 draw_set_transform(Vector2.ZERO,0.0,size/C.CANVAS)
 draw_texture_rect(model.assets.texture("room_background"),Rect2(Vector2.ZERO,C.CANVAS),false)
 draw_texture_rect(model.assets.texture("grooming_table"),Rect2(-100,550,2120,1193),false)
 if model.stage not in ["nails","to_nails"]:
  var box: Rect2=model.body_rect
  draw_ellipse_shadow(Rect2(box.position.x+box.size.x*.12,box.end.y-38,box.size.x*.77,58))
 var font: Font=ThemeDB.fallback_font
 if model.stage in ["reward","departure"]:
  var coin: Texture2D=model.assets.texture("coin")
  draw_texture_rect(coin,Rect2(780,145,62,62),false)
  draw_string(font,Vector2(855,196),"+%d"%model.last_payment,HORIZONTAL_ALIGNMENT_LEFT,-1,64,Color(1,0.85,0.3))

func draw_foreground(canvas: Node2D) -> void:
 if model==null:return
 canvas.draw_set_transform(Vector2.ZERO,0.0,size/C.CANVAS)
 if model.stage=="cleaning":
  var label_row: int=0
  for obj in model.objects:
   if obj.done or obj.rule in ["patch","edge","normal","wipe"]:continue
   var text: String="慢慢顺梳 →"
   if obj.rule=="dust":text="上下轻扫 %d/2"%obj.passes
   elif obj.rule=="flea":text="点跳蚤 %d/3"%obj.passes
   elif obj.rule=="vertical":text="上下擦 %d/3"%obj.passes
   elif obj.rule=="horizontal":text="左右擦 %d/4"%obj.passes
   var at: Vector2=actor_transform*(obj.rect.position+Vector2(0,-12))
   if model.cat_scale==.5:
    at=Vector2(model.body_rect.end.x+30,model.body_rect.position.y+80+label_row*55);label_row+=1
    canvas.draw_line(at-Vector2(10,8),actor_transform*obj.rect.get_center(),Color(1,.85,.45,.5),1.5,true)
   canvas.draw_style_box(label_style(),Rect2(at-Vector2(7,23),Vector2(150,34)))
   canvas.draw_string(ThemeDB.fallback_font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color(.28,.17,.08))
  if model.kind=="calico":
   for obj in model.objects:
    if obj.rule=="edge" and not obj.done and obj.rect.grow(20).has_point(mouse):
     canvas.draw_string(ThemeDB.fallback_font,mouse+Vector2(30,-65),"轮廓毛 · 向右一梳脱落 →",HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color(1,.9,.65))
     break
   var points: PackedVector2Array=Tool.edge_points(mouse)
   var active: bool=game!=null and game.dragging
   var color:=Color(.35,1.0,.95,.95) if active else Color(.8,.85,.9,.55)
   if model.comfort.load>=model.Comfort.ALERT:color=Color(1,.35,.2)
   elif model.comfort.load>=model.Comfort.WARNING:color=Color(1,.8,.25)
   if active:
    canvas.draw_line(points[0],points[1],color,3,true)
    for p in points:canvas.draw_line(p-Vector2(6,0),p+Vector2(6,0),color,2,true)
   canvas.draw_string(ThemeDB.fallback_font,mouse+Vector2(35,95),"已激活 · 向右轻梳 →" if active else "已抬起 · 按住左键开始",HORIZONTAL_ALIGNMENT_LEFT,-1,21,color)
   if model.comfort.load>.02:
    canvas.draw_rect(Rect2(mouse+Vector2(30,110),Vector2(130,8)),Color(.15,.10,.07,.7))
    canvas.draw_rect(Rect2(mouse+Vector2(30,110),Vector2(130*model.comfort.load,8)),color)
  elif game!=null and game.dragging:canvas.draw_arc(mouse,C.BRUSH_RADIUS,0,TAU,32,Color(1,1,1,.35),2,true)
 if model.stage=="nails":
  for nail in model.nails:
   if nail.done:continue
   var h: float=model.perfect_height();var edges: Vector2=model.nail_edges(nail,h)
   var y: float=nail.root.y-h
   canvas.draw_rect(Rect2(edges.x-10,y-C.NAIL_BAND_WIDTH/2.0,edges.y-edges.x+20,C.NAIL_BAND_WIDTH),Color(0.12,0.95,0.55,0.18))
   var x: float=edges.x-10
   while x<edges.y+10:
    canvas.draw_line(Vector2(x,y),Vector2(minf(x+11,edges.y+10),y),Color(0.14,0.90,0.57),4,true);x+=20
  if trail.size()>1:canvas.draw_polyline(trail,Color(0.75,0.97,1,0.8),5.0,true)

func label_style() -> StyleBoxFlat:
 var style:=StyleBoxFlat.new();style.bg_color=Color(1,0.9,0.68,0.9)
 style.corner_radius_top_left=8;style.corner_radius_top_right=8;style.corner_radius_bottom_left=8;style.corner_radius_bottom_right=8
 return style

func detach_patch(obj: Dictionary) -> void:
 for p in particles:
  if p.left>0:continue
  var sprite: Sprite2D=p.sprite
  sprite.texture=model.assets.texture(obj.type);sprite.scale=obj.rect.size/Vector2(sprite.texture.get_size())*(size/C.CANVAS)
  var material: ShaderMaterial=object_sprites[obj.id].sprite.material.duplicate()
  var white:=Image.create(2,2,false,Image.FORMAT_RGBA8);white.fill(Color.WHITE)
  material.set_shader_parameter("remaining_mask",ImageTexture.create_from_image(white));sprite.material=material
  sprite.position=obj.rect.get_center()*(size/C.CANVAS);sprite.rotation=obj.get("draw_angle",0.0);sprite.modulate=Color.WHITE;sprite.visible=true
  p.left=.45;p.total=.45;p.velocity=Vector2(90,-160)
  break

func draw_ellipse_shadow(rect: Rect2) -> void:
 var points:=PackedVector2Array()
 for i in range(48):points.append(rect.get_center()+Vector2(cos(TAU*i/48.0),sin(TAU*i/48.0))*rect.size*.5)
 draw_colored_polygon(points,Color(.08,.04,.025,.20))
