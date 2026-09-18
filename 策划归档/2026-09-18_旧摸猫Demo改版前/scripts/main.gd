extends Control
const Model = preload("res://scripts/model.gd")
const Room = preload("res://scripts/room.gd")
const D = preload("res://scripts/data.gd")
const SAVE = "user://furball_demo_v1.save"
var model = Model.new()
var room
var active: bool = false
var paused: bool = true
var testing: bool = false
var muted: bool = false
var modal: String = "start"
var overlay: PanelContainer
var menu: VBoxContainer
var wallet_label: Label
var goal: Label
var notice_label: Label
var cards: Dictionary = {}
var info: Label
var save_clock: float = 0
var refresh_clock: float = 0
var graph: GraphEdit
var detail: VBoxContainer
var mini_buttons: Array = []
var mini_status: Label
var mini_room
var audio: AudioStreamPlayer
var tone: AudioStreamWAV
var sound_cd: float = 0
func box(color: String = "fffaf0",border: String = "d8cbb9") -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color(color); style.border_color = Color(border); style.set_border_width_all(1); style.set_corner_radius_all(12)
	style.content_margin_left = 12; style.content_margin_right = 12; style.content_margin_top = 7; style.content_margin_bottom = 7; return style
func label(value: String,size: int = 15) -> Label:
	var l := Label.new(); l.text = value; l.add_theme_font_size_override("font_size",size); return l
func paragraph(value: String,parent: Node) -> Label:
	var l := label(value); l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; parent.add_child(l); return l
func button(value: String,callback: Callable,parent: Node) -> Button:
	var b := Button.new(); b.text = value; b.custom_minimum_size.y = 34; b.pressed.connect(callback); b.mouse_default_cursor_shape = CURSOR_POINTING_HAND; parent.add_child(b); return b
func column(parent: Node) -> VBoxContainer:
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation",8); parent.add_child(v); return v
func clear(parent: Node) -> void:
	for child in parent.get_children(): parent.remove_child(child); child.queue_free()
