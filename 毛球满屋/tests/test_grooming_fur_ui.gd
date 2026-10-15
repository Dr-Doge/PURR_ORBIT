extends SceneTree
const OUT="res://reports/grooming_fur_sizes_20261015/"
var vp: SubViewport
var game: Control
var checks: int=0
var failures: Array=[]
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func input_at(p: Vector2,press: int=0,held: bool=true) -> void:
 var actual: Vector2=p*Vector2(vp.size)/Vector2(1920,1080)
 if press!=0:
  var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=press==1;e.position=actual;e.global_position=actual;vp.push_input(e,true)
 else:
  var e:=InputEventMouseMotion.new();e.position=actual;e.global_position=actual;e.button_mask=MOUSE_BUTTON_MASK_LEFT if held else 0;vp.push_input(e,true)
func snapshot(name: String) -> void:
 await process_frame;await RenderingServer.frame_post_draw
 vp.get_texture().get_image().save_png(OUT+name+".png")
func swipe(a: Vector2,b: Vector2,speed: float) -> void:
 input_at(a,0,false);input_at(a,1);await process_frame
 # Keep each event within the live input gap; timing is explicitly controlled.
 var steps: int=maxi(2,int(a.distance_to(b)/35))
 var previous: Vector2=a
 for i in range(1,steps+1):
  var p: Vector2=a.lerp(b,float(i)/steps)
  var interval: float=previous.distance_to(p)/game.model.body_rect.size.x/speed
  game.previous_tick=Time.get_ticks_usec()-int(interval*1000000)
  input_at(p)
  if game.model.kind=="calico":game.flush_grooming(interval)
  previous=p
 input_at(b,2);await process_frame
func obj(rule: String) -> Dictionary:
 for o in game.model.objects:
  if o.rule==rule and not o.done:return o
 return {}
func _initialize() -> void:call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 vp=SubViewport.new();vp.size=Vector2i(1920,1080);vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(vp)
 game=load("res://scenes/prototype_grooming/fur_demo.tscn").instantiate();vp.add_child(game);await create_timer(.6).timeout
 check(game.model.kind=="calico" and game.model.objects.size()>=35,"new scene starts grey cat service")
 check(game.model.body_rect.size.x/1920.0>.75,"cat occupies roughly 80 percent of screen width")
 await snapshot("01_messy")
 var o: Dictionary=obj("patch");var p: Vector2=o.rect.get_center()
 await swipe(p-Vector2(65,0),p+Vector2(65,0),.18)
 check(o.done and not game.view.object_sprites[o.id].sprite.visible,"GUI valid stroke removes entire fur sprite")
 var particle: bool=false
 for e in game.view.particles:
  if e.left>0:particle=true
 check(particle,"detached fur animates as a flying sprite")
 await snapshot("02_patch_removed")
 o=obj("flea")
 for i in range(3):
  p=o.rect.get_center();input_at(p,0,false);input_at(p,1);input_at(p,2);await process_frame
 check(o.done,"three actual GUI clicks clear moving flea")
 var m: RefCounted=game.model
 # Finish through actual mouse gestures, not by setting objects done.
 for o2 in m.objects:
  if o2.rule=="dust":
   p=o2.rect.get_center();await swipe(p-Vector2(0,80),p+Vector2(0,80),.18);await swipe(p+Vector2(0,80),p-Vector2(0,80),.18)
 for round_index in range(3):
  for y in range(125,975,26):
   if m.stage!="cleaning" or m.served>0:break
   await swipe(Vector2(165,y),Vector2(1755,y),.18)
  if m.stage!="cleaning" or m.served>0:break
 var remaining: Array=[]
 for item in m.objects:
  if not item.done:remaining.append([item.id,item.rule,item.sum,str(item.rect)])
 if m.served!=1 or m.wallet!=100:print("GUI ORDER DIAGNOSTIC: ",m.stage," score=",m.score," wallet=",m.wallet," remaining=",remaining)
 check(m.served==1 and m.wallet==100,"full grey cat order completed by GUI and paid once")
 await create_timer(.48).timeout
 await snapshot("03_clean_reward")
 game.jump_order(1);await create_timer(.55).timeout
 o=game.model.objects[1];p=o.rect.get_center();var before: float=o.sum
 await swipe(p-Vector2(70,0),p+Vector2(70,0),3.0)
 check(o.sum<before and o.sum>0 and game.model.score==100,"new room preserves robot quick repeated wiping")
 await snapshot("04_robot")
 game.jump_order(0,true);await process_frame
 check(game.view.claw_root.get_index()<game.view.base.get_index(),"claws remain below new grey paw")
 await snapshot("05_grey_nails")
 for n in game.model.nails:
  var at: Vector2=n.root-Vector2(0,game.model.quick_height-12);var img: Image=vp.get_texture().get_image();var pink: int=0
  for y in range(int(at.y)-18,int(at.y)+19):
   for x in range(int(at.x)-38,int(at.x)+39):
    var c: Color=img.get_pixel(x,y)
    if c.r>.85 and c.g>.30 and c.g<.78 and c.b>.35 and c.r>c.g+.14:pink+=1
  check(pink>12,"visible pink nail quick on grey paw "+str(n.id))
 var nail: Dictionary=game.model.nails[0];var edges: Vector2=game.model.nail_edges(nail,game.model.perfect_height());var y: float=nail.root.y-game.model.perfect_height()
 await swipe(Vector2(edges.x-15,y),Vector2(edges.y+15,y),1.0)
 check(nail.done and nail.result=="perfect","grey paw aligned nail can be trimmed with mouse")
 await snapshot("06_trimmed_nail")
 game.jump_order(0);await create_timer(.55).timeout
 vp.size=Vector2i(1440,810);await process_frame
 o=obj("patch");p=o.rect.get_center();await swipe(p-Vector2(60,0),p+Vector2(60,0),.18)
 check(o.done,"scaled 1440x810 mouse hits same patch")
 await snapshot("07_1440x810")
 game.toggle_pause();var t: float=game.model.now;await create_timer(.15).timeout
 check(game.model.now==t and not game.dragging,"pause cancels input and freezes model")
 FileAccess.open(OUT+"ui.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"sizes":[[1920,1080],[1440,810]],"input":"real SubViewport mouse events, controlled timestamps for batch sweeps"}," "))
 print("FUR DEMO UI: ",checks," checks; ",failures.size()," failures")
 game.queue_free();vp.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
