extends RefCounted
const C = preload("res://scripts/ea/config.gd")
const Decimal = preload("res://scripts/ea/decimal.gd")
const WIDTH := C.WIDTH
const HEIGHT := C.HEIGHT
const PIXELS := WIDTH*HEIGHT
const WORLD_WIDTH := 1096.0
const WORLD_HEIGHT := 822.0
const SOIL_COLORS := [Color("624f41"),Color("88724a"),Color("676b5f"),Color("5a5241"),Color("33312f")]

signal changed
signal layers_shifted(count: int)

var wallet := Decimal.new()
var earned := Decimal.new()
var layers: Array[Dictionary] = []
var levels := {"power":0,"radius":0,"auto":0,"auto_power":0,"auto_radius":0,"auto_move":0,"opening":0}
var records: Array[Dictionary] = []
var discovered: Dictionary = {}
var series_seen := [false,false,false,false,false]
var identified_series := [false,false,false,false,false]
var draws := [[],[],[],[],[]]
var duplicate_streak := [0,0,0,0,0]
var rng := RandomNumberGenerator.new()
var base_depth := 1
var next_id := 1
var elapsed := 0.0
var paused := false
var started := false
var recent_finds: Array[Dictionary] = []
var notices: Array[String] = []
var machines: Array[Dictionary] = []
var robots: Array[Dictionary] = []
var auto_points: Array[Vector2] = []
var auto_enabled := true
var knowledge := 0
var awarded_sets: Dictionary = {}
var talents: Dictionary = {}
var analyzer := false
var queue_priority := 0
var auto_sell := false
var priority_series := -1
var presets := [{},{}]
var reduce_fx := false
var skip_repeat := false
var brush_work := 0.0
var last_removed_depth := 0
var deepest := 1
var texture_paths: Array[String] = []
var revision := 0
var scan_clock := 0.0
var reserve_key := ""
var reserve_value := Decimal.new()

func _init(seed_value: int = 5000913) -> void:
	rng.seed = seed_value
	var dir := DirAccess.open("res://assets/soil/RealSoil")
	if dir:
		for file in dir.get_files():
			if file.get_extension().to_lower() in ["png","jpg","webp"]:
				texture_paths.append("res://assets/soil/RealSoil/"+file)
	texture_paths.sort()
	if texture_paths.is_empty(): texture_paths.append("res://assets/soil/layer_01_red.png")
	for i in range(6): machines.append({"owned":false,"enabled":true,"task":-1})
	for i in range(3):
		robots.append({"p":Vector2(180+i*300,200+i*100),"target":Vector2(180+i*300,200+i*100),"direction":Vector2.RIGHT.rotated(rng.randf_range(0,TAU))})
		auto_points.append(robots[i].p)
	for d in range(1,6): _append_layer(d)
	
func touch() -> void:
	revision += 1
	changed.emit()

func _append_layer(depth: int) -> void:
	var scale: RefCounted = C.growth(depth-1) if layers.is_empty() else amount(layers.back().scale).times(118,2)
	var choices := texture_paths.duplicate()
	if choices.size()>1 and not layers.is_empty(): choices.erase(layers.back().texture)
	var texture: String = choices[rng.randi_range(0,choices.size()-1)]
	var wear := PackedFloat64Array()
	wear.resize(PIXELS)
	var mask := PackedByteArray()
	mask.resize(PIXELS); mask.fill(255)
	var layer := {"depth":depth,"texture":texture,"seed":rng.state,"scale":scale.data(),"wear":wear,"mask":mask,"cleared":0,"dirty":true,"finds":[]}
	for i in range(C.SCRAP_COUNT):
		var p := Vector2((i%30+rng.randf_range(0.18,0.82))*WORLD_WIDTH/30.0,(i/30+rng.randf_range(0.18,0.82))*WORLD_HEIGHT/20.0)
		layer.finds.append({"id":next_id,"kind":"scrap","position":p,"size":Vector2(5,5),"value":10 if i%20==19 else 1,"collected":false})
		next_id += 1
	for i in range(C.ARTIFACT_COUNT):
		var series := (depth-1)%5
		var variant := _draw_variant(series)
		layer.finds.append({"id":next_id,"kind":"artifact","position":Vector2(rng.randf_range(35,1061),rng.randf_range(35,787)),"size":Vector2(24,24),"series":series,"variant":variant,"collected":false})
		next_id += 1
	layers.append(layer)

