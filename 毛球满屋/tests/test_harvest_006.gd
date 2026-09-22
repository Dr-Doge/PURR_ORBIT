extends SceneTree
const H=preload("res://tests/harvest_fixture.gd")
const M=preload("res://scripts/model.gd")
const D=preload("res://scripts/data.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func fixture():
 var m=M.new();m.cats.resize(1);m.rng.seed=6
 var c: Dictionary=m.cats[0];c.pos=Vector2(600,500);m.reset_activity(c);c.idle_left=1000
 return m
func sim(m,seconds: float) -> void:
 for i in range(roundi(seconds/0.01)):m.tick(0.01)
func rub_distance(m,id: int,amount: float) -> void:
 while amount>0:
  var step: float=minf(amount,40.0);m.pet(id,step);amount-=step
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var m=fixture();var c: Dictionary=m.cats[0]
 var previous: float=165;var increment: float=INF
 for n in range(1,9):
  var need: float=m.harvest_distance(n)
  check(is_equal_approx(need/165,m.harvest_time(n)/2),"Manual and worker share multiplier at layer %d"%n)
  if n==1:check(need==165,"First layer is exactly 165 effective pixels")
  else:
   check(need>previous and need-previous<increment and need<495,"Increasing cost, diminishing increments and bound at layer %d"%n)
   increment=need-previous
  H.wait_ready(m,c)
  previous=need;c.layers=n;m.cancel_pet(c)
  var count: int=m.harvests
  rub_distance(m,c.id,need-0.02)
  check(m.harvests==count and m.pet_progress(c)<1,"No early payout at layer %d"%n)
  m.pet(c.id,0.02)
  check(m.harvests==count+1 and c.layers==1,"Exact threshold pays once at layer %d"%n)
 check(absf(m.harvest_distance(8)-467.823081)<0.00001,"Eight layers approach but do not reach three times base")
 check(m.harvest_distance(60)>494.99 and m.harvest_distance(60)<=495,"High-layer extension stays bounded by 495")
 m=fixture();c=m.cats[0]
 for amount in [0.0,-1.0,INF,NAN]:m.pet(c.id,amount)
 sim(m,0.2);check(c.pet==0 and m.wallet==0,"No motion or invalid motion never creates income")
 m.pet(c.id,1000);check(c.pet==45,"Distance cap applies to first event too")
 check(not m.harvest(c.id),"Partial distance ticket is not interpreted as seconds")
 sim(m,0.2);m.pet(c.id,45);check(c.pet==90,"Brief interruption retains progress")
 sim(m,0.3);m.pet(c.id,20);check(c.pet==20,"Long interruption restarts with fresh event credit")
 m.cancel_pet(c);c.layers=2;m.pet(c.id,40)
 var action: Dictionary=c.pet_action
 m.layer(c);rub_distance(m,c.id,224)
 check(m.wallet==9 and c.layers==2,"Growth during manual input is retained without changing locked cost")
 check(not m.harvest(c.id,action) and m.wallet==9,"Stale completed distance ticket never pays twice")
 m=fixture();c=m.cats[0];sim(m,9.99)
 check(c.layers==1,"Unbuffed fur does not grow early")
 m.tick(0.011);check(c.layers==2,"Unbuffed second layer grows at ten seconds")
 sim(m,10);check(c.layers==3,"Subsequent layers use the same ten-second CD")
 m=fixture();c=m.cats[0]
 for i in range(6):m.owned.append("s1_time:"+str(i))
 check(is_equal_approx(m.growth_speed(c),1.24),"Existing collection growth buff remains active")
 sim(m,8.06);check(c.layers==1,"Buff does not complete layer before 10 / 1.24 seconds")
 m.tick(0.01);check(c.layers==2,"Buff shortens natural CD to 10 / 1.24 seconds")
 for n in [1,4,8]:
  m=fixture();c=m.cats[0];c.layers=n;m.wallet=1000;m.research("worker");m.buy("worker",c.pos)
  var need: float=m.harvest_time(n)
  sim(m,floorf((need-0.1)*100)/100)
  check(m.harvests==0,"Worker cannot settle before shared curve duration at %d layers"%n)
  sim(m,0.2)
  check(m.harvests==1 and m.workers[0].cooldown>2.8,"Worker settles then starts own CD at %d layers"%n)
 m=fixture();c=m.cats[0]
 for i in range(3):
  H.wait_ready(m,c);rub_distance(m,c.id,165)
 check(m.wallet==9 and m.tokens==1 and m.production==9,"Three completed first-layer gestures grant early money and first token")
 var snap: Dictionary=m.snapshot();snap.cats[0].growth=5.9
 m.pet(c.id,40);snap=m.snapshot();snap.cats[0].growth=5.9
 var loaded=M.new();check(loaded.restore(snap) and loaded.cats[0].pet==0 and loaded.cats[0].growth==5.9,"Loading keeps natural elapsed growth but cancels incomplete manual input")
 print("HARVEST 006: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
