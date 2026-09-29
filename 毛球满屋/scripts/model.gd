extends RefCounted
const D = preload("res://scripts/data.gd")
const A = preload("res://scripts/cat_animation_data.gd")
const GROOM_FRAMES = preload("res://Art/cat1new_animations.tres")
const T=preload("res://scripts/tree_specs.gd")
const Build=preload("res://scripts/build_rules.gd")
const Space=preload("res://scripts/cat_space.gd")
var tree: Dictionary=T.nodes()
var nodes_owned: Dictionary={}
var build_state: Dictionary={}
var group_settings: Array=[{"target":1,"rounds":0},{"target":1,"rounds":0},{"target":1,"rounds":0}]
var orders: Array=[]
const SAVE_VERSION = 27
const B = preload("res://scripts/balance.gd")
const FIELDS = ["nodes_owned","build_state","group_settings","orders","round_no","wallet","tokens","food","cats","workers","facilities","researches","levels","inventory","owned","next_id","elapsed","round_elapsed","grown_total","token_progress","production","minted","first_token","contact_seen","gacha_ready","harvest_target","interference","harvests"]
var cat_overlap_times: Dictionary = {} # Pairwise continuous overlap; transient.
var cat_escape_targets: Dictionary = {} # Stable walking destinations, never saved.
var motion_tick: int = 0
var cat_displacements: Dictionary = {} # Last simulation step; visual telemetry only, never saved.
var hovered_cat_id: int = -1 # Transient input; intentionally absent from FIELDS/saves.
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
var harvest_target: int = 1 # Save compatibility only; runtime target comes from paid levels.
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
 return bool(researches.get(key,false))
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
 var c: Dictionary = {"id":uid(),"kind":"short","pos":at,"dest":at,"layers":1,"harvest_revision":0,"reaction_left":0.0,"reaction_kind":"short","pet_stamp":-1.0,"growth":0.0,"pet":0.0,"station":-1,"timer":0.0,"fed":0.0,"food_kind":0,"pop":0.0,"wander":0.0,"color":cats.size()%3,"dragging":false}
 c["variant"]=c.id%4;c["group"]=0;c["charges"]=[];c["ent_rounds"]=0;c["entry_bonus"]=0;c["use_boost"]=false
 c.pos=Space.place(self,c,at);c.dest=c.pos
 cats.append(c)
 return c
func clamp_position(at: Vector2) -> Vector2:
 return at.clamp(D.FLOOR.position+Vector2(35,30),D.FLOOR.end-Vector2(35,25))
func price(key: String) -> int:
 return ceili(B.ECONOMY_COST_SCALE*float(D.PRICES.get(key,0))*pow(float(B.PRICE_GROWTH.get(key,1.65)),maxi(0,count(key)-(2 if key == "short" else 0))))
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
 if not spend(ceili(float(D.RESEARCH[key].price)*B.ECONOMY_COST_SCALE-0.000001)): return false
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
 elif key == "worker": workers.append({"id":uid(),"pos":at,"role":"general","job":{},"clock":0.0,"cooldown":0.0,"status":"寻找工作"})
 else: facilities.append({"id":uid(),"kind":key,"pos":at,"grain":0,"food_kind":0,"pulse":0.0,"neglect":0.0,"bugs":0,"hits":0,"broken":false})
 notify(D.title(key)+"已就位")
 return true
func upgrade_price(subject: String,key: String) -> int:
 if not D.BRANCHES.get(subject,{}).has(key): return -1
 var spec: Array = D.BRANCHES[subject][key]
 return -1 if lv(subject,key) >= int(spec[2]) else ceili(ceili(float(spec[1])*pow(B.BRANCH_GROWTH,lv(subject,key)))*B.ECONOMY_COST_SCALE-0.000001)
func upgrade(subject: String,key: String) -> bool:
 if not has(subject): return fail("先解锁该设施")
 var segment: int=T.level_segment(subject,key,lv(subject,key)+1)
 if segment>1 and not node_owned("S10" if segment==2 else "S20"):return fail("先购买分组照料" if segment==2 else "先购买流程复盘")
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
 if f.hits >= B.REPAIR_HITS: f.broken = false; f.hits = 0; notify("画面回来了，娱乐设施重新运行")
 return true
func feed_capacity() -> int:
 return B.FEED_CAPACITY+B.FEED_CAPACITY_STEP*lv("feeder","capacity")
func work_speed() -> float:
 return effect("work")*(1+B.WORK_STEP*lv("worker","efficiency"))
