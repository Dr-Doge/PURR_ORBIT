extends Control
const Model = preload("res://scripts/fleet/simulation.gd")
const Board = preload("res://scripts/fleet/planet_view.gd")
const Slot = preload("res://scripts/fleet/module_slot.gd")
const C = preload("res://scripts/fleet/catalog.gd")
const SAVE = "user://fleet_demo_v3.save"
var model = Model.new()
var board
var active: bool = false
var paused: bool = false
var testing: bool = false
var save_clock: float = 0
var refresh_clock: float = 0
var cash: Label
var logistics: Label
var mission: Label
var notice: Label
var hint: Label
var hint_button: Button
var depart_button: Button
var overlay: PanelContainer
var menu: VBoxContainer
var modal: String = ""
var tree_tab: int = 0
var graph: GraphEdit
var detail: VBoxContainer
var current_subject: String = "frigate"
var edit_kind: String = "frigate"
var edit_id: int = -1
var edit_keys: Array = []
var edit_count: int = 1
var edit_template: int = 0
var edit_group: Array = []
var selected_module: String = "kinetic"
var slot_box: GridContainer
var quote_label: Label
var confirm_button: Button
var mouse_turn: int = 0
var held_keys: Dictionary = {}
var rate_time: float = 0
var last_extracted: float = 0
var last_returned: float = 0
var extract_rate: float = 0
var return_rate: float = 0
var displayed_hint: Dictionary = {}
var hint_changed: float = -10
var hint_age: float = 0
var hint_expanded: bool = false
var audio: AudioStreamPlayer
var shot_sound: AudioStreamWAV
var sound_clock: float = 0

func style(color: String, border: String = "294353") -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = Color(color); s.border_color = Color(border)
	s.set_border_width_all(1); s.set_corner_radius_all(7)
	s.content_margin_left = 12; s.content_margin_right = 12; s.content_margin_top = 9; s.content_margin_bottom = 9
	return s
func label(text: String, sz: int = 15) -> Label:
	var node := Label.new(); node.text = text; node.add_theme_font_size_override("font_size",sz); return node
func paragraph(text: String, parent: Node = null) -> Label:
	var node := label(text); node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if parent != null: parent.add_child(node)
	return node
func button(text: String, action: Callable, parent: Node = null) -> Button:
	var node := Button.new(); node.text = text; node.custom_minimum_size.y = 30; node.pressed.connect(action)
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if parent != null: parent.add_child(node)
	return node
func clear(node: Node) -> void:
	for child in node.get_children(): node.remove_child(child); child.queue_free()
