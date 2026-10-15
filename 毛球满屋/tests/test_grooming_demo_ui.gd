extends SceneTree
const C=preload("res://scripts/prototype_grooming/config.gd")
const REPORT="res://reports/prototype_grooming_20261014/"
var vp: SubViewport
var game: Control
var checks: int=0
var failures: Array=[]
var screenshots: Array=[]
var size_now:=Vector2i(1440,810)

func _initialize() -> void:call_deferred("run")

func check(ok: bool,text: String) -> void:
 checks+=1
 if not ok:failures.append(text);push_error(text)

func screen(point: Vector2) -> Vector2:return point*Vector2(size_now)/C.CANVAS

func motion(point: Vector2,held: bool=false) -> void:
 var event:=InputEventMouseMotion.new();event.position=screen(point);event.global_position=event.position;event.button_mask=MOUSE_BUTTON_MASK_LEFT if held else 0
 vp.push_input(event,true)

func button(point: Vector2,down: bool) -> void:
 if down:motion(point,false)
 var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=screen(point);event.global_position=event.position;event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
 vp.push_input(event,true)

func click_control(path: String) -> void:
 var control: Control=game.get_node(path)
 var p: Vector2=control.get_global_rect().get_center()/Vector2(size_now)*C.CANVAS
 button(p,true);button(p,false)
 await process_frame

func stroke(a: Vector2,b: Vector2,speed: float=0.2) -> void:
 button(a,true)
 await process_frame
 # Controlled event clock allows repeatable GUI-input tests independent of GPU frame speed.
 game.previous_tick=Time.get_ticks_usec()-int(a.distance_to(b)/game.model.body_rect.size.x/speed*1000000.0)
 motion(b,true);button(b,false)
 await process_frame

func valid_point(obj: Dictionary) -> Vector2:
 var best: Vector2=obj.rect.get_center()
 var distance: float=INF
 for y in range(C.OBJECT_GRID):
  for x in range(C.OBJECT_GRID):
   if obj.left[y*C.OBJECT_GRID+x]<=0:continue
   var p: Vector2=obj.rect.position+obj.rect.size*Vector2((x+0.5)/C.OBJECT_GRID,(y+0.5)/C.OBJECT_GRID)
   if p.distance_squared_to(obj.rect.get_center())<distance:best=p;distance=p.distance_squared_to(obj.rect.get_center())
 return best

func await_stage(wanted: String) -> void:
 var deadline: int=Time.get_ticks_msec()+4000
 while game.model.stage!=wanted and Time.get_ticks_msec()<deadline:await process_frame

func snapshot(name: String) -> void:
 await process_frame;await RenderingServer.frame_post_draw
 var image: Image=vp.get_texture().get_image()
 check(image.get_size()==size_now,"screenshot dimensions "+name)
 var filename: String=name+"_%dx%d.png"%[size_now.x,size_now.y]
 image.save_png(REPORT+filename);screenshots.append(filename)

func clean_gui() -> void:
 for pass_index in range(8):
  if game.model.stage!="cleaning":break
  # Real GUI events; short strokes keep each measured motion under the break timeout.
  for obj in game.model.objects:
   if obj.done:continue
   var r: Rect2=obj.rect
   for y in range(int(r.position.y)-25,int(r.end.y)+26,30):
    if game.model.stage!="cleaning":break
    for x in range(int(r.position.x)-25,int(r.end.x)+26,65):
     var a:=Vector2(x,y);var b:=Vector2(minf(x+65,r.end.x+26),y)
     await stroke(a,b,0.24)
     if game.model.stage!="cleaning":break

func nail_swipe(index: int,height: float) -> void:
 var n: Dictionary=game.model.nails[index]
 var edges: Vector2=game.model.nail_edges(n,height)
 var a:=Vector2(edges.x-15,n.root.y-height);var b:=Vector2(edges.y+15,n.root.y-height)
 button(a,true);await process_frame
 motion((a+b)/2,true);motion(b,true);button(b,false);await process_frame