func capacity(f: Dictionary) -> int:
 return 1
func occupants(id: int) -> Array:
 var result: Array = []
 for c in cats:
  if c.station == id: result.append(c)
 return result
func move_cat(id: int,at: Vector2) -> void:
 var c: Dictionary = cat(id)
 if c.is_empty() or grooming(c): return
 c.station = -1; c.timer = 0.0; cancel_pet(c)
 reset_activity(c)
 c.pos = Space.place(self,c,at); c.dest = c.pos; c.dragging = false;c.entry_bonus=0;c.ent_rounds=0
func assign(id: int,target_id: int) -> bool:
 var c: Dictionary = cat(id); var f: Dictionary = facility(target_id)
 if c.is_empty() or f.is_empty() or f.kind not in ["sun","arcade","altar"]: return fail("这里不能指派猫")
 if grooming(c):return false
 if Space.reserved(self,f,c.id):return fail("设施已有一只猫使用或前往")
 if c.station==f.id:return fail("已在使用这台设施")
 if f.kind == "sun" and c.layers >= D.MAX_LAYERS: return fail("这只猫的毛层已满，先收割")
 reset_activity(c)
 cancel_pet(c)
 c.station = f.id; c.timer = 0.0; c.dragging = false
 c.pos = Space.place(self,c,f.pos+Vector2(0,35)); c.dest = c.pos
 c.ent_rounds=0;c.entry_bonus=0
 if f.kind=="arcade" and node_owned("XBC") and c.get("use_boost",false) and c.layers>=4:
  c.entry_bonus=mini(c.layers-1,3);c.layers=1;c.charges=[];c.harvest_revision=c_revision(c)+1
 return true
func altar_speed() -> float:
 var amount: int = 0
 for f in facilities:
  if f.kind == "altar": amount += occupants(f.id).size()
 return minf(B.ALTAR_SPEED_CAP,1.0+amount*(B.ALTAR_SPEED_BASE+B.ALTAR_SPEED_STEP*lv("altar","speed")))
func growth_speed(c: Dictionary) -> float:
 var local: float = 1.0
 for other in cats:
  if other.id != c.id and other.kind == "alien" and other.pos.distance_to(c.pos) <= B.ALIEN_RADIUS: local = B.ALIEN_SPEED
 return effect("speed")*altar_speed()*local
func layer(c: Dictionary,source: String="natural") -> void:
 if c.layers >= D.MAX_LAYERS: return
 c.layers += 1; c.pop = D.CAT_PULSE_DURATION; grown_total += 1
 Build.charge_layer(self,c,source)
func multiplier(c: Dictionary) -> float:
 var m: float = effect("yield")
 if c.kind == "giant": m *= B.GIANT_FED if c.fed > 0 else B.GIANT_HUNGRY
 if c.fed > 0: m *= B.FOOD_MULT[int(c.food_kind)]
 for f in facilities:
  if f.kind == "feeder" and f.bugs > 0 and f.pos.distance_to(c.pos) < B.FEED_RADIUS: return effect("yield")*(B.GIANT_HUNGRY if c.kind == "giant" else 1.0)*B.BUG_MULT
 return m
func harvest_value(c: Dictionary,layers_count: int = -1) -> float:
 var n: int = int(c.layers) if layers_count<0 else layers_count
 return snappedf(B.BASE_YIELD*multiplier(c)*(n+0.5*B.STACK_BONUS*n*(n-1)),0.1)
func hovered(c: Dictionary) -> bool:
 return c.id==hovered_cat_id and c.station==-1 and not c.dragging
func set_hovered_cat(id: int) -> void:
 var c: Dictionary=cat(id)
 hovered_cat_id=id if not c.is_empty() and c.station==-1 and not c.dragging else -1
func reacting(c: Dictionary) -> bool:
 return c.get("reaction_left",0.0)>0.0
func harvest_scale(n: int) -> float:
 return 1.0+B.HARVEST_CURVE_EXTRA*(1.0-pow(B.HARVEST_CURVE_DECAY,maxi(n,1)-1))
func harvest_distance(n: int) -> float:
 return B.PET_BASE_DISTANCE*harvest_scale(n)
func harvest_time(n: int) -> float:
 # Workers measure seconds; manual input measures motion distance using the same curve.
 return B.HARVEST_BASE_TIME*harvest_scale(n)
func worker_target(w: Dictionary={}) -> int:
 var maximum: int=mini(D.MAX_LAYERS,1+lv("worker","harvest_layers"))
 if w.is_empty() or not node_owned("S10"):return maximum
 return mini(maximum,int(group_settings[clampi(w.get("group",0),0,group_count()-1)].target))
