extends Control

signal trade_changed(message: String)

const Catalog = preload("res://scripts/artifact_catalog.gd")
const ModelPreview = preload("res://scripts/model_preview_3d.gd")
const INK := Color("eaf0e9")
const MUTED := Color("92a8ac")

var model: RefCounted
var series_index := 0
var title_label: Label
var grid: GridContainer
var tabs: HBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := ColorRect.new()
	veil.color = Color(0.015, 0.025, 0.03, 0.94)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	var panel := Panel.new()
	panel.position = Vector2(95, 54)
	panel.size = Vector2(1176, 742)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("14252c")
	style.border_color = Color("47665f")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	title_label = _label(panel, "古物库存", Vector2(28, 20), Vector2(720, 40), 27, INK)
	var close := Button.new()
	close.text = "关闭"
	close.position = Vector2(1034, 20)
	close.size = Vector2(112, 38)
	close.pressed.connect(close_panel)
	panel.add_child(close)
	tabs = HBoxContainer.new()
	tabs.position = Vector2(28, 77)
	tabs.size = Vector2(1118, 42)
	tabs.add_theme_constant_override("separation", 8)
	panel.add_child(tabs)
	for i in range(Catalog.SERIES.size()):
		var button := Button.new()
		button.text = Catalog.SERIES[i].name
		button.custom_minimum_size = Vector2(206, 38)
		button.pressed.connect(_select_series.bind(i))
		tabs.add_child(button)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(28, 132)
	scroll.size = Vector2(1118, 580)
	panel.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	hide()

func _label(parent: Node, value: String, pos: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.position = pos
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func open_panel() -> void:
	model.paused = true
	_refresh()
	show()

func close_panel() -> void:
	hide()
	model.paused = false

func _select_series(index: int) -> void:
	series_index = index
	_refresh()

func _refresh() -> void:
	for child in grid.get_children(): child.queue_free()
	var counts := {}
	for owned in model.inventory:
		var key := "%d_%d" % [int(owned.series), int(owned.item_index)]
		counts[key] = int(counts.get(key, 0)) + 1
	var series: Dictionary = Catalog.SERIES[series_index]
	title_label.text = "古物库存  ·  已收藏 %d 件  ·  %s" % [model.inventory.size(), series.name]
	for item_index in range(series.items.size()):
		var item := Catalog.item(series_index, item_index)
		var key := "%d_%d" % [series_index, item_index]
		var known: bool = model.discovered.has(key)
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(208, 294)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("1d3036") if known else Color("17252a")
		style.border_color = item.color if known else Color("334248")
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", style)
		var stack := VBoxContainer.new()
		stack.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(stack)
		var preview: Control
		if known:
			preview = ModelPreview.new()
			preview.build(item.model_path, Vector2i(192, 178))
		else:
			var unknown := ColorRect.new()
			unknown.color = Color("1b292e")
			preview = unknown
		preview.custom_minimum_size = Vector2(188, 158)
		stack.add_child(preview)
		var name_label := Label.new()
		name_label.text = item.name if known else "？？？"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 16)
		stack.add_child(name_label)
		var count_label := Label.new()
		count_label.text = "持有 × %d" % int(counts.get(key, 0)) if known else "尚未发现"
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.add_theme_color_override("font_color", MUTED)
		stack.add_child(count_label)
		var price_label := Label.new()
		price_label.text = "出售 %d 废料" % int(item.price) if known else "价格未鉴定"
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_label.add_theme_color_override("font_color", Color("e1c180") if known else MUTED)
		stack.add_child(price_label)
		var sell := Button.new()
		sell.text = "卖出一件"
		sell.disabled = int(counts.get(key, 0)) <= 0
		sell.pressed.connect(_sell_item.bind(series_index, item_index))
		stack.add_child(sell)
		grid.add_child(card)

func _sell_item(sell_series: int, item_index: int) -> void:
	var item := Catalog.item(sell_series, item_index)
	var payout: int = model.sell_artifact(sell_series, item_index)
	if payout <= 0: return
	_refresh()
	trade_changed.emit("卖出「%s」，获得%d废料" % [item.name, payout])

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_panel()
		get_viewport().set_input_as_handled()