func run() -> void:
 DirAccess.make_dir_recursive_absolute(REPORT)
 vp=SubViewport.new();vp.size=size_now;vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;vp.handle_input_locally=true;root.add_child(vp)
 game=load("res://scenes/prototype_grooming/main.tscn").instantiate();vp.add_child(game)
 await create_timer(0.6).timeout
 check(game.model.stage=="cleaning" and game.view.size==Vector2(size_now),"scene starts as playable service")
 check(game.view.object_sprites.size()==14,"runtime dirt masks are connected")
 await snapshot("calico_dirty")
 var obj: Dictionary=game.model.objects[0];var p: Vector2=valid_point(obj);var initial: float=obj.sum
 button(p-Vector2(45,0),true)
 for i in range(6):await create_timer(0.07).timeout;motion(p+Vector2(-30+15*i,0),true)
 button(p+Vector2(45,0),false)
 check(obj.sum<initial,"normal real-clock held mouse motion cleans")
 var remaining: float=obj.sum
 await create_timer(0.2).timeout
 check(obj.sum==remaining and not game.dragging,"release preserves progress and ends gesture")
 await stroke(p-Vector2(30,0),p+Vector2(30,0),0.24)
 check(obj.sum<remaining,"new gesture resumes local progress")
 await snapshot("calico_partial")
 await create_timer(C.PAIN_INTERVAL+0.1).timeout
 var score: int=game.model.score
 var untouched: Vector2=valid_point(game.model.objects[8])
 button(untouched-Vector2(15,0),true);await process_frame;game.previous_tick=Time.get_ticks_usec()-1000;motion(untouched+Vector2(15,0),true)
 button(untouched+Vector2(15,0),false)
 check(game.model.score==score-5,"GUI overspeed causes visible rating penalty")
 await snapshot("calico_pain")
 button(p,true);await process_frame
 motion(Vector2(580,75),true);await process_frame
 check(not game.dragging,"crossing HUD clears active gesture")
 button(Vector2(580,75),false)
 await click_control("HUD/Top/Retry");await create_timer(0.5).timeout
 check(game.model.score==100 and game.model.wallet==0,"retry resets order without awarding money")
 await clean_gui()
 check(game.model.stage=="reward" and game.model.wallet==100,"actual GUI strokes finish first service and pay once")
 await snapshot("calico_paid")
 var paid: int=game.model.wallet
 await await_stage("cleaning")
 check(game.model.kind=="robot" and game.model.wallet==paid,"automatic customer handoff")
 await snapshot("robot_dirty")
 await clean_gui()
 check(game.model.stage=="reward" and game.model.wallet==220,"actual GUI robot wiping finishes and pays")
 await snapshot("robot_paid")
 await await_stage("cleaning")
 check(game.model.order_index==2,"automatic full-service customer")
 await clean_gui();await await_stage("nails")
 check(game.model.stage=="nails" and game.model.wallet==220,"full service waits for required nails")
 await snapshot("nails_before")
 var h: float=game.model.quick_height+C.NAIL_BAND_WIDTH+35
 await nail_swipe(0,h)
 check(game.model.nails[0].result=="shallow" and not game.model.nails[0].done,"actual swipe makes shallow partial cut")
 await snapshot("nail_shallow")
 await nail_swipe(0,game.model.perfect_height())
 check(game.model.nails[0].result=="perfect","actual swipe completes remaining nail")
 await nail_swipe(1,game.model.quick_height-12)
 check(game.model.score==80 and game.model.nails[1].result=="deep","actual deep swipe lowers rating")
 await create_timer(0.3).timeout
 await snapshot("nail_deep")
 for index in [2,3]:await nail_swipe(index,game.model.perfect_height())
 check(game.model.stage=="reward" and game.model.wallet==348 and game.model.served==3,"rating-based third settlement without modal")
 await snapshot("nails_paid")
 await click_control("HUD/Top/Pause")
 var time: float=game.model.now;await create_timer(0.2).timeout
 check(game.paused and game.model.now==time,"pause button freezes gameplay")
 await click_control("HUD/PausePanel/VBox/Continue")
 check(not game.paused,"continue button resumes gameplay")
 await click_control("HUD/Top/Nails")
 check(game.model.stage=="nails","debug nail order is directly playable")
 await click_control("HUD/Top/Sound")
 check(not game.sound_enabled,"sound toggle")
 button(Vector2(700,330),true);await process_frame
 game._notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
 check(not game.dragging and game.nail_points.is_empty(),"focus loss cancels incomplete gesture")
 button(Vector2(700,330),false)
 button(Vector2(700,330),true);await process_frame;motion(Vector2(715,330),false)
 check(not game.dragging,"returning without held button cancels a lost release")
 var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;vp.push_input(escape,true);await process_frame
 check(game.paused,"escape opens pause")
 await click_control("HUD/PausePanel/VBox/Continue")
 size_now=Vector2i(1920,1080);vp.size=size_now
 await process_frame;await process_frame
 await snapshot("nails_before")
 await nail_swipe(0,game.model.perfect_height())
 check(game.model.nails[0].done,"mouse mapping remains correct at 1920x1080")
 await snapshot("nail_one_done")
 await click_control("HUD/Top/Robot");await create_timer(0.6).timeout
 await snapshot("robot_dirty")
 obj=game.model.objects[0];p=valid_point(obj);initial=obj.sum
 await stroke(p-Vector2(25,0),p+Vector2(25,0),0.24)
 check(obj.sum<initial,"cleaning mapping remains correct at 1920x1080")
 await snapshot("robot_partial")
 var results: Dictionary={"checks":checks,"failures":failures,"screenshots":screenshots,"input":"SubViewport GUI InputEventMouseButton/MouseMotion; first stroke real clock, repeat strokes controlled event timestamps","rendering_method":"gl_compatibility","display_server":DisplayServer.get_name(),"served":game.model.served,"wallet":game.model.wallet}
 FileAccess.open(REPORT+"ui_results.json",FileAccess.WRITE).store_string(JSON.stringify(results," "))
 print("GROOMING UI: ",checks," checks, ",failures.size()," failures, ",screenshots.size()," screenshots")
 game.queue_free();vp.queue_free();await process_frame
 quit(0 if failures.is_empty() else 1)
