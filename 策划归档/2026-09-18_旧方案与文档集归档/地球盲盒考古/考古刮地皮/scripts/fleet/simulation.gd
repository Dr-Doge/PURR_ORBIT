extends RefCounted
const C = preload("res://scripts/fleet/catalog.gd")
const Guide = preload("res://scripts/fleet/guide.gd")
const FIELDS = ["wallet","elapsed","earned","planet","angle","regions","targets","ships","drones","modules","templates","loot","inventory","projectiles","threats","levels","researched","next_id","phase","wave_clock","enemy_cursor","focus","focus_group","priority","delivered","retreat","facts","tutorial_enabled","tutorial_later","settings"]
var wallet: float = 0
var elapsed: float = 0
var earned: float = 0
var planet: int = 0
var angle: float = 0
var regions: Array = []
var targets: Array = []
var ships: Array = []
var drones: Array = []
var modules: Array = []
var templates: Dictionary = {}
var loot: Array = []
var inventory: Array = []
var projectiles: Array = []
var threats: Array = []
var levels: Dictionary = {}
var researched: Array = ["frigate","carrier","raider","kinetic","plate","repair"]
var next_id: int = 1
var phase: String = "surface"
var wave_clock: float = 30
var enemy_cursor: int = 0
var focus: int = -1
var focus_group: String = "all"
var priority: int = -1
var delivered: float = 0
var retreat: float = 0
var events: Array = []
var facts: Dictionary = {}
var tutorial_enabled: bool = true
var tutorial_later: float = 0
var settings: Dictionary = {"mute":false,"reduced":false,"merge":true}
var turn: float = 0
var nuclear_armed: bool = false
var error: String = ""

func _init() -> void:
	for kind in C.HULLS:
		var loadout: Array = []; loadout.resize(int(C.HULLS[kind].slots)); loadout.fill("")
		if kind != "carrier": loadout[0] = "kinetic"
		templates[kind] = [loadout]
	add_ship("frigate",["kinetic","kinetic"],true,"starter1")
	add_ship("frigate",["kinetic","kinetic"],true,"starter2")
	var carrier: Dictionary = add_ship("carrier",["",""],true,"starter3")
	add_drone(carrier.id,true); add_drone(carrier.id,true); make_planet()
func uid() -> int:
	var result: int = next_id; next_id += 1; return result
func level(key: String) -> int: return int(levels.get(key,0))
func config() -> Dictionary: return C.PLANETS[planet]
func notify(text: String) -> void: events.append({"kind":"notice","text":text})
func find_id(items: Array, id: int) -> Dictionary:
	for item in items:
		if int(item.id) == id: return item
	return {}
func target(id: int) -> Dictionary: return find_id(targets,id)
func module(id: int) -> Dictionary: return find_id(modules,id)
func ship(id: int) -> Dictionary: return find_id(ships,id)
func longitude(x: float) -> float: return fposmod(angle+(x-0.5)*90.0,360.0)
func screen_x(lon: float) -> float: return 0.5+wrapf(lon-angle,-180.0,180.0)/90.0
func visible(lon: float) -> bool: return absf(wrapf(lon-angle,-180.0,180.0)) <= 45.0
func region_at(lon: float) -> int: return mini(regions.size()-1,int(fposmod(lon,360.0)/360.0*regions.size()))
func ship_x(index: int) -> float: return 0.12+float(index % 8)*0.108
func command_used() -> int:
	var count: int = 0
	for s in ships: count += int(C.HULLS[s.kind].cmd)
	return count
func command_max() -> int: return C.COMMAND[level("command")]
func hangar_max() -> int: return 2+2*level("hangar")
func carrier_load(id: int) -> int:
	var count: int = 0
	for d in drones:
		if int(d.carrier) == id: count += 1
	return count
func make_planet() -> void:
	angle = 0; regions.clear(); targets.clear(); loot.clear(); threats.clear(); projectiles.clear()
	phase = "surface"; focus = -1; priority = -1; delivered = 0; turn = 0
	wave_clock = 30.0 if planet < 2 else 20.0
	for i in range(int(config().regions)):
		regions.append({"stock":float(config().stock),"max":float(config().stock),"lon":(i+0.5)*360.0/config().regions})
	var count: int = int(config().aa)+int(config().silo)
	for i in range(count):
		var is_aa: bool = i < int(config().aa)
		var hp: float = (100.0 if planet == 1 else 400.0) if is_aa else (100.0 if planet == 1 else 500.0)
		var armor: float = (0.0 if planet == 1 else 40.0) if is_aa else (180.0 if planet == 1 else 600.0)
		targets.append({"id":uid(),"kind":"battery" if is_aa else "silo","lon":70.0+i*220.0/maxi(1,count-1),"hp":hp,"max_hp":hp,"armor":armor,"max_armor":armor,"cool":3.0,"visible":false})
	notify("抵达 "+config().name+" · 自动垂直轰炸已启动")
