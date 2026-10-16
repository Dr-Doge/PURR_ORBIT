extends "res://scripts/prototype_grooming/model.gd"
const FurAssets=preload("res://scripts/prototype_grooming_fur/assets.gd")
const Tool=preload("res://scripts/prototype_grooming_fur/tool_geometry.gd")
const PATCH_SIZE=Vector2(96,72)
const PATCH_STEP=Vector2(88,58)
const EDGE_PASSES=4
const PATCH_ANGLE_LIMIT=6.0
const FLEA_CLICKS=3
const DUST_PASSES=2
var fur_ready: bool=false
var cat_scale: float=1.0
var next_cat_scale: float=0.0

func _init() -> void:
 super()
 assets=FurAssets.new();claw_spans=[];prepare_claw();fur_ready=true;start_order(0)

func start_order(index: int,nail_practice: bool=false) -> void:
 if fur_ready:
  cat_scale=.5 if index%3==2 else 1.0
  if next_cat_scale>0:cat_scale=next_cat_scale;next_cat_scale=0
  assets.subject_scale=cat_scale
 super.start_order(index,nail_practice)
 if not fur_ready:return
 if kind=="calico":
  title=("大灰白猫" if cat_scale==1 else "小灰白猫")+(" · 分层梳理" if order_index==0 else " · 梳理＋修甲")
  if nail_practice:title="灰白猫 · 修甲练习";return
  objects=[];build_fur_objects()
  note="向右顺梳，尾巴也可向上梳；毛块整片脱落，轮廓来回梳四趟后整片脱落。跳蚤点三下。"
  note_left=4.0

func build_body_mask() -> void:
 if not fur_ready:super.build_body_mask();return
 var raw: Image=assets.image(kind+"_clean").duplicate()
 raw.resize(C.BODY_GRID.x,C.BODY_GRID.y,Image.INTERPOLATE_NEAREST)
 body_mask=Image.create(C.BODY_GRID.x,C.BODY_GRID.y,false,Image.FORMAT_RGBA8)
 body_valid.resize(C.BODY_GRID.x*C.BODY_GRID.y)
 for y in range(C.BODY_GRID.y):
  for x in range(C.BODY_GRID.x):
   var valid: bool=raw.get_pixel(x,y).a>0.15
   body_valid[y*C.BODY_GRID.x+x]=int(valid)
   body_mask.set_pixel(x,y,Color(float(valid),0,0,1))

func coat_at(uv: Vector2) -> String:
 var raw: Image=assets.image("calico_clean")
 var p: Color=raw.get_pixel(clampi(int(uv.x*raw.get_width()),0,raw.get_width()-1),clampi(int(uv.y*raw.get_height()),0,raw.get_height()-1))
 return "cream" if p.r>0.82 and p.g>0.79 and p.b>0.72 else "gray"

# Service zones exclude the entire head, ears and paws, not only facial marks.
func service_zone(uv: Vector2) -> bool:
 var body:=PackedVector2Array([Vector2(.44,.38),Vector2(.53,.33),Vector2(.74,.40),Vector2(.85,.51),Vector2(.86,.73),Vector2(.77,.83),Vector2(.47,.83),Vector2(.44,.70)])
 var tail:=PackedVector2Array([Vector2(.835,.08),Vector2(.945,.025),Vector2(.995,.20),Vector2(.985,.53),Vector2(.90,.66),Vector2(.835,.55)])
 return Geometry2D.is_point_in_polygon(uv,body) or Geometry2D.is_point_in_polygon(uv,tail)

func sample_point(obj: Dictionary,x: int,y: int) -> Vector2:
 var offset: Vector2=obj.rect.size*(Vector2((x+.5)/C.OBJECT_GRID,(y+.5)/C.OBJECT_GRID)-Vector2(.5,.5))
 return obj.rect.get_center()+offset.rotated(obj.get("draw_angle",0.0))

func patch_fits(type: String,uv: Vector2,angle: float) -> bool:
 var raw: Image=assets.image(type)
 # Test the complete visible silhouette before placement; never crop it to fit.
 for y in range(32):
  for x in range(32):
   if raw.get_pixel(int((x+.5)/32*raw.get_width()),int((y+.5)/32*raw.get_height())).a<.12:continue
   var point: Vector2=body_rect.position+body_rect.size*uv+(PATCH_SIZE*(Vector2((x+.5)/32,(y+.5)/32)-Vector2(.5,.5))).rotated(angle)
   var at: Vector2=(point-body_rect.position)/body_rect.size
   if not service_zone(at) or not body_hit(at):return false
 return true

