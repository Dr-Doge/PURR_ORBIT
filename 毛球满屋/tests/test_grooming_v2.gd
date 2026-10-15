extends SceneTree
const M=preload("res://scripts/prototype_grooming/model.gd")
const C=preload("res://scripts/prototype_grooming/config.gd")
const OUT="res://reports/grooming_v2_20261015/"
var checks: int=0
var failures: Array=[]
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func stroke(m: RefCounted,a: Vector2,b: Vector2,speed: float=0.18) -> void:
 m.stroke(a,b,a.distance_to(b)/m.body_rect.size.x/speed)
func row(m: RefCounted,y: float,speed: float=0.18) -> void:
 var a:=Vector2(m.body_rect.position.x+m.body_rect.size.x*0.20,y)
 var b:=Vector2(m.body_rect.end.x+45,y)
 m.begin_gesture(a);stroke(m,a,b,speed)
func complete(m: RefCounted) -> void:
 m.tick(1)
 for round_index in range(8):
  if m.stage!="cleaning":break
  for y in range(int(m.body_rect.position.y),int(m.body_rect.end.y)+30,28):
   if m.stage!="cleaning":break
   row(m,y,0.18 if m.kind=="calico" else 3.0)
  for obj in m.objects:
   if obj.done:continue
   var p: Vector2=obj.rect.get_center()
   if obj.rule=="lift":
    m.begin_gesture(p+Vector2(0,80));stroke(m,p+Vector2(0,80),p-Vector2(0,80))
   elif obj.rule in ["vertical","horizontal"]:
    var d:=Vector2(0,80) if obj.rule=="vertical" else Vector2(90,0)
    for i in range(4):
     stroke(m,p-d,p+d,3.0);stroke(m,p+d,p-d,3.0)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var m=M.new();m.tick(1)
 var obj: Dictionary=m.objects[1];var p: Vector2=obj.rect.get_center();var before: float=obj.sum
 m.begin_gesture(p+Vector2(50,0));stroke(m,p+Vector2(50,0),p-Vector2(50,0))
 check(obj.sum==before,"calico reverse strokes do not clean")
 m.begin_gesture(p);stroke(m,p,p+Vector2(50,0))
 check(obj.sum==before,"calico cannot start grooming in middle of body")
 var start:=Vector2(m.body_rect.position.x+m.body_rect.size.x*0.2,p.y)
 m.begin_gesture(start);stroke(m,start,p+Vector2(80,0))
 check(obj.sum<before,"head-to-tail gentle stroke cleans")
 var uncleared: int=0;var touched: int=0
 for y in range(C.OBJECT_GRID):
  for x in range(C.OBJECT_GRID):
   var at: Vector2=obj.rect.position+obj.rect.size*Vector2((x+0.5)/C.OBJECT_GRID,(y+0.5)/C.OBJECT_GRID)
   if M.covered_length(start,p+Vector2(80,0),at,C.BRUSH_RADIUS)>0:
    touched+=1
    if obj.left[y*C.OBJECT_GRID+x]>0:uncleared+=1
 check(touched>0 and uncleared==0,"one valid pass removes all covered calico dirt")
 var knot: Dictionary=m.objects[12];p=knot.rect.get_center();before=knot.sum
 row(m,p.y,0.4);check(knot.sum==before,"knot requires slower grooming than normal fur")
 row(m,p.y,0.18);check(knot.sum<before,"slow forward stroke loosens knot")
 var trash: Dictionary=m.objects[13];p=trash.rect.get_center();before=trash.sum
 row(m,p.y);check(trash.sum==before,"horizontal grooming cannot remove loose trash")
 m.begin_gesture(p+Vector2(0,80));stroke(m,p+Vector2(0,80),p-Vector2(0,80))
 check(trash.done,"gentle upward lift removes trash")
 obj=m.objects[8];before=obj.sum;p=obj.rect.get_center();var score: int=m.score
 row(m,p.y,2.0)
 check(m.score==score-5 and obj.sum==before,"fast calico brushing hurts without clearing")
 complete(m);check(m.stage=="reward" and m.wallet==96,"calico order remains completable and rating scales pay")
 var robot=M.new();robot.start_order(1);robot.tick(1)
 obj=robot.objects[1];p=obj.rect.get_center();before=obj.sum
 robot.begin_gesture(p-Vector2(80,0));stroke(robot,p-Vector2(80,0),p+Vector2(80,0),4.0)
 check(obj.sum<before and obj.sum>0,"fast robot wipe partially removes oil")
 var first: float=obj.sum
 stroke(robot,p+Vector2(80,0),p-Vector2(80,0),4.0)
 check(obj.sum<first and robot.score==100,"reverse fast robot wipe works without pain")
 var soot: Dictionary=robot.objects[12];p=soot.rect.get_center()
 stroke(robot,p-Vector2(90,0),p+Vector2(90,0),4.0)
 check(soot.passes==0,"robot soot rejects wrong horizontal direction")
 stroke(robot,p-Vector2(0,80),p+Vector2(0,80),4.0)
 check(soot.passes==1 and not soot.done,"robot soot needs multiple vertical passes")
 stroke(robot,p-Vector2(0,80),p+Vector2(0,80),4.0)
 check(soot.passes==1,"same-direction restarts do not fake a reversal")
 stroke(robot,p+Vector2(0,80),p-Vector2(0,80),4.0);stroke(robot,p-Vector2(0,80),p+Vector2(0,80),4.0)
 check(soot.done,"three alternating vertical passes remove soot")
 var tar: Dictionary=robot.objects[13];p=tar.rect.get_center()
 stroke(robot,p-Vector2(0,90),p+Vector2(0,90),4.0)
 check(tar.passes==0,"robot tar rejects vertical wiping")
 for i in range(2):
  stroke(robot,p-Vector2(90,0),p+Vector2(90,0),4.0);stroke(robot,p+Vector2(90,0),p-Vector2(90,0),4.0)
 check(tar.done,"four horizontal alternating passes remove tar")
 complete(robot);check(robot.stage=="reward" and robot.wallet==120,"robot full order completes without speed penalty")
 m.start_order(0,true)
 check(C.CLAW_ROOTS.size()==4 and C.CLAW_HEIGHT==210,"four resized nail anchors")
 for n in m.nails:
  var edges: Vector2=m.nail_edges(n,m.perfect_height());var yy: float=n.root.y-m.perfect_height()
  var result: Dictionary=m.cut_gesture(PackedVector2Array([Vector2(edges.x-15,yy),Vector2(edges.y+15,yy)]))
  check(result.result=="perfect","new anchor retains aligned cut geometry")
 check(m.stage=="reward","new nail layout does not block settlement")
 DirAccess.make_dir_recursive_absolute(OUT)
 FileAccess.open(OUT+"model.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"quick_height":m.quick_height}," "))
 print("GROOMING V2: ",checks," checks; ",failures.size()," failures")
 quit(0 if failures.is_empty() else 1)