func worker_cooldown() -> float:
 return maxf(B.WORK_CD_MIN,B.WORK_POST_CD*pow(B.WORK_CD_RATIO,lv("worker","cooldown")))
func harvest_ticket(c: Dictionary) -> Dictionary:
 return {"revision":int(c.get("harvest_revision",0)),"layers":int(c.layers),"progress":0.0}
func cancel_pet(c: Dictionary) -> void:
 c.pet=0.0;c.pet_stamp=-1.0;c.erase("pet_action")
# Grooming uses simulation time so movement and worker actions share the same lock.
func grooming(c: Dictionary) -> bool:
 return c.get("groom_left",0.0)>0.0
func tick_grooming(c: Dictionary,dt: float) -> bool:
 if grooming(c):
  c.groom_left=maxf(0.0,c.groom_left-dt)
  return true
 if c.kind not in ["short","static"] or reacting(c) or c.pet>0 or hovered(c):return false
 if c.get("idle_left",0.0)<=0 or c.get("feed_target",-1)>=0:return false
 c.groom_wait=c.get("groom_wait",(9.0+float(c.id%7))*0.5)-dt
 if c.groom_wait>0:return false
 c.groom_wait=(12.0+float(c.id%9))*0.5
 c.groom_left=A.duration("groom",preload("res://Art/cat2new_animations.tres") if c.kind=="static" else GROOM_FRAMES)
 return true
func pet(id: int,distance: float) -> void:
 var c: Dictionary=cat(id)
 if c.is_empty() or c.station!=-1 or c.dragging or reacting(c) or distance<=0 or not is_finite(distance):return
 c.groom_left=0.0 # Only valid player petting interrupts grooming.
 var stamp: float=c.get("pet_stamp",-1.0)
 if stamp<0 or elapsed-stamp>B.PET_BREAK_TIME or not c.has("pet_action"):
  cancel_pet(c);c.pet_action=harvest_ticket(c);c.pet_action.input="distance"
 c.pet+=minf(distance,B.PET_MAX_DISTANCE)
 c.pet_stamp=elapsed;c.pet_action.progress=c.pet
 if c.pet+0.00001>=harvest_distance(c.pet_action.layers):harvest(id,c.pet_action)
func pet_progress(c: Dictionary) -> float:
 if not c.has("pet_action"):return 0.0
 return clampf(c.pet/harvest_distance(c.pet_action.layers),0,1)
func money(amount: float,at: Vector2,fur_count: int = 0,cat_kind: String = "") -> void:
 wallet += amount
 events.append({"kind":"money","pos":at,"text":"+%.1f" % amount,"fur_count":fur_count,"cat_kind":cat_kind})
func prize(c: Dictionary,value: float) -> void:
 var item: Dictionary = {"id":uid(),"name":D.ITEMS[rng.randi_range(0,D.ITEMS.size()-1)],"value":value}
 inventory.append(item)
 Build.refresh_orders(self)
 events.append({"kind":"prize","pos":c.pos,"text":item.name})
func coin_bonus(c: Dictionary) -> void:
 if c.kind != "lucky": return
 var heads: bool = rng.randf() < B.LUCKY_CHANCE
 events.append({"kind":"coin","pos":c.pos,"text":"正面 · 额外道具" if heads else "反面 · 原奖励保留"})
 if heads: prize(c,B.LUCKY_VALUE)
func harvest(id: int,action: Dictionary = {}) -> bool:
 var c: Dictionary = cat(id)
 if c.is_empty() or c.station != -1 or c.dragging or reacting(c) or grooming(c):return false
 if action.is_empty():action=c.get("pet_action",{})
 if not action.has_all(["revision","layers","progress"]):return false
 if action.revision!=c.get("harvest_revision",0) or action.layers<1 or action.layers>c.layers:return false
 var n: int=action.layers
 var required: float=harvest_distance(n) if action.get("input","seconds")=="distance" else harvest_time(n)
 if action.progress+0.00001<required:return false
 var output: float = harvest_value(c,n)
 var bonus: float=Build.harvest_bonus(self,c,n)
 money(output*(1.0+bonus),c.pos,n,c.kind)
 c.reaction_kind=c.kind;c.reaction_left=A.reaction_duration(c.reaction_kind)
 c.layers = maxi(D.MIN_LAYERS,c.layers-n+D.MIN_LAYERS);cancel_pet(c)
 c.harvest_revision=int(c.get("harvest_revision",0))+1;c.pop=D.CAT_PULSE_DURATION;harvests+=1
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
  events.append({"kind":"token","pos":at,"text":"+1 神秘代币"})
  notify("猫咪留下了一枚陌生的代币。远处传来一个信号……")
 if not first_token: return
 while minted < B.TOKEN_THRESHOLDS.size() and production >= B.TOKEN_THRESHOLDS[minted]*B.TOKEN_SCALE:
  minted += 1; tokens += 1
  events.append({"kind":"token","pos":at,"text":"+1 神秘代币"})
