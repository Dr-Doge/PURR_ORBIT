extends RefCounted
const C=preload("res://scripts/prototype_grooming/config.gd")
const Assets=preload("res://scripts/prototype_grooming/assets.gd")
var assets=Assets.new()
var now: float=0.0
var wallet: int=0
var serial: int=0
var order_index: int=0
var kind: String="calico"
var title: String=""
var score: int=100
var stage: String="arrival"
var stage_left: float=0.0
var needs_nails: bool=false
var settled: bool=false
var last_payment: int=0
var base_pay: int=100
var served: int=0
var paused: bool=false
var gesture: int=0
var last_pain: float=-100.0
var reaction: float=0.0
var note: String="按住左键，梳理脏污；毛结要慢一点"
var note_left: float=0.0
var objects: Array=[]
var nails: Array=[]
var body_rect: Rect2
var body_mask: Image
var body_valid: PackedByteArray
var version: int=0
var claw_image: Image
var claw_scale: float
var quick_height: float
var claw_spans: Array=[]

func _init() -> void:
 prepare_claw()
 start_order(0)

func prepare_claw() -> void:
 claw_image=assets.image("claw_long")
 claw_scale=C.CLAW_HEIGHT/claw_image.get_height()
 var first_pink: int=claw_image.get_height()
 for y in range(claw_image.get_height()):
  var lo: int=claw_image.get_width()
  var hi: int=-1
  for x in range(claw_image.get_width()):
   var p: Color=claw_image.get_pixel(x,y)
   if p.a>0.15:
    lo=mini(lo,x);hi=maxi(hi,x)
   if p.a>0.6 and p.r>0.7 and p.g>0.25 and p.g<0.82 and p.r>p.g+0.12 and p.b>0.3 and p.r>p.b+0.03:
    first_pink=mini(first_pink,y)
  claw_spans.append(Vector2i(lo,hi))
 quick_height=(claw_image.get_height()-first_pink)*claw_scale

func start_order(index: int, nail_practice: bool=false) -> void:
 serial+=1;version+=1;gesture+=1
 order_index=index%3;kind=C.ORDER_KINDS[order_index];title=C.ORDER_NAMES[order_index]
 score=100;settled=false;last_payment=0;last_pain=-100.0;reaction=0.0
 needs_nails=order_index==2 or nail_practice
 base_pay=C.ORDER_PAY[order_index]
 stage="arrival";stage_left=C.ARRIVAL_TIME
 objects=[];nails=[]
 body_rect=assets.body_rect(kind)
 build_body_mask()
 for i in range(C.ORDINARY_POINTS.size()):
  var type: String="dust" if kind=="calico" else ["oil","fingerprints","soot"][i%3]
  add_object(type,"normal",C.ORDINARY_POINTS[i],Vector2(240,210))
 add_object("knot" if kind=="calico" else "soot","slow",Vector2(0.69,0.43),Vector2(145,145))
 add_object("trash" if kind=="calico" else "tar","sticky",Vector2(0.81,0.63),Vector2(165,145))
 for i in range(4): nails.append({"id":i,"root":C.CLAW_ROOTS[i],"height":C.CLAW_HEIGHT,"done":false,"result":"","cuts":0})
 note="按住左键，慢慢梳理；毛结放慢，垃圾来回刷" if kind=="calico" else "按住左键擦拭；积灰放慢，油块来回擦"
 note_left=3.0
 if nail_practice:
  objects=[];stage="nails";stage_left=0.0;title="三花猫 · 修甲练习";base_pay=100
  note="按住左键横向划过绿色区间；太浅可再剪，粉红根部不能剪"

func build_body_mask() -> void:
 var raw: Image=assets.image(kind+"_clean").duplicate()
 raw.resize(C.BODY_GRID.x,C.BODY_GRID.y,Image.INTERPOLATE_NEAREST)
 body_mask=Image.create(C.BODY_GRID.x,C.BODY_GRID.y,false,Image.FORMAT_RGBA8)
 body_valid.resize(C.BODY_GRID.x*C.BODY_GRID.y)
 for y in range(C.BODY_GRID.y):
  for x in range(C.BODY_GRID.x):
   var valid: bool=raw.get_pixel(x,y).a>0.15 and float(x)/C.BODY_GRID.x>0.37
   body_valid[y*C.BODY_GRID.x+x]=1 if valid else 0
   body_mask.set_pixel(x,y,Color(1,0,0,1) if valid else Color(0,0,0,1))