func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var font := SystemFont.new(); font.font_names = PackedStringArray(["Microsoft YaHei","Segoe UI"])
	theme = Theme.new(); theme.default_font = font; theme.default_font_size = 14
	for type in ["Label","Button","CheckButton","OptionButton","GraphNode"]:
		theme.set_color("font_color",type,Color("594e46")); theme.set_color("font_hover_color",type,Color("356c60")); theme.set_color("font_disabled_color",type,Color("a49889"))
	for state in ["normal","hover","pressed","disabled"]: theme.set_stylebox(state,"Button",box("e3eee3" if state == "hover" else "fffaf0"))
	var bg := ColorRect.new(); bg.color = Color("f5f0e6"); bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(bg)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,16)
	add_child(margin); var root_box := column(margin)
	var header := HBoxContainer.new(); root_box.add_child(header)
	var title := label("毛球满屋",30); title.size_flags_horizontal = SIZE_EXPAND_FILL; header.add_child(title)
	button("成长树 ↑",show_tree,header); button("小收藏与道具",show_inventory,header); button("纸箱寻宝",show_minigame,header); button("扭蛋",show_gacha,header); button("菜单",show_pause,header)
	var body := HBoxContainer.new(); body.size_flags_vertical = SIZE_EXPAND_FILL; body.add_theme_constant_override("separation",14); root_box.add_child(body)
	room = Room.new(); room.model = model; room.size_flags_horizontal = SIZE_EXPAND_FILL; body.add_child(room)
	room.notice.connect(func(value: String): notice_label.text = value)
	room.placed.connect(close_modal)
	var panel := PanelContainer.new(); panel.custom_minimum_size.x = 270; panel.add_theme_stylebox_override("panel",box("eee7d9")); body.add_child(panel)
	var scroll := ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; panel.add_child(scroll)
	var side := column(scroll); side.size_flags_horizontal = SIZE_EXPAND_FILL
	side.add_child(label("小猫的储蓄罐",14)); wallet_label = label("0.0 毛球",29); wallet_label.add_theme_color_override("font_color",Color("4e8175")); side.add_child(wallet_label)
	info = label("",12); side.add_child(info)
	goal = paragraph("",side); goal.custom_minimum_size.y = 60
	button("手动产毛升级 / 成长树",func(): show_tree("hand"),side)
	side.add_child(HSeparator.new()); side.add_child(label("邀请新伙伴",18))
	for kind in ["short","long","static","lucky"]:
		var row := HBoxContainer.new(); side.add_child(row)
		var color := OptionButton.new()
		for name in D.CATS[kind].colors: color.add_item(name)
		color.custom_minimum_size.x = 88; row.add_child(color)
		var b := button("",func(): transact(func(): return model.buy(kind,color.selected)),row); b.size_flags_horizontal = SIZE_EXPAND_FILL; cards[kind] = b
	side.add_child(HSeparator.new()); side.add_child(label("自动化小帮手",18))
	for kind in ["spirit","wand","heater","spark"]:
		cards[kind] = button("",func(): transact(func(): return model.buy(kind)),side)
	button("摆放 / 收回设施",show_facilities,side)
	side.add_child(HSeparator.new()); button("房间增益装饰",show_decor,side)
	paragraph("鼠标来回移动，无需按键。\n一次只摸一只猫；更多猫给精灵提供并行目标。",side)
	notice_label = label("欢迎回家。先轻轻摸摸地毯上的小猫吧。",13); root_box.add_child(notice_label)
	overlay = PanelContainer.new(); overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT); overlay.add_theme_stylebox_override("panel",box("f5f0e6")); add_child(overlay)
	var center := CenterContainer.new(); overlay.add_child(center); menu = column(center); menu.custom_minimum_size = Vector2(1100,650)
	audio = AudioStreamPlayer.new(); add_child(audio); tone = AudioStreamWAV.new(); tone.format = AudioStreamWAV.FORMAT_16_BITS; tone.mix_rate = 22050
	var data := PackedByteArray(); data.resize(4410)
	for i in range(2205): data.encode_s16(i*2,int(sin(TAU*650*i/22050.0)*exp(-float(i)/450)*1700))
	tone.data = data; refresh(); show_start()
func screen(title: String,description: String,kind: String,freeze: bool = true) -> void:
	room.reset_pointer(); room.interactive = false; room.placing = -1; modal = kind; paused = freeze; overlay.show(); clear(menu)
	var header := HBoxContainer.new(); menu.add_child(header); var l := label(title,28); l.size_flags_horizontal = SIZE_EXPAND_FILL; header.add_child(l)
	if active: button("回到猫咪房间",close_modal,header)
	paragraph(description,menu)
func close_modal() -> void:
	if not active: show_start(); return
	modal = ""; paused = false; overlay.hide(); room.interactive = true; room.placing = -1; room.reset_pointer(); refresh()
func show_start() -> void:
	screen("毛球满屋", "一只小猫，一块地毯，一间慢慢热闹起来的房间。\n来回摸猫 → 收到毛球 → 邀请伙伴 → 让精灵帮忙。", "start")
	button("开始新的小猫生活",start_game,menu)
	var b := button("读取猫舍存档",func():
		if model.load_from(SAVE): active = true; close_modal()
		else: paragraph("存档无法读取，原文件未覆盖。",menu),menu); b.disabled = not FileAccess.file_exists(SAVE)
	button("设置",show_settings,menu)
	paragraph("独立 Godot Demo · 新游戏自动保存会覆盖本项目存档。\n不需要按住鼠标，不显示满足度条；猫的整体动作会告诉你它有多舒服。",menu)
func start_game() -> void:
	model = Model.new(); room.model = model; room.particles.clear(); room.numbers.clear(); room.rings.clear(); active = true; save_clock = 0; close_modal()