func build_fur_objects() -> void:
 var count: int=0
 for row in range(ceili(body_rect.size.y/PATCH_STEP.y)):
  for column in range(ceili(body_rect.size.x/PATCH_STEP.x)):
   var local:=Vector2((column+.5)*PATCH_STEP.x+(22 if row%2 else 0),(row+.5)*PATCH_STEP.y)
   var uv: Vector2=local/body_rect.size
   if not service_zone(uv) or not body_hit(uv):continue
   # Same rightward hairlock shape. Tail hair follows the raised tail upward.
   var tail: bool=uv.x>=.835
   var angle: float=deg_to_rad((-78.0 if tail else -12.0)+float((row+column)%3-1)*PATCH_ANGLE_LIMIT)
   var type: String=coat_at(uv)+"_wide"
   if not patch_fits(type,uv,angle):continue
   add_full_object(type,"patch",uv,PATCH_SIZE,angle);count+=1
 # Follow the actual silhouette rather than cropping large strips into a thin mask.
 for i in range(5):
  var x: float=.50+i*.064
  add_outline("edge_gray_back",boundary_at_x(x,.30,.65,false),Vector2(142,60)*maxf(.75,cat_scale),deg_to_rad(-8+i*3))
 for i in range(4):
  var x: float=.51+i*.070
  add_outline("edge_cream_belly",boundary_at_x(x,.66,.865,true),Vector2(136,58)*maxf(.75,cat_scale),deg_to_rad(-6+i*3))
 for i in range(3):
  var y: float=.22+i*.135
  add_outline("edge_gray_flank",boundary_at_y(y,.84,.999,true),Vector2(130,58)*maxf(.75,cat_scale),deg_to_rad(-78+i*4))
 for i in range(2):
  var y: float=.29+i*.16
  add_outline("edge_gray_back",boundary_at_y(y,.81,.94,false),Vector2(112,54)*maxf(.75,cat_scale),deg_to_rad(-82+i*6))
 add_object("knot_gray","knot",Vector2(.56,.47),Vector2(110,100))
 if cat_scale==1:add_object("knot_cream","knot",Vector2(.48,.72),Vector2(110,100))
 add_object("dust_gray","dust",Vector2(.75,.53),Vector2(115,85))
 if cat_scale==1:add_object("dust_cream","dust",Vector2(.66,.75),Vector2(115,85))
 add_object("flea_idle","flea",Vector2(.72,.40),Vector2(76,64))
 objects[-1].home=objects[-1].rect.position

func boundary_at_x(x: float,low: float,high: float,bottom: bool) -> Vector2:
 var raw: Image=assets.image("calico_clean")
 var first: int=int(low*raw.get_height());var last: int=int(high*raw.get_height())
 for i in range(last-first):
  var y: int=last-1-i if bottom else first+i
  if raw.get_pixel(int(x*raw.get_width()),y).a>.6:return Vector2(x,float(y)/raw.get_height())
 return Vector2(x,(low+high)*.5)

func boundary_at_y(y: float,low: float,high: float,right: bool) -> Vector2:
 var raw: Image=assets.image("calico_clean")
 var first: int=int(low*raw.get_width());var last: int=int(high*raw.get_width())
 for i in range(last-first):
  var x: int=last-1-i if right else first+i
  if raw.get_pixel(x,int(y*raw.get_height())).a>.6:return Vector2(float(x)/raw.get_width(),y)
 return Vector2((low+high)*.5,y)

func add_object(type: String,rule: String,center: Vector2,drawn: Vector2) -> void:
 if not fur_ready or kind!="calico":super.add_object(type,rule,center,drawn);return
 add_full_object(type,rule,center,drawn)

