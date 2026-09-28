extends SceneTree
const Model = preload("res://scripts/model.gd")
const Visuals = preload("res://scripts/cat_visuals.gd")
var failures: int = 0
func check(ok: bool, message: String) -> void:
 if not ok:
  failures+=1
  push_error(message)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var model = Model.new()
 var c: Dictionary = model.cats[0]
 c.kind="alien"
 var v = Visuals.new()
 v.step(model,0)
 var idle: Texture2D=v.texture(c.id)
 v.step(model,3)
 check(v.texture(c.id)==idle and idle.resource_path.ends_with("Cat14Walk/001.png"),"Idle holds first walk frame")
 var anchor: float=v.foot_anchor(c.id)
 for i in range(4):
  c.pos.x+=1
  v.step(model,0.0 if i==0 else 0.101)
  check(v.texture(c.id).resource_path.ends_with("Cat14Walk/%03d.png" % (i+1)),"Start frame "+str(i+1))
 c.pos.x+=1;v.step(model,0.101)
 check(v.texture(c.id).resource_path.ends_with("Cat14Walk/005.png"),"Moving holds frame five")
 var y: float=v.visual_offset(c.id).y
 c.pos.x+=1;v.step(model,0.4)
 check(v.visual_offset(c.id).y<y,"Hover bobs upward")
 check(v.foot_anchor(c.id)==anchor,"Retracting feet do not shift the sprite anchor")
 for i in range(4):
  v.step(model,0.0 if i==0 else 0.101)
  check(v.texture(c.id).resource_path.ends_with("Cat14Walk/%03d.png" % (i+6)),"Stop frame "+str(i+6))
 v.step(model,0.101)
 check(v.texture(c.id)==idle and is_zero_approx(v.visual_offset(c.id).y),"Stopping lands at original height")
 c.layers=1;v.step(model,0)
 c.layers=0;c.pop=1
 var snapshot: PackedByteArray=var_to_bytes(model.cats)
 for i in range(17):
  v.step(model,0.0 if i==0 else 0.10001)
  check(v.texture(c.id).resource_path.ends_with("Cat14Produce/%03d.png" % (i+1)),"Produce frame "+str(i+1))
  if i==8:check(v.visual_offset(c.id).y < -7,"Produce floats after retracting legs")
 check(is_zero_approx(v.visual_offset(c.id).y),"Produce lands on final frame")
 check(var_to_bytes(model.cats)==snapshot,"Animation does not modify gameplay")
 v.step(model,0.11)
 check(v.texture(c.id)==idle,"Produce returns to idle")
 c.pos.x+=1;v.step(model,0)
 v.step(model,0.01)
 c.pos.x+=1;v.step(model,0.01)
 check(v.states[c.id].animation=="lift","Interrupted landing can restart movement")
 if "--capture" in OS.get_cmdline_user_args():
  var room = preload("res://scripts/room.gd").new()
  room.model=model
  root.size=Vector2i(1440,900)
  room.size=Vector2(1440,900)
  root.add_child(room)
  room.step(0)
  for i in range(3):await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("purr-cat14-preview.png"))
  room.queue_free()
  await process_frame
 print("ALIEN ANIMATION CHECKS: ",failures," failures")
 quit(0 if failures==0 else 1)
