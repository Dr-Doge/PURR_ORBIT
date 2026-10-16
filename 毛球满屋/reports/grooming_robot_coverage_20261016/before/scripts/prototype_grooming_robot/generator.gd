extends RefCounted
const R=preload("res://scripts/prototype_grooming_robot/config.gd")
var polygon: PackedVector2Array=PackedVector2Array(R.SERVICE)
var report: Dictionary={}
func inside(uv: Vector2,raw: Image) -> bool:
 if not Geometry2D.is_point_in_polygon(uv,polygon):return false
 if uv.x<0 or uv.y<0 or uv.x>=1 or uv.y>=1:return false
 return raw.get_pixel(int(uv.x*raw.get_width()),int(uv.y*raw.get_height())).a>.8
func fits(rect: Rect2,body: Rect2,raw: Image,existing: Array) -> bool:
 # The entire rectangle lies in a convex, opaque torso zone. Thus even low-alpha
 # fringes remain on the body; sprites are never cropped to manufacture a fit.
 for y in range(5):
  for x in range(5):
   var uv: Vector2=(rect.position+rect.size*Vector2(x/4.0,y/4.0)-body.position)/body.size
   if not inside(uv,raw):return false
 for other in existing:
  var intersection: Rect2=rect.intersection(other.rect)
  if intersection.has_area() and intersection.get_area()/minf(rect.get_area(),other.rect.get_area())>R.MAX_RECT_OVERLAP:return false
 return true
func generate(seed_value: int,assets: RefCounted,body: Rect2) -> Array:
 var rng:=RandomNumberGenerator.new();rng.seed=seed_value
 var normal_count: int=rng.randi_range(R.NORMAL_COUNT.x,R.NORMAL_COUNT.y)
 var stubborn_count: int=rng.randi_range(R.STUBBORN_COUNT.x,R.STUBBORN_COUNT.y)
 var requests: Array=[]
 # Place large objects first; reserve at least one of each source type per order.
 for i in stubborn_count:requests.append({"type":R.STUBBORN_TYPES[i] if i<2 else R.STUBBORN_TYPES[rng.randi_range(0,1)],"stubborn":true})
 for i in normal_count:requests.append({"type":R.NORMAL_TYPES[i] if i<2 else R.NORMAL_TYPES[rng.randi_range(0,1)],"stubborn":false})
 var bounds:=Rect2(polygon[0],Vector2.ZERO)
 for point in polygon:bounds=bounds.expand(point)
 var raw: Image=assets.image("robot_clean")
 var result: Array=[];var fallback_count: int=0;var dropped: int=0
 for request in requests:
  var image: Image=assets.image(request.type)
  var width_range: Vector2=R.STUBBORN_WIDTH if request.stubborn else R.NORMAL_WIDTH
  var width: float=body.size.x*bounds.size.x*rng.randf_range(width_range.x,width_range.y)
  var drawn:=Vector2(width,width*image.get_height()/image.get_width())
  var placed: bool=false;var rect: Rect2
  for attempt in R.MAX_ATTEMPTS:
   var uv:=bounds.position+Vector2(rng.randf(),rng.randf())*bounds.size
   rect=Rect2(body.position+uv*body.size-drawn*.5,drawn)
   if fits(rect,body,raw,result):placed=true;break
  if not placed:
   for row in R.FALLBACK_ROWS:
    for column in R.FALLBACK_COLUMNS:
     var uv: Vector2=bounds.position+bounds.size*Vector2((column+.5)/R.FALLBACK_COLUMNS,(row+.5)/R.FALLBACK_ROWS)
     rect=Rect2(body.position+uv*body.size-drawn*.5,drawn)
     if fits(rect,body,raw,result):placed=true;break
    if placed:break
   if placed:fallback_count+=1
  if not placed:dropped+=1;continue
  result.append({"type":request.type,"stubborn":request.stubborn,"rect":rect,
   "opacity":1.0 if request.stubborn else rng.randf_range(R.OPACITY.x,R.OPACITY.y),
   "required_passes":R.STUBBORN_PASSES.get(request.type,0)})
 report={"seed":seed_value,"requested_normal":normal_count,"requested_stubborn":stubborn_count,"actual_normal":0,"actual_stubborn":0,"fallback":fallback_count,"dropped":dropped}
 for object in result:report["actual_stubborn" if object.stubborn else "actual_normal"]+=1
 return result