func show_pause() -> void:
	if not active: return
	screen("猫咪打个盹", "房间、精灵、小游戏与道具时间已暂停。", "pause")
	button("继续摸猫",close_modal,menu); button("设置",show_settings,menu)
	button("保存进度",func(): paragraph("已保存" if save_game() else "保存失败",menu),menu)
	button("重新开始…",func():
		screen("重新开始？","新进度将替换本项目的猫舍存档。","confirm")
		button("确认新生活",start_game,menu); button("取消",show_pause,menu),menu)
func show_settings() -> void:
	screen("设置","视觉与声音设置仅作用于本次运行。","settings")
	var mute := CheckButton.new(); mute.text = "静音"; mute.button_pressed = muted; mute.toggled.connect(func(v: bool): muted = v); menu.add_child(mute)
	var reduced := CheckButton.new(); reduced.text = "减少毛球粒子"; reduced.button_pressed = room.reduced; reduced.toggled.connect(func(v: bool): room.reduced = v); menu.add_child(reduced)
	button("返回",show_pause if active else show_start,menu)
func transact(action: Callable) -> void:
	if not action.call(): notice_label.text = model.error
	refresh()
func refresh() -> void:
	wallet_label.text = "%.1f 毛球" % model.wallet
	info.text = "猫咪 %d只  ·  精灵 %d个\n游玩券 %d  ·  代币暂未开放" % [model.cats.size(),model.count("spirit")+model.count("spark"),model.tickets]
	for i in range(3):
		if model.buffs[i] > 0: info.text += "\n%s · %.0f秒" % [D.ITEMS[i],model.buffs[i]]
	var message: String = "把鼠标放在猫身上来回摸，无需按键。"
	if model.earned >= 1: message = "攒到4毛球可升级手动产毛，也可攒12毛球买首个精灵。"
	if model.lv("hand","yield") > 0: message = "邀请第二只猫；成长树免费研发精灵，再花12毛球购买。"
	if model.count("spirit") > 0: message = "精灵正在赶路照料。你可以继续摸另一只猫。"
	if model.auto_unlocked: message = "纸箱寻宝已开放；玩配对时精灵继续工作。"
	if model.completed: message = "闭环完成！继续向上研发长毛猫和更多设施，看看房间能多热闹。"
	goal.text = message
	for kind in cards:
		var why: String = model.buy_reason(kind)
		cards[kind].text = "%s  %d/%d\n%d 毛球" % [D.title(kind),model.count(kind),model.limit(kind),model.price(kind)]
		cards[kind].disabled = why != "" or model.wallet < model.price(kind)
		cards[kind].tooltip_text = why if why != "" else "购买一个真实实例；上限升级另行购买"
func show_tree(subject: String = "") -> void:
	if not active: return
	screen("让猫舍一点点长大 ↑", "从下向上浏览。购买主节点只开放下一节点和旁支，不赠猫或工具；无需购买任何旁支来推进。", "tree")
	var row := HBoxContainer.new(); menu.add_child(row)
	button("回到当前进度",func(): position_tree(graph,model.stage),row)
	var body := HBoxContainer.new(); body.custom_minimum_size.y = 520; menu.add_child(body)
	graph = GraphEdit.new(); graph.custom_minimum_size.x = 760; graph.size_flags_horizontal = SIZE_EXPAND_FILL; graph.minimap_enabled = false
	graph.add_theme_stylebox_override("panel",box("e9e4d6")); body.add_child(graph)
	detail = column(body); detail.custom_minimum_size.x = 290
	for index in range(8):
		var kind: String = D.ORDER[index]; var at := Vector2(240,(7-index)*350)
		var node := GraphNode.new(); node.name = kind; node.title = "M%02d · %s" % [index,D.title(kind)]; node.position_offset = at; graph.add_child(node)
		button("已研发" if index <= model.stage else (("可研发" if index == model.stage+1 else "前项未研发")+" · %d 毛球" % D.RESEARCH[index]),func():
			if index == 0: show_subject("short")
			else: show_research(index),node)
		node.set_slot(0,true,0,Color("619687"),true,0,Color("619687"))
		if index > 0: graph.connect_node(D.ORDER[index-1],0,kind,0)
		var owner: String = "short" if index == 0 else kind
		branch_node(owner,at+Vector2(260,0),kind)
		if index == 0: branch_node("hand",at-Vector2(230,0),kind)
	if subject == "": subject = "short" if model.stage == 0 else D.ORDER[model.stage]
	show_subject(subject); position_tree(graph,0 if subject == "hand" else model.stage)
