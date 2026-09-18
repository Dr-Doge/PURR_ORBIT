extends SceneTree
const M = preload("res://scripts/model.gd")
const D = preload("res://scripts/data.gd")
var checks: int = 0
var failures: int = 0
func check(value: bool,message: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(message)
func sim(m,seconds: float) -> void:
 for i in range(ceili(seconds/0.1)):m.tick(0.1)
func fresh(round_no: int=1):
 var m=M.new();m.rng.seed=5821;m.round_no=round_no;m.wallet=10000.0
 for k in D.RESEARCH:
  if D.gate(k)<=round_no:m.research(k)
 m.events.clear();return m
func device(m,kind: String,pos: Vector2=Vector2(600,500)) -> Dictionary:
 check(m.buy(kind,pos),"buy "+kind);return m.facilities.back()
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var m=M.new();m.rng.seed=4
 m.cats[0].layers=0;sim(m,6.1)
 check(m.cats[0].layers==1 and m.cats[1].layers==1,"Equal initial layer CD")
 check(m.wallet==0,"Grown fur is not automatically harvested")
 sim(m,12.0);check(m.cats[0].layers==3,"Unharvested fur stacks on same CD")
 var c: Dictionary=m.cats[0]
 check(m.harvest_value(c)>3*3.0,"Stacked yield exceeds repeated single layers")
 var growth: float=c.growth;m.harvest(c.id)
 check(c.layers==0 and is_equal_approx(c.growth,growth),"Harvest clears completed layers and retains partial CD")
 var coins: float=m.wallet;check(not m.harvest(c.id) and m.wallet==coins,"No zero-layer duplicate rewards")
 check(m.tokens==1 and m.first_token,"Early token after three harvested layers")
 c.layers=1;c.dragging=true;m.pet(c.id,500);check(c.layers==1,"Dragging cannot simultaneously pet")
 c.dragging=false
 for i in range(3):m.pet(c.id,45)
 check(c.layers==0,"Mouse distance produces one harvest")
 sim(m,70);check(c.layers==8,"Demo layer cap holds")
 m=fresh(1)
 check(not m.research("arcade") and not m.buy("arcade") and not m.upgrade("arcade","time"),"Money cannot bypass round gates")
 check(not m.buy("giant"),"Special cats cannot be bought")
 check(m.has("sun") and m.lv("feeder","food")==0,"Main path does not require branch levels")
 var f: Dictionary=device(m,"feeder");c=m.cats[0];m.move_cat(c.id,f.pos);c.layers=2
 var plain: float=m.harvest_value(c);check(m.refill(f.id),"Manual refill uses stocked food")
 check(m.food[0]==0 and f.grain==20,"Refill conserves food")
 sim(m,0.1);check(f.grain<20 and m.harvest_value(c)>plain,"Auto feeding consumes grain and improves output")
 var sun: Dictionary=device(m,"sun",Vector2(880,500));f.neglect=100;sim(m,1)
 check(f.bugs==0,"No bugs anywhere in round one")
 c.layers=0;check(m.assign(c.id,sun.id),"Cat enters sun")
 var old_pos: Vector2=c.pos;sim(m,2.5)
 check(c.layers==1 and c.station==-1 and c.pos!=old_pos,"Sun grants one layer then auto exits")
 m=fresh(2);f=device(m,"feeder");sim(m,40)
 check(f.bugs==0,"Round two still needs installed sun")
 sun=device(m,"sun",Vector2(870,500));sim(m,38.2)
 check(f.bugs==3,"Neglect after sun creates bugs")
 c=m.cats[0];m.move_cat(c.id,f.pos);c.layers=1;c.fed=10;c.kind="short"
 check(m.harvest_value(c)<3,"Bugs actively reduce below normal yield")
 for i in range(6):m.clean(f.id)
 check(f.bugs==0 and f.neglect==0,"Complete manual cleaning resets neglect")
 c.kind="giant";f.bugs=3;f.grain=8;f.pulse=0;sim(m,0.1)
 check(f.bugs<3,"Giant eating removes some bugs")
 var arcade: Dictionary=device(m,"arcade",Vector2(900,540));sim(m,40)
 check(not arcade.broken,"Round two has no interference")
 m=fresh(3);arcade=device(m,"arcade",Vector2(850,500));sim(m,35)
 check(not arcade.broken,"No altar means no interference")
 var altar: Dictionary=device(m,"altar",Vector2(1050,650));sim(m,32.1)
 check(arcade.broken,"Altar creates blackscreen without alien conversion")
 c=m.cats[0];m.assign(c.id,arcade.id);var items: int=m.inventory.size();var layers: int=c.layers;sim(m,12)
 check(m.inventory.size()==items and c.layers==layers,"Blackscreen halts prizes; arcade cats never grow fur")
 m.researches.erase("maint");check(not m.repair(arcade.id,true),"Workers need maintenance research")
 for i in range(6):m.repair(arcade.id)
 check(not arcade.broken,"Manual repair restores after six clicks")
 sim(m,25);check(m.inventory.size()>items,"Repaired arcade resumes payouts")
 c=m.cats[1];m.assign(c.id,altar.id);check(m.altar_speed()>1,"Assigned altar cat speeds production")
 m=fresh();m.facilities.clear();c=m.cats[0];var other: Dictionary=m.cats[1]
 c.kind="static";other.kind="static";c.pos=Vector2(600,500);other.pos=Vector2(650,500);c.layers=1;other.layers=5
 var before: float=m.wallet;var tc: int=m.token_progress;m.harvest(c.id)
 check(m.wallet-before==6 and other.layers==5 and m.token_progress==tc+1,"Static grants one separate bonus; no chain, no fur loss or extra token progress")
 c.kind="lucky";var heads: int=0;var tails: int=0
 for i in range(60):
  c.layers=1;before=m.wallet;items=m.inventory.size();m.harvest(c.id)
  if m.inventory.size()>items:heads+=1
  else:tails+=1
  check(m.wallet>before,"Coin flip never removes base reward")
 check(heads>0 and tails>0,"Lucky cat generates both outcomes")
 c.kind="giant"
 for i in range(100):m.try_transform(c,"alien","altar")
 check(c.kind=="giant","Special traits cannot overwrite each other in demo")
 m=fresh(2);m.buy("worker",Vector2(550,500));var w: Dictionary=m.workers[0]
 c=m.cats[0];c.layers=2;c.pos=Vector2(550,500);c.dest=c.pos;other=m.cats[1];other.layers=0;m.set_role(w.id,"harvest")
 sim(m,1.2);check(c.layers==2,"Worker respects three-layer harvest strategy")
 c.layers=3;sim(m,1.5);check(c.layers==0 and m.harvests==1,"Worker harvests and directly settles currency")
 sun=device(m,"sun",Vector2(1150,600));m.set_role(w.id,"sun");m.move_cat(c.id,Vector2(500,500));c.layers=0;w.pos=c.pos
 sim(m,1.0);check(c.station< -1 and c.pos.distance_to(sun.pos)>100,"Worker carries cat through room instead of teleporting")
 sim(m,6);check(c.layers>0,"Worker delivery finishes sun cycle")
 check(not m.set_role(w.id,"repair"),"Role assignment respects maintenance gate")
 m=fresh(3);arcade=device(m,"arcade");m.buy("worker",arcade.pos);w=m.workers[0];m.set_role(w.id,"repair");arcade.broken=true
 sim(m,6);check(not arcade.broken,"Maintenance worker can repair without open panel")
 m=M.new();check(not m.advance_round(),"Cannot reset before pool complete")
 m.first_token=true;m.tokens=50;check(m.accept_contact(),"Contact activates gacha")
 var collected: Dictionary={}
 for i in range(6):
  var key: String=m.draw_capsule();check(key!="" and not collected.has(key),"No-replacement collection");collected[key]=true
 var tokens: int=m.tokens;check(m.draw_capsule()=="" and m.tokens==tokens,"Empty pool never consumes coins")
 var buff: float=m.effect("yield");m.wallet=100;check(m.advance_round(),"Round two starts after collection")
 check(m.pool().size()==9 and m.owned.size()==6 and m.effect("yield")==buff and buff>1,"New nine-item pool; immediate inherited buff")
 check(m.wallet==0 and m.tokens==0 and m.cats.size()==2 and m.facilities.is_empty() and not m.has("sun"),"Explicit reset removes run state and installed event triggers")
 m.first_token=true;m.accept_contact();m.tokens=20
 for i in range(9):m.draw_capsule()
 check(m.advance_round() and m.pool().size()==12,"Third round adds twelve new items")
 m.first_token=true;m.accept_contact();m.tokens=20
 for i in range(12):m.draw_capsule()
 check(not m.advance_round() and m.owned.size()==27,"Demo stops after three rounds and preserves 27 unique collectibles")
 var saved: Dictionary=m.snapshot();var restored=M.new();check(restored.restore(saved),"Valid save restores")
 check(restored.owned==m.owned and restored.effect("yield")==m.effect("yield") and restored.rng.state==m.rng.state,"Save preserves collection, buffs and RNG")
 var invalid: Dictionary=saved.duplicate(true);invalid.wallet=-1.0;check(not restored.restore(invalid) and restored.wallet==m.wallet,"Malformed save rejected without mutation")
 invalid=saved.duplicate(true);invalid.owned.append(invalid.owned[0]);check(not restored.restore(invalid),"Duplicate collectibles rejected")
 invalid=saved.duplicate(true);invalid.food=["bad",0,0];check(not restored.restore(invalid),"Malformed nested food data rejected")
 invalid=saved.duplicate(true);invalid.cats[0].color=99;check(not restored.restore(invalid),"Invalid cat visual data rejected")
 var populated=fresh(3);device(populated,"feeder");device(populated,"altar",Vector2(1000,600));populated.buy("worker");populated.upgrade("feeder","food");populated.assign(populated.cats[0].id,populated.facilities[1].id);populated.prize(populated.cats[1],12)
 var populated_copy=M.new()
 check(populated_copy.restore(populated.snapshot()) and populated_copy.workers.size()==1 and populated_copy.occupants(populated_copy.facilities[1].id).size()==1 and populated_copy.inventory.size()==1,"Populated facility, worker, assignment, branch and inventory save restores")
 var draw_save=M.new();draw_save.first_token=true;draw_save.tokens=3;draw_save.accept_contact();var draw_copy=M.new();draw_copy.restore(draw_save.snapshot())
 check(draw_save.draw_capsule()==draw_copy.draw_capsule(),"Saved RNG resumes the same gacha draw")
 var path: String="user://test_v026.save"
 check(m.save_to(path)==OK,"Atomic save initial write");m.wallet=99
 check(m.save_to(path)==OK and FileAccess.file_exists(path+".bak"),"Atomic save replacement and backup")
 check(restored.load_from(path) and restored.wallet==99,"Saved replacement reads correctly")
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 print("MODEL CHECKS: ",checks," checks; ",failures," failures")
 quit(0 if failures==0 else 1)
