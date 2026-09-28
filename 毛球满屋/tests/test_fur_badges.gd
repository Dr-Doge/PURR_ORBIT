extends SceneTree
const H=preload("res://tests/harvest_fixture.gd")
const Model=preload("res://scripts/model.gd")
const Room=preload("res://scripts/room.gd")
var failures: int=0
func check(ok: bool,message: String) -> void:
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func visible_count(items: Array) -> int:
 var count: int=0
 for item in items:
  if item.visible:count+=1
 return count
func capture(name: String) -> void:
 for i in range(4):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join(name+".png"))
func run() -> void:
 root.size=Vector2i(1440,900)
 var model=Model.new();model.cats.resize(1)
 var room=Room.new();room.model=model;room.size=Vector2(1440,900);root.add_child(room)
 var c: Dictionary=model.cats[0]
 model.wallet=20000;model.research("worker");model.research("feeder")
 check(model.buy("feeder",Vector2(1000,500)),"Feeder present for visual verification")
 model.research("sun")
 check(model.buy("sun",Vector2(760,600)),"Sun lamp present for visual verification")
 model.events.clear()
 for count in [1,3,8]:
  H.wait_ready(model,c)
  room.effects.clear();c.layers=count;room.step(0)
  check(visible_count(room.harvest_art.badges)==count,"One badge per fur layer: "+str(count))
  var starts: Array[Vector2]=[]
  for badge in room.harvest_art.badges:
   if badge.visible:starts.append(badge.position)
  if count==8:await capture("purr-feed-fur-before")
  var before: float=model.wallet
  var expected: float=model.harvest_value(c)
  H.settle(model,c.id)
  for event in model.events:
   if event.kind=="money":room.consume_event(event)
  model.events.clear();room.step(0)
  check(is_equal_approx(model.wallet-before,expected),"Harvest payout unchanged")
  check(visible_count(room.harvest_art.badges)==1,"Harvest leaves permanent first-layer badge")
  check(visible_count(room.harvest_art.particles)==count,"Flight count matches badges: "+str(count))
  for i in range(count):check(room.harvest_art.particles[i].position.is_equal_approx(starts[i]),"Flight begins at badge position")
  if count==8:
   room.step(0.45);await capture("purr-feed-fur-flying")
  room.step(1.7)
  check(visible_count(room.harvest_art.particles)==0,"Flight particles clean up")
 room.queue_free();await process_frame
 print("FUR BADGE CHECKS: ",failures," failures")
 quit(0 if failures==0 else 1)
