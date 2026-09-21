extends RefCounted
const D = preload("res://scripts/data.gd")
const SAVE_VERSION = 27
const B = preload("res://scripts/balance.gd")
const FIELDS = ["round_no","wallet","tokens","food","cats","workers","facilities","researches","levels","inventory","owned","next_id","elapsed","round_elapsed","grown_total","token_progress","production","minted","first_token","contact_seen","gacha_ready","harvest_target","interference","harvests"]
var round_no: int = 1
var wallet: float = 0.0
var tokens: int = 0
var food: Array = [20,0,0]
var cats: Array = []
var workers: Array = []
var facilities: Array = []
var researches: Dictionary = {}
var levels: Dictionary = {}
var inventory: Array = []
var owned: Array = []
var next_id: int = 1
var elapsed: float = 0.0
var round_elapsed: float = 0.0
var grown_total: int = 0
var token_progress: int = 0
var production: float = 0.0
var minted: int = 0
var first_token: bool = false
var contact_seen: bool = false
var gacha_ready: bool = false
var harvest_target: int = 6
var interference: float = 0.0
var harvests: int = 0
var events: Array = []
var error: String = ""
var rng := RandomNumberGenerator.new()
func _init() -> void:
 rng.randomize()
 add_cat(Vector2(565,465))
 add_cat(Vector2(735,505))
 cats[0].layers = 1
func uid() -> int:
 var value: int = next_id
 next_id += 1
 return value
func notify(message: String) -> void:
 events.append({"kind":"notice","text":message})
func fail(message: String) -> bool:
 error = message
 return false
func cat(id: int) -> Dictionary:
 for c in cats:
  if c.id == id: return c
 return {}
func facility(id: int) -> Dictionary:
 for f in facilities:
  if f.id == id: return f
 return {}
func worker(id: int) -> Dictionary:
 for w in workers:
  if w.id == id: return w
 return {}
func lv(subject: String,key: String) -> int:
 return int(levels.get(subject+":"+key,0))
func has(key: String) -> bool:
 return bool(researches.get(key,false)) and round_no >= D.gate(key)
func count(kind: String) -> int:
 if kind == "short": return cats.size()
 if kind == "worker": return workers.size()
 var value: int = 0
 for f in facilities:
  if f.kind == kind: value += 1
 return value
func effect(key: String) -> float:
 var result: float = 1.0
 for s in D.SERIES:
  if s.effect == key:
   for i in range(D.SERIES_SIZE):
    if owned.has(s.id+":"+str(i)): result += float(s.full)/D.SERIES_SIZE
 return result
func add_cat(at: Vector2) -> Dictionary:
 # Legacy wander remains in the save schema, but no longer acts as a movement timer.
 var c: Dictionary = {"id":uid(),"kind":"short","pos":at,"dest":at,"layers":0,"growth":0.0,"pet":0.0,"station":-1,"timer":0.0,"fed":0.0,"food_kind":0,"pop":0.0,"wander":0.0,"color":cats.size()%3,"dragging":false}
 cats.append(c)
 return c
func clamp_position(at: Vector2) -> Vector2:
 return at.clamp(D.FLOOR.position+Vector2(35,30),D.FLOOR.end-Vector2(35,25))
func price(key: String) -> int:
 return ceili(float(D.PRICES.get(key,0))*pow(float(B.PRICE_GROWTH.get(key,1.65)),maxi(0,count(key)-(2 if key == "short" else 0))))
func spend(amount: float) -> bool:
 if wallet+0.001 < amount: return fail("还差 %d 毛球" % ceili(amount-wallet))
 wallet = maxf(0.0,wallet-amount)
 error = ""
 return true
func research_reason(key: String) -> String:
 if not D.RESEARCH.has(key): return "未知研究"
 if D.gate(key) > D.MAX_STAGE: return "后续内容，当前驻留暂未开放"
 if round_no < D.gate(key): return "第 %d 阶段开放" % D.gate(key)
 if has(key): return "已经解锁"
 for pre in D.RESEARCH[key].pre:
  if not has(pre): return "先解锁"+D.title(pre)
 return ""