func add_full_object(type: String,rule: String,center: Vector2,drawn: Vector2,angle: float=0.0) -> void:
 var raw: Image=assets.image(type)
 var mask:=Image.create(C.OBJECT_GRID,C.OBJECT_GRID,false,Image.FORMAT_RGBA8)
 # Source alpha is the only visual clipping. Collision samples do not cut sprites.
 mask.fill(Color.WHITE)
 var left:=PackedFloat32Array();left.resize(C.OBJECT_GRID*C.OBJECT_GRID)
 var count: int=0
 for y in range(C.OBJECT_GRID):
  for x in range(C.OBJECT_GRID):
   var valid: bool=raw.get_pixel(int((x+.5)/C.OBJECT_GRID*raw.get_width()),int((y+.5)/C.OBJECT_GRID*raw.get_height())).a>.12
   left[y*C.OBJECT_GRID+x]=float(valid);count+=int(valid)
 if count==0:return
 objects.append({"id":objects.size(),"type":type,"rule":rule,"rect":Rect2(body_rect.position+body_rect.size*center-drawn*.5,drawn),"draw_angle":angle,"mask":mask,"left":left,"initial":count,"sum":float(count),"version":0,"done":false,"passes":0,"travel":0.0,"dir":0.0,"axis":-1,"last_pass_dir":0.0,"last_pass_gesture":-1})

func add_outline(type: String,uv: Vector2,drawn: Vector2,angle: float=0.0) -> void:
 add_full_object(type,"edge",uv,drawn,angle)

func outline_stroke(obj: Dictionary,a: Vector2,b: Vector2) -> int:
 var delta: Vector2=b-a
 var tail: bool=(obj.rect.get_center().x-body_rect.position.x)/body_rect.size.x>=.83
 var axis: int=1 if tail and absf(delta.y)>absf(delta.x) else 0
 if absf(delta[axis])/delta.length()<.70:return 0
 var direction: float=signf(delta[axis])
 if obj.axis<0:obj.axis=axis
 elif obj.axis!=axis:return 0
 if obj.last_pass_dir==direction:return 0
 if obj.dir!=direction:obj.travel=0.0;obj.dir=direction
 var extent: float=obj.rect.size[axis]*.5
 var center: float=obj.rect.get_center()[axis]
 var lo: float=maxf(minf(a[axis],b[axis]),center-extent)
 var hi: float=minf(maxf(a[axis],b[axis]),center+extent)
 # Count only travel through this lock; not the rest of a long background stroke.
 obj.travel+=maxf(0.0,hi-lo)
 # Real travel, independent of mouse event count. Tiny oscillations never count.
 var threshold: float=maxf(24.0,obj.rect.size[axis]*.40)
 if obj.travel<threshold:return 0
 obj.passes+=1;obj.travel=0.0;obj.last_pass_dir=direction;obj.version+=1
 hint("轮廓毛 %d/%d · 来回轻梳 ↔"%[obj.passes,EDGE_PASSES])
 if obj.passes>=EDGE_PASSES:clear_object(obj)
 return 1

func cleaning_progress() -> float:
 if not fur_ready or kind!="calico":return super.cleaning_progress()
 if objects.is_empty():return 1.0
 var completed: float=0.0
 for obj in objects:
  if obj.done:completed+=1.0
  elif obj.rule=="edge":completed+=float(obj.passes)/EDGE_PASSES
  else:completed+=1.0-obj.sum/obj.initial
 return completed/objects.size()

func tick(dt: float) -> void:
 super.tick(dt)
 if not fur_ready or paused or kind!="calico" or stage!="cleaning":return
 for obj in objects:
  if obj.rule=="flea" and not obj.done:
   obj.rect.position=obj.home+Vector2(sin(now*3.0)*28.0,cos(now*4.0)*10.0)

func click_at(at: Vector2) -> Dictionary:
 var result: Dictionary={"changed":0,"particle":"fall_gray_wisps","point":at}
 if paused or stage!="cleaning" or kind!="calico":return result
 for obj in objects:
  if obj.rule!="flea" or obj.done or not obj.rect.grow(12).has_point(at):continue
  obj.passes+=1;obj.version+=1;result.changed=1
  hint("跳蚤 %d/%d"%[obj.passes,FLEA_CLICKS])
  if obj.passes>=FLEA_CLICKS:clear_object(obj);hint("跳蚤清除了！");check_clean_finished()
  break
 return result

