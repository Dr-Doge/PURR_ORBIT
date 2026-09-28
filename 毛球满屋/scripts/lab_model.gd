extends "res://scripts/model.gd"
## Isolated rules for IMP-20260928-004. Formal save migration is not implied.
const Personas=preload("res://scripts/cat_personas.gd")
const LAB_VERSION=1
const IDENTITY_SEED=2026092804
var initial_budget: Dictionary={}
func _init() -> void:
 initial_budget={"food_packet":D.FOOD_PRICES[0],"efficiency":upgrade_price("worker","efficiency"),"layers":upgrade_price("worker","harvest_layers"),"cooldown":upgrade_price("worker","cooldown")}
 tree=tree.duplicate(true)
 tree.erase("N11");tree.erase("N12")
 for id in tree:
  for field in ["all","any"]:
   var prerequisites: Array=[]
   for dependency in tree[id][field]:
    var replacement: String="N10" if dependency in ["N11","N12"] else dependency
    if not prerequisites.has(replacement):prerequisites.append(replacement)
   tree[id][field]=prerequisites
 tree.N10.desc="招募只负责收割的小帮手；补粮、搬猫、清虫和维修由玩家处理。"
 tree.S10.title="分组收割";tree.S10.desc="开放两组收割目标，保留已付费层数上限；不开放其他岗位。"
func used_names() -> Array:
 var names: Array=[]
 for c in cats:
  if c.has("identity"):names.append(c.identity.name)
 return names
func add_cat(at: Vector2) -> Dictionary:
 var c: Dictionary=super.add_cat(at)
 c.identity=Personas.generate(c.id,c.kind,IDENTITY_SEED+c.id,used_names())
 return c
func research_reason(key: String) -> String:
 if key in ["hats","maint"]:return "测试规则仅保留收割工人"
 return super.research_reason(key)
func set_role(id: int,role: String) -> bool:
 var w: Dictionary=worker(id)
 if w.is_empty() or role!="harvest":return fail("工人只负责收割")
 w.role="harvest";w.job={};w.clock=0.0;return true
func buy(key: String,at: Vector2=Vector2(640,540)) -> bool:
 if not super.buy(key,at):return false
 if key=="worker":workers.back().role="harvest"
 return true
func choose_job(w: Dictionary,reserved: Dictionary) -> Dictionary:
 # Enforce in execution, not only the role picker; stale jobs cannot run logistics.
 for c in cats:
  if c.station!=-1 or c.dragging or reacting(c) or c.layers<worker_target(w) or w.get("cooldown",0.0)>0:continue
  if node_owned("S10") and c.get("group",0)!=w.get("group",0):continue
  if not reserved.has("cat:"+str(c.id)):return {"kind":"harvest","target":c.id,"cat":c.id,"revision":c_revision(c)}
 return {}
func tick_worker(w: Dictionary,dt: float,reserved: Dictionary) -> void:
 w.role="harvest"
 if w.job.get("kind","harvest")!="harvest" or w.job.get("stage","")=="carry":
  for c in cats:
   if c.station==-w.id-2:move_cat(c.id,c.pos)
  w.job={};w.clock=0.0
 super.tick_worker(w,dt,reserved)
func repair(id: int,by_worker: bool=false) -> bool:
 if by_worker:return false
 return super.repair(id,false)
func snapshot() -> Dictionary:
 var result: Dictionary=super.snapshot();result["lab_rules"]=LAB_VERSION
 return result
func restore(data: Dictionary) -> bool:
 if data.get("lab_rules",0)!=LAB_VERSION:return false
 if not data.get("cats",null) is Array:return false
 var names: Dictionary={}
 for c in data.get("cats",[]):
  if c.has("identity"):
   if not Personas.valid_saved(c.identity,c.id) or names.has(c.identity.name):return false
   names[c.identity.name]=true
 # Reject incompatible test files rather than silently refund/convert formal saves.
 if data.get("researches",{}).get("hats",false) or data.get("researches",{}).get("maint",false):return false
 if not super.restore(data):return false
 for c in cats:
  if not c.has("identity"):c.identity=Personas.generate(c.id,c.kind,IDENTITY_SEED+c.id,used_names())
 for w in workers:w.role="harvest";w.job={}
 return true
func configure(setup: Node) -> void:
 cats.clear();workers.clear();facilities.clear();next_id=1
 rng.seed=20260928
 for marker in setup.get_node("Cats").get_children():
  var c: Dictionary=add_cat(marker.position)
  c.kind=marker.get_meta("kind","short");c.reaction_kind=c.kind
  c.layers=clampi(int(marker.get_meta("layers",1)),D.MIN_LAYERS,D.MAX_LAYERS)
  c.growth=float(marker.get_meta("growth",0.0));reset_activity(c);c.idle_left=2.0
 for key in ["worker","feeder","sun","arcade","altar"]:researches[key]=true
 for marker in setup.get_node("Facilities").get_children():
  var kind: String=marker.get_meta("kind")
  wallet=price(kind);buy(kind,marker.position)
  if kind=="feeder":facilities.back().grain=6
 for marker in setup.get_node("Workers").get_children():
  wallet=price("worker");buy("worker",marker.position)
 food=[40,0,0]
 # Budget is exactly one food packet and the three first worker upgrades.
 wallet=0
 for amount in initial_budget.values():wallet+=amount
 tokens=2;minted=2;first_token=true;contact_seen=true;gacha_ready=true
 # Leave a second sun and arcade empty for manual assignment.
 assign(cats[6].id,facilities[2].id)
 assign(cats[10].id,facilities[4].id)
 assign(cats[11].id,facilities[6].id)
 events.clear()

func save_to(path: String) -> Error:
 if path!="user://space_cats_lab_004.save" and not path.begins_with("res://reports/lab_004/"):return ERR_INVALID_PARAMETER
 return super.save_to(path)
func load_from(path: String) -> bool:
 if path!="user://space_cats_lab_004.save" and not path.begins_with("res://reports/lab_004/"):return false
 return super.load_from(path)
