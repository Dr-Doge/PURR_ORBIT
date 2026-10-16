extends "res://scripts/prototype_grooming/model.gd"
const FurAssets=preload("res://scripts/prototype_grooming_fur/assets.gd")
const Tool=preload("res://scripts/prototype_grooming_fur/tool_geometry.gd")
const PATCH_SIZE=Vector2(96,72)
const PATCH_STEP=Vector2(64,43)
const EDGE_PASSES=1
const PATCH_ANGLE_LIMIT=6.0
const Comfort=preload("res://scripts/prototype_grooming_fur/comfort.gd")
var comfort=Comfort.new()
const FLEA_CLICKS=3
const DUST_PASSES=2
var fur_ready: bool=false
var cat_scale: float=1.0
var next_cat_scale: float=0.0
var outline_profiles: Dictionary={}

func _init() -> void:
 super()
 assets=FurAssets.new();claw_spans=[];prepare_claw();fur_ready=true;start_order(0)

func start_order(index: int,nail_practice: bool=false) -> void:
 if fur_ready:
  cat_scale=.5 if index%3==2 else 1.0
  if next_cat_scale>0:cat_scale=next_cat_scale;next_cat_scale=0
  assets.subject_scale=cat_scale
 super.start_order(index,nail_practice)
 comfort.reset()
 if not fur_ready:return
 if kind=="calico":
  title=("大灰白猫" if cat_scale==1 else "小灰白猫")+(" · 分层梳理" if order_index==0 else " · 梳理＋修甲")
  if nail_practice:title="灰白猫 · 修甲练习";return
  objects=[];build_fur_objects()
  note="按住左键激活梳子，从左向右梳 →；身体和轮廓毛一梳脱落。毛结慢梳，灰尘上下扫，跳蚤点三下。"
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
var service_body=PackedVector2Array([Vector2(.44,.38),Vector2(.53,.33),Vector2(.74,.40),Vector2(.85,.51),Vector2(.86,.73),Vector2(.77,.83),Vector2(.47,.83),Vector2(.44,.70)])
var service_tail=PackedVector2Array([Vector2(.835,.08),Vector2(.945,.025),Vector2(.995,.20),Vector2(.985,.53),Vector2(.90,.66),Vector2(.835,.55)])
func service_zone(uv: Vector2) -> bool:
 if uv.x<.44 or uv.x>1.0 or uv.y<.025 or uv.y>.83:return false
 return Geometry2D.is_point_in_polygon(uv,service_body) or Geometry2D.is_point_in_polygon(uv,service_tail)

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

func module_angle(type: String,tail: bool) -> float:
 var angle: float=-12.0
 if type.ends_with("ruffle"):angle=-48.0
 elif type.ends_with("fold"):angle=78.0
 return deg_to_rad(angle+(-66.0 if tail else 0.0))

func build_fur_objects() -> void:
 var rng:=RandomNumberGenerator.new();rng.seed=6101602+int(cat_scale*100)+order_index
 var variants: Array=["ruffle","wide","fold","cross"]
 for row in range(ceili(body_rect.size.y/PATCH_STEP.y)):
  for column in range(ceili(body_rect.size.x/PATCH_STEP.x)):
   var local:=Vector2((column+.5)*PATCH_STEP.x+(32 if row%2 else 0),(row+.5)*PATCH_STEP.y)+Vector2(rng.randf_range(-8,8),rng.randf_range(-5,5))
   var uv: Vector2=local/body_rect.size
   if not service_zone(uv) or not body_hit(uv):continue
   var tail: bool=uv.x>=.835
   var coat: String=coat_at(uv)
   if coat_at(uv-Vector2(.022,0))!=coat_at(uv+Vector2(.022,0)):coat="mixed"
   var first: int=rng.randi_range(0,3)
   for attempt in range(4):
    var type: String=coat+"_"+variants[(first+attempt)%4]
    var angle: float=module_angle(type,tail)+deg_to_rad(rng.randf_range(-PATCH_ANGLE_LIMIT,PATCH_ANGLE_LIMIT))
    if not patch_fits(type,uv,angle):continue
    add_full_object(type,"patch",uv,PATCH_SIZE,angle);break
 # Overlapping full-size locks cover the clean outline, never skinny cropped strips.
 for i in range(7):
  var x: float=.51+i*.048
  var uv: Vector2=boundary_at_x(x,.30,.65,false)
  var type: String=["edge_gray_back","edge_gray_shoulder","edge_gray_flank"][i%3]
  add_outline(type,uv,Vector2(175,88)*maxf(.65,cat_scale),Vector2.UP)
 for i in range(6):
  var x: float=.49+i*.052
  var type: String=["edge_cream_belly","edge_cream_leg","edge_cream_cheek"][i%3]
  add_outline(type,boundary_at_x(x,.66,.865,true),Vector2(170,84)*maxf(.65,cat_scale),Vector2.DOWN)
 for i in range(5):
  var y: float=.15+i*.095
  var type: String=["edge_gray_flank","edge_gray_back","edge_gray_shoulder"][i%3]
  add_outline(type,boundary_at_y(y,.84,.999,true),Vector2(145,80)*maxf(.65,cat_scale),Vector2.RIGHT)
 for i in range(4):
  var y: float=.22+i*.095
  add_outline("edge_gray_back" if i%2==0 else "edge_cream_belly",boundary_at_y(y,.81,.94,false),Vector2(135,76)*maxf(.65,cat_scale),Vector2.LEFT)
 var cap_uv: Vector2=boundary_at_x(.875,.02,.22,false)
 add_outline("edge_cream_tail",cap_uv,Vector2(135,90)*maxf(.65,cat_scale),Vector2.UP)
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

