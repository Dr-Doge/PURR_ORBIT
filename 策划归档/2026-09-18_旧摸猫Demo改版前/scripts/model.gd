extends RefCounted
const D = preload("res://scripts/data.gd")
const FIELDS = ["wallet","earned","auto_earned","elapsed","stage","cats","tools","levels","inventory","discovered","consumables","buffs","decor","next_id","satisfied","eligible","misses","tickets","ticket_progress","auto_unlocked","minigame","completed","rng_state"]
var wallet: float = 0
var earned: float = 0
var auto_earned: float = 0
var elapsed: float = 0
var stage: int = 0
var cats: Array = []
var tools: Array = []
var levels: Dictionary = {}
var inventory: Array = []
var discovered: Array = []
var consumables: Array = [0,0,0]
var buffs: Array = [0.0,0.0,0.0]
var decor: Dictionary = {"bed":0,"post":0,"bell":0}
var next_id: int = 1
var satisfied: int = 0
var eligible: int = 0
var misses: int = 0
var tickets: int = 0
var ticket_progress: int = 0
var auto_unlocked: bool = false
var minigame: Dictionary = {}
var completed: bool = false
var rng_state: int = 0
var rng := RandomNumberGenerator.new()
var events: Array = []
var error: String = ""
var pet_id: int = -1
var pet_motion: float = 0
func _init() -> void:
	rng.randomize(); add_cat("short",0)
func uid() -> int:
	var id: int = next_id; next_id += 1; return id
func lv(s: String, k: String) -> int: return int(levels.get(s+":"+k,0))
func unlocked(kind: String) -> bool: return kind in ["hand","short"] or D.ORDER.find(kind) <= stage
func count(kind: String) -> int:
	var n: int = 0
	for obj in cats if D.CATS.has(kind) else tools:
		if obj.kind == kind: n += 1
	return n
func limit(kind: String) -> int: return (3 if D.CATS.has(kind) else 1)+lv(kind,"cap")
func cat(id: int) -> Dictionary:
	for c in cats:
		if c.id == id: return c
	return {}
func notify(text: String) -> void: events.append({"kind":"notice","text":text})
func price(kind: String) -> int:
	var n: int = count(kind)-(1 if kind == "short" else 0)
	return ceili((D.CATS[kind].price if D.CATS.has(kind) else D.TOOLS[kind])*pow(1.35 if D.CATS.has(kind) else 1.4,maxi(0,n)))
func spend(value: float) -> bool:
	if wallet+0.000001 < value: error = "还差 %.1f 毛球" % (value-wallet); return false
	wallet = maxf(0,wallet-value); return true
func buy_reason(kind: String) -> String:
	if kind == "lucky": return "抛币正面率待配置，暂不开放邀请"
	if not unlocked(kind): return "先在成长树研发主体"
	if count(kind) >= limit(kind): return "本类持有数已满，升级独立上限"
	return ""
func buy(kind: String, color: int = 0) -> bool:
	error = buy_reason(kind)
	if error != "" or not spend(price(kind)): return false
	if D.CATS.has(kind): add_cat(kind,color)
	else: tools.append({"id":uid(),"kind":kind,"pos":Vector2(450,330),"target":-1,"cd":0.0,"placed":kind in ["spirit","spark"],"passes":{}})
	notify(D.title(kind)+("来到房间！" if kind not in ["wand","heater"] else "已放入库存，请点击摆放")); return true
func add_cat(kind: String, color: int) -> void:
	var p: Vector2 = choose_position(Vector2(-100,-100)) if not cats.is_empty() else Vector2(450,320)
	cats.append({"id":uid(),"kind":kind,"color":color%3,"pos":p,"from":p,"dest":p,"progress":0.0,"moving":0.0,"duration":0.8,"pop":0.0,"manual_touched":false})
func choose_position(old: Vector2, subject: String = "") -> Vector2:
	var best: Vector2 = Vector2(450,320); var best_score: float = -1
	var heater: Dictionary = {}
	for t in tools:
		if t.kind == "heater" and t.placed and old.distance_to(t.pos) < radius(t):
			if heater.is_empty() or old.distance_to(t.pos) < old.distance_to(heater.pos): heater = t
	for i in range(40):
		var p := Vector2(rng.randf_range(100,800),rng.randf_range(170,530))
		if old.x >= 100 and i < 32: p = (old+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(90,180)).clamp(Vector2(100,170),Vector2(800,530))
		if not heater.is_empty():
			p = heater.pos+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(50,radius(heater)*0.85)
			p = p.clamp(Vector2(100,170),Vector2(800,530))
		if old.distance_to(p) < 85: continue
		var score: float = 10000
		for c in cats: score = minf(score,p.distance_to(c.dest))
		for t in tools:
			if t.placed and t.kind in ["wand","heater"]: score = minf(score,p.distance_to(t.pos))
		if score > best_score: best_score = score; best = p
		if old.x >= 100 and i < 32 and score >= 80: return p
	return best