func body_hit(uv: Vector2) -> bool:
 if uv.x<0 or uv.x>=1 or uv.y<0 or uv.y>=1:return false
 var x: int=clampi(int(uv.x*C.BODY_GRID.x),0,C.BODY_GRID.x-1)
 var y: int=clampi(int(uv.y*C.BODY_GRID.y),0,C.BODY_GRID.y-1)
 return body_valid[y*C.BODY_GRID.x+x]==1

func add_object(type: String, rule: String, center: Vector2, size: Vector2) -> void:
 var original: Image=assets.image(type).duplicate()
 original.resize(C.OBJECT_GRID,C.OBJECT_GRID,Image.INTERPOLATE_BILINEAR)
 var rect:=Rect2(body_rect.position+body_rect.size*center-size/2.0,size)
 var mask: Image=Image.create(C.OBJECT_GRID,C.OBJECT_GRID,false,Image.FORMAT_RGBA8)
 var remaining:=PackedFloat32Array();remaining.resize(C.OBJECT_GRID*C.OBJECT_GRID)
 var count: int=0
 for y in range(C.OBJECT_GRID):
  for x in range(C.OBJECT_GRID):
   var point: Vector2=rect.position+rect.size*Vector2((x+0.5)/C.OBJECT_GRID,(y+0.5)/C.OBJECT_GRID)
   var valid: bool=original.get_pixel(x,y).a>0.08 and body_hit((point-body_rect.position)/body_rect.size)
   var value: float=1.0 if valid else 0.0
   remaining[y*C.OBJECT_GRID+x]=value;mask.set_pixel(x,y,Color(value,0,0,1))
   if valid:count+=1
 if count==0:return
 objects.append({"id":objects.size(),"type":type,"rule":rule,"rect":rect,"mask":mask,"left":remaining,"initial":count,"sum":float(count),"version":0,"done":false,"passes":0,"travel":0.0,"dir":0.0,"axis":-1,"last_pass_dir":0.0,"last_pass_gesture":-1})

func tick(dt: float) -> void:
 if paused:return
 now+=dt;reaction=maxf(0.0,reaction-dt);note_left=maxf(0.0,note_left-dt)
 if stage not in ["arrival","to_nails","reward","departure"]:return
 stage_left=maxf(0.0,stage_left-dt)
 if stage_left>0.0:return
 match stage:
  "arrival":stage="cleaning"
  "to_nails":
   stage="nails";note="横向划过绿色区间修甲；不要碰粉红根部";note_left=3.0
  "reward":stage="departure";stage_left=C.DEPARTURE_TIME
  "departure":start_order(order_index+1)

func begin_gesture() -> void:gesture+=1

func hint(text: String) -> void:
 note=text;note_left=1.2

func pain(text: String, amount: int=C.PAIN_COST, always: bool=false) -> bool:
 if not always and now-last_pain<C.PAIN_INTERVAL:return false
 score=maxi(0,score-amount);last_pain=now;reaction=0.28;hint(text)
 return true

static func covered_length(a: Vector2,b: Vector2,p: Vector2,radius: float) -> float:
 var length: float=a.distance_to(b)
 if length<0.00001:return 0.0
 var direction: Vector2=(b-a)/length
 var projection: float=(p-a).dot(direction)
 var perpendicular: float=maxf(0.0,(p-a).length_squared()-projection*projection)
 if perpendicular>=radius*radius:return 0.0
 var reach: float=sqrt(radius*radius-perpendicular)
 return maxf(0.0,minf(length,projection+reach)-maxf(0.0,projection-reach))

