extends Node3D

const BOX_SCENE := preload("res://scenes/entities/physical_box.tscn")
const PRICE_CHART_SCENE := preload("res://scripts/ui/price_chart.gd")
const RARITIES := ["常见", "少见", "稀有", "史诗", "传说"]
const BASE_LUCK_WEIGHTS := [5000, 3000, 1000, 900, 100]
const TARGET_LUCK_WEIGHTS := [1000, 1400, 2200, 2500, 2900]
const SERIES_LUCK_MAX := [5, 10, 15]
const PROFICIENCY_THRESHOLDS := [5, 15, 30, 50, 80]
const PARCEL_PROFICIENCY_THRESHOLDS := [10, 30, 60, 100, 150]
const PROFICIENCY_PRICE_BONUS := 0.12
const GLOBAL_LUCK_COSTS := [50,100,1000,5000,10000,25000,50000,100000,250000,500000,1000000,2500000,5000000,10000000,25000000]
const RARITY_COLORS := [Color("#d9e0df"), Color("#76d98b"), Color("#62a8ff"), Color("#b989ff"), Color("#ffb347")]
const SERIES := [
	{"name":"桌角伙伴", "slogan":"小小桌角，也有大大的陪伴。", "base":10, "unlock":0, "color":Color("#59c7b5"), "items":["线团猫","吐司钟","云朵夹","镀金回形针","桌面之王"], "values":[1,15,50,300,5000]},
	{"name":"夜班小队", "slogan":"今晚不打烊，惊喜正在值班。", "base":250, "unlock":200, "color":Color("#526cb7"), "items":["咖啡骑士","灯泡幽灵","键盘鼹鼠","午夜主管","永夜董事"], "values":[25,375,1250,7500,125000]},
	{"name":"星港机修铺", "slogan":"穿过星港，把失落核心带回家。", "base":10000, "unlock":8000, "color":Color("#dd7048"), "items":["扳手机器人","货运水母","信标犬","零号领航员","星港初代核心"], "values":[1000,15000,50000,300000,5000000]}
]
const NEWS := ["桌角萌物进入热榜，入门盒价格温和上涨。","未拆盒开始出现溢价讨论。","夜班小队开放试销。","桌面潮流暂时退烧。","神秘买家寻找夜班藏品。","星港机修铺抵达本地。","收藏节成交活跃，市场进入新周期。"]
const FACTORS := [[1.10,1.0,1.0],[1.18,1.0,1.0],[0.92,1.05,1.0],[0.86,1.15,1.0],[1.02,1.32,1.0],[1.12,1.08,1.10],[1.26,1.18,1.35]]

@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var items_root: Node3D = $Items
@onready var wall_ticker: Label3D = $Room/MarketTicker/TickerLabel
@onready var wall_ticker_b: Label3D = $Room/MarketTicker/TickerLabelB

var rng := RandomNumberGenerator.new()
var day := 1
var cash: int = 3
var earned: int = 0
var collectibles: Array[Dictionary] = []
var discovered: Dictionary = {}
var boxes: Array[Node] = []
var global_luck_level := 0
var series_open_counts := [0, 0, 0]
var series_levels := [0, 0, 0]
var parcel_open_count := 0
var parcel_level := 0
var focused_box: RigidBody3D
var focus_origin := Transform3D.IDENTITY
var pointer_mode := ""
var pointer_start := Vector2.ZERO
var table_drag_box: RigidBody3D
var click_candidate: RigidBody3D
var seal_progress := 0.0
var gesture_progress := 0.0
var review_item: Node3D
var pending_item: Dictionary = {}

var money_label: Label
var value_label: Label
var date_label: Label
var parcel_label: Label
var detail_panel: PanelContainer
var detail_title: Label
var detail_hint: Label
var seal_bar: ProgressBar
var action_row: HBoxContainer
var sell_button: Button
var inventory_panel: PanelContainer
var inventory_list: VBoxContainer
var collection_panel: PanelContainer
var collection_grid: GridContainer
var market_panel: PanelContainer
var market_content: VBoxContainer
var loot_preview_panel: PanelContainer
var loot_preview_list: VBoxContainer
var toast_label: Label
var series_cards: Array[Dictionary] = []
var parcel_card_data: Dictionary
var luck_level_label: Label
var luck_probability_label: Label
var luck_button: Button
var ui_canvas: CanvasLayer
var ticker_source := ""
var ticker_scroll_x := 0.0

func _ready() -> void:
	rng.randomize()
	build_ui()
	refresh_ui()
	toast("用左侧 ¥1 购买快递盒；处理后把空盒推出桌边即可回收。")

func _process(delta: float) -> void:
	if ticker_source.is_empty(): return
	ticker_scroll_x -= delta * 0.82
	if ticker_scroll_x <= -6.4: ticker_scroll_x += 6.4
	wall_ticker.position.x = ticker_scroll_x
	wall_ticker_b.position.x = ticker_scroll_x + 6.4

func _physics_process(_delta: float) -> void:
	for box in boxes.duplicate():
		if not is_instance_valid(box): continue
		if box.global_position.y < -1.25 and box.opened:
			recycle_box(box)
		elif box.global_position.y < -3.0 and not box.opened:
			box.global_position = Vector3(rng.randf_range(-1.5, 2.5), 3.5, rng.randf_range(-1.2, 1.2))
			box.linear_velocity = Vector3.ZERO
			box.angular_velocity = Vector3.ZERO
			toast("未拆盒险些掉下桌面，已经重新送回桌上。")

