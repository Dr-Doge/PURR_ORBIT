extends SceneTree
var Main = load("res://scenes/3D scene.tscn" if "--3d" in OS.get_cmdline_user_args() else "res://scenes/main.tscn")
const M=preload("res://scripts/model.gd")
var game
var checks: int=0
var failures: int=0
func _initialize() -> void:
 root.size=Vector2i(1440,810);call_deferred("run")
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func frames() -> void:
 for i in range(5):await process_frame
func key(code: int,ctrl: bool=false,echo_key: bool=false) -> void:
 var e:=InputEventKey.new();e.keycode=code;e.unicode=code if code>=KEY_0 and code<=KEY_9 else 0;e.pressed=true;e.ctrl_pressed=ctrl;e.echo=echo_key;root.push_input(e,true)
 e=InputEventKey.new();e.keycode=code;e.pressed=false;e.ctrl_pressed=ctrl;root.push_input(e,true)
func capture(name: String) -> void:
 await frames();await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png("res://reports/merge_cat1new_928/developer/"+name+".png")==OK,"Screenshot "+name)
 check(game.card.get_global_rect().end.x<=game.size.x+1 and game.card.get_global_rect().end.y<=game.size.y+1,"Panel inside viewport")
func run() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/merge_cat1new_928/developer"))
 game=Main.instantiate();game.testing=true;root.add_child(game);game.set_process(false);await frames()
 key(KEY_1);key(KEY_3);key(KEY_9)
 check(game.model.wallet==0 and game.model.facilities.is_empty() and game.modal=="start","Start screen ignores developer commands")
 game.start_game()
 var unchanged: Dictionary=game.model.snapshot()
 for old in [KEY_F7,KEY_F8,KEY_F9,KEY_F10]:key(old)
 for old in [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6]:key(old,true)
 check(game.model.snapshot()==unchanged and game.modal=="","Old function keys and Ctrl shortcuts have no effect")
 key(KEY_1);key(KEY_1,false,true)
 check(game.model.wallet==10000,"1 works immediately without switch; held-key echo ignored")
 key(KEY_KP_2);check(game.model.food[0]==120,"Keypad 2 grants standard food")
 key(KEY_9);await frames()
 check(game.modal=="developer" and game.paused,"9 opens visible paused tools")
 key(KEY_3)
 check(game.model.facilities.size()==1 and game.model.facilities[0].kind=="feeder" and game.model.has("feeder"),"3 grants working feeder and prerequisites")
 check(game.model.wallet==10000,"Free research and facility do not spend wallet")
 check(game.model.refill(game.model.facilities[0].id),"Granted feeder accepts food")
 key(KEY_4);key(KEY_6);key(KEY_7)
 check(game.model.count("sun")==1 and game.model.workers.size()==1 and game.model.cats.size()==3,"Other entity shortcuts grant correct objects")
 var before: Dictionary=game.model.snapshot();key(KEY_5)
 check(game.model.count("arcade")==1 and game.model.round_no==1,"Entertainment is available without collection gate")
 check(game.developer_feedback.text.contains("免费获得"),"Grant result visible in tool panel")
 key(KEY_8)
 check(game.model.round_no==2 and game.model.owned.size()==12 and game.model.pool().size()==24,"Stage shortcut follows 12+24 collection restock")
 check(game.model.tokens==0 and game.model.minted==12 and game.model.gacha_ready,"Stage shortcut preserves token accounting and enables instrument")
 before=game.model.snapshot();key(KEY_8)
 check(game.model.snapshot()==before,"Repeated stage shortcut cannot duplicate rewards")
 key(KEY_5)
 check(game.model.count("arcade")==2 and game.model.has("arcade") and game.model.wallet==10000,"Stage-two entertainment is free and researched")
 var ids: Dictionary={};var valid: bool=true
 for list in [game.model.cats,game.model.facilities,game.model.workers]:
  for entity in list:
   valid=valid and not ids.has(entity.id) and game.model.clamp_position(entity.pos).is_equal_approx(entity.pos);ids[entity.id]=true
 check(valid,"Created entities have unique IDs and valid positions")
 var restored=M.new();check(restored.restore(game.model.snapshot()),"Developer state passes normal save validation")
 var path: String="res://reports/merge_cat1new_928/developer/test.save"
 check(game.model.save_to(path)==OK and restored.load_from(path),"Isolated developer save can be written and loaded")
 check(restored.owned.size()==12 and restored.count("arcade")==2 and restored.wallet==10000,"Granted assets persist through load")
 await capture("01_tools_1440")
 root.size=Vector2i(1280,720);await capture("02_tools_1280")
 # Click the first command through the actual viewport.
 var b: Button=game.body.get_child(2).get_child(0).get_child(0)
 var pos: Vector2=b.get_global_rect().get_center()
 var click:=InputEventMouseButton.new();click.position=pos;click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;root.push_input(click,true)
 click=InputEventMouseButton.new();click.position=pos;click.button_index=MOUSE_BUTTON_LEFT;root.push_input(click,true);await frames()
 check(game.model.wallet==20000,"Tool money button responds without mode switch")
 game.close_modal();key(KEY_KP_1)
 check(game.model.wallet==30000,"Keypad shortcut works in room after closing panel")
 var edit:=LineEdit.new();game.add_child(edit);edit.grab_focus();await frames()
 key(KEY_1)
 check(game.model.wallet==30000 and edit.text=="1","Typing into a text field never grants money")
 edit.release_focus();edit.queue_free();await frames()
 key(KEY_KP_9);await frames();check(game.modal=="developer","Keypad 9 opens tools")
 game.start_game();key(KEY_1)
 check(game.model.wallet==10000 and game.model.facilities.is_empty(),"New game has direct shortcuts with no switch")
 print("DEVELOPER CHECKS: ",checks,"; failures: ",failures)
 var file:=FileAccess.open("res://reports/merge_cat1new_928/developer/result.txt",FileAccess.WRITE);file.store_string("DEVELOPER CHECKS: %d; failures: %d\n" % [checks,failures]);file.close()
 quit(0 if failures==0 else 1)