func new_module(kind: String, gifted: bool = false) -> int:
	var id: int = uid()
	modules.append({"id":id,"kind":kind,"paid":0 if gifted else C.module_price(kind),"cool":0.0,"cycle":1.0,"beam":0,"beam_clock":0.0,"beam_target":-1,"beam_power":1.0})
	return id
func add_ship(kind: String, loadout: Array, gifted: bool = false, identity: String = "") -> Dictionary:
	var slots: Array = []
	for key in loadout: slots.append(-1 if key == "" else new_module(key,gifted))
	var s: Dictionary = {"id":uid(),"kind":kind,"slots":slots,"paid":0 if gifted else C.HULLS[kind].price,"gift":identity,"hp":1.0,"armor":1.0}
	ships.append(s); s.hp = max_hp(s); s.armor = max_armor(s); return s
func add_drone(carrier: int, gifted: bool = false) -> void:
	drones.append({"id":uid(),"carrier":carrier,"paid":0 if gifted else 60,"time":0.0,"duration":4.0,"cargo":0.0,"treasure":{},"lon":0.0})
func equipment(s: Dictionary, key: String) -> int:
	var count: int = 0
	for id in s.slots:
		var m: Dictionary = module(id)
		if not m.is_empty() and m.kind == key: count += 1
	return count
func max_hp(s: Dictionary) -> float:
	return float(C.HULLS[s.kind].hp)*pow(1.25,level(s.kind+":hp"))+equipment(s,"repair")*100.0*pow(1.25,level("repair:strength"))
func max_armor(s: Dictionary) -> float:
	return float(C.HULLS[s.kind].armor)*pow(1.25,level(s.kind+":armor"))+equipment(s,"plate")*40.0*pow(1.25,level("plate:strength"))
func ratios() -> Dictionary:
	var result: Dictionary = {}
	for s in ships: result[s.id] = [s.hp/max_hp(s),s.armor/max_armor(s) if max_armor(s) > 0 else s.hp/max_hp(s)]
	return result
func apply_ratios(old: Dictionary) -> void:
	for s in ships:
		if old.has(s.id): s.hp = max_hp(s)*old[s.id][0]; s.armor = max_armor(s)*old[s.id][1]
func research_reason(key: String) -> String:
	if researched.has(key): return "已研发"
	if not C.HULLS.has(key) and not C.WEAPONS.has(key) and not C.GEAR.has(key): return "未知主体"
	if planet < (2 if key in ["battleship","destroyer","neutron"] else 1): return "抵达下一颗星球获得许可"
	var chain: int = C.CHAIN.find(key)
	if chain > 0 and not researched.has(C.CHAIN[chain-1]): return "先研发 "+C.title(C.CHAIN[chain-1])+"（无需满级）"
	if key == "laser" and not facts.get("fixed_kill",false): return "先击破一处固定防御"
	if key == "neutron" and not researched.has("destroyer"): return "先研发歼星舰"
	return ""
func research_price(key: String) -> int:
	return int(C.HULLS.get(key,C.WEAPONS.get(key,C.GEAR.get(key,{"research":0}))).research)
func research(key: String) -> bool:
	error = research_reason(key)
	if error != "" or not spend(research_price(key)): return false
	researched.append(key); facts["research_"+key] = true; notify("已研发 "+C.title(key)+" · 装备需另行配装"); return true
func spend(amount: float) -> bool:
	if wallet+0.000001 < amount: error = "金属不足，还差 %d" % ceili(amount-wallet); return false
	wallet = maxf(0,wallet-amount); return true
func upgrade_price(key: String) -> int:
	var l: int = level(key)
	match key:
		"command": return C.COMMAND_COST[l] if l < 3 else -1
		"hangar": return ceili(240*pow(1.8,l)) if l < 3 else -1
		"cargo": return ceili(100*pow(1.65,l)) if l < 8 else -1
		"speed": return ceili(100*pow(1.65,l)) if l < 5 else -1
		"special": return [3000,9000][l] if l < 2 else -1
		"nuclear_auto": return 6000 if l == 0 else -1
	var parts: PackedStringArray = key.split(":")
	if parts.size() != 2: return -1
	var subject: String = parts[0]
	if C.HULLS.has(subject):
		if parts[1] == "reload": return ceili(2000*pow(1.6,l)) if subject == "destroyer" and l < 3 else -1
		if parts[1] not in ["hp","armor"] or (subject == "destroyer" and parts[1] == "armor"): return -1
		return ceili(C.HULLS[subject].branch*pow(1.55,l)) if l < 6 else -1
	if C.WEAPONS.has(subject) and parts[1] in ["attack","reload"]: return ceili(C.WEAPONS[subject].branch*pow(1.55,l)) if l < 6 else -1
	if C.GEAR.has(subject) and parts[1] == "strength": return ceili(C.GEAR[subject].branch*pow(1.55,l)) if l < 3 else -1
	return -1