func outline_profile(type: String) -> Dictionary:
 if outline_profiles.has(type):return outline_profiles[type]
 # Source art has an inked outer edge and a soft, uninked inner seam.
 # Profile direction is in the unrotated sprite's coordinates, never the
 # required mouse movement direction. Curled tail art has its ink on the right.
 var outward: Vector2=Vector2.RIGHT if type.ends_with("tail") else Vector2.UP
 if type.ends_with("shoulder"):outward=Vector2(-.30,-1).normalized()
 elif type.ends_with("cheek"):outward=Vector2(-.50,-1).normalized()
 var raw: Image=assets.image(type)
 var ink: Array=[];var peak: float=-INF
 for y in range(64):
  for x in range(64):
   var color: Color=raw.get_pixel(int((x+.5)/64*raw.get_width()),int((y+.5)/64*raw.get_height()))
   if color.a<.65 or maxf(color.r,maxf(color.g,color.b))>.27:continue
   var local:=Vector2((x+.5)/64-.5,(y+.5)/64-.5)
   peak=maxf(peak,local.dot(outward));ink.append(local)
 var anchor:=Vector2.ZERO;var n: int=0
 for local in ink:
  if local.dot(outward)>=peak-.13:anchor+=local;n+=1
 if n>0:anchor/=float(n)
 else:anchor=outward*.35
 var profile: Dictionary={"outward":outward,"anchor":anchor}
 outline_profiles[type]=profile;return profile

func contour_normal(uv: Vector2,fallback: Vector2) -> Vector2:
 var raw: Image=assets.image("calico_clean")
 var normal:=Vector2.ZERO
 # Average a local alpha neighbourhood, avoiding a jagged single-pixel tangent.
 var radius: float=26.0*cat_scale
 for i in range(32):
  var direction:=Vector2.from_angle(TAU*i/32.0)
  var at: Vector2=uv+direction*radius/body_rect.size
  var alpha: float=0.0
  if at.x>=0 and at.x<1 and at.y>=0 and at.y<1:
   alpha=raw.get_pixel(int(at.x*raw.get_width()),int(at.y*raw.get_height())).a
  normal+=direction*(1.0-alpha)
 if normal.length()<.5 or normal.normalized().dot(fallback)<.20:return fallback
 return normal.normalized()

func add_outline(type: String,uv: Vector2,drawn: Vector2,fallback: Vector2) -> void:
 var profile: Dictionary=outline_profile(type)
 var normal: Vector2=contour_normal(uv,fallback)
 var source_out: Vector2=(profile.outward*drawn).normalized()
 var angle: float=normal.angle()-source_out.angle()
 var boundary: Vector2=body_rect.position+body_rect.size*uv
 # Anchor the outer ink at the real boundary, with most of the sprite inside.
 var center: Vector2=boundary+normal*(4.0*cat_scale)-(profile.anchor*drawn).rotated(angle)
 add_full_object(type,"edge",(center-body_rect.position)/body_rect.size,drawn,angle)
 objects[-1].outline_normal=normal
 objects[-1].outline_boundary=boundary
 objects[-1].outline_anchor=profile.anchor
 objects[-1].outline_outward=source_out

func outline_stroke(obj: Dictionary,a: Vector2,b: Vector2) -> int:
 if (b-a).normalized().x<C.COMB_DIRECTION_COS:return 0
 obj.passes=1;clear_object(obj)
 return 1

