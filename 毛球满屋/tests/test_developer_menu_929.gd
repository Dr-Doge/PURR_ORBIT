extends SceneTree
const M=preload("res://scripts/model.gd")
var game
var checks=0
var failures=0
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:root.size=Vector2i(1440,810);call_deferred("run")
func frames() -> void:
 for i in range(4):await process_frame
func key(code: int) -> void:
 var e=InputEventKey.new();e.keycode=code;e.pressed=true;root.push_input(e,true)
 e=InputEventKey.new();e.keycode=code;e.pressed=false;root.push_input(e,true)
func click(at: Vector2) -> void:
 var motion=InputEventMouseMotion.new();motion.position=at;root.push_input(motion,true)
 for down in [true,false]:
  var e=InputEventMouseButton.new();e.position=at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e,true)
func press(node: Control) -> void:
 var parent=node.get_parent()
 while parent!=null:
  if parent is ScrollContainer:parent.ensure_control_visible(node)
  parent=parent.get_parent()
 await frames();click(node.get_global_rect().get_center());await frames()
func command(id: String) -> void:await press(game.developer_drawer.content.get_node("Command_"+id))
func capture(name: String) -> void:
 await frames();await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png("res://reports/developer_menu_929/"+name+".png")==OK,"Capture "+name)
func run() -> void:
 for scene in ["3D scene","测试场景","main"]:
  game=load("res://scenes/archive/测试场景_004.tscn" if scene=="测试场景" else "res://scenes/"+scene+".tscn").instantiate();game.testing=true;root.add_child(game);game.set_process(false);await frames()
  var lab=scene=="测试场景"
  var drawer=game.developer_drawer
  if not lab:
   check(not drawer.visible,"No developer tab on start screen")
   game.start_game();await frames()
  check(drawer.visible and not drawer.panel.visible and drawer.tab.get_global_rect().position.x==0,"Collapsed tab on physical left edge")
  check(drawer.tab.tooltip_text.contains("点击展开"),"Hover explains click-to-expand")
  var before=game.model.snapshot()
  for n in range(10):key(KEY_0+n);key(KEY_KP_0+n)
  check(game.model.snapshot()==before and game.modal=="","All number and keypad developer shortcuts removed")
  await press(drawer.tab)
  check(drawer.panel.visible and game.modal=="developer" and game.paused and not game.room.interactive,"Real tab click opens paused drawer without room input")
  var elapsed=game.model.elapsed;game._process(0.2)
  check(game.model.elapsed==elapsed,"Open drawer pauses simulation")
  game.model.move_cat(game.model.cats[0].id,Vector2(900,500));game.room.step(0)
  var frozen=game.model.snapshot();click(game.room.screen_position(game.model.cats[0].pos))
  check(game.model.snapshot()==frozen and game.room.dragging<0,"Clicks outside drawer cannot drag or harvest background cats")
  var wallet=game.model.wallet;await command("money");await command("food")
  check(game.model.wallet==wallet+10000 and game.model.food[0]==before.food[0]+100,"Money and food menu grants")
  for kind in game.Dev.CAT_KINDS:
   var count=game.model.cats.size();wallet=game.model.wallet
   await command(kind)
   var c=game.model.cats.back()
   check(game.model.cats.size()==count+1 and c.kind==kind and c.reaction_kind==kind and game.model.wallet==wallet,"Menu spawns "+kind+" without spending or substituting type")
   if lab:check(c.has("identity") and c.identity.id==c.id,"Generated special cat has stable lab identity")
  for kind in ["feeder","sun","arcade","altar","worker"]:
   var count=game.model.count(kind);wallet=game.model.wallet;await command(kind)
   check(game.model.count(kind)==count+1 and game.model.wallet==wallet,"Retained free facility/worker "+kind)
  await command("bugs");await command("interference")
  check(game.model.facilities.any(func(f):return f.bugs>0) and game.model.facilities.any(func(f):return f.broken),"Anomaly test functions accessible from drawer")
  await command("stage2")
  check(game.model.round_no==2 and game.model.owned.size()==12 and game.model.pool().size()==24,"Menu stage command preserves 12+24 behavior")
  before=game.model.snapshot();await command("stage2")
  check(game.model.snapshot()==before,"Stage command is idempotent")
  check(game.model.get_script().new().restore(game.model.snapshot()),"All five spawned kinds and grants roundtrip save schema")
  check(drawer.feedback.text!="","Command result visible")
  for size in [Vector2i(1440,810),Vector2i(960,540)]:
   root.size=size;await frames()
   check(drawer.panel.get_global_rect().end.x<=game.size.x and drawer.panel.get_global_rect().end.y<=game.size.y,"Drawer fits "+str(size))
   await command("alien")
   check(game.model.cats.back().kind=="alien","Lower scrolled command remains clickable")
   if scene!="main":await capture(("lab" if lab else "formal")+"_"+str(size.x))
  drawer.content.get_parent().scroll_vertical=0
  if scene!="main":await capture(("lab" if lab else "formal")+"_top")
  key(KEY_ESCAPE);await frames()
  check(not drawer.panel.visible and game.modal=="" and not game.paused and game.room.interactive,"Esc restores room control")
  await press(drawer.tab);await press(drawer.tab)
  check(not drawer.panel.visible and game.modal=="","Tab toggles closed")
  game.show_pause();game.show_developer();await frames()
  check(drawer.panel.visible and not game.overlay.visible,"Pause entry uses same side drawer")
  if lab:
   var reset: Button
   for b in drawer.content.get_children():
    if b is Button and b.text=="重置测试预置":reset=b
   check(reset!=null,"Original lab reset is available in drawer")
   await press(reset)
   check(game.model.cats.size()==12 and game.model.wallet==121 and not drawer.panel.visible,"Lab reset is exact and closes drawer")
  else:
   game.show_settings();await frames()
   check(not drawer.panel.visible and game.modal=="settings","Opening another screen hides drawer")
  game.queue_free();await frames();root.size=Vector2i(1440,810)
 print("DEVELOPER MENU: ",checks," checks, ",failures," failures")
 var out=FileAccess.open("res://reports/developer_menu_929/result.json",FileAccess.WRITE);out.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "));out.close()
 quit(0 if failures==0 else 1)
