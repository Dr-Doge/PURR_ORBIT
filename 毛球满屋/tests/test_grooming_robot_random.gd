extends SceneTree
const M=preload("res://scripts/prototype_grooming_robot/model.gd")
const R=preload("res://scripts/prototype_grooming_robot/config.gd")
const OUT="res://reports/grooming_robot_coverage_20261016/"
var checks: int=0
var failures: Array=[]
var samples: Array=[]
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func snapshot(m) -> Array:
 return m.objects.map(func(o):return [o.id,o.type,o.rect.position.x,o.rect.position.y,o.rect.size.x,o.rect.size.y,o.opacity,o.required_passes])
func ready_model(seed_value: int=6101604):
 var m=M.new();m.reproduce(seed_value);m.tick(.5);return m
func sweep(m,obj,reverse: bool=false) -> void:
 var a: Vector2=obj.rect.get_center()-Vector2(obj.rect.size.x*.5+55,0)
 var b: Vector2=obj.rect.get_center()+Vector2(obj.rect.size.x*.5+55,0)
 m.begin_gesture(a);m.stroke(b if reverse else a,a if reverse else b,.02)
func finish(m) -> void:
 for repeat in 14:
  for obj in m.objects:
   if obj.done:continue
   if obj.stubborn:sweep(m,obj,repeat%2==1)
   else:
    for y in range(int(obj.rect.position.y)-8,int(obj.rect.end.y)+25,25):
     var a:=Vector2(obj.rect.position.x-55,y);var b:=Vector2(obj.rect.end.x+55,y)
     m.stroke(a,b,.02);m.stroke(b,a,.02)
  if m.stage=="reward":break
