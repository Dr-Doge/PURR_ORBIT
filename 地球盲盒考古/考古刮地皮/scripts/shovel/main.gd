extends "res://scripts/ea/main.gd"

const ShovelModel = preload("res://scripts/shovel/model.gd")
const ShovelBoard = preload("res://scripts/shovel/board.gd")
var shovel_label: Label
var shovel_status: Label
var shovel_icon: TextureRect
var shovel_buy_button: Button
var shovel_price_label: Label
var shovel_owned_label: Label
var power_label: Label
var power_button: Button
var range_label: Label
var range_button: Button

func _ready() -> void:
	model=ShovelModel.new()
	save_path="user://shovel_save.dat"
	settings_path="user://shovel_settings.cfg"
	super._ready()

func _create_board() -> Control: return ShovelBoard.new()

func _build() -> void:
	super._build()
	_configure_old_ui(self)
	var panel := _panel(self,Rect2(20,30,302,72),Color("102125"))
	panel.mouse_filter=Control.MOUSE_FILTER_STOP
	shovel_icon=TextureRect.new(); shovel_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	shovel_icon.texture=load("res://assets/Jomin Assets/shovel1-transparent.png")
	shovel_icon.position=Vector2(12,11); shovel_icon.size=Vector2(30,48)
	shovel_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shovel_icon.mouse_filter=Control.MOUSE_FILTER_IGNORE; panel.add_child(shovel_icon)
	shovel_label=_text(panel,"",Rect2(55,8,236,26),20,ACCENT)
	shovel_status=_text(panel,"",Rect2(55,39,236,24),12,MUTED)
	move_child(panel,get_children().find(overlay))

func _build_upgrades() -> void:
	_text(upgrade_stack,"铲子扩充",Rect2(0,0,210,26),17,ACCENT).custom_minimum_size=Vector2(210,26)
	var card := _panel(upgrade_stack,Rect2(0,0,210,190)); card.custom_minimum_size=Vector2(210,190)
	shovel_owned_label=_text(card,"",Rect2(12,12,186,26),17,ACCENT)
	shovel_price_label=_text(card,"",Rect2(12,49,186,60),14)
	shovel_buy_button=_button(card,"",Rect2(10,132,190,42),_buy_shovel)
	var power_card := _panel(upgrade_stack,Rect2(0,0,210,166)); power_card.custom_minimum_size=Vector2(210,166)
	power_label=_text(power_card,"",Rect2(12,12,186,95),13,ACCENT)
	power_button=_button(power_card,"",Rect2(10,114,190,40),_buy_power)
	var range_card := _panel(upgrade_stack,Rect2(0,0,210,166)); range_card.custom_minimum_size=Vector2(210,166)
	range_label=_text(range_card,"",Rect2(12,12,186,95),13,ACCENT)
	range_button=_button(range_card,"",Rect2(10,114,190,40),_buy_range)
	var help := _text(upgrade_stack,"点击地面派出空闲铲子。\n点击铲子召回，进度归零。\n多把可同时作业，挖完返回。",Rect2(0,0,210,90),13,MUTED)
	help.custom_minimum_size=Vector2(210,90)

func _buy_shovel() -> void:
	if model.buy_shovel(): notify("新铲子已入库 · 现在拥有 %d 把"%model.shovel_count)
	_refresh()

func _buy_power() -> void:
	if model.buy_power(): notify("全体铲子强度提升 · 新派遣任务生效")
	_refresh()

func _buy_range() -> void:
	if model.buy_range(): notify("全体铲子范围提升 · 新派遣任务生效")
	_refresh()

func _configure_old_ui(node: Node) -> void:
	if node is Button and node.text=="天赋树": node.hide()
	if node is Button and node.text=="古物库存": node.size.x=224
	if node is Label:
		if node.text=="地球盲盒考古 / v0.3": node.text="自动铲子挖掘"
		elif node.text=="废料": node.text="挖掘点数"
	for child in node.get_children(): _configure_old_ui(child)

func open_page(page: String) -> void:
	if page in ["talents","shop","developer"]: return
	super.open_page(page)

func _refresh() -> void:
	super._refresh()
	var idle: int = model.idle_count()
	var returning := 0
	for unit in model.shovels:
		if unit.phase=="returning": returning+=1
	if is_instance_valid(shovel_label):
		shovel_label.text="铲子  %d / %d"%[idle,model.shovel_count]
		shovel_label.tooltip_text="空闲 / 已拥有"
		shovel_status.text="空闲 %d · 作业 %d · 返回 %d"%[idle,model.shovel_count-idle-returning,returning]
	status.text="已拥有 %d / 10 把铲子\n基础首层 20 秒 · 每层耗时 ×5"%model.shovel_count
	if is_instance_valid(power_button):
		power_label.text="铲子强度 Lv.%d · 全体共享\n每级速度 ×1.2\n当前层 %.1f → %.1f 秒\n新派遣生效 · 最低 2 秒"%[model.power_level,model.dig_seconds(model.base_depth),model.dig_seconds(model.base_depth,model.power_level+1)]
		var power_reason: String = model.power_purchase_reason()
		power_button.disabled=not power_reason.is_empty()
		power_button.text=power_reason if not power_reason.is_empty() else "升级强度 · %s 点"%model.power_price().display()
	if is_instance_valid(range_button):
		range_label.text="铲子范围 Lv.%d / 5\n每级半径 +10%%\n半径 %.1f → %.1f\n全体共享 · 新派遣生效"%[model.range_level,model.dig_radius(),model.dig_radius(mini(5,model.range_level+1))]
		var range_reason: String = model.range_purchase_reason()
		range_button.disabled=not range_reason.is_empty()
		range_button.text=range_reason if not range_reason.is_empty() else "升级范围 · %s 点"%model.range_price().display()
	if is_instance_valid(shovel_buy_button):
		var reason: String = model.shovel_purchase_reason()
		shovel_buy_button.disabled=not reason.is_empty()
		shovel_owned_label.text="已拥有  %d / 10"%model.shovel_count
		shovel_price_label.text="铲子已全部解锁\n可同时派出 10 把" if model.shovel_count>=10 else "第 %d 把铲子\n需要 %d 点"%[model.shovel_count+1,model.next_shovel_price()]
		shovel_buy_button.text=reason if not reason.is_empty() else "购买铲子 · %d 点"%model.next_shovel_price()
	if notice_clock<=0:
		notice.text="已暂停全部作业" if model.paused else ("点击土层派出一把空闲铲子" if idle>0 else "铲子正在作业或返回\n请等待空闲铲子")

func _build_start_menu() -> void:
	super._build_start_menu(); _replace_menu_text(start_menu)

func _replace_menu_text(node: Node) -> void:
	if node is Label:
		if node.text=="地球盲盒考古": node.text="自动挖土铲子"
		elif node.text=="刮开废土，寻找遗落的文明": node.text="赚取点数，组建你的挖掘小队"
	for child in node.get_children(): _replace_menu_text(child)
