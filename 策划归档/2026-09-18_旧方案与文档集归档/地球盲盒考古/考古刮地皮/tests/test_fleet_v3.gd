extends SceneTree
const M = preload("res://scripts/fleet/simulation.gd")
const C = preload("res://scripts/fleet/catalog.gd")
var failures: int = 0
var checks: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)
func advance(m, seconds: float) -> void:
	for i in range(ceili(seconds/0.05)): m.tick(0.05); m.events.clear()
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var m = M.new()
	check(m.wallet == 0 and m.ships.size() == 3 and m.drones.size() == 2,"gift fleet")
	check(m.command_used() == 3 and m.command_max() == 6,"command start")
	advance(m,4.5); check(m.wallet > 0,"automatic income within 8 seconds")
	check(is_equal_approx(m.conserved(),2400),"first planet conserved")
	var original: float = m.unextracted(); m.turn = 1; advance(m,8); m.turn = 0
	check(is_equal_approx(m.angle,0) and m.unextracted() < original,"full ring rotation continues production")
	check(is_equal_approx(m.conserved(),2400),"rotation conserves metal")
	var isolated = M.new(); isolated.ships.clear(); isolated.drones.clear()
	var before: float = isolated.regions[0].stock
	isolated.projectiles.append({"kind":"kinetic","ship":0,"x":0.5,"target":-1,"power":1.0,"time":0.35,"duration":0.35})
	isolated.angle = 100; advance(isolated,0.4)
	check(isolated.regions[0].stock == before and isolated.regions[2].stock < before,"impact uses current rotation")
	isolated.extract(100,10000); var generated: float = isolated.ground_value(); isolated.extract(100,10000)
	check(isolated.ground_value() == generated,"depleted ground never regenerates")
	var economy = M.new(); economy.wallet = 5000
	check(not economy.purchase("carrier",["kinetic",""]),"carrier rejects bombardment")
	check(economy.wallet == 5000,"invalid transaction atomic")
	check(not economy.purchase("frigate",["kinetic","kinetic"],4),"batch respects command")
	check(economy.wallet == 5000,"invalid batch no partial charge")
	check(economy.purchase("frigate",["kinetic",""]),"single cannon tutorial build")
	var s: Dictionary = economy.ships.back(); s.hp = economy.max_hp(s)*0.5; s.armor = economy.max_armor(s)*0.5
	var id: int = s.slots[0]; economy.module(id).cool = 0.75
	check(economy.purchase("frigate",["kinetic","kinetic"],1,s.id),"refit succeeds")
	check(is_equal_approx(s.hp/economy.max_hp(s),0.5) and economy.module(s.slots[1]).cool >= 0.75,"refit preserves wounds and cooldown")
	check(economy.upgrade("frigate:hp") and is_equal_approx(s.hp/economy.max_hp(s),0.5),"hull upgrade preserves damage ratio")
	check(not economy.sell_ship(s.id),"retire cannot heal damaged ship by rebuy")
	economy.planet = 1; economy.make_planet()
	check(not economy.research("ap"),"weapon chain prerequisite")
	check(economy.research("aa") and economy.research("ap"),"chain does not require branch max or installed module")
	check(economy.level("aa:attack") == 0,"research independence")
	var target: Dictionary = economy.targets.back(); var hp: float = target.hp
	economy.impact("laser",target.id,0.5,1); check(target.hp == hp and target.armor == target.max_armor,"laser cannot bypass armor")
	economy.impact("ap",target.id,0.5,100); check(target.armor == 0 and target.hp == hp,"armor damage has no HP overflow")
	var d: Dictionary = economy.drones[0]; economy.drop_metal(180,100); economy.transport(0.01)
	var time: float = d.duration; economy.angle = 180; economy.upgrade("speed")
	check(d.duration == time,"inflight route snapshot")
	var snapshot: Dictionary = economy.snapshot(); var copy = M.new()
	check(copy.restore(snapshot) and copy.snapshot() == snapshot,"save roundtrip")
	check(not copy.restore({"version":1}) and copy.snapshot() == snapshot,"old version rejected without mutation")
	var wave: float = copy.wave_clock; var cargo: float = copy.transit_value(); copy.emergency(); advance(copy,8.1)
	check(copy.retreat == 0 and copy.wave_clock < wave and copy.wave_clock > wave-0.2,"retreat keeps enemy wave clock")
	check(copy.transit_value() <= cargo,"retreat cargo preserved")
	var laser = M.new(); laser.wallet = 10000; laser.planet = 1; laser.make_planet(); laser.researched.append_array(["aa","ap","laser"])
	laser.purchase("frigate",["laser",""],1,laser.ships[0].id)
	var gun: Dictionary = laser.module(laser.ships[0].slots[0]); laser.tick(0.01); advance(laser,1.0)
	check(gun.beam > 0 and gun.cool == 0,"laser fixed duration before reload")
	advance(laser,1.1); check(gun.beam == 0 and gun.cool > 3.7,"laser reload after full beam")
	var nuclear = M.new(); nuclear.wallet = 100000; nuclear.planet = 2; nuclear.make_planet(); nuclear.researched.append_array(["destroyer","aa","ap","laser","neutron"])
	nuclear.upgrade("command"); nuclear.upgrade("special")
	check(not nuclear.purchase("frigate",["neutron",""]),"neutron cannot use normal slot")
	check(nuclear.purchase("destroyer",["","","","","","","","","neutron"]),"destroyer special slot")
	nuclear.angle = 180; var stock: float = nuclear.unextracted(); check(nuclear.fire_neutron(0.5),"manual neutron fire")
	check(is_equal_approx(stock-nuclear.unextracted(),12000),"neutron primary and two half neighbors")
	check(nuclear.upgrade("nuclear_auto"),"automation requires actual manual shot")
	check(not nuclear.fire_neutron(0.5),"neutron reload enforced")
	additional_checks()
	full_expedition()
	print("FLEET V3 CHECKS: %d, failures: %d" % [checks,failures]); quit(1 if failures > 0 else 0)

