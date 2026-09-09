extends RefCounted
## Five independent image masks. A sample damages only the uppermost surviving
## layer at each pixel. Finds are collected only when their own footprint is clear.

const Catalog = preload("res://scripts/artifact_catalog.gd")
const WIDTH := 512
const HEIGHT := 384
const PIXELS := WIDTH * HEIGHT
const WORLD_WIDTH := 1096.0
const WORLD_HEIGHT := 822.0
const DURATION := 180.0
const CELL := 4
const WEAR_PER_SECOND := [3.4, 2.7, 2.0, 1.35, 1.15]
const HARDNESS := [1.0, 6.0, 30.0, 140.0, 650.0]
const POWER := [1.0, 6.0, 30.0, 140.0, 650.0]
# Each footprint is approximately half the area of the previous circular brush.
const RADII := [18.0, 25.0, 34.0, 44.0]
const POWER_COST := [120, 420, 1050, 2400]
const RADIUS_COST := [80, 320, 900]
const AUTO_COST := [220, 720, 1800]
const AUTO_POWER_COST := [180, 550, 1400, 3000]
const AUTO_DIG_COST := [160, 480, 1200]
const AUTO_MOVE_COST := [140, 420, 1100]
const AUTO_DIG_SPEED := [3.0, 6.0, 12.0, 24.0]
const AUTO_MOVE_SPEED := [75.0, 120.0, 190.0, 280.0]
const AUTO_RADIUS := 22.0
const SCRAP_COUNTS := [600, 1500, 3600, 8400, 12600]
const ARTIFACTS_PER_LAYER := 8
const SOIL_COLORS := [Color("624f41"), Color("88724a"), Color("676b5f"), Color("5a5241"), Color("33312f")]
const NAMES := ["风化表土", "砂质浅土", "灰绿硬土", "板结密土", "黑色深土"]

class SoilLayer:
	var health := PackedFloat32Array()
	var mask := PackedByteArray()
	var removed := 0.0
	var dirty := true
	func _init() -> void:
		health.resize(PIXELS)
		health.fill(1.0)
		mask.resize(PIXELS)
		mask.fill(255)

var layers: Array[SoilLayer] = []
var finds: Array[Dictionary] = []
var scrap := 0
var total_scrap := 0
var inventory: Array[Dictionary] = []
var discovered: Dictionary = {}
var pending_artifacts: Array[Dictionary] = []
var recent_finds: Array[Dictionary] = []
var power_level := 0
var radius_level := 0
var auto_level := 0
var auto_power_level := 0
var auto_dig_level := 0
var auto_move_level := 0
var auto_directions: Array[Vector2] = []
var auto_targets: Array[Vector2] = []
var machine_rng := RandomNumberGenerator.new()
var elapsed := 0.0
var started := false
var paused := false
var auto_enabled := true
var auto_phase := 0.0
var auto_previous: Array[Vector2] = []
var auto_points: Array[Vector2] = []
var deepest := 0
var brush_work := 0.0
var last_removed_depth := 0
var scan_clock := 0.0


func _init() -> void:
	for i in range(5): layers.append(SoilLayer.new())
	machine_rng.seed = 91237
	for i in range(3):
		auto_previous.append(Vector2(-1, -1))
		auto_points.append(Vector2(-1, -1))
		auto_directions.append(Vector2.RIGHT.rotated(machine_rng.randf_range(0, TAU)))
		auto_targets.append(Vector2(-1, -1))
	_generate_finds()


func _generate_finds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5000913
	var id := 0
	for depth in range(5):
		var count: int = SCRAP_COUNTS[depth]
		var cols := int(ceil(sqrt(float(count) * WORLD_WIDTH / WORLD_HEIGHT)))
		var rows := int(ceil(float(count) / cols))
		var cell_w := WORLD_WIDTH / cols
		var cell_h := WORLD_HEIGHT / rows
		for index in range(count):
			var column := index % cols
			var row := index / cols
			var p := Vector2((column + rng.randf_range(0.20, 0.80)) * cell_w, (row + rng.randf_range(0.20, 0.80)) * cell_h)
			finds.append({"id":id, "kind":"scrap", "depth":depth, "position":p, "size":Vector2(5, 5), "value":10 if index % 20 == 19 else 1, "collected":false})
			id += 1
		for artifact_index in range(ARTIFACTS_PER_LAYER):
			var artifact := Catalog.roll_for_depth(depth, rng)
			artifact.merge({"id":id, "kind":"artifact", "depth":depth, "position":Vector2(rng.randf_range(70, WORLD_WIDTH - 70), rng.randf_range(60, WORLD_HEIGHT - 60)), "size":Vector2(24, 24), "collected":false, "soil_chunks":rng.randi_range(6, 10)})
			finds.append(artifact)
			id += 1

