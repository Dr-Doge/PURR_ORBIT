extends SceneTree
const M=preload("res://scripts/model.gd")
const S=preload("res://scripts/cat_space.gd")
var failures=0
var checks=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func allowed(delta: Vector2) -> bool:
 return minf(absf(delta.x),absf(delta.y))<=maxf(absf(delta.x),absf(delta.y))*tan(PI/9.0)+0.0001
func _initialize() -> void:
 var m=M.new();m.rng.seed=720
 var c: Dictionary=m.cats[0]
 for i in range(200):
  c.pos=m.D.FLOOR.get_center();m.start_walk(c)
  check(allowed(c.dest-c.pos),"Wander target inside cardinal cone")
 for target in [Vector2(350,350),Vector2(1100,350),Vector2(350,680),Vector2(1100,680)]:
  c.pos=m.D.FLOOR.get_center()
  for i in range(1000):
   var before: Vector2=c.pos
   c.pos=S.walk(m,c,c.pos.move_toward(target,3.0))
   check(allowed(c.pos-before),"Each navigation step inside cardinal cone")
   if c.pos.distance_to(target)<1.0:break
  check(c.pos.distance_to(target)<1.0,"Off-axis destination remains reachable")
 for i in range(3000):
  var positions: Dictionary={}
  for cat in m.cats:positions[cat.id]=cat.pos
  m.tick(0.05)
  for cat in m.cats:check(allowed(cat.pos-positions[cat.id]),"Simulation respects cones including avoidance")
 print("CARDINAL MOVEMENT: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
