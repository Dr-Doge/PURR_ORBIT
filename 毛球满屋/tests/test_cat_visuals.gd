extends SceneTree
const Model = preload("res://scripts/model.gd")
const Visuals = preload("res://scripts/cat_visuals.gd")
const Room = preload("res://scripts/room.gd")
var failures: int = 0
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var model = Model.new()
 var visuals = Visuals.new()
 var c: Dictionary = model.cats[0]
 visuals.step(model,0.0)
 check(visuals.states[c.id].animation == "idle","Stationary cat uses idle")
 var before: PackedByteArray = var_to_bytes(model.cats)
 visuals.step(model,0.25)
 check(var_to_bytes(model.cats) == before,"Visual update does not mutate cats")
 check(visuals.texture(c.id) == Visuals.FRAMES.get_frame_texture("idle",1),"Idle advances reduced frames")
 c.pos.x += 1.0
 visuals.step(model,0.1)
 check(visuals.states[c.id].animation == "walk" and visuals.flipped(c.id),"Right movement walks and faces right")
 c.pos.x -= 1.0
 visuals.step(model,0.1)
 check(not visuals.flipped(c.id),"Left movement faces left")
 visuals.step(model,0.1)
 check(visuals.states[c.id].animation == "idle","Stopping returns to idle")
 model.layer(c)
 visuals.step(model,0.1)
 check(visuals.states[c.id].animation == "idle","Natural fur growth does not trigger harvest animation")
 model.pet(c.id,45.0)
 visuals.step(model,0.1)
 check(visuals.states[c.id].animation == "idle","Incomplete petting does not produce")
 for i in range(20): model.pet(c.id,45.0)
 visuals.step(model,0.1)
 check(visuals.states[c.id].animation == "produce","Completed pet harvest triggers produce")
 c.pos.x += 1.0
 visuals.step(model,0.4)
 check(visuals.states[c.id].animation == "produce","Produce frames can play while the model keeps walking")
 c.pos.x += 1.0
 visuals.step(model,0.8)
 check(visuals.states[c.id].animation == "walk","Finished produce returns to movement")
 c.layers = 2
 visuals.step(model,0.1)
 model.harvest(c.id)
 visuals.step(model,0.1)
 check(visuals.states[c.id].animation == "produce","Worker harvest also triggers produce")
 var stationary: Vector2=c.pos
 var growth_before: float=c.growth
 c.dest=c.pos+Vector2(80,0)
 for i in range(10):model.tick(0.1)
 check(c.pos.distance_to(stationary)>0,"Cat keeps walking during produce")
 check(c.growth>growth_before,"Fur growth continues during animation")
 for i in range(4):model.tick(0.1)
 check(c.pos.distance_to(stationary)>0,"Cat still walks after produce")
 var fresh = Model.new()
 visuals.step(fresh,0.1)
 check(visuals.states[fresh.cats[0].id].animation == "idle","New game clears previous visual state")
 var giant: Dictionary=fresh.cats[1]
 giant.kind="giant"
 visuals.step(fresh,0.0)
 check(visuals.texture(giant.id).resource_path.begins_with("res://Art/Cat5idle/"),"Transformation selects Cat5 idle immediately")
 giant.pos.x+=1.0;visuals.step(fresh,0.1)
 check(visuals.texture(giant.id)==Visuals.GIANT_FRAMES.get_frame_texture("walk",0),"Giant uses Cat5 walk")
 giant.layers=2;visuals.step(fresh,0.1);fresh.harvest(giant.id);visuals.step(fresh,0.0)
 check(visuals.texture(giant.id)==Visuals.GIANT_FRAMES.get_frame_texture("produce",0),"Giant uses Cat5 produce")
 visuals.step(fresh,1.05)
 check(visuals.texture(giant.id)==Visuals.GIANT_FRAMES.get_frame_texture("produce",6),"Reduced produce frames fit the existing hold")
 visuals.step(fresh,0.06)
 check(visuals.states[giant.id].animation=="idle","Giant produce finishes with existing timing")
 check(Visuals.GIANT_FRAMES.get_frame_count("idle")==10 and Visuals.GIANT_FRAMES.get_frame_count("walk")==10,"Cat5 idle halved; walk retains all frames")
 var electric: Dictionary=fresh.add_cat(Vector2(950,505))
 electric.kind="static";visuals.step(fresh,0)
 check(visuals.texture(electric.id).resource_path.begins_with("res://Art/Cat8idle/"),"Static cat selects Cat8 idle")
 electric.pos.x+=1;visuals.step(fresh,0.1)
 check(visuals.texture(electric.id).resource_path.begins_with("res://Art/Cat8Walk/"),"Static cat selects Cat8 walk")
 electric.layers=1;visuals.step(fresh,0.1);fresh.harvest(electric.id);visuals.step(fresh,0)
 check(visuals.texture(electric.id).resource_path.begins_with("res://Art/Cat8Produce/"),"Static cat selects Cat8 produce")
 visuals.step(fresh,1.05)
 check(visuals.texture(electric.id)==Visuals.STATIC_FRAMES.get_frame_texture("produce",6),"Reduced Cat8 produce frames play")
 visuals.step(fresh,0.06)
 check(visuals.states[electric.id].animation=="idle","Static cat returns to idle")
 for animation in ["idle","walk","produce"]:
  var expected: int = {"idle":10,"walk":10,"produce":6}[animation]
  check(Visuals.FRAMES.get_frame_count(animation)==expected,"All frames loaded: "+animation)
  for frame in range(expected):
   var texture: Texture2D = Visuals.FRAMES.get_frame_texture(animation,frame)
   check(texture != null and texture.get_width()>0,"Texture loaded")
   check(texture.get_image().get_pixel(0,0).a<0.01,"Frame background transparent")
 if "--capture" in OS.get_cmdline_user_args():
  root.size = Vector2i(1440,900)
  var room = Room.new()
  room.model = fresh
  fresh.cats[1].layers=fresh.cats[0].layers
  room.size = Vector2(1440,900)
  root.add_child(room)
  room.step(0.0)
  fresh.gacha_ready=true
  room.consume_event({"kind":"money","pos":fresh.cats[0].pos,"text":"+3.0"})
  room.step(0.3)
  check(room.static_outlines.sprites.has(electric.id),"Static cat has outline")
  check(not room.static_outlines.sprites.has(giant.id),"Other cats do not receive static outlines")
  for i in range(4): await process_frame
  await RenderingServer.frame_post_draw
  var output: String = OS.get_environment("TEMP").path_join("purr-cat-animation-preview.png")
  check(root.get_texture().get_image().save_png(output)==OK,"Room preview saved")
  print("PREVIEW: ",output)
  room.queue_free()
  await process_frame
 print("CAT ANIMATION CHECKS: ",failures," failures")
 quit(0 if failures == 0 else 1)
