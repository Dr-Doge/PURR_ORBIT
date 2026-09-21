extends SceneTree
const Main=preload("res://scenes/main.tscn")
var failures: int=0
func check(ok: bool,message: String) -> void:
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func capture(name: String) -> void:
 for i in range(4):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join(name+".png"))
func run() -> void:
 root.size=Vector2i(1440,900)
 var game=Main.instantiate();game.testing=true;root.add_child(game);game.set_process(false);game.start_game()
 var c: Dictionary=game.model.cats[0];c.layers=3
 game.model.harvest(c.id)
 var token_events: int=0
 for event in game.model.events:
  if event.kind=="token":token_events+=1;game.room.consume_event(event)
 check(token_events==1 and game.model.tokens==1,"First token emits one effect without changing reward")
 game.room.step(0)
 var initial: Dictionary=game.room.token_effect.pose(game.room.effects[0])
 game.room.step(0.35)
 var expanded: Dictionary=game.room.token_effect.pose(game.room.effects[0])
 check(expanded.diameter>initial.diameter*4,"Token grows on appearance")
 game.refresh();await capture("purr-token-appear")
 game.show_contact();await capture("purr-token-over-guide")
 game.close_modal();game.room.step(0.95)
 var flying: Dictionary=game.room.token_effect.pose(game.room.effects[0])
 check(flying.diameter<expanded.diameter and flying.travel>0,"Token shrinks while flying")
 await capture("purr-token-flight")
 game.room.step(0.55)
 var arrived: Dictionary=game.room.token_effect.pose(game.room.effects[0])
 var target: Vector2=game.room.stage_origin()+Vector2(1250,137)*game.room.stage_scale()
 check(arrived.position.distance_to(target)<0.01,"Token reaches UI")
 game.room.step(0.3);check(game.room.effects.is_empty(),"Effect cleans up")
 game.model.events.clear();game.model.token_progress=13;c.layers=1
 game.model.harvest(c.id)
 token_events=0
 for event in game.model.events:
  if event.kind=="token":token_events+=1
 check(token_events==1 and game.model.tokens==2,"Later tokens retain reward and effect")
 game.queue_free();await process_frame
 print("TOKEN EFFECT CHECKS: ",failures," failures")
 quit(0 if failures==0 else 1)