func upgrade_reason(key: String) -> String:
	if upgrade_price(key) < 0: return "已达上限"
	if key.contains(":") and not researched.has(key.split(":")[0]): return "先研发主体"
	if key == "special" and not researched.has("destroyer"): return "先研发歼星舰"
	if key == "nuclear_auto" and (not facts.get("manual_neutron",false) or not has_installed("neutron")): return "安装中子炮并手动发射一次"
	return ""
func upgrade(key: String) -> bool:
	error = upgrade_reason(key)
	if error != "" or not spend(upgrade_price(key)): return false
	var old: Dictionary = ratios(); levels[key] = level(key)+1; apply_ratios(old)
	facts["upgrade_"+key] = true; notify("升级完成 · "+C.title(key.split(":")[0])); return true
func installed_ids() -> Array:
	var result: Array = []
	for s in ships: result.append_array(s.slots)
	return result
func has_installed(key: String) -> bool:
	for id in installed_ids():
		if id >= 0 and module(id).kind == key: return true
	return false
func valid_loadout(kind: String, keys: Array) -> String:
	if not researched.has(kind): return "先研发舰体"
	var normal: int = int(C.HULLS[kind].slots)
	if keys.size() < normal or keys.size() > normal+(level("special") if kind == "destroyer" else 0): return "槽位数量不合法"
	for i in range(keys.size()):
		var key: String = keys[i]
		if key == "": continue
		if not researched.has(key) or (not C.WEAPONS.has(key) and not C.GEAR.has(key)): return "模块未研发"
		if i >= normal and key != "neutron": return "特殊槽只能安装中子炮"
		if i < normal and key == "neutron": return "中子炮仅限歼星舰特殊槽"
		if kind == "carrier" and C.WEAPONS.has(key) and key != "aa": return "母舰只允许防空和非武器装备"
	return ""
func loadout_keys(s: Dictionary) -> Array:
	var result: Array = []
	for id in s.slots: result.append("" if id < 0 else module(id).kind)
	var count: int = int(C.HULLS[s.kind].slots)+(level("special") if s.kind == "destroyer" else 0)
	while result.size() < count: result.append("")
	return result
## Plans reserve unique owned instances before pricing new ones, across the whole batch.
func quote(kind: String, keys: Array, count: int = 1, refit_id: int = -1) -> Dictionary:
	var why: String = valid_loadout(kind,keys)
	if count < 1 or count > 48: why = "批量数量不合法"
	if refit_id < 0 and command_used()+int(C.HULLS[kind].cmd)*count > command_max(): why = "指挥点不足"
	var occupied: Array = installed_ids()
	if refit_id >= 0:
		var s: Dictionary = ship(refit_id)
		if s.is_empty() or s.kind != kind or count != 1: return {"error":"舰船不存在","price":0,"plans":[]}
		for id in s.slots:
			if id >= 0 and module(id).beam > 0: why = "激光束结束后可改装"
		for id in s.slots: occupied.erase(id)
	var available: Array = []
	for m in modules:
		if not occupied.has(m.id): available.append(m)
	var price: int = int(C.HULLS[kind].price)*count if refit_id < 0 else 0
	var plans: Array = []
	for j in range(count):
		var plan: Array = []
		for key in keys:
			if key == "": plan.append(-1); continue
			var chosen: Dictionary = {}
			for m in available:
				if m.kind == key: chosen = m; break
			if chosen.is_empty(): plan.append(key); price += C.module_price(key)
			else: plan.append(chosen.id); available.erase(chosen)
		plans.append(plan)
	return {"error":why,"price":price,"plans":plans}