func stroke(a: Vector2,b: Vector2,dt: float,measured_speed: float=-1.0) -> Dictionary:
 if not fur_ready or kind=="robot":return super.stroke(a,b,dt)
 var result: Dictionary={"changed":0,"pain":false,"particle":"fall_gray_peel","point":b}
 if paused or stage!="cleaning" or dt<=0 or a.distance_to(b)<.05:return result
 var delta: Vector2=b-a
 var speed: float=measured_speed if measured_speed>=0 else delta.length()/dt
 var forward: bool=delta.x/delta.length()>=C.COMB_DIRECTION_COS
 var area:=Rect2(a,Vector2.ZERO).expand(b).grow(Tool.EDGE_LENGTH*.5)
 var touched: bool=false
 for obj in objects:
  if obj.done or obj.rule=="flea" or not area.intersects(obj.rect.grow(maxf(obj.rect.size.x,obj.rect.size.y)*.25)) or not object_contact(obj,a,b):continue
  touched=true
  if speed>Tool.SPEED_LIMIT:continue
  if obj.rule=="dust":
   if absf(delta.y)/delta.length()<.70:hint("灰尘上下轻扫 ↕");continue
   var dir: float=signf(delta.y)
   if obj.last_pass_dir==dir:continue
   if obj.dir!=dir:obj.travel=0.0;obj.dir=dir
   obj.travel+=minf(absf(delta.y),obj.rect.size.y)
   if obj.travel>=obj.rect.size.y*.50:
    obj.passes+=1;obj.travel=0;obj.last_pass_dir=dir;result.changed+=1
    hint("灰尘 %d/%d · 换向再扫"%[obj.passes,DUST_PASSES])
    if obj.passes>=DUST_PASSES:clear_object(obj)
   continue
  if obj.rule=="edge":
   result.changed+=outline_stroke(obj,a,b);continue
  var on_tail: bool=(obj.rect.get_center().x-body_rect.position.x)/body_rect.size.x>=.83
  var tail_up: bool=on_tail and -delta.y/delta.length()>=C.COMB_DIRECTION_COS
  if not forward and not tail_up:
   hint("尾巴向右／向上轻梳 → ↑" if on_tail else "沿毛流轻柔向右梳 →");continue
  if on_tail:hint("尾巴可直接向右／向上轻梳 → ↑")
  if obj.rule=="knot":
   if speed>Tool.KNOT_SPEED_LIMIT:hint("打结处慢梳 · 不超过500像素/秒 →");continue
   obj.travel+=Tool.covered_length(a,b,obj.rect.get_center())
   if obj.travel<Tool.EDGE_HALF_WIDTH*1.8:continue
  # Any visibly occupied part brushed by the teeth is actionable. Requiring
  # a transparent rectangle centre made narrow tail patches unreachable.
  clear_object(obj);result.changed+=obj.initial
  result.particle="fall_cream_peel" if obj.type.begins_with("cream") or obj.type=="knot_cream" else "fall_gray_peel"
 if touched and speed>Tool.SPEED_LIMIT:result.pain=pain("超过1200像素/秒 · 轻一点 · 评价 -5")
 if result.changed>0:check_clean_finished()
 return result

func object_contact(obj: Dictionary,a: Vector2,b: Vector2) -> bool:
 if not fur_ready or kind=="robot":return super.object_contact(obj,a,b)
 for y in range(C.OBJECT_GRID):
  for x in range(C.OBJECT_GRID):
   if obj.left[y*C.OBJECT_GRID+x]<=0:continue
   var p: Vector2=sample_point(obj,x,y)
   if Tool.covered_length(a,b,p)>0:return true
 return false

func erase_segment(obj: Dictionary,a: Vector2,b: Vector2,resistance: float,one_pass: bool=false) -> int:
 if not fur_ready or kind=="robot":return super.erase_segment(obj,a,b,resistance,one_pass)
 var changed: int=0
 for y in range(C.OBJECT_GRID):
  for x in range(C.OBJECT_GRID):
   var i: int=y*C.OBJECT_GRID+x
   if obj.left[i]<=0:continue
   var p: Vector2=sample_point(obj,x,y)
   if Tool.covered_length(a,b,p)<=0:continue
   obj.sum-=obj.left[i];obj.left[i]=0;obj.mask.set_pixel(x,y,Color(0,0,0,1));changed+=1
 if changed>0:
  obj.version+=1
  if obj.sum/obj.initial<=C.FINISH_TOLERANCE:clear_object(obj)
 return changed
