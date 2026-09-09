extends SceneTree

func _init() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://" + name)

func run() -> void:
	var stall = load("res://scenes/stall_demo/stall_demo.tscn").instantiate()
	root.add_child(stall)
	await process_frame
	stall.set_process(false)
	var below_cost := false
	var divergent := false
	for day in range(1, 121):
		for series in stall.SERIES.size():
			for item in stall.SERIES[series]["items"].size():
				var price: int = stall.market_price_at_day(series, item, day)
				if stall.SERIES[series]["rarities"][item] > 0: assert(price >= stall.box_price(series))
				elif price < stall.box_price(series): below_cost = true
		if day > 1:
			var a: int = stall.market_price_at_day(0, 0, day) - stall.market_price_at_day(0, 0, day - 1)
			var b: int = stall.market_price_at_day(0, 1, day) - stall.market_price_at_day(0, 1, day - 1)
			if a * b < 0: divergent = true
	assert(below_cost and divergent)
	var price_before: int = stall.market_price_at_day(0, 0, 63)
	stall.item_market.histories.clear()
	assert(stall.market_price_at_day(0, 0, 63) == price_before)
	stall.cash = 999999
	for level in 10: stall._upgrade_shelf()
	assert(stall.stall_shelf_level == 10 and stall.stall_listings.size() == 24)
	var before: int = stall.cash
	stall._upgrade_shelf()
	assert(stall.cash == before)
	var centers := {}
	for index in range(0, 24, 2):
		var point: Vector3 = stall._stall_slot_position(index)
		assert(point.y <= 4.32)
		centers[point.x] = true
	assert(centers.size() == 3)
	var item := {"series":0, "item_index":0, "rarity":0, "name":stall.SERIES[0]["items"][0]}
	stall.collectibles.append(item)
	stall.collectibles.append(item.duplicate())
	stall.discovered["0_0"] = true
	stall.stall_listings[0] = {"item":item, "price":45}
	stall._render_stall_listings()
	await capture("three_acrylic_stands.png")
	stall._open_backpack_shortcut()
	await create_timer(4).timeout
	await capture("inventory_grid.png")
	assert(stall.inventory_grid.visible and not stall.stall_phone_visible)
	if DisplayServer.get_name() != "headless":
		assert(stall.inventory_grid.thumbnails.size() > 0)
		assert(stall.inventory_grid.find_children("*", "SubViewport", true, false).is_empty())
	stall.inventory_grid.hide()
	stall.stall_customer = stall._create_city_person(1, 1.0)
	stall.stall_customer_root.add_child(stall.stall_customer)
	stall.stall_customer.position = Vector3(0.5, -1.04, -5.15)
	stall.stall_customer_profile = stall.CUSTOMER_PROFILES[1]
	stall._make_customer_offer()
	for frame in 4:
		stall._fit_game_panels()
		await process_frame
	await capture("customer_bubble.png")
	assert(stall.stall_bargain_panel.visible and not stall.stall_offer_panel.visible)
	stall.queue_free()
	await process_frame
	print("MARKET_INVENTORY_OK: independent losses, hidden floor, deterministic history, 3x4 stand cap, static grid and unified bubble")
	quit()
