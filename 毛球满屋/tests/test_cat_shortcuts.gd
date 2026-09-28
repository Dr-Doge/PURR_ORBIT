extends SceneTree
const H=preload("res://tests/harvest_fixture.gd")
const Main = preload("res://scripts/main.gd")
const Visuals = preload("res://scripts/cat_visuals.gd")
var failures: int = 0
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error(message)
func key(app, code: int, echo: bool = false, ctrl: bool = false) -> void:
 var event := InputEventKey.new()
 event.keycode = code
 event.pressed = true
 event.echo = echo
 event.ctrl_pressed = ctrl
 app._unhandled_key_input(event)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var app = Main.new()
 app.testing = true
 root.add_child(app)
 key(app,KEY_1)
 check(app.model.cats.size()==2,"Title ignores spawn keys")
 app.start_game()
 var wallet: float = app.model.wallet
 var owned: Array = app.model.owned.duplicate(true)
 for i in range(5):
  key(app,KEY_1+i)
  check(app.model.cats.size()==3+i,"One cat per press")
  check(app.model.cats.back().kind==["short","giant","static","lucky","alien"][i],"Correct species")
 check(app.model.wallet==wallet and app.model.owned==owned,"Free shortcuts preserve balances")
 key(app,KEY_1,true);key(app,KEY_1,false,true)
 app.show_pause();key(app,KEY_1)
 check(app.model.cats.size()==7,"Repeat, modifier and pause ignored")
 app.close_modal()
 app.testing=false
 key(app,KEY_1)
 check(app.model.cats.size()==7,"Normal gameplay ignores art preview spawn keys")
 app.testing=true
 var lucky: Dictionary=app.model.cats[5]
 var visuals = Visuals.new()
 visuals.step(app.model,0)
 check(visuals.texture(lucky.id)==Visuals.LUCKY_FRAMES.get_frame_texture("idle",0),"Lucky idle bound")
 lucky.pos.x+=1
 visuals.step(app.model,0)
 check(visuals.texture(lucky.id)==Visuals.LUCKY_FRAMES.get_frame_texture("walk",0),"Lucky walk bound")
 lucky.layers=1
 visuals.step(app.model,0)
 H.settle(app.model,lucky.id)
 visuals.step(app.model,0)
 check(visuals.texture(lucky.id)==Visuals.LUCKY_FRAMES.get_frame_texture("produce",0),"Lucky harvest bound")
 app.model.tick(1.05);visuals.step(app.model,1.05)
 check(visuals.texture(lucky.id)==Visuals.LUCKY_FRAMES.get_frame_texture("produce",14),"Last produce frame plays before hold ends")
 app.model.tick(0.06);lucky.pos=visuals.states[lucky.id].pos
 app.model.reset_activity(lucky);lucky.idle_left=10;app.model.tick(0.001)
 visuals.step(app.model,0.06)
 check(visuals.states[lucky.id].animation=="idle","Produce completes")
 app.queue_free()
 await process_frame
 print("CAT SHORTCUT CHECKS: ",failures," failures")
 quit(0 if failures==0 else 1)
