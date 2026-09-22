extends SceneTree
const M=preload("res://scripts/model.gd")
const V=preload("res://scripts/cat_visuals.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var m=M.new();m.cats.resize(1);var c: Dictionary=m.cats[0]
 m.reset_activity(c);c.pos=Vector2(600,500);c.dest=Vector2(700,500);c.walk_left=5
 var v=V.new();v.step(m,0)
 m.tick(0.1);v.step(m,0.1)
 check(v.states[c.id].animation=="walk","Actual movement displays walk")
 for i in range(5):v.step(m,0)
 check(v.states[c.id].animation=="walk","Multiple display refreshes cannot replace movement with idle")
 m.set_hovered_cat(c.id);v.step(m,0);v.step(m,0)
 check(v.states[c.id].animation=="walk","Hover arriving after a movement step cannot hide that displacement as idle")
 var at: Vector2=c.pos;m.tick(0.1);v.step(m,0.1)
 check(c.pos==at and v.states[c.id].animation=="idle","First actually stationary hover step displays idle")
 var growth: float=c.growth;m.tick(0.1);v.step(m,0.1)
 check(c.pos==at and c.growth>growth and v.states[c.id].animation=="idle","Idle stays in place while production clock runs")
 m.set_hovered_cat(-1);m.tick(0.1);v.step(m,0.1)
 check(c.pos!=at and v.states[c.id].animation=="walk","Resume switches to walk on first position change")
 m.reset_activity(c);c.idle_left=2;at=c.pos;m.tick(0.1);v.step(m,0.1)
 check(c.pos==at and v.states[c.id].animation=="idle","Natural idle has zero displacement")
 c.dragging=true;c.pos+=Vector2(20,0);v.step(m,0);v.step(m,0)
 check(v.states[c.id].animation!="idle","Dragged displacement never uses idle, including repeated refresh")
 m.tick(0.1);v.step(m,0.1);check(v.states[c.id].animation=="idle","Stationary held cat can idle")
 c.dragging=false;c.station=-99;c.pos+=Vector2(20,0);v.step(m,0);v.step(m,0)
 check(v.states[c.id].animation!="idle","Carried displacement never uses idle")
 c.station=-1;m.reset_activity(c);c.idle_left=2;m.tick(0.1);v.step(m,0.1)
 var action: Dictionary=m.harvest_ticket(c);action.progress=m.harvest_time(c.layers)
 check(m.harvest(c.id,action),"Reaction fixture completes valid harvest")
 v.step(m,0);check(v.states[c.id].animation=="produce","Produce remains higher priority than idle and walk")
 m.tick(1.2);v.step(m,0.1);check(v.states[c.id].animation=="idle","Stationary cat returns to idle after reaction")
 var snap: Dictionary=m.snapshot()
 check(not snap.has("cat_displacements") and not snap.has("motion_tick"),"Motion telemetry never changes save schema")
 check(m.restore(snap) and m.cat_displacements.is_empty(),"Loading clears previous motion telemetry")
 var tiny=M.new();var tiny_cat: Dictionary=tiny.cats[0];tiny_cat.pos=Vector2.ZERO
 var tiny_visuals=V.new();tiny_visuals.step(tiny,0);tiny_cat.pos.x=0.000001;tiny_visuals.step(tiny,0)
 check(tiny_visuals.states[tiny_cat.id].animation=="walk","Even subpixel displacement cannot be classified as idle")
 # Frame-by-frame invariant over real random walking/feeding/growth/hover/worker activity.
 m=M.new();m.rng.seed=9;m.wallet=100000
 for key in ["worker","feeder","sun"]:m.research(key)
 m.buy("feeder",Vector2(600,500));m.refill(m.facilities[0].id);m.buy("worker",Vector2(500,500))
 v=V.new();v.step(m,0)
 var bad_frames: int=0;var idle_frames: int=0;var moving_frames: int=0
 for frame in range(1800):
  var positions: Dictionary={}
  for cat in m.cats:positions[cat.id]=cat.pos
  m.set_hovered_cat(m.cats[0].id if frame%100<25 else -1)
  m.tick(1.0/60.0);v.step(m,1.0/60.0);v.step(m,0)
  for cat in m.cats:
   if cat.pos!=positions[cat.id]:moving_frames+=1
   if v.states[cat.id].animation=="idle":
    idle_frames+=1
    if cat.pos!=positions[cat.id]:bad_frames+=1
 check(idle_frames>0 and moving_frames>0 and bad_frames==0,"1800 simulation frames: no idle frame has displacement")
 print("IDLE 009: ",checks," checks, ",failures," failures; ",idle_frames," idle, ",moving_frames," moving samples")
 quit(0 if failures==0 else 1)
