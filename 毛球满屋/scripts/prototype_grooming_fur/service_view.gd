extends Control
const C=preload("res://scripts/prototype_grooming/config.gd")
const CleaningShader=preload("res://scripts/prototype_grooming_fur/coat_cleaning.gdshader")
const Brush=preload("res://scripts/prototype_grooming_fur/brush_config.gd")
const Tool=preload("res://scripts/prototype_grooming_fur/tool_geometry.gd")
var game: Control
var model: RefCounted
var subject: Node2D
var platform: Node2D
var table: Sprite2D
var shadow: Node2D
var base: Sprite2D
var dirt: Node2D
var object_sprites: Dictionary={}
var particles: Array=[]
var tool: Sprite2D
var model_version: int=-1
var mouse: Vector2=Vector2(1470,550)
var body_texture: ImageTexture
var actor_transform:=Transform2D.IDENTITY
var last_stage: String=""
var foreground: Node2D
var fx_rng:=RandomNumberGenerator.new()
var last_variant: String=""

func _ready() -> void:
 fx_rng.randomize()
 var preview: Node=get_parent().get_node_or_null("EditorPreview")
 if preview!=null:preview.hide()
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 mouse_filter=Control.MOUSE_FILTER_STOP
 platform=get_node("PlatformRoot")
 table=platform.get_node("Table")
 shadow=Node2D.new();shadow.name="ContactShadow";shadow.set_script(preload("res://scripts/prototype_grooming_fur/platform_shadow.gd"));shadow.view=self;shadow.z_index=1;platform.add_child(shadow)
 subject=Node2D.new();subject.name="SubjectRoot";subject.z_index=2;platform.add_child(subject)
 base=Sprite2D.new();base.name="CleanSubject";subject.add_child(base)
 dirt=Node2D.new();dirt.name="RemovableDirt";subject.add_child(dirt)
 tool=Sprite2D.new();tool.name="ToolCursor";add_child(tool);tool.z_index=20
 foreground=Node2D.new();foreground.name="InteractionGuides";foreground.set_script(preload("res://scripts/prototype_grooming/foreground.gd"));foreground.view=self;foreground.z_index=30;add_child(foreground)
 for i in range(Brush.PARTICLE_INITIAL_POOL):create_particle()
 resized.connect(layout)
 layout()

func layout() -> void:
 var scale_factor: Vector2=size/C.CANVAS
 subject.scale=scale_factor;tool.scale=scale_factor
 if model!=null:sync()
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
   material.set_shader_parameter("match_coat",true)
   material.set_shader_parameter("preserve_outline",obj.rule=="edge")
   if model.kind=="calico":
    var white:=Image.create(2,2,false,Image.FORMAT_RGBA8);white.fill(Color.WHITE)
    material.set_shader_parameter("body_mask",ImageTexture.create_from_image(white))
   var uv: Vector2=(obj.rect.position-model.body_rect.position)/model.body_rect.size
   var uv_size: Vector2=obj.rect.size/model.body_rect.size
   material.set_shader_parameter("region_in_body",Vector4(uv.x,uv.y,uv_size.x,uv_size.y))
   material.set_shader_parameter("patch_angle",obj.get("draw_angle",0.0))
   material.set_shader_parameter("patch_dimensions",obj.rect.size)
   material.set_shader_parameter("source_dimensions",Vector2(sprite.texture.get_size()))
   material.set_shader_parameter("complete_sprite",model.kind=="calico")
   sprite.rotation=obj.get("draw_angle",0.0)
   sprite.flip_h=obj.get("flip_h",false);sprite.flip_v=obj.get("flip_v",false)
   sprite.z_index=1 if obj.rule=="edge" else 2
   material.set_shader_parameter("source_mirror",Vector2(-1 if sprite.flip_h else 1,-1 if sprite.flip_v else 1))
   sprite.material=material;sprite.position=obj.rect.get_center();sprite.scale=obj.rect.size/Vector2(sprite.texture.get_size())
   dirt.add_child(sprite)
   object_sprites[obj.id]={"sprite":sprite,"texture":mask_texture,"version":-1}
  for p in particles:p.left=0.0;p.sprite.visible=false
 dirt.visible=true
 var name: String="calico_clean"
 base.texture=model.assets.texture(name)
 base.material=null
 var box: Rect2=C.BODY_BOX
 var factor: float=minf(box.size.x/base.texture.get_width(),box.size.y/base.texture.get_height())
 var drawn: Vector2=Vector2(base.texture.get_size())*factor
 var rect: Rect2=model.body_rect
 base.position=rect.get_center();base.scale=rect.size/Vector2(base.texture.get_size())
 var table_rect: Rect2=model.assets.presentation.table_rect
 table.texture=model.assets.texture("grooming_table")
 table.position=table_rect.get_center()*(size/C.CANVAS)
 table.scale=table_rect.size/Vector2(table.texture.get_size())*(size/C.CANVAS)
 platform.position=Vector2(0,model.platform_offset)*(size/C.CANVAS)
 shadow.queue_redraw()
 for obj in model.objects:
  var entry: Dictionary=object_sprites[obj.id]
  if entry.sprite.visible and obj.done:detach_patch(obj)
  entry.sprite.position=obj.rect.get_center()
  entry.sprite.visible=not obj.done
  entry.sprite.material.set_shader_parameter("pull_amount",obj.pull_amount)
  if entry.version!=obj.version:
   entry.texture.update(obj.mask);entry.version=obj.version
   entry.sprite.material.set_shader_parameter("loosen",1.0)
 tool.texture=model.assets.texture("comb")
 tool.visible=model.stage=="cleaning" and not model.paused
 tool.rotation=-Tool.rotation_angle();tool.flip_h=true
 tool.scale=Vector2.ONE*Tool.texture_scale()*(size/C.CANVAS)
 var active: bool=game!=null and game.dragging and not model.paused
 var offset: Vector2=Tool.center_offset(Vector2(tool.texture.get_size()))
 if not active:tool.rotation+=Tool.IDLE_TILT;offset=offset.rotated(Tool.IDLE_TILT)+Tool.IDLE_LIFT
 tool.position=(mouse+offset)*(size/C.CANVAS)
 actor_transform=Transform2D(0.0,Vector2(0,model.platform_offset+model.cat_inertia))
 subject.transform=Transform2D(0.0,Vector2(0,model.cat_inertia)).scaled(size/C.CANVAS)
 subject.modulate=Color.WHITE
 last_stage=model.stage
 foreground.queue_redraw()
 queue_redraw()

