extends GridContainer
## Two-column, image-first shopping cards. Each image is captured once in an
## isolated world and cached; no models/lights leak into the gameplay scene.
static var photos: Dictionary = {}
var game: Node
var photo_jobs: Array[Dictionary] = []

func setup(source: Node) -> void:
	game = source
	name = "ProductGrid"
	columns = 2
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("h_separation", 6)
	add_theme_constant_override("v_separation", 8)

func add_product(title: String, detail: String, price: String, caption: String, action: Callable, enabled: bool, series := -1, item := -1) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.set_meta("shopping_card", true)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff8e9")
	style.border_color = Color("#d7bd9f")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	var window := AspectRatioContainer.new()
	window.ratio = 1.0
	window.custom_minimum_size.y = 112
	window.stretch_mode = AspectRatioContainer.STRETCH_WIDTH_CONTROLS_HEIGHT
	window.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(window)
	# AspectRatioContainer draws a square but its minimum height does not
	# reserve that square in a VBox automatically. Reserve it explicitly.
	window.resized.connect(func():
		var height := maxf(1.0, window.size.x)
		if absf(window.custom_minimum_size.y - height) > 0.5:
			window.custom_minimum_size.y = height
	)
	var background := ColorRect.new()
	background.color = Color("#e8e2d7") if series < 0 else Color("#e7edf2")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	window.add_child(background)
	var picture := TextureRect.new()
	picture.name = "ProductPhoto"
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	window.add_child(picture)
	if series < 0:
		var placeholder := _label("商品图\n待补充", 11, Color("#807567"), 0)
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		window.add_child(placeholder)
	else:
		var key := "%d:%d" % [series, item]
		if photos.has(key): picture.texture = photos[key]
		else: photo_jobs.append({"key":key, "series":series, "item":item, "picture":picture})
	column.add_child(_label(title, 12, Color("#502c31"), 36))
	column.add_child(_label(detail, 10, Color("#726964"), 44))
	column.add_child(_label(price, 13, Color("#b84c2e"), 18))
	var buy: Button = game.button(caption, game.UI_AMBER)
	buy.custom_minimum_size = Vector2(0, 30)
	buy.add_theme_font_size_override("font_size", 11)
	buy.clip_text = true
	buy.disabled = not enabled
	buy.pressed.connect(action)
	column.add_child(buy)
	return column

func _label(text: String, font_size: int, color: Color, height: float) -> Label:
	var result: Label = game.make_label(text, font_size, color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.custom_minimum_size = Vector2(0, height)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

func generate_photos() -> void:
	if DisplayServer.get_name() == "headless": return
	for job in photo_jobs:
		if not is_inside_tree(): return
		var viewport := SubViewport.new()
		viewport.size = Vector2i(320, 320)
		viewport.own_world_3d = true
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child(viewport)
		var studio := Node3D.new()
		viewport.add_child(studio)
		var group := Node3D.new()
		studio.add_child(group)
		var featured: Array = [job["item"]] if job["item"] >= 0 else [0, 1, game.SERIES[job["series"]]["items"].size() - 1]
		for index in featured.size():
			var holder := Node3D.new()
			holder.basis = game._stall_collectible_basis(Vector3.BACK)
			group.add_child(holder)
			var model: Node3D = game.instantiate_collectible_model(job["series"], featured[index])
			if model: holder.add_child(model)
			if featured.size() > 1:
				holder.scale *= 1.0 if index == 1 else 0.72
				holder.rotate_y(deg_to_rad((1 - index) * 12.0))
			var bounds: Dictionary = game.collectible_model_bounds(holder)
			if bounds["valid"]: holder.position -= (bounds["bounds"] as AABB).get_center()
			if featured.size() > 1:
				holder.position += Vector3((index - 1) * 0.58, 0.12 if index == 1 else -0.18, 0.18 if index == 1 else 0.0)
		var bounds: Dictionary = game.collectible_model_bounds(group)
		var extent := 1.5
		if bounds["valid"]:
			group.position = -(bounds["bounds"] as AABB).get_center()
			extent = maxf(bounds["bounds"].size.x, bounds["bounds"].size.y)
		var camera := Camera3D.new()
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = extent * 1.18
		camera.position = Vector3(0, 0, 5)
		studio.add_child(camera)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-25, -25, 0)
		studio.add_child(light)
		var environment := WorldEnvironment.new()
		environment.environment = Environment.new()
		environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.environment.ambient_light_color = Color.WHITE
		environment.environment.ambient_light_energy = 0.7
		studio.add_child(environment)
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		if not is_instance_valid(viewport): return
		var photo := ImageTexture.create_from_image(viewport.get_texture().get_image())
		photos[job["key"]] = photo
		if is_instance_valid(job["picture"]): job["picture"].texture = photo
		viewport.queue_free()
		await get_tree().process_frame
	photo_jobs.clear()