func research(key: String) -> bool:
 var why: String = research_reason(key)
 if why != "": return fail(why)
 if not spend(float(D.RESEARCH[key].price)): return false
 researches[key] = true
 notify("已解锁"+D.title(key)+( "，在商店购买并摆放" if key in D.PRICES else ""))
 return true
func buy_reason(key: String) -> String:
 if not D.PRICES.has(key): return "特殊猫只能通过设施转化"
 if D.gate(key) > D.MAX_STAGE: return "后续内容，当前驻留暂未开放"
 if round_no < D.gate(key): return "第 %d 阶段开放" % D.gate(key)
 if key != "short" and not has(key): return "先在升级树解锁"+D.title(key)
 return ""
func buy(key: String,at: Vector2 = Vector2(640,540)) -> bool:
 var why: String = buy_reason(key)
 if why != "": return fail(why)
 if not spend(price(key)): return false
 at = clamp_position(at)
 if key == "short": add_cat(at)
 elif key == "worker": workers.append({"id":uid(),"pos":at,"role":"general","job":{},"clock":0.0,"status":"寻找工作"})
 else: facilities.append({"id":uid(),"kind":key,"pos":at,"grain":0,"food_kind":0,"pulse":0.0,"neglect":0.0,"bugs":0,"hits":0,"broken":false})
 notify(D.title(key)+"已就位")
 return true
func upgrade_price(subject: String,key: String) -> int:
 if not D.BRANCHES.get(subject,{}).has(key): return -1
 var spec: Array = D.BRANCHES[subject][key]
 return -1 if lv(subject,key) >= int(spec[2]) else ceili(float(spec[1])*pow(B.BRANCH_GROWTH,lv(subject,key)))
func upgrade(subject: String,key: String) -> bool:
 if not has(subject): return fail("先解锁该设施，且需达到开放阶段")
 var cost: int = upgrade_price(subject,key)
 if cost < 0: return fail("该项已满级")
 if not spend(cost): return false
 levels[subject+":"+key] = lv(subject,key)+1
 return true
func buy_food(kind: int,batches: int = 1) -> bool:
 if batches<1 or batches>10:return fail("请选择1—10包猫粮")
 if kind < 0 or kind > lv("feeder","food") or kind > 2 or not has("feeder"): return fail("先解锁对应猫粮")
 if not spend(D.FOOD_PRICES[kind]*batches): return false
 food[kind] += B.FOOD_BATCH*batches
 return true
func refill(id: int,kind: int = 0) -> bool:
 var f: Dictionary = facility(id)
 if f.is_empty() or f.kind != "feeder" or kind < 0 or kind > lv("feeder","food") or kind > 2: return fail("无法补充这类猫粮")
 if f.grain > 0 and f.food_kind != kind: return fail("等待当前猫粮用完再更换")
 var amount: int = mini(int(food[kind]),feed_capacity()-int(f.grain))
 if amount <= 0: return fail("库存缺粮或料仓已满")
 food[kind] -= amount
 f.grain += amount
 f.food_kind = kind
 return true
func clean(id: int) -> bool:
 var f: Dictionary = facility(id)
 if f.is_empty() or f.kind != "feeder" or f.bugs <= 0: return false
 f.hits += 1
 if f.hits >= B.BUG_HITS:
  f.bugs -= 1
  f.hits = 0
 if f.bugs == 0: f.neglect = 0.0; notify("喂食器清理完成，恢复增产")
 return true
func repair(id: int,by_worker: bool = false) -> bool:
 var f: Dictionary = facility(id)
 if f.is_empty() or not f.broken: return false
 if by_worker and not has("maint"): return false
 f.hits += 1
 events.append({"kind":"hit","pos":f.pos})
 if f.hits >= 6: f.broken = false; f.hits = 0; notify("画面回来了，娱乐设施重新运行")
 return true
func feed_capacity() -> int:
 return B.FEED_CAPACITY+B.FEED_CAPACITY_STEP*lv("feeder","capacity")
func work_speed() -> float:
 return effect("work")*(1+B.WORK_STEP*lv("worker","efficiency"))
func capacity(f: Dictionary) -> int:
 return (2+lv(f.kind,"capacity")) if f.kind in ["sun","altar"] else 1
func occupants(id: int) -> Array:
 var result: Array = []
 for c in cats:
  if c.station == id: result.append(c)
 return result
