extends SceneTree
const M=preload("res://scripts/prototype_harvest/model.gd")
const C=preload("res://scripts/prototype_harvest/config.gd")
var checks: int=0
var failures: Array=[]
var performance: Array=[]
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures.append(why);push_error(why)
func fresh(index: int=0):
 var m=M.new();m.reset(index);return m
func accounting(m) -> void:
 check(m.wallet==m.initial_wallet+m.earned-m.spent,"Wallet ledger")
 for c in m.cats:
  var total: int=0;var ids: Dictionary={}
  for h in c.hairs.values():
   total+=h.value;check(not ids.has(h.id),"Unique hair identity");ids[h.id]=true
  check(total==c.pending and total>=0,"Pending value matches actual hairs")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var m=fresh();var c: Dictionary=m.cats[0]
 check(m.wallet==0 and c.hairs.size()==20 and m.cats.size()==1,"S01 starts small")
 var before: int=c.hairs.size();m.tick(20.4)
 check(c.hairs.size()==before+20 and is_equal_approx(c.growth,0.4),"Large dt does not drop growth")
 var positions: Dictionary={}
 for h in c.hairs.values():
  check((h.pos/C.BODY_RADIUS).length()<=1.0001,"Random positions on body")
  positions[h.pos]=true
 check(positions.size()>35,"Positions continuous and varied")
 var id: int=c.hairs.keys()[0];var v: int=c.hairs[id].value
 m.tick(10);check(c.hairs[id].value==v,"No maturity appreciation")
 check(m.direct(c,id)==v and m.direct(c,id)==0,"One ID pays once")
 m.paused=true;var clock: float=m.time;var count: int=c.hairs.size()
 m.tick(50);check(m.time==clock and c.hairs.size()==count,"Pause freezes all simulation")
 check(m.direct(c,c.hairs.keys()[0])==0 and not m.buy("yield"),"Pause rejects interaction")
 m.paused=false;m.wallet=100;m.initial_wallet=100-m.earned
 var old_id: int=c.hairs.keys()[0];var old_value: int=c.hairs[old_id].value
 check(m.buy("yield") and m.wallet==90,"Yield real cost")
 check(c.hairs[old_id].value==old_value,"Yield does not revalue old hairs")
 var new_id: int=m.spawn(c,"normal");check(c.hairs[new_id].value==2,"Yield affects new hairs")
 check(not m.buy("chain"),"Prerequisites enforced")
 check(m.buy("grow") and is_equal_approx(m.rate(c),1.25),"Growth actual rate")
 check(m.buy("touch"),"Touch purchasable")
 c.hairs.clear();c.pending=0
 var a: int=m.spawn(c,"normal",Vector2(-0.1,0));var b: int=m.spawn(c,"normal",Vector2(0.1,0))
 m.move(c.id,Vector2(-0.2,0),Vector2(0.2,0),false)
 check(not c.hairs.has(a) and not c.hairs.has(b),"Fast motion captures path targets")
 var stationary: int=m.spawn(c,"normal",Vector2.ZERO)
 m.move(c.id,Vector2.ZERO,Vector2.ZERO,false);check(c.hairs.has(stationary),"Stationary hover cannot collect newborn")
 m=fresh(1);c=m.cats[0]
 check(m.wallet==45 and m.level("touch")==0 and m.level("chain")==0,"S02 leaves two tool purchases")
 check(m.buy("touch") and m.buy("chain") and m.wallet==0,"Exact tool budget")
 c.hairs.clear();c.pending=0
 a=m.spawn(c,"normal",Vector2.ZERO);b=m.spawn(c,"normal",Vector2(0.07,0))
 var far_id: int=m.spawn(c,"normal",Vector2(0.14,0));var king: int=m.spawn(c,"king",Vector2(0.02,0))
 m.direct(c,a)
 check(not c.hairs.has(b) and c.hairs.has(far_id) and c.hairs.has(king),"Chain single hop, no king")
 check(m.direct(c,king,"touch")==0 and c.hairs[king].hits==0,"Touch cannot advance king")
 for i in C.KING_CLICKS-1:check(m.direct(c,king)==0,"King requires full click count")
 var king_value: int=c.hairs[king].value
 check(m.direct(c,king)==king_value and m.direct(c,king)==0,"King pays once")
 m=fresh(2);check(m.level("king")==1 and m.level("king_rate")==0,"S03 king upgrade available")
 check(m.buy("king_rate") and m.wallet==0,"King probability upgrade real purchase")
 m=fresh(3);c=m.cats[0];var fast: Dictionary=m.cats[1]
 check(is_equal_approx(m.rate(fast),m.rate(c)*2),"Fast sample has independent rate")
 var base_rate: float=m.rate(c)
 check(m.purchase("buff") and m.purchase("decor") and m.wallet==0,"S04 budgets cover both facilities")
 check(m.set_buff(c.id) and is_equal_approx(m.rate(c),base_rate*1.5),"Buff changes production")
 m.set_buff(c.id);check(is_equal_approx(m.rate(c),base_rate*1.5),"Repeated assignment not stack")
 m.set_buff(fast.id);check(is_equal_approx(m.rate(c),base_rate),"Reassignment releases previous buff")
 m.set_buff(-1);check(is_equal_approx(m.rate(fast),base_rate*2),"Decoration has no effect; buff can stop")
 m=fresh(4);c=m.cats[0]
 check(m.workers.is_empty() and m.purchase("worker") and m.buy("worker_rate") and m.wallet==0,"S05 recruits and upgrades normally")
 check(m.assign(1,c.id),"Worker assign")
 var wallet: int=m.wallet;m.tick(0.8)
 check(m.wallet>wallet and m.auto_rate(c)>0,"Worker consumes actual hair and earns at improved frequency")
 m.assign(1,-1);wallet=m.wallet;m.tick(3)
 check(m.wallet==wallet,"Unassigned worker stops immediately")
 m=fresh(5);c=m.cats[0];var k: Dictionary=c.knot;var locked_id: int=k.ids.keys()[0]
 check(m.direct(c,locked_id)==0,"Knot locks enclosed hair")
 var outside: int=m.spawn(c,"normal",-k.pos.normalized()*0.4)
 check(m.direct(c,outside)>0,"Knot does not lock rest of body")
 var knot_at: Vector2=k.pos
 m.move(c.id,knot_at-Vector2(0.04,0),knot_at+Vector2(0.04,0),false)
 check(is_zero_approx(k.distance),"Knot requires held input")
 m.click(c.id,knot_at);check(not c.knot.is_empty(),"Single click cannot untie")
 for i in 12:
  var from: Vector2=knot_at+Vector2(-0.045 if i%2==0 else 0.045,0)
  m.move(c.id,from,knot_at-(from-knot_at),true)
 check(c.knot.is_empty() and not c.hairs.has(locked_id),"Held reversals untie and pay once")
 m=fresh(6);c=m.cats[0];fast=m.cats[1]
 wallet=m.wallet;var lifetime: int=m.lifetime
 a=c.hairs.keys()[0];var pending: int=c.pending
 check(m.direct(c,a)==0 and m.collect(c,[a],"worker")==0 and m.collect(c,[a],"knot")==0,"Flea blocks all collection sources")
 var count_before: int=c.born;m.tick(1.1)
 check(c.born>count_before and c.flea.stolen==2 and m.wallet==wallet,"Flea steals actual hairs, growth continues, worker paused")
 check(m.direct(fast,fast.hairs.keys()[0])>0,"Other cat unaffected")
 wallet=m.wallet;lifetime=m.lifetime;var recovered: int=c.flea.bag+int(ceil(c.flea.left))
 for i in 6:m.hit_flea(c)
 check(c.flea.is_empty() and m.wallet==wallet+recovered and m.lifetime==lifetime,"Flea return and reward not milestone income")
 m.hit_flea(c);m.finish_flea(c,true);check(m.wallet==wallet+recovered,"Repeated completion cannot pay again")
 m=fresh(6);c=m.cats[0];wallet=m.wallet;m.tick(12)
 check(c.flea.is_empty() and m.wallet==wallet,"Timeout no inventory loss or reward")
 check(m.direct(c,c.hairs.keys()[0])>0,"Income resumes after expiry")
 m=fresh(5);c=m.cats[0];var ids: Array=c.knot.ids.keys()
 m.trigger_flea(c.id)
 var protected_king: int=m.spawn(c,"king")
 m.tick(1.01)
 check(c.hairs.has(protected_king),"Flea never steals king")
 k=c.knot;var knot_distance: float=k.distance
 m.move(c.id,k.pos-Vector2(0.04,0),k.pos+Vector2(0.04,0),true)
 check(k.distance==knot_distance,"Flea also blocks untying progress")
 for i in 6:m.hit_flea(c)
 var surviving: int=0
 for knot_id in ids:
  if c.hairs.has(knot_id):surviving+=int(c.hairs[knot_id].value)
 wallet=m.wallet;c.knot={};var paid: int=m.collect(c,ids,"knot")
 check(paid==surviving and m.wallet==wallet+surviving,"Stolen knot IDs cannot pay twice")
 m=fresh(7);var special: Dictionary=m.cats[2]
 check(m.assign(2,special.id),"Special permits demonstrative worker assignment")
 wallet=m.wallet;pending=special.pending;m.tick(1)
 check(special.lost>0 and special.pending==pending and m.wallet>=wallet,"Special shrinks one actual new/old hair, no inventory debit")
 m.assign(2,-1);var lost: int=special.lost;m.tick(2)
 check(special.lost==lost,"Withdrawal immediately stops losses")
 m.assign(2,special.id);m.trigger_flea(special.id);lost=special.lost;m.tick(1)
 check(special.lost==lost,"Flea pauses special worker losses")
 for i in 6:m.hit_flea(special)
 check(m.direct(special,special.hairs.keys()[0])>0,"Special manual harvest works")
 # Every preset is a complete reset, not an additive cheat; exercise all 64 transitions.
 for from in 8:
  for to in 8:
   m.reset(from);m.tick(0.1);m.reset(to)
   check(m.wallet==C.STAGES[to].wallet and m.cats.size()==C.STAGES[to].cats.size() and is_zero_approx(m.time),"Stage replaces session %d -> %d"%[from,to])
   for node in C.NODES:
    if m.level(node.key)>0 and node.prereq!="":check(m.level(node.prereq)>0,"Preset prerequisite coherence")
   var first_position: Vector2=m.cats[0].hairs[1].pos
   m.reset(to);check(m.cats[0].hairs[1].pos==first_position,"Preset seed reproducible")
 m=fresh();var report: Dictionary=simulate_progression(m)
 check(report.all_bought and m.cats.size()==3 and m.enabled.knot and m.enabled.flea,"Continuous no-cheat progression reaches all basic systems")
 accounting(m)
 for scale in [1000,10000,50000]:
  m=fresh();c=m.cats[0];c.hairs.clear();c.pending=0
  var start: int=Time.get_ticks_usec()
  for i in scale:m.spawn(c,"normal")
  var spawn_ms: float=(Time.get_ticks_usec()-start)/1000.0
  start=Time.get_ticks_usec();m.tick(10)
  var tick_ms: float=(Time.get_ticks_usec()-start)/1000.0
  check(c.hairs.size()==scale+10 and c.pending==scale+10,"Dense population retains all value and keeps growing")
  start=Time.get_ticks_usec();var harvested: int=m.collect(c,c.hairs.keys(),"click")
  var collect_ms: float=(Time.get_ticks_usec()-start)/1000.0
  check(harvested==scale+10 and c.pending==0 and c.hairs.is_empty(),"Dense collection full value, no cap")
  performance.append({"hairs":scale,"spawn_ms":spawn_ms,"tick_10s_ms":tick_ms,"collect_ms":collect_ms})
 var file=FileAccess.open("res://reports/prototype_20261009/model_results.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":checks,"failures":failures,"performance":performance,"continuous_strategy":report},"  "))
 print("PROTOTYPE MODEL: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
func simulate_progression(m) -> Dictionary:
 var history: Array=[]
 for second in 900:
  m.tick(1)
  for c in m.cats.duplicate():
   if not c.flea.is_empty():
    for i in 6:m.hit_flea(c)
   if not c.knot.is_empty():
    var center: Vector2=c.knot.pos
    for i in 12:
     var a: Vector2=center+Vector2(-0.045 if i%2==0 else 0.045,0)
     m.move(c.id,a,center-(a-center),true)
   # A simulated strategy, not a claim about human speed or duration.
   var actions: int=0
   for id in c.hairs.keys():
    if actions>=6:break
    m.direct(c,id);actions+=1
  for n in C.NODES:
   if m.reason(n.key)=="":
    m.buy(n.key);history.append({"seconds":second+1,"key":n.key,"level":m.level(n.key)})
  if m.workers.is_empty() and m.purchase("worker"):m.assign(1,1)
  if not m.buff_owned and m.purchase("buff"):m.set_buff(1)
  if not m.decor:m.purchase("decor")
  var complete: bool=m.buff_owned and m.decor and not m.workers.is_empty() and m.cats.size()==3 and m.enabled.flea
  for n in C.NODES:complete=complete and m.level(n.key)==n.costs.size()
  if complete:return {"all_bought":true,"seconds":second+1,"purchases":history,"lifetime":m.lifetime,"wallet":m.wallet,"note":"Automated strategy only, not human playtime"}
 return {"all_bought":false,"seconds":900,"purchases":history}