func signal_progress() -> float:
 if not first_token: return clampf(float(token_progress)/B.FIRST_TOKEN_LAYERS,0,1)
 if minted >= B.TOKEN_THRESHOLDS.size(): return 1.0
 var start: float = B.TOKEN_THRESHOLDS[minted-1]*B.TOKEN_SCALE
 return clampf((production-start)/(B.TOKEN_THRESHOLDS[minted]*B.TOKEN_SCALE-start),0,1)
func try_transform(c: Dictionary,kind: String,source: String) -> void:
 if c.kind != "short": return
 if rng.randf() < B.TRANSFORM_BASE+B.TRANSFORM_STEP*lv(source,"transform"):
  c.kind = kind; c.pop = D.CAT_PULSE_DURATION;c.pos=Space.place(self,c,c.pos)
  notify("一只猫变成了"+D.title(kind)+"！")
  events.append({"kind":"transform","pos":c.pos,"text":D.title(kind)})
func reset_activity(c: Dictionary) -> void:
 cat_escape_targets.erase(c.id)
 c.feed_target=-1; c.eat_time=0.0; c.walk_left=0.0; c.idle_left=0.0;c.feed_wait=0.0
func start_walk(c: Dictionary) -> void:
 cat_escape_targets.erase(c.id)
 c.idle_left=0.0
 c.walk_left=rng.randf_range(B.CAT_WALK_MIN,B.CAT_WALK_MAX)
 var direction:=Vector2.from_angle(float(rng.randi_range(0,3))*PI/2.0+rng.randf_range(-Space.DIRECTION_DEVIATION,Space.DIRECTION_DEVIATION))
 c.walk_horizontal=absf(direction.x)>=absf(direction.y)
 c.dest=clamp_position(c.pos+direction*D.CAT_MOVE_SPEED*c.walk_left)
 if c.pos.distance_to(c.dest)<8.0:c.dest=clamp_position(c.pos-direction*D.CAT_MOVE_SPEED*c.walk_left)
func feeding_spot(f: Dictionary) -> Vector2:
 return clamp_position(f.pos+Vector2(0,35))
func tick_cat_activity(c: Dictionary,dt: float) -> void:
 if hovered(c):return # Keep activity target/timers; growth/buffs/reaction tick elsewhere.
 if not c.has("feed_target"):reset_activity(c)
 if c.fed<=0:
  var target: Dictionary=facility(c.feed_target)
  if target.is_empty() or target.kind!="feeder" or target.grain<B.FEED_COST or Space.reserved(self,target,c.id):
   c.feed_target=-1;c.eat_time=0.0
   var distance: float=INF
   for f in facilities:
    if f.kind!="feeder" or f.grain<B.FEED_COST or Space.reserved(self,f,c.id):continue
    var candidate: float=c.pos.distance_squared_to(feeding_spot(f))
    if candidate<distance:target=f;distance=candidate;c.feed_target=f.id
  if c.feed_target>=0:
   c.idle_left=0.0;c.walk_left=0.0;c.dest=feeding_spot(target)
   if c.pos.distance_to(c.dest)>B.FEED_REACH:
    c.eat_time=0.0
    var previous: Vector2=c.pos
    c.pos=Space.walk(self,c,c.pos.move_toward(c.dest,D.CAT_MOVE_SPEED*dt))
    c.feed_wait=float(c.get("feed_wait",0.0))+dt if c.pos==previous else 0.0
    if c.feed_wait>3.0:reset_activity(c);c.idle_left=1.0
   else:
    c.eat_time+=dt
    if c.eat_time+0.00001>=B.FEED_EAT_TIME:
     target.grain-=B.FEED_COST;c.fed=B.FEED_DURATION;c.food_kind=target.food_kind
     try_transform(c,"giant","feeder")
     if c.kind=="giant" and target.bugs>0:
      target.bugs-=1
      if target.bugs==0:target.neglect=0.0
     events.append({"kind":"fed","pos":c.pos,"text":"吃饱了"})
     reset_activity(c);start_walk(c)
   return
  # An emptied/removed target cannot grant a buff or keep the cat waiting.
  c.eat_time=0.0
 else:
  c.feed_target=-1;c.eat_time=0.0
 if c.idle_left>0:
  c.idle_left=maxf(0.0,c.idle_left-dt)
  return
 if c.walk_left<=0:start_walk(c)
 c.pos=Space.walk(self,c,c.pos.move_toward(c.dest,D.CAT_MOVE_SPEED*dt))
 c.walk_left=maxf(0.0,c.walk_left-dt)
 if c.walk_left<=0 or c.pos.distance_to(c.dest)<=1.0:
  c.walk_left=0.0;c.idle_left=rng.randf_range(B.CAT_IDLE_MIN,B.CAT_IDLE_MAX)
