extends RefCounted
const C = preload("res://scripts/prototype_harvest/config.gd")
var rng = RandomNumberGenerator.new()
var cats: Array = []
var workers: Array = []
var research: Dictionary = {}
var wallet: int = 0
var lifetime: int = 0
var earned: int = 0
var spent: int = 0
var initial_wallet: int = 0
var time: float = 0.0
var next_hair: int = 1
var next_event: int = 1
var stage: int = 0
var continuous: bool = true
var paused: bool = false
var buff_owned: bool = false
var buff_target: int = -1
var decor: bool = false
var event_clock: Dictionary = {"knot":0.0,"flea":0.0}
var enabled: Dictionary = {"knot":false,"flea":false}
var milestones: Dictionary = {}
var feedback: Array = []
var message: String = "点击猫身的毛头，开始采集"
var revision: int = 0
func _init() -> void:
 reset(0)
func reset(index: int, fixed_seed: bool = true) -> void:
 stage=clampi(index,0,7);continuous=stage==0;paused=false
 cats.clear();workers.clear();research.clear();milestones.clear();feedback.clear()
 time=0;next_hair=1;next_event=1;lifetime=0;earned=0;spent=0;buff_owned=false;buff_target=-1;decor=false
 event_clock={"knot":0.0,"flea":0.0};enabled={"knot":stage==7,"flea":stage==7}
 if fixed_seed:rng.seed=104901+stage
 else:rng.randomize()
 var preset: Dictionary=C.STAGES[stage]
 for key in preset.research:grant(key)
 wallet=preset.wallet;initial_wallet=wallet
 for i in preset.cats.size():
  var c: Dictionary=add_cat(preset.cats[i])
  for j in preset.counts[i]:spawn(c,"normal")
 for i in preset.workers:
  workers.append({"id":i+1,"cat":cats[0].id if i==0 else -1,"clock":0.0,"pos":Vector2.ZERO,"flash":0.0})
 if stage==2:spawn(cats[0],"king",Vector2.ZERO)
 if stage==5:trigger_knot(cats[0].id)
 if stage==6:trigger_flea(cats[0].id)
 message=preset.intro;revision+=1
func spec(key: String) -> Dictionary:
 for n in C.NODES:
  if n.key==key:return n
 return {}
func level(key: String) -> int:return int(research.get(key,0))
func grant(key: String) -> void:
 var n: Dictionary=spec(key)
 if n.is_empty():return
 if n.prereq!="" and level(n.prereq)==0:grant(n.prereq)
 research[key]=1
func reason(key: String) -> String:
 var n: Dictionary=spec(key)
 if n.is_empty():return "未知研究"
 if level(key)>=n.costs.size():return "已满级"
 if n.prereq!="" and level(n.prereq)==0:return "前置："+spec(n.prereq).name
 if wallet<int(n.costs[level(key)]):return "毛球不足"
 return ""
func buy(key: String) -> bool:
 if paused or reason(key)!="":return false
 var cost: int=spec(key).costs[level(key)]
 wallet-=cost;spent+=cost;research[key]=level(key)+1;revision+=1
 message="已升级："+spec(key).name
 return true
func purchase(kind: String) -> bool:
 if paused:return false
 var cost: int=0
 if kind=="worker":
  if level("worker")==0:return false
  cost=C.WORKER_COST
 elif kind=="buff" or kind=="decor":
  if level("buff")==0 or (buff_owned if kind=="buff" else decor):return false
  cost=C.BUFF_COST if kind=="buff" else C.DECOR_COST
 else:return false
 if wallet<cost:return false
 wallet-=cost;spent+=cost
 if kind=="worker":workers.append({"id":workers.size()+1,"cat":-1,"clock":0.0,"pos":Vector2.ZERO,"flash":0.0})
 elif kind=="buff":buff_owned=true
 else:decor=true
 revision+=1;return true
func assign(worker_id: int, cat_id: int) -> bool:
 if paused or (cat_id!=-1 and cat(cat_id).is_empty()):return false
 for w in workers:
  if w.id==worker_id:
   w.cat=cat_id;w.clock=0.0;w.pos=Vector2.ZERO;revision+=1
   message="小帮手已撤下" if cat_id==-1 else ("警告：该样本排斥自动化，工作会使一根毛缩回" if cat(cat_id).kind=="special" else "小帮手已指派")
   return true
 return false