func build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	ui_canvas = canvas
	# The player status is deliberately outside the shop scroll area so the
	# important economy information remains visible while browsing every series.
	var left_hud := PanelContainer.new()
	left_hud.position = Vector2(18, 18)
	left_hud.size = Vector2(272, 188)
	left_hud.add_theme_stylebox_override("panel", style(Color(0.055,0.07,0.085,0.95), 15, Color("#42505d"), 2))
	canvas.add_child(left_hud)
	var hud_column := VBoxContainer.new()
	hud_column.add_theme_constant_override("separation", 5)
	left_hud.add_child(hud_column)
	money_label = stat_label("现金")
	hud_column.add_child(money_label)
	value_label = stat_label("库存总价值")
	hud_column.add_child(value_label)
	date_label = stat_label("日期")
	hud_column.add_child(date_label)
	var end_day := button("结束今天", Color("#a45d43"))
	end_day.pressed.connect(end_day_pressed)
	hud_column.add_child(end_day)

	var left_shop := PanelContainer.new()
	left_shop.position = Vector2(18, 216)
	left_shop.size = Vector2(272, 486)
	left_shop.add_theme_stylebox_override("panel", style(Color(0.055,0.07,0.085,0.93), 15, Color("#42505d"), 2))
	canvas.add_child(left_shop)
	var left_scroll := ScrollContainer.new()
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	left_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_shop.add_child(left_scroll)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 238
	column.add_theme_constant_override("separation", 5)
	left_scroll.add_child(column)
	var parcel_card := make_shop_card("快递盒", "买入 ¥1 · 处理后回收 ¥2–3", Color("#a87e55"))
	parcel_label = parcel_card["detail"]
	parcel_card["button"].text = "购买  ¥1"
	parcel_card["button"].pressed.connect(buy_parcel)
	var parcel_mastery_label := make_label("拆箱熟练 Lv.0/5", 10, Color("#d0b28e"), true)
	parcel_card["column"].add_child(parcel_mastery_label)
	var parcel_mastery_bar := ProgressBar.new()
	parcel_mastery_bar.custom_minimum_size.y = 9
	parcel_mastery_bar.max_value = 100
	parcel_mastery_bar.show_percentage = false
	parcel_card["column"].add_child(parcel_mastery_bar)
	parcel_card["mastery_label"] = parcel_mastery_label
	parcel_card["mastery_bar"] = parcel_mastery_bar
	parcel_card_data = parcel_card
	column.add_child(parcel_card["panel"])
	for i in SERIES.size():
		var data: Dictionary = SERIES[i]
		var card := make_shop_card("盲盒 %d · %s" % [i + 1, data["name"]], "固定概率 50 / 30 / 10 / 9 / 1", data["color"])
		card["button"].pressed.connect(buy_box.bind(i))
		var mastery_label := make_label("熟练 Lv.0 / 5", 10, Color("#aeb9c5"), true)
		card["column"].add_child(mastery_label)
		var mastery_bar := ProgressBar.new()
		mastery_bar.custom_minimum_size.y = 9
		mastery_bar.max_value = 100
		mastery_bar.show_percentage = false
		card["column"].add_child(mastery_bar)
		card["mastery_label"] = mastery_label
		card["mastery_bar"] = mastery_bar
		column.add_child(card["panel"])
		series_cards.append(card)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var unknown := PanelContainer.new()
	unknown.custom_minimum_size.y = 45
	unknown.add_theme_stylebox_override("panel", style(Color("#20262c"), 10, Color("#4a545e"), 2))
	var unknown_label := make_label("？  新系列预留栏位", 16, Color("#78838e"), true)
	unknown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unknown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	unknown.add_child(unknown_label)
	column.add_child(unknown)

	var top_buttons := HBoxContainer.new()
	top_buttons.position = Vector2(890, 18)
	top_buttons.size = Vector2(372, 48)
	top_buttons.add_theme_constant_override("separation", 8)
	canvas.add_child(top_buttons)
	var market_button := button("行情", Color("#7b6739"))
	market_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_button.pressed.connect(toggle_market)
	top_buttons.add_child(market_button)
	var inv_button := button("库存", Color("#355d6d"))
	inv_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_button.pressed.connect(toggle_inventory)
	top_buttons.add_child(inv_button)
	var collect_button := button("收藏", Color("#67517c"))
	collect_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collect_button.pressed.connect(toggle_collection)
	top_buttons.add_child(collect_button)
	build_upgrade_panel(canvas)

	detail_panel = PanelContainer.new()
	detail_panel.position = Vector2(365, 535)
	detail_panel.size = Vector2(580, 155)
	detail_panel.visible = false
	detail_panel.add_theme_stylebox_override("panel", style(Color(0.06,0.075,0.09,0.94), 13, Color("#e7b967"), 2))
	canvas.add_child(detail_panel)
	var detail_col := VBoxContainer.new()
	detail_col.add_theme_constant_override("separation", 5)
	detail_panel.add_child(detail_col)
	detail_title = make_label("", 20, Color("#ffd178"), true)
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_col.add_child(detail_title)
	detail_hint = make_label("", 14, Color("#d3dae1"))
	detail_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_col.add_child(detail_hint)
	seal_bar = ProgressBar.new()
	seal_bar.max_value = 100
	seal_bar.show_percentage = false
	seal_bar.visible = false
	detail_col.add_child(seal_bar)
	action_row = HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 12)
	action_row.visible = false
	detail_col.add_child(action_row)
	sell_button = button("直接出售", Color("#9a6240"))
	sell_button.custom_minimum_size.x = 210
	sell_button.pressed.connect(resolve_review.bind(true))
	action_row.add_child(sell_button)
	var keep_button := button("保留库存", Color("#397568"))
	keep_button.custom_minimum_size.x = 180
	keep_button.pressed.connect(resolve_review.bind(false))
	action_row.add_child(keep_button)
	toast_label = make_label("点击桌面上的箱子，将它拿到眼前查看。", 15, Color("#f0dfc4"), true)
	toast_label.position = Vector2(350, 665)
	toast_label.size = Vector2(600, 38)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(toast_label)

	inventory_panel = side_panel(canvas, "库存", 411)
	inventory_list = VBoxContainer.new()
	inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_list.add_theme_constant_override("separation", 7)
	var inv_scroll := ScrollContainer.new()
	inv_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inv_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inv_scroll.add_child(inventory_list)
	inventory_panel.get_child(0).add_child(inv_scroll)
	collection_panel = side_panel(canvas, "收藏册  ·  15 件", 411)
	collection_grid = GridContainer.new()
	collection_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection_grid.columns = 3
	collection_grid.add_theme_constant_override("h_separation", 6)
	collection_grid.add_theme_constant_override("v_separation", 6)
	collection_panel.get_child(0).add_child(collection_grid)
	market_panel = build_market_panel(canvas)
	loot_preview_panel = build_loot_preview_panel(canvas)

