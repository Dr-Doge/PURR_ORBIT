extends Control
## One isolated offscreen capture per collectible, then ordinary TextureRects.
## No live 3D scenes are retained in inventory slots.
static var thumbnails: Dictionary = {}
var game: Node
var generation := 0

func open_inventory(source: Node) -> void:
	game = source
	generation += 1
	var ticket := generation
	for child in get_children():
		remove_child(child)
		child.queue_free()
	show()
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.65)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(120, 42)
	panel.size = Vector2(1040, 636)
	game.PIXEL_UI_SKIN.apply_panel(panel, "popup")
	add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var bar := HBoxContainer.new()
	column.add_child(bar)
	var title: Label = game.make_label("背包与收藏  ·  %d / %d 件" % [game.collectibles.size(), game.stall_inventory_capacity], 22, game.UI_INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(title)
	var close: Button = game.button("关闭", game.UI_CARBON)
	close.pressed.connect(hide)
	bar.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	var jobs: Array = []
	for series in game.SERIES.size():
		for item in game.SERIES[series]["items"].size():
			var key := "%d_%d" % [series, item]
			var count := 0
			var first := -1
			for index in game.collectibles.size():
				var owned: Dictionary = game.collectibles[index]
				if int(owned.get("series", -1)) == series and int(owned.get("item_index", -1)) == item:
					count += 1
					if first < 0: first = index
			var known: bool = game.discovered.has(key) or count > 0
			var card := PanelContainer.new()
			card.custom_minimum_size = Vector2(184, 246)
			game.PIXEL_UI_SKIN.apply_panel(card, "diary")
			grid.add_child(card)
			var stack := VBoxContainer.new()
			card.add_child(stack)
			var picture := TextureRect.new()
			picture.custom_minimum_size = Vector2(0, 132)
			picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			picture.modulate = Color.WHITE if known else Color.BLACK
			stack.add_child(picture)
			if thumbnails.has(key): picture.texture = thumbnails[key]
			else: jobs.append({"key":key, "series":series, "item":item, "picture":picture})
			var caption: Label = game.make_label("%s：%s" % [game.SERIES[series]["name"], game.SERIES[series]["items"][item]] if known else "？？？", 12, game.UI_INK)
			caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			caption.custom_minimum_size.y = 38
			stack.add_child(caption)
			stack.add_child(game.make_label("库存数量：%d" % count, 12, game.UI_INK))
			var list: Button = game.button("上架一件" if count > 0 else ("未持有" if known else "尚未发现"), game.UI_AMBER)
			list.disabled = count == 0 or game._first_empty_listing() < 0
			list.pressed.connect(func(): hide(); game._price_inventory_item(first))
			stack.add_child(list)
	game.PIXEL_UI_SKIN.fit_content(panel)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.custom_minimum_size.x = 88
	_generate_thumbnails(jobs, ticket)

func _generate_thumbnails(jobs: Array, ticket: int) -> void:
	if DisplayServer.get_name() == "headless": return
	for job in jobs:
		if ticket != generation or not visible: return
		var viewport := SubViewport.new()
		viewport.size = Vector2i(192, 192)
		viewport.own_world_3d = true
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child(viewport)
		var scene := Node3D.new()
		viewport.add_child(scene)
		var holder := Node3D.new()
		holder.basis = game._stall_collectible_basis(Vector3.BACK)
		scene.add_child(holder)
		var model: Node3D = game.instantiate_collectible_model(job["series"], job["item"])
		if model: holder.add_child(model)
		else:
			var fallback := MeshInstance3D.new()
			fallback.mesh = SphereMesh.new()
			holder.add_child(fallback)
		var bounds: Dictionary = game.collectible_model_bounds(holder)
		var extent := 1.0
		if bounds["valid"]:
			holder.position = -(bounds["bounds"] as AABB).get_center()
			extent = maxf(bounds["bounds"].size.x, bounds["bounds"].size.y)
		var camera := Camera3D.new()
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = extent * 1.22
		camera.position = Vector3(0, 0, 5)
		scene.add_child(camera)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-25, -25, 0)
		scene.add_child(light)
		var environment := WorldEnvironment.new()
		environment.environment = Environment.new()
		environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.environment.ambient_light_color = Color.WHITE
		environment.environment.ambient_light_energy = 0.7
		scene.add_child(environment)
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		if not is_instance_valid(viewport): return
		var captured := ImageTexture.create_from_image(viewport.get_texture().get_image())
		thumbnails[job["key"]] = captured
		if is_instance_valid(job["picture"]): job["picture"].texture = captured
		viewport.queue_free()
		await get_tree().process_frame
