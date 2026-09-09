extends SceneTree
const Model = preload("res://scripts/scratch_model.gd")
var failures := 0
func check(ok: bool, what: String) -> void:
	if not ok: failures += 1; printerr("FAIL: " + what)
func _initialize() -> void: call_deferred("run")
func clear_footprint(m: RefCounted, find: Dictionary) -> void:
	var p: Vector2 = find.position
	var h: Vector2 = find.size * 0.5
	for point in [p, p-h, p+h, p+Vector2(-h.x,h.y), p+Vector2(h.x,-h.y)]:
		var x := clampi(int(point.x / Model.WORLD_WIDTH * Model.WIDTH), 0, Model.WIDTH-1)
		var y := clampi(int(point.y / Model.WORLD_HEIGHT * Model.HEIGHT), 0, Model.HEIGHT-1)
		m.layers[int(find.depth)].health[y*Model.WIDTH+x] = 0.0
func run() -> void:
	var m := Model.new()
	check(m.finds.size() == 26740, "tripled scrap counts plus eight artifacts per layer")
	for depth in range(5): check(m.layer_finds(depth).size() == Model.SCRAP_COUNTS[depth]+Model.ARTIFACTS_PER_LAYER, "layer find count")
	check(not m.buy("power") and m.cost("unknown") == -1, "purchase validation")
	var p := Vector2(420,310)
	m.scratch(p,p,0.02)
	check(m.progress(0)>0.0 and m.progress(1)==0.0, "topmost-only soil damage")
	check(m.scrap==0, "soil wear produces no currency")
	check(m.efficiency(1)<0.03 and m.efficiency(2)<0.002, "deeper hardness gate")
	var small := Model.new(); var wide := Model.new(); wide.radius_level=1
	small.scratch(p,p,0.01); wide.scratch(p,p,0.01)
	check(wide.progress(0)>small.progress(0)*1.55, "radius upgrade changes area")
	var scrap_find: Dictionary; var artifact_find: Dictionary
	for find in m.layer_finds(0):
		if find.kind=="scrap" and scrap_find.is_empty(): scrap_find=find
		if find.kind=="artifact": artifact_find=find
	clear_footprint(m,scrap_find); m.scan_exposed_finds()
	check(m.scrap==1 and m.total_scrap==1, "fully exposed scrap collected")
	m.scan_exposed_finds(); check(m.scrap==1, "scrap collected once")
	clear_footprint(m,artifact_find); m.scan_exposed_finds()
	check(m.pending_artifacts.size()==1, "artifact enters reveal queue")
	check(int(m.pending_artifacts[0].soil_chunks)>=6 and int(m.pending_artifacts[0].soil_chunks)<=10, "6-10 soil chunks")
	m.scrap=120; check(m.buy("power") and m.scrap==0 and m.power_level==1, "upgrade spends scrap")
	m.paused=true; var before:=m.progress(0); m.scratch(p,p,1.0); m.tick(1.0)
	check(m.progress(0)==before and m.elapsed==0.0, "pause freezes work")
	var automatic:=Model.new(); automatic.auto_level=1; automatic.started=true; automatic.tick(0.2)
	check(automatic.progress(0)>0.0, "automation scratches soil")
	m.store_artifact(artifact_find)
	check(m.inventory.size()==1 and m.discovered.has("%d_%d"%[artifact_find.series,artifact_find.item_index]), "artifact stored and discovered")
	var trader:=Model.new()
	var bought:=Model.Catalog.item(0,0)
	trader.store_artifact(bought)
	var payout:=trader.sell_artifact(int(bought.series),int(bought.item_index))
	check(payout==int(bought.price) and trader.scrap==payout and trader.inventory.is_empty(),"inventory sale pays twice old collectible value")
	check(not trader.has_method("buy_series_box"), "inventory purchasing removed")
	var premium: Dictionary = m.layer_finds(0)[19]
	clear_footprint(m,premium)
	var cash_before := m.scrap
	m.scan_exposed_finds()
	check(m.scrap == cash_before+10, "premium scrap pays ten")
	var machine := Model.new()
	machine.power_level=4
	machine.radius_level=3
	machine._dig_machine_footprint(p,10.0)
	check(machine.surface_at(p)==1 and machine.progress(1)==0.0,"machine ignores manual upgrades")
	machine.auto_power_level=2
	machine._dig_machine_footprint(p,10.0)
	check(machine.surface_at(p)==3 and machine.progress(3)==0.0,"machine clears all reachable layers and stops at harder soil")
	machine.auto_points[0]=Vector2(1095,400)
	machine.auto_targets[0]=machine.auto_points[0]
	machine.auto_directions[0]=Vector2.RIGHT
	machine._step_machine(0,10.0)
	check(machine.auto_directions[0].x<0 and machine.auto_targets[0].x<1095,"edge chooses opposite inward direction")
	var target := machine.auto_targets[0]
	for frame in range(120): machine._step_machine(0,1.0/30.0)
	check(machine.surface_at(target)==3,"machine travelling path stays fully cleared to its own strength")
	var slow := Model.new()
	var fast := Model.new()
	fast.auto_dig_level=3
	slow._dig_machine_footprint(p,0.1)
	fast._dig_machine_footprint(p,0.1)
	check(fast.progress(0)>slow.progress(0),"independent digging speed changes wear")
	slow.auto_points[0]=p; fast.auto_points[0]=p
	slow.auto_targets[0]=p+Vector2(10,0); fast.auto_targets[0]=p+Vector2(10,0)
	slow._dig_machine_footprint(p,10.0); fast._dig_machine_footprint(p,10.0)
	slow._dig_machine_footprint(p+Vector2(10,0),10.0); fast._dig_machine_footprint(p+Vector2(10,0),10.0)
	fast.auto_move_level=3
	slow._step_machine(0,0.01); fast._step_machine(0,0.01)
	check(fast.auto_points[0].x>slow.auto_points[0].x,"independent travel speed changes distance")
	print("MODEL_CHECKS: %d failure(s)"%failures)
	quit(1 if failures>0 else 0)