func animate(dt: float) -> void:
 for p in particles:
  if p.left<=0:continue
  p.left=maxf(0,p.left-dt)
  p.velocity.y=minf(Brush.PARTICLE_MAX_SPEED,p.velocity.y+Brush.PARTICLE_GRAVITY*dt)
  p.sprite.position+=p.velocity*dt*(size/C.CANVAS)
  p.sprite.rotation+=dt*p.angular
  var elapsed: float=p.total-p.left
  p.sprite.modulate.a=p.alpha*(1.0 if elapsed<=Brush.PARTICLE_ALPHA_HOLD else clampf(p.left/(p.total-Brush.PARTICLE_ALPHA_HOLD),0,1))
  p.sprite.visible=p.left>0
 sync()

func burst(name: String,at: Vector2,count: int=1) -> void:
 # One independently cut clump or shard; cap FX without affecting grooming.
 if active_particles("loose")>=Brush.LOOSE_LIMIT:return
 var palette: String="cream" if name.contains("cream") else "gray"
 var role: String="shard" if fx_rng.randf()<.55 else "clump"
 var variant: String=choose_fall_variant(palette,role)
 var p: Dictionary=available_particle()
 var sprite: Sprite2D=p.sprite;sprite.texture=model.assets.texture(variant);sprite.material=null
 var widths: Vector2=Brush.SHARD_WIDTH if role=="shard" else Brush.PARTICLE_WIDTH
 var width: float=fx_rng.randf_range(widths.x,widths.y)
 sprite.scale=Vector2.ONE*(width/sprite.texture.get_width())*(size/C.CANVAS)
 sprite.position=at*(size/C.CANVAS);sprite.rotation=fx_rng.randf_range(-PI,PI);sprite.flip_h=fx_rng.randf()<.5
 p.variant=variant;p.source_id=-1;prepare_fall(p,"loose")

func choose_fall_variant(palette: String,role: String="") -> String:
 var variants: Array=[]
 for key in model.assets.fall_index.sprites:
  var entry: Dictionary=model.assets.fall_index.sprites[key]
  if entry.palette==palette and (role.is_empty() or entry.role==role):variants.append(key)
 var choices: Array=variants.filter(func(key):return key!=last_variant)
 var variant: String=choices[fx_rng.randi_range(0,choices.size()-1)]
 last_variant=variant
 return variant

