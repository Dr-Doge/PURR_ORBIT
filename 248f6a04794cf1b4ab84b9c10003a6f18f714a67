extends SceneTree

func _init() -> void:
	call_deferred("run")

func capture(file: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://" + file)

func run() -> void:
	var actor_script = load("res://scripts/stall_demo/city_pedestrian.gd")
	var unique := {}
	for category in 9:
		assert(actor_script.MODEL_POOLS[category].size() == 3)
		for variant in 3:
			var asset: String = actor_script.MODEL_POOLS[category][variant]
			assert(not unique.has(asset))
			unique[asset] = true
			var actor = actor_script.new()
			actor.setup(category, 1.0, variant)
			assert(actor.animation_player.has_animation("Walk_A"))
			actor.free()
	var stall = load("res://scenes/stall_demo/stall_demo.tscn").instantiate()
	root.add_child(stall)
	await process_frame
	stall.set_process(false)
	stall.rng.seed = 147
	stall._start_business()
	var averages: Array[float] = []
	for level in [0, 4]:
		stall._clear_pedestrians()
		await process_frame
		stall.stall_location_level = level
		stall.stall_pedestrian_spawn_wait = 0
		var total := 0.0
		for frame in 1200:
			stall._update_pedestrians(0.1)
			for i in stall.stall_pedestrians.size():
				for j in range(i + 1, stall.stall_pedestrians.size()):
					assert(stall.stall_pedestrians[i]["node"].position.distance_to(stall.stall_pedestrians[j]["node"].position) >= 1.349)
			if frame > 300: total += stall.stall_pedestrians.size()
			if frame % 40 == 0: await process_frame
		averages.append(total / 899.0)
		await capture("crowd_level_%d.png" % level)
	assert(averages[1] > averages[0] * 1.5, "Upgraded footfall must visibly increase")
	stall._clear_pedestrians()
	await process_frame
	var mover = stall._create_city_person(1, 1.0)
	var blocker = stall._create_city_person(5, 1.0)
	stall.stall_pedestrian_root.add_child(mover)
	stall.stall_pedestrian_root.add_child(blocker)
	mover.position = Vector3(-2, -1.04, -6.5)
	blocker.position = Vector3(0, -1.04, -6.5)
	stall.stall_pedestrians.append_array([{"node":mover}, {"node":blocker}])
	var changed_lane := false
	for frame in 900:
		stall._walk_with_avoidance(mover, Vector3(3, -1.04, -6.5), 1.4, 1.0 / 60.0)
		if absf(mover.position.z + 6.5) > 0.3: changed_lane = true
	assert(changed_lane and mover.position.x > 2.5, "Blocked walker must change lane and pass")
	stall._clear_pedestrians()
	stall._finish_business_day()
	assert(stall.day_one_story.visible and paused)
	for point in [Vector2(150, 610), Vector2(400, 200)]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = point
		root.push_input(click)
		await process_frame
	assert(stall.day_one_story.index == 2, "Clicks inside and outside the caption must advance once")
	for line in 13: stall.day_one_story.advance()
	await capture("day_one_story.png")
	for line in 5: stall.day_one_story.advance()
	assert(not paused and stall.day_one_story_seen and stall.stall_day_panel.visible)
	assert(stall._capture_save_state()["day_one_story_seen"])
	stall._begin_next_day()
	stall._start_business()
	stall._finish_business_day()
	assert(not stall.day_one_story.visible)
	stall.queue_free()
	await process_frame
	print("CROWD_STORY_OK: 24 pedestrian models + dedicated owner pool, traffic averages ", averages, ", separation, overtaking, 20-line story, viewport clicks and persistence")
	quit()