func branch_node(subject: String,at: Vector2,parent: String) -> void:
	var node := GraphNode.new(); node.name = subject+"_branches"; node.title = D.title(subject)+" · 可选旁支"; node.position_offset = at; graph.add_child(node)
	for key in D.BRANCHES[subject]:
		var cost: int = model.upgrade_price(subject,key)
		button(D.LABELS[key]+" · Lv.%d%s" % [model.lv(subject,key)," / 待定或满级" if cost < 0 else ""],func(): show_branch(subject,key),node)
	node.set_slot(0,true,0,Color("ba9b74"),false,0,Color("ba9b74")); graph.connect_node(parent,0,node.name,0)
func position_tree(view: GraphEdit,index: int) -> void:
	await get_tree().process_frame; await get_tree().process_frame
	if is_instance_valid(view) and graph == view and modal == "tree": view.scroll_offset = Vector2(-15,(7-index)*350-70)
func show_research(index: int) -> void:
	clear(detail); var kind: String = D.ORDER[index]; detail.add_child(label(D.title(kind),23))
	paragraph("主体研发：%d毛球\n研发不会赠送实体。主节点购买后即可继续向上，不要求旁支等级。" % D.RESEARCH[index],detail)
	var b := button("购买主节点",func(): transact(func(): return model.research(index)); show_tree(kind),detail); b.disabled = index != model.stage+1 or model.wallet < D.RESEARCH[index]
	if index <= model.stage: paragraph("已研发，可在房间右栏购买。",detail)
	if kind == "lucky": paragraph("招财抛币正面率待设计；目前只展示研发位置，不开放猫咪购买与收费抛币。",detail)
func show_subject(subject: String) -> void:
	clear(detail); detail.add_child(label(D.title(subject),23))
	paragraph("点击旁支查看效果和费用。\n同类型共享等级，各项独立购买。\n持有上限只放宽数量，不赠送实体。",detail)
	if subject in ["hand","short"]: paragraph("初始已开放。手动产毛首级能让亲手完成的奖励更明显。",detail)
	else: show_research(D.ORDER.find(subject))
func branch_description(subject: String,key: String) -> String:
	match key:
		"yield": return "猫种每级＋1毛球；手动每级额外＋1；精灵来源每级＋20%。逗猫棒与暖炉使用各自独立产量。"
		"double": return "本次普通毛球双倍概率＋5个百分点；每个产出事件只判定一次，不多抽物品。"
		"move": return "实际移动速度×1.15；不改变抚摸速度、满足阈值或CD。"
		"drop": return "物品掉率＋1个百分点；不是品质概率，也不是代币概率。"
		"quality": return "已掉落物品时，提高少见与稀有档权重；不增加物品抽取次数。"
		"cap": return "本类持有上限＋1；其他类型的上限不变，不设房间总猫数门槛。"
		"sale": return "所有换金收藏售价每级＋20%；已有库存按出售时等级结算。"
		"speed": return "毛球精灵实际抚摸速度×1.25；不改变行走速度和休息CD。"
		"cd": return "工作间隔除以1.2；抵达后仍须真实完成工作。"
		"range": return "本类设施作用半径×1.15；不会增加持有上限。"
		_: return "参数待用户补充，不收费，不影响其他主节点推进。"
