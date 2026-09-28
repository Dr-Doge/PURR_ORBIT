extends SceneTree
const M=preload("res://scripts/model.gd")
const V=preload("res://scripts/cat_visuals.gd")
var checks=0
var failures=0
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(why)
func pair():
 var m=M.new();m.cats.resize(2)
 for c in m.cats:
  m.move_cat(c.id,Vector2(650,460));c.idle_left=100;c.walk_left=0;c.fed=100
 return m
func sim(m,seconds: float) -> void:
 for i in range(roundi(seconds/0.05)):m.tick(0.05)
func _initialize() -> void:
 var m=pair();var a=m.cats[0];var b=m.cats[1];var origin: Vector2=a.pos
 check(a.pos==b.pos,"Drop placement permits exact overlap")
 sim(m,2.0)
 check(a.pos==origin and b.pos==origin,"Two seconds inclusive do not force separation")
 m.tick(0.05)
 check(a.pos!=origin or b.pos!=origin,"Overlap longer than two seconds starts escape")
 check(maxf(a.pos.distance_to(origin),b.pos.distance_to(origin))<=0.801,"Escape walks at normal speed, no teleport")
 var visual=V.new();visual.step(m,0)
 check(visual.states[b.id].animation=="walk","Escaping movement uses walk, never idle")
 sim(m,15)
 check(not m.Space.overlaps(a,b),"Overlapping pair eventually separates")
 check(m.cat_overlap_times.is_empty(),"Separation clears pair timer")
 m=pair();a=m.cats[0];b=m.cats[1];sim(m,1.5)
 b.pos=Vector2(1000,650);m.tick(0.05);b.pos=a.pos;sim(m,1.0)
 check(a.pos==b.pos,"New encounter receives a fresh grace interval")
 m=pair();a=m.cats[0];b=m.cats[1];a.dragging=true;sim(m,4)
 check(a.pos==b.pos and m.cat_overlap_times.is_empty(),"Held overlap does not push either cat or age timer")
 a.dragging=false;sim(m,2)
 check(a.pos==b.pos,"Release starts full two second grace")
 m.tick(0.05);check(a.pos!=b.pos,"After release grace escape starts")
 m=pair();a=m.cats[0];b=m.cats[1];m.set_hovered_cat(b.id);sim(m,2.2)
 check(b.pos==origin and a.pos!=origin,"Hovered cat stays still; other free cat leaves")
 m=pair();a=m.cats[0];b=m.cats[1];m.wallet=1000000
 for topic in ["worker","feeder","sun"]:m.research(topic)
 m.buy("sun",Vector2(650,425));var f=m.facilities[0]
 check(m.assign(a.id,f.id),"Assign first cat to facility")
 check(not m.assign(b.id,f.id),"Short overlaps do not bypass single-cat facility reservation")
 b.pos=a.pos;m.Space.update_overlap(m,2.1)
 check(m.cat_escape_targets.has(b.id) and not m.cat_escape_targets.has(a.id),"Free cat moves around occupied facility")
 m=pair();a=m.cats[0];b=m.cats[1]
 var direct: Vector2=a.pos+Vector2(0.2,0)
 check(m.Space.walk(m,a,direct)==direct,"Crowding does not hard-block forward travel")
 sim(m,1);var saved=m.snapshot();m.cat_escape_targets[a.id]=Vector2.ZERO
 check(m.restore(saved),"Overlapping state remains loadable")
 check(m.cats[0].pos==m.cats[1].pos,"Load does not forcibly relocate overlapping cats")
 check(m.cat_overlap_times.is_empty() and m.cat_escape_targets.is_empty(),"Load clears transient pair times and escape destinations")
 print("SOFT OVERLAP: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