func create_particle() -> Dictionary:
 var sprite:=Sprite2D.new();sprite.visible=false;sprite.z_index=15;platform.add_child(sprite)
 var p: Dictionary={"sprite":sprite,"left":0.0,"total":Brush.PARTICLE_TIME,"velocity":Vector2.ZERO,"kind":"","alpha":1.0,"angular":0.0,"variant":"","source_id":-1}
 particles.append(p)
 return p

func available_particle() -> Dictionary:
 for p in particles:
  if p.left<=0:return p
 # Detached patches must never vanish because cosmetic slots are occupied.
 # Pool grows only to this finite coat plus loose FX, then reuses idle slots.
 return create_particle()

func active_particles(kind: String) -> int:
 var count: int=0
 for p in particles:
  if p.left>0 and p.kind==kind:count+=1
 return count

func prepare_fall(p: Dictionary,kind: String) -> void:
 p.left=Brush.PARTICLE_TIME;p.total=Brush.PARTICLE_TIME
 p.kind=kind;p.alpha=Brush.DETACHED_ALPHA if kind=="detached" else Brush.LOOSE_ALPHA
 p.angular=fx_rng.randf_range(-Brush.PARTICLE_ANGULAR,Brush.PARTICLE_ANGULAR)
 p.velocity=Vector2(fx_rng.randf_range(-Brush.PARTICLE_HORIZONTAL,Brush.PARTICLE_HORIZONTAL),fx_rng.randf_range(Brush.PARTICLE_START_SPEED.x,Brush.PARTICLE_START_SPEED.y))
 p.sprite.modulate=Color(1,1,1,p.alpha);p.sprite.visible=true

func _gui_input(event: InputEvent) -> void:
 if game!=null:game.surface_input(event)

func _draw() -> void:
 if model==null:return
 draw_set_transform(Vector2.ZERO,0.0,size/C.CANVAS)
 draw_texture_rect(model.assets.texture("room_background"),Rect2(Vector2.ZERO,C.CANVAS),false)
 # Room is static. Contact shadow is drawn after the table by its platform child.

func draw_foreground(canvas: Node2D) -> void:
 if model==null or model.stage!="cleaning":return
 canvas.draw_set_transform(Vector2.ZERO,0.0,size/C.CANVAS)
 for obj in model.objects:
  if obj.done or not obj.rect.grow(18).has_point(mouse):continue
  var text: String="回弹后脱落" if obj.detach_pending else "已梳 %d/2 · 向右再梳"%obj.passes
  canvas.draw_string(ThemeDB.fallback_font,mouse+Vector2(30,-65),text,HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color(1,.9,.65));break
 var active: bool=game!=null and game.dragging
 var color:=Color(.35,1,.95,.95) if active else Color(.8,.85,.9,.55)
 if active:
  var points: PackedVector2Array=Tool.edge_points(mouse)
  canvas.draw_line(points[0],points[1],color,3,true)
  for point in points:canvas.draw_line(point-Vector2(6,0),point+Vector2(6,0),color,2,true)
 canvas.draw_string(ThemeDB.fallback_font,mouse+Vector2(35,95),"已激活 · 向右梳 →" if active else "已抬起 · 按住左键开始",HORIZONTAL_ALIGNMENT_LEFT,-1,21,color)

func detach_patch(obj: Dictionary) -> void:
 # One larger loose-fur graphic per source, instead of the dense outlined tile.
 var p: Dictionary=available_particle()
 var sprite: Sprite2D=p.sprite
 var palette: String="cream" if obj.type.begins_with("cream") or obj.type.begins_with("edge_cream") else "gray"
 var variant: String=choose_fall_variant(palette)
 sprite.texture=model.assets.texture(variant);sprite.material=null
 var target: Vector2=obj.rect.size*fx_rng.randf_range(Brush.DETACHED_SIZE_RATIO.x,Brush.DETACHED_SIZE_RATIO.y)
 var dimensions:=Vector2(sprite.texture.get_size())
 sprite.scale=Vector2.ONE*minf(target.x/dimensions.x,target.y/dimensions.y)*(size/C.CANVAS)
 sprite.position=obj.rect.get_center()*(size/C.CANVAS);sprite.rotation=obj.get("draw_angle",0.0)+fx_rng.randf_range(-.65,.65);sprite.flip_h=fx_rng.randf()<.5
 p.variant=variant;p.source_id=obj.id;prepare_fall(p,"detached")