func _initialize() -> void:call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 var m=M.new()
 check(m.kind=="robot" and m.serial==1,"Constructor generates exactly one random robot order")
 check(m.order_seed==R.DEFAULT_DEMO_SEED,"Initial deterministic demonstration seed")
 var shapes: Dictionary={};var counts: Dictionary={};var types: Dictionary={}
 for seed_value in range(6101600,6101680):
  m.reproduce(seed_value)
  var state: Array=snapshot(m)
  var normal: int=m.generation.actual_normal;var stubborn: int=m.generation.actual_stubborn
  check(normal>=8 and normal<=14 and stubborn>=2 and stubborn<=3,"Actual usable count range seed %d: %d+%d"%[seed_value,normal,stubborn])
  check(m.objects.size()==normal+stubborn,"Completion uses effective objects, not failed candidates")
  counts[normal]=true;shapes[JSON.stringify(state)]=true
  check(m.generation.zones.values().all(func(n):return n>0),"Every order covers shoulder, back, belly and hindquarters")
  var valid: bool=true;var visible: bool=true;var source: Image=m.assets.image("robot_clean")
  var enlarged: bool=true
  var minimum:=Vector2(INF,INF);var maximum:=Vector2(-INF,-INF)
  var visible_min:=Vector2(INF,INF);var visible_max:=Vector2(-INF,-INF)
  for obj in m.objects:
   types[obj.type]=true
   if obj.stubborn:valid=valid and obj.opacity==1 and obj.required_passes>=4
   else:valid=valid and obj.opacity>=.45 and obj.opacity<=.70
   var center_uv: Vector2=(obj.rect.get_center()-m.body_rect.position)/m.body_rect.size
   minimum=minimum.min(center_uv);maximum=maximum.max(center_uv)
   var old_max_width: float=m.body_rect.size.x*.45*(.24 if obj.stubborn else .18)
   enlarged=enlarged and obj.rect.size.x>old_max_width*1.25
   # Match the full visible footprint, including the source fringe.
   for point in m.generator.shape_points(obj.type,m.assets):
    var uv: Vector2=(obj.rect.position+obj.rect.size*point-m.body_rect.position)/m.body_rect.size
    valid=valid and m.generator.inside(uv,source)
    visible_min=visible_min.min(uv);visible_max=visible_max.max(uv)
   for other in m.objects:
    if other.id==obj.id:continue
    if other.rect.encloses(obj.rect):visible=false
  check(valid and visible,"Full visible shape stays inside expanded torso; distinct opacity and no hidden mandatory object")
  check(enlarged,"Every stain is visibly wider than the entire previous size range")
  check(visible_min.x<.39 and visible_max.x>.85 and visible_min.y<.52 and visible_max.y>.74,"Visible stain shapes span shoulder/back/belly/hindquarters seed %d: %s %s"%[seed_value,str(visible_min),str(visible_max)])
  m.reproduce(seed_value);check(snapshot(m)==state,"Seed reproduces count, type, exact position, size, opacity")
  var sample: Dictionary=m.generation.duplicate(true);sample.center_extent=[minimum.x,minimum.y,maximum.x,maximum.y];sample.visible_extent=[visible_min.x,visible_min.y,visible_max.x,visible_max.y];samples.append(sample)
 check(counts.size()==7 and shapes.size()==80 and types.size()==4,"Seeds cover count limits, unique layouts and every source class")
 seed(176)
 var first_global: float=randf();var expected_global: float=randf()
 seed(176);check(randf()==first_global,"Global random baseline reproducible")
 var isolated=M.new();isolated.reproduce(18);isolated.new_random_order()
 check(randf()==expected_global,"Private generation and order RNG never consumes global random state")
 m=ready_model();var original: Array=snapshot(m);var serial: int=m.serial
 var obj: Dictionary=m.objects.filter(func(o):return o.stubborn)[0]
 var p: Vector2=obj.rect.get_center();var before: float=obj.sum
 for i in 20:m.stroke(p,p,1)
 check(obj.sum==before and obj.passes==0,"Stationary contact cannot wipe")
 for i in 60:m.stroke(p-Vector2(3,0),p+Vector2(3,0),.01);m.stroke(p+Vector2(3,0),p-Vector2(3,0),.01)
 check(obj.passes==0 and not obj.done,"Micro-oscillation cannot fake complete stubborn passes")
 m=ready_model();obj=m.objects.filter(func(o):return o.stubborn)[0];before=obj.sum
 sweep(m,obj)
 check(obj.passes==1 and not obj.done and obj.sum<before,"First pass visibly reduces stubborn dirt but cannot finish it")
 var after_pass: float=obj.sum
 for i in 4:sweep(m,obj)
 check(obj.passes==1 and obj.sum==after_pass,"Same-direction restart cannot fake another reciprocation")
 var old_required: int=4 if obj.type=="soot" else 5
 for i in range(1,old_required):sweep(m,obj,i%2==1)
 check(not obj.done,"The old 4/5-pass workload no longer finishes a stubborn stain")
 for i in range(old_required,obj.required_passes):sweep(m,obj,i%2==1)
 check(obj.done,"Required real reciprocations finish stubborn object")
 check(m.score==100 and m.reaction==0,"Fast wiping never enters calico pain model")
 m=ready_model();obj=m.objects.filter(func(o):return not o.stubborn)[0];before=obj.sum
 sweep(m,obj,true)
 check(obj.sum<before,"Fast reverse movement clears ordinary dirt")
 var partial: float=obj.sum;var time_before: float=m.now
 m.paused=true;sweep(m,obj);m.tick(10)
 check(obj.sum==partial and m.now==time_before and snapshot(m)==original,"Pause retains this order and partial clearing")
 m.paused=false;m.tick(.1)
 check(m.serial==serial and obj.sum==partial,"Resume does not regenerate or restore dirt")
 var sparse=ready_model();var dense=ready_model()
 var s: Dictionary=sparse.objects.filter(func(o):return o.stubborn)[0]
 var d: Dictionary=dense.objects.filter(func(o):return o.stubborn)[0]
 var a: Vector2=s.rect.get_center()-Vector2(200,0);var b: Vector2=s.rect.get_center()+Vector2(200,0)
 sparse.stroke(a,b,.1)
 for i in 24:dense.stroke(a.lerp(b,i/24.0),a.lerp(b,(i+1)/24.0),.1/24)
 check(s.passes==d.passes and absf(s.sum-d.sum)<.1,"Event density does not multiply stubborn full-pass progress")
 m=ready_model();obj=m.objects.filter(func(o):return o.stubborn)[0];p=obj.rect.get_center()
 for i in obj.required_passes:
  var direction: Vector2=[Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP][i%4]
  m.stroke(p-direction*200,p+direction*200,.02)
 check(obj.done,"Free multi-axis wiping does not lock player into a hidden horizontal/vertical axis")
 # Equal footprint and one logical occupied sample isolates resistance from art.
 var ordinary=ready_model();var durable=ready_model()
 var n: Dictionary=ordinary.objects.filter(func(o):return not o.stubborn)[0]
 var hard: Dictionary=durable.objects.filter(func(o):return o.stubborn)[0]
 for pair in [[ordinary,n],[durable,hard]]:
  pair[0].objects=[pair[1]];pair[1].rect=Rect2(900,600,100,100)
  pair[1].left.fill(0);pair[1].left[16*32+16]=1;pair[1].initial=1;pair[1].sum=1
 for i in 2:sweep(ordinary,n,i%2==1);sweep(durable,hard,i%2==1)
 check(n.done and not hard.done,"Identical area and two identical wipes finish normal dirt before stubborn dirt")
 var completed_orders: Array=[]
 for seed_value in [6101604,6101605,6101610,6101620,6101640,6101679]:
  m=ready_model(seed_value);finish(m)
  check(m.stage=="reward" and m.wallet==120 and m.served==1,"All objects finish with one normal payout seed "+str(seed_value))
  var paid: int=m.wallet;m.settle();m.check_clean_finished();m.tick(.1)
  check(m.wallet==paid and m.served==1,"Repeated completion cannot pay twice")
  var old_layout: Array=snapshot(m);var old_seed: int=m.order_seed
  m.tick(2);m.tick(1)
  check(m.kind=="robot" and m.order_seed!=old_seed and snapshot(m)!=old_layout and m.wallet==paid,"Automatic next customer is a fresh random robot; wallet preserved")
  check(m.order_seed>=0 and m.order_seed<=2147483647,"Every generated seed can be re-entered in debug UI")
  completed_orders.append(seed_value)
 m=ready_model();var generator=m.generator;generator.polygon=PackedVector2Array([Vector2(.01,.01),Vector2(.02,.01),Vector2(.02,.02)])
 generator.generate(42,m.assets,m.body_rect)
 check(generator.report.dropped>0,"Invalid tiny service zone terminates bounded attempts and records failed candidates")
 FileAccess.open(OUT+"model.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"seed_samples":samples,"completed_seeds":completed_orders,"default_seed":R.DEFAULT_DEMO_SEED},"  "))
 print("ROBOT RANDOM MODEL: %d checks; %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
