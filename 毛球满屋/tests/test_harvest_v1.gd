extends SceneTree
const M=preload("res://scripts/model.gd")
const D=preload("res://scripts/data.gd")
const B=preload("res://scripts/balance.gd")
const H=preload("res://tests/harvest_fixture.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func sim(m,seconds: float) -> void:
 for i in range(ceili(seconds/0.05)):m.tick(0.05)
func fixture():
 var m=M.new();m.rng.seed=25;m.wallet=100000;m.research("worker");m.cats.resize(1)
 m.cats[0].pos=Vector2(600,500);m.reset_activity(m.cats[0]);m.cats[0].idle_left=100
 return m
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var m=fixture();var c: Dictionary=m.cats[0]
 check(c.layers==1 and m.add_cat(Vector2(800,500)).layers==1,"Initial and purchased cats start with first layer")
 var cash: float=m.wallet;sim(m,10.1)
 check(c.layers==2 and m.wallet==cash,"Equal natural CD grows second layer without money")
 c.layers=1;c.growth=0
 m.pet(c.id,1000)
 check(m.wallet==cash and c.pet==45,"One large motion event credits at most 45 pixels")
 m.pet(c.id,45);m.pet(c.id,45);m.pet(c.id,29)
 check(m.harvests==0 and c.pet==164,"164 effective pixels cannot settle first layer")
 m.pet(c.id,1)
 check(m.harvests==1 and c.layers==1 and m.wallet==cash+3,"Exactly 165 pixels settles once and leaves first layer")
 check(not m.harvest(c.id),"Repeated completion without fresh interaction is rejected")
 var next: float=m.wallet;sim(m,0.5)
 check(m.wallet==next,"Persistent first layer never pays automatically")
 H.wait_ready(m,c)
 m.pet(c.id,20);sim(m,0.1);m.pet(c.id,20)
 check(c.pet>0,"Mouse movement adds operation progress")
 sim(m,0.3);check(c.pet==0,"Interrupted input cancels manual progress")
 var durations: Array=[]
 for n in [1,4,8]:
  H.wait_ready(m,c)
  c.layers=n;c.growth=0;m.cancel_pet(c);var start: float=m.elapsed;H.rub(m,c.id);durations.append(m.elapsed-start)
 check(durations[0]>0 and durations[1]>durations[0] and durations[2]>durations[1],"Higher layers really require longer input")
 H.wait_ready(m,c)
 c.layers=3;c.growth=5.9
 var action: Dictionary=m.harvest_ticket(c);action.progress=m.harvest_time(3)
 m.layer(c);cash=m.wallet
 check(m.harvest(c.id,action) and m.wallet==cash+18 and c.layers==2,"Start layers lock payout; newly grown layer is retained")
 check(c.growth==5.9,"Harvest preserves partial natural CD")
 check(not m.harvest(c.id,action),"Same completion ticket cannot pay twice")
 c.dragging=true;check(not H.settle(m,c.id),"Dragging blocks settlement");c.dragging=false
 m.research("feeder");m.research("sun");m.buy("sun",Vector2(800,500));m.assign(c.id,m.facilities[0].id)
 check(not H.settle(m,c.id),"Occupied cat cannot exploit permanent first layer")
 m.move_cat(c.id,Vector2(600,500));H.wait_ready(m,c);c.layers=1
 check(m.worker_target()==1,"Workers start at threshold one")
 for i in range(7):
  check(m.upgrade("worker","harvest_layers") and m.worker_target()==i+2,"Paid upgrade adds exactly one threshold")
 check(m.worker_target()==D.MAX_LAYERS and not m.upgrade("worker","harvest_layers"),"Threshold cannot exceed layer cap")
 m.buy("worker",c.pos);var w: Dictionary=m.workers[0]
 c.layers=7;check(m.choose_job(w,{}).get("kind","")!="harvest","Below threshold is not harvested")
 c.layers=8;check(m.choose_job(w,{}).get("kind","")=="harvest","At threshold is eligible")
 m.levels["worker:harvest_layers"]=1;c.layers=5
 check(m.choose_job(w,{}).get("kind","")=="harvest","Excess layers remain eligible")
 m=fixture();c=m.cats[0];m.buy("worker",c.pos);w=m.workers[0]
 sim(m,1);check(m.harvests==0 and w.cooldown==0,"Worker CD starts after output, not when interaction begins")
 H.settle(m,c.id);var count: int=m.harvests
 sim(m,0.1);check(m.harvests==count and w.clock<=0.1,"Player winning race cancels stale worker progress")
 sim(m,3.2);check(m.harvests==count+1 and w.cooldown>2.5,"Worker finishes fresh full action then starts CD")
 count=m.harvests;sim(m,2.0);check(m.harvests==count,"No reharvest during cooldown")
 m.researches.hats=true;m.round_no=2
 var cooldown: float=w.cooldown;m.set_role(w.id,"refill");m.set_role(w.id,"harvest")
 check(w.cooldown==cooldown,"Role change cannot clear cooldown")
 m.round_no=1;m.researches.erase("hats");w.role="general"
 var snap: Dictionary=m.snapshot();var loaded=M.new()
 check(loaded.restore(snap) and loaded.workers[0].cooldown==w.cooldown,"Read/write snapshot preserves remaining CD")
 var path: String="user://harvest_v1_isolated.save"
 check(m.save_to(path)==OK and loaded.load_from(path) and loaded.workers[0].cooldown==w.cooldown,"Actual isolated file preserves CD")
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 var old_cd: float=m.worker_cooldown();var time: float=m.harvest_time(4)
 m.upgrade("worker","cooldown")
 check(m.worker_cooldown()<old_cd and m.harvest_time(4)==time and D.LAYER_CD==10 and m.worker_target()==1,"CD upgrade changes only next post-output cooldown")
 m.upgrade("worker","efficiency")
 check(m.worker_cooldown()==maxf(B.WORK_CD_MIN,old_cd*B.WORK_CD_RATIO),"Efficiency does not multiply CD reduction")
 w.cooldown=3;m.buy("worker",c.pos);var w2: Dictionary=m.workers[1]
 sim(m,2);check(w2.cooldown>0 and w.cooldown>0 and not is_equal_approx(w2.cooldown,w.cooldown),"Workers have independent cooldown clocks")
 m=fixture();c=m.cats[0];m.research("feeder");m.buy("feeder",c.pos);m.buy("worker",c.pos);w=m.workers[0];w.cooldown=3
 sim(m,0.7);check(m.facilities[0].grain>0 and w.cooldown>0,"Other jobs can run during harvest CD")
 m.research("sun");m.buy("sun",Vector2(680,500));w.role="sun";w.job={};c.layers=1
 sim(m,5);check(c.layers>1 or c.station>=0,"Sun carry works for permanent-first-layer cats")
 m=fixture();snap=m.snapshot();snap.erase("harvest_rules");snap.levels["worker:carry"]=4;snap.harvest_target=6;snap.cats[0].layers=0
 var original: Dictionary=snap.duplicate(true)
 check(loaded.restore(snap),"Old zero-layer/carry save is accepted")
 check(loaded.cats[0].layers==1 and loaded.worker_target()==1,"Old save normalizes layers without forcing high threshold")
 check(loaded.wallet==snap.wallet+2850 and not loaded.levels.has("worker:carry"),"Old carry investment refunded at exact historic costs")
 check(snap==original,"Restore never mutates source snapshot")
 var updated: Dictionary=loaded.snapshot();check(loaded.restore(updated) and loaded.wallet==updated.wallet,"Migration refund does not repeat after resave")
 m=fixture();c=m.cats[0];c.kind="static";var other: Dictionary=m.add_cat(c.pos+Vector2(10,0));other.layers=4
 cash=m.wallet;H.settle(m,c.id)
 check(m.wallet==cash+6 and other.layers==4 and m.production==3,"Static bonus once, no extra contribution or layer clearing")
 var last: float=m.wallet;check(not m.harvest(c.id) and m.wallet==last,"Static bonus cannot repeat with stale callback")
 c.kind="lucky";var draws: int=0
 for i in range(20):
  H.wait_ready(m,c)
  c.layers=1
  var before: int=m.inventory.size();H.settle(m,c.id);draws+=m.inventory.size()-before
 check(draws>0 and draws<=20 and m.production==63,"Lucky trigger bounded per completed action, contribution only primary")
 print("HARVEST V1: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