func _draw_variant(series: int) -> int:
	var missing: Array[int] = []
	for i in range(5):
		if not i in draws[series]: missing.append(i)
	var variant := rng.randi_range(0,4)
	# Reserve distinct variants for already generated, unopened items too.
	if not missing.is_empty() and (draws[series].size()<3 or duplicate_streak[series]>=2):
		variant = missing[rng.randi_range(0,missing.size()-1)]
	if variant in draws[series]: duplicate_streak[series] += 1
	else:
		draws[series].append(variant)
		duplicate_streak[series] = 0
	return variant

func amount(data: Dictionary) -> RefCounted: return Decimal.new(data.digits,int(data.places))
func get_radius() -> float: return C.radius(levels.radius)
func robot_radius() -> float: return C.radius(levels.auto_radius,true)
func efficiency(index: int, robot: bool = false) -> float:
	return C.efficiency(levels.auto_power if robot else levels.power,int(layers[index].depth))
func progress(index: int) -> float: return float(layers[index].cleared)/PIXELS
func progress_text(index: int) -> String:
	return "100%" if layers[index].cleared==PIXELS else "%.1f%%" % minf(97.9,floor(progress(index)*1000.0)/10.0)
func total_progress() -> float:
	var total := 0.0
	for i in range(5): total += progress(i)
	return total/5.0

func surface_at(point: Vector2) -> int:
	var x := clampi(int(point.x/WORLD_WIDTH*WIDTH),0,WIDTH-1)
	var y := clampi(int(point.y/WORLD_HEIGHT*HEIGHT),0,HEIGHT-1)
	for i in range(5):
		if layers[i].mask[y*WIDTH+x] != 0: return i
	return 5

func scratch(from: Vector2,to: Vector2,delta: float,radius: float = -1.0,robot: bool = false) -> float:
	if paused or delta<=0: return 0.0
	started = true
	var factor := WIDTH/WORLD_WIDTH
	var a := from*factor
	var b := to*factor
	var r := (get_radius() if radius<0 else radius)*factor
	var ab := b-a
	var length_sq := ab.length_squared()
	var work := 0.0
	var touched := {}
	var rates: Array[float] = []
	for i in range(5): rates.append(C.WEAR*efficiency(i,robot)*delta)
	var left := maxi(0,int(floor(minf(a.x,b.x)-r)))
	var top := maxi(0,int(floor(minf(a.y,b.y)-r)))
	left -= left%4; top -= top%4
	for cy in range(top,mini(HEIGHT,int(ceil(maxf(a.y,b.y)+r))+1),4):
		for cx in range(left,mini(WIDTH,int(ceil(maxf(a.x,b.x)+r))+1),4):
			var center := Vector2(cx+2,cy+2)
			var t := clampf((center-a).dot(ab)/length_sq,0,1) if length_sq>0.001 else 0.0
			var hash := fmod(float(abs((cx*73856093)^(cy*19349663)))*0.000001,0.24)
			if center.distance_to(a+ab*t)>r*(0.62+hash): continue
			for y in range(cy,mini(cy+4,HEIGHT)):
				for x in range(cx,mini(cx+4,WIDTH)):
					var index := y*WIDTH+x
					for i in range(5):
						var layer: Dictionary = layers[i]
						if layer.mask[index]==0: continue
						var old: float = layer.wear[index]
						var value := minf(1.0,old+rates[i])
						layer.wear[index] = value
						layer.mask[index] = 0 if value>=1.0 else maxi(1,int(ceil((1.0-value)*255.0)))
						if value>=1.0: layer.cleared += 1
						layer.dirty = true
						touched[i] = true
						work += value-old
						last_removed_depth = i
						deepest = maxi(deepest,int(layer.depth))
						break
	# Actual zeroing, not rounding the progress display.
	for i in touched:
		if float(layers[i].cleared)/PIXELS>=C.FINISH:
			layers[i].wear.fill(1.0)
			layers[i].mask.fill(0)
			layers[i].cleared=PIXELS
			layers[i].dirty=true
	brush_work = work
	return work

func tick(delta: float) -> void:
	if paused: return
	if started: elapsed += delta
	if auto_enabled:
		for i in range(levels.auto): _robot_step(i,delta)
	_tick_machines(delta)
	scan_clock += delta
	if scan_clock >= 0.12:
		scan_clock=0
		scan_exposed_finds()
		advance_layers()

