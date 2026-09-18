extends RefCounted
## Simulation owns rewards; render particles never change the economy.
var wallet: float = 0.0
var elapsed: float = 0.0
var earned: float = 0.0
var generated: float = 0.0
var kills: int = 0
var next_id: int = 1
var auto_fire: bool = false
var piercing: bool = false
var use_piercing: bool = true
var unlocked: bool = false
var first_spawned: bool = false
var armor_spawned: bool = false
var armor_returned: bool = false
var auto_sell: bool = false
var completed: bool = false
var next_cache: int = 50
var pending_cache: bool = false
var focus: int = -1
var priority: int = -1
var manual_target: int = -1
var held: bool = false
var requested: bool = false
var cargo_level: int = 0
var levels: Dictionary = {"light_damage":0, "heavy_damage":0, "light_rate":0, "heavy_rate":0}
var ships: Array = []
var drones: Array = []
var targets: Array = []
var projectiles: Array = []
var loot: Array = []
var inventory: Array = []
var discovered: Array = []
var events: Array = []

func _init() -> void:
	ships.append({"kind":"light", "cool":0.0})
	drones.append({"time":0.0, "cargo":0.0, "treasure":{}, "x":0.5})
	for x in [0.16, 0.37, 0.63, 0.85]:
		targets.append(make_target("normal", x))

func uid() -> int:
	var result: int = next_id
	next_id += 1
	return result

func make_target(kind: String, x: float) -> Dictionary:
	var hp: float = 20.0 if kind == "normal" else 100.0
	return {"id":uid(), "kind":kind, "x":x, "hp":hp, "max_hp":hp, "armor":100.0 if kind == "armor" else 0.0, "paid":0, "respawn":0.0}

func target(id: int) -> Dictionary:
	for t in targets:
		if int(t.id) == id: return t
	return {}

func ship_count(kind: String) -> int:
	var count: int = 0
	for s in ships:
		if s.kind == kind: count += 1
	return count

func price(key: String) -> int:
	match key:
		"auto": return -1 if auto_fire else 80
		"light": return -1 if ship_count("light") >= 3 else int(240 * pow(2, ship_count("light")-1))
		"heavy": return -1 if ship_count("heavy") > 0 else 450
		"drone": return -1 if drones.size() >= 3 else int(ceil(160 * pow(1.8, drones.size()-1)))
		"cargo": return -1 if cargo_level >= 3 else int(ceil(120 * pow(1.25, cargo_level)))
		"piercing": return -1 if piercing else 200
	if levels.has(key):
		var l: int = int(levels[key])
		if l >= 3: return -1
		var base: float = 120.0 if key.ends_with("rate") else (60.0 if key.begins_with("light") else 150.0)
		return int(ceil(base * pow(1.8 if key.ends_with("rate") else 1.25, l)))
	return -1

func reason(key: String) -> String:
	if price(key) < 0: return "已完成升级"
	if key == "heavy" and not unlocked: return "回收首个宝库，获得蓝图"
	if (key == "piercing" or key.begins_with("heavy_")) and ship_count("heavy") == 0: return "需要重炮舰"
	if wallet + 0.000001 < price(key): return "还差 %d 金属" % int(ceil(price(key)-wallet))
	return ""

func buy(key: String) -> bool:
	if reason(key) != "": return false
	wallet -= price(key)
	match key:
		"auto": auto_fire = true
		"light", "heavy": ships.append({"kind":key, "cool":0.0})
		"drone": drones.append({"time":0.0, "cargo":0.0, "treasure":{}, "x":0.5})
		"cargo": cargo_level += 1
		"piercing": piercing = true
		_: levels[key] = int(levels[key]) + 1
	events.append({"kind":"purchase", "text":"舰队升级完成"})
	return true

func command(id: int) -> void:
	var t: Dictionary = target(id)
	if t.is_empty() or t.hp <= 0: return
	manual_target = id
	focus = id if t.kind != "normal" else -1
	requested = true

func damage_for(kind: String) -> float:
	return (10.0 if kind == "light" else 32.0) * pow(1.25, int(levels[kind+"_damage"]))

func interval(kind: String) -> float:
	return (2.0 if kind == "light" else 4.0) / pow(1.1, int(levels[kind+"_rate"]))