func get_power() -> float: return POWER[power_level]
func get_radius() -> float: return RADII[radius_level]

func efficiency(depth: int) -> float:
	var ratio: float = get_power() / HARDNESS[depth]
	return minf(ratio * ratio, 4.0)

func progress(depth: int) -> float: return clampf(layers[depth].removed / PIXELS, 0.0, 1.0)

func total_progress() -> float:
	var total := 0.0
	for i in range(5): total += progress(i)
	return total / 5.0

func complete() -> bool: return progress(4) >= 0.95

func cost(kind: String) -> int:
	match kind:
		"power": return POWER_COST[power_level] if power_level < POWER_COST.size() else -1
		"radius": return RADIUS_COST[radius_level] if radius_level < RADIUS_COST.size() else -1
		"auto": return AUTO_COST[auto_level] if auto_level < AUTO_COST.size() else -1
		"auto_power": return AUTO_POWER_COST[auto_power_level] if auto_power_level < AUTO_POWER_COST.size() else -1
		"auto_dig": return AUTO_DIG_COST[auto_dig_level] if auto_dig_level < AUTO_DIG_COST.size() else -1
		"auto_move": return AUTO_MOVE_COST[auto_move_level] if auto_move_level < AUTO_MOVE_COST.size() else -1
	return -1

func buy(kind: String) -> bool:
	var price := cost(kind)
	if price < 0 or scrap < price or paused: return false
	scrap -= price
	match kind:
		"power": power_level += 1
		"radius": radius_level += 1
		"auto": auto_level += 1; started = true
		"auto_power": auto_power_level += 1
		"auto_dig": auto_dig_level += 1
		"auto_move": auto_move_level += 1
	return true

func surface_at(world_point: Vector2) -> int:
	var x := clampi(int(world_point.x / WORLD_WIDTH * WIDTH), 0, WIDTH - 1)
	var y := clampi(int(world_point.y / WORLD_HEIGHT * HEIGHT), 0, HEIGHT - 1)
	var index := y * WIDTH + x
	for i in range(5):
		if layers[i].health[index] > 0.0: return i
	return 5

func scratch(from: Vector2, to: Vector2, delta: float, radius: float = -1.0, power_scale: float = 1.0) -> float:
	if paused or delta <= 0.0: return 0.0
	started = true
	var scale_factor := WIDTH / WORLD_WIDTH
	var a := from * scale_factor
	var b := to * scale_factor
	var r := (get_radius() if radius < 0.0 else radius) * scale_factor
	var left := maxi(0, int(floor(minf(a.x, b.x) - r)))
	var right := mini(WIDTH - 1, int(ceil(maxf(a.x, b.x) + r)))
	var top := maxi(0, int(floor(minf(a.y, b.y) - r)))
	var bottom := mini(HEIGHT - 1, int(ceil(maxf(a.y, b.y) + r)))
	left -= left % CELL
	top -= top % CELL
	var ab := b - a
	var length_squared := ab.length_squared()
	var rates := PackedFloat32Array()
	for i in range(5): rates.append(WEAR_PER_SECOND[i] * efficiency(i) * power_scale * delta)
	var work := 0.0
	for cy in range(top, bottom + 1, CELL):
		for cx in range(left, right + 1, CELL):
			var center := Vector2(cx + CELL * 0.5, cy + CELL * 0.5)
			var t := clampf((center - a).dot(ab) / length_squared, 0.0, 1.0) if length_squared > 0.001 else 0.0
			var distance := center.distance_to(a + ab * t)
			var hash := float(abs((cx * 73856093) ^ (cy * 19349663))) / 2147483647.0
			var jagged_radius := r * (0.76 + fmod(hash * 7.13, 0.24))
			if distance > jagged_radius: continue
			for y in range(cy, mini(cy + CELL, HEIGHT)):
				for x in range(cx, mini(cx + CELL, WIDTH)):
					var index := y * WIDTH + x
					for depth in range(5):
						var layer := layers[depth]
						var old := layer.health[index]
						if old <= 0.0: continue
						var new := maxf(0.0, old - rates[depth])
						if new < 0.002: new = 0.0
						var removed := old - new
						layer.health[index] = new
						layer.mask[index] = int(ceil(new * 255.0))
						layer.removed += removed
						layer.dirty = true
						work += removed
						last_removed_depth = depth
						deepest = maxi(deepest, depth)
						break
	brush_work = work
	return work

