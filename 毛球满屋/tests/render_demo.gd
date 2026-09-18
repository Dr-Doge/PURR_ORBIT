extends SceneTree
const Main = preload("res://scenes/main.tscn")
const D = preload("res://scripts/data.gd")
var game
var failures: int = 0
func _initialize() -> void:
 root.size = Vector2i(1440,900)
 call_deferred("run")
func check(value: bool,message: String) -> void:
 if not value: failures += 1; push_error(message)
func capture(name: String) -> void:
 for i in range(5): await process_frame
 await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://reports/v026/"+name+".png")) == OK,"Screenshot "+name)
func motion(pos: Vector2) -> void:
 var event := InputEventMouseMotion.new(); event.position = pos; root.push_input(event)
func click_at(pos: Vector2,down: bool) -> void:
 var event := InputEventMouseButton.new(); event.position = pos; event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;root.push_input(event)
func frame_wait(count: int = 2) -> void:
 for i in range(count):await process_frame
func find_button(node: Node,text: String) -> Button:
 if node is Button and node.text==text:return node
 for child in node.get_children():
  var found: Button=find_button(child,text)
  if found!=null:return found
 return null
func click_button(text: String) -> void:
 var b: Button=find_button(game,text)
 check(b!=null,"Button present: "+text)
 if b==null:return
 click_at(b.global_position+b.size/2,true);click_at(b.global_position+b.size/2,false)
 await frame_wait(4)
func run() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/v026"))
 game = Main.instantiate();game.testing=true;root.add_child(game)
 await capture("01_start")
 await click_button("开始第一次停留")
 if not game.active:game.start_game()
 await frame_wait()
 var cat: Dictionary=game.model.cats[0]
 var start: Vector2=cat.pos
 for i in range(8):
  motion(start+Vector2(-18 if i%2 else 18,0));await process_frame
 check(game.model.wallet>=3,"Actual hover input harvests without clicking")
 await capture("02_room")
 game.model.wallet=2000
 for key in ["worker","feeder","sun"]:check(game.model.research(key),"Research "+key)
 check(game.model.buy("feeder",Vector2(330,470)),"Buy feeder")
 check(game.model.buy("sun",Vector2(850,465)),"Buy sun")
 var sun: Dictionary=game.model.facilities[1]
 game.model.move_cat(cat.id,Vector2(550,470))
 motion(cat.pos);click_at(cat.pos,true);await process_frame
 motion(sun.pos);click_at(sun.pos,false);await process_frame
 check(cat.station==sun.id,"Real drag drops cat into sun")
 game.show_tree("worker");await capture("03_tree")
 var prior: float=game.model.wallet
 cat.layers=3;game.model.move_cat(cat.id,Vector2(550,470))
 for i in range(8):motion(cat.pos+Vector2(-18 if i%2 else 18,0));await process_frame
 check(game.model.wallet==prior,"Modal blocks pet input")
 game.show_shop();await frame_wait(5)
 await click_button("购买 · 20 毛球")
 check(game.model.workers.size()==1,"Shop mouse click buys worker")
 await capture("04_shop")
 game.close_modal();game.model.harvest(cat.id);await frame_wait()
 check(game.modal=="contact","First token opens contact")
 await capture("05_contact")
 game.model.accept_contact();game.show_gacha();game.pull_capsule();await capture("06_capsule")
 game.model.round_no=3;game.model.wallet=10000
 for key in ["hats","arcade","altar","maint"]:check(game.model.research(key),"Research "+key)
 game.model.buy("arcade",Vector2(610,440));game.model.buy("altar",Vector2(1085,620))
 var kinds: Array=["short","giant","static","lucky","alien"]
 game.model.cats.clear()
 for i in range(10):
  var c: Dictionary=game.model.add_cat(Vector2(360+(i%5)*170,570+(i/5)*92));c.kind=kinds[i%5];c.layers=3+i%5
 for i in range(3):game.model.buy("worker",Vector2(450+i*190,370))
 game.model.set_role(game.model.workers[0].id,"harvest");game.model.set_role(game.model.workers[1].id,"refill");game.model.set_role(game.model.workers[2].id,"repair")
 game.model.facilities[0].bugs=3;game.model.facilities[0].grain=14
 game.model.facilities[2].broken=true
 game.close_modal();game.paused=true;game.refresh();await capture("07_round3_room")
 game.show_facility(game.model.facilities[0].id);await capture("08_bugs")
 game.show_workers();await capture("09_workers")
 game.show_facility(game.model.facilities[2].id);await capture("10_repair")
 game.show_tree("altar");await frame_wait(6)
 check(game.graph.get_child_count()>=20,"Upgrade tree includes visual branch nodes")
 await capture("11_late_tree")
 game.show_gacha();await capture("12_collection")
 game.show_pause();var elapsed: float=game.model.elapsed;await capture("13_pause")
 check(game.model.elapsed==elapsed,"Pause actually freezes model")
 var esc:=InputEventKey.new();esc.keycode=KEY_ESCAPE;esc.pressed=true;root.push_input(esc);await frame_wait()
 check(game.modal=="" and not game.paused,"Escape resumes room")
 root.size=Vector2i(1280,720);await frame_wait(6);game.show_shop();await capture("14_1280_shop")
 game.show_contact();await capture("15_1280_contact")
 game.queue_free();await process_frame
 print("UI CHECKS: ",failures," failures")
 quit(0 if failures==0 else 1)