func show_branch(subject: String,key: String) -> void:
	clear(detail); detail.add_child(label(D.title(subject)+" / "+D.LABELS[key],18))
	paragraph(branch_description(subject,key),detail)
	var price: int = model.upgrade_price(subject,key)
	paragraph("Lv.%d → Lv.%d\n%s" % [model.lv(subject,key),model.lv(subject,key)+1,"待定或达到等级上限" if price < 0 else "本级费用：%d毛球" % price],detail)
	var b := button("购买本次升级",func(): transact(func(): return model.upgrade(subject,key)); show_tree(subject); show_branch(subject,key),detail)
	b.disabled = not model.unlocked(subject) or price < 0 or model.wallet < price
func show_inventory() -> void:
	if not active: return
	screen("猫咪的小收藏", "房间自动化继续工作。首件默认锁定；出售不删除图鉴。道具使用后才开始计时。", "inventory",false)
	var scroll := ScrollContainer.new(); scroll.custom_minimum_size.y = 420; menu.add_child(scroll); var list := column(scroll); list.size_flags_horizontal = SIZE_EXPAND_FILL
	paragraph("已发现 %d / %d 款" % [model.discovered.size(),D.COLLECTIBLES.size()],list)
	for item in model.inventory:
		var row := HBoxContainer.new(); list.add_child(row); row.add_child(label(D.COLLECTIBLES[item.item]+" · %.1f毛球" % model.sale_value(item)))
		button("解锁" if item.locked else "锁定",func(): item.locked = not item.locked; show_inventory(),row)
		button("出售",func(): model.sell(item.id); show_inventory(),row).disabled = item.locked
	if model.inventory.is_empty(): paragraph("摸满足时有机会吐出收藏；首次在前12次合格产出内保底。",list)
	list.add_child(HSeparator.new())
	for i in range(3):
		button("%s ×%d · %s" % [D.ITEMS[i],model.consumables[i],"剩余 %.0f秒" % model.buffs[i] if model.buffs[i] > 0 else "点击使用"],func(): model.use_item(i); show_inventory(),list).disabled = model.consumables[i] <= 0 or model.buffs[i] > 0 or (i == 0 and model.count("spirit") == 0)
	paragraph("羽毛：普通精灵抚摸×1.5／30秒；金贴：普通毛球×1.5／30秒；铃铛：物品掉率＋2个百分点／60秒。同类不可重复使用。",list)
func show_facilities() -> void:
	screen("布置地毯", "固定设施买入库存，手动摆下才生效；收回仍占本类数量。摆放编辑时暂停。", "facilities")
	for t in model.tools:
		if t.kind not in ["wand","heater"]: continue
		var row := HBoxContainer.new(); menu.add_child(row); row.add_child(label(D.title(t.kind)+(" · 已摆放" if t.placed else " · 在库存")))
		button("摆放 / 移动",func(): overlay.hide(); room.reset_pointer(); room.placing = t.id; room.interactive = false; modal = "place",row)
		button("收回",func(): t.placed = false; show_facilities(),row)
	paragraph("暖炉让进入暖区的猫优先在附近换位；逗猫棒只奖励真正经过，不奖励原地停留或重摆。",menu)
func show_decor() -> void:
	screen("留在房间里的成长", "购买即在地毯边缘摆放，节点与实体共用一份等级。本Demo的三件装饰固定在预留位。", "decor")
	for key in ["bed","post","bell"]:
		paragraph({"bed":"蓬松猫窝：普通毛球每级＋10%","post":"猫抓柱：普通精灵抚摸速度每级＋10%","bell":"幸运猫铃架：物品掉率每级＋1个百分点"}[key],menu)
		button("%s Lv.%d · 升级 %d毛球" % [D.title(key),model.decor[key],model.decor_price(key)],func(): model.buy_decor(key); show_decor(),menu).disabled = model.decor[key] >= (6 if key == "bell" else 3) or model.wallet < model.decor_price(key)