func choose_target(index: int) -> Dictionary:
	var f: Dictionary = target(focus)
	if index == ships.size()-1 and not f.is_empty() and f.hp > 0: return f
	if not auto_fire:
		var m: Dictionary = target(manual_target)
		return m if not m.is_empty() and m.hp > 0 else {}
	var candidates: Array = []
	for t in targets:
		if t.kind != "normal" or t.hp <= 0: continue
		var reserved: float = 0
		for p in projectiles:
			if int(p.target) == int(t.id): reserved += float(p.damage)
		if float(t.hp) > reserved: candidates.append(t)
	if candidates.is_empty(): return {}
	return candidates[index % candidates.size()]

func tick(dt: float) -> void:
	elapsed += dt
	for i in range(targets.size()):
		var t: Dictionary = targets[i]
		if t.kind == "normal" and t.hp <= 0:
			t.respawn -= dt
			if t.respawn <= 0: targets[i] = make_target("normal", float(t.x))
	for p in projectiles.duplicate():
		p.time -= dt
		if p.time <= 0:
			hit(int(p.target), float(p.damage), bool(p.ap))
			projectiles.erase(p)
	for i in range(ships.size()):
		var s: Dictionary = ships[i]
		s.cool = maxf(0, float(s.cool)-dt)
		if s.cool > 0 or not (auto_fire or held or requested): continue
		var t: Dictionary = choose_target(i)
		if t.is_empty(): continue
		var p: Dictionary = {"target":t.id, "x":t.x, "ship":i, "time":0.5, "duration":0.5, "damage":damage_for(s.kind), "ap":s.kind == "heavy" and piercing and use_piercing}
		projectiles.append(p)
		s.cool = interval(s.kind)
		events.append({"kind":"shot", "ship":i, "heavy":s.kind == "heavy"})
	requested = false
	for d in drones:
		if d.time > 0:
			d.time = maxf(0, float(d.time)-dt)
			if d.time <= 0:
				wallet += float(d.cargo)
				earned += float(d.cargo)
				if d.cargo > 0: events.append({"kind":"income", "value":d.cargo, "x":d.x})
				d.cargo = 0.0
				if not d.treasure.is_empty(): receive(d.treasure); d.treasure = {}
		if d.time <= 0: dispatch(d)
	spawn_hotspots()
	if not completed and auto_fire and ship_count("light")+ship_count("heavy") >= 2 and drones.size() >= 2 and unlocked and armor_returned:
		completed = true
		events.append({"kind":"complete", "text":"轨道行动完成 · 舰队可继续作业"})

func hit(id: int, amount: float, ap: bool = false) -> void:
	var t: Dictionary = target(id)
	if t.is_empty() or t.hp <= 0: return
	var dealt: float
	var armored: bool = t.armor > 0
	if armored:
		dealt = minf(float(t.armor), amount * (1.0 if ap else 0.1))
		t.armor = maxf(0, float(t.armor)-dealt)
	else:
		dealt = minf(float(t.hp), amount)
		t.hp = maxf(0, float(t.hp)-dealt)
	events.append({"kind":"hit", "x":t.x, "value":dealt, "armored":armored, "big":amount >= 30})
	if t.kind == "normal":
		var due: int = 20 if t.hp <= 0 else (10 if t.hp <= 10 else 0)
		if due > int(t.paid):
			drop_metal(float(t.x), due-int(t.paid))
			t.paid = due
		if t.hp <= 0:
			kills += 1
			t.respawn = 1.0
	else:
		if t.hp <= 0:
			loot.append({"id":uid(), "kind":"treasure", "x":t.x, "value":240.0 if t.kind == "armor" else 120.0, "source":t.kind})
			events.append({"kind":"treasure_drop", "x":t.x})
			targets.erase(t)
	if t.hp <= 0 and focus == id: focus = -1

func drop_metal(x: float, amount: float) -> void:
	generated += amount
	for pile in loot:
		if pile.kind == "metal" and absf(float(pile.x)-x) < 0.035:
			pile.value += amount
			events.append({"kind":"drop", "x":x, "value":amount})
			return
	loot.append({"id":uid(), "kind":"metal", "x":x, "value":amount, "source":"normal"})
	events.append({"kind":"drop", "x":x, "value":amount})