func move_cat(id: int,at: Vector2) -> void:
 var c: Dictionary = cat(id)
 if c.is_empty(): return
 c.station = -1; c.timer = 0.0; c.pet = 0.0
 c.pos = clamp_position(at); c.dest = c.pos; c.dragging = false
func assign(id: int,target_id: int) -> bool:
 var c: Dictionary = cat(id); var f: Dictionary = facility(target_id)
 if c.is_empty() or f.is_empty() or f.kind not in ["sun","arcade","altar"]: return fail("这里不能指派猫")
 if occupants(f.id).size() >= capacity(f): return fail("设施位置已满")
 if f.kind == "sun" and c.layers >= D.MAX_LAYERS: return fail("这只猫的毛层已满，先收割")
 c.station = f.id; c.timer = 0.0; c.pet = 0.0; c.dragging = false
 c.pos = f.pos+Vector2(-25+occupants(f.id).size()*22,35); c.dest = c.pos
 return true
func altar_speed() -> float:
 var amount: int = 0
 for f in facilities:
  if f.kind == "altar": amount += occupants(f.id).size()
 return 1.0+amount*(0.18+0.08*lv("altar","speed"))
func growth_speed(c: Dictionary) -> float:
 var local: float = 1.0
 for other in cats:
  if other.id != c.id and other.kind == "alien" and other.pos.distance_to(c.pos) <= 180: local = 1.35
 return effect("speed")*altar_speed()*local
func layer(c: Dictionary) -> void:
 if c.layers >= D.MAX_LAYERS: return
 c.layers += 1; c.pop = D.CAT_PULSE_DURATION; grown_total += 1
func multiplier(c: Dictionary) -> float:
 var m: float = effect("yield")
 if c.kind == "giant": m *= B.GIANT_FED if c.fed > 0 else B.GIANT_HUNGRY
 if c.fed > 0: m *= B.FOOD_MULT[int(c.food_kind)]
 for f in facilities:
  if f.kind == "feeder" and f.bugs > 0 and f.pos.distance_to(c.pos) < B.FEED_RADIUS: return effect("yield")*(B.GIANT_HUNGRY if c.kind == "giant" else 1.0)*B.BUG_MULT
 return m
func harvest_value(c: Dictionary) -> float:
 var n: int = c.layers
 return snappedf(B.BASE_YIELD*multiplier(c)*(n+0.5*B.STACK_BONUS*n*(n-1)),0.1)
func pet(id: int,distance: float) -> void:
 var c: Dictionary = cat(id)
 if c.is_empty() or c.station != -1 or c.layers <= 0 or c.dragging: return
 c.pet += clampf(distance,0,45)
 if c.pet >= D.PET_DISTANCE: harvest(id)
func money(amount: float,at: Vector2) -> void:
 wallet += amount
 events.append({"kind":"money","pos":at,"text":"+%.1f" % amount})
func prize(c: Dictionary,value: float) -> void:
 var item: Dictionary = {"id":uid(),"name":D.ITEMS[rng.randi_range(0,D.ITEMS.size()-1)],"value":value}
 inventory.append(item)
 events.append({"kind":"prize","pos":c.pos,"text":item.name})
func coin_bonus(c: Dictionary) -> void:
 if c.kind != "lucky": return
 var heads: bool = rng.randf() < B.LUCKY_CHANCE
 events.append({"kind":"coin","pos":c.pos,"text":"正面 · 额外道具" if heads else "反面 · 原奖励保留"})
 if heads: prize(c,B.LUCKY_VALUE)
func harvest(id: int) -> bool:
 var c: Dictionary = cat(id)
 if c.is_empty() or c.station != -1 or c.layers <= 0: return false
 var n: int = c.layers
 var output: float = harvest_value(c)
 money(output,c.pos)
 c.layers = 0; c.pet = 0.0; c.pop = D.CAT_PULSE_DURATION; harvests += 1
 token_progress += n
 contribute(output,c.pos)
 coin_bonus(c)
 if c.kind == "static":
  events.append({"kind":"ring","pos":c.pos,"radius":B.STATIC_RADIUS})
  for other in cats:
   if other.id != c.id and other.station == -1 and other.pos.distance_to(c.pos) < B.STATIC_RADIUS:
    # A separate one-layer reward preserves stored fur; it cannot chain or mint tokens.
    money(B.BASE_YIELD*multiplier(other),other.pos)
 return true
