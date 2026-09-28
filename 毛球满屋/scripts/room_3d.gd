extends "res://scripts/room.gd"
## 3D shell with camera-projected 2D actors. Simulation coordinates stay unchanged.
var view: SubViewport
var camera: Camera3D
var shell: Node3D
var presentation: SubViewportContainer
var actor_lighting
const PLAY_TOP = 0.26
const PLAY_BOTTOM = 0.95
const FRUSTUM_HEIGHT = 0.06
const FRUSTUM_OFFSET = -0.4056
const FLOOR_FRONT = 3.090909
const FLOOR_BACK = -6.91743
var room_half_width: float = 12.0
func _ready() -> void:
 gacha_position=Vector2(1190,465)
 super._ready()
 backdrop.hide()
 presentation=SubViewportContainer.new()
 presentation.name="WhiteboxViewport"
 presentation.mouse_filter=Control.MOUSE_FILTER_IGNORE
 presentation.show_behind_parent=true
 presentation.stretch=true
 add_child(presentation);move_child(presentation,0)
 view=SubViewport.new();view.name="World3D"
 view.size=Vector2i(size);view.own_world_3d=true
 view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 view.msaa_3d=Viewport.MSAA_2X
 # Reserve large atlas tiles for the room lights instead of the default small tiles.
 view.positional_shadow_atlas_size=4096
 view.positional_shadow_atlas_quad_0=Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_1
 view.positional_shadow_atlas_quad_1=Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_1
 view.positional_shadow_atlas_quad_2=Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_4
 view.positional_shadow_atlas_quad_3=Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_16
 presentation.add_child(view)
 shell=preload("res://scenes/whitebox_room.tscn").instantiate()
 view.add_child(shell)
 camera=shell.get_node("Camera")
 # A level camera keeps the back wall rectangular. An off-axis frustum puts
 # the vanishing point above the canvas, exposing the floor without tilting.
 camera.rotation=Vector3.ZERO
 camera.set_frustum(FRUSTUM_HEIGHT,Vector2(0,FRUSTUM_OFFSET),1.0,200.0)
 actor_lighting=preload("res://scripts/actor_lighting_3d.gd").new()
 actor_lighting.room=self;shell.add_child(actor_lighting)
 resized.connect(resize_world)
 resize_world()
func resize_world() -> void:
 if presentation==null:return
 presentation.position=Vector2.ZERO
 presentation.size=size
 if camera==null or size.y<=0:return
 # Rear/front width ratio is 1:1.10; all four floor corners are on screen.
 room_half_width=(camera.position.z-FLOOR_FRONT)*FRUSTUM_HEIGHT*(size.x/size.y)*0.5
 shell.get_node("Floor").mesh.size=Vector2(room_half_width*2,FLOOR_FRONT-FLOOR_BACK)
 shell.get_node("Floor").material_override.set_shader_parameter("half_width",room_half_width)
 shell.get_node("BackWall").mesh.size=Vector2(room_half_width*2,6)
 shell.get_node("BackWall").material_override.set_shader_parameter("canvas_size",size)
 shell.get_node("LeftWall").position.x=-room_half_width
 shell.get_node("RightWall").position.x=room_half_width
 for name in ["Left","LeftFront"]:
  shell.get_node("Frames/"+name).position.x=-room_half_width
 for name in ["Right","RightFront"]:
  shell.get_node("Frames/"+name).position.x=room_half_width
func horizontal_span(z: float) -> float:
 var distance: float=camera.position.z-z
 var visible_half: float=distance*FRUSTUM_HEIGHT*(size.x/size.y)*0.5
 return minf(room_half_width*0.96,visible_half*0.94)
func point_3d(at: Vector2) -> Vector3:
 var uv: Vector2=(at-D.FLOOR.position)/D.FLOOR.size
 var screen_y: float=lerpf(PLAY_TOP,PLAY_BOTTOM,uv.y)
 var ray_y: float=(0.5-screen_y)*FRUSTUM_HEIGHT+FRUSTUM_OFFSET
 var distance: float=-camera.position.y/ray_y
 var z: float=camera.position.z-distance
 return Vector3((uv.x*2.0-1.0)*horizontal_span(z),0,z)
func screen_position(at: Vector2) -> Vector2:
 if camera==null:return super.screen_position(at)
 return presentation.position+camera.unproject_position(point_3d(at))
func project(at: Vector2) -> Vector2:
 return (screen_position(at)-stage_origin())/stage_scale()
func world(at: Vector2) -> Vector2:
 if camera==null:return super.world(at)
 var local: Vector2=at-presentation.position
 # Invert the actual off-axis projection, including its frustum offset.
 var ndc:=Vector4(local.x/size.x*2.0-1.0,1.0-local.y/size.y*2.0,-1.0,1.0)
 var near_point: Vector4=camera.get_camera_projection().inverse()*ndc
 var origin: Vector3=camera.global_position
 var ray: Vector3=camera.global_basis*Vector3(near_point.x,near_point.y,near_point.z)/near_point.w
 if absf(ray.y)<0.0001:return Vector2(-9999,-9999)
 var p: Vector3=origin+ray*(-origin.y/ray.y)
 var screen_y: float=camera.unproject_position(p).y/size.y
 var uv:=Vector2((p.x/horizontal_span(p.z)+1.0)*0.5,(screen_y-PLAY_TOP)/(PLAY_BOTTOM-PLAY_TOP))
 return D.FLOOR.position+uv*D.FLOOR.size
