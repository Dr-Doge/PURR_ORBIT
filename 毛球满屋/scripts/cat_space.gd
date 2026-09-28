extends RefCounted
const D=preload("res://scripts/data.gd")
static func radius(c: Dictionary) -> Vector2:
 var scale: float=(1.35 if c.kind=="giant" else 1.0)*(1.342 if c.kind=="lucky" else 1.0)*(1+D.MAX_LAYERS*D.CAT_LAYER_SIZE_STEP)
 return Vector2(57,30)*scale*1.16 # Reserve room for fur and pulse, not just current idle frame.
static func is_clear(m,c: Dictionary,at: Vector2) -> bool:
 for other in m.cats:
  if other.id==c.id:continue
  var bounds: Vector2=radius(c)+radius(other)+Vector2(8,8)
  if ((at-other.pos)/bounds).length_squared()<1.0:return false
 return true
static func place(m,_c: Dictionary,at: Vector2) -> Vector2:
 # Placement and dragging are authoritative; overlap is resolved later by walking.
 return m.clamp_position(at)
static func walk(m,c: Dictionary,at: Vector2) -> Vector2:
 at=m.clamp_position(at)
 if is_clear(m,c,at):return at
 var direction: Vector2=at-c.pos
 # Best effort only: prefer a clear small turn, but never block forward travel.
 for angle in [PI/6,-PI/6]:
  var candidate: Vector2=m.clamp_position(c.pos+direction.rotated(angle))
  if is_clear(m,c,candidate):return candidate
 return at
static func body_radius(c: Dictionary) -> Vector2:
 var scale: float=(1.35 if c.kind=="giant" else 1.0)*(1.342 if c.kind=="lucky" else 1.0)*(1+clampi(c.layers,1,D.MAX_LAYERS)*D.CAT_LAYER_SIZE_STEP)
 return Vector2(30,22)*scale # Body footprint, not the larger optional avoidance margin.
static func overlaps(a: Dictionary,b: Dictionary) -> bool:
 return ((a.pos-b.pos)/(body_radius(a)+body_radius(b))).length_squared()<1.0
static func can_leave(m,c: Dictionary) -> bool:
 return c.station==-1 and not c.dragging and not m.hovered(c)
static func escape_spot(m,c: Dictionary) -> Vector2:
 var start_angle: float=fmod(float(c.id)*2.399963,TAU)
 for ring in range(1,25):
  for step in range(24):
   var candidate: Vector2=m.clamp_position(c.pos+Vector2.from_angle(start_angle+step*TAU/24.0)*ring*18.0)
   if is_clear(m,c,candidate):return candidate
 # Crowding cannot force a teleport or a hard collision; still try to walk away.
 return m.clamp_position(c.pos+Vector2.from_angle(start_angle)*100.0)
static func update_overlap(m,dt: float) -> void:
 var active: Dictionary={}
 var leave: Dictionary={}
 for i in range(m.cats.size()):
  var a: Dictionary=m.cats[i]
  for j in range(i+1,m.cats.size()):
   var b: Dictionary=m.cats[j]
   # Held/carried cats are under direct control. Start grace after release.
   if a.dragging or b.dragging or a.station < -1 or b.station < -1 or not overlaps(a,b):continue
   var key: String=str(mini(a.id,b.id))+":"+str(maxi(a.id,b.id))
   active[key]=float(m.cat_overlap_times.get(key,0.0))+dt
   if active[key]<=m.B.CAT_OVERLAP_GRACE+0.000001:continue
   var first: Dictionary=a if a.id>b.id else b
   var second: Dictionary=b if a.id>b.id else a
   var chosen: Dictionary=first if can_leave(m,first) else second
   if can_leave(m,chosen):leave[chosen.id]=true
 m.cat_overlap_times=active
 for id in m.cat_escape_targets.keys():
  if not leave.has(id):m.cat_escape_targets.erase(id)
 for id in leave:
  var c: Dictionary=m.cat(id)
  if not m.cat_escape_targets.has(id) or c.pos.distance_to(m.cat_escape_targets[id])<1.0:
   m.cat_escape_targets[id]=escape_spot(m,c)
static func escape(m,c: Dictionary,dt: float) -> bool:
 if not can_leave(m,c) or not m.cat_escape_targets.has(c.id):return false
 c.pos=c.pos.move_toward(m.cat_escape_targets[c.id],D.CAT_MOVE_SPEED*dt)
 return true
static func reserved(m,f: Dictionary,except_cat: int=-1) -> bool:
 for c in m.cats:
  if c.id==except_cat:continue
  if c.station==f.id or (not c.dragging and c.station==-1 and c.get("feed_target",-1)==f.id):return true
 for w in m.workers:
  if w.job.get("facility",-1)==f.id and w.job.get("cat",-1)!=except_cat:return true
 return false
static func reconcile(m) -> void:
 var seen: Dictionary={}
 for c in m.cats:
  if c.station>=0:
   if seen.has(c.station):m.move_cat(c.id,c.pos)
   else:seen[c.station]=true
  if c.station==-1:
   var original: Vector2=c.pos
   c.pos=place(m,c,c.pos)
   if c.pos!=original:c.dest=c.pos

 for c in m.cats:
  var id: int=c.get("feed_target",-1)
  if id<0:continue
  var f: Dictionary=m.facility(id)
  if seen.has(id) or f.is_empty() or f.kind!="feeder" or f.grain<=0 or c.station!=-1 or c.fed>0:
   c.feed_target=-1;c.eat_time=0.0
  else:seen[id]=true
