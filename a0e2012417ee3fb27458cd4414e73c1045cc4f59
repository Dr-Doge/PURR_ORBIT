extends Control

const Model = preload("res://scripts/scratch_model.gd")
const Board = preload("res://scripts/scratch_board.gd")
const InventoryPanel = preload("res://scripts/inventory_panel.gd")
const ArtifactReveal = preload("res://scripts/artifact_reveal.gd")
const INK := Color("eaf0e9")
const MUTED := Color("92a8ac")
const ACCENT := Color("95e0c2")

var model := Model.new()
var board: Control
var scrap_label: Label
var time_label: Label
var status_label: Label
var hint_label: Label
var shop_buttons := {}
var shop_details := {}
var layer_labels: Array[Label] = []
var layer_bars: Array[ProgressBar] = []
var inventory_button: Button
var start_hint: Panel
var inventory_panel: Control
var reveal_panel: Control
var developer_panel: Control
var developer_buttons := {}
var developer_saved := {"power":0, "radius":0, "auto":0, "auto_power":0, "auto_dig":0, "auto_move":0}
var modal: Control
var modal_title: Label
var modal_body: Label
var summary_shown := false
var update_clock := 0.0
var simulation_clock := 0.0
var toast := ""
var toast_time := 0.0
var last_deepest := 0

func _ready() -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Segoe UI"])
	var ui_theme := Theme.new()
	ui_theme.default_font = font
	ui_theme.default_font_size = 14
	theme = ui_theme
	_build_ui()
	_refresh()
	get_window().focus_exited.connect(_on_focus_lost)

func _style(color: Color, border: Color = Color("2a3d44"), radius: int = 7) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style

func _panel(rect: Rect2, color: Color = Color("14232b"), border: Color = Color("2a3d44"), parent: Node = self) -> Panel:
	var node := Panel.new()
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_stylebox_override("panel", _style(color, border))
	parent.add_child(node)
	return node

func _label(value: String, rect: Rect2, font_size: int = 14, color: Color = INK, parent: Node = self) -> Label:
	var label := Label.new()
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(value: String, rect: Rect2, callback: Callable, parent: Node = self) -> Button:
	var button := Button.new()
	button.text = value
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled"]:
		var colors := {"normal":Color("b9ebd4"), "hover":Color("d3f6e5"), "pressed":Color("89c6ae"), "disabled":Color("25373e")}
		button.add_theme_stylebox_override(state, _style(colors[state], colors[state], 5))
	button.add_theme_color_override("font_color", Color("15372e"))
	button.add_theme_color_override("font_hover_color", Color("15372e"))
	button.add_theme_color_override("font_pressed_color", Color("15372e"))
	button.add_theme_color_override("font_disabled_color", Color("82969b"))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _build_ui() -> void:
	_panel(Rect2(4, 14, 1096, 822), Color("16242b"))
	board = Board.new()
	board.name = "ScratchBoard"
	board.model = model
	board.position = Vector2(4, 14)
	board.size = Vector2(1096, 822)
	add_child(board)
	var sidebar := _panel(Rect2(1110, 14, 248, 822), Color("101f26"), Color("30464d"))
	_label("废料", Rect2(14, 13, 70, 22), 13, MUTED, sidebar)
	scrap_label = _label("0", Rect2(14, 32, 138, 42), 30, Color("e1c180"), sidebar)
	_label("试掘时间", Rect2(154, 14, 78, 20), 11, MUTED, sidebar)
	time_label = _label("00:00", Rect2(151, 35, 82, 30), 19, INK, sidebar)
	_button("暂停", Rect2(10, 78, 48, 29), _pause, sidebar)
	inventory_button = _button("库存 0", Rect2(62, 78, 78, 29), _open_inventory, sidebar)
	_button("开发", Rect2(144, 78, 48, 29), _open_developer, sidebar)
	_button("重开", Rect2(196, 78, 42, 29), _confirm_restart, sidebar)
	_build_shop(sidebar, "power", "手动 · 刮除强度", 114)
	_build_shop(sidebar, "radius", "手动 · 刮除范围", 190)
	_build_shop(sidebar, "auto", "自动机 · 数量", 266)
	_build_shop(sidebar, "auto_power", "自动机 · 挖地强度", 342)
	_build_shop(sidebar, "auto_dig", "自动机 · 挖地速度", 418)
	_build_shop(sidebar, "auto_move", "自动机 · 行进速度", 494)
	var layers_panel := _panel(Rect2(10, 574, 228, 141), Color("14272d"), Color("31464d"), sidebar)
	_label("地层清理", Rect2(10, 8, 110, 24), 15, INK, layers_panel)
	for i in range(5):
		var y := 29 + i * 20
		var swatch := ColorRect.new()
		swatch.color = Model.SOIL_COLORS[i]
		swatch.position = Vector2(10, y + 4)
		swatch.size = Vector2(9, 20)
		layers_panel.add_child(swatch)
		layer_labels.append(_label("", Rect2(25, y, 122, 27), 12, INK, layers_panel))
		var bar := ProgressBar.new()
		bar.position = Vector2(149, y + 8)
		bar.size = Vector2(65, 8)
		bar.show_percentage = false
		bar.add_theme_font_size_override("font_size", 1)
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color("293c42")
		var fill := StyleBoxFlat.new()
		fill.bg_color = Model.SOIL_COLORS[i].lightened(0.22)
		bar.add_theme_stylebox_override("background", bg)
		bar.add_theme_stylebox_override("fill", fill)
		layers_panel.add_child(bar)
		layer_bars.append(bar)
	var info_panel := _panel(Rect2(10, 723, 228, 85), Color("14272d"), Color("31464d"), sidebar)
	status_label = _label("", Rect2(11, 4, 206, 35), 12, INK, info_panel)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label = _label("", Rect2(11, 40, 206, 42), 12, ACCENT, info_panel)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start_hint = _panel(Rect2(342, 346, 430, 116), Color(0.035, 0.055, 0.06, 0.92), Color("9da89c"))
	var a := _label("按住左键，拖动刮开地皮", Rect2(16, 15, 398, 30), 21, INK, start_hint)
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var b := _label("夹层废料用于升级；盲盒需要继续清理", Rect2(16, 52, 398, 24), 14, MUTED, start_hint)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var c := _label("升级强度，才能挖进更深的硬土", Rect2(16, 81, 398, 22), 13, ACCENT, start_hint)
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_modal()
	_build_developer_panel()
	inventory_panel = InventoryPanel.new()
	inventory_panel.model = model
	inventory_panel.trade_changed.connect(_on_trade_changed)
	add_child(inventory_panel)
	reveal_panel = ArtifactReveal.new()
	reveal_panel.model = model
	reveal_panel.finished.connect(_on_reveal_finished)
	add_child(reveal_panel)