func tick(delta: float) -> void:
	if not started or paused: return
	elapsed += delta
	if auto_level > 0 and auto_enabled:
		for unit in range(auto_level):
			_step_machine(unit, delta)
	scan_clock += delta
	if scan_clock >= 0.08:
		scan_clock = 0.0
		scan_exposed_finds()

# A machine finishes its next overlapping footprint before travelling to it.
# Digging time and travel time are independent; stronger soil is never damaged.
func _step_machine(unit: int, delta: float) -> void:
	if auto_points[unit].x < 0.0:
		auto_points[unit] = Vector2(machine_rng.randf_range(40, WORLD_WIDTH-40), machine_rng.randf_range(40, WORLD_HEIGHT-40))
		auto_targets[unit] = auto_points[unit]
	var target := auto_targets[unit]
	if not _dig_machine_footprint(target, delta):
		return
	auto_points[unit] = auto_points[unit].move_toward(target, AUTO_MOVE_SPEED[auto_move_level] * delta)
	if not auto_points[unit].is_equal_approx(target): return
	var direction := auto_directions[unit]
	var next := target + direction * 10.0
	if next.x < 0 or next.x > WORLD_WIDTH or next.y < 0 or next.y > WORLD_HEIGHT:
		# Pick an inward direction in the opposite hemisphere, not a fixed reflection.
		for attempt in range(64):
			var candidate := (-direction).rotated(machine_rng.randf_range(-1.25, 1.25))
			var probe := target + candidate * 10.0
			if Rect2(0, 0, WORLD_WIDTH, WORLD_HEIGHT).has_point(probe):
				direction = candidate
				break
		next = target + direction * 10.0
		next = next.clamp(Vector2.ZERO, Vector2(WORLD_WIDTH, WORLD_HEIGHT))
	auto_directions[unit] = direction
	auto_targets[unit] = next

func _dig_machine_footprint(point: Vector2, delta: float) -> bool:
	var center := point * WIDTH / WORLD_WIDTH
	var radius := AUTO_RADIUS * WIDTH / WORLD_WIDTH
	var clean := true
	for y in range(maxi(0, int(center.y-radius)), mini(HEIGHT, int(ceil(center.y+radius))+1)):
		for x in range(maxi(0, int(center.x-radius)), mini(WIDTH, int(ceil(center.x+radius))+1)):
			if Vector2(x+0.5,y+0.5).distance_to(center) > radius: continue
			var budget: float = AUTO_DIG_SPEED[auto_dig_level] * delta
			var index := y * WIDTH + x
			for depth in range(auto_power_level+1):
				var layer := layers[depth]
				var removed := minf(layer.health[index], budget)
				if removed > 0:
					layer.health[index] -= removed
					layer.mask[index] = int(ceil(layer.health[index]*255.0))
					layer.removed += removed
					layer.dirty = true
					deepest = maxi(deepest, depth)
					budget -= removed
				if layer.health[index] > 0.0:
					clean = false
					break
	return clean

func scan_exposed_finds() -> void:
	for find in finds:
		if bool(find.collected): continue
		if _footprint_is_clear(find):
			find.collected = true
			recent_finds.append(find.duplicate(true))
			if find.kind == "scrap":
				scrap += int(find.get("value", 1))
				total_scrap += int(find.get("value", 1))
			else:
				pending_artifacts.append(find.duplicate(true))

func _footprint_is_clear(find: Dictionary) -> bool:
	var depth: int = find.depth
	var p: Vector2 = find.position
	var half: Vector2 = find.size * 0.5
	var points := [p, p + Vector2(-half.x, -half.y), p + Vector2(half.x, -half.y), p + Vector2(-half.x, half.y), p + Vector2(half.x, half.y)]
	for world_point in points:
		var x := clampi(int(world_point.x / WORLD_WIDTH * WIDTH), 0, WIDTH - 1)
		var y := clampi(int(world_point.y / WORLD_HEIGHT * HEIGHT), 0, HEIGHT - 1)
		if layers[depth].health[y * WIDTH + x] > 0.0: return false
	return true

func store_artifact(item: Dictionary) -> void:
	var stored := item.duplicate(true)
	inventory.append(stored)
	discovered["%d_%d" % [int(stored.series), int(stored.item_index)]] = true

func sell_artifact(series_index: int, item_index: int) -> int:
	for index in range(inventory.size() - 1, -1, -1):
		var owned: Dictionary = inventory[index]
		if int(owned.series) == series_index and int(owned.item_index) == item_index:
			var price := int(owned.get("price", Catalog.item(series_index, item_index).price))
			inventory.remove_at(index)
			scrap += price
			return price
	return 0

func layer_finds(depth: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for find in finds:
		if int(find.depth) == depth: result.append(find)
	return result