func purchase(kind: String, keys: Array, count: int = 1, refit_id: int = -1) -> bool:
	var q: Dictionary = quote(kind,keys,count,refit_id); error = q.error
	if error != "" or not spend(q.price): return false
	var old: Dictionary = ratios()
	for plan in q.plans:
		var slots: Array = []
		for entry in plan: slots.append(new_module(entry) if entry is String else int(entry))
		if refit_id >= 0:
			var s: Dictionary = ship(refit_id); var ratio: float = 0.0
			var newly_fitted: Array = []
			for id in slots:
				if id >= 0 and not s.slots.has(id): newly_fitted.append(id)
			for id in s.slots:
				if id >= 0: ratio = maxf(ratio,module(id).cool/maxf(0.01,module(id).cycle))
			s.slots = slots
			for id in slots:
				if id >= 0 and C.WEAPONS.has(module(id).kind):
					var m: Dictionary = module(id); m.cycle = interval(m.kind,s); m.cool = maxf(m.cool,m.cycle*ratio)
			facts["refit_ids"] = newly_fitted
		else:
			var s: Dictionary = add_ship(kind,[],false); s.slots = slots; s.hp = max_hp(s); s.armor = max_armor(s); facts["bought_ship"] = s.id
	apply_ratios(old); notify("改装完成" if refit_id >= 0 else "舰队已扩编"); return true
func buy_raider(carrier_id: int) -> bool:
	var s: Dictionary = ship(carrier_id)
	if s.is_empty() or s.kind != "carrier" or carrier_load(carrier_id) >= hangar_max(): error = "母舰机库已满"; return false
	if not spend(60): return false
	add_drone(carrier_id); return true
func group_trial(ids: Array, keys: Array, commit: bool = false) -> Dictionary:
	if ids.is_empty(): return {"error":"未选择舰船","price":0}
	var trial = get_script().new()
	if not trial.restore(snapshot()): return {"error":"当前状态无法建立改装预览","price":0}
	var start: float = wallet if commit else 1000000000.0
	trial.wallet = start
	var seen: Array = []
	var old: Dictionary = trial.ratios()
	var reload_ratios: Dictionary = {}
	for id in ids:
		if seen.has(id) or trial.ship(id).is_empty(): return {"error":"编组包含重复或无效舰船","price":0}
		seen.append(id)
		var s: Dictionary = trial.ship(id); var ratio: float = 0
		for mid in s.slots:
			if mid < 0: continue
			var m: Dictionary = trial.module(mid)
			if m.beam > 0: return {"error":"激光束结束后可改装","price":0}
			ratio = maxf(ratio,m.cool/maxf(0.01,m.cycle))
		reload_ratios[id] = ratio; s.slots.fill(-1)
	trial.apply_ratios(old)
	for id in ids:
		if not trial.purchase(trial.ship(id).kind,keys,1,id): return {"error":trial.error,"price":0}
		for mid in trial.ship(id).slots:
			if mid >= 0 and C.WEAPONS.has(trial.module(mid).kind):
				var m: Dictionary = trial.module(mid); m.cool = maxf(m.cool,m.cycle*reload_ratios[id])
	trial.apply_ratios(old)
	var total: int = roundi(start-trial.wallet)
	if commit:
		if not restore(trial.snapshot()): return {"error":"改装状态校验失败","price":0}
		notify("同型舰编组改装完成")
	return {"error":"","price":total}
func refit_group(ids: Array, keys: Array) -> bool:
	var result: Dictionary = group_trial(ids,keys,true); error = result.error; return error == ""
func sell_module(id: int) -> bool:
	var m: Dictionary = module(id)
	if m.is_empty() or installed_ids().has(id): return false
	if m.cool > 0 or m.beam > 0: error = "模块装填完成后可退役"; return false
	wallet += m.paid; modules.erase(m); return true
func sell_ship(id: int) -> bool:
	var s: Dictionary = ship(id)
	if s.is_empty() or carrier_load(id) > 0: error = "先转移或退役所属掠袭舰"; return false
	if s.gift != "": error = "初始赠舰保留，免费救援可恢复其火力"; return false
	if s.hp < max_hp(s)-0.001: error = "受损舰先免费安全撤离，再退役"; return false
	for mid in s.slots:
		if mid >= 0 and (module(mid).cool > 0 or module(mid).beam > 0): error = "装填结束后可退役"; return false
	wallet += s.paid; ships.erase(s); return true
func move_raider(id: int, carrier_id: int) -> bool:
	var d: Dictionary = find_id(drones,id); var s: Dictionary = ship(carrier_id)
	if d.is_empty() or s.is_empty() or s.kind != "carrier" or carrier_load(carrier_id) >= hangar_max(): return false
	d.carrier = carrier_id; return true
func sell_raider(id: int) -> bool:
	var d: Dictionary = find_id(drones,id)
	if d.is_empty() or d.time > 0 or d.paid == 0: return false
	wallet += d.paid; drones.erase(d); return true
func power(key: String) -> float: return pow(1.25,level(key+":attack"))
func interval(key: String, s: Dictionary) -> float:
	var value: float = float(C.WEAPONS[key].reload)/pow(1.12,level(key+":reload"))
	if s.kind == "destroyer": value /= pow(1.08,level("destroyer:reload"))
	value /= minf(1.4,1.0+equipment(s,"energy")*0.08*pow(1.15,level("energy:strength")))
	return maxf(6.0 if key == "neutron" else 0.2,value)