func begin_gesture(at: Vector2=Vector2(INF,INF)) -> void:
 super.begin_gesture(at)
 if fur_ready and kind=="calico":comb_armed=true

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
 if not paused:comfort.recover(dt,now)
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
 if paused or stage!="cleaning" or dt<=0 or a.distance_to(b)<.05 or comfort.recoil_left>0:return result
 var delta: Vector2=b-a
 var speed: float=measured_speed if measured_speed>=0 else delta.length()/dt
 var forward: bool=delta.x/delta.length()>=C.COMB_DIRECTION_COS
 var area:=Rect2(a,Vector2.ZERO).expand(b).grow(Tool.EDGE_LENGTH*.5)
 var risk: float=0.0
 var risk_exposure: float=0.0;var risk_strength: float=0.0
 for obj in objects:
  if obj.done or obj.rule=="flea" or not area.intersects(obj.rect.grow(maxf(obj.rect.size.x,obj.rect.size.y)*.25)) or not object_contact(obj,a,b):continue
  var strength: float=0.0
  if speed>Comfort.EXTREME_SPEED:strength=1.4
  var local_pull: bool=obj.rect.grow(12).has_point(a) and obj.rect.grow(12).has_point(b)
  if obj.rule=="knot" and local_pull:
   if speed>Comfort.KNOT_STALL_SPEED:strength=maxf(strength,1.1)
   if not forward and speed>Tool.KNOT_SPEED_LIMIT:strength=maxf(strength,1.35)
  if strength>0:
   var exposure: float=dt*contact_fraction(obj,a,b)
   if exposure*strength>risk:
    risk=exposure*strength;risk_exposure=exposure;risk_strength=strength
  if speed>Comfort.EXTREME_SPEED:hint("梳子有阻力 · 放慢或松手，不会立刻扣评");continue
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
  if not forward:
   hint("梳子已激活 · 请从左向右梳 →");continue
  if obj.rule=="knot":
   if speed>Tool.KNOT_SPEED_LIMIT:hint("这里打结了 · 慢顺梳即可，停手可放松");continue
   obj.travel+=Tool.covered_length(a,b,obj.rect.get_center())
   if obj.travel<Tool.EDGE_HALF_WIDTH*1.8:continue
  # Any visibly occupied part brushed by the teeth is actionable. Requiring
  # a transparent rectangle centre made narrow tail patches unreachable.
  clear_object(obj);result.changed+=obj.initial
  result.particle="fall_cream_peel" if obj.type.begins_with("cream") or obj.type=="knot_cream" else "fall_gray_peel"
 if risk>0.0:
  if comfort.strain(risk_exposure,risk_strength,now):result.pain=pain("持续硬拉弄疼了 · 松手缓一下 · 评价 -3",Comfort.PAIN_COST,true)
  elif comfort.load>=Comfort.ALERT:hint("快弄疼了！停一下或改为轻梳")
  elif comfort.load>=Comfort.WARNING:hint("猫开始不舒服 · 慢梳或松手会恢复")
 if result.changed>0:check_clean_finished()
 return result

func contact_fraction(obj: Dictionary,a: Vector2,b: Vector2) -> float:
 var lo: float=1.0;var hi: float=0.0
 for y in range(C.OBJECT_GRID):
  for x in range(C.OBJECT_GRID):
   if obj.left[y*C.OBJECT_GRID+x]<=0:continue
   var span: Vector2=Tool.coverage_interval(a,b,sample_point(obj,x,y))
   if span.y>span.x:lo=minf(lo,span.x);hi=maxf(hi,span.y)
 return maxf(0.0,hi-lo)

func build_edge_cover() -> Image:
 var cover:=Image.create(512,256,false,Image.FORMAT_RGBA8);cover.fill(Color(0,0,0,1))
 # Diagnostic footprint for coverage checks. It never alters the base ink
 # or the lock alpha; actual coverage is ordinary sprite compositing.
 for obj in objects:
  if obj.rule!="edge" or obj.done:continue
  var radius: float=obj.rect.size.length()*.5+18.0
  var center_uv: Vector2=(obj.rect.get_center()-body_rect.position)/body_rect.size
  var low:=Vector2i(maxi(0,int((center_uv.x-radius/body_rect.size.x)*512)),maxi(0,int((center_uv.y-radius/body_rect.size.y)*256)))
  var high:=Vector2i(mini(512,ceili((center_uv.x+radius/body_rect.size.x)*512)),mini(256,ceili((center_uv.y+radius/body_rect.size.y)*256)))
  for y in range(low.y,high.y):
   for x in range(low.x,high.x):
    var point: Vector2=body_rect.position+body_rect.size*Vector2((x+.5)/512,(y+.5)/256)
    var local: Vector2=(point-obj.rect.get_center()).rotated(-obj.draw_angle)
    var edge: float=maxf(absf(local.x)-obj.rect.size.x*.5,absf(local.y)-obj.rect.size.y*.5)
    var amount: float=clampf((18.0-edge)/8.0,0,1)
    if amount>cover.get_pixel(x,y).r:cover.set_pixel(x,y,Color(amount,0,0,1))
 return cover

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
