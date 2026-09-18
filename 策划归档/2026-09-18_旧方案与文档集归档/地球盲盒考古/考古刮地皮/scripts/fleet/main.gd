extends Control
const Model = preload("res://scripts/fleet/model.gd")
const Board = preload("res://scripts/fleet/board.gd")
const SAVE = "user://fleet_demo_v1.save"
var model = Model.new()
var board
var active := false
var paused := false
var testing := false
var save_clock := 0.0
var refresh_clock := 0.0
var cash: Label
var logistics: Label
var mission: Label
var notice: Label
var cards: Dictionary = {}
var overlay: PanelContainer
var menu: VBoxContainer
var audio: AudioStreamPlayer
var muted := false

func style(color: String, border: String = "263d50") -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(color); s.border_color = Color(border)
	s.set_border_width_all(1); s.set_corner_radius_all(8)
	s.content_margin_left = 14; s.content_margin_right = 14
	s.content_margin_top = 10; s.content_margin_bottom = 10
	return s

func label(text: String, size: int = 15) -> Label:
	var l := Label.new(); l.text = text; l.add_theme_font_size_override("font_size", size)
	return l

func button(text: String, action: Callable) -> Button:
	var b := Button.new(); b.text = text; b.custom_minimum_size.y = 40
	b.pressed.connect(action); b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var font := SystemFont.new(); font.font_names = PackedStringArray(["Microsoft YaHei", "Segoe UI"])
	theme = Theme.new(); theme.default_font = font; theme.default_font_size = 15
	theme.set_color("font_color", "Label", Color("dcebf0"))
	for state in ["normal", "hover", "pressed", "disabled"]:
		theme.set_stylebox(state,"Button",style("173846" if state == "hover" else "132532"))
	theme.set_color("font_disabled_color","Button",Color("68808d"))
	var bg := ColorRect.new(); bg.color = Color("080f19"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side, 16)
	add_child(margin)
	var root_box := VBoxContainer.new(); root_box.add_theme_constant_override("separation",12); margin.add_child(root_box)
	var header := HBoxContainer.new(); root_box.add_child(header)
	var title := label("远征舰桥  /  ORBITAL SALVAGE",23); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; header.add_child(title)
	header.add_child(button("藏品舱", show_inventory)); header.add_child(button("ESC  菜单", show_pause))
	var body := HBoxContainer.new(); body.size_flags_vertical = Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation",14); root_box.add_child(body)
	board = Board.new(); board.model = model; board.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_child(board)
	board.message.connect(func(t: String): notice.text = t)
	board.sound_requested.connect(play_shot)
	var panel := PanelContainer.new(); panel.custom_minimum_size.x = 326; panel.add_theme_stylebox_override("panel",style("0e1c29")); body.add_child(panel)
	var side := VBoxContainer.new(); side.add_theme_constant_override("separation",10); panel.add_child(side)
	side.add_child(label("舰队指挥 / FLEET CONTROL",17))
	cash = label("0 金属",30); cash.add_theme_color_override("font_color",Color("74ebdb")); side.add_child(cash)
	logistics = label(""); side.add_child(logistics)
	mission = label(""); mission.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; mission.custom_minimum_size.y = 65; side.add_child(mission)
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; side.add_child(scroll)
	var list := VBoxContainer.new(); list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; list.add_theme_constant_override("separation",8); scroll.add_child(list)
	var entries := [["auto","自动火控","自动寻找普通结构，持续开炮"],["light","轻型炮舰","10 伤害 / 2 秒 · 新舰直接入场"],["drone","回收无人机","每趟 5 秒 · 基础运力 30 金属"],["heavy","重炮舰","32 伤害 / 4 秒 · 宝库蓝图解锁"],["piercing","穿甲弹研究","重炮对装甲造成完整伤害"],["light_damage","轻炮威力","每级伤害 +25%"],["light_rate","轻炮装填","每级射速 +10%"],["cargo","运输货舱","每级运力 +25%"],["heavy_damage","重炮威力","每级伤害 +25%"],["heavy_rate","重炮装填","每级射速 +10%"]]
	for entry in entries:
		var box := VBoxContainer.new(); list.add_child(box)
		box.add_child(label(entry[1],17)); box.add_child(label(entry[2],12))
		var key: String = entry[0]
		var b := button("",func(): model.buy(key); refresh())
		box.add_child(b); cards[key] = b
	var ammo := CheckButton.new(); ammo.text = "重炮使用穿甲弹"; ammo.button_pressed = true
	ammo.toggled.connect(func(v: bool): model.use_piercing = v); list.add_child(ammo)
	list.add_child(label("弹药无限 · 无舰损 · 升级最高 3 级",12))
	notice = label("点击星球上的结构开炮；按住持续射击。",14); root_box.add_child(notice)
	audio = AudioStreamPlayer.new(); add_child(audio)
	overlay = PanelContainer.new(); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); overlay.add_theme_stylebox_override("panel",style("0c1725")); overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new(); overlay.add_child(center)
	menu = VBoxContainer.new(); menu.custom_minimum_size.x = 510; menu.add_theme_constant_override("separation",14); center.add_child(menu)
	add_child(overlay)
	refresh(); show_start()

func clear_menu(title: String, detail: String) -> void:
	model.held = false; overlay.show()
	for child in menu.get_children(): menu.remove_child(child); child.queue_free()
	menu.add_child(label(title,30))
	var desc := label(detail); desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; menu.add_child(desc)

