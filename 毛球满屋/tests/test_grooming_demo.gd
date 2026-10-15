extends SceneTree
const M=preload("res://scripts/prototype_grooming/model.gd")
const C=preload("res://scripts/prototype_grooming/config.gd")
var checks: int=0
var failures: Array=[]

func json_value(value: Variant) -> Variant:
 if value is Vector2 or value is Vector2i:return [value.x,value.y]
 if value is Rect2:return [value.position.x,value.position.y,value.size.x,value.size.y]
 if value is Array:
  var values: Array=[]
  for item in value:values.append(json_value(item))
  return values
 if value is Dictionary:
  var values: Dictionary={}
  for key in value:values[key]=json_value(value[key])
  return values
 return value

func check(ok: bool, text: String) -> void:
 checks+=1
 if not ok: failures.append(text);push_error(text)

func segment(m: RefCounted,a: Vector2,b: Vector2,speed: float=0.2) -> void:
 var dt: float=a.distance_to(b)/m.body_rect.size.x/speed
 m.tick(dt);m.stroke(a,b,maxf(dt,0.001))

func clean_all(m: RefCounted) -> void:
 m.tick(1.0)
 for pass_index in range(8):
  if m.stage!="cleaning":break
  for obj in m.objects:
   if obj.done:continue
   m.begin_gesture()
   var r: Rect2=obj.rect
   for y in range(int(r.position.y)-30,int(r.end.y)+31,30):
    segment(m,Vector2(r.position.x-40,y),Vector2(r.end.x+40,y))
    if m.stage!="cleaning":break
    segment(m,Vector2(r.end.x+40,y),Vector2(r.position.x-40,y))
    if m.stage!="cleaning":break

