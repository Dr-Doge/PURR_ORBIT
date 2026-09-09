extends Control

const Catalog = preload("res://scripts/artifact_catalog.gd")
const RevealStage = preload("res://scripts/reveal_stage_3d.gd")

signal finished

var model: RefCounted
var item: Dictionary
var chunk_layer: Control
var chunk_label: Label
var instruction: Label
var reveal_title: Label
var continue_button: Button
var stage: Control
var vfx_layer: Control
var chunks_left := 0
var revealing := false
var reveal_3d: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := ColorRect.new()
	veil.color = Color(0.015, 0.025, 0.028, 0.95)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	reveal_title = _label("发现被泥土包裹的上古盲盒", Rect2(250, 44, 866, 48), 30, Color("f0e5ca"))
	instruction = _label("频繁点击土块，把覆盖物逐块剥离", Rect2(250, 92, 866, 32), 17, Color("9fb1ae"))
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage = Control.new()
	stage.position = Vector2(223, 132)
	stage.size = Vector2(920, 590)
	add_child(stage)
	var stage_bg := ColorRect.new()
	stage_bg.color = Color("0d181c")
	stage_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(stage_bg)
	vfx_layer = Control.new()
	vfx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vfx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(vfx_layer)
	chunk_layer = Control.new()
	chunk_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(chunk_layer)
	chunk_label = _label("", Rect2(24, 24, 250, 32), 17, Color("d9bb8a"), stage)
	continue_button = Button.new()
	continue_button.text = "收入库存并继续"
	continue_button.position = Vector2(543, 738)
	continue_button.size = Vector2(280, 48)
	continue_button.pressed.connect(_close)
	add_child(continue_button)
	continue_button.hide()
	hide()

func _label(value: String, rect: Rect2, font_size: int, color: Color, parent: Node = self) -> Label:
	var label := Label.new()
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func show_artifact(found: Dictionary) -> void:
	item = found.duplicate(true)
	model.paused = true
	revealing = false
	continue_button.hide()
	reveal_title.text = "发现被泥土包裹的上古盲盒"
	instruction.text = "频繁点击各个土块，把覆盖物逐块剥离"
	for child in chunk_layer.get_children(): child.queue_free()
	for child in vfx_layer.get_children(): child.queue_free()
	if reveal_3d and is_instance_valid(reveal_3d): reveal_3d.queue_free()
	var box := ColorRect.new()
	box.name = "BuriedBox"
	box.color = Color("536b68")
	box.position = Vector2(310, 170)
	box.size = Vector2(300, 260)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chunk_layer.add_child(box)
	chunks_left = clampi(int(item.get("soil_chunks", 8)), 6, 10)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(item.id) * 931 + 17
	for i in range(chunks_left):
		var chunk := Button.new()
		chunk.name = "SoilChunk%d" % i
		chunk.text = ""
		var chunk_size := Vector2(rng.randf_range(74, 122), rng.randf_range(60, 105))
		chunk.position = Vector2(rng.randf_range(260, 610 - chunk_size.x), rng.randf_range(125, 445 - chunk_size.y))
		chunk.size = chunk_size
		chunk.rotation = rng.randf_range(-0.18, 0.18)
		chunk.focus_mode = Control.FOCUS_NONE
		chunk.set_meta("hits", rng.randi_range(2, 3))
		var style := StyleBoxFlat.new()
		style.bg_color = Color("76543c").lightened(rng.randf_range(-0.08, 0.08))
		style.border_color = Color("9a704d")
		style.set_border_width_all(3)
		chunk.add_theme_stylebox_override("normal", style)
		chunk.add_theme_stylebox_override("hover", style.duplicate())
		chunk.pressed.connect(_remove_chunk.bind(chunk))
		chunk_layer.add_child(chunk)
	_update_chunk_label()
	show()

func _remove_chunk(chunk: Button) -> void:
	if revealing or not is_instance_valid(chunk) or chunk.is_queued_for_deletion(): return
	var center := chunk.position + chunk.size * 0.5
	_emit_square_dust(center)
	var hits := int(chunk.get_meta("hits")) - 1
	chunk.set_meta("hits", hits)
	if hits > 0:
		chunk.modulate = chunk.modulate.darkened(0.16)
		var hit_tween := create_tween()
		hit_tween.tween_property(chunk, "scale", Vector2(0.93, 0.93), 0.06)
		hit_tween.tween_property(chunk, "scale", Vector2.ONE, 0.08)
		return
	chunk.queue_free()
	chunks_left -= 1
	_update_chunk_label()
	if chunks_left <= 0:
		revealing = true
		start_reveal.call_deferred()

func _update_chunk_label() -> void:
	chunk_label.text = "附着土块  %d" % chunks_left

func _emit_square_dust(center: Vector2) -> void:
	for i in range(8):
		var square := ColorRect.new()
		square.color = Color("9b744f")
		square.position = center + Vector2(randf_range(-24, 24), randf_range(-12, 12))
		square.size = Vector2.ONE * randf_range(5, 11)
		square.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vfx_layer.add_child(square)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(square, "position", square.position + Vector2(randf_range(-45, 45), randf_range(65, 130)), 0.48)
		tween.tween_property(square, "modulate:a", 0.0, 0.48)
		tween.chain().tween_callback(square.queue_free)

func start_reveal() -> void:
	for child in chunk_layer.get_children(): child.queue_free()
	reveal_title.text = "盲盒密封结构正在开启"
	instruction.text = "剪影弹出后会恢复模型本色"
	reveal_3d = RevealStage.new()
	reveal_3d.position = Vector2.ZERO
	reveal_3d.size = stage.size
	stage.add_child(reveal_3d)
	reveal_3d.configure(item)
	await reveal_3d.play_reveal()
	model.store_artifact(item)
	var rarity_name := Catalog.rarity_name(int(item.rarity))
	reveal_title.text = "%s · %s" % [item.series_name, item.name]
	instruction.text = "%s  ·  按住模型拖动可自由旋转查看  ·  已收入库存" % rarity_name
	continue_button.show()

func _close() -> void:
	hide()
	model.paused = false
	finished.emit()
