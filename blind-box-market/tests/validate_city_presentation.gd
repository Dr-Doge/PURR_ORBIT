extends SceneTree

func _init() -> void:
	call_deferred("run")

func capture(file: String) -> void:
	if DisplayServer.get_name() == "headless": return
	for frame in 4:
		for child in root.get_children():
			if child.has_method("_fit_game_panels"): child._fit_game_panels()
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://" + file)
	print("CAPTURE ", ProjectSettings.globalize_path("user://" + file))

func run() -> void:
	var menu: Control = load("res://scenes/frontend/main_menu.tscn").instantiate()
	root.add_child(menu)
	await create_timer(0.3).timeout
	await capture("city_menu.png")
	menu.queue_free()
	await process_frame
	var stall = load("res://scenes/stall_demo/stall_demo.tscn").instantiate()
	root.add_child(stall)
	await process_frame
	stall.set_process(false)
	stall.rng.seed = 120
	stall._start_business()
	assert(stall.stall_pedestrians.is_empty(), "Opening must not seed a visible crowd")
	stall._spawn_background_pedestrian()
	var entrant: Node3D = stall.stall_pedestrians[0]["node"]
	var camera := root.get_camera_3d()
	var screen_point := camera.unproject_position(entrant.global_position + Vector3.UP * 4.0)
	assert(screen_point.x < -40 or screen_point.x > root.size.x + 40, "New walkers must start fully outside view")
	for frame in 600:
		stall._update_pedestrians(1.0 / 60.0)
	stall._set_phone_visible(false, true)
	stall.stall_listings[0] = {"item":{"series":0, "item_index":0, "rarity":0, "name":"冬日暖意"}, "price":45}
	stall._rebuild_stall_shelf()
	var original_ids: Array[int] = []
	for entry in stall.stall_pedestrians:
		original_ids.append(entry["node"].get_instance_id())
	stall._spawn_customer()
	for frame in 2400:
		if stall.stall_customer != null: break
		stall._update_pedestrians(1.0 / 60.0)
		for entry in stall.stall_pedestrians:
			if not original_ids.has(entry["node"].get_instance_id()): original_ids.append(entry["node"].get_instance_id())
		stall._spawn_customer()
	assert(stall.stall_customer != null, "Must recruit a passerby")
	var customer = stall.stall_customer
	assert(original_ids.has(customer.get_instance_id()), "Customer must be an existing walker")
	assert(customer.animation_player.has_animation("Walk_A"))
	var skeleton: Skeleton3D = customer.find_child("Skeleton3D", true, false)
	var leg := skeleton.find_bone("UpperLeg.L")
	customer.set_walking(true)
	customer.animation_player.advance(0.1)
	var pose := skeleton.get_bone_pose_rotation(leg)
	customer.animation_player.advance(0.3)
	assert(not pose.is_equal_approx(skeleton.get_bone_pose_rotation(leg)), "Walk must animate the skeleton")
	var start: Vector3 = customer.position
	stall._update_customer(0.05)
	assert(customer.position.distance_to(start) < 0.08, "Approach must not teleport")
	for frame in 300:
		stall._update_customer(1.0 / 60.0)
		if stall.stall_customer_phase == "browse": break
	assert(stall.stall_customer_phase == "browse")
	for frame in 30: stall._update_customer(1.0 / 60.0)
	assert(customer.global_basis.z.normalized().dot(Vector3.BACK) > 0.97, "Stopped customer must face the player")
	assert(customer.animation_player.current_animation == "Idle_A")
	await create_timer(0.4).timeout
	await capture("city_street.png")
	var profile: Dictionary = stall.stall_customer_profile
	stall._make_customer_offer()
	stall._open_bargain()
	stall._fit_game_panels()
	await create_timer(0.3).timeout
	await capture("ui_bargain.png")
	stall.stall_bargain_panel.hide()
	stall._open_phone_app("supply")
	stall._set_phone_visible(true, true)
	stall._fit_game_panels()
	await create_timer(0.3).timeout
	await capture("ui_supply.png")
	stall._set_phone_visible(false, true)
	assert(stall.stall_customer_profile == profile, "Bargain identity must match the walker's asset")
	stall.stall_customer_phase = "leave"
	for frame in 500:
		stall._update_customer(1.0 / 60.0)
		if stall.stall_customer == null: break
	assert(stall.stall_customer == null)
	assert(is_instance_valid(customer), "Leaving customer should return to the pedestrian stream")
	assert(customer.get_parent() == stall.stall_pedestrian_root)
	stall._clear_pedestrians()
	assert(stall.stall_pedestrians.is_empty())
	stall.stall_customer_profile = stall.CUSTOMER_PROFILES[1]
	var full_price_count := 0
	for attempt in 100:
		stall._make_customer_offer()
		assert(stall.stall_offer_price in [41, 45], "Ordinary fans only ask about 10% off or pay the tag")
		if stall.stall_offer_price == 45: full_price_count += 1
	assert(full_price_count > 45 and full_price_count < 85)
	stall.stall_offer_price = 45
	stall._open_bargain()
	await process_frame
	assert(stall.stall_bargain_content.find_children("*", "VSlider", true, false).is_empty())
	await capture("ui_full_price.png")
	stall.stall_bargain_panel.hide()
	for level in 3:
		stall.stall_shelf_level = level
		while stall.stall_listings.size() < 4 + level * 2: stall.stall_listings.append(null)
		stall._rebuild_stall_shelf()
		assert(stall.stall_shelf_root.find_children("Acrylic_Tier_*", "CSGBox3D", false, false).size() == 2 + level)
		var holder: Node3D = stall.stall_shelf_root.get_node("Listed_0")
		var measured: Dictionary = stall.collectible_model_bounds(holder)
		assert(absf(measured["bounds"].position.y - stall._stall_slot_position(0).y) < 0.001, "Model bottom must touch its acrylic tier")
	await capture("acrylic_upgraded.png")
	# No arrivals in the final seconds; thinning does not delete walkers.
	stall.stall_business_elapsed = 299.0
	stall.stall_pedestrian_spawn_wait = 0.0
	stall._update_pedestrians(0.1)
	assert(stall.stall_pedestrians.is_empty())
	stall.stall_price_item = {"series":0, "item_index":0, "rarity":0, "name":"用于测试较长商品名称的隐藏款"}
	stall.stall_price_source = "listing"
	stall._open_price_panel(99999)
	stall._fit_game_panels()
	await create_timer(0.3).timeout
	stall._fit_game_panels()
	await capture("ui_price.png")
	stall.stall_price_panel.hide()
	stall.pause_panel.get_parent().show()
	stall._fit_game_panels()
	await create_timer(0.3).timeout
	await capture("ui_pause.png")
	stall.pause_panel.get_parent().hide()
	stall._finish_business_day()
	while stall.day_one_story.visible: stall.day_one_story.advance()
	stall._fit_game_panels()
	await create_timer(0.3).timeout
	await capture("ui_day.png")
	stall.stall_day_panel.hide()
	stall.detail_panel.show()
	stall.detail_title.text = "小隐藏款 · 袋鼠骑士"
	stall.detail_hint.text = "所属：肥嘟嘟伙伴\n按住物品可自由旋转查看"
	stall.sell_button.show()
	stall.keep_button.show()
	stall.sell_button.text = "定价上市｜市价 ¥1.2万"
	stall.keep_button.text = "计入库存（同款 12）"
	stall.seal_bar.hide()
	await capture("ui_review.png")
	stall.queue_free()
	await process_frame
	print("CITY_PRESENTATION_OK: animated rig, existing walker recruitment, heading, identity and return to stream")
	quit()