func show_start() -> void:
	clear_menu("远征舰桥", "指挥轨道舰队，轰开异星结构，回收文明宝藏。\n点击 / 按住开炮 → 自动火控 → 扩编 → 集火宝库 → 穿甲突破")
	menu.add_child(button("开始新远征",func(): start_session()))
	var resume := button("继续远征",func():
		if model.load_from(SAVE): active = true; paused = false; overlay.hide(); refresh()
		else: notice.text = "存档无法读取，可开始新远征"; overlay.hide())
	resume.disabled = not FileAccess.file_exists(SAVE); menu.add_child(resume)
	menu.add_child(label("新远征将在首次自动保存时替换本 Demo 存档。",12))

func start_session() -> void:
	model = Model.new(); board.model = model; active = true; paused = false
	board.particles.clear(); board.rings.clear(); board.numbers.clear()
	save_clock = 0; overlay.hide(); refresh()

func show_pause() -> void:
	if not active: return
	paused = true
	clear_menu("行动暂停", "升级与轰炸已暂停。进度每 30 秒自动保存。")
	menu.add_child(button("返回舰桥",func(): paused = false; overlay.hide()))
	menu.add_child(button("设置",show_settings))
	menu.add_child(button("保存进度",func(): notice.text = "进度已保存" if save_game() else "保存失败"))
	menu.add_child(button("开始新远征…",func():
		clear_menu("重新开始远征？","将从一艘轻炮舰开始；新的自动保存会替换当前 Demo 存档。")
		menu.add_child(button("确认开始",start_session)); menu.add_child(button("取消",show_pause))))

func show_settings() -> void:
	clear_menu("设置", "画面与声音")
	var motion := CheckButton.new(); motion.text = "减少动态效果"; motion.button_pressed = board.reduced
	motion.toggled.connect(func(v: bool): board.reduced = v); menu.add_child(motion)
	var mute := CheckButton.new(); mute.text = "静音"; mute.button_pressed = muted
	mute.toggled.connect(func(v: bool): muted = v); menu.add_child(mute)
	menu.add_child(button("返回菜单",show_pause))

func show_inventory() -> void:
	if not active: return
	clear_menu("藏品舱", "首次发现默认锁定；解锁出售不撤销蓝图。舰队继续作业。")
	var scroll := ScrollContainer.new(); scroll.custom_minimum_size.y = 260; menu.add_child(scroll)
	var items := VBoxContainer.new(); items.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(items)
	for item in model.inventory:
		if item.sold: continue
		var row := HBoxContainer.new(); items.add_child(row)
		row.add_child(label(("遗迹核心" if item.source == "armor" else "记忆晶体")+"  %d 金属" % item.value))
		var lock := button("解锁" if item.locked else "锁定",func(): item.locked = not item.locked; show_inventory()); row.add_child(lock)
		var sell := button("出售",func(): model.sell(int(item.id)); show_inventory(); refresh()); sell.disabled = item.locked; row.add_child(sell)
	if items.get_child_count() == 0: items.add_child(label("集火金色热点，等待无人机将宝藏运回。"))
	var auto := CheckButton.new(); auto.text = "自动出售后续重复藏品"; auto.button_pressed = model.auto_sell
	auto.toggled.connect(func(v: bool): model.auto_sell = v); menu.add_child(auto)
	menu.add_child(button("返回舰桥",func(): overlay.hide()))

func refresh() -> void:
	cash.text = "%d 金属" % int(model.wallet)
	logistics.text = "地表 %d   /   运输中 %d\n舰船 %d   ·   无人机 %d   ·   击破 %d" % [model.ground_value(),model.transit_value(),model.ships.size(),model.drones.size(),model.kills]
	var goal: String = "攒够 80 金属，购买自动火控。"
	if model.auto_fire: goal = "扩编轻炮舰和无人机；击破 20 个结构暴露宝库。"
	if model.first_spawned: goal = "点击金色宝库持续集火；回收宝藏解锁重炮舰。"
	if model.unlocked: goal = "购买重炮舰 → 研究穿甲弹 → 集火重甲遗迹。"
	if model.armor_returned: goal = "补齐额外舰船与无人机，完成本次行动。"
	if model.completed: goal = "行动完成！可继续轰炸、扩编和收藏。"
	mission.text = "当前目标\n"+goal
	for key in cards:
		var why: String = model.reason(key); var cost: int = model.price(key)
		cards[key].disabled = why != ""
		cards[key].text = why if cost < 0 else ("购买 · %d 金属" % cost if why == "" else "%d 金属 · %s" % [cost,why])
		cards[key].tooltip_text = why

func _process(dt: float) -> void:
	if not active or paused: return
	model.tick(minf(dt,0.05)); board.step(minf(dt,0.05))
	refresh_clock += dt; save_clock += dt
	if refresh_clock > 0.15: refresh_clock = 0; refresh()
	if save_clock >= 30: save_clock = 0; save_game()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed: model.held = false
	if event.is_action_pressed("ui_cancel"):
		if active and overlay.visible: paused = false; overlay.hide()
		else: show_pause()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and model != null: model.held = false
	if what == NOTIFICATION_WM_CLOSE_REQUEST: save_game()

func save_game() -> bool:
	return model.save_to(SAVE) == OK if active and not testing else false

func play_shot(heavy: bool) -> void:
	if muted or not active: return
	var wave := AudioStreamWAV.new(); wave.format = AudioStreamWAV.FORMAT_16_BITS; wave.mix_rate = 22050
	var bytes := PackedByteArray(); bytes.resize(2205 * 2)
	for i in range(2205):
		var t: float = float(i)/22050.0
		var value: float = sin(TAU*(65.0 if heavy else 120.0)*t)*exp(-t*45.0)*0.2
		bytes.encode_s16(i*2,int(value*32767))
	wave.data = bytes; audio.stream = wave; audio.play()
