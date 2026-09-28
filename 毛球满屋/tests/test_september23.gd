extends SceneTree
const M=preload("res://scripts/model.gd")
const H=preload("res://tests/harvest_fixture.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func sim(m,seconds: float) -> void:
 for i in range(ceili(seconds/0.1)):m.tick(0.1)
func funded():
 var m=M.new();m.wallet=2000000.0;m.rng.seed=234
 return m
func buy_all(m) -> void:
 for pass_index in range(20):
  for id in m.tree:
   if m.node_reason(id)=="":m.buy_node(id)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var m=funded()
 check(m.tree.size()>120,"Full unified tree includes facility, performance, builds and altar")
 check(not m.buy_node("A2T") and not m.buy_node("XAB"),"Higher segments and cross routes require prerequisites")
 for id in ["N10","N20","N11","N40","N50","N12"]:check(m.buy_node(id),"Facility path without collection gate: "+id)
 check(m.round_no==1 and m.owned.is_empty() and m.has("maint"),"All mechanisms can unlock before first collection")
 check(not m.buy("alien"),"Special cats still require transformation")
 check(m.buy_node("A1T") and is_equal_approx(m.Build.spec(m,"A"),0.03),"First fragment only adds 3 percent")
 check(m.buy_node("A1M") and m.buy_node("S10") and m.buy_node("A2T"),"OR merge works without optional fragments")
 check(is_equal_approx(m.Build.spec(m,"A"),0.06),"Later entry adds its own fragment only")
 check(not m.buy_node("A2T"),"Node cannot be bought twice")
 for i in range(2):check(m.upgrade("worker","efficiency"),"Early worker levels")
 check(m.upgrade("worker","efficiency"),"S10 permits middle levels")
 buy_all(m)
 var complete: bool=true
 for id in m.tree:
  complete=complete and m.node_owned(id)
 check(complete,"Every node reachable without collections or optional deadlock")
 check(m.Build.combo_need(m)==7 and is_equal_approx(m.Build.combo_reward(m),0.65),"Full combo is 7 hits and 65 percent")
 for route in ["A","B","C"]:check(is_equal_approx(m.Build.spec(m,route),0.25),"Full specialty totals 25 percent: "+route)
 check(m.Build.charge_capacity(m)==6 and is_equal_approx(m.Build.order_factor(m,"set"),1.18),"Charge and order cumulative limits")
 var c: Dictionary=m.cats[0];m.cats.resize(1);c.kind="short";c.layers=1
 var base: float=m.harvest_value(c);var before: float=m.wallet
 for i in range(7):
  c.reaction_left=0;c.layers=1
  check(H.settle(m,c.id),"Real single harvest")
 check(is_equal_approx(m.wallet-before,base*(7*1.25+0.65)),"Combo bonus applies once based on Y0")
 check(is_equal_approx(m.production,base*7),"Build bonuses never duplicate token contribution")
 c.reaction_left=0;c.fed=10;c.layers=1;c.charges=[]
 for i in range(5):m.layer(c)
 check(c.charges.size()==5 and c.layers==6,"Fed new layers charge individually")
 var action: Dictionary=m.harvest_ticket(c);action.progress=m.harvest_time(c.layers)
 m.layer(c);var saved_charge: int=c.charges.size()
 check(m.harvest(c.id,action) and c.layers==2 and c.charges==[2],"Harvest preserves charge on newly grown unlocked layer")
 check(not m.harvest(c.id,action),"Old ticket cannot pay twice")
 c.reaction_left=0;c.layers=1;c.charges=[];c.fed=0;m.layer(c)
 check(c.charges.is_empty(),"No food means no charge")
 c.fed=10;m.layer(c,"sun");check(c.charges.size()==1,"B2M charges actual sunlight layer")
 var io=funded();io.cats.resize(1);var ic: Dictionary=io.cats[0]
 io.pet(ic.id,45);var progress: float=ic.pet;sim(io,2.0)
 check(ic.pet==progress,"Two-second interruption preserves progress")
 io.pet(ic.id,45);check(ic.pet==90,"Returning resumes same cat")
 sim(io,3.1);check(ic.pet==0,"Beyond three-second grace clears action")
 io.pet(ic.id,45);var snap: Dictionary=io.snapshot();var restored=M.new()
 check(restored.restore(snap) and restored.cats[0].pet==0,"Load cancels partial input without rewards")
 var reservation=funded();reservation.research("worker");reservation.research("feeder");reservation.research("sun")
 reservation.buy("sun",Vector2(650,500));var f: Dictionary=reservation.facilities[0]
 check(reservation.assign(reservation.cats[0].id,f.id),"First cat occupies single slot")
 check(not reservation.assign(reservation.cats[1].id,f.id) and reservation.capacity(f)==1,"Second cat cannot occupy same facility")
 reservation.move_cat(reservation.cats[0].id,Vector2(300,650))
 check(reservation.assign(reservation.cats[1].id,f.id),"Leaving releases occupancy")
 reservation.move_cat(reservation.cats[1].id,Vector2(850,650));reservation.buy("feeder",Vector2(600,500));f=reservation.facilities[1];reservation.refill(f.id)
 reservation.tick(0.1)
 var targets: int=0
 for cat in reservation.cats:
  if cat.feed_target==f.id:targets+=1
 check(targets==1,"Feeder attracts exactly one cat")
 var owner: Dictionary={}
 for cat in reservation.cats:
  if cat.feed_target==f.id:owner=cat
 reservation.move_cat(owner.id,Vector2(200,600));f.grain=0;reservation.tick(0.1)
 check(reservation.cats.all(func(cat):return cat.feed_target!=f.id),"Empty feeder and moved cat release reservations")
 m=funded();m.cats.clear()
 for i in range(15):m.add_cat(Vector2(650,500))
 var overlaps: int=0
 for cat in m.cats:
  if not m.Space.is_clear(m,cat,cat.pos):overlaps+=1
 check(overlaps==15,"Soft placement allows 15 cats at the requested point")
 sim(m,20)
 overlaps=0
 for cat in m.cats:
  if not m.Space.is_clear(m,cat,cat.pos):overlaps+=1
 check(m.cats.size()==15 and m.cats.all(func(cat):return cat.pos.is_finite()),"Crowding preserves cats and valid positions without hard separation")
 var old=funded().snapshot();old.erase("scope_rules")
 for key in ["nodes_owned","build_state","group_settings","orders"]:old.erase(key)
 old.researches={"worker":true,"feeder":true,"sun":true};old.levels={"sun:capacity":2}
 before=old.wallet;check(restored.restore(old) and restored.wallet==before+1200+2160,"Old multi-slot levels refunded at original prices")
 check(not restored.levels.has("sun:capacity") and restored.restore(restored.snapshot()) and restored.wallet==before+3360,"Refund is idempotent across saves")
 m=funded();buy_all(m);m.cats.resize(1);c=m.cats[0]
 m.prize(c,10);m.inventory[0].name="same";m.prize(c,20);m.inventory[1].name="same"
 check(m.Build.create_order(m,"pair") and m.orders[0].ids.size()==2,"Pair reserves two physical items")
 before=m.wallet;check(m.sell_all()==0 and m.inventory.size()==2,"Bulk sale protects reserved items")
 var production: float=m.production;var paid: float=m.Build.sell(m,0)
 check(is_equal_approx(paid,30*1.25*1.11) and m.inventory.is_empty() and m.production==production,"Order uses one factor and no repeated contribution")
 check(m.Build.sell(m,0)==0,"Consumed order cannot settle twice")
 for i in range(3):m.prize(c,10);m.inventory.back().name=str(i)
 m.Build.create_order(m,"trio");var ids: Array=m.orders[0].ids.duplicate()
 m.Build.create_order(m,"pair");check(m.orders[1].ids.is_empty(),"Different reservations cannot share objects")
 check(restored.restore(m.snapshot()),"New tree, orders, counters and groups survive validation")
 m.buy("altar",Vector2(900,500));var altar: Dictionary=m.facilities.back()
 m.assign(c.id,altar.id);check(m.altar_speed()>1 and m.capacity(altar)==1,"Single altar cat speeds global growth")
 m.buy("arcade",Vector2(300,500));var arcade: Dictionary=m.facilities.back();sim(m,33)
 check(arcade.broken,"Altar interference active in first collection batch")
 for i in range(6):m.repair(arcade.id)
 check(not arcade.broken,"Manual six-hit repair works")
 arcade.broken=true;m.buy("worker",arcade.pos);var w: Dictionary=m.workers[0];m.set_role(w.id,"repair");sim(m,5)
 check(not arcade.broken,"Maintenance worker repairs actual equipment")
 c.kind="alien";check(restored.restore(m.snapshot()) and restored.cats[0].kind=="alien","Alien, altar and maintenance save support")
 check(m.set_group("worker",w.id,1) and m.set_group_target(1,4,2) and m.worker_target(w)==4,"Group worker target within paid range")
 check(not m.set_group_target(1,9),"Group target cannot bypass paid cap")
 var cross=funded();buy_all(cross);cross.cats.resize(1);var cc: Dictionary=cross.cats[0]
 for i in range(8):cc.reaction_left=0;cc.layers=1;H.settle(cross,cc.id)
 check(cross.build_state.get("XAB_ready",false),"Eight true singles grant one relay marker")
 cc.reaction_left=0;cc.layers=4;before=cross.wallet;base=cross.harvest_value(cc);H.settle(cross,cc.id)
 check(is_equal_approx(cross.wallet-before,base*1.30) and not cross.build_state.XAB_ready,"Next heavy harvest consumes relay once")
 for i in range(12):cc.reaction_left=0;cc.layers=1;H.settle(cross,cc.id)
 check(cross.build_state.get("XAC_ready",false),"Twenty true singles grant one sale voucher")
 cross.prize(cc,10);cross.prize(cc,10);before=cross.wallet
 var sale: float=cross.sell_all()
 check(is_equal_approx(sale,25+12.5*0.05) and not cross.build_state.XAC_ready,"Voucher applies to exactly one physical item")
 cross.buy("arcade",Vector2(600,500));cc.reaction_left=0;cc.layers=4;cc.charges=[2,3,4];cc.use_boost=true
 before=cross.wallet;check(cross.assign(cc.id,cross.facilities[0].id) and cc.layers==1 and cc.charges.is_empty() and cc.entry_bonus==3 and cross.wallet==before,"Optional loaded entry consumes fur without double payout")
 sim(cross,6);check(cc.entry_bonus<3,"Entertainment consumes loaded rounds, not permanent bonus")
 cross.move_cat(cc.id,Vector2(900,600));check(cc.entry_bonus==0,"Leaving clears unused loaded rounds")
 var booking=funded()
 for subject in ["worker","feeder","sun","hats"]:booking.research(subject)
 booking.buy("sun",Vector2(850,500))
 for i in range(2):booking.buy("worker",Vector2(200,350));booking.set_role(booking.workers.back().id,"sun")
 booking.tick(0.1);var booked: int=0
 for worker in booking.workers:
  if worker.job.get("facility",-1)==booking.facilities[0].id:booked+=1
 check(booked==1,"Two workers reserve only one incoming cat for a facility")
 var chosen: Dictionary={}
 for worker in booking.workers:
  if not worker.job.is_empty():chosen=worker
 booking.set_role(chosen.id,"harvest")
 check(not booking.Space.reserved(booking,booking.facilities[0]),"Changing a worker job releases destination reservation")
 var invalid: Dictionary=booking.snapshot();invalid.nodes_owned={"UNKNOWN":true}
 check(not M.new().restore(invalid),"Unknown unified node rejected during load")
 var total: int=0
 for spec in booking.tree.values():total+=spec.price
 check(total>100000 and total<927484,"Updated full-tree budget calculated from actual nodes")
 print("TREE: ",booking.tree.size()," positions; ",total," total cost")
 var file:=FileAccess.open("res://reports/overlap_924/mechanics.txt",FileAccess.WRITE)
 file.store_string("SEPTEMBER23: %d checks, %d failures\n" % [checks,failures]);file.close()
 print("SEPTEMBER23: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