func set_buff(id: int) -> bool:
 if paused or not buff_owned or (id!=-1 and cat(id).is_empty()):return false
 buff_target=id;revision+=1;return true
func cat(id: int) -> Dictionary:
 for c in cats:
  if c.id==id:return c
 return {}
func add_cat(kind: String) -> Dictionary:
 var c: Dictionary={"id":cats.size()+1,"kind":kind,"name":C.CATS[kind].name,"hairs":{},"pending":0,"growth":0.0,"born":0,"harvested":0,"lost":0,"knot":{},"flea":{},"auto_log":[],"feedback":0.0}
 cats.append(c);revision+=1;return c
func random_position() -> Vector2:
 var a: float=rng.randf()*TAU
 var r: float=sqrt(rng.randf())
 return Vector2(cos(a),sin(a))*C.BODY_RADIUS*r
func rate(c: Dictionary) -> float:
 return float(C.CATS[c.kind].rate)*pow(1.25,level("grow"))*(C.BUFF_MULTIPLIER if buff_target==c.id else 1.0)
func value(c: Dictionary) -> int:return int(C.CATS[c.kind].value)+level("yield")
func spawn(c: Dictionary, kind: String="", at: Vector2=Vector2(INF,INF)) -> int:
 if kind=="":kind="king" if level("king")>0 and rng.randf()<C.KING_RATES[mini(level("king_rate"),1)] else "normal"
 var v: int=value(c)*(C.KING_MULTIPLIER if kind=="king" else 1)
 var id: int=next_hair;next_hair+=1
 c.hairs[id]={"id":id,"pos":random_position() if not at.is_finite() else at,"kind":kind,"value":v,"hits":0}
 c.pending+=v;c.born+=1;revision+=1
 return id
func locked(c: Dictionary,id: int) -> bool:return not c.knot.is_empty() and c.knot.ids.has(id)
func remove_hair(c: Dictionary,id: int) -> Dictionary:
 if not c.hairs.has(id):return {}
 var h: Dictionary=c.hairs[id];c.hairs.erase(id);c.pending-=h.value;revision+=1
 return h
func pay(c: Dictionary, amount: int, source: String, at: Vector2=Vector2.ZERO) -> void:
 if amount<=0:return
 wallet+=amount;earned+=amount
 if source!="flea":lifetime+=amount;c.harvested+=amount
 if source=="worker":c.auto_log.append({"time":time,"value":amount})
 c.feedback=0.4
 feedback.append({"cat":c.id,"pos":at,"value":amount,"kind":source})
 check_milestones()
func collect(c: Dictionary, ids: Array, source: String) -> int:
 if paused or not c.flea.is_empty():return 0
 var total: int=0;var at:=Vector2.ZERO
 for id in ids:
  if not c.hairs.has(id):continue
  var h: Dictionary=c.hairs[id]
  if locked(c,id) and source!="knot":continue
  if h.kind=="king" and source!="king":continue
  at=h.pos;total+=int(h.value);remove_hair(c,id)
 pay(c,total,source,at)
 return total
func direct(c: Dictionary,id: int, source: String="click") -> int:
 if paused or not c.flea.is_empty() or not c.hairs.has(id) or locked(c,id):return 0
 var h: Dictionary=c.hairs[id]
 if h.kind=="king":
  if source!="click":return 0
  h.hits+=1;revision+=1;feedback.append({"cat":c.id,"pos":h.pos,"value":0,"kind":"king_hit"})
  if h.hits<C.KING_CLICKS:return 0
  return collect(c,[id],"king")
 var ids: Array=[id]
 if level("chain")>0 and source!="worker":
  for other in c.hairs.values():
   if other.id!=id and other.kind=="normal" and other.pos.distance_to(h.pos)<=C.CHAIN_RADIUS:ids.append(other.id)
 return collect(c,ids,source)