func research(index: int) -> bool:
	if index != stage+1 or index >= D.ORDER.size(): error = "只需先购买相连的前一主节点"; return false
	if not spend(D.RESEARCH[index]): return false
	stage = index; notify("已研发 "+D.title(D.ORDER[index])+" · 实体另行购买"); return true
func upgrade_price(s: String,k: String) -> int:
	if not D.BRANCHES.get(s,[]).has(k): return -1
	var data: Dictionary = D.branch(s,k)
	return ceili(data.base*pow(data.growth,lv(s,k))) if lv(s,k) < data.cap else -1
func upgrade(s: String,k: String) -> bool:
	if not unlocked(s): error = "先研发主体"; return false
	var cost: int = upgrade_price(s,k)
	if cost < 0: error = "已满级或参数待定"; return false
	if not spend(cost): return false
	levels[s+":"+k] = lv(s,k)+1
	if s in ["wand","heater"] and k == "range":
		for t in tools:
			if t.kind == s: sync_passes(t)
	return true
func decor_price(key: String) -> int: return ceili((8 if key == "bell" else 20)*pow(1.6 if key == "bell" else 1.7,int(decor[key])))
func buy_decor(key: String) -> bool:
	if int(decor[key]) >= (6 if key == "bell" else 3) or not spend(decor_price(key)): return false
	decor[key] += 1; notify(D.title(key)+"已摆入房间"); return true
func pet(id: int, distance: float) -> void:
	if id != pet_id: pet_motion = 0
	pet_id = id; pet_motion += maxf(0,distance)
func clear_pet() -> void: pet_id = -1; pet_motion = 0
func care(c: Dictionary, amount: float, source: String) -> void:
	if c.is_empty() or c.moving > 0 or c.kind == "lucky": return
	if amount <= 0: return
	if source == "hand": c.manual_touched = true
	c.progress += amount
	if c.progress+0.00001 < float(D.CATS[c.kind].need): return
	c.progress = 0.0; c.pop = 1.0; satisfied += 1
	var independent_auto: bool = source != "hand" and not c.get("manual_touched",false)
	reward(c,source,independent_auto)
	if independent_auto and not auto_unlocked: auto_unlocked = true; tickets = mini(3,tickets+1); notify("精灵已独立产出！纸箱寻宝开放，赠送1张游玩券。")
	if tickets < 3:
		ticket_progress += 1
		if ticket_progress >= 20: tickets += 1; ticket_progress = 0
	else: ticket_progress = 0
	if c.kind == "static":
		var r: float = 3*72*pow(1.15,lv("static","range"))
		events.append({"kind":"ring","pos":c.pos,"radius":r})
		for other in cats:
				if other.id != c.id and other.pos.distance_to(c.pos) <= r: reward(other,"chain",independent_auto)
	c.manual_touched = false
	c.from = c.pos; c.dest = choose_position(c.pos,c.kind); c.duration = rng.randf_range(0.6,1.0)/pow(1.15,lv(c.kind,"move")); c.moving = c.duration
func room_multiplier(p: Vector2) -> float:
	var heat: float = 1.0
	for t in tools:
		if t.kind == "heater" and t.placed and p.distance_to(t.pos) <= radius(t): heat = maxf(heat,1.2+0.1*lv("heater","yield"))
	return (1.0+0.1*int(decor.bed))*(1.5 if buffs[1] > 0 else 1.0)*heat
func add_money(value: float,p: Vector2,source: String,double: bool = false,count_auto: bool = true) -> void:
	wallet += value; earned += value
	if source != "hand" and count_auto: auto_earned += value
	events.append({"kind":"money","pos":p,"value":value,"double":double})
