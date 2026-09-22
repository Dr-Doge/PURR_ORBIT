extends SceneTree
const H=preload("res://tests/harvest_fixture.gd")
const M=preload("res://scripts/model.gd")
const D=preload("res://scripts/data.gd")
const B=preload("res://scripts/balance.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func sim(m,seconds: float) -> void:
 for i in range(ceili(seconds/0.1)):m.tick(0.1)
func funded():
 var m=M.new();m.rng.seed=2718;m.wallet=100000.0
 for key in ["worker","feeder","sun"]:m.research(key)
 return m
func restock(m) -> void:
 m.first_token=true;m.minted=36;m.tokens=36;m.accept_contact()
 for i in range(12):m.draw_capsule()
func run() -> void:
 var m=M.new();m.rng.seed=1
 m.cats[0].layers=1;sim(m,10.1)
 check(m.cats[0].layers==2 and m.cats[1].layers==2,"Equal layer CDs")
 check(m.wallet==0,"Growth is not automatic harvest")
 sim(m,20);var c: Dictionary=m.cats[0]
 check(c.layers==4 and m.harvest_value(c)==30,"Stack formula: 4 layers = 30")
 var partial: float=c.growth;H.settle(m,c.id)
 check(c.layers==1 and c.growth==partial,"Harvest preserves partial growth")
 check(m.first_token and m.tokens==1 and m.production==30,"First contact after 3 harvested layers")
 var value: float=m.production;check(not m.harvest(c.id) and m.production==value,"No empty harvest rewards")
 c.layers=2;c.dragging=true;m.pet(c.id,1000);check(c.layers==2,"Drag does not harvest")
 c.dragging=false
 H.rub(m,c.id)
 check(c.layers==1,"Hover movement completes harvest")
 sim(m,80);check(c.layers==8,"Fur cap")
 m=funded();check(not m.research("arcade") and not m.buy("arcade"),"Money cannot bypass stage gates")
 check(not m.research("altar") and not m.buy("altar") and not m.buy("alien"),"Future content unavailable")
 check(m.has("sun") and m.lv("feeder","food")==0,"Branches not mandatory")
 m.buy("feeder",Vector2(600,500));var f: Dictionary=m.facilities[0]
 m.refill(f.id);check(f.grain==20 and m.food[0]==0,"Refill conserves grain")
 m.buy("sun",Vector2(950,500));var sun: Dictionary=m.facilities[1]
 c=m.cats[0];m.move_cat(c.id,f.pos);c.layers=2;var before: float=m.harvest_value(c)
 sim(m,3.5);check(m.harvest_value(c)>before,"Actual arrival and eating improves output")
 f.neglect=999;sim(m,1);check(f.bugs==0,"No stage-one pests")
 c.layers=1;m.assign(c.id,sun.id);sim(m,2.5)
 check(c.layers==2 and c.station==-1,"Sun adds a layer and releases cat")
 m.buy("worker");m.workers[0].job={"kind":"harvest","target":c.id,"cat":c.id};m.workers[0].clock=0.3
 var snap: Dictionary=m.snapshot();restock(m)
 check(m.round_no==2 and m.owned.size()==12 and m.pool().size()==24,"12th draw adds 24 new items")
 check(m.tokens==24,"Restock never charges next coin")
 check(m.wallet==snap.wallet and m.cats==snap.cats and m.workers==snap.workers,"Restock keeps money, cats, partial CD, jobs and positions")
 check(m.food==snap.food and m.researches==snap.researches and f.grain==snap.facilities[0].grain,"Restock keeps supplies and facilities")
 check(f.neglect==0 and is_equal_approx(m.effect("yield"),1.6) and is_equal_approx(m.effect("speed"),1.24),"Pest grace and non-duplicated set buffs")
 check(not m.advance_stage(),"No skip to third stage")
 m.workers.clear();f.grain=0;f.pulse=999;c.kind="short";c.fed=0;m.move_cat(c.id,f.pos)
 sim(m,D.BUG_TIME-1);check(f.bugs==0,"No instant pests")
 sim(m,1.2);check(f.bugs==B.BUG_COUNT,"Existing sun enables second-stage pests")
 c.layers=1;check(m.harvest_value(c)<B.BASE_YIELD*m.effect("yield"),"Pests reduce below unbuffed production")
 for i in range(B.BUG_COUNT*B.BUG_HITS):m.clean(f.id)
 check(f.bugs==0 and f.neglect==0,"Manual clean resets risk")
 var production: float=m.production;var wallet: float=m.wallet
 m.prize(c,90);check(m.wallet==wallet and m.production==production,"No auto-sale or bonus double credit")
 m.sell_all();check(m.wallet>wallet and m.production==production,"Sale does not repeat contribution")
 m.research("hats");m.research("arcade");m.buy("arcade",Vector2(400,650));var arcade: Dictionary=m.facilities.back()
 c.kind="short";m.assign(c.id,arcade.id);var layers: int=c.layers;sim(m,60)
 check(c.layers==layers and m.inventory.size()>0 and m.production>production,"Arcade replaces fur with contributing main prizes")
 check(not arcade.broken and not m.research("maint"),"No interference or maintenance")
 m.move_cat(c.id,Vector2(600,500));c.kind="static";c.layers=1
 var other: Dictionary=m.cats[1];other.pos=c.pos+Vector2(30,0);other.layers=5
 before=m.production;value=m.harvest_value(c);H.settle(m,c.id)
 check(is_equal_approx(m.production-before,value) and other.layers==5,"Static bonus does not duplicate contribution or consume neighbour fur")
 c.kind="lucky";var heads: int=0;var tails: int=0
 for i in range(50):
  H.wait_ready(m,c)
  c.layers=1;before=m.wallet;var count: int=m.inventory.size();value=m.production;var primary: float=m.harvest_value(c);H.settle(m,c.id)
  if m.inventory.size()>count:heads+=1
  else:tails+=1
  check(m.wallet>before and is_equal_approx(m.production-value,primary),"Coin keeps base rewards without double credit")
 check(heads>0 and tails>0,"Both coin faces")
 for i in range(24):check(m.draw_capsule()!="","Unique second-batch draw")
 var coins: int=m.tokens
 check(m.owned.size()==36 and m.pool().is_empty() and m.draw_capsule()=="" and m.tokens==coins,"36 total; empty pool does not charge")
 check(not m.advance_stage() and m.round_no==2,"No third batch")
 check(is_equal_approx(m.effect("yield"),2.2) and is_equal_approx(m.effect("speed"),1.48),"Same-effect full-set bonuses add")
 var restored=M.new();var saved: Dictionary=m.snapshot()
 check(restored.restore(saved),"Valid save")
 check(restored.owned==m.owned and restored.production==m.production and restored.rng.state==m.rng.state,"Contribution, collection, RNG survive load")
 var invalid: Dictionary=saved.duplicate(true);invalid.version=26;check(not restored.restore(invalid),"No silent old-save migration")
 invalid=saved.duplicate(true);invalid.wallet=-1.0;check(not restored.restore(invalid),"Negative wallet rejected")
 invalid=saved.duplicate(true);invalid.owned.append(invalid.owned[0]);check(not restored.restore(invalid),"Duplicate collection rejected")
 invalid=saved.duplicate(true);invalid.production=NAN;check(not restored.restore(invalid),"NaN rejected")
 m=funded();m.levels["worker:harvest_layers"]=2;m.buy("worker",Vector2(550,500));c=m.cats[0];m.move_cat(c.id,Vector2(550,500));c.layers=3;m.cats[1].layers=1
 sim(m,4.5);check(m.harvests==1,"Worker independently harvests")
 var speed: float=m.work_speed();m.upgrade("worker","efficiency");check(m.work_speed()>speed,"Efficiency branch affects work")
 check(m.feed_capacity()==80,"Initial feeder capacity");m.upgrade("feeder","capacity");check(m.feed_capacity()==120,"Capacity branch")
 var balance: float=m.wallet;var grain: int=m.food[0]
 check(m.buy_food(0,10) and m.food[0]==grain+100 and m.wallet==balance-60,"Bulk food preserves per-pack cost")
 balance=m.wallet;check(not m.buy_food(0,-1) and m.wallet==balance,"Negative bulk cannot refund money")
 m=M.new();m.token_progress=3;m.contribute(B.TOKEN_THRESHOLDS[5]+0.1)
 check(m.tokens==6 and m.minted==6,"Large production settles every crossed threshold")
 var path: String="user://test_v027_isolated.save"
 check(m.save_to(path)==OK,"Isolated save write");m.wallet=99.0;check(m.save_to(path)==OK,"Atomic replacement")
 check(restored.load_from(path) and restored.wallet==99,"Replacement reads")
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 print("MODEL: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