func _build_shop(parent: Node, kind: String, title: String, y: int) -> void:
	var card := _panel(Rect2(10, y, 228, 71), Color("14272d"), Color("31464d"), parent)
	_label(title, Rect2(10, 3, 200, 20), 14, INK, card)
	shop_details[kind] = _label("", Rect2(10, 23, 208, 17), 11, MUTED, card)
	shop_buttons[kind] = _button("", Rect2(10, 43, 208, 24), _purchase.bind(kind), card)

func _build_modal() -> void:
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	var veil := ColorRect.new()
	veil.color = Color(0.01, 0.02, 0.025, 0.88)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(veil)
	var panel := _panel(Rect2(401, 225, 564, 365), Color("172b32"), Color("47665f"), modal)
	modal_title = _label("", Rect2(25, 28, 514, 48), 27, INK, panel)
	modal_body = _label("", Rect2(25, 91, 514, 175), 16, MUTED, panel)
	modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button("继续挖掘", Rect2(25, 294, 246, 43), _resume, panel)
	_button("重新开始", Rect2(289, 294, 250, 43), _restart, panel)
	modal.hide()

func _build_developer_panel() -> void:
	developer_panel = Control.new()
	developer_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	developer_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(developer_panel)
	var veil := ColorRect.new()
	veil.color = Color(0.01,0.02,0.025,0.90)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	developer_panel.add_child(veil)
	var panel := _panel(Rect2(433,70,500,704),Color("172b32"),Color("63a18e"),developer_panel)
	_label("开发者模式",Rect2(26,24,320,42),27,INK,panel)
	_label("快速切换升级的最高等级，用于验证深层流程。",Rect2(26,68,448,25),13,MUTED,panel)
	developer_buttons.power = _button("",Rect2(26,112,448,50),_developer_toggle.bind("power"),panel)
	developer_buttons.radius = _button("",Rect2(26,178,448,50),_developer_toggle.bind("radius"),panel)
	developer_buttons.auto = _button("",Rect2(26,244,448,50),_developer_toggle.bind("auto"),panel)
	developer_buttons.auto_power = _button("",Rect2(26,310,448,50),_developer_toggle.bind("auto_power"),panel)
	developer_buttons.auto_dig = _button("",Rect2(26,376,448,50),_developer_toggle.bind("auto_dig"),panel)
	developer_buttons.auto_move = _button("",Rect2(26,442,448,50),_developer_toggle.bind("auto_move"),panel)
	_button("一键增加 10,000 废料",Rect2(26,518,448,52),_developer_add_scrap,panel)
	_button("关闭开发者模式",Rect2(26,610,448,48),_close_developer,panel)
	developer_panel.hide()

