extends "res://scripts/ea/model.gd"

const DIG_SECONDS := 20.0
const DEPTH_MULTIPLIER := 5.0
const POWER_MULTIPLIER := 1.2
const MIN_DIG_SECONDS := 2.0
const RANGE_MULTIPLIER := 1.1
const MAX_RANGE_LEVEL := 5
const DIG_RADIUS := 72.0
const GOLD_CHANCE_PER_10000 := 200
const MAX_SHOVELS := 10
const SHOVEL_PRICES := [60,120,220,360,550,800,1100,1500,2000]
const HUD_POINT := Vector2(43,51)
const SPRITE_OFFSET := Vector2(0,-48)
const RETURN_SECONDS := 0.75
var shovel_count := 1
var power_level := 0
var range_level := 0
var shovels: Array = []
var soil_changed_this_tick := false
# Read-only migration inputs for saves made by the single-shovel prototype.
var shovel_position := Vector2(110,145)
var shovel_job: Dictionary = {}

func _ensure_shovels() -> void:
	while shovels.size()<shovel_count:
		shovels.append({"phase":"idle","position":HUD_POINT,"job":{},"flight_time":0.0,"flight_duration":0.75,"flight_from":HUD_POINT})

func idle_count() -> int:
	_ensure_shovels()
	var count := 0
	for unit in shovels:
		if unit.phase=="idle": count+=1
	return count

func next_shovel_price() -> int:
	return SHOVEL_PRICES[shovel_count-1] if shovel_count<MAX_SHOVELS else 0

func shovel_purchase_reason() -> String:
	if shovel_count>=MAX_SHOVELS: return "已达到 10 把上限"
	if paused: return "暂停中"
	var cost := Decimal.new(str(next_shovel_price()))
	if wallet.compare(cost)<0: return "还差 %s 点"%cost.minus(wallet).ceil_value().display()
	return ""

func buy_shovel() -> bool:
	if not shovel_purchase_reason().is_empty(): return false
	wallet=wallet.minus(Decimal.new(str(next_shovel_price())))
	shovel_count+=1
	_ensure_shovels()
	touch()
	return true

func upgrade_price(level: int, base: int, multiplier_tenths: int) -> RefCounted:
	# Round to the nearest ten without converting the exact wallet currency to float.
	var rounded: RefCounted = C.growth(level,base,multiplier_tenths,1).plus(Decimal.new("5")).floor_value()
	return Decimal.new(rounded.digits.left(-1)+"0")

func power_price() -> RefCounted:
	return upgrade_price(power_level,100,18)

func power_purchase_reason() -> String:
	if paused: return "暂停中"
	var cost := power_price()
	if wallet.compare(cost)<0: return "还差 %s 点"%cost.minus(wallet).ceil_value().display()
	return ""

func buy_power() -> bool:
	if not power_purchase_reason().is_empty(): return false
	wallet=wallet.minus(power_price()); power_level+=1
	touch()
	return true

func dig_radius(level: int = -1) -> float:
	return DIG_RADIUS*pow(RANGE_MULTIPLIER,range_level if level<0 else level)

func range_price() -> RefCounted:
	return upgrade_price(range_level,200,16)

func range_purchase_reason() -> String:
	if range_level>=MAX_RANGE_LEVEL: return "范围已满级"
	if paused: return "暂停中"
	var cost := range_price()
	if wallet.compare(cost)<0: return "还差 %s 点"%cost.minus(wallet).ceil_value().display()
	return ""

func buy_range() -> bool:
	if not range_purchase_reason().is_empty(): return false
	wallet=wallet.minus(range_price()); range_level+=1
	touch()
	return true

func scratch(_from: Vector2, _to: Vector2, _delta: float, _radius: float = -1.0, _robot: bool = false) -> float:
	return 0.0

func scrap_reward(layer: Dictionary, find: Dictionary) -> RefCounted:
	if not find.has("shovel_reward"):
		# Stable per find: recalls, different worker order and reloads never reroll
		# rewards or alter the terrain RNG used to generate future layers.
		var reward_rng := RandomNumberGenerator.new()
		reward_rng.seed=int(layer.seed) ^ (int(find.id)*104729)
		find.shovel_reward=10 if reward_rng.randi_range(0,9999)<GOLD_CHANCE_PER_10000 else reward_rng.randi_range(1,5)
	find.value=int(find.shovel_reward)
	return Decimal.new(str(find.value))

func recall(index: int) -> bool:
	if paused or index<0 or index>=shovels.size(): return false
	var unit: Dictionary = shovels[index]
	if unit.phase not in ["moving","digging"]: return false
	# No soil pixels are cleared until completion. Dropping the job resets its
	# timer/cracks and releases reservations; collected finds stay paid once.
	_return_home(unit)
	notices.append("已召回铲子 · 此处挖掘进度归零")
	touch()
	return true