func build_upgrade_panel(canvas: CanvasLayer) -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(994, 74)
	panel.size = Vector2(268, 205)
	panel.add_theme_stylebox_override("panel", style(Color(0.055,0.07,0.085,0.94), 11, Color("#a98143"), 2))
	canvas.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)
	col.add_child(make_label("升级 · 整体幸运度", 16, Color("#ffd27c"), true))
	luck_level_label = make_label("", 12, Color("#e9edf1"), true)
	col.add_child(luck_level_label)
	luck_probability_label = make_label("", 9, Color("#98a5af"))
	luck_probability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(luck_probability_label)
	luck_button = button("整体升级", Color("#8b6a32"))
	luck_button.custom_minimum_size.y = 32
	luck_button.pressed.connect(upgrade_luck)
	col.add_child(luck_button)

func side_panel(canvas: CanvasLayer, title_text: String, height: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(888, 285)
	panel.size = Vector2(374, height)
	panel.visible = false
	panel.add_theme_stylebox_override("panel", style(Color(0.055,0.07,0.085,0.97), 13, Color("#4a5967"), 2))
	canvas.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	var title := make_label(title_text, 21, Color("#f4e4c6"), true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := button("×", Color("#5a4245"))
	close.custom_minimum_size.x = 42
	close.pressed.connect(func(): panel.visible = false)
	head.add_child(close)
	return panel

func build_market_panel(canvas: CanvasLayer) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(320, 72)
	panel.size = Vector2(850, 610)
	panel.visible = false
	panel.add_theme_stylebox_override("panel", style(Color(0.045,0.06,0.075,0.98), 14, Color("#8a7446"), 2))
	canvas.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	var title := make_label("收藏市场行情", 23, Color("#f3d89b"), true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := button("×", Color("#5a4245"))
	close.custom_minimum_size.x = 44
	close.pressed.connect(func(): panel.visible = false)
	head.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	market_content = VBoxContainer.new()
	market_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_content.add_theme_constant_override("separation", 10)
	scroll.add_child(market_content)
	return panel

func show_market_overview() -> void:
	clear_children(market_content)
	var intro := make_label("按系列查看全部内容物。点击任意图标可查看以日期为横轴、市价为纵轴的历史曲线。", 13, Color("#aeb9c5"))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	market_content.add_child(intro)
	for s in SERIES.size():
		var group := PanelContainer.new()
		group.add_theme_stylebox_override("panel", style(Color("#202933"), 10, SERIES[s]["color"], 2))
		market_content.add_child(group)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		group.add_child(col)
		col.add_child(make_label("盲盒 %d · %s" % [s + 1, SERIES[s]["name"]], 17, SERIES[s]["color"], true))
		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 7)
		col.add_child(grid)
		for r in 5:
			var item_button := button("%s\n%s" % [RARITIES[r], SERIES[s]["items"][r]], RARITY_COLORS[r].darkened(0.48))
			item_button.custom_minimum_size = Vector2(145, 62)
			item_button.tooltip_text = "点击查看价格曲线"
			item_button.pressed.connect(show_price_chart.bind(s, r))
			grid.add_child(item_button)

func show_price_chart(series_index: int, rarity: int) -> void:
	clear_children(market_content)
	var back := button("← 返回系列陈列", Color("#4d5b68"))
	back.pressed.connect(show_market_overview)
	market_content.add_child(back)
	var item_name: String = SERIES[series_index]["items"][rarity]
	market_content.add_child(make_label("%s · %s · %s" % [SERIES[series_index]["name"], RARITIES[rarity], item_name], 22, RARITY_COLORS[rarity], true))
	var current_market := market_price_at_day(series_index, rarity, day)
	market_content.add_child(make_label("第 %d 天市场价：¥%s  ·  熟练度后的实际售价：¥%s" % [day, comma(current_market), comma(collectible_price(series_index, rarity))], 14, Color("#d6dde3")))
	var prices: Array[float] = []
	var dates: Array[int] = []
	for date_index in range(1, day + 1):
		prices.append(float(market_price_at_day(series_index, rarity, date_index)))
		dates.append(date_index)
	var chart: Control = PRICE_CHART_SCENE.new()
	chart.custom_minimum_size = Vector2(800, 450)
	market_content.add_child(chart)
	chart.setup(prices, dates, RARITY_COLORS[rarity])

func build_loot_preview_panel(canvas: CanvasLayer) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(900, 78)
	panel.size = Vector2(362, 470)
	panel.visible = false
	panel.add_theme_stylebox_override("panel", style(Color(0.045,0.06,0.075,0.97), 13, Color("#d2aa5f"), 2))
	canvas.add_child(panel)
	loot_preview_list = VBoxContainer.new()
	loot_preview_list.add_theme_constant_override("separation", 5)
	panel.add_child(loot_preview_list)
	return panel

func populate_loot_preview(series_index: int) -> void:
	clear_children(loot_preview_list)
	loot_preview_list.add_child(make_label(SERIES[series_index]["name"], 22, SERIES[series_index]["color"], true))
	var slogan := make_label(SERIES[series_index]["slogan"], 13, Color("#d8c9ae"))
	slogan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loot_preview_list.add_child(slogan)
	loot_preview_list.add_child(line())
	for rarity in 5:
		var row := PanelContainer.new()
		row.custom_minimum_size.y = 68
		row.add_theme_stylebox_override("panel", style(Color("#202832"), 7, RARITY_COLORS[rarity]))
		loot_preview_list.add_child(row)
		var hbox := HBoxContainer.new()
		row.add_child(hbox)
		var item_label := make_label("%s · %s\n概率 %s  ·  市价 ¥%s" % [RARITIES[rarity], SERIES[series_index]["items"][rarity], rarity_probability_text(series_index, rarity), comma(collectible_price(series_index, rarity))], 12, RARITY_COLORS[rarity], true)
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(item_label)

func spawn_box(kind: String, series_index: int, rarity: int, paid: int, slot := 0) -> void:
	var box: RigidBody3D = BOX_SCENE.instantiate()
	items_root.add_child(box)
	box.setup(kind, series_index, rarity, paid, SERIES[series_index]["color"] if series_index >= 0 else Color("#b18458"))
	box.position = Vector3(-1.7 + slot * 1.15 + rng.randf_range(-0.25,0.25), 4.2 + slot * 0.45, rng.randf_range(-1.5,1.35))
	box.rotation = Vector3(rng.randf_range(-0.15,0.15), rng.randf_range(-1.8,1.8), rng.randf_range(-0.12,0.12))
	box.angular_velocity = Vector3(rng.randf_range(-1.2,1.2), rng.randf_range(-1.5,1.5), rng.randf_range(-1.0,1.0))
	boxes.append(box)

func buy_parcel() -> void:
	if cash < 1:
		toast("至少需要 ¥1 才能购入快递盒。")
		return
	cash -= 1
	spawn_box("parcel", -1, -1, 1, rng.randi_range(0, 2))
	toast("快递盒落到了桌面。处理并回收它可获得 ¥2–3。")
	refresh_ui()

func upgrade_luck() -> void:
	if global_luck_level >= GLOBAL_LUCK_COSTS.size():
		toast("整体幸运度已经达到最高等级。")
		return
	var cost: int = GLOBAL_LUCK_COSTS[global_luck_level]
	if cash < cost:
		toast("升级幸运度还需要 ¥%s。" % comma(cost - cash))
		return
	cash -= cost
	global_luck_level += 1
	toast("整体幸运升级至第 %d 阶；三个系列以不同速度获得概率提升。" % global_luck_level)
	refresh_ui()

func buy_box(series_index: int) -> void:
	if not series_unlocked(series_index):
		toast("这个系列仍未解锁。")
		return
	var price := box_price(series_index)
	if cash < price:
		toast("现金不足，还差 ¥%s。" % comma(price - cash))
		return
	cash -= price
	spawn_box("blind", series_index, roll_rarity(series_index), price, rng.randi_range(0, 2))
	toast("购买成功，盲盒从右侧落到了桌面。结果已锁定。")
	refresh_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if review_item:
			toast("请先选择直接出售或保留库存。")
		elif focused_box:
			exit_focus()
		else:
			inventory_panel.visible = false
			collection_panel.visible = false
			market_panel.visible = false
		return
	if market_panel.visible or inventory_panel.visible or collection_panel.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: on_pointer_down(event.position)
		else: on_pointer_up(event.position)
	elif event is InputEventMouseMotion:
		on_pointer_move(event)

func on_pointer_down(mouse_pos: Vector2) -> void:
	pointer_start = mouse_pos
	gesture_progress = 0.0
	if review_item:
		pointer_mode = "review_rotate"
		return
	if focused_box:
		var hit := ray_hit(mouse_pos, true)
		if hit and hit.collider is Area3D and hit.collider.name == "SealArea" and not focused_box.seal_removed:
			pointer_mode = "seal"
			seal_bar.visible = true
		elif hit and hit.collider is Area3D and hit.collider.name == "LidArea" and focused_box.seal_removed and not focused_box.lid_opened:
			pointer_mode = "lid"
			seal_bar.visible = true
		elif hit and hit.collider is Area3D and hit.collider.name == "ContentArea" and focused_box.lid_opened:
			pointer_mode = "content_lift"
			seal_bar.visible = true
		else:
			# Closed parcel/blind-box bodies are inspected from a fixed angle.
			# Only the collectible shown after opening supports free rotation.
			pointer_mode = ""
		return
	var hit := ray_hit(mouse_pos, false)
	var box := box_from_collider(hit.collider if hit else null)
	if box:
		click_candidate = box
		if box.opened:
			table_drag_box = box
			table_drag_box.freeze = true
			pointer_mode = "table_drag"

func on_pointer_move(event: InputEventMouseMotion) -> void:
	if pointer_mode == "review_rotate" and review_item:
		review_item.rotate_y(event.relative.x * 0.012)
		review_item.rotate_object_local(Vector3.RIGHT, event.relative.y * 0.012)
	elif pointer_mode == "seal" and focused_box:
		gesture_progress = clamp(gesture_progress + event.relative.length() / 105.0, 0.0, 1.0)
		seal_bar.value = gesture_progress * 100.0
		detail_hint.text = "持续拖动撕下封条  %d%%" % int(gesture_progress * 100.0)
	elif pointer_mode == "lid" and focused_box:
		gesture_progress = clamp((pointer_start.y - event.position.y) / 150.0, 0.0, 1.0)
		focused_box.set_lid_progress(gesture_progress)
		seal_bar.value = gesture_progress * 100.0
		detail_hint.text = "向上拖动盒盖  %d%%" % int(gesture_progress * 100.0)
	elif pointer_mode == "content_lift" and focused_box:
		gesture_progress = clamp((pointer_start.y - event.position.y) / 145.0, 0.0, 1.0)
		focused_box.set_content_lift(gesture_progress)
		seal_bar.value = gesture_progress * 100.0
		detail_hint.text = "把内容物拿出来  %d%%" % int(gesture_progress * 100.0)
	elif pointer_mode == "table_drag" and table_drag_box:
		var origin := camera.project_ray_origin(event.position)
		var direction := camera.project_ray_normal(event.position)
		var point: Variant = Plane(Vector3.UP, 0.85).intersects_ray(origin, direction)
		if point != null: table_drag_box.global_position = point

func on_pointer_up(mouse_pos: Vector2) -> void:
	if pointer_mode == "seal" and focused_box:
		if gesture_progress >= 0.65:
			focused_box.tear_seal()
			seal_bar.visible = false
			detail_hint.text = "封条已撕下。按住盒盖并向上拖动来打开。"
			toast("封条已拆除，现在需要亲手掀开盒盖。")
		else:
			toast("按住封条任意位置并持续拖动即可撕下。")
			seal_bar.value = 0
	elif pointer_mode == "lid" and focused_box:
		if gesture_progress >= 0.72:
			focused_box.finish_open_lid()
			seal_bar.visible = false
			if focused_box.box_kind == "parcel": finish_parcel_processing()
			else:
				detail_hint.text = "盒内物品已经出现。按住内容物向上拖出。"
				toast("盒盖打开了，把里面的藏品拿出来。")
		else:
			focused_box.set_lid_progress(0.0)
			seal_bar.value = 0
			toast("请按住盒盖，向上拖到完全打开。")
	elif pointer_mode == "content_lift" and focused_box:
		if gesture_progress >= 0.72: begin_content_review()
		else:
			focused_box.set_content_lift(0.0)
			seal_bar.value = 0
			toast("继续向上拖，把藏品完整取出。")
	elif pointer_mode == "table_drag" and table_drag_box:
		table_drag_box.freeze = false
		table_drag_box.sleeping = false
		table_drag_box.linear_velocity.y = -0.45
		table_drag_box.apply_central_impulse(Vector3(0, -0.15, 0))
		if abs(table_drag_box.global_position.x) > 5.7 or abs(table_drag_box.global_position.z) > 3.7:
			toast("松手让空盒掉到桌下，即可自动回收结算。")
		table_drag_box = null
	elif click_candidate and not click_candidate.opened and mouse_pos.distance_to(pointer_start) < 12.0:
		focus_box(click_candidate)
	click_candidate = null
	pointer_mode = ""

func focus_box(box: RigidBody3D) -> void:
	if focused_box or box.opened: return
	focused_box = box
	focus_origin = box.global_transform
	box.freeze = true
	box.linear_velocity = Vector3.ZERO
	box.angular_velocity = Vector3.ZERO
	var target := camera.global_position - camera.global_basis.z * 3.4
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(box, "global_position", target, 0.35)
	tween.tween_property(box, "rotation", Vector3(0.18, 0.55, 0.0), 0.35)
	detail_panel.visible = true
	loot_preview_panel.visible = box.box_kind == "blind"
	if box.box_kind == "blind": populate_loot_preview(box.series_index)
	detail_title.text = "快递盒" if box.box_kind == "parcel" else SERIES[box.series_index]["name"] + "盲盒"
	detail_title.add_theme_color_override("font_color", Color("#ffd178"))
	if not box.seal_removed: detail_hint.text = "按住盖子接缝处的黄色封条任意位置并拖动"
	elif not box.lid_opened: detail_hint.text = "封条已移除。按住盒盖向上拖动。"
	else: detail_hint.text = "按住盒内内容物并向上拖出。"
	seal_bar.visible = false
	action_row.visible = false
	toast("黄色封条就在盒盖与盒体的接缝处。")

func exit_focus() -> void:
	if not focused_box: return
	var box := focused_box
	focused_box = null
	detail_panel.visible = false
	loot_preview_panel.visible = false
	seal_bar.visible = false
	box.global_transform = focus_origin
	box.freeze = false
	box.apply_central_impulse(Vector3(0,0.25,0))
	pointer_mode = ""

func finish_parcel_processing() -> void:
	if not focused_box: return
	var box := focused_box
	parcel_open_count += 1
	update_parcel_proficiency()
	box.mark_empty()
	focused_box = null
	detail_panel.visible = false
	loot_preview_panel.visible = false
	box.global_transform = focus_origin
	box.freeze = false
	box.apply_central_impulse(Vector3(0,0.3,0))
	toast("快递处理完成。把空盒推出任意桌边，掉到桌下可获得 ¥2–3。")
	refresh_ui()

func begin_content_review() -> void:
	if not focused_box or focused_box.box_kind != "blind": return
	var box := focused_box
	var item_name: String = SERIES[box.series_index]["items"][box.rarity]
	pending_item = {"series":box.series_index, "rarity":box.rarity, "name":item_name}
	series_open_counts[box.series_index] += 1
	update_proficiency_level(box.series_index)
	register_discovery(pending_item)
	box.mark_empty()
	focused_box = null
	loot_preview_panel.visible = false
	box.global_transform = focus_origin
	box.freeze = false
	box.apply_central_impulse(Vector3(0,0.25,0))
	review_item = Node3D.new()
	review_item.position = camera.global_position - camera.global_basis.z * 3.15
	add_child(review_item)
	var shape := CSGSphere3D.new()
	shape.radius = 0.55 + box.rarity * 0.045
	shape.radial_segments = 20
	shape.rings = 10
	var material := StandardMaterial3D.new()
	material.albedo_color = RARITY_COLORS[box.rarity]
	material.metallic = 0.15 + box.rarity * 0.12
	material.roughness = 0.5
	material.emission_enabled = box.rarity >= 2
	material.emission = RARITY_COLORS[box.rarity] * 0.35
	shape.material = material
	review_item.add_child(shape)
	var accent := CSGTorus3D.new()
	accent.inner_radius = 0.5
	accent.outer_radius = 0.62
	accent.rotation.x = PI / 2.0
	accent.material = material
	review_item.add_child(accent)
	var price := collectible_price(box.series_index, box.rarity)
	detail_panel.visible = true
	detail_title.text = "%s · %s" % [RARITIES[box.rarity], item_name]
	detail_title.add_theme_color_override("font_color", RARITY_COLORS[box.rarity])
	detail_hint.text = "所属：%s  ·  当前概率：%s  ·  当前市价：¥%s\n熟练 Lv.%d（售价 +%d%%）· 按住物品可自由旋转查看" % [SERIES[box.series_index]["name"], rarity_probability_text(box.series_index, box.rarity), comma(price), series_levels[box.series_index], int(series_levels[box.series_index] * PROFICIENCY_PRICE_BONUS * 100.0)]
	seal_bar.visible = false
	action_row.visible = true
	sell_button.text = "直接出售  ¥%s" % comma(price)
	toast("查看藏品后选择出售或保留，随后才会返回桌面。")

func resolve_review(sell_now: bool) -> void:
	if not review_item or pending_item.is_empty(): return
	if sell_now:
		var price := collectible_price(pending_item["series"], pending_item["rarity"])
		cash += price
		earned += price
		toast("藏品出售，到账 ¥%s。" % comma(price))
	else:
		collectibles.append(pending_item.duplicate(true))
		toast("藏品已保留在库存。")
	review_item.queue_free()
	review_item = null
	pending_item.clear()
	detail_panel.visible = false
	action_row.visible = false
	pointer_mode = ""
	refresh_ui()

func recycle_box(box: RigidBody3D) -> void:
	var payout := 1
	if box.box_kind == "parcel":
		payout = int(round(rng.randi_range(2,3) * (1.0 + parcel_level * PROFICIENCY_PRICE_BONUS)))
	var recycle_position: Vector3 = box.global_position
	cash += payout
	earned += payout
	boxes.erase(box)
	box.queue_free()
	show_income_popup(payout, recycle_position)
	toast("空盒回收 +¥%d。桌面终于清爽了一点。" % payout)
	refresh_ui()

func show_income_popup(amount: int, world_position: Vector3) -> void:
	var popup := make_label("+ ¥%s" % comma(amount), 30, Color("#7dff9a"), true)
	var screen_position := camera.unproject_position(world_position)
	popup.position = Vector2(clamp(screen_position.x - 55.0, 305.0, 1160.0), clamp(screen_position.y - 25.0, 90.0, 640.0))
	popup.size = Vector2(130, 46)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.scale = Vector2(0.75, 0.75)
	popup.pivot_offset = popup.size * 0.5
	ui_canvas.add_child(popup)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "position:y", popup.position.y - 75.0, 1.0)
	tween.tween_property(popup, "scale", Vector2.ONE, 0.35)
	tween.tween_property(popup, "modulate:a", 0.0, 0.45).set_delay(0.6)
	tween.finished.connect(popup.queue_free)

func register_discovery(item: Dictionary) -> void:
	var key := "%d_%d" % [item["series"], item["rarity"]]
	if not discovered.has(key):
		discovered[key] = true
		var bonus: int = max(1, int(SERIES[item["series"]]["base"] * 0.1))
		cash += bonus
		earned += bonus

func sell_collectible(index: int) -> void:
	if index < 0 or index >= collectibles.size(): return
	var item := collectibles[index]
	var value := collectible_price(item["series"], item["rarity"])
	cash += value
	earned += value
	collectibles.remove_at(index)
	toast("藏品售出，到账 ¥%s。" % comma(value))
	refresh_ui()

func end_day_pressed() -> void:
	if focused_box or review_item:
		toast("请先完成当前查看流程。")
		return
	day += 1
	toast("进入第 %d 天：市场价格已更新，桌面与库存保持不变。" % day)
	refresh_ui()

func refresh_ui() -> void:
	money_label.text = "现金\n¥%s" % comma(cash)
	value_label.text = "库存总价值\n¥%s" % comma(total_inventory_value())
	date_label.text = "日期\n第 %d 天 · 无终局限制" % day
	parcel_label.text = "不限量 · 买 ¥1 / 回收 ¥2–3"
	var new_ticker_source: String = "今日行情 · " + NEWS[(day - 1) % NEWS.size()]
	if ticker_source != new_ticker_source:
		ticker_source = new_ticker_source
		ticker_scroll_x = 0.0
		wall_ticker.text = ticker_source
		wall_ticker_b.text = ticker_source
	refresh_luck_panel()
	refresh_parcel_mastery()
	for i in series_cards.size():
		var card := series_cards[i]
		if series_unlocked(i):
			card["detail"].text = "今日 ¥%s · 幸运 %d/%d" % [comma(box_price(i)), min(global_luck_level, SERIES_LUCK_MAX[i]), SERIES_LUCK_MAX[i]]
			card["button"].text = "购买  ¥%s" % comma(box_price(i))
			card["button"].disabled = cash < box_price(i)
		else:
			card["detail"].text = "累计收入 ¥%s 解锁" % comma(SERIES[i]["unlock"])
			card["button"].text = "未解锁"
			card["button"].disabled = true
		refresh_mastery_card(i, card)
	refresh_inventory()
	refresh_collection()

func refresh_luck_panel() -> void:
	luck_level_label.text = "整体升级 %d / %d" % [global_luck_level, GLOBAL_LUCK_COSTS.size()]
	var lines: Array[String] = []
	for i in SERIES.size():
		lines.append("盲盒%d 吸收进度  %d/%d" % [i + 1, min(global_luck_level, SERIES_LUCK_MAX[i]), SERIES_LUCK_MAX[i]])
	luck_probability_label.text = "\n".join(lines)
	if global_luck_level >= GLOBAL_LUCK_COSTS.size():
		luck_button.text = "整体幸运度已满"
		luck_button.disabled = true
	else:
		var cost: int = GLOBAL_LUCK_COSTS[global_luck_level]
		luck_button.text = "整体升级  ¥%s" % comma(cost)
		luck_button.disabled = cash < cost

func refresh_mastery_card(series_index: int, card: Dictionary) -> void:
	var level: int = series_levels[series_index]
	var count: int = series_open_counts[series_index]
	card["mastery_label"].text = "熟练 Lv.%d/5 · 售价 +%d%%" % [level, int(level * PROFICIENCY_PRICE_BONUS * 100.0)]
	if level >= 5:
		card["mastery_bar"].value = 100
		card["mastery_bar"].tooltip_text = "已满级 · 累计开盒 %d 次" % count
	else:
		var previous: int = 0 if level == 0 else PROFICIENCY_THRESHOLDS[level - 1]
		var target: int = PROFICIENCY_THRESHOLDS[level]
		card["mastery_bar"].value = float(count - previous) / float(target - previous) * 100.0
		card["mastery_bar"].tooltip_text = "%d / %d 次，升级还需 %d 次" % [count, target, target - count]

func update_proficiency_level(series_index: int) -> void:
	var old_level: int = series_levels[series_index]
	var new_level := 0
	for threshold in PROFICIENCY_THRESHOLDS:
		if series_open_counts[series_index] >= threshold: new_level += 1
	series_levels[series_index] = min(new_level, 5)
	if series_levels[series_index] > old_level:
		toast("%s 熟练度升至 Lv.%d，系列藏品售价提高！" % [SERIES[series_index]["name"], series_levels[series_index]])

func update_parcel_proficiency() -> void:
	var old_level := parcel_level
	var new_level := 0
	for threshold in PARCEL_PROFICIENCY_THRESHOLDS:
		if parcel_open_count >= threshold: new_level += 1
	parcel_level = min(new_level, 5)
	if parcel_level > old_level:
		toast("快递拆箱熟练度升至 Lv.%d，空盒回收收益提高！" % parcel_level)

func refresh_parcel_mastery() -> void:
	parcel_card_data["mastery_label"].text = "拆箱熟练 Lv.%d/5 · 回收 +%d%%" % [parcel_level, int(parcel_level * PROFICIENCY_PRICE_BONUS * 100.0)]
	if parcel_level >= 5:
		parcel_card_data["mastery_bar"].value = 100
		parcel_card_data["mastery_bar"].tooltip_text = "已满级 · 累计拆箱 %d 次" % parcel_open_count
	else:
		var previous: int = 0 if parcel_level == 0 else PARCEL_PROFICIENCY_THRESHOLDS[parcel_level - 1]
		var target: int = PARCEL_PROFICIENCY_THRESHOLDS[parcel_level]
		parcel_card_data["mastery_bar"].value = float(parcel_open_count - previous) / float(target - previous) * 100.0
		parcel_card_data["mastery_bar"].tooltip_text = "%d / %d 次，升级还需 %d 次" % [parcel_open_count, target, target - parcel_open_count]

func refresh_inventory() -> void:
	clear_children(inventory_list)
	var unopened_count := 0
	for box in boxes:
		if is_instance_valid(box) and box.box_kind == "blind" and not box.opened: unopened_count += 1
	inventory_list.add_child(make_label("桌面未拆盲盒  %d" % unopened_count, 15, Color("#b7c5d0"), true))
	inventory_list.add_child(make_label("藏品  %d" % collectibles.size(), 17, Color("#f2dfbf"), true))
	if collectibles.is_empty(): inventory_list.add_child(make_label("拆开盲盒并选择保留后，藏品会进入这里。", 13, Color("#7f8c98")))
	for i in collectibles.size():
		var item := collectibles[i]
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", style(Color("#242d35"), 8, RARITY_COLORS[item["rarity"]]))
		inventory_list.add_child(row)
		var h := HBoxContainer.new()
		row.add_child(h)
		var label := make_label("%s · %s\n¥%s" % [RARITIES[item["rarity"]], item["name"], comma(collectible_price(item["series"], item["rarity"]))], 13, RARITY_COLORS[item["rarity"]], true)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(label)
		var sell := button("出售", Color("#8a5e41"))
		sell.pressed.connect(sell_collectible.bind(i))
		h.add_child(sell)

func refresh_collection() -> void:
	clear_children(collection_grid)
	for s in SERIES.size():
		for r in 5:
			var found := discovered.has("%d_%d" % [s,r])
			var card := PanelContainer.new()
			card.custom_minimum_size = Vector2(105,86)
			card.add_theme_stylebox_override("panel", style(Color("#232b33"), 7, RARITY_COLORS[r] if found else Color("#46515b")))
			collection_grid.add_child(card)
			var text := "%s\n%s" % [RARITIES[r], SERIES[s]["items"][r]] if found else "%s\n???" % RARITIES[r]
			var label := make_label(text, 12, RARITY_COLORS[r] if found else Color("#66717b"), found)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(label)

func toggle_inventory() -> void:
	inventory_panel.visible = not inventory_panel.visible
	collection_panel.visible = false
	market_panel.visible = false
	refresh_inventory()

func toggle_collection() -> void:
	collection_panel.visible = not collection_panel.visible
	inventory_panel.visible = false
	market_panel.visible = false
	refresh_collection()

func toggle_market() -> void:
	market_panel.visible = not market_panel.visible
	inventory_panel.visible = false
	collection_panel.visible = false
	if market_panel.visible: show_market_overview()

func ray_hit(mouse_pos: Vector2, areas: bool) -> Dictionary:
	var origin := camera.project_ray_origin(mouse_pos)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(mouse_pos) * 30.0)
	query.collide_with_areas = areas
	query.collide_with_bodies = true
	return get_world_3d().direct_space_state.intersect_ray(query)