func _process(delta: float) -> void:
	simulation_clock += minf(delta, 0.10)
	var steps := 0
	while simulation_clock >= 1.0 / 30.0 and steps < 3:
		simulation_clock -= 1.0 / 30.0
		board.step(1.0 / 30.0)
		model.tick(1.0 / 30.0)
		board.consume_find_events()
		steps += 1
	if not model.paused: toast_time = maxf(0.0, toast_time - delta)
	if model.started: start_hint.hide()
	if model.deepest > last_deepest:
		last_deepest = model.deepest
		_notify("进入%s；需要更高刮除强度。" % Model.NAMES[last_deepest])
	if not model.pending_artifacts.is_empty() and not reveal_panel.visible and not inventory_panel.visible and not developer_panel.visible and not modal.visible:
		var found: Dictionary = model.pending_artifacts.pop_front()
		board.cancel_drag()
		reveal_panel.show_artifact(found)
	if model.elapsed >= Model.DURATION and not summary_shown and not reveal_panel.visible:
		summary_shown = true
		_show_modal("三分钟试掘结束", "总清理进度 %d%%  ·  到达第%d层\n收集废料 %d  ·  古物入库 %d 件\n\n可以继续挖掘，也可以重开尝试另一种升级顺序。" % [int(model.total_progress() * 100), model.deepest + 1, model.total_scrap, model.inventory.size()])
	update_clock += delta
	if update_clock >= 0.10:
		update_clock = 0.0
		_refresh()

func _refresh() -> void:
	scrap_label.text = str(model.scrap)
	time_label.text = _format_time(model.elapsed)
	inventory_button.text = "库存 %d" % model.inventory.size()
	if developer_panel.visible: _refresh_developer_buttons()
	for kind in shop_buttons:
		var price: int = model.cost(kind)
		var button: Button = shop_buttons[kind]
		button.disabled = price < 0 or model.scrap < price or model.paused
		button.text = "已满级" if price < 0 else "%s · %d 废料" % ["购买" if kind == "auto" and model.auto_level == 0 else "升级", price]
	shop_details.power.text = "强度 %d  ·  等级 %d/4" % [int(model.get_power()), model.power_level]
	shop_details.radius.text = "像素笔刷直径 %d  ·  等级 %d/3" % [int(model.get_radius() * 2), model.radius_level]
	shop_details.auto.text = "%d/3 台  ·  随机直线巡航" % model.auto_level
	shop_details.auto_power.text = "强度 %d · 清至第%d层" % [int(Model.POWER[model.auto_power_level]), model.auto_power_level+1]
	shop_details.auto_dig.text = "清理速度 %.0f · 等级%d/3" % [Model.AUTO_DIG_SPEED[model.auto_dig_level],model.auto_dig_level]
	shop_details.auto_move.text = "行进 %.0f 像素/秒" % Model.AUTO_MOVE_SPEED[model.auto_move_level]
	for i in range(5):
		layer_labels[i].text = "%d  %s  %d%%" % [i + 1, Model.NAMES[i], int(model.progress(i) * 100)]
		layer_bars[i].value = model.progress(i) * 100
	var depth: int = board.active_depth
	var surface: String = Model.NAMES[depth] if depth < 5 else "遗址底部"
	status_label.text = "工具下方：%s\n累计废料：%d  ·  总清理：%d%%" % [surface, model.total_scrap, int(model.total_progress() * 100)]
	if toast_time > 0.0:
		hint_label.text = toast
	elif depth < 5 and model.efficiency(depth) < 0.08:
		hint_label.text = "这层几乎刮不动。收集已暴露的废料，升级刮除强度。"
	else:
		hint_label.text = "按住并拖动刮土。夹层物品完全露出后才会拾取。"