func _robot_step(unit: int,delta: float) -> void:
	started=true
	var bot: Dictionary = robots[unit]
	# Work only the topmost soil per pixel. Stay until the footprint's initial
	# exposed layer is cleared, then move; next stop can dig the following layer.
	if not bot.has("work_layer"):
		bot.work_layer=surface_at(bot.target)
	if int(bot.work_layer)<5 and int(layers[int(bot.work_layer)].depth)>int(levels.auto_power)+1:
		# Seek remaining compatible soil before spending minutes on the next layer.
		for attempt in range(24):
			var point:=Vector2(rng.randf_range(0,WORLD_WIDTH),rng.randf_range(0,WORLD_HEIGHT))
			var surface:=surface_at(point)
			if surface<5 and int(layers[surface].depth)<=int(levels.auto_power)+1:
				bot.direction=(point-(bot.p as Vector2)).normalized()
				bot.target=(bot.p as Vector2).move_toward(point,C.move_speed(levels.auto_move)*delta)
				bot.p=bot.target; auto_points[unit]=bot.p; bot.erase("work_layer")
				return
	if int(bot.work_layer)<5:
		scratch(bot.target,bot.target,delta,robot_radius(),true)
		if not _robot_area_clear(bot.target,int(bot.work_layer)): return
	bot.p = (bot.p as Vector2).move_toward(bot.target,C.move_speed(levels.auto_move)*delta)
	auto_points[unit]=bot.p
	if not (bot.p as Vector2).is_equal_approx(bot.target): return
	var direction: Vector2 = bot.direction
	var next: Vector2 = bot.target+direction*12.0
	if not Rect2(Vector2.ZERO,C.WORLD).has_point(next):
		for attempt in range(64):
			var candidate := (-direction).rotated(rng.randf_range(-1.2,1.2))
			if Rect2(Vector2.ZERO,C.WORLD).has_point(bot.target+candidate*12.0):
				direction=candidate
				break
		next=(bot.target+direction*12.0).clamp(Vector2.ZERO,C.WORLD-Vector2.ONE)
	# Redirect from exposed bottom to an actual remaining patch.
	if surface_at(next)==5:
		var found := false
		for attempt in range(16):
			var candidate := Vector2(rng.randf_range(0,WORLD_WIDTH),rng.randf_range(0,WORLD_HEIGHT))
			if surface_at(candidate)<5:
				direction=(candidate-(bot.p as Vector2)).normalized()
				next=(bot.p as Vector2)+direction*12.0
				found=true
				break
		if not found: direction=-direction
	bot.direction=direction
	bot.target=next
	bot.erase("work_layer")

func _robot_area_clear(point: Vector2,layer_index: int) -> bool:
	var r := robot_radius()*WIDTH/WORLD_WIDTH
	var center := point*WIDTH/WORLD_WIDTH
	# Same pixel-cluster footprint as scratch; avoids waiting for unpainted corners.
	var left:=maxi(0,int(center.x-r)); left-=left%4
	var top:=maxi(0,int(center.y-r)); top-=top%4
	for y in range(top,mini(HEIGHT,int(center.y+r)+1),4):
		for x in range(left,mini(WIDTH,int(center.x+r)+1),4):
			var h:=fmod(float(abs((x*73856093)^(y*19349663)))*0.000001,0.24)
			if Vector2(x+2,y+2).distance_to(center)>r*(0.62+h): continue
			if layers[layer_index].mask[y*WIDTH+x]!=0: return false
	return true

func footprint_clear(layer: Dictionary,find: Dictionary) -> bool:
	var half: Vector2 = find.size*0.5
	var p: Vector2 = find.position
	var lo := ((p-half)*WIDTH/WORLD_WIDTH).floor()
	var hi := ((p+half)*WIDTH/WORLD_WIDTH).ceil()
	for y in range(maxi(0,int(lo.y)),mini(HEIGHT,int(hi.y)+1)):
		for x in range(maxi(0,int(lo.x)),mini(WIDTH,int(hi.x)+1)):
			if layer.mask[y*WIDTH+x]!=0: return false
	return true