func command(id: int) -> void:
	var t: Dictionary = target(id)
	if not t.is_empty() and t.hp > 0 and visible(t.lon): focus = id; facts["focused"] = true
func focused_for(key: String) -> int:
	if focus_group == "ap" and key != "ap": return -1
	if focus_group == "normal" and key in ["ap","aa"]: return -1
	return focus
func extract(lon: float, strength: float) -> void:
	var index: int = region_at(lon); var r: Dictionary = regions[index]
	var amount: float = minf(r.stock,strength*float(config().factor))
	if amount <= 0: return
	r.stock -= amount; drop_metal(r.lon,amount); facts["extracted_region"] = index
	if facts.get("rotated",false) and index != int(facts.get("first_region",index)): facts["navigated"] = true
	if not facts.has("first_region"): facts["first_region"] = index
func drop_metal(lon: float, amount: float) -> void:
	for item in loot:
		if item.kind == "metal" and region_at(item.lon) == region_at(lon): item.value += amount; return
	loot.append({"id":uid(),"kind":"metal","lon":lon,"value":amount})
func impact(key: String, target_id: int, x: float, strength: float) -> void:
	var w: Dictionary = C.WEAPONS[key]
	if target_id >= 0:
		var t: Dictionary = target(target_id)
		if t.is_empty() or t.hp <= 0: return
		var amount: float = float(w.armor if t.armor > 0 else w.hp)*strength
		if t.armor > 0: t.armor = maxf(0,t.armor-amount)
		else: t.hp = maxf(0,t.hp-amount)
		facts["focus_damage"] = true; events.append({"kind":"hit","lon":t.lon,"value":amount})
		if t.hp <= 0:
			if t.kind == "vault":
				drop_metal(t.lon,float(config().vault)); phase = "recovery"
				loot.append({"id":uid(),"kind":"treasure","lon":t.lon,"value":config().sale,"name":config().treasure})
				notify("最终宝库击破 · 回收藏品与全部物资后驶离")
			else: facts["fixed_kill"] = true
			if focus == target_id: focus = -1
	else:
		var lon: float = longitude(x); extract(lon,float(w.extract)*strength)
		events.append({"kind":"hit","lon":lon,"value":0.0})
func fire_neutron(x: float, target_id: int = -1, manual: bool = true) -> bool:
	if retreat > 0 or phase == "finished": return false
	for s in ships:
		if s.hp <= 0: continue
		for id in s.slots:
			if id < 0: continue
			var m: Dictionary = module(id)
			if m.kind != "neutron" or m.cool > 0: continue
			if target_id < 0 and regions[region_at(longitude(x))].stock <= 0: continue
			if target_id >= 0:
				var primary: Dictionary = target(target_id)
				if primary.is_empty() or primary.hp <= 0 or not visible(primary.lon): return false
				var nearby: Array = []
				for t in targets:
					if t.id != target_id and t.hp > 0 and visible(t.lon) and absf(wrapf(t.lon-primary.lon,-180,180)) <= 30: nearby.append(t)
				nearby.sort_custom(func(a: Dictionary,b: Dictionary): return absf(wrapf(a.lon-primary.lon,-180,180)) < absf(wrapf(b.lon-primary.lon,-180,180)))
				impact("neutron",target_id,x,power("neutron"))
				for j in range(mini(2,nearby.size())): impact("neutron",nearby[j].id,x,power("neutron")*0.5)
			else:
				var index: int = region_at(longitude(x))
				for offset in [-1,0,1]:
					var r: Dictionary = regions[posmod(index+offset,regions.size())]
					if visible(r.lon): extract(r.lon,1200.0*power("neutron")*(1.0 if offset == 0 else 0.5))
			m.cycle = interval("neutron",s); m.cool = m.cycle
			if manual: facts["manual_neutron"] = true
			events.append({"kind":"nuclear","lon":longitude(x)}); nuclear_armed = false; return true
	return false