func contribute(amount: float,at: Vector2 = Vector2.ZERO) -> void:
 # Only primary harvest output and main arcade prizes call this. Sales/bonus rewards never do.
 if amount <= 0 or not is_finite(amount): return
 production += amount
 if not first_token and token_progress >= B.FIRST_TOKEN_LAYERS:
  first_token = true; minted = 1; tokens += 1
  notify("猫咪留下了一枚陌生的代币。远处传来一个信号……")
 if not first_token: return
 while minted < B.TOKEN_THRESHOLDS.size() and production >= B.TOKEN_THRESHOLDS[minted]:
  minted += 1; tokens += 1
  events.append({"kind":"token","pos":at,"text":"+1 神秘代币"})
func signal_progress() -> float:
 if not first_token: return clampf(float(token_progress)/B.FIRST_TOKEN_LAYERS,0,1)
 if minted >= B.TOKEN_THRESHOLDS.size(): return 1.0
 var start: float = B.TOKEN_THRESHOLDS[minted-1]
 return clampf((production-start)/(B.TOKEN_THRESHOLDS[minted]-start),0,1)
func try_transform(c: Dictionary,kind: String,source: String) -> void:
 if c.kind != "short": return
 if rng.randf() < B.TRANSFORM_BASE+B.TRANSFORM_STEP*lv(source,"transform"):
  c.kind = kind; c.pop = D.CAT_PULSE_DURATION
  notify("一只猫变成了"+D.title(kind)+"！")
  events.append({"kind":"transform","pos":c.pos,"text":D.title(kind)})
func tick(dt: float) -> void:
 if dt <= 0 or not is_finite(dt): return
 elapsed += dt; round_elapsed += dt
 for f in facilities:
  if f.kind != "feeder": continue
  if round_no >= 2 and count("sun") > 0:
   f.neglect += dt
   if f.neglect >= D.BUG_TIME and f.bugs == 0:
    f.bugs = B.BUG_COUNT; f.hits = 0; notify("喂食器里有偷渡客！打开设备清理蟑螂")
  f.pulse -= dt
  if f.pulse <= 0:
   f.pulse = B.FEED_PERIOD
   for c in cats:
    if f.grain <= 0: break
    if c.pos.distance_to(f.pos) > B.FEED_RADIUS or c.station >= 0: continue
    f.grain -= 1; c.fed = B.FEED_DURATION; c.food_kind = f.food_kind
    try_transform(c,"giant","feeder")
    if c.kind == "giant" and f.bugs > 0:
     f.bugs -= 1
     if f.bugs == 0: f.neglect = 0.0
 if round_no >= 3 and count("altar") > 0:
  interference += dt
  if interference >= D.INTERFERENCE_TIME:
   interference = 0.0
   for f in facilities:
    if f.kind == "arcade" and not f.broken:
     f.broken = true; f.hits = 0; notify("未知信号干扰了娱乐设施，捶打屏幕试试")
     break
 for c in cats:
  if c.station < -1: continue # A worker is carrying this cat.
  c.pop = maxf(0,c.pop-dt); c.fed = maxf(0,c.fed-dt)
  if c.dragging: continue
  var station: Dictionary = facility(c.station)
  if not station.is_empty():
   if station.kind == "sun":
    c.timer += dt*growth_speed(c)*(1+B.SUN_SPEED_STEP*lv("sun","time"))
    if c.timer >= B.SUN_TIME:
     layer(c); c.growth = 0.0; try_transform(c,"static","sun")
     move_cat(c.id,station.pos+Vector2(rng.randf_range(-120,120),95))
   elif station.kind == "arcade":
    if station.broken: continue
    c.timer += dt*altar_speed()
    if c.timer >= B.ENT_TIME/(1+B.ENT_SPEED_STEP*lv("arcade","time")):
     c.timer = 0.0
     if rng.randf() < minf(0.9,B.ENT_WIN+B.ENT_WIN_STEP*lv("arcade","win")):
      var value: float = B.ENT_VALUE*(1+B.ENT_VALUE_STEP*lv("arcade","value"))
      prize(c,value); contribute(value,c.pos); coin_bonus(c)
     try_transform(c,"lucky","arcade")
   elif station.kind == "altar":
    c.timer += dt
    if c.timer >= 10.0: c.timer = 0.0; try_transform(c,"alien","altar")
   continue
  c.growth += dt*growth_speed(c)
  while c.growth >= D.LAYER_CD:
   c.growth -= D.LAYER_CD; layer(c)
  if c.pos.distance_to(c.dest) <= 1.0:
   # Reaching a destination, not a cooldown or harvest, chooses the next walk.
   var direction := Vector2.from_angle(rng.randf_range(0,TAU))
   c.dest = clamp_position(c.pos+direction*rng.randf_range(45,90))
   if c.pos.distance_to(c.dest) < 8.0:
    c.dest = clamp_position(c.pos-direction*60.0)
  c.pos = c.pos.move_toward(c.dest,D.CAT_MOVE_SPEED*dt)
 var reserved: Dictionary = {}
 for w in workers:
  if not w.job.is_empty(): reserved[job_key(w.job)] = true
 for w in workers: tick_worker(w,dt,reserved)