func scan_exposed_finds() -> void:
	for layer in layers:
		if float(layer.cleared)/PIXELS>=C.FINISH:
			layer.mask.fill(0); layer.wear.fill(1.0); layer.cleared=PIXELS; layer.dirty=true
		for find in layer.finds:
			if find.collected or not footprint_clear(layer,find): continue
			var covered := false
			for upper in layers:
				if upper.depth>=layer.depth: break
				if not footprint_clear(upper,find): covered=true; break
			if covered: continue
			find.collected=true
			if find.kind=="scrap":
				var before := wallet.floor_value()
				var reward: RefCounted = amount(layer.scale).times(int(find.value))
				wallet=wallet.plus(reward)
				earned=earned.plus(reward)
				var visible_gain: RefCounted = wallet.floor_value().minus(before)
				recent_finds.append({"kind":"scrap","position":find.position,"text":"+"+visible_gain.display(),"premium":find.value==10})
			else:
				records.append({"id":find.id,"series":find.series,"variant":find.variant,"depth":layer.depth,
					"estimate":amount(layer.scale).times(C.BASE_PRICES[int(find.series)]).times(8+int(find.variant),1).data(),"status":"raw","step":0,"progress":[0.0,0.0,0.0],
					"owner":"","quality":false,"polish":0.0,"locked":false,"new":false,"marks":[[],[],[]]})
				series_seen[int(find.series)]=true
				recent_finds.append({"kind":"artifact","position":find.position})
				notices.append("未知土块已入库，可稍后清理")
			touch()

func advance_layers() -> void:
	var count := 0
	while layers[0].cleared==PIXELS:
		scan_exposed_finds()
		layers.pop_front()
		base_depth += 1
		_append_layer(base_depth+4)
		count += 1
	if count>0:
		for bot in robots: bot.erase("work_layer")
		last_removed_depth=0
		layers_shifted.emit(count)
		touch()

func purchase_reason(kind: String) -> String:
	if not levels.has(kind): return "未知升级"
	if int(C.LIMITS[kind])>=0 and levels[kind]>=C.LIMITS[kind]: return "已满级"
	if kind.begins_with("auto_") and levels.auto==0: return "先购买首台机器人"
	var reason := spending_reason(C.price(kind,levels[kind]),kind=="power")
	if not reason.is_empty(): return reason
	return ""

func buy(kind: String) -> bool:
	if paused or not purchase_reason(kind).is_empty(): return false
	wallet=wallet.minus(C.price(kind,levels[kind]))
	levels[kind]+=1
	touch()
	return true

func machine_reason(index: int) -> String:
	if machines[index].owned: return "已拥有"
	if index<5 and not identified_series[index] and not (analyzer and series_seen[index]): return "先鉴定或分析本系列"
	if index==5 and false in identified_series: return "先分别鉴定五个系列"
	var cost := Decimal.new(str(C.MACHINE_PRICES[index]))
	return spending_reason(cost)

func buy_machine(index: int) -> bool:
	if paused or not machine_reason(index).is_empty(): return false
	wallet=wallet.minus(Decimal.new(str(C.MACHINE_PRICES[index])))
	machines[index].owned=true
	touch()
	return true

func record(id: int) -> Dictionary:
	for r in records:
		if int(r.id)==id: return r
	return {}

func claim_manual(id: int) -> bool:
	var r := record(id)
	if r.is_empty() or not r.status in ["raw","cleaning"]: return false
	for machine in machines:
		if machine.task==id: machine.task=-1
	for other in records:
		if other.owner=="manual" and other.id!=id: other.owner=""
	r.owner="manual"
	r.status="cleaning"
	touch()
	return true

func release_manual(id: int) -> void:
	var r := record(id)
	if not r.is_empty() and r.owner=="manual":
		r.owner=""
		touch()

func add_cleaning(id: int,work: float) -> bool:
	var r := record(id)
	if paused or r.is_empty() or r.owner!="manual" or r.status=="identified": return false
	var step := int(r.step)
	r.progress[step]=minf(1.0,float(r.progress[step])+work)
	if r.progress[step]>=C.FINISH: r.progress[step]=1.0
	return _finish_steps(r)

func _finish_steps(r: Dictionary) -> bool:
	while r.step<2 and r.progress[int(r.step)]>=C.FINISH:
		r.progress[int(r.step)]=1.0
		r.step+=1
	if r.step>=2:
		identify(r)
		return true
	touch()
	return false

