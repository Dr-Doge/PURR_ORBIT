extends SceneTree
const OUT="res://reports/grooming_robot_coverage_20261016/"
var checks: int=0
var failures: Array=[]
var vp: SubViewport
var game: Control
var alpha_result: Dictionary={}
var screenshots: Array=[]
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func event_at(point: Vector2,button: int=0,held: bool=true) -> void:
 var actual: Vector2=point*Vector2(vp.size)/Vector2(1920,1080)
 if button!=0:
  var e:=InputEventMouseButton.new();e.position=actual;e.global_position=actual;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=button==1;vp.push_input(e,true)
 else:
  var e:=InputEventMouseMotion.new();e.position=actual;e.global_position=actual;e.button_mask=MOUSE_BUTTON_MASK_LEFT if held else 0;vp.push_input(e,true)
func click(point: Vector2) -> void:event_at(point,0,false);event_at(point,1);event_at(point,2)
func button(path: String) -> void:
 var control: Control=game.get_node(path)
 var point: Vector2=control.get_global_rect().get_center()*Vector2(1920,1080)/Vector2(vp.size)
 click(point)
 await process_frame
func brush(a: Vector2,b: Vector2,steps: int=8) -> void:
 event_at(a,0,false);event_at(a,1)
 for i in range(1,steps+1):
  event_at(a.lerp(b,float(i)/steps));game.flush_paths()
 event_at(b,2);game.view.sync();game.update_ui();await process_frame
func frames() -> void:
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
func capture(name: String) -> void:
 await frames()
 var target: String=OUT+name+".png"
 if FileAccess.file_exists(target):target=OUT+name+"_"+str(Time.get_ticks_msec())+".png"
 check(vp.get_texture().get_image().save_png(target)==OK,"Screenshot written: "+name)
 screenshots.append(target)
func advance(seconds: float) -> void:
 for i in int(ceil(seconds/.02)):game._process(.02)
func fingerprint() -> String:
 return JSON.stringify(game.model.objects.map(func(o):return [o.type,str(o.rect),o.opacity]))
func finish_mouse() -> void:
 for cycle in 14:
  for obj in game.model.objects:
   if obj.done:continue
   var half: float=obj.rect.size.x*.5+55
   var p: Vector2=obj.rect.get_center()
   if obj.stubborn:
    var a: Vector2=p-Vector2(half,0);var b: Vector2=p+Vector2(half,0)
    await brush(b if cycle%2 else a,a if cycle%2 else b)
   else:
    for y in range(int(obj.rect.position.y)-8,int(obj.rect.end.y)+25,25):
     var a:=Vector2(obj.rect.position.x-55,y);var b:=Vector2(obj.rect.end.x+55,y)
     await brush(a,b);await brush(b,a)
  if game.model.settled:break
func alpha_check() -> void:
 game.view.tool.hide();game.view.foreground.hide();game.view.dirt.hide();await frames()
 var clean: Image=vp.get_texture().get_image()
 var obj: Dictionary=game.model.objects.filter(func(o):return not o.stubborn)[0]
 game.view.dirt.show()
 for item in game.model.objects:game.view.object_sprites[item.id].sprite.visible=item.id==obj.id
 await frames();var dirty: Image=vp.get_texture().get_image()
 var raw: Image=game.model.assets.image(obj.type);var total: float=0;var squared: float=0;var count: int=0
 for y in range(3,29,2):
  for x in range(3,29,2):
   var uv:=Vector2((x+.5)/32,(y+.5)/32)
   var ink: Color=raw.get_pixel(int(uv.x*raw.get_width()),int(uv.y*raw.get_height()))
   if ink.a<.25 or ink.a>.90:continue
   var point: Vector2=obj.rect.position+obj.rect.size*uv
   var at:=Vector2i(point*Vector2(vp.size)/Vector2(1920,1080))
   var under: Color=clean.get_pixelv(at);var actual: Color=dirty.get_pixelv(at)
   var alpha: float=ink.a*obj.opacity
   var expected: Color=ink*alpha+under*(1-alpha)
   var wrong_alpha: float=ink.a*ink.a*obj.opacity*obj.opacity
   var wrong: Color=ink*wrong_alpha+under*(1-wrong_alpha)
   total+=(absf(actual.r-expected.r)+absf(actual.g-expected.g)+absf(actual.b-expected.b))/3
   squared+=(absf(actual.r-wrong.r)+absf(actual.g-wrong.g)+absf(actual.b-wrong.b))/3;count+=1
 alpha_result={"samples":count,"single_alpha_error":total/maxi(1,count),"double_alpha_error":squared/maxi(1,count)}
 check(count>20 and total/count<.06 and total<squared,"GPU source/opacity applied once; double-alpha image would be measurably wrong")
 game.view.foreground.show();game.view.sync()