func box_from_collider(collider: Object) -> RigidBody3D:
	if collider is RigidBody3D and collider.has_method("tear_seal"): return collider
	if collider is Area3D and collider.get_parent() is RigidBody3D: return collider.get_parent()
	return null

func series_unlocked(index: int) -> bool:
	return index == 0 or earned >= int(SERIES[index]["unlock"])

func box_price(index: int) -> int:
	return max(1, int(round(SERIES[index]["base"] * FACTORS[(day - 1) % FACTORS.size()][index])))

func collectible_price(series_index: int, rarity: int) -> int:
	var mastery_multiplier: float = 1.0 + series_levels[series_index] * PROFICIENCY_PRICE_BONUS
	return max(1, int(round(market_price_at_day(series_index, rarity, day) * mastery_multiplier)))

func market_price_at_day(series_index: int, rarity: int, date_index: int) -> int:
	var market: float = FACTORS[(date_index - 1) % FACTORS.size()][series_index]
	var factor: float = 1.0 + (market - 1.0) * (1.0 + rarity * 0.16)
	return max(1, int(round(SERIES[series_index]["values"][rarity] * factor)))

func total_inventory_value() -> int:
	var value := 0
	for box in boxes:
		if is_instance_valid(box) and box.box_kind == "blind" and not box.opened: value += int(round(box_price(box.series_index) * 0.9))
	for item in collectibles: value += collectible_price(item["series"], item["rarity"])
	return value