func _tick_machines(delta: float) -> void:
	for i in range(machines.size()):
		var machine: Dictionary = machines[i]
		if not machine.owned or not machine.enabled: continue
		var r := record(int(machine.task))
		if r.is_empty() or r.status in ["identified","sold"] or r.owner!="machine%d"%i:
			machine.task=-1
			r=_next_task(i)
			if r.is_empty(): continue
			r.owner="machine%d"%i
			r.status="cleaning"
			machine.task=r.id
			touch()
		var seconds: float = delta*pow(1.2,levels.opening)
		while seconds>0 and r.step<2:
			var step := int(r.step)
			var duration: float = C.PHASE_SECONDS[i][step]
			var spent := minf(seconds,maxf(0,C.FINISH-float(r.progress[step]))*duration)
			r.progress[step]+=spent/duration
			seconds-=spent
			if r.progress[step]>=C.FINISH-0.000000001: r.progress[step]=1.0
			if _finish_steps(r): break
			if spent<=0: break
		if r.status in ["identified","sold"]: machine.task=-1

func _next_task(machine_index: int) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for r in records:
		if r.status in ["raw","cleaning"] and r.owner=="" and (machine_index==5 or r.series==machine_index): candidates.append(r)
	if candidates.is_empty(): return {}
	if talents.has("T31") and queue_priority>0:
		candidates.sort_custom(func(a,b): return float(a.progress[0])+float(a.progress[1]) > float(b.progress[0])+float(b.progress[1]) if queue_priority==1 else float(a.progress[0])+float(a.progress[1]) < float(b.progress[0])+float(b.progress[1]))
	if talents.has("T31") and analyzer and priority_series>=0:
		for r in candidates:
			if r.series==priority_series: return r
	return candidates[0]

func identify(r: Dictionary) -> void:
	if r.status in ["identified","sold"]: return
	var key := "%d_%d" % [int(r.series),int(r.variant)]
	var was_known := discovered.has(key)
	r.new=not was_known
	r.status="identified"
	r.owner=""
	r.step=2
	r.progress[0]=1.0; r.progress[1]=1.0
	discovered[key]=true
	identified_series[int(r.series)]=true
	if not was_known: knowledge+=1
	var complete := true
	for v in range(5):
		if not discovered.has("%d_%d"%[int(r.series),v]): complete=false
	if complete and not awarded_sets.has(str(r.series)):
		awarded_sets[str(r.series)]=true
		knowledge+=2
	notices.append("鉴定完成："+C.model_item(int(r.series),int(r.variant)).name)
	if auto_sell and was_known and not r.locked:
		wallet=wallet.plus(sale_price(r))
		r.status="sold"
	touch()

func sale_price(r: Dictionary) -> RefCounted:
	var estimate := amount(r.estimate)
	var multiplier := 125 if r.quality else (100 if r.status in ["identified","sold"] else (70 if int(r.step)>=1 else 40))
	return estimate.times(multiplier,2).floor_value()

func sell(id: int) -> bool:
	var r := record(id)
	if paused or r.is_empty() or r.status!="identified" or r.locked: return false
	wallet=wallet.plus(sale_price(r))
	r.status="sold"
	touch()
	return true

func polish(id: int,delta: float) -> void:
	var r := record(id)
	if paused or r.is_empty() or r.status!="identified" or r.quality: return
	r.polish=minf(8.0,float(r.polish)+delta)
	if r.polish/8.0>=C.FINISH:
		r.polish=8.0; r.quality=true; r.progress[2]=1.0
	touch()

func buy_talent(id: String) -> bool:
	if paused or talents.has(id): return false
	for t in C.TALENTS:
		if t.id!=id: continue
		if not t.pre.is_empty() and not talents.has(t.pre): return false
		if knowledge<int(t.cost) or discovered.is_empty(): return false
		knowledge-=int(t.cost)
		talents[id]=true
		touch()
		return true
	return false

func reset_talents() -> void:
	for t in C.TALENTS:
		if talents.has(t.id): knowledge+=int(t.cost)
	talents.clear()
	priority_series=-1
	touch()

func save_preset(slot: int) -> void:
	if not talents.has("T32"): return
	var enabled: Array[bool] = []
	for m in machines: enabled.append(m.enabled)
	presets[slot]={"enabled":enabled,"auto_sell":auto_sell,"priority":priority_series,"queue":queue_priority}
	touch()

func load_preset(slot: int) -> void:
	if not talents.has("T32") or presets[slot].is_empty(): return
	auto_sell=presets[slot].auto_sell
	priority_series=presets[slot].priority
	queue_priority=presets[slot].get("queue",0)
	for i in range(6): machines[i].enabled=presets[slot].enabled[i]
	touch()

