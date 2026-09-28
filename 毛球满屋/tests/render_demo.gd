extends SceneTree
const Main=preload("res://scenes/main.tscn")
var game
var failures: int=0
func _initialize() -> void:
 root.size=Vector2i(1440,810);call_deferred("run")
func check(ok: bool,msg: String) -> void:
 if not ok:failures+=1;push_error(msg)
func frames(count: int=4) -> void:
 for i in range(count):await process_frame
func capture(name: String) -> void:
 await frames(5);await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://reports/editor_928/"+name+".png"))==OK,"Capture "+name)
 check(game.room.stage_origin().is_equal_approx(Vector2.ZERO),"No stage letterboxing: "+name)
 check(game.room.backdrop.size.is_equal_approx(game.room.size),"Backdrop fills viewport: "+name)
 check(game.card.get_global_rect().end.x<=game.size.x+1 and game.card.get_global_rect().end.y<=game.size.y+1,"Panel within viewport: "+name)
func move(at: Vector2) -> void:
 var e:=InputEventMouseMotion.new();e.position=at;root.push_input(e,true)
func click(at: Vector2,down: bool) -> void:
 var e:=InputEventMouseButton.new();e.position=at;e.pressed=down;e.button_index=MOUSE_BUTTON_LEFT;root.push_input(e,true)
func find_button(node: Node,text: String) -> Button:
 if node is Button and node.text==text:return node
 for child in node.get_children():
  var b: Button=find_button(child,text)
  if b!=null:return b
 return null
func press(text: String) -> void:
 var b: Button=find_button(game,text);check(b!=null,"Button exists "+text)
 if b==null:return
 click(b.global_position+b.size/2,true);click(b.global_position+b.size/2,false);await frames()
func rub_cat(c: Dictionary) -> void:
 var revision: int=game.model.c_revision(c)
 for i in range(160):
  move(game.room.screen_position(c.pos+Vector2(-18 if i%2 else 18,0)))
  game._process(0.05);await process_frame
  if game.model.c_revision(c)!=revision:return
func run() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/editor_928"))
 game=Main.instantiate();game.testing=true;root.add_child(game);game.set_process(false)
 await capture("01_start");await press("开始游戏")
 if not game.active:game.start_game()
 await frames()
 var c: Dictionary=game.model.cats[0];var at: Vector2=c.pos
 await rub_cat(c)
 check(game.model.wallet>=3,"Real mouse hover harvest")
 await capture("02_room")
 game.model.wallet=50000
 for key in ["worker","feeder","sun"]:game.model.research(key)
 game.model.buy("feeder",Vector2(330,470));game.model.buy("sun",Vector2(850,465))
 var sun: Dictionary=game.model.facilities[1]
 game.model.move_cat(c.id,Vector2(550,470));move(game.room.screen_position(c.pos));click(game.room.screen_position(c.pos),true);await process_frame
 move(game.room.screen_position(sun.pos));click(game.room.screen_position(sun.pos),false);await process_frame
 check(c.station==sun.id,"Real mouse drag assigns sun")
 game.show_tree("sun");await capture("03_tree")
 game.model.move_cat(c.id,Vector2(550,470));c.layers=3;var before: float=game.model.wallet
 for i in range(8):move(game.room.screen_position(c.pos+Vector2(-18 if i%2 else 18,0)));await process_frame
 check(game.model.wallet==before,"Modal blocks scene input")
 game.show_shop();await capture("04_shop");await press("购买 · 12 毛球")
 check(game.model.workers.size()==1,"Real shop button buys worker")
 game.close_modal();await rub_cat(c);await frames();check(game.modal=="contact","First contact")
 await capture("05_contact");game.model.accept_contact();game.show_gacha();game.pull_capsule();await capture("06_capsule")
 game.model.tokens=35;game.model.minted=36
 for i in range(11):game.model.draw_capsule()
 check(game.model.round_no==2,"UI fixture reaches restock")
 for key in ["hats","arcade"]:game.model.research(key)
 game.model.buy("arcade",Vector2(580,650));game.model.refill(game.model.facilities[0].id)
 for i in range(7):
  var cat: Dictionary=game.model.add_cat(Vector2(460+(i%4)*175,520+(i/4)*125));cat.kind=["short","giant","static","lucky"][i%4];cat.layers=3+i%5
 game.close_modal();await capture("07_populated_room")
 game.show_gacha();await capture("08_collections")
 game.model.facilities[0].bugs=3;game.show_facility(game.model.facilities[0].id);await capture("09_feeder")
 game.show_workers();await capture("10_workers")
 for i in range(300):game.model.prize(game.model.cats[0],90)
 game.show_inventory();await capture("11_inventory")
 check(game.body.get_child_count()<10,"Inventory has grouped layout")
 root.size=Vector2i(1280,720);await frames();game.show_shop();await capture("12_shop_1280")
 game.show_tree("worker");await capture("13_tree_1280")
 game.show_pause();var stopped: float=game.model.elapsed;game._process(0.1);await frames(12)
 check(game.model.elapsed==stopped,"Pause stops simulation")
 var esc:=InputEventKey.new();esc.keycode=KEY_ESCAPE;esc.pressed=true;root.push_input(esc,true);await frames()
 check(game.modal=="" and not game.paused,"Escape returns to room")
 game.model.wallet=0;game.show_shop();await frames();var cat_button: Button=find_button(game,"购买 · %d 毛球" % game.model.price("short"))
 check(cat_button!=null and cat_button.disabled,"Unavailable purchase disabled")
 game.model.wallet=100000;game.refresh();check(not cat_button.disabled,"Affordability updates while panel stays open")
 game.model.workers[0].cooldown=2.5;game.show_workers();await frames()
 check(game.model.workers[0].cooldown==2.5,"Opening worker panel preserves cooldown")
 game.show_tree("U12-L1");await frames();await press("购买 · 30 毛球")
 check(game.model.worker_target()==2,"Real upgrade button buys exactly one target layer")
 game.show_tree("U13-L1");await frames();await press("购买 · 45 毛球")
 check(game.model.worker_cooldown()<3.0 and game.model.workers[0].cooldown==2.5,"Real CD upgrade changes future CD without resetting current one")
 await capture("14_worker_upgrades");game.show_workers();await capture("15_worker_cd")
 print("UI CHECKS: ",failures," failures");quit(0 if failures==0 else 1)
