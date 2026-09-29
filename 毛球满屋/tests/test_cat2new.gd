extends SceneTree
const M=preload("res://scripts/model.gd")
const V=preload("res://scripts/cat_visuals.gd")
var failures=0
var checks=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize() -> void:
 var m=M.new();var v=V.new();var c: Dictionary=m.cats[0];c.kind="static"
 v.step(m,0)
 for pair in [[Vector2(4,0),"walk"],[Vector2(-4,0),"walk"],[Vector2(0,-4),"walk_up"],[Vector2(0,4),"walk_down"]]:
  c.pos+=pair[0];v.step(m,0.1)
  check(v.states[c.id].clip==pair[1],"Directional movement")
  m.reset_activity(c);c.idle_left=100;m.tick(0.001);v.step(m,0)
  check(v.states[c.id].clip==String(pair[1]).replace("walk","idle"),"Directional idle")
 c.groom_wait=0;m.tick(0.01);v.step(m,0)
 check(v.states[c.id].clip=="groom","Rest animation begins")
 var at: Vector2=c.pos;m.tick(0.4);v.step(m,0)
 check(c.pos==at and v.states[c.id].clip=="groom","Rest locks movement")
 m.set_hovered_cat(c.id);m.pet(c.id,1);v.step(m,0)
 check(v.states[c.id].clip=="pet","Pet interrupts rest")
 preload("res://tests/harvest_fixture.gd").settle(m,c.id);v.step(m,0)
 check(v.states[c.id].clip=="produce" and is_equal_approx(c.reaction_left,1.1),"Produce keeps economic cooldown")
 m.tick(1.2);v.step(m,0);c.pop=0;m.cancel_pet(c)
 var room=preload("res://scenes/room.tscn").instantiate();room.model=m;room.cat_visuals=v
 v.states[c.id].clip="idle";var base: Vector2=room.cat_rect(c).size
 for clip in ["pet","walk_down","idle_down"]:
  v.states[c.id].clip=clip
  check(room.cat_rect(c).size.is_equal_approx(base*(1.32 if clip=="pet" else 1.05)),"Requested size: "+clip)
 v.states[c.id].clip="idle"
 check(is_equal_approx(v.foot_anchor(c.id),265.0/320.0),"Side idle feet align to own padding")
 v.states[c.id].clip="walk"
 check(is_equal_approx(v.foot_anchor(c.id),278.0/320.0),"Side walk has a stable grounded pivot")
 var total=0
 for clip in V.STATIC_FRAMES.get_animation_names():
  v.states[c.id].clip=clip
  var anchor: float=v.foot_anchor(c.id)
  for i in range(V.STATIC_FRAMES.get_frame_count(clip)):
   var texture: AtlasTexture=V.STATIC_FRAMES.get_frame_texture(clip,i);total+=1
   check(texture.atlas.resource_path.begins_with("res://Art/Cat2new/"),"New static sheet")
   check(float(V.read_frame_image(texture).get_used_rect().end.y)/320.0<=anchor,"Feet remain above floor")
 check(total==80,"All 80 frames included")
 room.free()
 print("CAT2NEW: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