func set_role(id: int,role: String) -> bool:
 var w: Dictionary = worker(id)
 if w.is_empty() or not D.ROLES.has(role): return false
 if role != "general" and not has("hats"): return fail("先解锁职责分配帽")
 if role == "repair" and not has("maint"): return fail("先解锁工人维护")
 if role in ["sun","arcade","altar"] and not has(role): return fail("先研发对应设施")
 if role == "clean" and round_no < 2: return fail("第二阶段才会出现虫害")
 if not w.job.is_empty() and w.job.get("stage","") == "carry":
  var carried: Dictionary = cat(w.job.cat)
  if not carried.is_empty(): move_cat(carried.id,carried.pos)
 w.role = role; w.job = {}; w.clock = 0.0
 return true
func job_key(job: Dictionary) -> String:
 return ("cat:" if job.cat >= 0 else str(job.kind)+":")+str(job.target)
func choose_job(w: Dictionary,reserved: Dictionary) -> Dictionary:
 var roles: Array = ["repair","clean","refill","harvest","sun"] if w.role == "general" else [w.role]
 for role in roles:
  if role == "repair" and not has("maint"): continue
  if role in ["repair","clean","refill"]:
   for f in facilities:
    var valid: bool = (role == "repair" and f.broken) or (role == "clean" and f.bugs > 0) or (role == "refill" and f.kind == "feeder" and f.grain <= B.REFILL_THRESHOLD and food[int(f.food_kind)] > 0)
    var key: String = role+":"+str(f.id)
    if valid and not reserved.has(key): return {"kind":role,"target":f.id,"cat":-1}
  else:
   for c in cats:
    if c.station != -1 or c.dragging: continue
    var key: String = "cat:"+str(c.id)
    if reserved.has(key): continue
    if role == "harvest" and c.layers >= harvest_target: return {"kind":role,"target":c.id,"cat":c.id}
    if role in ["sun","arcade","altar"] and (role != "sun" or c.layers == 0):
     for f in facilities:
      if f.kind == role and occupants(f.id).size() < capacity(f): return {"kind":role,"target":c.id,"cat":c.id,"facility":f.id}
 return {}
