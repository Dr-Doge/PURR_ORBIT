extends "res://scripts/prototype_grooming/model.gd"
const R=preload("res://scripts/prototype_grooming_robot/config.gd")
const RobotAssets=preload("res://scripts/prototype_grooming_robot/assets.gd")
const Generator=preload("res://scripts/prototype_grooming_robot/generator.gd")
var ready_for_orders: bool=false
var seed_stream=RandomNumberGenerator.new()
var order_seed: int=0
var next_seed: int=-1
var generator=Generator.new()
var generation: Dictionary={}
func _init() -> void:
 # Base constructs claws and calls virtual start_order. Guard that call so no
 # fixed-layout order is ever generated or exposed in this independent model.
 super()
 assets=RobotAssets.new();seed_stream.randomize();ready_for_orders=true
 next_seed=R.DEFAULT_DEMO_SEED;start_order(1)
func new_random_order() -> void:
 next_seed=-1;start_order(1)
func reproduce(seed_value: int) -> void:
 next_seed=seed_value;start_order(1)
func start_order(_index: int,_nail_practice: bool=false) -> void:
 if not ready_for_orders:return
 var previous_seed: int=order_seed
 order_seed=next_seed if next_seed>=0 else seed_stream.randi_range(0,2147483647)
 if next_seed<0 and order_seed==previous_seed:order_seed=(order_seed+1)%2147483648
 next_seed=-1
 serial+=1;version+=1;gesture+=1;order_index=1;kind="robot"
 title="机器猫 · 随机污垢";base_pay=R.BASE_PAY;needs_nails=false
 score=100;settled=false;last_payment=0;last_pain=-100;reaction=0
 stage="arrival";stage_left=C.ARRIVAL_TIME;objects=[];nails=[]
 body_rect=assets.body_rect(kind);build_body_mask()
 for object in generator.generate(order_seed,assets,body_rect):create_dirt(object)
 generation=generator.report.duplicate(true)
 # Existing renderer's claw fields remain valid but are not visible here.
 for i in 4:nails.append({"id":i,"root":C.CLAW_ROOTS[i],"height":C.CLAW_HEIGHT,"done":false,"result":"","cuts":0})
 note="按住擦布自由来回擦；大块顽固污垢要多次往返";note_left=4
func build_body_mask() -> void:
 var raw: Image=assets.image("robot_clean").duplicate()
 raw.resize(C.BODY_GRID.x,C.BODY_GRID.y,Image.INTERPOLATE_NEAREST)
 body_mask=Image.create(C.BODY_GRID.x,C.BODY_GRID.y,false,Image.FORMAT_RGBA8)
 body_valid.resize(C.BODY_GRID.x*C.BODY_GRID.y)
 for y in C.BODY_GRID.y:
  for x in C.BODY_GRID.x:
   var valid: bool=raw.get_pixel(x,y).a>.8
   body_valid[y*C.BODY_GRID.x+x]=int(valid);body_mask.set_pixel(x,y,Color(float(valid),0,0,1))
func create_dirt(data: Dictionary) -> void:
 var raw: Image=assets.image(data.type)
 var mask:=Image.create(C.OBJECT_GRID,C.OBJECT_GRID,false,Image.FORMAT_RGBA8);mask.fill(Color.WHITE)
 var left:=PackedFloat32Array();left.resize(C.OBJECT_GRID*C.OBJECT_GRID)
 var count: int=0
 for y in C.OBJECT_GRID:
  for x in C.OBJECT_GRID:
   var valid: bool=raw.get_pixel(int((x+.5)/C.OBJECT_GRID*raw.get_width()),int((y+.5)/C.OBJECT_GRID*raw.get_height())).a>.08
   left[y*C.OBJECT_GRID+x]=float(valid);count+=int(valid)
 if count==0:return
 var obj: Dictionary=data.duplicate(true)
 obj.merge({"id":objects.size(),"rule":"stubborn" if data.stubborn else "wipe","mask":mask,"left":left,"initial":count,"sum":float(count),"version":0,"done":false,"passes":0,"travel":0.0,"dir":0.0,"axis":-1,"last_pass_dir":0.0,"last_vector":Vector2.ZERO,"work_vector":Vector2.ZERO},true)
 objects.append(obj)
func stroke(a: Vector2,b: Vector2,dt: float) -> Dictionary:
 var result: Dictionary={"changed":0,"pain":false,"particle":"oil_fleck","point":b}
 if paused or stage!="cleaning" or dt<=0 or a.distance_to(b)<.05:return result
 var area:=Rect2(a,Vector2.ZERO).expand(b).grow(C.BRUSH_RADIUS)
 for obj in objects:
  if obj.done or not area.intersects(obj.rect) or not object_contact(obj,a,b):continue
  if obj.stubborn:result.changed+=scrub_stubborn(obj,a,b)
  else:result.changed+=erase_segment(obj,a,b,R.NORMAL_RESISTANCE)
 if result.changed>0:check_clean_finished()
 return result
func scrub_stubborn(obj: Dictionary,a: Vector2,b: Vector2) -> int:
 var delta: Vector2=b-a
 var axis: int=0 if absf(delta.x)>=absf(delta.y) else 1
 var direction: Vector2=delta.normalized()
 # Free rubbing: horizontal, vertical and diagonal all work. A meaningful
 # change of direction is needed after a full pass, without locking an axis.
 if obj.last_vector.length_squared()>.1 and obj.last_vector.dot(direction)>.5:return 0
 if obj.work_vector.length_squared()>.1 and obj.work_vector.dot(direction)<.5:obj.travel=0
 obj.work_vector=direction;obj.axis=axis
 var radius: float=obj.rect.size[axis]*.5+C.BRUSH_RADIUS
 var length: float=covered_length(a,b,obj.rect.get_center(),radius)
 var threshold: float=maxf(28,obj.rect.size[axis]*R.PASS_TRAVEL)
 obj.travel+=length
 if obj.travel>=threshold:
  obj.travel=0;obj.passes+=1;obj.last_vector=direction;obj.last_pass_dir=signf(delta[axis])
 if obj.passes>=obj.required_passes:
  clear_object(obj);hint("顽固污垢擦干净了！");return obj.initial
 var remaining: float=1.0-(obj.passes+minf(.99,obj.travel/threshold))/obj.required_passes
 # Progress is monotone even when an incomplete stroke is abandoned.
 for y in C.OBJECT_GRID:
  for x in C.OBJECT_GRID:
   var i: int=y*C.OBJECT_GRID+x
   if obj.left[i]>0:obj.left[i]=minf(obj.left[i],remaining);obj.mask.set_pixel(x,y,Color(obj.left[i],0,0,1))
 obj.sum=0
 for value in obj.left:obj.sum+=value
 obj.version+=1
 hint("顽固污垢 %d/%d · 换向继续擦"%[obj.passes,obj.required_passes])
 return 1