func column(parent: Node) -> VBoxContainer:
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation",9); parent.add_child(v); return v
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var font := SystemFont.new(); font.font_names = PackedStringArray(["Microsoft YaHei","Segoe UI"])
	theme = Theme.new(); theme.default_font = font; theme.default_font_size = 14
	theme.set_color("font_color","Label",Color("dce7ee"))
	for state in ["normal","hover","pressed","disabled"]: theme.set_stylebox(state,"Button",style("214739" if state == "hover" else "182c3a"))
	theme.set_color("font_disabled_color","Button",Color("6d8394"))
	var bg := ColorRect.new(); bg.color = Color("080f1b"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,12)
	add_child(margin); var root_box := column(margin)
	var top := HBoxContainer.new(); root_box.add_child(top)
	var title := label("游牧舰队 / 远征舰桥",22); title.size_flags_horizontal = SIZE_EXPAND_FILL; top.add_child(title)
	button("操作手册",show_help,top); button("藏品舱",show_inventory,top); button("菜单 / ESC",show_pause,top)
	var body := HBoxContainer.new(); body.size_flags_vertical = SIZE_EXPAND_FILL; body.add_theme_constant_override("separation",12); root_box.add_child(body)
	board = Board.new(); board.model = model; board.size_flags_horizontal = SIZE_EXPAND_FILL; body.add_child(board)
	board.message.connect(func(text: String): notice.text = text)
	board.selected_ship.connect(func(id: int): open_refit(id))
	var panel := PanelContainer.new(); panel.custom_minimum_size.x = 302; panel.add_theme_stylebox_override("panel",style("101e2c")); body.add_child(panel)
	var side_scroll := ScrollContainer.new(); side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; panel.add_child(side_scroll)
	var side := column(side_scroll); side.size_flags_horizontal = SIZE_EXPAND_FILL; side.size_flags_vertical = SIZE_EXPAND_FILL; side.add_theme_constant_override("separation",5); side.add_child(label("舰队控制  /  COMMAND",15))
	cash = label("",30); cash.add_theme_color_override("font_color",Color("79e1cd")); side.add_child(cash)
	logistics = label("",13); side.add_child(logistics)
	mission = paragraph("",side); mission.custom_minimum_size.y = 42
	button("舰体 / 武器 / 装备 / 全局研究树",func(): show_tree(),side)
	button("舰队管理与现役改装",show_fleet,side)
	button("建造舰船与模板",func(): open_build("frigate"),side)
	button("母舰机库 / 掠袭舰",show_hangars,side)
	var groups := OptionButton.new(); groups.add_item("集火：全部轰炸炮台"); groups.add_item("集火：仅穿甲炮台"); groups.add_item("集火：常规火力（不含穿甲）")
	groups.item_selected.connect(func(i: int): model.focus_group = ["all","ap","normal"][i]); side.add_child(groups)
	button("中子炮：进入手动瞄准",func():
		if model.has_installed("neutron"): model.nuclear_armed = true; notice.text = "点击地表或特殊目标发射，右键取消"
		else: notice.text = "先研发歼星舰与中子炮，解锁特殊槽并安装",side)
	button("紧急撤离 · 免费维修",func(): model.emergency(),side)
	var spacer := Control.new(); spacer.size_flags_vertical = SIZE_EXPAND_FILL; side.add_child(spacer)
	var hint_panel := PanelContainer.new(); hint_panel.add_theme_stylebox_override("panel",style("183431","497667")); side.add_child(hint_panel)
	var hint_column := column(hint_panel); hint_column.add_theme_constant_override("separation",5); hint_column.add_child(label("舰桥副官",13)); hint = paragraph("",hint_column); hint.custom_minimum_size.y = 42
	var hint_row := HBoxContainer.new(); hint_column.add_child(hint_row)
	hint_button = button("定位",locate_hint,hint_row)
	button("稍后",func(): model.tutorial_later = model.elapsed+30; displayed_hint = {}; refresh(),hint_row)
	button("关闭",func(): model.tutorial_enabled = false; displayed_hint = {}; refresh(),hint_row)
	var nav := HBoxContainer.new(); side.add_child(nav)
	for direction in [-1,1]:
		var b := button("◀ A 按住" if direction < 0 else "按住 D ▶",func(): pass,nav); b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.button_down.connect(func(): mouse_turn = direction)
		b.button_up.connect(func(): mouse_turn = 0)
	depart_button = button("驶离星球",leave_planet,side)
	notice = label("舰桥系统待命。",13); root_box.add_child(notice)
	overlay = PanelContainer.new(); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); overlay.add_theme_stylebox_override("panel",style("091421")); add_child(overlay)
	var center := CenterContainer.new(); overlay.add_child(center); menu = column(center); menu.custom_minimum_size = Vector2(1100,650)
	audio = AudioStreamPlayer.new(); add_child(audio)
	shot_sound = AudioStreamWAV.new(); shot_sound.format = AudioStreamWAV.FORMAT_16_BITS; shot_sound.mix_rate = 22050
	var bytes := PackedByteArray(); bytes.resize(2205*2)
	for i in range(2205): bytes.encode_s16(i*2,int(sin(TAU*100.0*i/22050.0)*exp(-float(i)/500.0)*2400))
	shot_sound.data = bytes
	refresh(); show_start()
func stop_input() -> void:
	held_keys.clear(); mouse_turn = 0; model.turn = 0; model.nuclear_armed = false; board.interactive = false
func screen(title: String, description: String, name: String, freeze: bool = true) -> void:
	stop_input(); modal = name; paused = freeze; overlay.show(); clear(menu)
	var row := HBoxContainer.new(); menu.add_child(row)
	var heading := label(title,27); heading.size_flags_horizontal = SIZE_EXPAND_FILL; row.add_child(heading)
	if active: button("返回舰桥 / ESC",close_screen,row)
	paragraph(description,menu)
func close_screen() -> void:
	if not active: show_start(); return
	stop_input(); modal = ""; paused = false; overlay.hide(); board.interactive = true; refresh()
