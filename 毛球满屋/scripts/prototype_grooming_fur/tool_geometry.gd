extends RefCounted
# 1920x1080 logical pixels. Visible tooth edge and physics share this data.
const EDGE_LENGTH=110.0
const EDGE_HALF_WIDTH=6.0
const SPEED_LIMIT=1200.0 # Historical guide only; Comfort now controls penalties.
const KNOT_SPEED_LIMIT=500.0
const SPEED_WINDOW=.10
const IDLE_TILT=-0.20
const IDLE_LIFT=Vector2(-12,-18)
# Coordinates in the existing cropped 585x398 comb texture.
const TOOTH_FIRST=Vector2(80,377)
const TOOTH_LAST=Vector2(431,240)

static func rotation_angle() -> float:
 return PI/2.0-(TOOTH_LAST-TOOTH_FIRST).angle()
static func texture_scale() -> float:return EDGE_LENGTH/TOOTH_FIRST.distance_to(TOOTH_LAST)
static func center_offset(texture_size: Vector2) -> Vector2:
 return -project_texture_point((TOOTH_FIRST+TOOTH_LAST)*.5,texture_size)
static func project_texture_point(point: Vector2,texture_size: Vector2) -> Vector2:
 # Keep the head up and handle down, but face the teeth right (stroke direction).
 return ((point-texture_size*.5)*texture_scale()).rotated(rotation_angle())*Vector2(-1,1)
static func edge_points(at: Vector2) -> PackedVector2Array:
 return PackedVector2Array([at-Vector2(0,EDGE_LENGTH*.5),at+Vector2(0,EDGE_LENGTH*.5)])

static func covered_length(a: Vector2,b: Vector2,point: Vector2) -> float:
 var span: Vector2=coverage_interval(a,b,point)
 return a.distance_to(b)*maxf(0.0,span.y-span.x)

static func coverage_interval(a: Vector2,b: Vector2,point: Vector2) -> Vector2:
 var delta: Vector2=b-a
 if delta.length()<.00001:return Vector2.ZERO
 var lo: float=0.0;var hi: float=1.0
 for axis in range(2):
  var half: float=EDGE_HALF_WIDTH if axis==0 else EDGE_LENGTH*.5
  var start: float=a[axis]-point[axis];var motion: float=delta[axis]
  if absf(motion)<.00001:
   if absf(start)>half:return Vector2.ZERO
  else:
   var t0: float=(-half-start)/motion;var t1: float=(half-start)/motion
   lo=maxf(lo,minf(t0,t1));hi=minf(hi,maxf(t0,t1))
   if lo>=hi:return Vector2.ZERO
 return Vector2(lo,hi)