func stroke(a: Vector2,b: Vector2,dt: float) -> Dictionary:
 var result: Dictionary={"changed":0,"pain":false,"particle":"fur_white" if kind=="calico" else "oil_fleck","point":b}
 if paused or stage!="cleaning" or dt<=0.0 or a.distance_to(b)<0.05:return result
 var speed: float=a.distance_to(b)/dt/body_rect.size.x
 var area:=Rect2(a,Vector2.ZERO).expand(b).grow(C.BRUSH_RADIUS)
 var touched: bool=false
 for obj in objects:
  if obj.done or not area.intersects(obj.rect):continue
  if not object_contact(obj,a,b):continue
  touched=true
  if speed>C.MAX_SPEED:continue
  if obj.rule=="slow" and speed>C.KNOT_SPEED:
   hint("毛结要慢慢梳" if kind=="calico" else "积灰要慢慢擦")
   continue
  if obj.rule=="sticky":
   result.changed+=sticky_stroke(obj,a,b)
   continue
  var resistance: float=C.KNOT_RESISTANCE if obj.rule=="slow" else C.NORMAL_RESISTANCE
  var changed: int=erase_segment(obj,a,b,resistance)
  result.changed+=changed
  if changed>0 and obj.rule=="slow":hint("毛结正在松开" if kind=="calico" else "积灰正在清除")
 if touched and speed>C.MAX_SPEED:result.pain=pain("太快了！顾客不舒服 · 评价 -5")
 if result.changed>0:check_clean_finished()
 return result

func object_contact(obj: Dictionary,a: Vector2,b: Vector2) -> bool:
 var rect: Rect2=obj.rect
 for y in range(C.OBJECT_GRID):
  for x in range(C.OBJECT_GRID):
   if obj.left[y*C.OBJECT_GRID+x]<=0.0:continue
   var p: Vector2=rect.position+rect.size*Vector2((x+0.5)/C.OBJECT_GRID,(y+0.5)/C.OBJECT_GRID)
   if covered_length(a,b,p,C.BRUSH_RADIUS)>0.0:return true
 return false

func erase_segment(obj: Dictionary,a: Vector2,b: Vector2,resistance: float) -> int:
 var changed: int=0;var rect: Rect2=obj.rect
 for y in range(C.OBJECT_GRID):
  for x in range(C.OBJECT_GRID):
   var i: int=y*C.OBJECT_GRID+x;var previous: float=obj.left[i]
   if previous<=0.0:continue
   var p: Vector2=rect.position+rect.size*Vector2((x+0.5)/C.OBJECT_GRID,(y+0.5)/C.OBJECT_GRID)
   var travel: float=covered_length(a,b,p,C.BRUSH_RADIUS)
   if travel<=0.0:continue
   var value: float=maxf(0.0,previous-travel/(C.BRUSH_RADIUS*1.3*resistance))
   obj.left[i]=value;obj.sum-=previous-value;obj.mask.set_pixel(x,y,Color(value,0,0,1));changed+=1
 if changed>0:
  obj.version+=1
  if obj.sum/obj.initial<=C.FINISH_TOLERANCE:clear_object(obj)
 return changed

func clear_object(obj: Dictionary) -> void:
 obj.done=true;obj.sum=0.0;obj.mask.fill(Color(0,0,0,1));obj.version+=1
 obj.left.fill(0.0)

func sticky_stroke(obj: Dictionary,a: Vector2,b: Vector2) -> int:
 var delta: Vector2=b-a
 if obj.axis==-1:obj.axis=0 if absf(delta.x)>=absf(delta.y) else 1
 var motion: float=delta.x if obj.axis==0 else delta.y
 if absf(motion)<0.1:return 0
 var direction: float=signf(motion)
 if obj.last_pass_dir==direction and obj.last_pass_gesture==gesture:return 0
 if obj.dir!=direction:obj.travel=0.0;obj.dir=direction
 var width: float=obj.rect.size.x if obj.axis==0 else obj.rect.size.y
 obj.travel+=minf(absf(motion),width)
 if obj.travel<width*C.STICKY_TRAVEL:return 0
 obj.travel=0.0;obj.passes+=1;obj.last_pass_dir=direction;obj.last_pass_gesture=gesture;obj.version+=1
 if obj.passes>=C.STICKY_PASSES:
  clear_object(obj);hint("粘附物清掉了！");return obj.initial
 hint("松动了，反方向再刷一次！")
 return 1

func cleaning_progress() -> float:
 if objects.is_empty():return 1.0
 var done: float=0.0
 for obj in objects:
  if obj.done:done+=1.0
  elif obj.rule=="sticky":done+=0.45*float(obj.passes)/C.STICKY_PASSES
  else:done+=1.0-obj.sum/obj.initial
 return done/objects.size()

func check_clean_finished() -> void:
 if stage!="cleaning":return
 for obj in objects:
  if not obj.done:return
 if needs_nails:stage="to_nails";stage_left=C.NAIL_TRANSITION;hint("梳理完成 · 现在修剪指甲")
 else:settle()

