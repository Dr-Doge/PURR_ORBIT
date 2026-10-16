extends SceneTree
const M=preload("res://scripts/prototype_grooming_fur/model.gd")
const OUT="res://reports/grooming_fur_activation_20261016/"
var checks: int=0
var failures: Array=[]
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func stroke(m: RefCounted,a: Vector2,b: Vector2,speed: float=.18) -> void:
 m.begin_gesture(a)
 m.stroke(a,b,a.distance_to(b)/m.body_rect.size.x/speed)
func find(m: RefCounted,rule: String) -> Dictionary:
 for obj in m.objects:
  if obj.rule==rule and not obj.done:return obj
 return {}
func finish_cat(m: RefCounted) -> void:
 for obj in m.objects:
  if obj.rule=="flea":
   for i in range(3):m.click_at(obj.rect.get_center())
  elif obj.rule=="dust":
   var p: Vector2=obj.rect.get_center()
   stroke(m,p-Vector2(0,80),p+Vector2(0,80));stroke(m,p+Vector2(0,80),p-Vector2(0,80))
 for cycle in range(4):
  for y in range(int(m.body_rect.position.y),int(m.body_rect.end.y)+20,24):
   stroke(m,Vector2(m.body_rect.position.x-60,y),Vector2(m.body_rect.end.x+60,y))
   stroke(m,Vector2(m.body_rect.end.x+60,y),Vector2(m.body_rect.position.x-60,y))
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var m=M.new();m.tick(1)
 check(m.assets.image("calico_clean").get_width()>1400,"new grey-white base is used")
 check(m.objects.size()>=35,"modular fur and special objects are present")
 var counts: Dictionary={}
 for obj in m.objects:counts[obj.rule]=counts.get(obj.rule,0)+1
 check(counts.get("patch",0)>=30,"body contains repeated modular fur patches")
 check(counts.get("edge",0)>=4,"complete outline hairlocks exist")
 check(counts.get("knot",0)==2 and counts.get("dust",0)==2 and counts.get("flea",0)==1,"three distinct special demands")
 var o: Dictionary=find(m,"patch");var p: Vector2=o.rect.get_center();var original: float=o.sum
 stroke(m,p+Vector2(60,0),p-Vector2(60,0))
 check(o.sum==original and not o.done,"reverse normal brushing cannot clear patch")
 stroke(m,p-Vector2(60,0),p+Vector2(60,0),3.0)
 check(o.sum==original and m.score==100,"short extreme stroke stalls with grace instead of immediate penalty")
 stroke(m,p-Vector2(60,0),p+Vector2(60,0))
 check(o.done and o.sum==0 and o.left.count(0.0)==o.left.size(),"valid brush removes entire patch, not part of it")
 o=find(m,"edge");var before: float=o.sum;p=Vector2.ZERO
 for y in range(32):
  for x in range(32):
   if o.left[y*32+x]>0:
    p=m.sample_point(o,x,y);break
  if p!=Vector2.ZERO:break
 # Contour now shares the body's single rightward-stroke rule.
 stroke(m,p-Vector2(10,0),p+Vector2(10,0))
 check(o.done and o.sum==0,"short correct contour stroke detaches the whole hairlock")
 o=find(m,"knot");p=o.rect.get_center();before=o.sum
 stroke(m,p-Vector2(90,0),p+Vector2(90,0),.4)
 check(o.sum==before,"tangle rejects normal fast pace")
 stroke(m,p-Vector2(90,0),p+Vector2(90,0),.18)
 stroke(m,p-Vector2(90,0),p+Vector2(90,0),.18)
 check(o.done,"slow repeated rightward brushing releases tangle")
 o=find(m,"dust");p=o.rect.get_center()
 stroke(m,p-Vector2(80,0),p+Vector2(80,0))
 check(o.passes==0,"dust rejects horizontal brushing")
 stroke(m,p-Vector2(0,70),p+Vector2(0,70))
 check(o.passes==1 and not o.done,"dust requires alternating sweeps")
 stroke(m,p-Vector2(0,70),p+Vector2(0,70))
 check(o.passes==1,"same-direction restarts cannot fake dust reversal")
 stroke(m,p+Vector2(0,70),p-Vector2(0,70))
 check(o.done,"two alternating sweeps clear dust")
 o=find(m,"flea");p=o.rect.get_center()
 m.click_at(Vector2.ZERO);check(o.passes==0,"missed click does not clear flea")
 m.click_at(p);m.click_at(p);check(not o.done and o.passes==2,"flea persists until third targeted click")
 m.paused=true;m.click_at(p);check(o.passes==2,"paused flea cannot accept clicks");m.paused=false
 m.click_at(p);check(o.done,"third click clears flea")
 finish_cat(m)
 var unfinished: Array=[]
 for obj in m.objects:
  if not obj.done:unfinished.append([obj.id,obj.rule,obj.sum])
 check(m.stage=="reward" and m.wallet==100,"all fur tasks complete and rating scales immediate payout "+str(unfinished))
 var money: int=m.wallet;m.settle();check(m.wallet==money,"same order cannot pay twice")
 m.start_order(1);m.tick(1);o=m.objects[1];p=o.rect.get_center();before=o.sum
 stroke(m,p-Vector2(80,0),p+Vector2(80,0),4)
 check(o.sum<before and o.sum>0 and m.score==100,"robot still allows rapid repeated wiping without pain")
 m.start_order(0,true)
 check(m.assets.image("paw_base").get_width()==952,"new grey paw keeps four-toe framing")
 for n in m.nails:
  var e: Vector2=m.nail_edges(n,m.perfect_height());var y: float=n.root.y-m.perfect_height()
  var r: Dictionary=m.cut_gesture(PackedVector2Array([Vector2(e.x-15,y),Vector2(e.y+15,y)]))
  check(r.result=="perfect","nail remains cuttable under toe "+str(n.id))
 check(m.stage=="reward","nail practice settles once all four toes are finished")
 m.start_order(0);m.tick(1);m.paused=true;var time: float=m.now;m.tick(2)
 check(m.now==time,"pause freezes service and flea movement")
 check(m.wallet>0 and not m.settled,"new order preserves wallet but resets settlement")
 DirAccess.make_dir_recursive_absolute(OUT)
 FileAccess.open(OUT+"model.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"object_counts":counts,"cat_bounds":[m.body_rect.position.x,m.body_rect.position.y,m.body_rect.size.x,m.body_rect.size.y]}," "))
 print("FUR DEMO MODEL: ",checks," checks; ",failures.size()," failures")
 quit(0 if failures.is_empty() else 1)