func roll_rarity(series_index: int) -> int:
	var roll := rng.randi_range(1,10000)
	var total := 0
	var weights := weights_for_series(series_index)
	for i in weights.size():
		total += weights[i]
		if roll <= total: return i
	return 4

func weights_for_series(series_index: int) -> Array[int]:
	var progress := float(min(global_luck_level, SERIES_LUCK_MAX[series_index])) / float(SERIES_LUCK_MAX[series_index])
	var weights: Array[int] = []
	var used := 0
	for i in 4:
		var weight := int(round(lerp(float(BASE_LUCK_WEIGHTS[i]), float(TARGET_LUCK_WEIGHTS[i]), progress)))
		weights.append(weight)
		used += weight
	weights.append(10000 - used)
	return weights

func probability_summary(series_index: int) -> String:
	var weights := weights_for_series(series_index)
	var parts: Array[String] = []
	for weight in weights:
		var percent := float(weight) / 100.0
		parts.append("%.1f%%" % percent if int(weight) % 100 != 0 else "%d%%" % int(percent))
	return " / ".join(parts)

func rarity_probability_text(series_index: int, rarity: int) -> String:
	var weight: int = weights_for_series(series_index)[rarity]
	var percent := float(weight) / 100.0
	return "%.1f%%" % percent if weight % 100 != 0 else "%d%%" % int(percent)