func show_start() -> void:
	screen("游牧舰队", "你是太空游牧部族的可汗。三颗星球，一支舰队，掠尽资源、击破防御、带着宝藏继续远征。\n自动轰炸 → 按住 A / D 航行 → 扩军与改装 → 宝库集火 → 回收并驶离", "start")
	button("开始新远征",start_session,menu)
	var load_button := button("读取新版存档",func():
		if model.load_from(SAVE): active = true; close_screen()
		else: paragraph("读取失败：文件无效或版本不符。原文件未覆盖。",menu),menu)
	load_button.disabled = not FileAccess.file_exists(SAVE)
	button("设置",show_settings,menu)
	paragraph("v0.3.2 原型 · 新版独立存档，保留旧 v0.2 存档。\n开始新远征后，新版进度将于自动保存时替换。数值为 EA 试玩初稿。",menu)
func start_session() -> void:
	var preferences: Dictionary = model.settings.duplicate(); var guide_enabled: bool = model.tutorial_enabled
	model = Model.new(); model.settings = preferences; model.tutorial_enabled = guide_enabled; board.model = model; board.particles.clear(); board.rings.clear(); board.numbers.clear()
	active = true; save_clock = 0; rate_time = 0; last_extracted = 0; last_returned = 0; displayed_hint = {}; close_screen()
func show_pause() -> void:
	if not active: return
	screen("行动暂停","模拟、运输和敌袭均暂停。每 30 秒自动保存。","pause")
	button("继续远征",close_screen,menu); button("设置",show_settings,menu)
	button("保存进度",func(): paragraph("保存成功" if save_game() else "保存失败",menu),menu)
	button("开始新远征…",func():
		screen("开始新远征？","将重置本次进度，并在下一次保存时替换新版存档。","confirm")
		button("确认重开",start_session,menu); button("取消",show_pause,menu),menu)
func show_settings() -> void:
	screen("设置","关闭引导后仍可随时打开操作手册。设置随新版存档保存。","settings")
	for entry in [["mute","静音"],["reduced","减少粒子"],["merge","合并到账跳字"]]:
		var key: String = entry[0]; var check := CheckButton.new(); check.text = entry[1]; check.button_pressed = model.settings[key]
		check.toggled.connect(func(value: bool): model.settings[key] = value); menu.add_child(check)
	var check := CheckButton.new(); check.text = "启用舰桥副官引导"; check.button_pressed = model.tutorial_enabled
	check.toggled.connect(func(value: bool): model.tutorial_enabled = value; model.tutorial_later = 0); menu.add_child(check)
	button("返回",show_pause if active else show_start,menu)
func show_help() -> void:
	screen("舰桥操作手册","打开本手册时模拟暂停。","help")
	paragraph("1. 开局自动开炮，炮弹按命中时的星球角度提取资源。焦黑地表不会再生。\n2. 按住 A / D 或右栏左右按钮转动星球；右键取消集火或中子瞄准。\n3. 地表货物不等于钱包。掠袭舰自动往返；离屏货物也能回收。\n4. 研究解锁购买资格，分支升级影响同型号。武器依次研发，不必升满。\n5. 模板仅用于未来购舰；改变现役舰必须在舰队管理中确认改装。模块可拖进槽位。\n6. 普通炮台不会自动攻击固定防御。点击红色阵地或金色宝库持续集火。\n7. 防空炮独立拦截导弹与飞机。穿甲先破甲，激光无破甲能力。\n8. 全星资源耗尽且固定防御全灭才出现宝库。宝库击破、威胁清除、货物全部到账后驶离。\n9. 舰船失能不会永久消失。紧急撤离免费维修，保留地表、敌人和货物。\n10. 藏品舱不暂停；研究树、改装、设置与交易确认暂停。",menu)
