extends SceneTree
const M=preload("res://scripts/model.gd")
var failures: int=0
func _initialize() -> void:call_deferred("run")
func require(value: bool,message: String) -> void:
 if not value:failures+=1;push_error(message)
func run() -> void:
 var m=M.new();m.rng.seed=81926
 var report: Array=[]
 for run_no in range(1,4):
  var finished: bool=false
  for second in range(1200):
   # Player policy: harvest at 3 layers; use only earned money and ordinary APIs.
   for i in range(10):m.tick(0.1)
   for c in m.cats:
    if c.station==-1 and c.layers>=3:m.harvest(c.id)
   m.sell_all()
   if m.first_token and not m.gacha_ready:m.accept_contact()
   while m.tokens>0 and not m.pool().is_empty():m.draw_capsule()
   if not m.has("worker"):m.research("worker")
   elif m.workers.size()<1:m.buy("worker",Vector2(610,540))
   elif m.cats.size()<6:m.buy("short",Vector2(430+(m.cats.size()%3)*95,480+(m.cats.size()/3)*55))
   elif not m.has("feeder"):m.research("feeder")
   elif m.count("feeder")==0:m.buy("feeder",Vector2(550,490))
   elif not m.has("sun"):m.research("sun")
   elif m.count("sun")==0:m.buy("sun",Vector2(900,480))
   elif run_no>=2 and not m.has("hats"):m.research("hats")
   elif run_no>=2 and not m.has("arcade"):m.research("arcade")
   elif run_no>=2 and m.count("arcade")==0:m.buy("arcade",Vector2(740,660))
   elif run_no>=3 and not m.has("altar"):m.research("altar")
   elif run_no>=3 and m.count("altar")==0:m.buy("altar",Vector2(1150,600))
   elif run_no>=3 and not m.has("maint"):m.research("maint")
   elif m.workers.size()<3:m.buy("worker",Vector2(630,590))
   if m.has("feeder") and m.food[0]<6:m.buy_food(0)
   for f in m.facilities:
    if f.kind=="feeder" and f.grain<5:m.refill(f.id)
    if f.bugs>0:m.clean(f.id)
    if f.broken:m.repair(f.id)
    if f.kind in ["arcade","altar"] and m.occupants(f.id).is_empty():
     for c in m.cats:
      if c.station==-1:m.assign(c.id,f.id);break
   m.events.clear()
   var ready: bool=m.count("sun")>0 and (run_no<2 or m.count("arcade")>0) and (run_no<3 or (m.count("altar")>0 and m.has("maint")))
   if m.pool().is_empty() and ready:
    report.append({"round":run_no,"seconds":second+1,"cats":m.cats.size(),"workers":m.workers.size(),"wallet":snappedf(m.wallet,0.1),"collection":m.owned.size()})
    finished=true;break
  require(finished,"Round %d cannot progress with earned resources" % run_no)
  if run_no<3:require(m.advance_round(),"Advance round %d" % run_no)
 require(m.owned.size()==27,"All three rounds have complete unique collections")
 var file:=FileAccess.open("res://reports/v026/progression.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"policy":"Deterministic active-play simulation, no injected currency", "rounds":report,"failures":failures},"  "));file.close()
 print("PROGRESSION: ",JSON.stringify(report)," failures=",failures)
 quit(0 if failures==0 else 1)