func _purchase(kind: String) -> void:
	if model.buy(kind):
		var messages := {"power":"刮除强度提升，可以继续向下挖。", "radius":"像素笔刷范围扩大。", "auto":"自动刮地器开始工作。"}
		_notify(messages.get(kind, "自动机独立属性已升级。"))
		_refresh()

func _notify(message: String) -> void:
	toast = message
	toast_time = 4.0

func _format_time(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]

func _show_modal(title_value: String, body: String) -> void:
	model.paused = true
	board.cancel_drag()
	modal_title.text = title_value
	modal_body.text = body
	modal.show()

func _pause() -> void:
	if modal.visible:
		_resume()
	elif not reveal_panel.visible and not inventory_panel.visible:
		_show_modal("已暂停", "计时与自动挖掘已经暂停。\n\n按住左键拖动刮土；完全暴露夹层废料后，它会自动进入账户。")

func _confirm_restart() -> void:
	_show_modal("重新开始本轮试掘？", "这会清空本轮地皮、废料、升级和古物库存。")

func _resume() -> void:
	modal.hide()
	model.paused = false
	board.cancel_drag()
	simulation_clock = 0.0

func _restart() -> void: get_tree().reload_current_scene()

func _open_inventory() -> void:
	if not reveal_panel.visible and not modal.visible and not developer_panel.visible:
		board.cancel_drag()
		inventory_panel.open_panel()

func _open_developer() -> void:
	if reveal_panel.visible or inventory_panel.visible or modal.visible: return
	board.cancel_drag()
	model.paused = true
	_refresh_developer_buttons()
	developer_panel.show()

func _close_developer() -> void:
	developer_panel.hide()
	model.paused = false
	_refresh()

func _refresh_developer_buttons() -> void:
	developer_buttons.power.text = "刮除强度：%s" % ("最高等级（点击关闭）" if model.power_level==Model.POWER.size()-1 else "当前%d级（点击全开）"%model.power_level)
	developer_buttons.radius.text = "刮除范围：%s" % ("最高等级（点击关闭）" if model.radius_level==Model.RADII.size()-1 else "当前%d级（点击全开）"%model.radius_level)
	developer_buttons.auto.text = "自动刮地器：%s" % ("3台运行（点击关闭）" if model.auto_level==Model.AUTO_COST.size() else "当前%d台（点击全开）"%model.auto_level)

	for kind in ["auto_power", "auto_dig", "auto_move"]:
		var level := int(model.get(kind + "_level"))
		var maximum := 4 if kind == "auto_power" else 3
		var title: String = {"auto_power":"机器强度", "auto_dig":"挖地速度", "auto_move":"行进速度"}[kind]
		developer_buttons[kind].text = "%s：%d级（点击%s）" % [title,level,"恢复" if level==maximum else "全开"]

func _developer_toggle(kind: String) -> void:
	if kind in ["auto_power", "auto_dig", "auto_move"]:
		var property := kind + "_level"
		var maximum := 4 if kind == "auto_power" else 3
		var level := int(model.get(property))
		if level == maximum: model.set(property, int(developer_saved[kind]))
		else:
			developer_saved[kind] = level
			model.set(property, maximum)
	match kind:
		"power":
			if model.power_level==Model.POWER.size()-1: model.power_level=int(developer_saved.power)
			else: developer_saved.power=model.power_level; model.power_level=Model.POWER.size()-1
		"radius":
			if model.radius_level==Model.RADII.size()-1: model.radius_level=int(developer_saved.radius)
			else: developer_saved.radius=model.radius_level; model.radius_level=Model.RADII.size()-1
		"auto":
			if model.auto_level==Model.AUTO_COST.size(): model.auto_level=int(developer_saved.auto)
			else: developer_saved.auto=model.auto_level; model.auto_level=Model.AUTO_COST.size(); model.auto_enabled=true
	_refresh_developer_buttons()

func _developer_add_scrap() -> void:
	model.scrap += 10000
	_notify("开发者模式：增加10,000废料。")
	_refresh()

func _on_trade_changed(message: String) -> void:
	_notify(message)
	_refresh()

func _on_reveal_finished() -> void:
	_notify("%s已收入库存。" % model.inventory.back().name)
	_refresh()

func _on_focus_lost() -> void:
	if model.started and not model.paused: _pause()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if developer_panel.visible: _close_developer()
		elif not reveal_panel.visible and not inventory_panel.visible: _pause()
		get_viewport().set_input_as_handled()