func show_inventory() -> void:
	screen("藏品舱 / 模块仓库","舰队继续作业。首次藏品默认锁定；出售不撤销许可。安装中的模块需先卸下。","inventory",false)
	var scroll := ScrollContainer.new(); scroll.custom_minimum_size.y = 450; menu.add_child(scroll); var list := column(scroll); list.size_flags_horizontal = SIZE_EXPAND_FILL
	for item in model.inventory:
		var row := HBoxContainer.new(); list.add_child(row); row.add_child(label(item.name+" · %d 金属" % item.value+("（已售出，图鉴保留）" if item.sold else "")))
		if not item.sold:
			button("解锁" if item.locked else "锁定",func(): item.locked = not item.locked; show_inventory(),row)
			var sell := button("出售",func(): confirm_sale("出售 "+item.name,func(): model.sell_treasure(item.id)),row); sell.disabled = item.locked
	if model.inventory.is_empty(): paragraph("尚未回收藏品。每颗星球的最终宝库拥有一件独特藏品。",list)
	list.add_child(HSeparator.new()); list.add_child(label("未装配模块"))
	for m in model.modules:
		if model.installed_ids().has(m.id): continue
		button(C.title(m.kind)+" #%d · 退回 %d 金属" % [m.id,m.paid],func(): confirm_sale("退役模块 "+C.title(m.kind),func(): model.sell_module(m.id)),list)
func confirm_sale(title: String, action: Callable) -> void:
	screen(title,"按实际支付金额退款；赠品退款为 0。研发与升级费用不退。","confirm")
	button("确认",func(): action.call(); show_inventory(),menu); button("取消",show_inventory,menu)
func show_fleet() -> void:
	screen("现役舰队","点击舰船进入改装。模板修改不会改变现役舰。退役舰体保留卸下的模块。","fleet")
	var scroll := ScrollContainer.new(); scroll.custom_minimum_size.y = 460; menu.add_child(scroll); var list := column(scroll); list.size_flags_horizontal = SIZE_EXPAND_FILL
	for s in model.ships:
		var row := HBoxContainer.new(); list.add_child(row)
		var b := button("#%d %s   生命 %d/%d  装甲 %d/%d" % [s.id,C.title(s.kind),s.hp,model.max_hp(s),s.armor,model.max_armor(s)],func(): open_refit(s.id),row); b.size_flags_horizontal = SIZE_EXPAND_FILL
		button("退役",func():
			screen("退役 "+C.title(s.kind),"舰体返还 %d 金属；模块卸回仓库。受损或装填中的舰船不可退役。" % s.paid,"confirm")
			button("确认退役",func():
				if model.sell_ship(s.id): show_fleet()
				else: paragraph(model.error,menu),menu)
			button("取消",show_fleet,menu),row)
func show_hangars() -> void:
	screen("母舰机库与掠袭舰","每艘掠袭舰 60 金属。机库升级只增加泊位，不赠送掠袭舰。飞行中的货物和耗时已锁定。","hangar")
	var scroll := ScrollContainer.new(); scroll.custom_minimum_size.y = 450; menu.add_child(scroll); var list := column(scroll); list.size_flags_horizontal = SIZE_EXPAND_FILL
	for s in model.ships:
		if s.kind != "carrier": continue
		button("母舰 #%d · %d/%d   ＋购买掠袭舰 60 金属" % [s.id,model.carrier_load(s.id),model.hangar_max()],func():
			if model.buy_raider(s.id): show_hangars()
			else: paragraph(model.error,menu),list)
		for d in model.drones:
			if d.carrier != s.id: continue
			var row := HBoxContainer.new(); list.add_child(row); row.add_child(label("    掠袭舰 #%d · %s" % [d.id,"运输中" if d.time > 0 else "待命"]))
			var dest := OptionButton.new(); var ids: Array = []
			for other in model.ships:
				if other.kind == "carrier": dest.add_item("转至母舰 #%d" % other.id); ids.append(other.id)
			row.add_child(dest); button("转移",func(): model.move_raider(d.id,ids[dest.selected]); show_hangars(),row)
			button("退役",func(): model.sell_raider(d.id); show_hangars(),row).disabled = d.time > 0 or d.paid == 0
	button("打开运输升级",func(): show_tree(3,"cargo"),menu)

func open_build(kind: String) -> void:
	edit_kind = kind; edit_id = -1; edit_count = 1; edit_template = 0; edit_group.clear()
	edit_keys = model.templates[kind][0].duplicate(); fit_slot_count(); show_loadout()
func open_refit(id: int) -> void:
	var s: Dictionary = model.ship(id)
	if s.is_empty(): return
	edit_kind = s.kind; edit_id = id; edit_count = 1; edit_keys = model.loadout_keys(s); edit_group.clear(); show_loadout()
