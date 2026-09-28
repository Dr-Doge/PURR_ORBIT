extends SceneTree
const M=preload("res://scripts/model.gd")
const V=preload("res://scripts/cat_visuals.gd")
const A=preload("res://scripts/cat_animation_data.gd")
var checks=0
var failures=0
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(why)
func old_walk(m,c: Dictionary,at: Vector2) -> Vector2:
 if m.Space.is_clear(m,c,at):return at
 var direction: Vector2=at-c.pos
 for angle in [PI/3,-PI/3,PI/2,-PI/2]:
  var point: Vector2=m.clamp_position(c.pos+direction.rotated(angle))
  if m.Space.is_clear(m,c,point):return point
 return c.pos
func _initialize() -> void:
 print("Hard-avoidance regression superseded by test_overlap_924.gd; historical report retained.")
 quit(0)
func historical_checks() -> void:
 var m=M.new();m.cats.resize(1);var c=m.cats[0];var visual=V.new();visual.step(m,0)
 for kind in ["short","giant","static","lucky"]:
  c.kind=kind;visual.step(m,0);var anchor=visual.foot_anchor(c.id);var stable=true
  for anim in ["idle","walk","produce"]:
   for i in range(A.frames_for(kind).get_frame_count(anim)):
    visual.states[c.id].animation=anim;visual.states[c.id].age=i*0.11
    stable=stable and is_equal_approx(visual.foot_anchor(c.id),anchor)
  check(stable,"Fixed sprite ground pivot: "+kind)
 var initial=visual.flipped(c.id)
 for i in range(120):
  c.pos.x+=0.1 if i%2==0 else -0.1;m.motion_tick+=1;visual.step(m,1.0/60.0)
 check(visual.flipped(c.id)==initial,"Subpixel oscillation cannot flip facing")
 var sign_x=-1.0 if initial else 1.0
 for i in range(20):
  c.pos.x+=sign_x*0.2;m.motion_tick+=1;visual.step(m,1.0/60.0)
 check(visual.flipped(c.id)!=initial,"Sustained travel does change facing")
 m.motion_tick+=1;visual.step(m,0.1);initial=visual.flipped(c.id)
 for i in range(20):visual.step(m,0.1)
 check(visual.flipped(c.id)==initial,"Idle/repeated renders preserve facing")
 var old_turns=0;var new_turns=0;var speed_ok=true;var overlaps=0
 for seed_value in range(30):
  for legacy in [true,false]:
   m=M.new();m.cats.clear();m.rng.seed=seed_value+9124
   c=m.add_cat(Vector2(450,400))
   for i in range(5):m.add_cat(Vector2(550+m.rng.randf_range(-60,260),400+m.rng.randf_range(-180,180)))
   c.dest=Vector2(900,400);var previous=Vector2.ZERO
   for i in range(600):
    var at: Vector2=c.pos.move_toward(c.dest,16.0/60.0)
    var next: Vector2=old_walk(m,c,at) if legacy else m.Space.walk(m,c,at)
    var delta: Vector2=next-c.pos
    if delta.length()>0.001 and previous.length()>0.001 and delta.dot(previous)<-0.0001:
     if legacy:old_turns+=1
     else:new_turns+=1
    if not legacy:
     speed_ok=speed_ok and delta.length()<=16.0/60.0+0.001
     if not m.Space.is_clear(m,c,next):overlaps+=1
    if delta.length()>0.001:previous=delta
    c.pos=next
 check(speed_ok,"Avoidance displacement never exceeds movement speed")
 check(overlaps==0,"Avoidance keeps valid nonoverlapping positions")
 check(new_turns<old_turns and new_turns==0,"No alternating opposing steps in obstruction fixtures")
 # Exercise the actual carry job, including a blocker near its destination.
 for blocked in [false,true]:
  m=M.new();m.cats.clear();m.wallet=1000000
  for subject in ["worker","feeder","sun","hats"]:m.research(subject)
  c=m.add_cat(Vector2(450,450));m.buy("sun",Vector2(850,450));m.buy("worker",Vector2(450,470))
  var w=m.workers[0];var f=m.facilities[0]
  if blocked:m.add_cat(Vector2(630,450))
  c.station=-w.id-2;w.role="sun";w.job={"kind":"sun","target":c.id,"cat":c.id,"facility":f.id,"stage":"carry"}
  var continuous=true
  for i in range(2400):
   var before: Vector2=c.pos
   m.tick_worker(w,1.0/60.0,{})
   if c.station==-w.id-2:continuous=continuous and c.pos.distance_to(before)<=m.B.WORK_SPEED*m.work_speed()/60.0+0.001
   else:break
  check(continuous,"Carry motion respects speed bound; blocked="+str(blocked))
  check(c.station==f.id,"Carrier reaches and assigns destination; blocked="+str(blocked))
 var save=m.snapshot();m.cat_navigation[c.id]={"test":true}
 check(m.restore(save) and m.cat_navigation.is_empty(),"Transient detour state cleared on load")
 print("MOTION 924: ",checks," checks, ",failures," failures; old reversals=",old_turns," new=",new_turns)
 quit(0 if failures==0 else 1)
