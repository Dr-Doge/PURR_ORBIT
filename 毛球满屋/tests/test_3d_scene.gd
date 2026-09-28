extends SceneTree
var game
var checks: int=0
var failures: int=0
func _initialize() -> void:
 root.size=Vector2i(1440,900);call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func motion(at: Vector2) -> void:
 var event:=InputEventMouseMotion.new();event.position=at;root.push_input(event,true)
func press_button(caption: String) -> bool:
 for node in game.body.find_children("*","Button",true,false):
  if node.text==caption and node.is_visible_in_tree():
   var at: Vector2=node.get_global_rect().get_center()
   motion(at);click(at);click(at,false)
   return true
 return false
func click(at: Vector2,pressed: bool=true) -> void:
 var event:=InputEventMouseButton.new();event.position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;root.push_input(event,true)
func room_covers(at: Vector2) -> bool:
 # Dark metal is valid artwork; test physical coverage instead of pixel brightness.
 var room=game.room
 var origin: Vector3=room.camera.global_position
 var ray: Vector3=room.actor_lighting.ray_at(at)
 var epsilon: float=0.002
 var p=Plane(Vector3.UP,0).intersects_ray(origin,ray)
 if p!=null and absf(p.x)<=room.room_half_width+epsilon and p.z>=room.FLOOR_BACK-epsilon and p.z<=room.FLOOR_FRONT+epsilon:return true
 p=Plane(Vector3.BACK,room.FLOOR_BACK).intersects_ray(origin,ray)
 if p!=null and absf(p.x)<=room.room_half_width+epsilon and p.y>=-epsilon and p.y<=6+epsilon:return true
 for side in [-1,1]:
  p=Plane(Vector3.RIGHT,side*room.room_half_width).intersects_ray(origin,ray)
  if p!=null and p.z>=room.FLOOR_BACK-epsilon and p.z<=room.FLOOR_FRONT+epsilon and p.y>=-epsilon and p.y<=6+epsilon:return true
 return false
func capture(file: String) -> void:
 await process_frame;await process_frame
 await RenderingServer.frame_post_draw
 var picture: Image=root.get_texture().get_image()
 picture.save_png(ProjectSettings.globalize_path("res://reports/merge_3d_928/"+file+".png"))
 var covered: bool=true
 for i in range(11):
  var x: int=roundi((picture.get_width()-1)*i/10.0)
  var y: int=roundi((picture.get_height()-1)*i/10.0)
  for at in [Vector2i(x,0),Vector2i(x,picture.get_height()-1),Vector2i(0,y),Vector2i(picture.get_width()-1,y)]:
   var canvas_point: Vector2=Vector2(at)*game.room.size/Vector2(picture.get_size())
   if not room_covers(canvas_point):covered=false
 check(covered,"No black exterior at canvas edges: "+file)