func additional_checks() -> void:
	var m = M.new(); m.wallet = 200
	var ids: Array = [m.ships[0].id,m.ships[1].id]
	check(m.group_trial(ids,["kinetic",""]).price == 0,"group reuses owned modules before buying")
	check(m.refit_group(ids,["kinetic",""]),"group refit atomic success")
	check(m.installed_ids().filter(func(id): return id >= 0).size() == 2,"group unloads unused modules")
	var snapshot: Dictionary = m.snapshot(); m.wallet = 0
	check(not m.refit_group(ids,["repair","repair"]),"unaffordable group refused")
	check(m.installed_ids().filter(func(id): return id >= 0).size() == 2,"group failure no partial refit")
	m.restore(snapshot); m.purchase("frigate",["kinetic",""],1,m.ships[0].id); advance(m,1)
	check(not m.facts.get("refit_fired",false),"unchanged loadout does not verify tutorial refit")
	var file: String = "user://fleet_v3_test_only.save"
	check(m.save_to(file) == OK,"save file created")
	advance(m,1); check(m.save_to(file) == OK,"atomic overwrite existing save")
	var copy = M.new(); check(copy.load_from(file) and copy.snapshot() == m.snapshot(),"file save reload")
	DirAccess.remove_absolute(file)
	var corrupt: Dictionary = m.snapshot(); corrupt.modules[0].erase("cool")
	check(not copy.restore(corrupt),"corrupt nested module rejected")
	corrupt = m.snapshot(); corrupt.levels.command = 99; check(not copy.restore(corrupt),"corrupt capacity rejected")
	var soft = M.new(); soft.wallet = 0
	for s in soft.ships:
		if s.kind == "frigate": soft.purchase("frigate",["",""],1,s.id)
	for mod in soft.modules.duplicate(): soft.sell_module(mod.id)
	for s in soft.ships: s.hp = 0
	soft.emergency(); advance(soft,13)
	check(soft.has_installed("kinetic") and soft.wallet > 0,"zero wallet zero guns disabled fleet can recover")
	var guided = M.new(); guided.facts.income = true; guided.facts.bought_fired = true; guided.wallet = 500
	check(guided.tutorial().id != "G04","full starter ships do not force empty slot refit")
	guided.tutorial_enabled = false; check(guided.tutorial().is_empty(),"guide disabled persists without granting facts")
	stress(false); stress(true)
func stress(extreme: bool) -> void:
	var m = M.new(); m.ships.clear(); m.drones.clear(); m.modules.clear(); m.levels.hangar = 3; m.levels.command = 3; m.planet = 2; m.make_planet()
	for i in range(48):
		var carrier: bool = extreme or i >= 36
		var s: Dictionary = m.add_ship("carrier" if carrier else "frigate",["aa","aa"] if carrier else ["kinetic","kinetic"])
		if carrier:
			for j in range(8): m.add_drone(s.id)
	var start: int = Time.get_ticks_usec(); var peak: int = 0
	for i in range(400):
		var frame: int = Time.get_ticks_usec(); m.tick(0.05); m.events.clear(); peak = maxi(peak,Time.get_ticks_usec()-frame)
	print("Stress %d hulls / %d raiders: average %.3f ms, peak %.3f ms per tick (headless)" % [m.ships.size(),m.drones.size(),float(Time.get_ticks_usec()-start)/400/1000,peak/1000.0])
	check(m.command_used() <= 48 and m.drones.size() == (384 if extreme else 96),"stress capacity valid")