func toast(text_value: String) -> void: toast_label.text = text_value

func make_shop_card(title_text: String, detail_text: String, color: Color) -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style(Color("#202831"), 9, color.darkened(0.2), 2))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	panel.add_child(col)
	col.add_child(make_label(title_text, 14, color.lightened(0.2), true))
	var detail := make_label(detail_text, 11, Color("#9ba8b3"))
	col.add_child(detail)
	var buy := button("购买", color.darkened(0.28))
	buy.custom_minimum_size.y = 28
	col.add_child(buy)
	return {"panel":panel,"detail":detail,"button":buy,"column":col}

func stat_label(title_text: String) -> Label:
	var label := make_label(title_text, 15, Color("#f5f0e7"), true)
	label.custom_minimum_size.y = 36
	return label

func make_label(text_value: String, font_size := 14, color := Color.WHITE, bold := false) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.55))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func button(text_value: String, color: Color) -> Button:
	var result := Button.new()
	result.text = text_value
	result.custom_minimum_size.y = 38
	result.add_theme_font_size_override("font_size", 14)
	result.add_theme_stylebox_override("normal", style(color, 7, color.lightened(0.12)))
	result.add_theme_stylebox_override("hover", style(color.lightened(0.1), 7, color.lightened(0.3), 2))
	result.add_theme_stylebox_override("pressed", style(color.darkened(0.12), 7, color.lightened(0.18)))
	result.add_theme_stylebox_override("disabled", style(Color("#30373e"), 7, Color("#424b54")))
	return result

func style(color: Color, radius := 8, border := Color.TRANSPARENT, width := 1) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.corner_radius_top_left = radius
	result.corner_radius_top_right = radius
	result.corner_radius_bottom_left = radius
	result.corner_radius_bottom_right = radius
	result.border_width_left = width
	result.border_width_top = width
	result.border_width_right = width
	result.border_width_bottom = width
	result.border_color = border
	result.content_margin_left = 10
	result.content_margin_right = 10
	result.content_margin_top = 7
	result.content_margin_bottom = 7
	return result

func line() -> HSeparator:
	var result := HSeparator.new()
	result.modulate = Color("#58636d")
	return result

func clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func comma(value: int) -> String:
	var raw := str(value)
	var result := ""
	for i in raw.length():
		if i > 0 and (raw.length() - i) % 3 == 0: result += ","
		result += raw[i]
	return result