func run() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/merge_3d_928"))
 game=load("res://scenes/3D scene.tscn").instantiate();game.testing=true;root.add_child(game)
 await process_frame;await process_frame
 check(game.modal=="start","Start screen available")
 await capture("00_start")
 check(game.hud.title_art.visible,"Original cover is visible")
 check(press_button("开始游戏"),"Start button is reachable")
 await process_frame;await process_frame
 if game.modal=="new_confirm":
  check(press_button("确认开始新游戏"),"New game confirmation is reachable")
  await process_frame;await process_frame
 check(game.active and game.modal=="" and game.room.interactive,"Mouse clicks enter the playable 3D scene")
 check(not game.hud.title_art.visible,"Cover hides after starting")
 game.set_process(false)
 var room=game.room
 check(room.shell.get_children().filter(func(n):return n is MeshInstance3D).size()==4,"Exactly four room planes")
 var upper: Vector2=room.camera.unproject_position(Vector3(-room.room_half_width,6,room.FLOOR_BACK))
 var lower: Vector2=room.camera.unproject_position(Vector3(-room.room_half_width,0,room.FLOOR_BACK))
 var right: Vector2=room.camera.unproject_position(Vector3(room.room_half_width,0,room.FLOOR_BACK))
 check(absf(upper.x-lower.x)<0.1 and absf(lower.y-right.y)<0.1,"Back wall stays rectangular in one-point perspective")
 var front_left: Vector2=room.camera.unproject_position(Vector3(-room.room_half_width,0,room.FLOOR_FRONT))
 var front_right: Vector2=room.camera.unproject_position(Vector3(room.room_half_width,0,room.FLOOR_FRONT))
 var floor_visible: bool=true
 for p in [lower,right,front_left,front_right]:
  if p.x < -1 or p.x > room.size.x+1 or p.y < 0 or p.y > room.size.y:floor_visible=false
 check(floor_visible,"All four floor corners fit inside canvas")
 check(absf((front_right.x-front_left.x)/(right.x-lower.x)-1.11)<0.01,"Floor perspective width difference is only 11 percent")
 check(absf(front_left.y-room.size.y)<1,"Floor reaches canvas bottom without a footer")
 check((front_left.y-lower.y)/room.size.y>0.70,"Complete floor remains dominant")
 check(room.object_scale(Vector2(720,510))>=1.2,"Cats have an enlarged interactive presentation")
 for at in [Vector2(150,340),Vector2(720,510),Vector2(1250,680)]:
  check(room.world(room.screen_position(at)).distance_to(at)<0.1,"Camera inverse projection "+str(at))
 var c: Dictionary=game.model.cats[0]
 c.pos=Vector2(680,530);c.dest=c.pos;c.layers=2
 room.step(0)
 for i in range(10):
  motion(room.screen_position(c.pos)+Vector2(-18 if i%2 else 18,0));await process_frame
 check(game.model.harvests>0,"Projected mouse motion harvests cat")
 click(room.screen_position(c.pos));await process_frame
 check(room.dragging==c.id,"Projected click starts cat drag")
 var target:=Vector2(840,610)
 motion(room.screen_position(target));await process_frame
 click(room.screen_position(target),false);await process_frame
 check(room.dragging==-1 and c.pos.distance_to(target)<1,"Drag release places cat at projected floor point")
 for corner in [Vector2(123,330),Vector2(1317,330),Vector2(123,713),Vector2(1317,713)]:
  click(room.screen_position(c.pos));motion(room.screen_position(corner));click(room.screen_position(corner),false)
  await process_frame
  check(c.pos.distance_to(corner)<1,"Cat can reach floor corner "+str(corner))
  var foot: Vector2=room.screen_position(c.pos)+Vector2(0,26)*room.object_scale(c.pos)
  check(foot.y>room.size.y*0.28 and foot.y<room.size.y*0.98,"Foot stays inside textured floor")
 c.pos=target;c.dest=target;room.step(0)
 game.hud.set_open(true)
 check(game.hud.drawer.visible and not room.interactive,"Drawer opens and blocks room input")
 game.hud.set_open(false)
 check(not game.hud.drawer.visible and room.interactive,"Drawer closes and restores input")
 for item in ["shop","tree","workers","inventory","gacha","pause"]:
  check(game.nav_buttons.has(item),"Existing feature wired: "+item)
 game.show_shop();check(game.modal=="shop","Shop opens");game.close_modal()
 game.show_tree();check(game.modal=="tree","Research opens");game.close_modal()
 game.model.wallet=100000
 game.model.researches["worker"]=true
 game.model.researches["feeder"]=true
 room.placing="feeder"
 var place:=Vector2(400,590)
 click(room.screen_position(place));click(room.screen_position(place),false);await process_frame
 check(game.model.facilities.size()>0,"Facility placement through projected mouse input")
 if not game.model.facilities.is_empty():
  click(room.screen_position(game.model.facilities[0].pos));click(room.screen_position(game.model.facilities[0].pos),false)
  check(game.modal=="facility","Facility management opens from scene");game.close_modal()
 game.model.first_token=true;game.model.gacha_ready=true;game.model.tokens=2
 room.step(0);game.refresh()
 click(room.screen_position(room.gacha_position));click(room.screen_position(room.gacha_position),false)
 check(game.modal=="gacha","Gacha machine opens from scene");game.close_modal()
 var snapshot: Dictionary=game.model.snapshot()
 check(game.Model.new().restore(snapshot),"Existing save schema remains compatible")
 room.step(2.0)
 check(room.shell.get_node("BackWall").material_override.get_shader_parameter("orbit_angle")>0,"Universe rotation advances")
 for kind in ["giant","static","lucky","alien"]:
  var added: Dictionary=game.model.add_cat(Vector2(440+game.model.cats.size()*140,470));added.kind=kind;added.layers=2
 room.step(0);game.refresh()
 await capture("01_whitebox")
 game.hud.set_open(true);await capture("02_drawer");game.hud.set_open(false)
 root.size=Vector2i(960,600);await process_frame;await process_frame
 check(room.world(room.screen_position(target)).distance_to(target)<0.1,"Resize preserves pointer projection")
 await capture("03_small_window")
 root.size=Vector2i(1280,720);await process_frame;await process_frame
 check(room.presentation.size.distance_to(room.size)<1,"Viewport fills widescreen canvas")
 check(room.world(room.screen_position(target)).distance_to(target)<0.1,"Widescreen pointer projection")
 await capture("04_widescreen")
 root.size=Vector2i(960,600);await process_frame;await process_frame
 game.active=false;game.show_start()
 await process_frame;await process_frame
 await capture("00_start_small")
 check(press_button("开始游戏"),"Small window start button is reachable")
 await process_frame;await process_frame
 if game.modal=="new_confirm":
  check(press_button("确认开始新游戏"),"Small window confirmation is reachable")
  await process_frame;await process_frame
 check(game.active and game.modal=="","Small window mouse clicks enter game")
 print("3D SCENE: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