func tick(dt: float) -> void:
 if dt <= 0 or not is_finite(dt): return
 motion_tick+=1
 var starts: Dictionary={}
 for c in cats:starts[c.id]=c.pos
 Space.update_overlap(self,dt)
 elapsed += dt; round_elapsed += dt
 for f in facilities:
  if f.kind != "feeder": continue
  if count("sun") > 0:
   f.neglect += dt
   if f.neglect >= D.BUG_TIME and f.bugs == 0:
    f.bugs = B.BUG_COUNT; f.hits = 0; notify("喂食器里有偷渡客！打开设备清理蟑螂")
 if count("altar") > 0 and count("arcade")>0:
  interference += dt
  if interference >= D.INTERFERENCE_TIME:
   interference = 0.0
   for f in facilities:
    if f.kind == "arcade" and not f.broken:
     f.broken = true; f.hits = 0; notify("未知信号干扰了娱乐设施，捶打屏幕试试")
     break
 for c in cats:
  c.reaction_left=maxf(0.0,c.get("reaction_left",0.0)-dt)
  if c.station < -1: continue # A worker is carrying this cat.
  c.layers=maxi(D.MIN_LAYERS,c.layers)
  if c.pet>0 and elapsed-c.get("pet_stamp",-1.0)>B.PET_BREAK_TIME:cancel_pet(c)
  c.pop = maxf(0,c.pop-dt); c.fed = maxf(0,c.fed-dt)
  if c.dragging: continue
  var station: Dictionary = facility(c.station)
  if not station.is_empty():
   if station.kind == "sun":
    c.timer += dt*growth_speed(c)*(1+B.SUN_SPEED_STEP*lv("sun","time"))
    if c.timer >= B.SUN_TIME:
     layer(c,"sun"); c.growth = 0.0; try_transform(c,"static","sun")
     move_cat(c.id,station.pos+Vector2(rng.randf_range(-120,120),95))
   elif station.kind == "arcade":
    if station.broken: continue
    c.timer += dt*altar_speed()
    if c.timer >= B.ENT_TIME/(1+B.ENT_SPEED_STEP*lv("arcade","time")):
     c.timer = 0.0;c.ent_rounds=int(c.get("ent_rounds",0))+1
     if rng.randf() < minf(0.9,B.ENT_WIN+B.ENT_WIN_STEP*lv("arcade","win")):
      var value: float = B.ENT_VALUE*(1+B.ENT_VALUE_STEP*lv("arcade","value"))
      prize(c,value*(1.05 if c.get("entry_bonus",0)>0 else 1.0)); contribute(value,c.pos); coin_bonus(c)
     c.entry_bonus=maxi(0,int(c.get("entry_bonus",0))-1)
     try_transform(c,"lucky","arcade")
     var limit: int=int(group_settings[clampi(c.get("group",0),0,2)].rounds) if node_owned("S20") else 0
     if limit>0 and c.ent_rounds>=limit:move_cat(c.id,station.pos+Vector2(0,110))
   elif station.kind == "altar":
    c.timer += dt
    if c.timer >= B.ALTAR_TRANSFORM_TIME: c.timer = 0.0; try_transform(c,"alien","altar")
   continue
  c.growth += dt*growth_speed(c)
  while c.growth >= D.LAYER_CD:
   c.growth -= D.LAYER_CD; layer(c)
  if not tick_grooming(c,dt) and not Space.escape(self,c,dt):tick_cat_activity(c,dt)
 var reserved: Dictionary = {}
 for w in workers:
  if not w.job.is_empty(): reserved[job_key(w.job)] = true
 for w in workers: tick_worker(w,dt,reserved)
 cat_displacements.clear()
 for c in cats:cat_displacements[c.id]=c.pos-starts.get(c.id,c.pos)
