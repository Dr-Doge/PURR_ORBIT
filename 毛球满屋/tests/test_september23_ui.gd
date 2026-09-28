extends SceneTree
const Main=preload("res://scenes/main.tscn")
var game
var checks: int=0
var failures: int=0
func _initialize() -> void:root.size=Vector2i(1440,810);call_deferred("run")
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func frames() -> void:
 for i in range(5):await process_frame
func advance(seconds: float) -> void:
 for i in range(ceili(seconds/0.1)):game._process(0.1)
func move(at: Vector2) -> void:
 var e:=InputEventMouseMotion.new();e.position=at;root.push_input(e,true)
func find(node: Node,title: String) -> Button:
 if node is Button and node.text==title:return node
 for child in node.get_children():
  var result:=find(child,title)
  if result!=null:return result
 return null
func press(title: String) -> void:
 var b:=find(game,title);check(b!=null,"Button "+title)
 if b==null:return
 for down in [true,false]:
  var e:=InputEventMouseButton.new();e.position=b.get_global_rect().get_center();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e,true)
 await frames()
func screenshot(name: String) -> void:
 await frames();await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png("res://reports/editor_928/"+name+".png")==OK,"Capture "+name)
func run() -> void:
 game=Main.instantiate();game.testing=true;root.add_child(game);game.set_process(false);game.start_game();await frames()
 var m=game.model;var c: Dictionary=m.cats[0]
 m.cats[1].pos=Vector2(1100,650);m.move_cat(c.id,Vector2(600,480));m.set_hovered_cat(c.id)
 move(game.room.screen_position(c.pos));await frames()
 move(game.room.screen_position(c.pos+Vector2(-10,0)));advance(0.1)
 move(game.room.screen_position(c.pos+Vector2(10,0)));advance(0.1)
 var partial: float=c.pet;check(partial>0 and partial<m.harvest_distance(1),"Mouse creates partial gesture")
 move(game.room.screen_position(Vector2(200,700)));advance(2.0)
 check(c.pet==partial,"Leaving for two seconds retains exact progress")
 move(game.room.screen_position(c.pos));await frames();move(game.room.screen_position(c.pos+Vector2(-10,0)));advance(0.1)
 check(c.pet>partial,"Real mouse return resumes progress")
 game.show_pause();partial=c.pet;advance(5);check(c.pet==partial,"Pause freezes grace clock")
 game.close_modal();move(game.room.screen_position(Vector2(200,700)));advance(3.1)
 check(c.pet==0,"Live time beyond grace clears gesture")
 move(game.room.screen_position(c.pos));await frames()
 for i in range(2):move(game.room.screen_position(c.pos+Vector2(-12 if i%2 else 12,0)));advance(0.1)
 await screenshot("20_pet_feedback")
 game.room.lose_pointer_focus();partial=c.pet;advance(1)
 check(c.pet==partial,"Brief focus loss retains progress while simulation continues")
 game.room.gain_pointer_focus();m.wallet=1000000
 game.show_tree("A1T");await frames();var wallet: float=m.wallet;await press("购买 · 20 毛球")
 check(m.node_owned("A1T") and m.wallet==wallet-20,"Unified tree actual mouse purchase charges once")
 check(not m.node_owned("A1P") and not m.node_owned("A2T"),"Entry does not grant future fragments")
 game.show_tree("A1M");await frames();await press("购买 · 60 毛球")
 for id in ["N10","N20","N11","S10","N30","N40","N50","N12"]:m.buy_node(id)
 game.show_tree("A2T");await screenshot("21_unified_tree")
 m.buy("altar",Vector2(1150,500));m.buy("arcade",Vector2(300,480));m.buy("worker")
 game.show_workers();await screenshot("22_groups")
 for id in ["C1T","C1M"]:m.buy_node(id)
 m.prize(c,10);m.inventory[0].name="同款测试";m.prize(c,20);m.inventory[1].name="同款测试"
 game.show_inventory();await frames();await press("预留2件同款")
 check(m.orders.size()==1 and m.orders[0].ids.size()==2,"Order UI reserves distinct physical items")
 wallet=m.wallet;await press("提交")
 check(m.inventory.is_empty() and m.orders.is_empty() and m.wallet>wallet,"Order UI consumes inventory exactly once")
 for size in [Vector2i(1440,810),Vector2i(1280,720)]:
  root.size=size;game.show_tree("N50");await frames()
  check(game.card.get_global_rect().end.x<=game.size.x+1 and game.card.get_global_rect().end.y<=game.size.y+1,"Unified tree fits "+str(size))
  await screenshot("23_tree_"+str(size.x))
 game.close_modal()
 for i in range(6):
  var cat: Dictionary=m.add_cat(Vector2(400+i*130,680));cat.kind=["short","giant","static","lucky","alien","short"][i];cat.variant=i%4;cat.pos=m.Space.place(m,cat,cat.pos)
 game.room.step(0);await screenshot("24_variants_altar")
 var file:=FileAccess.open("res://reports/editor_928/ui.txt",FileAccess.WRITE);file.store_string("UI: %d checks, %d failures\n" % [checks,failures]);file.close()
 print("SEPTEMBER23 UI: ",checks," checks, ",failures," failures");quit(0 if failures==0 else 1)