func click(id: int,at: Vector2) -> int:
 if paused:return 0
 var c: Dictionary=cat(id)
 if c.is_empty():return 0
 if not c.flea.is_empty():
  if at.distance_to(c.flea.pos)<=C.FLEA_RADIUS:hit_flea(c)
  return 0
 var best: int=-1;var distance: float=C.HIT_RADIUS
 # King heads are larger; ordinary heads still remain individually collectible.
 for h in c.hairs.values():
  var d: float=h.pos.distance_to(at)
  if h.kind=="king" and d<C.HIT_RADIUS*1.8:return direct(c,h.id)
  if d<=distance and not locked(c,h.id):distance=d;best=h.id
 return direct(c,best) if best>=0 else 0
func move(id: int, start: Vector2, finish: Vector2, held: bool) -> int:
 if paused or start.distance_to(finish)<0.00001:return 0
 var c: Dictionary=cat(id)
 if c.is_empty() or not c.flea.is_empty():return 0
 var total: int=0
 if held and not c.knot.is_empty():
  var k: Dictionary=c.knot
  if start.distance_to(k.pos)<=C.KNOT_RADIUS*1.5 and finish.distance_to(k.pos)<=C.KNOT_RADIUS*1.5:
   var direction: Vector2=(finish-start).normalized()
   if k.direction!=Vector2.ZERO and direction.dot(k.direction)<-0.25:k.reversals+=1
   k.direction=direction;k.distance+=start.distance_to(finish);revision+=1
   if k.distance>=C.KNOT_DISTANCE and k.reversals>=C.KNOT_REVERSALS:
    var ids: Array=k.ids.keys();c.knot={};total+=collect(c,ids,"knot")
 if level("touch")>0:
  var hits: Array=[]
  for h in c.hairs.values():
   if h.kind=="normal" and Geometry2D.get_closest_point_to_segment(h.pos,start,finish).distance_to(h.pos)<=C.HIT_RADIUS:hits.append(h.id)
  for hit in hits:total+=direct(c,hit,"touch")
 return total
func trigger_knot(id: int) -> bool:
 for other in cats:
  if not other.knot.is_empty():return false
 var c: Dictionary=cat(id)
 if c.is_empty():return false
 var center: Vector2=Vector2(INF,INF)
 for h in c.hairs.values():
  if h.kind=="normal":center=h.pos;break
 if not center.is_finite():return false
 var ids: Dictionary={}
 for h in c.hairs.values():
  if h.kind=="normal" and h.pos.distance_to(center)<=C.KNOT_RADIUS:ids[h.id]=true
 c.knot={"id":next_event,"pos":center,"ids":ids,"distance":0.0,"reversals":0,"direction":Vector2.ZERO};next_event+=1;revision+=1
 return true
func trigger_flea(id: int) -> bool:
 for other in cats:
  if not other.flea.is_empty():return false
 var c: Dictionary=cat(id)
 if c.is_empty():return false
 var has_normal: bool=false
 for h in c.hairs.values():
  if h.kind=="normal":has_normal=true;break
 if not has_normal:return false
 c.flea={"id":next_event,"left":C.FLEA_TIME,"hits":0,"bag":0,"stolen":0,"clock":0.0,"hold":C.FLEA_HOLD,"pos":Vector2.ZERO,"dest":random_position()};next_event+=1;revision+=1
 message="偷毛贼！这只猫暂时禁止全部收割；长毛继续。"
 return true
func hit_flea(c: Dictionary) -> bool:
 if paused or c.flea.is_empty():return false
 if c.flea.left<=0.000001:finish_flea(c,false);return false
 c.flea.hits+=1;c.flea.hold=C.FLEA_HOLD;revision+=1
 if c.flea.hits>=C.FLEA_CLICKS:finish_flea(c,true)
 return true
func finish_flea(c: Dictionary, success: bool) -> void:
 if c.flea.is_empty():return
 var f: Dictionary=c.flea;c.flea={};revision+=1
 if success and f.left>0:
  var reward: int=int(f.bag)+int(ceil(f.left))
  pay(c,reward,"flea",f.pos);message="赶走偷毛贼！追回 %d，及时奖励 %d" % [f.bag,int(ceil(f.left))]
 else:message="偷毛贼逃跑，带走 %d 待摘价值；库存不受影响" % f.bag