func unit_draw_position(unit: Dictionary) -> Vector2:
	var point: Vector2 = unit.position
	if unit.phase=="digging" and not reduce_fx:
		point.y-=absf(sin(float(unit.job.time)*PI*2.2))*15.0
	return point

func extra_save_state() -> Dictionary:
	_ensure_shovels()
	return {"shovel_count":shovel_count,"shovels":shovels,"power_level":power_level,"range_level":range_level}

func dig_seconds(depth: int, level: int = -1) -> float:
	# Saturate only beyond practical floating-point durations, never wrap to INF.
	var strength := power_level if level<0 else level
	var exponent := log(DIG_SECONDS)+maxi(0,depth-1)*log(DEPTH_MULTIPLIER)-strength*log(POWER_MULTIPLIER)
	return maxf(MIN_DIG_SECONDS,exp(minf(exponent,log(1.0e300))))

func circle_pixels(point: Vector2, radius_world: float = -1.0) -> PackedInt32Array:
	var factor := WIDTH/WORLD_WIDTH
	var center := point*factor
	var radius := (dig_radius() if radius_world<0 else radius_world)*factor
	var pixels := PackedInt32Array()
	for y in range(maxi(0,int(floor(center.y-radius))),mini(HEIGHT,int(ceil(center.y+radius))+1)):
		for x in range(maxi(0,int(floor(center.x-radius))),mini(WIDTH,int(ceil(center.x+radius))+1)):
			if Vector2(x+0.5,y+0.5).distance_squared_to(center)<=radius*radius: pixels.append(y*WIDTH+x)
	return pixels

func top_layer_in_circle(pixels: PackedInt32Array) -> int:
	# Include occupied soil: another shovel reserving it is not permission to
	# bypass it and dig a deeper layer within the same circle.
	for i in range(layers.size()):
		for pixel in pixels:
			if layers[i].mask[pixel]!=0: return i
	return layers.size()

func load_from(path: String = "user://shovel_save.dat") -> bool:
	# The parent reader assigns saved properties, including legacy migration inputs.
	var old_units: Array = shovels
	var old_power := power_level
	var old_range := range_level
	shovels=[]; shovel_job={}; power_level=0; range_level=0
	if not super.load_from(path): shovels=old_units; power_level=old_power; range_level=old_range; return false
	shovel_count=clampi(shovel_count,1,MAX_SHOVELS)
	var legacy := shovels.is_empty()
	_ensure_shovels()
	if legacy and not shovel_job.is_empty():
		var unit: Dictionary = shovels[0]
		unit.job=shovel_job
		unit.position=shovel_position+SPRITE_OFFSET
		unit.phase=shovel_job.phase
		unit.flight_from=unit.position
		unit.flight_duration=0.6
	shovel_job={}
	for unit in shovels:
		if unit.phase not in ["moving","digging"]: continue
		var job: Dictionary = unit.job
		if not job.has("duration"): job.duration=dig_seconds(int(job.depth))
		if not job.has("radius"): job.radius=DIG_RADIUS
		var top := top_layer_in_circle(circle_pixels(job.target,float(job.radius)))
		if top>=layers.size() or int(layers[top].depth)!=int(job.depth):
			_return_home(unit)
			notices.append("旧任务已召回 · 挖掘范围内需先清理最上层")
	auto_enabled=false
	return true

func dispatch(point: Vector2) -> bool:
	if paused or not Rect2(Vector2.ZERO,C.WORLD).has_point(point): return false
	_ensure_shovels()
	var free := -1
	for i in range(shovels.size()):
		if shovels[i].phase=="idle": free=i; break
	if free<0: return false
	var footprint := circle_pixels(point)
	var layer_index := top_layer_in_circle(footprint)
	if layer_index>=layers.size(): return false
	var depth: int = layers[layer_index].depth
	var reserved := {}
	var reserved_scraps := {}
	for unit in shovels:
		if unit.phase not in ["moving","digging"] or int(unit.job.depth)!=depth: continue
		for pixel in unit.job.pixels: reserved[pixel]=true
		for id in unit.job.scraps: reserved_scraps[id]=true
	var factor := WIDTH/WORLD_WIDTH
	var pixels := PackedInt32Array()
	var selected := {}
	for pixel in footprint:
		if layers[layer_index].mask[pixel]==0 or reserved.has(pixel): continue
		pixels.append(pixel); selected[pixel]=true
	if pixels.is_empty(): return false
	var scraps: Array[int] = []
	for find in layers[layer_index].finds:
		if find.kind!="scrap" or find.collected or reserved_scraps.has(find.id): continue
		var eligible := true
		var lo: Vector2 = ((find.position-find.size*0.5)*factor).floor()
		var hi: Vector2 = ((find.position+find.size*0.5)*factor).ceil()
		for y in range(maxi(0,int(lo.y)),mini(HEIGHT,int(hi.y)+1)):
			for x in range(maxi(0,int(lo.x)),mini(WIDTH,int(hi.x)+1)):
				var pixel := y*WIDTH+x
				if layers[layer_index].mask[pixel]!=0 and not selected.has(pixel): eligible=false
				for upper in range(layer_index):
					if layers[upper].mask[pixel]!=0: eligible=false
		if eligible: scraps.append(find.id)
	var unit: Dictionary = shovels[free]
	unit.job={"target":point,"depth":depth,"pixels":pixels,"scraps":scraps,"paid":0,"time":0.0,"duration":dig_seconds(depth),"radius":dig_radius()}
	unit.phase="moving"; unit.position=HUD_POINT; unit.flight_from=HUD_POINT; unit.flight_time=0.0
	unit.flight_duration=clampf(HUD_POINT.distance_to(point+SPRITE_OFFSET)/900.0,0.45,1.1)
	started=true
	touch()
	return true

