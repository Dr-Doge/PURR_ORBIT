extends SceneTree
var failures=0
func check(ok: bool,msg: String) -> void:
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:call_deferred("run")
func capture() -> Image:
 for i in range(4):await process_frame
 await RenderingServer.frame_post_draw
 return root.get_texture().get_image()
func run() -> void:
 root.size=Vector2i(1440,810)
 var game=load("res://scenes/3D scene.tscn").instantiate();game.testing=true;root.add_child(game)
 game.start_game();game.set_process(false);game.room.set_process(false);game.model.cats.clear()
 var index=0
 for kind in ["short","giant","static","lucky","alien"]:
  var cat=game.model.add_cat(Vector2(310+index*205,540));cat.kind=kind;index+=1
 game.room.step(0);game.refresh()
 var fill=game.room.actor_lighting.get_node("CatFillLight")
 check(fill.light_cull_mask==2 and not fill.shadow_enabled,"Fill affects only cat layer without extra shadows")
 for actor in game.room.actor_lighting.sprites.values():
  check(actor.layers==3 if str(actor.name).begins_with("Cat_") else actor.layers==1,"Correct light layer")
 fill.visible=false;var before: Image=await capture()
 fill.visible=true;var after: Image=await capture()
 var rectangles: Array[Rect2]=[]
 for cat in game.model.cats:
  var rect: Rect2=game.room.cat_rect(cat);var factor: float=game.room.object_scale(cat.pos)
  rectangles.append(Rect2(game.room.screen_position(cat.pos)+(rect.position-cat.pos)*factor,rect.size*factor).grow(4))
 var brighter=0;var outside=0
 for y in range(0,after.get_height(),2):
  for x in range(0,after.get_width(),2):
   var delta=after.get_pixel(x,y).get_luminance()-before.get_pixel(x,y).get_luminance()
   if absf(delta)<0.005:continue
   var inside=false
   for rect in rectangles:
    if rect.has_point(Vector2(x,y)):inside=true;break
   if inside and delta>0.01:brighter+=1
   if not inside:outside+=1
 check(brighter>100,"Cat pixels visibly brighter")
 check(outside<20,"Room brightness unchanged")
 DirAccess.make_dir_recursive_absolute("res://reports/cat1new2_fix")
 before.save_png("res://reports/cat1new2_fix/fill_off.png");after.save_png("res://reports/cat1new2_fix/fill_on.png")
 var cat: Dictionary=game.model.cats[0]
 for depth in [350,540,680]:
  cat.pos=Vector2(700,depth);game.room.step(0)
  var state: Dictionary=game.room.cat_visuals.states[cat.id]
  state.clip="walk_up";state.animation="walk";state.flip=false
  for frame_index in range(5):
   state.age=frame_index/8.0;game.room.actor_lighting.sync()
   var sprite=game.room.actor_lighting.sprites["Cat_%d"%cat.id]
   var bounds: Rect2i=sprite.texture.get_image().get_used_rect()
   var lowest: float=sprite.position.y+(sprite.texture.get_height()*0.5-bounds.end.y)*sprite.pixel_size*sprite.scale.y
   check(lowest>=-0.00001,"Upward feet never cross 3D floor")
 var upward: Image=await capture();upward.save_png("res://reports/cat1new2_fix/upward.png")
 print("CAT FILL: brighter=",brighter,", outside=",outside,", failures=",failures)
 game.queue_free();await process_frame;quit(0 if failures==0 else 1)