func tick(dt: float) -> void:
	if phase == "finished": return
	elapsed += dt
	if retreat > 0:
		retreat = maxf(0,retreat-dt)
		if retreat <= 0:
			for s in ships: s.hp = max_hp(s); s.armor = max_armor(s)
			restore_gifts(); notify("安全轨道维修完成 · 原星球进度保留")
		return
	if turn != 0: angle = fposmod(angle+turn*45.0*dt,360.0); facts["rotated"] = true
	if focus >= 0:
		var f: Dictionary = target(focus)
		if f.is_empty() or f.hp <= 0 or not visible(f.lon): focus = -1; notify("目标离开可见弧，恢复垂直轰炸")
	for m in modules:
		if m.beam <= 0: m.cool = maxf(0,m.cool-dt)
	for p in projectiles.duplicate():
		p.time -= dt
		if p.time > 0: continue
		if p.kind == "aa":
			var t: Dictionary = find_id(threats,p.target)
			if not t.is_empty():
				t.hp -= p.power*12.0
				if t.hp <= 0: threats.erase(t); facts["intercept"] = true
		else: impact(p.kind,p.target,p.x,p.power)
		projectiles.erase(p)
	for i in range(ships.size()):
		var s: Dictionary = ships[i]
		if s.hp <= 0: continue
		for id in s.slots:
			if id < 0: continue
			var m: Dictionary = module(id); var key: String = m.kind
			if not C.WEAPONS.has(key): continue
			if m.beam > 0:
				m.beam_clock -= dt
				while m.beam_clock <= 0 and m.beam > 0:
					var aim: int = m.beam_target
					if aim >= 0 and (target(aim).is_empty() or not visible(target(aim).lon)): aim = -2
					if aim != -2: impact(key,aim,ship_x(i),m.beam_power/20.0)
					m.beam -= 1; m.beam_clock += 0.1
				if m.beam == 0: m.cool = m.cycle
				continue
			if m.cool > 0: continue
			if key == "neutron":
				if level("nuclear_auto") > 0: fire_neutron(ship_x(i),focused_for(key),false)
				continue
			var aim: int = focused_for(key)
			if key == "aa":
				aim = aa_target()
				if aim < 0: continue
			m.cycle = interval(key,s)
			if key == "laser": m.beam = 20; m.beam_clock = 0.1; m.beam_target = aim; m.beam_power = power(key)
			else:
				var duration: float = 0.15 if key == "aa" else 0.35
				projectiles.append({"kind":key,"ship":s.id,"x":ship_x(i),"target":aim,"power":power(key),"time":duration,"duration":duration}); m.cool = m.cycle
			facts["shot"] = true
			if int(facts.get("bought_ship",-1)) == int(s.id): facts["bought_fired"] = true
			if facts.get("refit_ids",[]).has(id): facts["refit_fired"] = true
			events.append({"kind":"shot","ship":s.id})
	transport(dt); enemies(dt); update_phase()
func transport(dt: float) -> void:
	for d in drones:
		if d.time > 0:
			d.time = maxf(0,d.time-dt)
			if d.time <= 0:
				wallet += d.cargo; earned += d.cargo; delivered += d.cargo
				if d.cargo > 0: facts["income"] = true; events.append({"kind":"income","value":d.cargo})
				d.cargo = 0.0
				if not d.treasure.is_empty():
					var item: Dictionary = d.treasure.duplicate(true); item.locked = true; item.sold = false; inventory.append(item); d.treasure = {}
					facts["treasure_"+str(planet)] = true; notify("已回收藏品："+item.name)
		if d.time > 0 or loot.is_empty(): continue
		var carrier: Dictionary = ship(d.carrier)
		if carrier.is_empty() or carrier.hp <= 0: continue
		var chosen: Dictionary = loot[0]
		for item in loot:
			if item.kind == "treasure": chosen = item
			if int(item.id) == priority: chosen = item; break
		d.lon = chosen.lon; d.duration = maxf(1.0,(4.0 if visible(chosen.lon) else 6.0)/pow(1.2,level("speed"))); d.time = d.duration
		if chosen.kind == "treasure": d.treasure = chosen.duplicate(true); loot.erase(chosen)
		else:
			d.cargo = minf(chosen.value,40.0*pow(1.8,level("cargo"))); chosen.value -= d.cargo
			if chosen.value < 0.000001: loot.erase(chosen)
		if priority == chosen.id: priority = -1
func aa_target() -> int:
	var candidates: Array = threats.duplicate()
	candidates.sort_custom(func(a: Dictionary,b: Dictionary): return (a.kind == "missile" and b.kind != "missile") or (a.kind == b.kind and a.time < b.time))
	for t in candidates:
		var reserved: float = 0
		for p in projectiles:
			if p.kind == "aa" and p.target == t.id: reserved += 12.0*p.power
		if t.hp > reserved: return int(t.id)
	return -1
func next_enemy_target() -> int:
	for i in range(ships.size()):
		enemy_cursor = posmod(enemy_cursor,ships.size()); var s: Dictionary = ships[enemy_cursor]; enemy_cursor += 1
		if s.hp > 0: return s.id
	return -1