func reward(c: Dictionary,source: String,count_auto: bool = true) -> void:
	if c.kind == "lucky": return
	var source_key: String = source if source in ["hand","spirit","spark"] else "none"
	var amount: float = float(D.CATS[c.kind].yield)+lv(c.kind,"yield")+(lv("hand","yield") if source == "hand" else 0)
	if source in ["spirit","spark"]: amount *= 1.0+0.2*lv(source,"yield")
	var double: bool = rng.randf() < minf(0.5,0.05*(lv(c.kind,"double")+(lv("hand","double") if source == "hand" else 0)))
	amount *= room_multiplier(c.pos)*(2 if double else 1); add_money(amount,c.pos,source,double,count_auto); c.pop = 1.0
	eligible += 1; misses += 1
	var drop: float = minf(0.25,0.04+0.01*(int(decor.bell)+lv(c.kind,"drop")+lv(source_key,"drop"))+(0.02 if buffs[2] > 0 else 0))
	if (discovered.is_empty() and eligible >= 12) or misses >= 40 or rng.randf() < drop:
		misses = 0
		var q: int = lv(c.kind,"quality")+lv(source_key,"quality")
		var roll: float = rng.randf()*(70+25*(1+0.2*q)+5*(1+0.4*q))
		var grade: int = 0 if roll < 70 else (1 if roll < 70+25*(1+0.2*q) else 2)
		var item: int = rng.randi_range(0,2) if grade == 0 else (rng.randi_range(3,4) if grade == 1 else 5)
		var first: bool = not discovered.has(item)
		if first: discovered.append(item)
		inventory.append({"id":uid(),"item":item,"price":[1,3,8][grade],"locked":first})
		notify("猫咪吐出了「"+D.COLLECTIBLES[item]+"」"+(" · 首件已锁定" if first else ""))
func radius(t: Dictionary) -> float:
	return {"wand":1.5,"heater":3.0,"spark":2.5}.get(t.kind,0.5)*72*pow(1.15,lv(t.kind,"range"))
func sync_passes(t: Dictionary) -> void:
	t.passes.clear()
	for c in cats: t.passes[c.id] = {"armed":c.pos.distance_to(t.pos) > radius(t)+21.6,"time":elapsed}
func place(id: int,p: Vector2) -> bool:
	for t in tools:
		if t.id != id or t.kind not in ["wand","heater"]: continue
		p = p.clamp(Vector2(100,170),Vector2(800,530))
		for c in cats:
			if c.pos.distance_to(p) < 48: error = "请在猫旁边的空地摆放"; return false
		t.pos = p; t.placed = true; sync_passes(t); return true
	return false
func tick(dt: float) -> void:
	elapsed += dt
	for i in range(3): buffs[i] = maxf(0,buffs[i]-dt)
	var c: Dictionary = cat(pet_id)
	if not c.is_empty(): care(c,minf(40.0*dt,pet_motion*0.7),"hand")
	pet_motion = 0
	for current in cats:
		current.pop = maxf(0,current.pop-dt*2.5)
		if current.moving > 0:
			current.moving = maxf(0,current.moving-dt)
			current.pos = current.from.lerp(current.dest,smoothstep(0,1,1-current.moving/current.duration))
	for t in tools:
		if not t.placed: continue
		if t.kind == "wand":
			for current in cats:
				var distance: float = current.pos.distance_to(t.pos)
				if not t.passes.has(current.id): t.passes[current.id] = {"armed":distance > radius(t)+21.6,"time":elapsed}
				var state: Dictionary = t.passes[current.id]
				if distance > radius(t)+21.6: state.armed = true
				if state.armed and current.moving > 0 and distance <= radius(t) and elapsed-state.time >= 2:
					state.armed = false; state.time = elapsed; add_money(0.2*pow(1.5,lv("wand","yield"))*room_multiplier(current.pos),current.pos,"wand")
			continue
		if t.kind == "heater": continue
		t.cd = maxf(0,t.cd-dt)
		if t.cd > 0: continue
		if t.kind == "spark" and t.get("arrived",false):
			events.append({"kind":"ring","pos":t.pos,"radius":radius(t)})
			for current in cats:
				if current.pos.distance_to(t.pos) <= radius(t): reward(current,"spark")
			t.arrived = false; t.target = -1; continue
		var selected: Dictionary = cat(t.target)
		if selected.is_empty() or selected.moving > 0:
			t.target = -1; t.arrived = false; var best: float = INF
			for current in cats:
				if current.moving > 0 or current.kind == "lucky": continue
				var reserved: bool = false
				for other in tools:
					if other.id != t.id and other.kind == t.kind and other.target == current.id: reserved = true
				var distance: float = t.pos.distance_to(current.pos)
				if not reserved and distance < best: selected = current; best = distance; t.target = current.id
			if t.target < 0: continue
		var distance: float = t.pos.distance_to(selected.pos)
		if distance > 48:
			t.pos = t.pos.move_toward(selected.pos,4*72*pow(1.15,lv(t.kind,"move"))*dt)
			continue
		if t.kind == "spirit":
			care(selected,20*pow(1.25,lv("spirit","speed"))*(1+0.1*int(decor.post))*(1.5 if buffs[0] > 0 else 1.0)*dt,"spirit")
			if selected.moving > 0: t.cd = 1.0/pow(1.2,lv("spirit","cd")); t.target = -1
		else:
			t.arrived = true; t.cd = 8.0/pow(1.2,lv("spark","cd"))
	if not minigame.is_empty() and float(minigame.wait) > 0:
		minigame.wait = maxf(0,minigame.wait-dt)
		if minigame.wait == 0: minigame.open.clear()
	if not completed and count("short") >= 2 and count("spirit") >= 1 and lv("hand","yield") >= 1 and auto_unlocked:
		completed = true; notify("小小猫舍成形！你已完成手动→升级→多猫→自动产出的闭环，可继续探索成长树。")