func nail_line(m: RefCounted,n: Dictionary,h: float) -> PackedVector2Array:
 var edges: Vector2=m.nail_edges(n,h)
 var y: float=n.root.y-h
 return PackedVector2Array([Vector2(edges.x-15,y),Vector2((edges.x+edges.y)/2,y),Vector2(edges.y+15,y)])

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var m=M.new()
 check(m.objects.size()==14,"14 independent dirt objects")
 check(m.wallet==0 and m.stage=="arrival","fresh memory-only order")
 m.tick(1.0)
 var normal: Dictionary=m.objects[0]
 var p: Vector2=normal.rect.get_center()
 var initial: float=normal.sum
 m.stroke(p,p,1.0)
 check(normal.sum==initial,"stationary hold does not clean")
 segment(m,p-Vector2(45,0),p+Vector2(45,0))
 check(normal.sum<initial,"actual travel removes dirt")
 var remaining: float=normal.sum
 m.begin_gesture();m.tick(2.0)
 check(normal.sum==remaining,"release preserves local mask progress")
 var score: int=m.score
 m.stroke(p-Vector2(100,0),p+Vector2(100,0),0.001)
 check(m.score==score-5,"overspeed on uncleared dirt hurts")
 m.stroke(p-Vector2(100,0),p+Vector2(100,0),0.001)
 check(m.score==score-5,"pain rate limit prevents event-rate penalties")
 m.tick(1.0)
 m.stroke(Vector2(50,130),Vector2(300,130),0.001)
 check(m.score==score-5,"outside body cannot cause pain")
 var knot: Dictionary=m.objects[12]
 initial=knot.sum;p=knot.rect.get_center()
 segment(m,p-Vector2(70,0),p+Vector2(70,0),0.6)
 check(is_equal_approx(knot.sum,initial),"slow knot rejects medium speed")
 segment(m,p-Vector2(70,0),p+Vector2(70,0),0.2)
 check(knot.sum<initial,"slow knot accepts gentle motion")
 var sticky: Dictionary=m.objects[13]
 p=sticky.rect.get_center();m.begin_gesture()
 for i in range(10):segment(m,p,p+Vector2(2,0));segment(m,p+Vector2(2,0),p)
 check(sticky.passes==0,"tiny jitter cannot remove sticky trash")
 segment(m,p-Vector2(70,0),p+Vector2(70,0))
 check(sticky.passes==1 and not sticky.done,"first real pass loosens trash")
 segment(m,p+Vector2(70,0),p-Vector2(70,0))
 check(sticky.done,"second opposite pass removes trash")
 check(m.settle()==0,"cannot pay unfinished order")
 clean_all(m)
 check(m.stage=="reward" and m.wallet==C.payment(100,95),"complete first order pays rating-scaled amount")
 var paid: int=m.wallet
 check(m.settle()==0 and m.wallet==paid and m.served==1,"settlement is idempotent")
 m.tick(C.REWARD_TIME+0.1);m.tick(C.DEPARTURE_TIME+0.1);m.tick(1.0)
 check(m.kind=="robot" and m.wallet==paid,"next customer preserves wallet")
 clean_all(m)
 check(m.stage=="reward" and m.wallet==paid+120,"robot wiping completes through real strokes")
 m.tick(2.0);m.tick(1.0);m.tick(1.0)
 check(m.order_index==2 and m.needs_nails,"third order contains grooming and nails")
 clean_all(m);m.tick(1.0)
 check(m.stage=="nails" and not m.settled,"cleaning transitions to nails without premature payment")
 var n: Dictionary=m.nails[0]
 var height: float=m.quick_height+C.NAIL_BAND_WIDTH+35.0
 var result: Dictionary=m.cut_gesture(nail_line(m,n,height))
 check(result.result=="shallow" and not n.done and n.height<C.CLAW_HEIGHT,"shallow cut actually shortens nail and permits recut")
 var after_shallow: float=n.height
 result=m.cut_gesture(nail_line(m,n,height+10.0))
 check(result.result=="miss" and n.height==after_shallow,"cannot cut already removed tip")
 result=m.cut_gesture(nail_line(m,n,m.perfect_height()))
 check(result.result=="perfect" and n.done,"recut in safe band completes nail")
 score=m.score;n=m.nails[1]
 result=m.cut_gesture(nail_line(m,n,m.quick_height-12))
 check(result.result=="deep" and n.done and m.score==score-20,"deep cut hurts but does not lock the order")
 result=m.cut_gesture(PackedVector2Array([Vector2(10,10),Vector2(40,10)]))
 check(result.result=="miss","background swipe cannot trim claws")
 for i in [2,3]:m.cut_gesture(nail_line(m,m.nails[i],m.perfect_height()))
 check(m.stage=="reward" and m.served==3,"all required services settle automatically")
 m.tick(2.0);m.tick(1.0)
 check(m.order_index==0,"customer sequence loops continuously")
 var serial: int=m.serial;m.paused=true;var time: float=m.now;m.tick(20.0)
 check(m.now==time and m.serial==serial,"pause freezes service progression")
 m.paused=false;m.start_order(0,true)
 var old_wallet: int=m.wallet
 check(m.stage=="nails" and m.wallet==old_wallet,"nail practice does not grant free money")
 result=m.cut_gesture(PackedVector2Array([Vector2(20,20)]))
 check(result.result=="miss","single click is not a nail swipe")
 n=m.nails[0];var edges: Vector2=m.nail_edges(n,m.perfect_height());var yy: float=n.root.y-m.perfect_height()
 result=m.cut_gesture(PackedVector2Array([Vector2(edges.x-20,yy-70),Vector2(edges.y+20,yy+70)]))
 check(result.result=="miss" and n.cuts==0,"sparse steep swipe cannot bypass angle tolerance")
 var a: Vector2=Vector2(10,10);var b: Vector2=Vector2(200,10);p=Vector2(100,25)
 var full: float=M.covered_length(a,b,p,48)
 var split: float=M.covered_length(a,Vector2(80,10),p,48)+M.covered_length(Vector2(80,10),b,p,48)
 check(is_equal_approx(full,split),"analytic brush travel is independent of input sampling")
 var high=M.new();var low=M.new();high.tick(1);low.tick(1)
 var rect: Rect2=high.objects[1].rect
 a=rect.get_center()-Vector2(35,0);b=a+Vector2(70,0)
 segment(low,a,b,0.24)
 for i in range(6):segment(high,a.lerp(b,float(i)/6),a.lerp(b,float(i+1)/6),0.24)
 check(absf(high.objects[1].sum-low.objects[1].sum)<0.001,"six sampled segments and one segment give same cleaning amount")
 m.start_order(0)
 var valid_cells: int=0
 var invalid_cells: int=0
 for obj in m.objects:
  for y in range(C.OBJECT_GRID):
   for x in range(C.OBJECT_GRID):
    if obj.left[y*C.OBJECT_GRID+x]<=0:continue
    p=obj.rect.position+obj.rect.size*Vector2((x+0.5)/C.OBJECT_GRID,(y+0.5)/C.OBJECT_GRID)
    valid_cells+=1
    if not m.body_hit((p-m.body_rect.position)/m.body_rect.size):invalid_cells+=1
 check(valid_cells>0 and invalid_cells==0,"all active dirt cells stay inside body")
 DirAccess.make_dir_recursive_absolute("res://reports/prototype_grooming_20261014")
 var output=FileAccess.open("res://reports/prototype_grooming_20261014/model_results.json",FileAccess.WRITE)
 output.store_string(JSON.stringify({"checks":checks,"failures":failures,"quick_height":m.quick_height,"safe_band":[m.quick_height,m.quick_height+C.NAIL_BAND_WIDTH]}," "))
 var configuration: GDScript=load("res://scripts/prototype_grooming/config.gd")
 FileAccess.open("res://reports/prototype_grooming_20261014/config.json",FileAccess.WRITE).store_string(JSON.stringify({"status":"prototype trial values, not final tuning","source":"res://scripts/prototype_grooming/config.gd","parameters":json_value(configuration.get_script_constant_map()),"measured_quick_height":m.quick_height,"payment_formula":"round(base*(0.25+0.75*score/100))","save":"memory only"}," "))
 print("GROOMING MODEL: ",checks," checks, ",failures.size()," failures; quick height=",m.quick_height)
 quit(0 if failures.is_empty() else 1)