func fit_slot_count() -> void:
	var count: int = int(C.HULLS[edit_kind].slots)+(model.level("special") if edit_kind == "destroyer" else 0)
	while edit_keys.size() < count: edit_keys.append("")
func show_loadout() -> void:
	screen(("现役改装" if edit_id >= 0 else "建造与模板")+" / "+C.title(edit_kind),"从模块库拖入槽位，或先点选模块再点击槽位。允许重复、空槽和纯防空。确认前不会花费。","loadout")
	if edit_id >= 0:
		var group := CheckButton.new(); group.text = "将此配置应用于全部同型号现役舰（整批核价与确认）"; group.button_pressed = not edit_group.is_empty(); menu.add_child(group)
		group.toggled.connect(func(value: bool):
			edit_group.clear()
			if value:
				for s in model.ships:
					if s.kind == edit_kind: edit_group.append(s.id)
			update_quote())
	if edit_id < 0:
		var row := HBoxContainer.new(); menu.add_child(row)
		for kind in C.HULLS: button(C.title(kind),func(): open_build(kind),row)
		var variants := HBoxContainer.new(); menu.add_child(variants)
		var picker := OptionButton.new()
		for i in range(model.templates[edit_kind].size()): picker.add_item("模板 "+str(i+1))
		picker.select(edit_template); picker.item_selected.connect(func(i: int): edit_template = i; edit_keys = model.templates[edit_kind][i].duplicate(); fit_slot_count(); show_loadout()); variants.add_child(picker)
		button("保存当前模板",func(): model.templates[edit_kind][edit_template] = edit_keys.duplicate(); notice.text = "模板已保存，仅影响未来购舰",variants)
		button("另存新模板",func(): model.templates[edit_kind].append(edit_keys.duplicate()); edit_template = model.templates[edit_kind].size()-1; show_loadout(),variants)
		var amount := SpinBox.new(); amount.min_value = 1; amount.max_value = 48; amount.value = edit_count; amount.prefix = "建造数量 "; variants.add_child(amount)
		amount.value_changed.connect(func(v: float): edit_count = int(v); update_quote())
	var body := HBoxContainer.new(); body.size_flags_vertical = SIZE_EXPAND_FILL; menu.add_child(body)
	var left := column(body); left.custom_minimum_size.x = 340
	left.add_child(label("模块库 / 拖拽或点击选择",16))
	var palette := GridContainer.new(); palette.columns = 2; left.add_child(palette)
	var keys: Array = [""]; keys.append_array(C.WEAPONS.keys()); keys.append_array(C.GEAR.keys())
	for key in keys:
		var b = Slot.new(); b.palette = true; b.key = key; b.text = "清空槽位" if key == "" else C.title(key)+"\n%d 金属" % C.module_price(key); b.custom_minimum_size = Vector2(158,48)
		b.disabled = key != "" and not model.researched.has(key); b.pressed.connect(func(): selected_module = key; notice.text = "已选择："+("清空" if key == "" else C.title(key))); palette.add_child(b)
	var right := column(body); right.size_flags_horizontal = SIZE_EXPAND_FILL
	right.add_child(label("实际槽位配置",17)); slot_box = GridContainer.new(); slot_box.columns = 2; right.add_child(slot_box)
	quote_label = paragraph("",right); quote_label.custom_minimum_size.y = 110
	confirm_button = button("核对并确认",confirm_loadout,right)
	redraw_slots(); update_quote()
func redraw_slots() -> void:
	clear(slot_box)
	for i in range(edit_keys.size()):
		var key: String = edit_keys[i]; var b = Slot.new(); b.index = i; b.key = key
		b.text = ("特殊槽" if i >= int(C.HULLS[edit_kind].slots) else "普通槽")+str(i+1)+"  /  "+("空" if key == "" else C.title(key)); b.custom_minimum_size = Vector2(310,42)
		b.module_dropped.connect(set_slot); b.pressed.connect(func(): set_slot(i,selected_module)); slot_box.add_child(b)
func set_slot(index: int, key: String) -> void:
	var draft: Array = edit_keys.duplicate(); draft[index] = key
	var why: String = model.valid_loadout(edit_kind,draft)
	if why != "": notice.text = why; return
	edit_keys = draft; redraw_slots(); update_quote()