func show_minigame() -> void:
	if not active: return
	screen("纸箱里藏着什么？", "配对三个图案。这里不暂停自动化；自动收入实时到账，完成时只额外领取本局奖励。", "mini",false)
	if not model.auto_unlocked:
		paragraph("等第一只精灵真正摸出毛球后，纸箱游乐台会开放并送你一张券。",menu); return
	if model.minigame.is_empty() or model.minigame.claimed:
		paragraph("当前游玩券 %d。每局消耗1券，完成奖励2毛球＋1件临时道具。" % model.tickets,menu)
		button("开始奖励局",func():
			if model.start_minigame(): show_minigame(),menu).disabled = model.tickets <= 0
		if not model.minigame.is_empty(): paragraph("上一局奖励已入账。",menu)
		return
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation",18); menu.add_child(row)
	var grid := GridContainer.new(); grid.columns = 3; row.add_child(grid); mini_buttons.clear()
	for i in range(6): mini_buttons.append(button("纸箱",func(): model.flip(i); refresh_mini(),grid)); mini_buttons.back().custom_minimum_size = Vector2(220,120)
	var preview := column(row); preview.add_child(label("猫咪们仍在忙碌",16))
	mini_room = Room.new(); mini_room.model = model; mini_room.mouse_filter = MOUSE_FILTER_IGNORE; mini_room.custom_minimum_size = Vector2(340,240); preview.add_child(mini_room)
	mini_status = paragraph("",menu); refresh_mini()
	button("先回房间，下次继续同一局",close_modal,menu)
func refresh_mini() -> void:
	if modal != "mini" or mini_buttons.is_empty() or not is_instance_valid(mini_buttons[0]) or model.minigame.is_empty(): return
	var g: Dictionary = model.minigame
	if is_instance_valid(mini_room): mini_room.clock = model.elapsed; mini_room.queue_redraw()
	for i in range(6):
		mini_buttons[i].text = ["小鱼干","猫爪印","毛线团"][g.deck[i]] if g.open.has(i) or g.matched.has(i) else "纸箱 · "+str(i+1)
		mini_buttons[i].disabled = g.claimed or g.matched.has(i)
	mini_status.text = "本局期间真实自动收入：%.1f毛球 · 当前钱包 %.1f\n%s" % [model.auto_earned-g.auto_start,model.wallet,"配对完成，奖励已领取：2毛球＋"+D.ITEMS[g.reward] if g.claimed else "中途离开会保存题面，继续不重复扣券。"]
func show_gacha() -> void:
	screen("独立扭蛋收藏", "此入口不依赖成长树或场景设施。房间自动化继续运行。", "gacha",false)
	paragraph("扭蛋费用、奖池、重复规则、保底和代币概率尚未配置，本Demo不开放扣费。\n招财猫的规则保留为：抛币正面仅1枚代币，反面整次无奖励；不会擅自使用50%概率或发普通毛球。",menu)
func _process(dt: float) -> void:
	if not active or paused: return
	var step: float = minf(dt,0.05); model.tick(step); sound_cd -= step
	if not muted and sound_cd <= 0:
		for e in model.events:
			if e.kind == "money": audio.stream = tone; audio.play(); sound_cd = 0.12; break
	room.step(step); refresh_clock += dt; save_clock += dt
	if refresh_clock > 0.15: refresh_clock = 0; refresh(); refresh_mini()
	if save_clock > 20: save_clock = 0; save_game()
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if modal == "mini": show_pause()
		elif overlay.visible or modal == "place": close_modal()
		else: show_pause()
		get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and active: room.reset_pointer(); show_pause()
	if what == NOTIFICATION_WM_CLOSE_REQUEST: save_game()
func save_game() -> bool: return model.save_to(SAVE) == OK if active and not testing else false