func hurt(id: int, amount: float) -> void:
	var s: Dictionary = ship(id)
	if s.is_empty() or s.hp <= 0: return
	if s.armor > 0: s.armor = maxf(0,s.armor-amount)
	else: s.hp = maxf(0,s.hp-amount)
	if s.hp <= 0: notify(C.title(s.kind)+"失能 · 可免费紧急撤离维修")
func enemies(dt: float) -> void:
	if planet == 0: return
	for t in targets:
		if t.hp <= 0 or t.kind == "vault": continue
		if not visible(t.lon): t.visible = false; continue
		if not t.visible: t.visible = true; t.cool = 3.0
		t.cool -= dt
		if t.cool > 0: continue
		var victim: int = next_enemy_target()
		if t.kind == "battery":
			t.cool = 3.0 if planet == 1 else 2.0; hurt(victim,8.0 if planet == 1 else 15.0)
			events.append({"kind":"enemy_shot","lon":t.lon,"ship":victim})
		else:
			t.cool = 6.0 if planet == 1 else 5.0
			threats.append({"id":uid(),"kind":"missile","hp":18.0 if planet == 1 else 50.0,"time":6.0 if planet == 1 else 5.0,"duration":6.0 if planet == 1 else 5.0,"target":victim,"lon":t.lon,"x":screen_x(t.lon)})
	if phase in ["surface","vault"]:
		wave_clock -= dt
		if wave_clock <= 0:
			wave_clock = 30.0 if planet == 1 else 25.0; var alive: int = 0
			for t in threats:
				if t.kind == "aircraft": alive += 1
			for i in range(mini(2 if planet == 1 else 4,(4 if planet == 1 else 8)-alive)):
				threats.append({"id":uid(),"kind":"aircraft","hp":24.0 if planet == 1 else 80.0,"time":3.0 if planet == 1 else 2.5,"duration":3.0,"target":-1,"lon":angle,"x":0.15+0.1*posmod(next_id,7)})
	for t in threats.duplicate():
		t.time -= dt
		if t.time > 0: continue
		if t.kind == "missile": hurt(t.target,30.0 if planet == 1 else 70.0); threats.erase(t)
		else: hurt(next_enemy_target(),4.0 if planet == 1 else 8.0); t.time = 3.0 if planet == 1 else 2.5
func update_phase() -> void:
	if phase == "surface" and unextracted() <= 0.000001:
		for t in targets:
			if t.hp > 0: return
		phase = "vault"; targets.append({"id":uid(),"kind":"vault","lon":fposmod(135.0+planet*67.0,360),"hp":config().hp,"max_hp":config().hp,"armor":config().armor,"max_armor":config().armor,"cool":0.0,"visible":false})
		notify("全星掠尽 · 最终宝库暴露，按罗盘寻找金色信号")
	if phase == "recovery" and threats.is_empty() and loot.is_empty() and not cargo_pending(): phase = "ready"; notify("所有物资已回收 · 可以驶离")
func unextracted() -> float:
	var value: float = 0
	for r in regions: value += r.stock
	return value
func ground_value() -> float:
	var value: float = 0
	for item in loot:
		if item.kind == "metal": value += item.value
	return value
func transit_value() -> float:
	var value: float = 0
	for d in drones: value += d.cargo
	return value
func cargo_pending() -> bool:
	for d in drones:
		if d.time > 0: return true
	return false
func conserved() -> float: return unextracted()+ground_value()+transit_value()+delivered+(float(config().vault) if phase in ["surface","vault"] else 0.0)
func depart() -> bool:
	if phase != "ready": error = "需要宝库击破、威胁清除、所有物资到账"; return false
	if planet == 2: phase = "finished"; notify("远征完成 · 三颗星球已征服"); return true
	planet += 1; make_planet(); facts["arrival_"+str(planet)] = true; return true
func emergency() -> void:
	if retreat > 0 or phase == "finished": return
	retreat = 8.0; turn = 0; nuclear_armed = false; facts["retreated"] = true; notify("安全撤离中 · 8 秒后免费修复，星球与货物保留")
func restore_gifts() -> void:
	for s in ships:
		if s.gift == "" or s.kind != "frigate" or equipment(s,"kinetic") > 0: continue
		var recovered: int = -1
		for m in modules:
			if m.kind == "kinetic" and m.paid == 0 and not installed_ids().has(m.id):
				recovered = m.id; break
		if recovered < 0: recovered = new_module("kinetic",true)
		var slot: int = s.slots.find(-1); s.slots[maxi(0,slot)] = recovered
func sell_treasure(id: int) -> bool:
	var item: Dictionary = find_id(inventory,id)
	if item.is_empty() or item.sold or item.locked: return false
	item.sold = true; wallet += item.value; return true