func tick_worker(w: Dictionary,dt: float,reserved: Dictionary) -> void:
 if w.job.is_empty():
  w.job = choose_job(w,reserved); w.clock = 0.0
  if w.job.is_empty():
   w.status = "缺粮" if w.role in ["general","refill"] and count("feeder") > 0 and int(food[0])+int(food[1])+int(food[2]) == 0 else "待命"
   return
  reserved[job_key(w.job)] = true
 var job: Dictionary = w.job
 var target: Dictionary = cat(job.target) if job.cat >= 0 else facility(job.target)
 if target.is_empty() or (job.cat >= 0 and (target.dragging or (target.station != -1 and target.station != -w.id-2))):
  w.job = {}; return
 if job.get("stage","") == "carry":
  if target.station != -w.id-2: w.job = {}; return
  var destination: Dictionary = facility(job.facility)
  if destination.is_empty(): move_cat(target.id,w.pos); w.job = {}; return
  w.pos = w.pos.move_toward(destination.pos,B.WORK_SPEED*work_speed()*(1+B.CARRY_STEP*lv("worker","carry"))*dt)
  target.pos = w.pos+Vector2(0,-20); target.dest = target.pos
  if w.pos.distance_to(destination.pos) < B.WORK_REACH:
   move_cat(target.id,w.pos)
   assign(target.id,destination.id)
   w.job = {}
  return
 w.status = D.ROLES.get(job.kind,job.kind)
 var dest: Vector2 = target.pos
 if w.pos.distance_to(dest) > B.WORK_REACH:
  w.pos = w.pos.move_toward(dest,B.WORK_SPEED*work_speed()*dt); return
 w.clock += dt*work_speed()
 if w.clock < (B.WORK_HARVEST if job.kind == "harvest" else B.WORK_ACTION): return
 w.clock = 0.0
 match job.kind:
  "harvest": harvest(target.id)
  "refill": refill(target.id,target.food_kind)
  "clean": clean(target.id)
  "repair": repair(target.id,true)
  _:
   w.job.stage = "carry"; target.station = -w.id-2; w.status = "搬运中"
   return
 w.job = {}
func accept_contact() -> bool:
 if not first_token: return false
 contact_seen = true; gacha_ready = true
 return true
func pool() -> Array:
 var result: Array = []
 for s in D.SERIES:
  if int(s.round) != round_no: continue
  for i in range(D.SERIES_SIZE):
   var key: String = s.id+":"+str(i)
   if not owned.has(key): result.append(key)
 return result
func draw_capsule() -> String:
 if not gacha_ready: fail("先回应神秘信号"); return ""
 var remaining: Array = pool()
 if remaining.is_empty(): fail("本频段已经没有新的回声"); return ""
 if tokens < B.DRAW_COST: fail("需要一枚神秘代币"); return ""
 var key: String = remaining[rng.randi_range(0,remaining.size()-1)]
 tokens -= B.DRAW_COST; owned.append(key)
 if round_no == 1 and pool().is_empty(): advance_stage()
 return key
func advance_stage() -> bool:
 if round_no >= D.MAX_STAGE: return fail("这段信号已收集完成，可以继续经营")
 if not pool().is_empty(): return fail("仪器中仍有未回应的信号")
 round_no = 2
 # New risk starts here; every existing production/job timer remains untouched.
 for f in facilities:
  if f.kind == "feeder": f.neglect = 0.0
 notify("仪器收到新的信号：24个新回声已抵达，舱室补给也更新了。")
 return true
func sell_all() -> float:
 var total: float = 0.0
 for item in inventory: total += float(item.value)*effect("sale")
 wallet += total; inventory.clear()
 return total
func snapshot() -> Dictionary:
 var data: Dictionary = {"version":SAVE_VERSION,"rng":rng.state}
 for field in FIELDS: data[field] = get(field)
 return data.duplicate(true)
func numeric_fields(record: Dictionary,fields: Array) -> bool:
 for key in fields:
  if not record.has(key) or typeof(record[key]) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(record[key])):return false
 return true
