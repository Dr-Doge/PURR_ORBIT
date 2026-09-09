extends SceneTree

func _init() -> void:
	call_deferred("run")

func capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://" + filename + ".png")

func run() -> void:
	var game = load("res://scenes/stall_demo/stall_demo.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.cash = 999999
	game.unlocked_apps["resale"] = true
	game.series_open_counts = [30, 30, 30, 30, 30]
	game.refresh_ui()
	game._set_phone_visible(true, true)
	for app in ["supply", "jimi", "resale"]:
		if app == "resale":
			for item_index in 4:
				for copy in 3:
					game.collectibles.append({"series":0, "item_index":item_index, "rarity":0, "name":game.SERIES[0]["items"][item_index]})
		game._open_phone_app(app)
		await create_timer(2).timeout
		var grid = game.stall_phone_page.find_child("ProductGrid", true, false)
		assert(grid != null and grid.columns == 2)
		var screen: Rect2 = game.stall_phone_page.get_global_rect()
		for card in grid.get_children():
			if not card is Control: continue
			var rect: Rect2 = card.get_global_rect()
			assert(rect.position.x >= screen.position.x - 1 and rect.end.x <= screen.end.x + 1, "Card extends beyond phone screen")
			var column: VBoxContainer = card.get_child(0)
			var image_rect: Rect2 = column.get_child(0).get_global_rect()
			assert(column.get_child(1).global_position.y >= image_rect.end.y, "Title overlaps product photo")
		if DisplayServer.get_name() != "headless" and app != "jimi":
			assert(grid.photos.size() > 0)
			assert(grid.find_children("*", "SubViewport", true, false).is_empty())
		await capture("shopping_" + app)
	var before: int = game.cash
	# Key format is sourced from the actual canonical item rather than guessed.
	var key: String = game._item_price_key(game.collectibles[0])
	game._resale_item_duplicates(key)
	assert(game.cash > before)
	game._set_phone_visible(false, true)
	assert(game.get_node("Room/Desk").size.x == 26)
	for slot in 24: assert(absf(game._stall_slot_position(slot).x) > 2.5)
	game.spawn_box("blind", 0, 0, 20)
	var box = game.boxes.back()
	assert(box.uses_kangaroo_art and not box.shell.visible)
	var textured_meshes := 0
	for mesh in box.find_children("*", "MeshInstance3D", true, false):
		var material = mesh.get_active_material(0)
		assert(material is BaseMaterial3D and material.albedo_texture != null)
		assert(material.albedo_texture.resource_path.ends_with("肥嘟嘟袋鼠贴图.jpg"))
		assert(not mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV].is_empty())
		textured_meshes += 1
	assert(textured_meshes == 2)
	await create_timer(0.6).timeout
	await capture("shopping_table")
	game.focus_box(box)
	await create_timer(0.5).timeout
	await capture("kangaroo_closed")
	game.begin_seal_drag(game.camera.unproject_position(box.active_seal_anchor_global()))
	var movement := InputEventMouseMotion.new()
	movement.button_mask = MOUSE_BUTTON_MASK_LEFT
	movement.relative = Vector2(-12, 4)
	movement.position = Vector2(1150, 600) # over UI, not on the box
	Input.parse_input_event(movement)
	await process_frame
	assert(box.seal_progress > 0 and game.pointer_mode == "seal_drag")
	var previous: float = box.seal_progress
	movement.relative = Vector2(12, -4)
	Input.parse_input_event(movement)
	await process_frame
	assert(box.seal_progress > previous)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame
	assert(game.pointer_mode == "")
	previous = box.seal_progress
	game.begin_seal_drag(Vector2.ZERO)
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(game.pointer_mode == "" and box.seal_progress == previous)
	box.set_seal_progress(1.0)
	game.opening_sequence = true
	game.complete_drag_opening()
	await create_timer(0.35).timeout
	assert(not box.lid_opened and not is_instance_valid(game.review_item))
	await capture("kangaroo_opening")
	await create_timer(0.60).timeout
	assert(box.lid_opened)
	await create_timer(1.2).timeout
	assert(is_instance_valid(game.review_item))
	await capture("kangaroo_revealed")
	# All other series share the same slower lid contract.
	for series in range(1, 5):
		game.spawn_box("blind", series, 0, game.box_price(series))
		var other = game.boxes.back()
		other.freeze = true
		other.tear_seal()
		other.play_auto_open()
		await create_timer(0.35).timeout
		assert(not other.lid_opened and not other.content.visible)
		await create_timer(0.55).timeout
		assert(other.lid_opened and not other.content.visible)
	game.stall_shelf_level = 10
	game._rebuild_stall_shelf()
	game.detail_panel.hide()
	game.loot_preview_panel.hide()
	game.review_item.hide()
	game.review_glow.hide()
	if is_instance_valid(game.review_new_badge): game.review_new_badge.hide()
	for test_box in game.boxes:
		test_box.hide()
	for index in 4:
		game.stall_listings[index] = {"item":{"series":0, "item_index":index, "rarity":0, "name":game.SERIES[0]["items"][index]}, "price":30}
	game._render_stall_listings()
	game.set_focus_depth_of_field(false)
	await capture("shopping_max_displays")
	game.queue_free()
	await process_frame
	print("PHONE_SHOPPING_OPENING_OK: 2-column cards, photos, resale protection, central delivery, captured drag, full lid before reveal")
	quit()
