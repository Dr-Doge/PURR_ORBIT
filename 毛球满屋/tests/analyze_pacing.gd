extends SceneTree
const M = preload("res://scripts/model.gd")
const D = preload("res://scripts/data.gd")
class AuditModel extends M:
 var cost_factor: float = 1.0
 var earned: float = 0.0
 var spent: float = 0.0
 func spend(amount: float) -> bool:
  var price: float=amount*cost_factor
  var ok: bool=super.spend(price)
  if ok:spent+=price
  return ok
 func money(amount: float,at: Vector2) -> void:
  super.money(amount,at);earned+=amount
 func sell_all() -> float:
  var amount: float=super.sell_all();earned+=amount;return amount
func _initialize() -> void:call_deferred("run")
func record(m,marks: Dictionary,key: String,valid: bool) -> void:
 if valid and not marks.has(key):marks[key]=snappedf(m.round_elapsed,0.1)
func run() -> void:
 var results: Array=[]
 var plans: Array=[
  {"name":"full_route_true_end","mode":"full","showcase":false,"cost":1.0,"cat_target":6,"layers":3},
  {"name":"old_showcase_test","mode":"full","showcase":true,"cost":1.0,"cat_target":6,"layers":3},
  {"name":"no_purchases","mode":"none","showcase":false,"cost":1.0,"cat_target":2,"layers":3},
  {"name":"only_buy_cats","mode":"cats","showcase":false,"cost":1.0,"cat_target":12,"layers":3},
  {"name":"all_prices_x16","mode":"full","showcase":false,"cost":16.0,"cat_target":6,"layers":3},
  {"name":"eight_layer_harvest","mode":"full","showcase":false,"cost":1.0,"cat_target":6,"layers":8}]
 for plan in plans:
  for seed in [81926,2718,42]:
   var m=AuditModel.new();m.rng.seed=seed;m.cost_factor=plan.cost
   var runs: Array=[]
   for round_no in range(1,4):
    m.harvest_target=plan.layers;m.earned=0;m.spent=0
    var marks: Dictionary={};var completed: bool=false
    for second in range(1800):
     for i in range(10):m.tick(0.1)
     for f in m.facilities:
      record(m,marks,"first_bug",f.bugs>0);record(m,marks,"first_blackscreen",f.broken)
     # Finite active input budget: at most one manual cat harvest per second.
     for c in m.cats:
      if c.station==-1 and c.layers>=plan.layers:m.harvest(c.id);break
     m.sell_all()
     record(m,marks,"first_token",m.first_token)
     if m.first_token and not m.gacha_ready:m.accept_contact()
     while m.tokens>0 and not m.pool().is_empty():m.draw_capsule()
     if plan.mode=="cats":
      if m.cats.size()<plan.cat_target:m.buy("short",Vector2(430+(m.cats.size()%3)*95,480+(m.cats.size()/3)*55))
     elif plan.mode=="full":
      if not m.has("worker"):m.research("worker")
      elif m.workers.size()<1:m.buy("worker",Vector2(610,540))
      elif m.cats.size()<plan.cat_target:m.buy("short",Vector2(430+(m.cats.size()%3)*95,480+(m.cats.size()/3)*55))
      elif not m.has("feeder"):m.research("feeder")
      elif m.count("feeder")==0:m.buy("feeder",Vector2(550,490))
      elif not m.has("sun"):m.research("sun")
      elif m.count("sun")==0:m.buy("sun",Vector2(900,480))
      elif round_no>=2 and not m.has("hats"):m.research("hats")
      elif round_no>=2 and not m.has("arcade"):m.research("arcade")
      elif round_no>=2 and m.count("arcade")==0:m.buy("arcade",Vector2(740,660))
      elif round_no>=3 and not m.has("altar"):m.research("altar")
      elif round_no>=3 and m.count("altar")==0:m.buy("altar",Vector2(1150,600))
      elif round_no>=3 and not m.has("maint"):m.research("maint")
      elif m.workers.size()<3:m.buy("worker",Vector2(630,590))
      if m.has("feeder") and m.food[0]<6:m.buy_food(0)
      for f in m.facilities:
       if f.kind=="feeder" and f.grain<5:m.refill(f.id)
       if f.bugs>0:m.clean(f.id)
       if f.broken:m.repair(f.id)
       if f.kind in ["arcade","altar"] and m.occupants(f.id).is_empty():
        for c in m.cats:
         if c.station==-1:m.assign(c.id,f.id);break
     record(m,marks,"first_worker",m.workers.size()>0)
     for key in ["feeder","sun","arcade","altar"]:record(m,marks,"first_"+key,m.count(key)>0)
     record(m,marks,"hats",m.has("hats"));record(m,marks,"maintenance",m.has("maint"))
     record(m,marks,"pool_empty",m.pool().is_empty())
     m.events.clear()
     var content: bool=m.count("sun")>0 and (round_no<2 or m.count("arcade")>0) and (round_no<3 or (m.count("altar")>0 and m.has("maint")))
     if m.pool().is_empty() and (not plan.showcase or content):completed=true;break
    runs.append({"round":round_no,"seconds":snappedf(m.round_elapsed,0.1),"completed":completed,"cats":m.cats.size(),"workers":m.workers.size(),"research":m.researches.keys(),"marks":marks,"earned":snappedf(m.earned,0.1),"spent":snappedf(m.spent,0.1),"balance":snappedf(m.wallet,0.1)})
    if round_no<3 and not m.advance_round():break
   results.append({"plan":plan,"seed":seed,"runs":runs})
 var path: String="res://reports/pacing_2h/current_audit.json"
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/pacing_2h"))
 var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"method":"One manual harvest per second, simulated decisions, no user saves. Models are diagnostic, not human-play timings.","results":results},"  "));f.close()
 print("PACING AUDIT: ",results.size()," scenarios saved to ",path)
 quit()
