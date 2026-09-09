extends Control

const Model = preload("res://scripts/scratch_model.gd")
const MASK_SHADER = preload("res://shaders/soil_mask.gdshader")
const FindLayer = preload("res://scripts/find_layer.gd")
const ASSETS := ["res://assets/soil/RealSoil/1.png", "res://assets/soil/RealSoil/2.png", "res://assets/soil/RealSoil/3.png", "res://assets/soil/RealSoil/4.png", "res://assets/soil/RealSoil/5.png"]

var model: RefCounted
var mask_textures: Array[ImageTexture] = []
var drawing := false
var previous := Vector2(-1, -1)
var hover := false
var cursor := Vector2.ZERO
var motion_points: Array[Vector2] = []
var dust: Array[Dictionary] = []
var pickup_numbers: Array[Dictionary] = []
var find_layers: Array[Control] = []
var texture_clock := 0.0
var active_depth := 0
var effective := false

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	for i in range(5):
		var img := Image.create_from_data(Model.WIDTH, Model.HEIGHT, false, Image.FORMAT_L8, model.layers[i].mask)
		mask_textures.append(ImageTexture.create_from_image(img))
	for i in range(4, -1, -1):
		var finds := FindLayer.new()
		finds.model = model
		finds.depth = i
		finds.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(finds)
		find_layers.push_front(finds)
		var plane := TextureRect.new()
		plane.name = "SoilLayer%d" % (i + 1)
		plane.texture = load(ASSETS[i])
		plane.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		plane.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		plane.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var material := ShaderMaterial.new()
		material.shader = MASK_SHADER
		material.set_shader_parameter("soil_mask", mask_textures[i])
		plane.material = material
		add_child(plane)
	var overlay := Control.new()
	overlay.name = "BrushOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.draw.connect(_draw_overlay.bind(overlay))
	add_child(overlay)
	mouse_entered.connect(func(): hover = true)
	mouse_exited.connect(_leave)

func _leave() -> void:
	hover = false
	cancel_drag()

func cancel_drag() -> void:
	drawing = false
	previous = Vector2(-1, -1)
	motion_points.clear()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel_drag()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		drawing = event.pressed and not model.paused
		previous = event.position if drawing else Vector2(-1, -1)
		motion_points.clear()
		accept_event()
	elif event is InputEventMouseMotion:
		cursor = event.position
		if not Rect2(Vector2.ZERO, size).has_point(cursor):
			previous = Vector2(-1, -1)
			motion_points.clear()
		elif drawing and not model.paused:
			motion_points.append(event.position)

func step(delta: float) -> void:
	cursor = get_local_mouse_position()
	effective = false
	if drawing and hover and not model.paused:
		if previous.x < 0.0:
			previous = cursor
		if motion_points.is_empty():
			motion_points.append(cursor)
		var per_segment := delta / motion_points.size()
		for p in motion_points:
			model.scratch(previous, p, per_segment)
			previous = p
		motion_points.clear()
		effective = model.brush_work > 0.15
		if effective and dust.size() < 42:
			var color: Color = Model.SOIL_COLORS[model.last_removed_depth]
			for i in range(3):
				dust.append({"p":cursor + Vector2(randf_range(-12, 12), randf_range(-8, 8)), "v":Vector2(randf_range(-24, 24), randf_range(25, 75)), "life":0.62, "size":randf_range(3, 7), "color":color.lightened(0.14)})
	active_depth = model.surface_at(cursor) if hover else model.deepest
	for i in range(dust.size() - 1, -1, -1):
		dust[i].life -= delta
		dust[i].p += dust[i].v * delta
		dust[i].v.y += 330.0 * delta
		if dust[i].life <= 0.0:
			dust.remove_at(i)
	for i in range(pickup_numbers.size() - 1, -1, -1):
		pickup_numbers[i].life -= delta
		pickup_numbers[i].p += pickup_numbers[i].v * delta
		pickup_numbers[i].v.y += 32.0 * delta
		if pickup_numbers[i].life <= 0.0: pickup_numbers.remove_at(i)
	texture_clock += delta
	if texture_clock >= 1.0 / 30.0:
		texture_clock = 0.0
		upload_masks()
	get_node("BrushOverlay").queue_redraw()

func consume_find_events() -> void:
	if model.recent_finds.is_empty(): return
	for find in model.recent_finds:
		if find.kind == "artifact": find_layers[int(find.depth)].queue_redraw()
		if find.kind == "scrap":
			var value := int(find.get("value", 1))
			pickup_numbers.append({"p":find.position + Vector2(-8,-6), "v":Vector2(0,-48), "life":0.95, "text":"+%d" % value, "color":Color("ffd44f") if value == 10 else Color("eaf7ed")})
	model.recent_finds.clear()

func upload_masks() -> void:
	for i in range(5):
		if model.layers[i].dirty:
			var img := Image.create_from_data(Model.WIDTH, Model.HEIGHT, false, Image.FORMAT_L8, model.layers[i].mask)
			mask_textures[i].update(img)
			model.layers[i].dirty = false

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("192a2b"))
	for x in range(0, int(size.x), 32):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color("263b3b"))
	for y in range(0, int(size.y), 32):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color("263b3b"))

func _draw_overlay(canvas: Control) -> void:
	for particle in dust:
		var color: Color = particle.color
		color.a = particle.life / 0.62
		canvas.draw_rect(Rect2(particle.p - Vector2.ONE * particle.size * 0.5, Vector2.ONE * particle.size), color)
	for particle in pickup_numbers:
		var color: Color = particle.color
		color.a = minf(1.0, particle.life / 0.35)
		var font := get_theme_default_font()
		canvas.draw_string_outline(font, particle.p, particle.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 4, Color(0.02,0.03,0.03,color.a))
		canvas.draw_string(font, particle.p, particle.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
	if model.auto_enabled and model.started:
		for i in range(model.auto_level):
			var p: Vector2 = model.auto_points[i]
			if p.x < 0.0:
				continue
			canvas.draw_arc(p, Model.AUTO_RADIUS, 0, TAU, 48, Color(0.72, 0.98, 0.88, 0.75), 1.6, true)
			canvas.draw_rect(Rect2(p - Vector2(6, 6), Vector2(12, 12)), Color("183b35"))
			canvas.draw_line(p - Vector2(4, 0), p + Vector2(4, 0), Color("a6f0d8"), 2.0)
	if hover and not model.paused:
		var color := Color("fff9dd")
		if active_depth < 5 and model.efficiency(active_depth) < 0.08:
			color = Color("ffd18a")
		_draw_pixel_brush(canvas, cursor, model.get_radius(), color)
		canvas.draw_line(cursor - Vector2(5, 0), cursor + Vector2(5, 0), color, 1.5)
		canvas.draw_line(cursor - Vector2(0, 5), cursor + Vector2(0, 5), color, 1.5)

func _draw_pixel_brush(canvas: Control, center: Vector2, radius: float, color: Color) -> void:
	var pixel := 8.0
	var cells := int(ceil(radius / pixel))
	for y in range(-cells, cells + 1):
		for x in range(-cells, cells + 1):
			var p := Vector2(x, y) * pixel
			var hash := fmod(float(abs((x * 73856093) ^ (y * 19349663))) * 0.000001, 0.22)
			if p.length() > radius * (0.77 + hash): continue
			canvas.draw_rect(Rect2(center + p - Vector2.ONE * pixel * 0.5, Vector2.ONE * pixel), Color(color, 0.12))
			canvas.draw_rect(Rect2(center + p - Vector2.ONE * pixel * 0.5, Vector2.ONE * pixel), Color(color, 0.72), false, 1.0)