func dispatch(d: Dictionary) -> void:
	if loot.is_empty(): return
	var chosen: Dictionary = loot[0]
	for item in loot:
		if int(item.id) == priority: chosen = item; break
		if item.kind == "treasure": chosen = item
	d.x = chosen.x
	d.time = 5.0
	if chosen.kind == "treasure":
		d.treasure = chosen.duplicate(true)
		loot.erase(chosen)
	else:
		var remaining: float = 30.0 * pow(1.25, cargo_level)
		# Reserve the selected local pile; multiple drones cannot collect it twice.
		for pile in [chosen]:
			if remaining <= 0: continue
			var take: float = minf(remaining, float(pile.value))
			d.cargo += take
			pile.value -= take
			remaining -= take
			if pile.value <= 0.000001: loot.erase(pile)
	priority = -1

func receive(item: Dictionary) -> void:
	var source: String = item.source
	var first: bool = not discovered.has(source)
	if first: discovered.append(source)
	var record: Dictionary = {"id":item.id, "source":source, "value":item.value, "locked":first, "new":first, "sold":false}
	inventory.append(record)
	if source == "armor": armor_returned = true
	else: unlocked = true
	events.append({"kind":"reveal", "text":"重甲遗迹核心" if source == "armor" else "外星记忆晶体", "first":first})
	if auto_sell and not first: sell(int(record.id))

func sell(id: int) -> bool:
	for item in inventory:
		if int(item.id) != id: continue
		if item.locked or item.sold: return false
		item.sold = true
		wallet += float(item.value)
		return true
	return false

func spawn_hotspots() -> void:
	var active: int = 0
	for t in targets:
		if t.kind != "normal": active += 1
	if not first_spawned and auto_fire and kills >= 20 and active < 2:
		first_spawned = true
		next_cache = kills + 30
		add_hotspot("cache")
		active += 1
	if unlocked and ship_count("heavy") > 0 and not armor_spawned and active < 2:
		armor_spawned = true
		add_hotspot("armor")
		active += 1
	if first_spawned and kills >= next_cache:
		pending_cache = true
	if pending_cache and active < 2:
		add_hotspot("cache")
		pending_cache = false
		next_cache = kills + 30

func add_hotspot(kind: String) -> void:
	var x: float = 0.49
	for t in targets:
		if t.kind != "normal" and absf(float(t.x)-x) < 0.05: x = 0.74
	targets.append(make_target(kind, x))
	events.append({"kind":"hotspot", "text":"发现重甲遗迹 · 重炮穿甲可快速突破" if kind == "armor" else "宝库暴露 · 点击金色结构集火"})

func ground_value() -> float:
	var value: float = 0
	for item in loot:
		if item.kind == "metal": value += float(item.value)
	return value

func transit_value() -> float:
	var value: float = 0
	for d in drones: value += float(d.cargo)
	return value

const FIELDS = ["wallet","elapsed","earned","generated","kills","next_id","auto_fire","piercing","use_piercing","unlocked","first_spawned","armor_spawned","armor_returned","auto_sell","completed","next_cache","pending_cache","focus","priority","cargo_level","levels","ships","drones","targets","projectiles","loot","inventory","discovered"]
func snapshot() -> Dictionary:
	var data: Dictionary = {"version":1}
	for key in FIELDS: data[key] = get(key)
	return data.duplicate(true)

func restore(data: Dictionary) -> bool:
	if int(data.get("version",0)) != 1: return false
	for key in FIELDS:
		if not data.has(key): return false
	for key in ["ships","drones","targets","projectiles","loot","inventory","discovered"]:
		if not data[key] is Array: return false
	if data.ships.is_empty() or data.drones.is_empty() or not data.levels is Dictionary: return false
	for key in FIELDS: set(key, data[key])
	held = false; requested = false; manual_target = -1; events.clear()
	return true

func save_to(path: String) -> Error:
	var file := FileAccess.open(path+".tmp", FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_var(snapshot())
	file.close()
	return DirAccess.rename_absolute(path+".tmp", path)

func load_from(path: String) -> bool:
	if not FileAccess.file_exists(path): return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return false
	var data = file.get_var(false)
	return restore(data) if data is Dictionary else false