func full_expedition() -> void:
	var m = M.new(); var actions: Array = []; var stage: int = -1; var last_planet_time: float = 0; var repair_count: int = 0
	for frame in range(60000):
		if stage != m.planet:
			stage = m.planet; actions = plan(stage)
		if not actions.is_empty() and attempt(m,actions[0]): actions.pop_front()
		if m.retreat <= 0:
			var disabled: int = 0
			for s in m.ships:
				if s.hp <= 0: disabled += 1
			if disabled >= maxi(1,m.ships.size()/3): m.emergency(); repair_count += 1
		var alive: Array = []
		for t in m.targets:
			if t.hp > 0: alive.append(t)
		if not alive.is_empty() and (m.planet == 0 or m.has_installed("ap")):
			var t: Dictionary = alive[0]; var delta: float = wrapf(t.lon-m.angle,-180,180)
			if absf(delta) > 3: m.turn = signf(delta)
			else: m.turn = 0; m.command(t.id)
		else:
			m.focus = -1; var below: bool = false
			for i in range(m.ships.size()):
				if m.ships[i].kind != "carrier" and m.regions[m.region_at(m.longitude(m.ship_x(i)))].stock > 0: below = true
			m.turn = 0 if below else 1
		if m.has_installed("neutron") and not m.facts.get("manual_neutron",false): m.fire_neutron(0.5,m.focus)
		m.tick(0.05); m.events.clear()
		if frame % 100 == 0: check(absf(m.conserved()-(2400 if stage == 0 else 36000 if stage == 1 else 300000)) < 0.01,"planet conservation during full expedition")
		if m.phase == "ready":
			print("Planet %d: %.1fs, wallet %.0f, fleet %d, raiders %d, pending purchases %d" % [stage+1,m.elapsed-last_planet_time,m.wallet,m.ships.size(),m.drones.size(),actions.size()]); last_planet_time = m.elapsed
			check(m.depart(),"safe departure")
		if m.phase == "finished": break
	check(m.phase == "finished","zero cheat three planet expedition completes")
	check(m.inventory.size() == 3 and is_equal_approx(m.earned,338400),"all metal and three treasures returned")
	print("Zero-cheat expedition: %.1fs, repairs %d, wallet %.0f" % [m.elapsed,repair_count,m.wallet])
func attempt(m, a: Array) -> bool:
	match a[0]:
		"u": return m.upgrade(a[1])
		"r": return m.research(a[1])
		"b": return m.purchase(a[1],a[2])
		"d":
			for s in m.ships:
				if s.kind == "carrier" and m.carrier_load(s.id) < m.hangar_max(): return m.buy_raider(s.id)
			return false
		"fit":
			for s in m.ships:
				if s.kind == "carrier" and m.equipment(s,"aa") == 0: return m.purchase("carrier",["aa",""],1,s.id)
			return true
		"auto": return m.upgrade("nuclear_auto")
	return false
func plan(p: int) -> Array:
	if p == 0: return [["b","frigate",["kinetic","kinetic"]],["u","kinetic:attack"],["u","cargo"],["u","speed"],["u","command"],["b","frigate",["kinetic","kinetic"]],["u","hangar"],["d"],["d"]]
	if p == 1:
		var a: Array = [["r","aa"],["fit"],["r","ap"],["r","cruiser"],["b","cruiser",["kinetic","kinetic","ap","aa"]],["u","cargo"],["u","speed"],["u","kinetic:attack"],["u","kinetic:attack"],["u","command"]]
		for i in range(5): a.append(["b","cruiser",["kinetic","kinetic","ap","aa"]])
		a.append_array([["b","carrier",["",""]],["b","carrier",["",""]],["u","cargo"]])
		for i in range(8): a.append(["d"])
		return a
	var a: Array = [["u","aa:attack"],["u","aa:attack"],["u","aa:attack"],["u","cargo"],["u","cargo"],["u","cargo"],["u","speed"],["u","kinetic:attack"],["u","kinetic:attack"],["u","kinetic:attack"],["u","command"],["r","laser"],["r","battleship"],["r","destroyer"],["r","neutron"],["u","special"],["b","destroyer",["kinetic","kinetic","kinetic","kinetic","kinetic","kinetic","kinetic","kinetic","neutron"]],["auto"]]
	for i in range(6): a.append(["b","battleship",["kinetic","kinetic","kinetic","kinetic","ap","aa"]])
	for i in range(3): a.append(["b","carrier",["",""]])
	for i in range(12): a.append(["d"])
	return a