func update_quote() -> void:
	var q: Dictionary = current_quote()
	var bombard: int = 0; var aa: int = 0
	for key in edit_keys:
		if key == "aa": aa += 1
		elif C.WEAPONS.has(key): bombard += 1
	var hull_cost: int = int(C.HULLS[edit_kind].price)*edit_count if edit_id < 0 else 0
	quote_label.text = "舰体 %d + 新购模块 %d = 总价 %d 金属\n库存模块优先使用 · 钱包 %d\n指挥点 %d/%d · 本批新增 %d\n每舰轰炸炮 %d / 防空炮 %d%s\n%s" % [hull_cost,q.price-hull_cost,q.price,model.wallet,model.command_used(),model.command_max(),int(C.HULLS[edit_kind].cmd)*edit_count if edit_id < 0 else 0,bombard,aa,"（没有地表火力）" if bombard == 0 else "",q.error]
	if not edit_group.is_empty(): quote_label.text += "\n整批现役舰 %d 艘" % edit_group.size()
	confirm_button.disabled = q.error != "" or q.price > model.wallet
func current_quote() -> Dictionary:
	return model.group_trial(edit_group,edit_keys) if not edit_group.is_empty() else model.quote(edit_kind,edit_keys,edit_count,edit_id)
func confirm_loadout() -> void:
	var q: Dictionary = current_quote()
	screen("确认改装" if edit_id >= 0 else "确认建造", "%s × %d\n总价 %d 金属。库存模块将被独占使用，卸下的模块进入仓库。" % [C.title(edit_kind),edit_group.size() if not edit_group.is_empty() else edit_count,q.price],"confirm_loadout")
	button("支付并执行",func():
		var success: bool = model.refit_group(edit_group,edit_keys) if not edit_group.is_empty() else model.purchase(edit_kind,edit_keys,edit_count,edit_id)
		if success: close_screen()
		else: paragraph(model.error,menu),menu)
	button("返回配置",show_loadout,menu)

func show_tree(tab: int = 0, selected: String = "") -> void:
	tree_tab = tab; screen("舰队研究网络","拖动空白处平移 · 滚轮缩放 · 点击节点查看分支。研发只解锁资格；武器链不要求前项满级。","tree")
	var tabs := HBoxContainer.new(); menu.add_child(tabs)
	for i in range(4): button(["舰体","武器","装备","全局"][i],func(): show_tree(i),tabs)
	var body := HBoxContainer.new(); body.custom_minimum_size.y = 465; menu.add_child(body)
	graph = GraphEdit.new(); graph.custom_minimum_size.x = 770; graph.size_flags_horizontal = SIZE_EXPAND_FILL; graph.size_flags_vertical = SIZE_EXPAND_FILL
	graph.minimap_enabled = false; graph.right_disconnects = false; body.add_child(graph)
	detail = column(body); detail.custom_minimum_size.x = 305; detail.size_flags_horizontal = SIZE_EXPAND_FILL
	var subjects: Array = [C.HULLS.keys(),C.CHAIN,C.GEAR.keys(),["command","hangar","cargo","speed","special","nuclear_auto"]][tab]
	for i in range(subjects.size()):
		var key: String = subjects[i]; var x: float = i*225.0; var y: float = 35
		make_graph_node(key,C.title(key),Vector2(x,y))
		var branches: Array = []
		if tab == 0: branches = ["hp"] if key == "destroyer" else ["hp","armor"]
		if key == "destroyer": branches.append("reload")
		if tab == 1: branches = ["attack","reload"]
		if tab == 2: branches = ["strength"]
		for j in range(branches.size()):
			var branch: String = key+":"+branches[j]
			make_graph_node(branch,{"hp":"舰体生命","armor":"舰体装甲","attack":"武器威力","reload":"装填速度","strength":"装备强度"}[branches[j]],Vector2(x,125+j*95))
			graph.connect_node(key,0,branch.replace(":","_"),0)
		if tab == 1 and i > 0: graph.connect_node(subjects[i-1],0,key,0)
	current_subject = selected if selected != "" else subjects[0]; select_subject(current_subject)
	var idx: int = subjects.find(current_subject.split(":")[0])
	settle_graph(graph,Vector2(idx*225-70 if idx > 1 else -20,-40))