func save_to(path: String = "user://ea_save.dat") -> Error:
	var state := {"version":3,"analyzer":analyzer,"queue_priority":queue_priority,"wallet":wallet.data(),"earned":earned.data(),"layers":layers,"rng":rng.state,
		"base_depth":base_depth,"next_id":next_id,"elapsed":elapsed,"started":started,"levels":levels,
		"records":records,"discovered":discovered,"series_seen":series_seen,"identified_series":identified_series,
		"draws":draws,"duplicate_streak":duplicate_streak,"machines":machines,"robots":robots,
		"knowledge":knowledge,"awarded_sets":awarded_sets,"talents":talents,"auto_sell":auto_sell,
		"priority_series":priority_series,"presets":presets,"reduce_fx":reduce_fx,"skip_repeat":skip_repeat}
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_var(state)
	file.flush()
	file.close()
	return DirAccess.rename_absolute(path+".tmp",path)

func load_from(path: String = "user://ea_save.dat") -> bool:
	if not FileAccess.file_exists(path): return false
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null: return false
	var state: Variant = file.get_var(false)
	if not state is Dictionary or not state.get("version",0) in [2,3]: return false
	if not state.has("layers") or state.layers.size()!=5: return false
	for layer in state.layers:
		if layer.mask.size()!=PIXELS or layer.wear.size()!=PIXELS: return false
	var legacy: bool = state.version==2
	if legacy and not FileAccess.file_exists(path+".v2.bak"):
		DirAccess.copy_absolute(path,path+".v2.bak")
	for key in state:
		if key in ["version","wallet","earned","rng"]: continue
		set(key,state[key])
	wallet=amount(state.wallet)
	earned=amount(state.earned)
	rng.state=state.rng
	for layer in layers: layer.dirty=true
	for r in records:
		if r.owner=="manual": r.owner=""
	for i in range(3): auto_points[i]=robots[i].p
	if legacy: _migrate_v2()
	paused=false
	recent_finds.clear()
	touch()
	return true

func reserve() -> RefCounted:
	var key := "%d/%d"%[levels.power,base_depth]
	if key==reserve_key: return reserve_value
	var total := Decimal.new()
	for level in range(int(levels.power),base_depth):
		total=total.plus(C.price("power",level))
	reserve_key=key; reserve_value=total
	return total

func spending_reason(cost: RefCounted, strength: bool = false) -> String:
	if wallet.compare(cost)<0: return "还差 "+cost.minus(wallet.floor_value()).display()+" 废料"
	if not strength and wallet.minus(cost).compare(reserve())<0: return "需预留推进升级 "+reserve().display()
	return ""

func analyzer_reason() -> String:
	if analyzer: return "已拥有分析仪"
	return spending_reason(Decimal.new("500"))

func buy_analyzer() -> bool:
	if paused or not analyzer_reason().is_empty(): return false
	wallet=wallet.minus(Decimal.new("500")); analyzer=true; touch()
	return true

func unknown_title(r: Dictionary) -> String:
	var label := "未知土块（已剥壳）" if int(r.step)>0 else "未知土块"
	return label+("｜潜在系列："+C.series_name(int(r.series)) if analyzer else "")

func _migrate_v2() -> void:
	analyzer=false
	# Refund changed branches and their dependent nodes without resetting discovery.
	for t in C.TALENTS:
		if t.id!="T00" and talents.has(t.id):
			knowledge+=int(t.cost); talents.erase(t.id)
	priority_series=-1; queue_priority=0; presets=[{},{}]
	for r in records:
		r.marks=[[],[],[]]
		if r.status in ["identified","sold"]:
			r.step=2; r.progress=[1.0,1.0,1.0 if r.quality else float(r.polish)/8.0]
		else:
			var completed_work: float=(float(r.progress[0])+float(r.progress[1])+float(r.progress[2]))/3.0*2.0
			r.progress=[minf(1.0,completed_work),maxf(0.0,completed_work-1.0),0.0]
			r.step=0 if completed_work<1.0 else 1
			_finish_steps(r)
	# One-time strength compatibility upgrade, no free repeat money.
	levels.power=maxi(int(levels.power),base_depth-1)
	if levels.auto>0: levels.auto_power=maxi(int(levels.auto_power),base_depth-1)
	notices.append("v0.2存档已迁移：旧市价保留，变更天赋退点，强度匹配当前层；原档已备份")
