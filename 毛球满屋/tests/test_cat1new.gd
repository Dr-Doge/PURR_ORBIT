extends SceneTree
const M=preload("res://scripts/model.gd")
const V=preload("res://scripts/cat_visuals.gd")
var failures=0
var checks=0
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var m=M.new();var v=V.new();var c: Dictionary=m.cats[0]
 v.step(m,0)
 for pair in [[Vector2(4,1),"walk",true],[Vector2(-4,1),"walk",false],[Vector2(1,-4),"walk_up",false],[Vector2(-1,4),"walk_down",false]]:
  c.pos+=pair[0];v.step(m,0.1)
  check(v.states[c.id].clip==pair[1] and v.flipped(c.id)==pair[2],"Dominant movement direction "+pair[1])
  m.reset_activity(c);c.idle_left=100;m.tick(0.001);v.step(m,0)
  check(v.states[c.id].clip==String(pair[1]).replace("walk","idle"),"Idle retains direction")
 v.states[c.id].groom_wait=0;v.step(m,0)
 check(v.states[c.id].clip=="groom","Idle timer triggers grooming")
 c.pos.x+=4;v.step(m,0.1)
 check(v.states[c.id].clip=="walk","Movement interrupts grooming")
 m.reset_activity(c);c.idle_left=100;m.tick(0.001);m.set_hovered_cat(c.id);m.pet(c.id,1);v.step(m,0)
 check(v.states[c.id].clip=="pet","Pet input starts stroking")
 var t=v.texture(c.id);v.step(m,0.625)
 check(v.texture(c.id)==t,"Stroking animation loops")
 preload("res://tests/harvest_fixture.gd").settle(m,c.id);v.step(m,0)
 check(v.states[c.id].clip=="produce" and is_equal_approx(c.reaction_left,1.1),"Produce overrides pet without changing cooldown")
 m.tick(0.55);v.step(m,0)
 check(v.texture(c.id)==V.Short.FRAMES.get_frame_texture("produce",2),"Produce follows model clock")
 var snapshot=var_to_bytes(m.cats);v.step(m,0.2)
 check(snapshot==var_to_bytes(m.cats),"Visuals never mutate simulation")
 for kind in ["giant","static","lucky","alien"]:
  var other: Dictionary=m.add_cat(Vector2(300,400));other.kind=kind;v.step(m,0)
  check(v.states[other.id].frames==(V.Alien.FRAMES if kind=="alien" else V.A.frames_for(kind)),"Other cat unchanged: "+kind)
 m.tick(0.6);m.cancel_pet(c);m.set_hovered_cat(-1);m.reset_activity(c);c.idle_left=100;m.tick(0.001);v.step(m,0)
 v.states[c.id].groom_wait=0;v.step(m,0);v.step(m,2.51)
 check(v.states[c.id].clip.begins_with("idle"),"Grooming completes into idle")
 var room=preload("res://scenes/room.tscn").instantiate();room.model=m;room.cat_visuals=v
 v.states[c.id].clip="walk";var side_size: Vector2=room.cat_rect(c).size
 v.states[c.id].clip="walk_up";var up_size: Vector2=room.cat_rect(c).size
 check(up_size.is_equal_approx(side_size*0.88),"Only upward walking is 12 percent smaller")
 for clip in ["idle_up","walk_down","idle","produce","pet","groom"]:
  v.states[c.id].clip=clip
  check(room.cat_rect(c).size.is_equal_approx(side_size),"Other clip retains size: "+clip)
 for clip in V.Short.FRAMES.get_animation_names():
  var sheet: AtlasTexture=V.Short.FRAMES.get_frame_texture(clip,0)
  check(sheet.atlas.resource_path.begins_with("res://Art/cat1new1/"),"Latest sheet: "+clip)
 room.free()
 print("CAT1NEW: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
