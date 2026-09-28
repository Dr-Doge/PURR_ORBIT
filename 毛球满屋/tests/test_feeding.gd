extends SceneTree
const M=preload("res://scripts/model.gd")
const B=preload("res://scripts/balance.gd")
const V=preload("res://scripts/cat_visuals.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func sim(m,seconds: float) -> void:
 for i in range(ceili(seconds/0.05)):m.tick(0.05)
func fixture():
 var m=M.new();m.rng.seed=25;m.cats.resize(1);m.wallet=100000
 m.research("worker");m.research("feeder");m.buy("feeder",Vector2(650,500))
 m.facilities[0].grain=10
 m.move_cat(m.cats[0].id,Vector2(400,535));m.cats[0].kind="giant"
 return m
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var m=fixture();var c: Dictionary=m.cats[0];var f: Dictionary=m.facilities[0]
 var original: Vector2=c.pos
 sim(m,1)
 check(c.pos.x>original.x and c.feed_target==f.id,"Hungry cat seeks a stocked feeder outside old radius")
 check(c.fed==0 and f.grain==10,"Travelling does not grant buff or consume grain")
 c.pos=m.feeding_spot(f);c.layers=2;var layers: int=c.layers;var wallet: float=m.wallet
 sim(m,0.5)
 check(c.fed==0 and f.grain==10,"Meal must finish")
 sim(m,0.5)
 check(is_equal_approx(c.fed,B.FEED_DURATION) and f.grain==9,"Completed meal consumes exactly one portion")
 check(c.layers==layers and m.wallet==wallet,"Eating is not a harvest or payout")
 check(c.feed_target==-1 and c.walk_left>0,"Fed cat leaves to roam")
 m.move_cat(c.id,Vector2(150,680));sim(m,1)
 check(c.fed>0 and m.multiplier(c)>B.GIANT_HUNGRY,"Buff persists far away from feeder")
 check(f.grain==9,"Buff cannot refresh or repeatedly consume food")
 c.fed=0.01;sim(m,0.05)
 check(c.feed_target==f.id,"Expired buff starts a new search")
 m.buy("feeder",Vector2(300,600));var second: Dictionary=m.facilities[1];second.grain=2
 f.grain=0;sim(m,0.05)
 check(c.feed_target==second.id,"Empty destination redirects to available food")
 second.grain=0;sim(m,0.05)
 check(c.feed_target==-1 and c.fed==0,"All empty: no phantom buff or stuck target")
 second.grain=1;sim(m,0.05)
 check(c.feed_target==second.id,"Refilling resumes food search")
 m.move_cat(c.id,m.feeding_spot(second));sim(m,0.5);second.grain=0;sim(m,1)
 check(c.fed==0 and c.eat_time==0,"Food lost mid-meal cancels without reward")
 second.grain=1
 var other: Dictionary=m.add_cat(m.feeding_spot(second));other.kind="giant"
 other.pos=Vector2(1100,650);m.move_cat(c.id,m.feeding_spot(second));sim(m,1.1)
 check(second.grain==0 and int(c.fed>0)+int(other.fed>0)==1,"Two cats cannot consume the same last portion")
 m=fixture();c=m.cats[0];f=m.facilities[0];f.bugs=2
 m.move_cat(c.id,m.feeding_spot(f));sim(m,1.1)
 check(f.bugs==1,"Giant eats one pest only when meal completes")
 sim(m,1);check(f.bugs==1,"No repeated pest consumption during buff")
 m=fixture();c=m.cats[0];f=m.facilities[0];m.research("sun");m.buy("sun",Vector2(900,500))
 m.assign(c.id,m.facilities[1].id);sim(m,1)
 check(c.station==m.facilities[1].id and f.grain==10,"Assigned cats finish their facility activity first")
 sim(m,1.5);check(c.station==-1 and c.feed_target==f.id,"Released cats resume seeking food")
 m=fixture();c=m.cats[0];f=m.facilities[0];c.dragging=true;sim(m,2)
 check(f.grain==10 and c.fed==0,"Carried by player: no remote feeding")
 m.move_cat(c.id,m.feeding_spot(f));sim(m,0.5)
 var saved: Dictionary=m.snapshot();var loaded=M.new()
 check(loaded.restore(saved),"New activity state saves and restores")
 sim(loaded,0.5);check(loaded.cats[0].fed>0 and loaded.facilities[0].grain==9,"Saved half-meal finishes exactly once")
 for entry in saved.cats:
  for key in ["feed_target","eat_time","walk_left","idle_left"]:entry.erase(key)
 check(loaded.restore(saved),"Existing v27 saves need no migration")
 var bad: Dictionary=m.snapshot();bad.cats[0].idle_left=NAN
 check(not loaded.restore(bad),"Invalid activity timer rejected")
 m=M.new();m.cats.resize(1);c=m.cats[0];m.reset_activity(c)
 c.pos=Vector2(600,500);c.dest=Vector2(700,500);c.walk_left=0.2;c.layers=2
 var visual=V.new();visual.step(m,0)
 m.tick(0.1);visual.step(m,0.1)
 check(visual.states[c.id].animation=="walk","Movement selects walk frames")
 m.tick(0.1);visual.step(m,0.1);var stopped: Vector2=c.pos
 check(c.idle_left>=B.CAT_IDLE_MIN and c.idle_left<=B.CAT_IDLE_MAX,"Random idle duration stays in configured range")
 m.tick(0.1);visual.step(m,0.1)
 check(c.pos==stopped and visual.states[c.id].animation=="idle","Pause stays still and plays idle")
 var growth: float=c.growth;var pause: float=c.idle_left
 var action: Dictionary=m.harvest_ticket(c);action.progress=m.harvest_time(action.layers);m.harvest(c.id,action)
 check(m.harvests==1 and c.idle_left==pause,"Idle cat is harvestable without resetting its activity")
 sim(m,0.1);check(c.growth>growth,"Fur growth continues during idle")
 sim(m,B.CAT_IDLE_MAX+0.2);check(c.pos!=stopped,"Cat resumes walking after idle")
 print("FEEDING / ROAM: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