func set_role(id: int,role: String) -> bool:
 var w: Dictionary = worker(id)
 if w.is_empty() or not D.ROLES.has(role): return false
 if role != "general" and not has("hats"): return fail("先解锁职责分配帽")
 if role == "repair" and not has("maint"): return fail("先解锁工人维护")
 if role in ["sun","arcade","altar"] and not has(role): return fail("先研发对应设施")
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
    if c.station != -1 or c.dragging or grooming(c): continue
    if node_owned("S10") and c.get("group",0)!=w.get("group",0):continue
    var key: String = "cat:"+str(c.id)
    if reserved.has(key): continue
    if role == "harvest" and w.get("cooldown",0.0)<=0 and not reacting(c) and c.layers >= worker_target(w):return {"kind":role,"target":c.id,"cat":c.id,"revision":int(c.get("harvest_revision",0))}
    if role in ["sun","arcade","altar"] and (role != "sun" or (c.layers<D.MAX_LAYERS and c.layers<=worker_target(w))):
     for f in facilities:
      if f.kind == role and not Space.reserved(self,f,c.id): return {"kind":role,"target":c.id,"cat":c.id,"facility":f.id}
 return {}
func tick_worker(w: Dictionary,dt: float,reserved: Dictionary) -> void:
 w.cooldown=maxf(0.0,w.get("cooldown",0.0)-dt)
 if w.job.is_empty():
  w.job = choose_job(w,reserved); w.clock = 0.0
  if w.job.is_empty():
   w.status = "收割休息 %.1f秒" % w.cooldown if w.cooldown>0 else "缺粮" if w.role in ["general","refill"] and count("feeder") > 0 and int(food[0])+int(food[1])+int(food[2]) == 0 else "待命"
   return
  reserved[job_key(w.job)] = true
 var job: Dictionary = w.job
 var target: Dictionary = cat(job.target) if job.cat >= 0 else facility(job.target)
 if target.is_empty() or (job.cat >= 0 and (target.dragging or grooming(target) or (target.station != -1 and target.station != -w.id-2))):
  w.job = {}; return
 if job.get("stage","") == "carry":
  if target.station != -w.id-2: w.job = {}; return
  var destination: Dictionary = facility(job.facility)
  if destination.is_empty(): move_cat(target.id,w.pos); w.job = {}; return
  w.pos = w.pos.move_toward(destination.pos,B.WORK_SPEED*work_speed()*dt)
  target.dest = clamp_position(w.pos+Vector2(0,-20))
  target.pos = Space.walk(self,target,target.pos.move_toward(target.dest,B.WORK_SPEED*work_speed()*dt))
  w.pos = target.pos+Vector2(0,20)
  if w.pos.distance_to(destination.pos) < B.WORK_REACH:
   move_cat(target.id,w.pos)
   assign(target.id,destination.id)
   w.job = {}
  return
 if job.kind=="harvest":
  if w.cooldown>0 or reacting(target) or c_revision(target)!=job.get("revision",-1) or target.layers<worker_target(w):
   w.job={};w.clock=0.0;return
 w.status = D.ROLES.get(job.kind,job.kind)
 var dest: Vector2 = target.pos
 if w.pos.distance_to(dest) > B.WORK_REACH:
  w.pos = w.pos.move_toward(dest,B.WORK_SPEED*work_speed()*dt); return
 if job.kind=="harvest" and not job.has("action"):job.action=harvest_ticket(target)
 w.clock += dt*work_speed()
 var required: float=harvest_time(job.action.layers) if job.kind=="harvest" else B.WORK_ACTION
 if w.clock+0.00001<required:return
 match job.kind:
  "harvest":
   job.action.progress=w.clock
   if harvest(target.id,job.action):w.cooldown=worker_cooldown()
  "refill": refill(target.id,target.food_kind)
  "clean": clean(target.id)
  "repair": repair(target.id,true)
  _:
   w.job.stage = "carry"; target.station = -w.id-2; w.status = "搬运中"
   return
 w.job = {};w.clock=0.0
func c_revision(c: Dictionary) -> int:
 return int(c.get("harvest_revision",0))
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
 # Collection restock does not reset facility timers or reservations.
 notify("仪器收到新的信号：24个新回声已抵达，舱室补给也更新了。")
 return true