func sale_value(item: Dictionary) -> float: return float(item.price)*(1+0.2*lv("hand","sale"))
func sell(id: int) -> bool:
	for item in inventory:
		if item.id == id and not item.locked: wallet += sale_value(item); inventory.erase(item); return true
	return false
func use_item(index: int) -> bool:
	if index < 0 or index > 2 or consumables[index] <= 0 or buffs[index] > 0: return false
	if index == 0 and count("spirit") == 0: return false
	consumables[index] -= 1; buffs[index] = 60.0 if index == 2 else 30.0; return true
func start_minigame() -> bool:
	if not minigame.is_empty() and not minigame.claimed: return true
	if not auto_unlocked or tickets <= 0: error = "需要自动化产出，并持有游玩券"; return false
	tickets -= 1
	var deck: Array = [0,0,1,1,2,2]
	for i in range(5,0,-1):
		var j: int = rng.randi_range(0,i); var temp = deck[i]; deck[i] = deck[j]; deck[j] = temp
	minigame = {"id":uid(),"deck":deck,"open":[],"matched":[],"wait":0.0,"claimed":false,"reward":rng.randi_range(0,2),"auto_start":auto_earned}
	return true
func flip(index: int) -> bool:
	if minigame.is_empty() or minigame.claimed or minigame.wait > 0 or index < 0 or index > 5 or minigame.open.has(index) or minigame.matched.has(index): return false
	minigame.open.append(index)
	if minigame.open.size() == 2:
		if minigame.deck[minigame.open[0]] == minigame.deck[minigame.open[1]]: minigame.matched.append_array(minigame.open); minigame.open.clear()
		else: minigame.wait = 0.8
	if minigame.matched.size() == 6:
		minigame.claimed = true; wallet += 2; consumables[minigame.reward] += 1; notify("配对完成：＋2毛球，获得"+D.ITEMS[minigame.reward])
	return true
func snapshot() -> Dictionary:
	rng_state = rng.state
	var data: Dictionary = {"version":1}
	for field in FIELDS: data[field] = get(field)
	return data.duplicate(true)
func restore(data: Dictionary) -> bool:
	if data.get("version",0) != 1: return false
	for key in FIELDS:
		if not data.has(key) or typeof(data[key]) != typeof(get(key)): return false
	if data.stage < 0 or data.stage > 7 or data.wallet < 0 or not is_finite(data.wallet) or data.cats.is_empty(): return false
	for c in data.cats:
		if not c is Dictionary or not c.has_all(["id","kind","color","pos","from","dest","progress","moving","duration","pop"]) or not D.CATS.has(c.kind): return false
	for t in data.tools:
		if not t is Dictionary or not t.has_all(["id","kind","pos","target","cd","placed","passes"]) or not D.TOOLS.has(t.kind): return false
	if data.buffs.size() != 3 or data.consumables.size() != 3: return false
	if not data.minigame.is_empty() and not data.minigame.has_all(["id","deck","open","matched","wait","claimed","reward","auto_start"]): return false
	for field in FIELDS: set(field,data[field].duplicate(true) if data[field] is Array or data[field] is Dictionary else data[field])
	rng.state = rng_state; clear_pet(); events.clear(); return true
func save_to(path: String) -> Error:
	var f := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if f == null: return FileAccess.get_open_error()
	f.store_var(snapshot()); f.close(); return DirAccess.rename_absolute(path+".tmp",path)
func load_from(path: String) -> bool:
	if not FileAccess.file_exists(path): return false
	var f := FileAccess.open(path,FileAccess.READ)
	if f == null: return false
	var data = f.get_var(false)
	return restore(data) if data is Dictionary else false