func _initialize() -> void:call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 vp=SubViewport.new();vp.size=Vector2i(1920,1080);vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(vp)
 game=load("res://scenes/prototype_grooming/robot_random_demo.tscn").instantiate();vp.add_child(game)
 await process_frame;await process_frame;game.set_process(false);advance(.5)
 check(game.model.kind=="robot" and game.model.objects.size()>=10,"Independent scene starts real random robot model")
 check(game.view.object_sprites.size()==game.model.objects.size(),"Every valid random object has its own visible state")
 await capture("01_initial_1920_seed6101604")
 await alpha_check()
 var layout: String=fingerprint();var seed_value: int=game.model.order_seed
 await button("HUD/Top/New");advance(.5)
 check(game.model.order_seed!=seed_value and fingerprint()!=layout,"Real new-order button changes both seed and visible layout")
 var changed_layout: String=fingerprint();seed_value=game.model.order_seed
 await button("HUD/Top/Retry");advance(.5)
 check(game.model.order_seed==seed_value and fingerprint()==changed_layout,"Real retry reproduces order without added payment")
 # Type a seed through the actual LineEdit keyboard route.
 await button("HUD/Top/Seed")
 var select:=InputEventKey.new();select.keycode=KEY_A;select.ctrl_pressed=true;select.pressed=true;vp.push_input(select,true)
 for character in "6101604":
  var e:=InputEventKey.new();e.pressed=true;e.unicode=character.unicode_at(0);vp.push_input(e,true)
 await button("HUD/Top/Reproduce");advance(.5)
 check(game.model.order_seed==6101604 and fingerprint()==layout,"Seed typed into debug field reproduces original objects")
 var obj: Dictionary=game.model.objects.filter(func(o):return not o.stubborn)[0]
 var p: Vector2=obj.rect.get_center();var before: float=obj.sum
 event_at(p,0,false);event_at(p+Vector2(60,0),0,false);game.flush_paths()
 check(obj.sum==before and not game.dragging,"Mouse movement without holding cannot clean")
 event_at(p,1);advance(.2);event_at(p,2)
 check(obj.sum==before,"Stationary hold and click cannot clean")
 await brush(Vector2(100,p.y),p+Vector2(90,0))
 check(obj.sum<before,"Hold in background then move into body activates wiping")
 await capture("02_partial_1920")
 var partial: float=obj.sum;game.model.tick(.2)
 check(obj.sum==partial and fingerprint()==layout,"Release preserves partial removal and generated order")
 event_at(p,1);game.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(not game.dragging and obj.sum==partial,"Focus-loss notification releases tool but preserves progress")
 await button("HUD/Top/Pause");var now: float=game.model.now;advance(2)
 await brush(p-Vector2(80,0),p+Vector2(80,0))
 check(game.model.now==now and obj.sum==partial and not game.dragging,"Real pause blocks both timer and brush input")
 await button("HUD/PausePanel/VBox/Continue")
 check(not game.paused,"Resume button restores same order")
 await finish_mouse()
 check(game.model.settled and game.model.wallet==120 and game.model.served==1,"1920 mouse gestures clean entire random order and pay once")
 await capture("03_completed_1920")
 var wallet: int=game.model.wallet
 await brush(Vector2(700,600),Vector2(1300,600))
 check(game.model.wallet==wallet,"Input after reward cannot double-pay")
 advance(2)
 check(game.model.serial>1 and game.model.kind=="robot" and game.model.wallet==wallet,"Automatic next customer is another random robot")
 vp.size=Vector2i(1440,810);await process_frame;await process_frame
 await button("HUD/Top/Retry");advance(.5)
 await capture("04_initial_1440")
 var stubborn: Dictionary=game.model.objects.filter(func(o):return o.stubborn)[0]
 p=stubborn.rect.get_center();before=stubborn.sum
 await brush(p-Vector2(110,0),p+Vector2(110,0))
 check(stubborn.sum<before and not stubborn.done,"1440 mouse mapping gives progressive stubborn removal")
 await capture("05_partial_1440")
 await finish_mouse()
 check(game.model.settled and game.model.wallet==240 and game.model.served==2,"Second screen size completes and pays the second order")
 await capture("06_completed_1440")
 await button("HUD/Top/New");advance(.5)
 await capture("07_new_random_1440")
 event_at(Vector2(200,65),1)
 check(not game.dragging,"Top panel consumes background button press without activating tool")
 event_at(Vector2(200,65),2)
 FileAccess.open(OUT+"ui.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"sizes":[[1920,1080],[1440,810]],"alpha_check":alpha_result,"screenshots":screenshots,"input":"SubViewport real mouse/keyboard events, controlled simulation time, not a human playtest"},"  "))
 print("ROBOT RANDOM UI: %d checks; %d failures"%[checks,failures.size()])
 game.queue_free();vp.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