func sell_all() -> float:
 return Build.sell(self)
func group_count() -> int:return 3 if node_owned("S20") else (2 if node_owned("S10") else 1)
func node_owned(id: String) -> bool:
 if id=="S00":return true
 if not tree.has(id):return false
 var spec: Dictionary=tree[id]
 if spec.kind=="research":return has(spec.subject)
 if spec.kind=="upgrade":return lv(spec.subject,spec.branch)>=spec.level
 return bool(nodes_owned.get(id,false))
func node_reason(id: String) -> String:
 if not tree.has(id):return "未知节点"
 if node_owned(id):return "已获得"
 var spec: Dictionary=tree[id]
 for pre in spec.all:
  if not node_owned(pre):return "需要："+tree[pre].title
 if not spec.any.is_empty():
  var allowed: bool=false
  for pre in spec.any:
   if node_owned(pre):allowed=true
  if not allowed:return "需要任一路对应机制入口（或条件）"
 return ""
func buy_node(id: String) -> bool:
 var why: String=node_reason(id)
 if why!="":return fail(why)
 var spec: Dictionary=tree[id]
 if spec.kind=="research":return research(spec.subject)
 if spec.kind=="upgrade":return upgrade(spec.subject,spec.branch)
 if not spend(spec.price):return false
 nodes_owned[id]=true
 if id=="S10":
  for group in group_settings:group.target=worker_target()
 return true
func set_group(kind: String,id: int,group: int) -> bool:
 if not node_owned("S10") or group<0 or group>=group_count():return fail("先解锁对应猫群")
 var entity: Dictionary=cat(id) if kind=="cat" else worker(id)
 if entity.is_empty():return false
 if kind=="worker":set_role(id,entity.role)
 entity.group=group;return true
func set_group_target(group: int,target: int,rounds: int=-1) -> bool:
 if not node_owned("S10") or group<0 or group>=group_count() or target<1 or target>worker_target():return false
 group_settings[group].target=target
 if rounds>=0 and node_owned("S20"):group_settings[group].rounds=clampi(rounds,0,20)
 return true
func snapshot() -> Dictionary:
 var data: Dictionary = {"version":SAVE_VERSION,"harvest_rules":1,"scope_rules":1,"rng":rng.state}
 for field in FIELDS: data[field] = get(field)
 return data.duplicate(true)
func numeric_fields(record: Dictionary,fields: Array) -> bool:
 for key in fields:
  if not record.has(key) or typeof(record[key]) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(record[key])):return false
 return true