func settle_graph(view: GraphEdit, offset: Vector2) -> void:
	# GraphEdit recalculates scrollbar bounds during container layout; set the initial view afterwards.
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(view) and view == graph and modal == "tree": view.scroll_offset = offset
func make_graph_node(key: String, title: String, at: Vector2) -> void:
	var node := GraphNode.new(); node.name = key.replace(":","_"); node.title = title; node.position_offset = at; node.resizable = false; graph.add_child(node)
	var branch: bool = key.contains(":") or tree_tab == 3
	var status: String = "Lv.%d" % model.level(key) if branch else ("已研发" if model.researched.has(key) else "待研发")
	button(status+" · 查看",func(): select_subject(key),node); node.set_slot(0,true,0,Color("79e1cd"),true,0,Color("79e1cd"))
func select_subject(key: String) -> void:
	current_subject = key; clear(detail); var subject: String = key.split(":")[0]
	detail.add_child(label(C.title(subject),19))
	if key.contains(":") or tree_tab == 3:
		var cost: int = model.upgrade_price(key); var why: String = model.upgrade_reason(key)
		paragraph("当前 Lv.%d → Lv.%d\n%s\n费用 %s 金属\n%s" % [model.level(key),model.level(key)+1,upgrade_description(key),str(cost) if cost >= 0 else "—",why],detail)
		var b := button("购买此分支升级",func():
			if not model.upgrade(key): notice.text = model.error
			show_tree(tree_tab,key),detail); b.disabled = why != "" or cost > model.wallet
		return
	if C.WEAPONS.has(key):
		var w: Dictionary = C.WEAPONS[key]
		paragraph("模块 %d 金属\n甲伤 %.1f / 肉伤 %.1f\n提取强度 %.1f\n基础装填 %.1f 秒%s\n作用于所有同型号模块。" % [w.price,w.armor*model.power(key),w.hp*model.power(key),w.extract*model.power(key),w.reload," + 2 秒光束" if key == "laser" else ""],detail)
	elif C.HULLS.has(key):
		var h: Dictionary = C.HULLS[key]; paragraph("裸舰 %d 金属 / 指挥 %d\n普通槽 %d\n基础生命 %d / 装甲 %d\n同型号独立成长。" % [h.price,h.cmd,h.slots,h.hp,h.armor],detail)
	else: paragraph("模块 %d 金属\n%s" % [C.module_price(key),{"plate":"额外装甲 +40","repair":"额外生命 +100","energy":"每件装填加速 8%，总计上限 40%"}[key]],detail)
	var why: String = model.research_reason(key)
	paragraph("研发费用 %d 金属\n%s" % [model.research_price(key),why],detail)
	var b := button("研发主体",func():
		if not model.research(key): notice.text = model.error
		show_tree(tree_tab,key),detail)
	b.disabled = why != "" or model.wallet < model.research_price(key)
	if C.HULLS.has(key): button("配置并购买此舰",func(): open_build(key),detail)
	else: button("给现役舰安装",show_fleet,detail)
func upgrade_description(key: String) -> String:
	match key:
		"command": return "指挥容量 %d → %d" % [model.command_max(),C.COMMAND[mini(3,model.level(key)+1)]]
		"hangar": return "每母舰泊位 %d → %d" % [model.hangar_max(),mini(8,model.hangar_max()+2)]
		"cargo": return "单趟运力 %.0f → %.0f" % [40*pow(1.8,model.level(key)),40*pow(1.8,model.level(key)+1)]
		"speed": return "航速 ×1.2；在途任务保持原耗时"
		"special": return "每艘歼星舰特殊槽 +1（最多 2）"
		"nuclear_auto": return "中子自动发射；不自动寻找地表目标"
	if key.ends_with(":reload"): return "同型号装填速度 ×1.12（歼星舰 ×1.08）"
	if key == "energy:strength": return "单件装填加成 ×1.15，总加成仍最多 40%"
	return "同型号对应属性 ×1.25；零值不增加"
func locate_hint() -> void:
	var action: String = displayed_hint.get("action","")
	match action:
		"frigate": open_build("frigate")
		"kinetic": show_tree(1,"kinetic:attack")
		"aa", "ap": show_tree(1,action)
		"neutron": show_tree(1,"neutron")
		"command", "special", "nuclear_auto": show_tree(3,action)
		"nuclear": model.nuclear_armed = true
		"logistics": show_tree(3,"cargo")
		"refit": show_fleet()
		"retreat": model.emergency()
		"depart": leave_planet()
		"navigate", "vault", "focus": notice.text = "按住 A / D 或右栏方向键；底部罗盘金色点为宝库，红色点为防御"
		_: show_help()