func nail_edges(nail: Dictionary,height: float) -> Vector2:
 var y: int=clampi(int(claw_image.get_height()-height/claw_scale),0,claw_image.get_height()-1)
 var span: Vector2i=claw_spans[y]
 if span.y<span.x:return Vector2(INF,INF)
 var left: float=nail.root.x-claw_image.get_width()*claw_scale/2.0
 return Vector2(left+span.x*claw_scale,left+(span.y+1)*claw_scale)

func perfect_height() -> float:return quick_height+C.NAIL_BAND_WIDTH/2.0

func cut_gesture(points: PackedVector2Array) -> Dictionary:
 var result: Dictionary={"result":"miss","nail":-1,"pain":false}
 if paused or stage!="nails" or points.size()<2:return result
 for nail in nails:
  if nail.done:continue
  var reference: Vector2=nail_edges(nail,perfect_height())
  var axis: float=(reference.x+reference.y)/2.0
  for i in range(points.size()-1):
   var a: Vector2=points[i];var b: Vector2=points[i+1]
   if absf(b.x-a.x)<0.001 or axis<minf(a.x,b.x) or axis>maxf(a.x,b.x):continue
   var t: float=(axis-a.x)/(b.x-a.x)
   var y: float=lerpf(a.y,b.y,t)
   var height: float=nail.root.y-y
   if height<8.0 or height>=nail.height-2.0:continue
   var edges: Vector2=nail_edges(nail,height)
   if not is_finite(edges.x):continue
   var xmin: float=INF;var xmax: float=-INF;var ymin: float=INF;var ymax: float=-INF
   for p in points:
    xmin=minf(xmin,p.x);xmax=maxf(xmax,p.x)
   # Clip every continuous segment to the claw's horizontal span. Sparse events
   # must not bypass the angle/depth rule just because endpoints lie outside it.
   for j in range(points.size()-1):
    var p: Vector2=points[j];var q: Vector2=points[j+1]
    var dx: float=q.x-p.x
    if absf(dx)<0.001:
     if p.x>=edges.x-10.0 and p.x<=edges.y+10.0:ymin=minf(ymin,minf(p.y,q.y));ymax=maxf(ymax,maxf(p.y,q.y))
     continue
    var t0: float=(edges.x-10.0-p.x)/dx;var t1: float=(edges.y+10.0-p.x)/dx
    var lo: float=maxf(0.0,minf(t0,t1));var hi: float=minf(1.0,maxf(t0,t1))
    if lo>hi:continue
    var y0: float=lerpf(p.y,q.y,lo);var y1: float=lerpf(p.y,q.y,hi)
    ymin=minf(ymin,minf(y0,y1));ymax=maxf(ymax,maxf(y0,y1))
   if xmin>edges.x-3.0 or xmax<edges.y+3.0:continue
   if is_finite(ymin) and ymax-ymin>C.NAIL_ANGLE_TOLERANCE:continue
   if is_finite(ymax):height=minf(height,nail.root.y-ymax)
   if height<8.0:continue
   nail.height=height;nail.cuts+=1
   result.nail=nail.id;result.point=Vector2(axis,nail.root.y-height)
   if height<=quick_height:
    nail.done=true;nail.result="deep";result.result="deep";result.pain=pain("剪到粉红根部了 · 评价 -20",C.DEEP_COST,true)
   elif height<=quick_height+C.NAIL_BAND_WIDTH:
    nail.done=true;nail.result="perfect";result.result="perfect";hint("刚刚好！")
   else:nail.result="shallow";result.result="shallow";hint("太浅了，靠近绿色区域再剪一次")
   check_nails_finished()
   return result
 hint("按住左键，横向划过整根指甲")
 return result

func check_nails_finished() -> void:
 if stage!="nails":return
 for nail in nails:
  if not nail.done:return
 settle()

func settle() -> int:
 if settled:return 0
 if stage not in ["cleaning","nails"]:return 0
 for obj in objects:
  if not obj.done:return 0
 if needs_nails:
  for nail in nails:
   if not nail.done:return 0
 settled=true;last_payment=C.payment(base_pay,score);wallet+=last_payment;served+=1
 stage="reward";stage_left=C.REWARD_TIME;note="服务完成！";note_left=1.0
 return last_payment