func tick(delta: float) -> void:
	if paused: return
	_ensure_shovels()
	auto_enabled=false
	soil_changed_this_tick=false
	for unit in shovels: _step_unit(unit,delta)
	# All units use absolute depths, so rolling a finished layer cannot retarget them.
	if soil_changed_this_tick:
		scan_exposed_finds()
		advance_layers()
	super.tick(delta)

func _tick_machines(_delta: float) -> void:
	pass # Legacy processing upgrades and automation are suspended in this mode.

func _step_unit(unit: Dictionary, delta: float) -> void:
	if unit.phase=="idle": return
	if unit.phase in ["moving","returning"]:
		unit.flight_time=minf(float(unit.flight_duration),float(unit.flight_time)+delta)
		var t := float(unit.flight_time)/float(unit.flight_duration)
		var eased := t*t*(3.0-2.0*t)
		var destination: Vector2 = HUD_POINT if unit.phase=="returning" else unit.job.target+SPRITE_OFFSET
		unit.position=(unit.flight_from as Vector2).lerp(destination,eased)+Vector2(0,-sin(t*PI)*36.0)
		if t>=1.0:
			unit.position=destination
			unit.phase="idle" if unit.phase=="returning" else "digging"
			touch()
		return
	var job: Dictionary = unit.job
	var layer_index := int(job.depth)-base_depth
	if layer_index<0 or layer_index>=layers.size(): _return_home(unit); return
	var duration: float = job.duration
	job.time=minf(duration,float(job.time)+delta)
	if float(job.time)>=duration-0.000001: job.time=duration
	var due := int(floor(job.scraps.size()*float(job.time)/duration))
	while int(job.paid)<due:
		var id: int = job.scraps[int(job.paid)]; job.paid+=1
		for find in layers[layer_index].finds:
			if find.id!=id or find.collected: continue
			find.collected=true
			var before := wallet.floor_value()
			var reward: RefCounted = scrap_reward(layers[layer_index],find)
			wallet=wallet.plus(reward); earned=earned.plus(reward)
			recent_finds.append({"kind":"scrap","position":find.position,"text":"+"+wallet.floor_value().minus(before).display(),"premium":find.value==10})
	if float(job.time)<duration: return
	var layer: Dictionary = layers[layer_index]
	for pixel in job.pixels:
		if layer.mask[pixel]!=0:
			layer.mask[pixel]=0; layer.wear[pixel]=1.0; layer.cleared+=1
	layer.dirty=true
	soil_changed_this_tick=true
	deepest=maxi(deepest,int(layer.depth))
	_return_home(unit)
	notices.append("挖掘完成 · 铲子正在返回")
	touch()

func _return_home(unit: Dictionary) -> void:
	unit.return_scale=unit_scale(unit)
	unit.position=unit_draw_position(unit)
	unit.phase="returning"; unit.flight_from=unit.position; unit.flight_time=0.0
	unit.flight_duration=RETURN_SECONDS; unit.job={}

func unit_scale(unit: Dictionary) -> float:
	if unit.phase=="moving": return lerpf(0.34,1.0,float(unit.flight_time)/float(unit.flight_duration))
	if unit.phase=="returning": return lerpf(float(unit.get("return_scale",1.0)),0.34,float(unit.flight_time)/float(unit.flight_duration))
	return 1.0

func purchase_reason(_kind: String) -> String: return "旧升级系统已停用"
func machine_reason(_index: int) -> String: return "旧升级系统已停用"
func analyzer_reason() -> String: return "旧升级系统已停用"
func buy_talent(_id: String) -> bool: return false
func reserve() -> RefCounted: return Decimal.new()