func leave_planet() -> void:
	if model.depart():
		last_extracted = 0; last_returned = 0
		if model.phase == "finished":
			screen("远征完成", "三颗星球的资源与宝藏已运回。\n累计回收 %d 金属 · 舰队 %d 艘 · 藏品 %d 件\n模拟作业时间 %d 分 %d 秒（不含暂停决策）" % [model.earned,model.ships.size(),model.inventory.size(),int(model.elapsed)/60,int(model.elapsed)%60],"results")
			button("返回舰桥查看舰队",close_screen,menu)
	else: notice.text = model.error
	refresh()
func refresh() -> void:
	if cash == null: return
	cash.text = "%d 金属" % model.wallet
	logistics.text = "未提取 %d\n地表积压 %d  /  在途 %d\n提取 %.1f/s   到账 %.1f/s\n指挥 %d / %d   掠袭舰 %d" % [model.unextracted(),model.ground_value(),model.transit_value(),extract_rate,return_rate,model.command_used(),model.command_max(),model.drones.size()]
	mission.text = "%d / 3  %s\n%s" % [model.planet+1,model.config().name,{"surface":"掠尽地表与固定防御","vault":"最终宝库已暴露","recovery":"清除威胁并回收全部货物","ready":"回收完成，可安全驶离","finished":"三球远征已完成"}[model.phase]]
	depart_button.disabled = model.phase != "ready"; depart_button.text = "完成远征" if model.planet == 2 else "驶离 → 下一颗星球"
	var candidate: Dictionary = model.tutorial()
	if displayed_hint.is_empty() or candidate.is_empty() or candidate.get("urgent",false) or model.elapsed-hint_changed >= 3.0:
		if candidate != displayed_hint:
			displayed_hint = candidate; hint_changed = model.elapsed; hint_age = 0; hint_expanded = false
	hint.text = displayed_hint.get("text","副官已待命，可在设置中启用引导。")
	hint_button.disabled = displayed_hint.is_empty()
	hint_button.text = "点此定位 ◀" if hint_age >= 8 else "定位"
func _process(dt: float) -> void:
	if not active or paused: return
	model.turn = mouse_turn if mouse_turn != 0 else float(int(held_keys.get(KEY_D,false))-int(held_keys.get(KEY_A,false)))
	if overlay.visible: model.turn = 0
	var step: float = minf(dt,0.05); model.tick(step)
	sound_clock -= step
	if not model.settings.mute and sound_clock <= 0:
		for e in model.events:
			if e.kind == "shot": audio.stream = shot_sound; audio.play(); sound_clock = 0.15; break
	board.step(step)
	if not overlay.visible:
		hint_age += step
		if hint_age >= 20 and not hint_expanded:
			hint_expanded = true; notice.text = "副官提示：点击右栏「定位」查看相关控件；可在操作手册查阅完整说明。"
	refresh_clock += dt; save_clock += dt; rate_time += step
	if rate_time >= 1:
		var extracted: float = float(model.config().regions)*float(model.config().stock)-model.unextracted()
		extract_rate = maxf(0,(extracted-last_extracted)/rate_time); return_rate = maxf(0,(model.delivered-last_returned)/rate_time)
		last_extracted = extracted; last_returned = model.delivered; rate_time = 0
	if refresh_clock >= 0.15: refresh_clock = 0; refresh()
	if save_clock >= 30: save_clock = 0; save_game()
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode in [KEY_A,KEY_D]:
		if not event.pressed: held_keys.erase(event.physical_keycode)
		elif active and not overlay.visible and not event.echo: held_keys[event.physical_keycode] = true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed: mouse_turn = 0
	if event.is_action_pressed("ui_cancel"):
		if modal == "confirm_loadout": show_loadout()
		elif modal == "settings": show_pause() if active else show_start()
		elif overlay.visible: close_screen()
		else: show_pause()
		get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and board != null: stop_input(); if active: show_pause()
	if what == NOTIFICATION_WM_CLOSE_REQUEST: save_game()
func save_game() -> bool: return model.save_to(SAVE) == OK if active and not testing else false