func restore(data: Dictionary) -> bool:
 data=data.duplicate(true)
 var refund: int=0
 var old_scope: bool=not data.has("scope_rules")
 if not old_scope and data.scope_rules!=1:return false
 if old_scope:
  data.nodes_owned={};data.build_state={};data.orders=[]
  data.group_settings=[{"target":1,"rounds":0},{"target":1,"rounds":0},{"target":1,"rounds":0}]
  if data.get("levels",null) is Dictionary:
   var capacity_level=data.levels.get("sun:capacity",0)
   if not capacity_level is int or capacity_level<0 or capacity_level>4:return false
   for level in range(capacity_level):refund+=ceili(1200.0*pow(1.8,level))
   data.levels.erase("sun:capacity")
 var legacy: bool=not data.has("harvest_rules")
 if not legacy and data.harvest_rules!=1:return false
 if legacy and data.get("levels",null) is Dictionary:
  var carry = data.levels.get("worker:carry",0)
  if not carry is int or carry<0 or carry>4:return false
  if carry>0 and not data.get("researches",{}).get("worker",false):return false
  for level in range(carry):refund+=ceili(240.0*pow(1.8,level))
  data.levels.erase("worker:carry")
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
  for field in ["feed_target","eat_time","walk_left","idle_left","harvest_revision","reaction_left"]:
   if c.has(field) and (not numeric_fields(c,[field]) or (field!="feed_target" and c[field]<0)):return false
  if c.has("reaction_kind") and c.reaction_kind not in ["short","giant","static","lucky","alien"]:return false
  if not numeric_fields(c,["id","layers","growth","pet","station","timer","fed","food_kind","pop","wander","color"]):return false
  if c.kind not in ["short","giant","static","lucky","alien"] or not c.pos is Vector2 or not c.dest is Vector2 or c.layers < 0 or c.layers > D.MAX_LAYERS or ids.has(c.id): return false
  if c.color<0 or c.color>2 or c.food_kind<0 or c.food_kind>2 or not c.pos.is_finite() or not c.dest.is_finite():return false
  ids[c.id] = true
 for f in data.facilities:
  if not f is Dictionary or not f.has_all(["id","kind","pos","grain","food_kind","pulse","neglect","bugs","hits","broken"]): return false
  if not numeric_fields(f,["id","grain","food_kind","pulse","neglect","bugs","hits"]) or not f.broken is bool:return false
  if f.kind not in ["feeder","sun","arcade","altar"] or not f.pos is Vector2 or ids.has(f.id): return false
  if f.food_kind<0 or f.food_kind>2 or f.grain<0 or f.grain>B.FEED_CAPACITY+B.FEED_CAPACITY_STEP*int(data.levels.get("feeder:capacity",0)) or f.bugs<0 or not f.pos.is_finite():return false
  ids[f.id] = true;station_ids[f.id]=true
 for w in data.workers:
  if not w is Dictionary or not w.has_all(["id","pos","role","job","clock","status"]) or not w.pos is Vector2 or not D.ROLES.has(w.role) or ids.has(w.id): return false
  if w.has("cooldown") and (not numeric_fields(w,["cooldown"]) or w.cooldown<0):return false
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
 for id in data.nodes_owned:
  if not tree.has(id) or tree[id].kind!="build" or not data.nodes_owned[id] is bool:return false
 if data.group_settings.size()!=3:return false
 for group in data.group_settings:
  if not group is Dictionary or not group.has_all(["target","rounds"]) or not group.target is int or not group.rounds is int or group.target<1 or group.target>D.MAX_LAYERS or group.rounds<0 or group.rounds>20:return false
 for field in ["combo","XAB_count","XAC_count"]:
  if data.build_state.has(field) and (not data.build_state[field] is int or data.build_state[field]<0):return false
 for field in ["XAB_ready","XAC_ready"]:
  if data.build_state.has(field) and not data.build_state[field] is bool:return false
 var reserved_items: Dictionary={}
 if data.orders.size()>4:return false
 for order in data.orders:
  if not order is Dictionary or not order.has_all(["kind","ids"]) or not order.ids is Array or Build.order_size(order.kind)==0 or order.ids.size()>Build.order_size(order.kind):return false
  for id in order.ids:
   if not id is int or reserved_items.has(id):return false
   var found: bool=false
   for item in data.inventory:
    if item.id==id:found=true
   if not found:return false
   reserved_items[id]=true
 for c in data.cats:
  for field in ["variant","group","ent_rounds","entry_bonus"]:
   if c.has(field) and (not c[field] is int or c[field]<0):return false
  if c.get("group",0)>2 or c.get("variant",0)>3:return false
  if c.has("charges"):
   if not c.charges is Array or c.charges.size()>6:return false
   var last: int=0
   for layer_number in c.charges:
    if not layer_number is int or layer_number<2 or layer_number>c.layers or layer_number<=last:return false
    last=layer_number
  if c.has("use_boost") and not c.use_boost is bool:return false
 for w in data.workers:
  if w.has("group") and (not w.group is int or w.group<0 or w.group>2):return false
 for field in FIELDS:
  var value = data[field]
  set(field,value.duplicate(true) if value is Array or value is Dictionary else value)
 for c in cats:
  c.variant=int(c.get("variant",c.id%4));c.group=int(c.get("group",0));c.charges=c.get("charges",[]);c.entry_bonus=int(c.get("entry_bonus",0));c.ent_rounds=int(c.get("ent_rounds",0));c.use_boost=bool(c.get("use_boost",false))
  c.reaction_left=float(c.get("reaction_left",0.0));c.reaction_kind=c.get("reaction_kind",c.kind)
  c.dragging = false;c.layers=maxi(D.MIN_LAYERS,c.layers);c.harvest_revision=int(c.get("harvest_revision",0));cancel_pet(c)
  if not c.has_all(["feed_target","eat_time","walk_left","idle_left"]):reset_activity(c)
  c.feed_wait=float(c.get("feed_wait",0.0))
  if c.station < -1: c.station = -1
 for w in workers:w.job={};w.clock=0.0;w.cooldown=float(w.get("cooldown",0.0))
 hovered_cat_id=-1;cat_displacements.clear();cat_overlap_times.clear();cat_escape_targets.clear();motion_tick+=1
 Space.reconcile(self)
 harvest_target=worker_target();wallet+=refund
 rng.state = int(data.rng); events.clear()
 if refund>0:notify("旧容量／搬运升级已按原价返还 %d 毛球" % refund)
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