func tutorial() -> Dictionary:
	return Guide.choose(self)

func snapshot() -> Dictionary:
	var data: Dictionary = {"version":3,"design":"0.3.2"}
	for key in FIELDS: data[key] = get(key)
	return data.duplicate(true)
func restore(data: Dictionary) -> bool:
	if data.get("version",0) != 3: return false
	for key in FIELDS:
		if not data.has(key) or typeof(data[key]) != typeof(get(key)): return false
	if data.planet < 0 or data.planet > 2 or data.regions.size() != int(C.PLANETS[data.planet].regions): return false
	if data.ships.is_empty() or data.drones.is_empty() or data.wallet < 0: return false
	if data.phase not in ["surface","vault","recovery","ready","finished"] or data.focus_group not in ["all","ap","normal"]: return false
	if not is_finite(data.wallet) or not is_finite(data.angle): return false
	for key in data.levels:
		if not key is String or not data.levels[key] is int or data.levels[key] < 0: return false
		var cap: int = {"command":3,"hangar":3,"cargo":8,"speed":5,"special":2,"nuclear_auto":1,"destroyer:reload":3,"plate:strength":3,"repair:strength":3,"energy:strength":3}.get(key,6)
		if data.levels[key] > cap: return false
	for r in data.regions:
		if not r is Dictionary or not r.has_all(["stock","max","lon"]): return false
		for key in ["stock","max","lon"]:
			if not numeric(r[key]): return false
		if r.stock < 0 or r.stock > r.max: return false
	var seen: Array = []
	for items in [data.ships,data.modules,data.drones,data.targets,data.threats,data.loot,data.inventory]:
		for item in items:
			if not item is Dictionary or not item.get("id") is int or seen.has(item.id): return false
			seen.append(item.id)
	for s in data.ships:
		if not s is Dictionary or not s.has_all(["id","kind","slots","hp","armor","paid","gift"]) or not C.HULLS.has(s.kind): return false
		if not s.slots is Array or not numeric(s.hp) or not numeric(s.armor) or s.hp < 0 or s.armor < 0: return false
	for m in data.modules:
		if not m is Dictionary or not m.has_all(["id","kind","paid","cool","cycle","beam","beam_clock","beam_target","beam_power"]): return false
		if not C.WEAPONS.has(m.kind) and not C.GEAR.has(m.kind): return false
		for key in ["cool","cycle","beam_clock","beam_power","paid"]:
			if not numeric(m[key]): return false
	var used: Array = []
	for s in data.ships:
		for id in s.slots:
			if not id is int: return false
			if id >= 0:
				if find_id(data.modules,id).is_empty() or used.has(id): return false
				used.append(id)
	for d in data.drones:
		if not d.has_all(["carrier","paid","time","duration","cargo","treasure","lon"]) or not d.treasure is Dictionary: return false
		if find_id(data.ships,d.carrier).is_empty(): return false
		for key in ["time","duration","cargo","lon"]:
			if not numeric(d[key]): return false
		if d.time < 0 or d.duration <= 0 or d.cargo < 0: return false
	for t in data.targets:
		if not t.has_all(["kind","lon","hp","max_hp","armor","max_armor","cool","visible"]): return false
		if t.kind not in ["battery","silo","vault"]: return false
	for t in data.threats:
		if not t.has_all(["kind","hp","time","duration","target","lon","x"]): return false
		if t.kind not in ["missile","aircraft"]: return false
	for p in data.projectiles:
		if not p is Dictionary or not p.has_all(["kind","ship","x","target","power","time","duration"]) or not C.WEAPONS.has(p.kind): return false
	for items in [data.loot,data.inventory]:
		for item in items:
			if not item.has_all(["kind","lon","value"]) or item.kind not in ["metal","treasure"]: return false
	for kind in C.HULLS:
		if not data.templates.has(kind) or not data.templates[kind] is Array or data.templates[kind].is_empty(): return false
		for loadout in data.templates[kind]:
			if not loadout is Array: return false
			for key in loadout:
				if not key is String or (key != "" and not C.WEAPONS.has(key) and not C.GEAR.has(key)): return false
	for key in FIELDS: set(key,data[key].duplicate(true) if data[key] is Array or data[key] is Dictionary else data[key])
	turn = 0; nuclear_armed = false; events.clear(); return true
func numeric(value: Variant) -> bool: return (value is float or value is int) and is_finite(float(value))
func save_to(path: String) -> Error:
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_var(snapshot()); file.close(); return DirAccess.rename_absolute(path+".tmp",path)
func load_from(path: String) -> bool:
	if not FileAccess.file_exists(path): return false
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null: return false
	var data = file.get_var(false)
	return restore(data) if data is Dictionary else false