func tick_flea(c: Dictionary, dt: float) -> void:
 var f: Dictionary=c.flea
 if f.is_empty():return
 # Stop at the timeout boundary; even a large frame cannot steal after expiry.
 var active_dt: float=minf(dt,f.left)
 f.left-=dt
 f.clock+=active_dt
 while f.clock>=C.FLEA_STEAL_INTERVAL:
  f.clock-=C.FLEA_STEAL_INTERVAL
  var stolen: int=0
  for id in c.hairs.keys():
   if c.hairs[id].kind=="king":continue
   var h: Dictionary=remove_hair(c,id)
   f.bag+=h.value;f.stolen+=1;stolen+=1
   if stolen>=C.FLEA_STEAL_COUNT:break
  f.hold=C.FLEA_HOLD
 if f.left<=0.000001:f.left=0.0;finish_flea(c,false);return
 if f.hold>0:f.hold=maxf(0.0,f.hold-dt)
 else:
  f.pos=f.pos.move_toward(f.dest,C.FLEA_SPEED*dt)
  if f.pos.distance_to(f.dest)<0.01:f.dest=random_position()
func auto_rate(c: Dictionary) -> float:
 var amount: float=0
 for entry in c.auto_log:
  if entry.time>time-C.RATE_WINDOW:amount+=entry.value
 return amount/maxf(0.001,minf(time,C.RATE_WINDOW))
func worker_tick(w: Dictionary,dt: float) -> void:
 w.flash=maxf(0.0,w.flash-dt)
 var c: Dictionary=cat(w.cat)
 if c.is_empty() or not c.flea.is_empty():return
 w.clock+=dt*pow(1.25,level("worker_rate"))
 while w.clock>=1.0:
  w.clock-=1.0
  var target: int=-1
  for h in c.hairs.values():
   if h.kind=="normal" and not locked(c,h.id):target=h.id;break
  if target<0:continue
  w.pos=c.hairs[target].pos;w.flash=0.4
  if c.kind=="special":
   var h: Dictionary=remove_hair(c,target);c.lost+=h.value;c.feedback=0.4
   feedback.append({"cat":c.id,"pos":h.pos,"value":-int(h.value),"kind":"shrink"})
   message="刺刺排斥小帮手：一根待摘毛缩回！请撤下工作者。"
  else:collect(c,[target],"worker")
func check_milestones() -> void:
 if not continuous:return
 for key in C.MILESTONES:
  if lifetime<C.MILESTONES[key] or milestones.has(key):continue
  milestones[key]=true
  if key=="fast" or key=="special":
   add_cat(key);message="新访客抵达："+C.CATS[key].name
  else:enabled[key]=true;event_clock[key]=0;message="新事件开放："+("毛发打结" if key=="knot" else "偷毛贼")
func tick(dt: float) -> void:
 if paused or dt<=0:return
 time+=dt
 var blocked_workers: Dictionary={}
 for c in cats:
  if not c.flea.is_empty():blocked_workers[c.id]=true
  c.feedback=maxf(0.0,c.feedback-dt)
  c.growth+=dt*rate(c)
  var count: int=int(floor(c.growth+0.000001));c.growth-=count
  for i in count:spawn(c)
  tick_flea(c,dt)
  while not c.auto_log.is_empty() and c.auto_log[0].time<=time-C.RATE_WINDOW:c.auto_log.pop_front()
 for w in workers:
  # An expiry frame must not credit work for time spent under the event lock.
  if not blocked_workers.has(w.cat):worker_tick(w,dt)
 for key in event_clock:
  if not enabled[key]:continue
  event_clock[key]+=dt
  if event_clock[key]>=C.EVENT_INTERVALS[key]:
   event_clock[key]=0.0
   for c in cats:
    if trigger_knot(c.id) if key=="knot" else trigger_flea(c.id):break
 # Visual messages are disposable, never the resource ledger.
 if feedback.size()>200:feedback=feedback.slice(feedback.size()-200)