func object_scale(at: Vector2) -> float:
 if camera==null:return super.object_scale(at)
 var depth: float=clampf((at.y-D.FLOOR.position.y)/D.FLOOR.size.y,0,1)
 return minf(size.x/1440.0,size.y/900.0)*lerpf(1.30,1.43,depth)
func reward_target(token: bool = false) -> Vector2:
 return Vector2(size.x-175 if token else 165,48)
func text(at: Vector2,value: String,sz: int = 16,color: Color = INK) -> void:
 # World captions need contrast on the whitebox floor; the hover card is dark.
 var ink:=Color("334452")
 if at==Vector2(310,757):ink=color
 ink.a=color.a
 super.text(at,value,sz,ink)
func station_at(at: Vector2) -> int:
 var p: Vector2=screen_position(at)
 var ordered: Array=model.facilities.duplicate()
 ordered.sort_custom(func(a: Dictionary,b: Dictionary):return a.pos.y>b.pos.y)
 for f in ordered:
  var factor: float=object_scale(f.pos)
  var rect:=Rect2(screen_position(f.pos)+Vector2(-90,-110)*factor,Vector2(180,180)*factor)
  if rect.has_point(p):return f.id
 return -1
func _gui_input(event: InputEvent) -> void:
 if interactive and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and dragging<0 and placing=="" and moving_id<0 and model.gacha_ready:
  var factor: float=object_scale(gacha_position)
  var rect:=Rect2(screen_position(gacha_position)+Vector2(-88,-129)*factor,Vector2(176,211)*factor)
  if rect.has_point(event.position) and cat_at(world(event.position))<0:
   gacha_selected.emit();accept_event();return
 super._gui_input(event)
func step(dt: float) -> void:
 super.step(dt)
 # Draw the machine inside the same depth ordering as cats and devices.
 harvest_art.machine.hide()
 if shell!=null:
  var wall: MeshInstance3D=shell.get_node("BackWall")
  wall.material_override.set_shader_parameter("orbit_angle",clock*TAU/Backdrop.ORBIT_SECONDS)
  actor_lighting.sync()
func draw_cat(c: Dictionary) -> void:
 if c.id==hover:
  draw_arc(c.pos,43*cat_extent(c)/100.0,0,TAU,32,MINT,2)
  if c.pet>0:draw_arc(c.pos,47*cat_extent(c)/100.0,-PI/2,-PI/2+TAU*model.pet_progress(c),32,GOLD,3)
  if c.kind=="alien":draw_arc(c.pos,180,0,TAU,50,Color(MINT,0.25),1)
 if c.station>=0:text(c.pos+Vector2(-25,47),"设施使用中",11,Color("8dadaf"))
func draw_facility(f: Dictionary) -> void:
 var caption: String=D.title(f.kind)
 if f.kind=="feeder":caption="猫粮 %d/%d"%[f.grain,model.feed_capacity()]
 elif f.kind=="sun":caption="日光浴 %d/%d"%[model.occupants(f.id).size(),model.capacity(f)]
 elif f.broken:caption="黑屏 · 捶打"
 text(f.pos+Vector2(-50,82),caption,14,GOLD)
 if f.bugs>0:text(f.pos+Vector2(20,-50),"虫！",16,Color("c96f78"))
 if pointer.distance_to(f.pos)<70 and interactive:draw_arc(f.pos,85,0,TAU,40,Color(MINT,0.65),2)
func draw_worker(w: Dictionary) -> void:
 text(w.pos+Vector2(-25,39),w.status,11,Color("a1b8c7"))
func draw_entities() -> void:
 var entries: Array=[]
 for f in model.facilities:entries.append({"kind":"facility","data":f,"at":f.pos})
 for c in model.cats:entries.append({"kind":"cat","data":c,"at":c.pos})
 for w in model.workers:entries.append({"kind":"worker","data":w,"at":w.pos})
 if model.gacha_ready:entries.append({"kind":"gacha","at":gacha_position})
 entries.sort_custom(func(a: Dictionary,b: Dictionary):return a.at.y<b.at.y)
 for entry in entries:
  object_transform(entry.at)
  match entry.kind:
   "facility":draw_facility(entry.data)
   "cat":draw_cat(entry.data)
   "worker":draw_worker(entry.data)
   "gacha":draw_gacha()
func cat_at(at: Vector2) -> int:
 # Hit-test visible bodies, not the foreshortened floor distance.
 var pointer_screen: Vector2=screen_position(at)
 var ordered: Array=model.cats.duplicate()
 ordered.sort_custom(func(a: Dictionary,b: Dictionary):return a.pos.y>b.pos.y)
 for c in ordered:
  var rect: Rect2=cat_rect(c)
  var factor: float=object_scale(c.pos)
  var visible_rect:=Rect2(screen_position(c.pos)+(rect.position-c.pos)*factor,rect.size*factor)
  if visible_rect.grow(3).has_point(pointer_screen):return c.id
 return -1
