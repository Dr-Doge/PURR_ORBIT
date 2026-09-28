extends SceneTree
const M = preload("res://scripts/model.gd")
const D = preload("res://scripts/data.gd")
class ReferenceModel extends M:
 func contribute(amount: float, _at: Vector2 = Vector2.ZERO) -> void:
  production += amount
  if not first_token and token_progress >= B.FIRST_TOKEN_LAYERS:
   first_token = true; minted = 1; tokens += 1
func _initialize() -> void:
 print("Historical exploratory runner frozen. Use tests/test_progression.gd for current paired validation.")
 quit(0)
func mark(m, marks: Dictionary, key: String, valid: bool) -> void:
 if valid and not marks.has(key): marks[key] = snappedf(m.elapsed,0.1)
func decisions(m, mode: String, second: int) -> void:
 if mode == "none": return
 var limit: int = 12 if mode == "cats" else (8 if m.round_no == 1 else 12)
 if mode == "cats":
  if m.cats.size()<limit: m.buy("short",Vector2(450+(m.cats.size()%4)*100,450+(m.cats.size()/4)*70))
  return
 # One strategic transaction per ten simulated seconds; no free assets or timed unlocks.
 if not m.has("worker"): m.research("worker"); return
 if m.workers.size()<1: m.buy("worker"); return
 if m.cats.size()<4: m.buy("short",Vector2(500+(m.cats.size()%3)*80,480)); return
 if mode!="single" and m.lv("worker","harvest_layers")<(7 if mode=="layers" else 5):
  if m.upgrade("worker","harvest_layers"):return
 if not m.has("feeder"): m.research("feeder"); return
 if m.count("feeder")==0: m.buy("feeder",Vector2(600,480)); return
 if m.food[0]<20: m.buy_food(0); return
 if m.round_no==2 and not m.has("hats"): m.research("hats"); return
 if m.workers.size()<(4 if mode=="workers" else 2): m.buy("worker"); return
 if m.cats.size()<6: m.buy("short",Vector2(520+(m.cats.size()%3)*65,510)); return
 if not m.has("sun"): m.research("sun"); return
 if m.count("sun")==0: m.buy("sun",Vector2(950,520)); return
 if m.round_no==2 and not m.has("arcade"): m.research("arcade"); return
 var arcades: int = 3 if mode=="arcade" else 2
 if m.round_no==2 and m.count("arcade")<arcades:
  m.buy("arcade",Vector2(350+m.count("arcade")*140,660)); return
 # Rotate affordable useful investments; no requirement to buy every branch.
 var options: Array=[]
 for subject in D.BRANCHES:
  if not m.has(subject):continue
  for key in D.BRANCHES[subject]:
   if key in ["food","transform","harvest_layers"]:continue
   var cost: int=m.upgrade_price(subject,key)
   if cost>0:options.append({"s":subject,"k":key,"price":cost})
 options.sort_custom(func(a,b):return a.price<b.price)
 if second%30==0 and m.cats.size()<limit:m.buy("short",Vector2(450+(m.cats.size()%4)*100,450+(m.cats.size()/4)*65));return
 if second%40==0 and m.workers.size()<5:m.buy("worker");return
 if not options.is_empty():m.upgrade(options[0].s,options[0].k)
func scenario(mode: String, seed: int, calibration: bool = false) -> Dictionary:
 var m=ReferenceModel.new() if calibration else M.new()
 m.rng.seed=seed
 var marks: Dictionary={};var sampled: Array=[9.0];var draw_times: Array=[];var decisions_log: Array=[]
 var targets: Array=[120,240,360,480,600,750,900,1050,1200,1350,1500]
 for i in range(1,25):targets.append(1500+roundi(i*87.5))
 var manual_id: int=-1;var manual_revision: int=0
 var max_seconds: int=3600 if calibration else 7200
 for second in range(1,max_seconds+1):
  var manual_goal: int=8 if mode=="layers" else (1 if mode=="single" else 6)
  for step in range(10):
   var hover_target: Dictionary=m.cat(manual_id)
   m.set_hovered_cat(manual_id if not hover_target.is_empty() and m.c_revision(hover_target)==manual_revision else -1)
   m.tick(0.1)
   if manual_id>=0:
    var target: Dictionary=m.cat(manual_id)
    if target.is_empty() or target.station!=-1 or m.c_revision(target)!=manual_revision:manual_id=-1
    else:m.pet(manual_id,20)
  for f in m.facilities:
   mark(m,marks,"first_bug",f.bugs>0)
   if second%3==0 and f.bugs>0:m.clean(f.id)
   if f.kind=="feeder" and f.grain<12:m.refill(f.id)
   if f.kind=="arcade" and m.occupants(f.id).is_empty():
    for c in m.cats:
     if c.station==-1 and c.kind!="giant":m.assign(c.id,f.id);break
  if second%3==0 and manual_id<0:
   for c in m.cats:
    if c.station==-1 and c.layers >= (1 if not m.first_token else manual_goal):
     manual_id=c.id;manual_revision=m.c_revision(c);m.set_hovered_cat(c.id);m.pet(c.id,20);break
  if second%10==0:
   m.sell_all()
   var before: float=m.wallet
   decisions(m,mode,second)
   if m.wallet<before:decisions_log.append(second)
  mark(m,marks,"first_token",m.first_token)
  if m.first_token and not m.gacha_ready:m.accept_contact()
  if calibration and sampled.size()<36 and second>=targets[sampled.size()-1]:
   sampled.append(ceilf(m.production/10)*10);m.tokens+=1;m.minted+=1
  if m.tokens>0 and not m.pool().is_empty():
   m.draw_capsule();draw_times.append(second)
  mark(m,marks,"first_worker",not m.workers.is_empty())
  for kind in ["feeder","sun","arcade"]:mark(m,marks,kind,m.count(kind)>0)
  mark(m,marks,"hats",m.has("hats"));mark(m,marks,"restock",m.round_no==2)
  mark(m,marks,"complete",m.owned.size()==36)
  m.events.clear()
  if not calibration and m.owned.size()==36:break
 return {"mode":mode,"seed":seed,"seconds":m.elapsed,"completed":m.owned.size()==36,"collection":m.owned.size(),"contribution":m.production,"marks":marks,"cats":m.cats.size(),"workers":m.workers.size(),"balance":m.wallet,"unspent_tokens":m.tokens,"draw_times":draw_times,"investments":decisions_log,"thresholds":sampled if calibration else []}
func run() -> void:
 var calibrate: bool="--calibrate" in OS.get_cmdline_user_args()
 var results: Array=[]
 if calibrate:results.append(scenario("full",2718,true))
 else:
  for mode in ["full"]:
   for seed in [2718,42,81926]:
    var result: Dictionary=scenario(mode,seed)
    results.append(result)
    print(mode," / ",seed," : ",snappedf(result.seconds/60,0.1)," min; ",result.collection," items; ",result.marks)
 var folder: String="res://reports/september23/comparison"
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
 var f:=FileAccess.open(folder+("/calibration.json" if calibrate else "/scenarios.json"),FileAccess.WRITE)
 f.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"method":"Simulation only, 0.1-second model steps: start at most one manual interaction per 3 seconds, 20 effective motion pixels per 0.1 seconds, saturating distance threshold, hover held during each manual gesture and released after settlement, paid worker thresholds, one investment per 10 seconds, sales every 10 seconds. No human time claim; no user saves. Calibration uses an offline reference schedule; shipped model only reads fixed production thresholds.","results":results},"  "));f.close()
 print("PACING FINISHED")
 quit()