func restore(data: Dictionary) -> bool:
 if data.get("version",0) != SAVE_VERSION or not data.has("rng") or not data.rng is int: return false
 for key in FIELDS:
  if not data.has(key) or typeof(data[key]) != typeof(get(key)): return false
 if data.round_no < 1 or data.round_no > D.MAX_STAGE or data.wallet < 0 or not is_finite(data.wallet) or data.tokens < 0 or data.cats.is_empty() or data.food.size()!=3: return false
 if data.harvest_target < 1 or data.harvest_target > D.MAX_LAYERS: return false
 for value in data.food:
  if not value is int or value<0:return false
 if not numeric_fields(data,["elapsed","round_elapsed","grown_total","token_progress","production","minted","next_id","interference","harvests"]):return false
 if data.elapsed<0 or data.round_elapsed<0 or data.token_progress<0 or data.production<0 or data.minted<0 or data.minted>36:return false
 var ids: Dictionary = {}
 var station_ids: Dictionary = {}
 for c in data.cats:
  if not c is Dictionary or not c.has_all(["id","kind","pos","dest","layers","growth","pet","station","timer","fed","food_kind","pop","wander","color","dragging"]): return false
  if not numeric_fields(c,["id","layers","growth","pet","station","timer","fed","food_kind","pop","wander","color"]):return false
  if c.kind not in ["short","giant","static","lucky"] or not c.pos is Vector2 or not c.dest is Vector2 or c.layers < 0 or c.layers > D.MAX_LAYERS or ids.has(c.id): return false
  if c.color<0 or c.color>2 or c.food_kind<0 or c.food_kind>2 or not c.pos.is_finite() or not c.dest.is_finite():return false
  ids[c.id] = true
 for f in data.facilities:
  if not f is Dictionary or not f.has_all(["id","kind","pos","grain","food_kind","pulse","neglect","bugs","hits","broken"]): return false
  if not numeric_fields(f,["id","grain","food_kind","pulse","neglect","bugs","hits"]) or not f.broken is bool:return false
  if f.kind not in ["feeder","sun","arcade"] or D.gate(f.kind) > data.round_no or not f.pos is Vector2 or ids.has(f.id): return false
  if f.food_kind<0 or f.food_kind>2 or f.grain<0 or f.grain>B.FEED_CAPACITY+B.FEED_CAPACITY_STEP*int(data.levels.get("feeder:capacity",0)) or f.bugs<0 or not f.pos.is_finite():return false
  ids[f.id] = true;station_ids[f.id]=true
 for w in data.workers:
  if not w is Dictionary or not w.has_all(["id","pos","role","job","clock","status"]) or not w.pos is Vector2 or not D.ROLES.has(w.role) or ids.has(w.id): return false
  if not numeric_fields(w,["id","clock"]) or not w.job is Dictionary or not w.status is String or not w.pos.is_finite():return false
  ids[w.id] = true
 for c in data.cats:
  if c.station>=0 and not station_ids.has(c.station):return false
 for item in data.inventory:
  if not item is Dictionary or not item.has_all(["id","name","value"]) or not numeric_fields(item,["id","value"]) or not item.name is String or item.value<0 or ids.has(item.id):return false
  ids[item.id]=true
 for id in ids:
  if id<1 or data.next_id<=id:return false
 for key in data.levels:
  if not key is String or not data.levels[key] is int:return false
  var parts: PackedStringArray=key.split(":")
  if parts.size()!=2 or not D.BRANCHES.get(parts[0],{}).has(parts[1]):return false
  if not data.researches.get(parts[0],false) or data.levels[key]<0 or data.levels[key]>D.BRANCHES[parts[0]][parts[1]][2]:return false
 var seen: Dictionary = {}
 for key in data.owned:
  var known: bool = false
  for s in D.SERIES:
   for i in range(D.SERIES_SIZE):
    if key == s.id+":"+str(i) and int(s.round) <= data.round_no: known = true
  if not known or seen.has(key): return false
  seen[key] = true
 for key in data.researches:
  if not D.RESEARCH.has(key) or D.gate(key) > data.round_no: return false
 if data.round_no == 2:
  for series in D.SERIES:
   if series.round == 1:
    for i in range(D.SERIES_SIZE):
     if not data.owned.has(series.id+":"+str(i)): return false
 for field in FIELDS:
  var value = data[field]
  set(field,value.duplicate(true) if value is Array or value is Dictionary else value)
 for c in cats:
  c.dragging = false
  if c.station < -1: c.station = -1
 for w in workers: w.job = {}; w.clock = 0.0
 rng.state = int(data.rng); events.clear()
 return true
func save_to(path: String) -> Error:
 var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
 if file == null: return FileAccess.get_open_error()
 file.store_var(snapshot()); file.close()
 if FileAccess.file_exists(path):
  var copy_err: Error = DirAccess.copy_absolute(path,path+".bak")
  if copy_err != OK: return copy_err
 return DirAccess.rename_absolute(path+".tmp",path)
func load_from(path: String) -> bool:
 if not FileAccess.file_exists(path): return false
 var file := FileAccess.open(path,FileAccess.READ)
 if file == null: return false
 var saved = file.get_var(false)
 return restore(saved) if saved is Dictionary else false
