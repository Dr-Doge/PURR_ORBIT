extends RefCounted
const R=preload("res://scripts/prototype_grooming_robot/config.gd")
var polygon: PackedVector2Array=PackedVector2Array(R.SERVICE)
var report: Dictionary={}
static var shape_cache: Dictionary={}
func inside(uv: Vector2,raw: Image) -> bool:
 if not Geometry2D.is_point_in_polygon(uv,polygon):return false
 if uv.x<0 or uv.y<0 or uv.x>=1 or uv.y>=1:return false
 return raw.get_pixel(int(uv.x*raw.get_width()),int(uv.y*raw.get_height())).a>.8
func shape_points(type: String,assets: RefCounted) -> PackedVector2Array:
 if shape_cache.has(type):return shape_cache[type]
 var source: Image=assets.image(type)
 var points:=PackedVector2Array()
 for y in 32:
  for x in 32:
   var uv:=Vector2((x+.5)/32,(y+.5)/32)
   if source.get_pixel(int(uv.x*source.get_width()),int(uv.y*source.get_height())).a>.08:points.append(uv)
 # Include the source's outer fringe, not transparent rectangle corners.
 for y in range(0,source.get_height(),4):
  var lo: int=source.get_width();var hi: int=-1
  for x in source.get_width():
   if source.get_pixel(x,y).a>.03:lo=mini(lo,x);hi=maxi(hi,x)
  if hi>=lo:
   points.append(Vector2(float(lo)/source.get_width(),float(y)/source.get_height()))
   points.append(Vector2(float(hi)/source.get_width(),float(y)/source.get_height()))
 shape_cache[type]=points;return points
func fits(rect: Rect2,body: Rect2,raw: Image,existing: Array,footprint: PackedVector2Array) -> bool:
 for other in existing:
  var intersection: Rect2=rect.intersection(other.rect)
  if intersection.has_area() and intersection.get_area()/minf(rect.get_area(),other.rect.get_area())>R.MAX_RECT_OVERLAP:return false
 # Validate the entire visible source shape against the torso and base alpha.
 # This permits irregular stains near curved shoulders/back/abdomen without
 # cropping or restricting all large rectangles to the centre of the torso.
 for point in footprint:
  if not inside((rect.position+rect.size*point-body.position)/body.size,raw):return false
 return true
func generate(seed_value: int,assets: RefCounted,body: Rect2) -> Array:
 var rng:=RandomNumberGenerator.new();rng.seed=seed_value
 var normal_count: int=rng.randi_range(R.NORMAL_COUNT.x,R.NORMAL_COUNT.y)
 var stubborn_count: int=rng.randi_range(R.STUBBORN_COUNT.x,R.STUBBORN_COUNT.y)
 var requests: Array=[]
 # Place large objects first; reserve at least one of each source type per order.
 for i in stubborn_count:requests.append({"type":R.STUBBORN_TYPES[i] if i<2 else R.STUBBORN_TYPES[rng.randi_range(0,1)],"stubborn":true,"zone":"back" if i%2==0 else "hind"})
 for i in normal_count:requests.append({"type":R.NORMAL_TYPES[i] if i<2 else R.NORMAL_TYPES[rng.randi_range(0,1)],"stubborn":false,"zone":R.NORMAL_ZONE_ORDER[i%4]})
 var bounds:=Rect2(polygon[0],Vector2.ZERO)
 for point in polygon:bounds=bounds.expand(point)
 var raw: Image=assets.image("robot_clean")
 var result: Array=[];var fallback_count: int=0;var dropped: int=0;var smaller_fallback: int=0
 for request in requests:
  var image: Image=assets.image(request.type)
  var footprint: PackedVector2Array=shape_points(request.type,assets)
  var zone: Rect2=R.ZONES[request.zone]
  var width_range: Vector2=R.STUBBORN_WIDTH if request.stubborn else R.NORMAL_WIDTH
  var width: float=body.size.x*bounds.size.x*rng.randf_range(width_range.x,width_range.y)
  var drawn:=Vector2(width,width*image.get_height()/image.get_width())
  var placed: bool=false;var rect: Rect2
  for attempt in R.MAX_ATTEMPTS:
   var uv:=zone.position+Vector2(rng.randf(),rng.randf())*zone.size
   rect=Rect2(body.position+uv*body.size-drawn*.5,drawn)
   if fits(rect,body,raw,result,footprint):placed=true;break
  if not placed:
   for size_attempt in 2:
    if size_attempt==1:
     var minimum: float=body.size.x*bounds.size.x*width_range.x
     drawn=Vector2(minimum,minimum*image.get_height()/image.get_width())
    for row in R.FALLBACK_ROWS:
     for column in R.FALLBACK_COLUMNS:
      var uv: Vector2=zone.position+zone.size*Vector2((column+.5)/R.FALLBACK_COLUMNS,(row+.5)/R.FALLBACK_ROWS)
      rect=Rect2(body.position+uv*body.size-drawn*.5,drawn)
      if fits(rect,body,raw,result,footprint):placed=true;break
     if placed:break
    if placed:
     smaller_fallback+=int(size_attempt==1);break
   if placed:fallback_count+=1
  # A narrow shoulder can fit one enlarged stain but not three. Keep that
  # area's first stain, then redistribute excess requests to other torso zones
  # instead of shrinking them below the new size range or silently losing work.
  if not placed and not request.stubborn:
   var minimum: float=body.size.x*bounds.size.x*width_range.x
   drawn=Vector2(minimum,minimum*image.get_height()/image.get_width())
   for alternate in R.NORMAL_ZONE_ORDER:
    if alternate==request.zone:continue
    var alternate_zone: Rect2=R.ZONES[alternate]
    for row in R.FALLBACK_ROWS:
     for column in R.FALLBACK_COLUMNS:
      var uv: Vector2=alternate_zone.position+alternate_zone.size*Vector2((column+.5)/R.FALLBACK_COLUMNS,(row+.5)/R.FALLBACK_ROWS)
      rect=Rect2(body.position+uv*body.size-drawn*.5,drawn)
      if fits(rect,body,raw,result,footprint):placed=true;break
     if placed:break
    if placed:
     request.zone=alternate;fallback_count+=1;smaller_fallback+=1;break
  if not placed:dropped+=1;continue
  result.append({"type":request.type,"stubborn":request.stubborn,"rect":rect,"zone":request.zone,
   "opacity":1.0 if request.stubborn else rng.randf_range(R.OPACITY.x,R.OPACITY.y),
   "required_passes":R.STUBBORN_PASSES.get(request.type,0)})
 report={"seed":seed_value,"requested_normal":normal_count,"requested_stubborn":stubborn_count,"actual_normal":0,"actual_stubborn":0,"fallback":fallback_count,"minimum_size_fallback":smaller_fallback,"dropped":dropped,"zones":{"shoulder":0,"back":0,"belly":0,"hind":0}}
 for object in result:
  report["actual_stubborn" if object.stubborn else "actual_normal"]+=1
  report.zones[object.zone]+=1
 return result
