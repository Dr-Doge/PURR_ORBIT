extends Node3D

const BOX_SCENE := preload("res://scenes/entities/physical_box.tscn")
const PRICE_CHART_SCENE := preload("res://scripts/ui/price_chart.gd")
const RARITIES := ["常见", "少见", "稀有", "史诗", "传说", "隐藏"]
const LUCK_RARITY_MULTIPLIERS := [0.22, 0.55, 1.25, 2.2, 4.2, 5.5]
const SERIES_LUCK_MAX := [5, 10, 15, 20, 25]
const PROFICIENCY_THRESHOLDS := [5, 15, 30, 50, 80]
const PARCEL_PROFICIENCY_THRESHOLDS := [10, 30, 60, 100, 150]
const PROFICIENCY_PRICE_BONUS := 0.12
const PARCEL_SEAL_DRAG_FORCE := 620.0
const SERIES_SEAL_DRAG_FORCE := [430.0, 600.0, 760.0, 960.0, 1220.0]
const PARCEL_DETACH_NODES := [0.24, 0.50, 0.76]
const SERIES_DETACH_NODES := [
	[0.18, 0.39, 0.61, 0.82],
	[0.15, 0.32, 0.50, 0.68, 0.85],
	[0.13, 0.28, 0.43, 0.57, 0.72, 0.87],
	[0.11, 0.24, 0.37, 0.50, 0.63, 0.76, 0.89],
	[0.10, 0.21, 0.33, 0.44, 0.56, 0.67, 0.79, 0.90]
]
const PARCEL_DETACH_CHANCE := 0.58
const SERIES_DETACH_CHANCES := [0.34, 0.43, 0.52, 0.61, 0.70]
const TEAR_MIN_DETACH_MULTIPLIER := 0.18
const TEAR_MIN_FORCE_MULTIPLIER := 0.50
const REVEAL_EFFECT_COLORS := [Color("#f2f4f7"), Color("#65e582"), Color("#4e9cff"), Color("#a568ff"), Color("#ffc34d"), Color.WHITE]
const GLOBAL_LUCK_COSTS := [50,100,1000,5000,10000,25000,50000,100000,250000,500000,1000000,2500000,5000000,10000000,25000000,50000000,100000000,250000000,500000000,1000000000,2500000000,5000000000,10000000000,25000000000,50000000000]
const SHAKE_UPGRADE_COSTS := [100, 1000, 10000, 100000, 1000000]
const SERIES_SHAKE_TRAVEL := [420.0, 520.0, 650.0, 800.0, 980.0]
const SERIES_SHAKE_REVERSALS := [6, 8, 10, 12, 14]
const TEAR_SKILL_UPGRADE_COSTS := [50,100,1000,5000,10000,25000,50000,100000,250000,500000,1000000,2500000,5000000,10000000,25000000,50000000,100000000,250000000,500000000,1000000000,2500000000,5000000000,10000000000,25000000000,50000000000]
const RARITY_COLORS := [Color("#d9e0df"), Color("#65d77d"), Color("#62a8ff"), Color("#b989ff"), Color("#ffb347"), Color("#ff76d8")]
const SERIES := [
	{"name":"桌角伙伴", "slogan":"小小桌角，也有大大的陪伴。", "base":10, "unlock":0, "color":Color("#59c7b5"), "items":["线团猫","吐司钟","云朵夹","桌面之王"], "rarities":[0,1,2,3], "weights":[3800,4200,1500,500], "values":[5,15,45,130]},
	{"name":"LADUDU 精灵怪", "slogan":"坏笑、打盹和恶作剧，都藏在这一盒。", "base":100, "unlock":100, "color":Color("#8d66c7"), "items":["傻笑 LADUDU","打盹 LADUDU","哭哭 LADUDU","金牙 LADUDU","国王 LADUDU"], "rarities":[0,1,2,3,5], "weights":[5000,3000,1100,810,90], "values":[50,100,1000,3000,10000]},
	{"name":"夜班小队", "slogan":"今晚不打烊，惊喜正在值班。", "base":1000, "unlock":1000, "color":Color("#526cb7"), "items":["咖啡骑士","灯泡幽灵","键盘鼹鼠","打卡树懒","午夜主管","永夜董事"], "rarities":[0,0,1,2,3,5], "weights":[2500,2500,3000,1100,810,90], "values":[500,500,1000,10000,30000,100000]},
	{"name":"泪包宝贝", "slogan":"把今天的小情绪，装进柔软的眼泪里。", "base":10000, "unlock":10000, "color":Color("#dc759b"), "items":["素面泪包","墨镜泪包","甜梦泪包","委屈泪包","暴雨泪包","天使泪包·左翼","天使泪包·右翼"], "rarities":[0,0,1,2,3,5,5], "weights":[2500,2500,3000,1000,820,90,90], "values":[5000,5000,10000,100000,500000,100000,100000]},
	{"name":"星港机修铺", "slogan":"穿过星港，把失落核心带回家。", "base":100000, "unlock":100000, "color":Color("#dd7048"), "items":["扳手机器人","货运水母","信标犬","油渍章鱼","零号领航员","机库技师","星港机神·头部","星港机神·躯干","星港机神·腿部"], "rarities":[0,0,1,1,2,3,5,5,5], "weights":[2500,2500,1500,1500,1000,800,67,67,66], "values":[50000,50000,100000,100000,1000000,5000000,1000000,1000000,1000000]}
]
const NEWS := ["桌角萌物进入热榜，入门盒价格温和上涨。","LADUDU 精灵怪引发恶作剧收藏热。","夜班小队开放夜间试销。","泪包宝贝情绪主题成交活跃。","神秘买家寻找隐藏级藏品。","星港机修铺抵达本地。","收藏节成交活跃，市场进入新周期。"]
const FACTORS := [[1.10,1.00,1.00,1.00,1.00],[1.18,1.04,1.00,1.00,1.00],[0.92,1.08,1.05,1.00,1.00],[0.86,1.15,1.12,1.04,1.00],[1.02,1.32,1.18,1.10,1.04],[1.12,1.08,1.25,1.18,1.10],[1.26,1.18,1.35,1.28,1.35]]

@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var items_root: Node3D = $Items
@onready var wall_ticker: Label3D = $Room/MarketTicker/TickerLabel
@onready var wall_ticker_b: Label3D = $Room/MarketTicker/TickerLabelB
@onready var secondhand_bin: Node3D = $SecondhandBin

var rng := RandomNumberGenerator.new()
var day := 1
var cash: int = 3
var earned: int = 0
var collectibles: Array[Dictionary] = []
var discovered: Dictionary = {}
var boxes: Array[Node] = []
var global_luck_level := 0
var shake_upgrade_level := 0
var tear_skill_level := 0
var series_open_counts := [0, 0, 0, 0, 0]
var series_levels := [0, 0, 0, 0, 0]
var parcel_open_count := 0
var parcel_level := 0
var focused_box: RigidBody3D
var focus_origin := Transform3D.IDENTITY
var pointer_mode := ""
var pointer_start := Vector2.ZERO
var table_drag_box: RigidBody3D
var click_candidate: RigidBody3D
var table_drag_moved := false
var shake_axis := 0
var shake_distance := 0.0
var shake_reversals := 0
var shake_last_direction := 0
var shake_result_triggered := false
var shake_base_position := Vector3.ZERO
var shake_base_rotation := Vector3.ZERO
var review_item: Node3D
var review_glow: Node3D
var pending_item: Dictionary = {}

var money_label: Label
var value_label: Label
var date_label: Label
var player_level_label: Label
var player_level_bar: ProgressBar
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
var luck_button: Button
var shake_level_label: Label
var shake_button: Button
var tear_skill_level_label: Label
var tear_skill_button: Button
var shake_audio: AudioStreamPlayer
var shake_return_tween: Tween
var seal_drag_last_position := Vector2.ZERO
var focus_camera_attributes: CameraAttributesPractical
var ui_canvas: CanvasLayer
var ticker_source := ""
var ticker_scroll_x := 0.0
var opening_sequence := false
var review_animation_playing := false

func _ready() -> void:
	rng.randomize()
	focus_camera_attributes = CameraAttributesPractical.new()
	camera.attributes = focus_camera_attributes
	set_focus_depth_of_field(false)
	shake_audio = AudioStreamPlayer.new()
	add_child(shake_audio)
	build_ui()
	refresh_ui()
	toast("点击盲盒查看并摇盒；拖动未拆盲盒到桌面右上角的忙鱼回收盒可按市价八折出售。")

func _process(delta: float) -> void:
	if ticker_source.is_empty(): return
	ticker_scroll_x -= delta * 0.82
	if ticker_scroll_x <= -6.4: ticker_scroll_x += 6.4
	wall_ticker.position.x = ticker_scroll_x
	wall_ticker_b.position.x = ticker_scroll_x + 6.4

func _physics_process(_delta: float) -> void:
	for box in boxes.duplicate():
		if not is_instance_valid(box): continue
		if box.global_position.y < -3.0 and not box.opened:
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
	left_hud.size = Vector2(182, 188)
	left_hud.add_theme_stylebox_override("panel", style(Color(0.055,0.07,0.085,0.95), 15, Color("#42505d"), 2))
	canvas.add_child(left_hud)
	var hud_column := VBoxContainer.new()
	hud_column.add_theme_constant_override("separation", 5)
	left_hud.add_child(hud_column)
	var asset_row := HBoxContainer.new()
	asset_row.add_theme_constant_override("separation", 5)
	hud_column.add_child(asset_row)
	money_label = stat_label("现金")
	money_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	money_label.add_theme_font_size_override("font_size", 12)
	asset_row.add_child(money_label)
	value_label = stat_label("库存总价值")
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.add_theme_font_size_override("font_size", 12)
	asset_row.add_child(value_label)
	date_label = stat_label("日期")
	hud_column.add_child(date_label)
	var level_block := VBoxContainer.new()
	level_block.add_theme_constant_override("separation", 2)
	hud_column.add_child(level_block)
	player_level_label = make_label("等级", 11, Color("#a8d8ff"), true)
	level_block.add_child(player_level_label)
	player_level_bar = ProgressBar.new()
	player_level_bar.custom_minimum_size.y = 10
	player_level_bar.max_value = 100
	player_level_bar.show_percentage = false
	level_block.add_child(player_level_bar)
	var end_day := button("结束今天", Color("#a45d43"))
	end_day.pressed.connect(end_day_pressed)
	hud_column.add_child(end_day)

	var left_shop := PanelContainer.new()
	left_shop.position = Vector2(18, 216)
	left_shop.size = Vector2(182, 486)
	left_shop.add_theme_stylebox_override("panel", style(Color(0.055,0.07,0.085,0.93), 15, Color("#42505d"), 2))
	canvas.add_child(left_shop)
	var left_scroll := ScrollContainer.new()
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	left_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_shop.add_child(left_scroll)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 148
	column.add_theme_constant_override("separation", 5)
	left_scroll.add_child(column)
	var parcel_card := make_shop_card("快递盒", "买入 ¥1 · 压扁即结算 ¥2–3", Color("#a87e55"))
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
		var card := make_shop_card("盲盒 %d · %s" % [i + 1, data["name"]], "按图鉴逐件公开概率", data["color"])
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
	collection_panel = side_panel(canvas, "收藏册  ·  %d 件" % total_collectible_definitions(), 411)
	collection_grid = GridContainer.new()
	collection_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection_grid.columns = 3
	collection_grid.add_theme_constant_override("h_separation", 6)
	collection_grid.add_theme_constant_override("v_separation", 6)
	var collection_scroll := ScrollContainer.new()
	collection_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	collection_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	collection_scroll.add_child(collection_grid)
	collection_panel.get_child(0).add_child(collection_scroll)
	market_panel = build_market_panel(canvas)
	loot_preview_panel = build_loot_preview_panel(canvas)

func build_upgrade_panel(canvas: CanvasLayer) -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(1080, 74)
	panel.size = Vector2(182, 330)
	panel.add_theme_stylebox_override("panel", style(Color(0.055,0.07,0.085,0.94), 11, Color("#a98143"), 2))
	canvas.add_child(panel)
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = 148
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)
	col.add_child(make_label("升级1 · 整体幸运", 13, Color("#ffd27c"), true))
	luck_level_label = make_label("", 11, Color("#e9edf1"), true)
	col.add_child(luck_level_label)
	luck_button = button("整体升级", Color("#8b6a32"))
	luck_button.custom_minimum_size.y = 32
	luck_button.add_theme_font_size_override("font_size", 11)
	luck_button.pressed.connect(upgrade_luck)
	col.add_child(luck_button)
	col.add_child(line())
	col.add_child(make_label("升级2 · 摇盒次数", 13, Color("#88d9ef"), true))
	shake_level_label = make_label("", 11, Color("#c6e8f0"))
	col.add_child(shake_level_label)
	shake_button = button("升级摇盒次数", Color("#39758a"))
	shake_button.custom_minimum_size.y = 32
	shake_button.add_theme_font_size_override("font_size", 11)
	shake_button.pressed.connect(upgrade_shake)
	col.add_child(shake_button)
	col.add_child(line())
	col.add_child(make_label("升级3 · 撕封技巧", 13, Color("#f0aaa0"), true))
	tear_skill_level_label = make_label("", 11, Color("#efd0cb"))
	col.add_child(tear_skill_level_label)
	tear_skill_button = button("练习撕封技巧", Color("#8c5149"))
	tear_skill_button.custom_minimum_size.y = 32
	tear_skill_button.add_theme_font_size_override("font_size", 11)
	tear_skill_button.pressed.connect(upgrade_tear_skill)
	col.add_child(tear_skill_button)

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
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 7)
		col.add_child(grid)
		for item_index in SERIES[s]["items"].size():
			var rarity: int = SERIES[s]["rarities"][item_index]
			var item_button := button("%s\n%s" % [RARITIES[rarity], SERIES[s]["items"][item_index]], RARITY_COLORS[rarity].darkened(0.48))
			item_button.custom_minimum_size = Vector2(145, 62)
			item_button.tooltip_text = "点击查看价格曲线"
			item_button.pressed.connect(show_price_chart.bind(s, item_index))
			grid.add_child(item_button)

func show_price_chart(series_index: int, item_index: int) -> void:
	clear_children(market_content)
	var back := button("← 返回系列陈列", Color("#4d5b68"))
	back.pressed.connect(show_market_overview)
	market_content.add_child(back)
	var rarity: int = SERIES[series_index]["rarities"][item_index]
	var item_name: String = SERIES[series_index]["items"][item_index]
	market_content.add_child(make_label("%s · %s · %s" % [SERIES[series_index]["name"], RARITIES[rarity], item_name], 22, RARITY_COLORS[rarity], true))
	var current_market := market_price_at_day(series_index, item_index, day)
	market_content.add_child(make_label("第 %d 天市场价：¥%s  ·  熟练度后的实际售价：¥%s" % [day, comma(current_market), comma(collectible_price(series_index, item_index))], 14, Color("#d6dde3")))
	var prices: Array[float] = []
	var dates: Array[int] = []
	for date_index in range(1, day + 1):
		prices.append(float(market_price_at_day(series_index, item_index, date_index)))
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
	var preview_scroll := ScrollContainer.new()
	preview_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(preview_scroll)
	loot_preview_list = VBoxContainer.new()
	loot_preview_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loot_preview_list.add_theme_constant_override("separation", 5)
	preview_scroll.add_child(loot_preview_list)
	return panel

func populate_loot_preview(series_index: int, inspected_box: RigidBody3D = null) -> void:
	clear_children(loot_preview_list)
	loot_preview_list.add_child(make_label(SERIES[series_index]["name"], 22, SERIES[series_index]["color"], true))
	var slogan := make_label(SERIES[series_index]["slogan"], 13, Color("#d8c9ae"))
	slogan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loot_preview_list.add_child(slogan)
	if inspected_box:
		var allowed := shake_limit_for_box(inspected_box)
		var shake_info := make_label("摇盒机会 %d / %d  ·  每次排除一个错误候选" % [inspected_box.shake_count, allowed], 12, Color("#8fdcef"), true)
		shake_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		loot_preview_list.add_child(shake_info)
	loot_preview_list.add_child(line())
	for item_index in SERIES[series_index]["items"].size():
		var rarity: int = SERIES[series_index]["rarities"][item_index]
		var eliminated: bool = inspected_box != null and item_index in inspected_box.shake_eliminated
		var row := PanelContainer.new()
		row.custom_minimum_size.y = 58
		row.add_theme_stylebox_override("panel", style(Color("#301e22") if eliminated else Color("#202832"), 7, Color("#b9575f") if eliminated else RARITY_COLORS[rarity]))
		loot_preview_list.add_child(row)
		var hbox := HBoxContainer.new()
		row.add_child(hbox)
		var prefix := "✕  已排除 · " if eliminated else ""
		var item_label := make_label("%s%s · %s\n概率 %s  ·  市价 ¥%s" % [prefix, RARITIES[rarity], SERIES[series_index]["items"][item_index], item_probability_text(series_index, item_index), comma(collectible_price(series_index, item_index))], 12, Color("#d46a72") if eliminated else RARITY_COLORS[rarity], true)
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(item_label)

func spawn_box(kind: String, series_index: int, item_index: int, paid: int, slot := 0) -> void:
	var box: RigidBody3D = BOX_SCENE.instantiate()
	items_root.add_child(box)
	var rarity := -1 if series_index < 0 else int(SERIES[series_index]["rarities"][item_index])
	box.setup(kind, series_index, rarity, paid, SERIES[series_index]["color"] if series_index >= 0 else Color("#b18458"), item_index)
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
	toast("快递盒落到了桌面。拆开上下盖并压扁后，将立即结算 ¥2–3。")
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
	toast("整体幸运升级至第 %d 阶；五个系列以不同速度获得概率提升。" % global_luck_level)
	refresh_ui()

func upgrade_shake() -> void:
	if shake_upgrade_level >= SHAKE_UPGRADE_COSTS.size():
		toast("摇盒次数已经升至满级。")
		return
	var cost: int = SHAKE_UPGRADE_COSTS[shake_upgrade_level]
	if cash < cost:
		toast("升级摇盒次数还需要 ¥%s。" % comma(cost - cash))
		return
	cash -= cost
	shake_upgrade_level += 1
	toast("摇盒升级完成：每只盲盒最多可摇 %d 次。" % (shake_upgrade_level + 1))
	refresh_ui()

func upgrade_tear_skill() -> void:
	if tear_skill_level >= TEAR_SKILL_UPGRADE_COSTS.size():
		toast("撕封技巧已经升至满级。")
		return
	var cost: int = TEAR_SKILL_UPGRADE_COSTS[tear_skill_level]
	if cash < cost:
		toast("练习撕封技巧还需要 ¥%s。" % comma(cost - cash))
		return
	cash -= cost
	tear_skill_level += 1
	toast("撕封技巧升至 %d 级；各系列按 5/10/15/20/25 级速度降低脱手概率。" % tear_skill_level)
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
	spawn_box("blind", series_index, roll_content(series_index), price, rng.randi_range(0, 2))
	toast("购买成功。点击盲盒可摇盒判断；拖进忙鱼桶可按今日市价八折止损。")
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
	if review_item:
		if review_animation_playing: return
		pointer_mode = "review_rotate"
		return
	if focused_box:
		if opening_sequence or focused_box.seal_removed:
			return
		var near_seal := is_near_seal_anchor(mouse_pos)
		if not near_seal and not pointer_hits_focused_box(mouse_pos):
			exit_focus()
			toast("盲盒已放回桌面；当前撕封进度会保留，也可以拖去忙鱼回收。")
			return
		if near_seal:
			begin_seal_drag(mouse_pos)
		elif focused_box.box_kind == "blind" and focused_box.seal_progress <= 0.001:
			if focused_box.shake_count >= shake_limit_for_box(focused_box):
				toast("摇盒机会已用完。请点击黄色封条的一端开始撕封。")
				return
			begin_shake_gesture()
		else:
			toast("请重新按住黄色封条掀起的一端，沿当前纹路继续拖动。")
		return
	var hit := ray_hit(mouse_pos, false)
	var box := box_from_collider(hit.collider if hit else null)
	if box:
		click_candidate = box
		if box.opened or box.box_kind == "blind":
			table_drag_box = box
			table_drag_box.freeze = true
			table_drag_moved = false
			pointer_mode = "table_drag"

func on_pointer_move(event: InputEventMouseMotion) -> void:
	if pointer_mode == "review_rotate" and review_item:
		review_item.rotate_y(event.relative.x * 0.012)
		review_item.rotate_object_local(Vector3.RIGHT, event.relative.y * 0.012)
	elif pointer_mode == "seal_drag" and focused_box:
		update_seal_drag(event)
	elif pointer_mode == "shake" and focused_box:
		update_shake_gesture(event)
	elif pointer_mode == "table_drag" and table_drag_box:
		if event.position.distance_to(pointer_start) < 12.0:
			return
		table_drag_moved = true
		var origin := camera.project_ray_origin(event.position)
		var direction := camera.project_ray_normal(event.position)
		var point: Variant = Plane(Vector3.UP, 0.85).intersects_ray(origin, direction)
		if point != null: table_drag_box.global_position = point

func on_pointer_up(mouse_pos: Vector2) -> void:
	if pointer_mode == "seal_drag":
		pointer_mode = ""
		if focused_box and not opening_sequence:
			update_seal_progress_hud(focused_box)
			toast("已经松开封条；从掀起的一端重新按住即可继续。")
		return
	if pointer_mode == "seal_detached":
		pointer_mode = ""
		return
	if pointer_mode == "shake" or pointer_mode == "shake_complete":
		finish_shake_gesture()
		pointer_mode = ""
		return
	if pointer_mode == "table_drag" and table_drag_box:
		if not table_drag_moved and not table_drag_box.opened and mouse_pos.distance_to(pointer_start) < 12.0:
			var box_to_focus := table_drag_box
			table_drag_box = null
			click_candidate = null
			pointer_mode = ""
			focus_box(box_to_focus)
			return
		if not table_drag_box.opened and table_drag_box.box_kind == "blind" and is_over_secondhand_bin(table_drag_box.global_position):
			var box_to_sell := table_drag_box
			table_drag_box = null
			click_candidate = null
			pointer_mode = ""
			sell_box_secondhand(box_to_sell)
			return
		table_drag_box.freeze = false
		table_drag_box.sleeping = false
		table_drag_box.linear_velocity.y = -0.45
		table_drag_box.apply_central_impulse(Vector3(0, -0.15, 0))
		table_drag_box = null
	elif click_candidate and not click_candidate.opened and mouse_pos.distance_to(pointer_start) < 12.0:
		focus_box(click_candidate)
	click_candidate = null
	pointer_mode = ""

func is_near_seal_anchor(mouse_pos: Vector2) -> bool:
	if not focused_box or not focused_box.has_method("active_seal_anchor_global"): return false
	var anchor_screen := camera.unproject_position(focused_box.active_seal_anchor_global())
	return mouse_pos.distance_to(anchor_screen) <= 72.0

func pointer_hits_focused_box(mouse_pos: Vector2) -> bool:
	if not focused_box: return false
	var hit := ray_hit(mouse_pos, false)
	return box_from_collider(hit.collider if hit else null) == focused_box

func begin_seal_drag(mouse_pos: Vector2) -> void:
	if not focused_box: return
	if focused_box.seal_detach_points.is_empty() and focused_box.seal_detach_index == 0:
		configure_seal_detaches(focused_box)
	pointer_mode = "seal_drag"
	seal_drag_last_position = mouse_pos
	detail_hint.text = "按住并沿%s拖动；脱手后重新点击掀起端" % seal_pattern_name(focused_box)
	toast("抓住封条了。沿黄色纹路持续搓动。")

func configure_seal_detaches(box: RigidBody3D) -> void:
	box.seal_detach_points.clear()
	box.seal_detach_index = 0
	var nodes: Array = PARCEL_DETACH_NODES if box.box_kind == "parcel" else SERIES_DETACH_NODES[box.series_index]
	for threshold in nodes:
		box.seal_detach_points.append(float(threshold))

func tear_skill_progress_for_box(box: RigidBody3D) -> float:
	var required_level: int = 5 if box.box_kind == "parcel" else SERIES_LUCK_MAX[box.series_index]
	return float(mini(tear_skill_level, required_level)) / float(required_level)

func seal_detach_probability(box: RigidBody3D) -> float:
	var base_chance: float = PARCEL_DETACH_CHANCE if box.box_kind == "parcel" else SERIES_DETACH_CHANCES[box.series_index]
	return base_chance * lerpf(1.0, TEAR_MIN_DETACH_MULTIPLIER, tear_skill_progress_for_box(box))

func seal_drag_force(box: RigidBody3D) -> float:
	var base_force: float = PARCEL_SEAL_DRAG_FORCE if box.box_kind == "parcel" else SERIES_SEAL_DRAG_FORCE[box.series_index]
	return base_force * lerpf(1.0, TEAR_MIN_FORCE_MULTIPLIER, tear_skill_progress_for_box(box))

func seal_pattern_name(box: RigidBody3D) -> String:
	if box.box_kind == "parcel": return "中央直条"
	return ["横向直条", "折线锯齿", "纵向拉链", "往复针脚", "角形螺旋"][box.series_index]

func update_seal_drag(event: InputEventMouseMotion) -> void:
	if not focused_box or pointer_mode != "seal_drag": return
	var anchor_screen := camera.unproject_position(focused_box.active_seal_anchor_global())
	var next_screen := camera.unproject_position(focused_box.next_seal_anchor_global())
	var expected := (next_screen - anchor_screen).normalized()
	var motion := event.position - seal_drag_last_position
	seal_drag_last_position = event.position
	if motion.length() < 0.4 or expected.length() < 0.1: return
	# Only motion following the current printed segment contributes. At every
	# corner the expected vector rotates, creating genuinely different traces.
	var aligned_motion := motion.dot(expected)
	if aligned_motion <= 0.0: return
	if event.position.distance_to(anchor_screen) > 260.0:
		force_seal_detach("拖动偏离纹路，封条脱手了。")
		return
	var next_progress: float = focused_box.seal_progress + aligned_motion / seal_drag_force(focused_box)
	focused_box.set_seal_progress(next_progress)
	update_seal_progress_hud(focused_box)
	while focused_box.seal_detach_index < focused_box.seal_detach_points.size() and focused_box.seal_progress >= focused_box.seal_detach_points[focused_box.seal_detach_index]:
		focused_box.seal_detach_index += 1
		if rng.randf() < seal_detach_probability(focused_box):
			force_seal_detach("判定节点触发脱手！重新按住已经掀起的黄色端点。")
			return
	if focused_box.seal_progress >= 0.999:
		pointer_mode = "seal_detached"
		opening_sequence = true
		complete_drag_opening()

func force_seal_detach(message: String) -> void:
	pointer_mode = "seal_detached"
	if focused_box:
		update_seal_progress_hud(focused_box)
	toast(message)

func begin_shake_gesture() -> void:
	if not focused_box: return
	pointer_mode = "shake"
	shake_axis = -1
	shake_distance = 0.0
	shake_reversals = 0
	shake_last_direction = 0
	shake_result_triggered = false
	shake_base_position = focused_box.global_position
	shake_base_rotation = focused_box.rotation
	detail_hint.text = "按住左键，横向或纵向来回摇动……"

func update_shake_gesture(event: InputEventMouseMotion) -> void:
	if not focused_box or pointer_mode != "shake": return
	var total_motion := event.position - pointer_start
	if shake_axis < 0 and total_motion.length() >= 12.0:
		shake_axis = 0 if absf(total_motion.x) >= absf(total_motion.y) else 1
	if shake_axis < 0: return
	var component: float = event.relative.x if shake_axis == 0 else event.relative.y
	if absf(component) < 0.8: return
	var direction := 1 if component > 0.0 else -1
	if shake_last_direction != 0 and direction != shake_last_direction:
		shake_reversals += 1
	shake_last_direction = direction
	shake_distance += absf(component)
	# The box follows the held cursor directly. Horizontal and vertical strokes
	# therefore feel physical rather than playing a canned wobble animation.
	var limited_motion := total_motion.limit_length(220.0)
	focused_box.global_position = shake_base_position + camera.global_basis.x * limited_motion.x * 0.004 - camera.global_basis.y * limited_motion.y * 0.004
	focused_box.rotation = shake_base_rotation + Vector3(-limited_motion.y * 0.0018, limited_motion.x * 0.0011, limited_motion.x * 0.0018)
	if not shake_result_triggered and shake_distance >= SERIES_SHAKE_TRAVEL[focused_box.series_index] and shake_reversals >= SERIES_SHAKE_REVERSALS[focused_box.series_index]:
		perform_box_shake()

func perform_box_shake() -> void:
	if not focused_box or pointer_mode != "shake" or shake_result_triggered: return
	shake_result_triggered = true
	var candidates: Array[int] = []
	for item_index in SERIES[focused_box.series_index]["items"].size():
		if item_index != focused_box.item_index and item_index not in focused_box.shake_eliminated:
			candidates.append(item_index)
	if candidates.is_empty():
		toast("其余错误候选已经全部排除。")
		return
	var eliminated_index: int = candidates[rng.randi_range(0, candidates.size() - 1)]
	focused_box.shake_eliminated.append(eliminated_index)
	focused_box.shake_count += 1
	play_shake_sound(focused_box)
	populate_loot_preview(focused_box.series_index, focused_box)
	update_seal_progress_hud(focused_box)
	toast("听到一次明确的盒内碰撞声；右侧已划掉 1 个错误候选。可以继续摇，松手后盒体才会回中。")

func finish_shake_gesture() -> void:
	if not focused_box: return
	if shake_return_tween and shake_return_tween.is_valid():
		shake_return_tween.kill()
	shake_return_tween = create_tween().set_parallel(true)
	shake_return_tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	shake_return_tween.tween_property(focused_box, "global_position", shake_base_position, 0.28)
	shake_return_tween.tween_property(focused_box, "rotation", shake_base_rotation, 0.28)

func shake_limit_for_box(box: RigidBody3D) -> int:
	if not box or box.box_kind != "blind": return 0
	return mini(1 + shake_upgrade_level, SERIES[box.series_index]["items"].size() - 1)

func play_shake_sound(box: RigidBody3D) -> void:
	# The locked content controls resonance, impact count and pitch. Players can
	# learn a series' sound language without the UI revealing the answer.
	var sample_rate := 22050
	var duration := 0.22 + float(box.rarity) * 0.012
	var frame_count := int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	var base_frequency := 145.0 + float((box.item_index * 47 + box.series_index * 29) % 180)
	var impact_count: int = 2 + (box.item_index % 3)
	for frame in frame_count:
		var t := float(frame) / float(sample_rate)
		var value := 0.0
		for impact in impact_count:
			var impact_time := float(impact) * duration / float(impact_count + 1)
			var local_t := t - impact_time
			if local_t >= 0.0:
				var envelope := exp(-local_t * (27.0 - minf(float(box.rarity), 5.0) * 1.4))
				value += sin(TAU * (base_frequency + impact * 31.0) * local_t) * envelope
		value *= 0.24 / float(impact_count)
		bytes.encode_s16(frame * 2, clampi(int(value * 32767.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	shake_audio.stream = stream
	shake_audio.play()

func is_over_secondhand_bin(world_position: Vector3) -> bool:
	var local := secondhand_bin.to_local(world_position)
	return absf(local.x) <= 1.05 and absf(local.z) <= 0.82

func sell_box_secondhand(box: RigidBody3D) -> void:
	if not is_instance_valid(box) or box.opened or box.box_kind != "blind": return
	var payout := maxi(1, int(round(box_price(box.series_index) * 0.8)))
	var sale_position := secondhand_bin.global_position + Vector3(0, 0.7, 0)
	cash += payout
	earned += payout
	boxes.erase(box)
	box.queue_free()
	show_income_popup(payout, sale_position)
	toast("未拆盲盒已卖给忙鱼二手市场，按今日市价八折到账 ¥%s。" % comma(payout))
	refresh_ui()

func focus_box(box: RigidBody3D) -> void:
	if focused_box or box.opened: return
	focused_box = box
	set_focus_depth_of_field(true)
	focus_origin = box.global_transform
	box.freeze = true
	box.linear_velocity = Vector3.ZERO
	box.angular_velocity = Vector3.ZERO
	var target := camera.global_position - camera.global_basis.z * 3.4
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(box, "global_position", target, 0.35)
	# Align the active seal face almost perpendicular to the camera. Parcel
	# boxes add PI after the first face, so the lower face automatically turns in.
	var focus_rotation_x := deg_to_rad(38.0)
	if box.box_kind == "parcel" and box.parcel_seal_side == 1: focus_rotation_x += PI
	tween.tween_property(box, "rotation", Vector3(focus_rotation_x, 0.0, 0.0), 0.35)
	detail_panel.visible = true
	loot_preview_panel.visible = box.box_kind == "blind"
	if box.box_kind == "blind": populate_loot_preview(box.series_index, box)
	detail_title.text = "快递盒" if box.box_kind == "parcel" else SERIES[box.series_index]["name"] + "盲盒"
	detail_title.add_theme_color_override("font_color", Color("#ffd178"))
	if box.seal_detach_points.is_empty() and box.seal_detach_index == 0:
		configure_seal_detaches(box)
	update_seal_progress_hud(box)
	seal_bar.visible = true
	action_row.visible = false
	if box.box_kind == "blind":
		toast("拖动盒体区域可摇盒；点击黄色封条起点并沿纹路拖动即可开盒。")
	else:
		toast("点击双开门中央的黄色封条一端，按住左键沿直条不断搓动。")

func set_focus_depth_of_field(enabled: bool) -> void:
	if not focus_camera_attributes: return
	focus_camera_attributes.dof_blur_far_enabled = enabled
	focus_camera_attributes.dof_blur_far_distance = 4.15
	focus_camera_attributes.dof_blur_far_transition = 1.85
	focus_camera_attributes.dof_blur_near_enabled = false
	focus_camera_attributes.dof_blur_amount = 0.18

func update_seal_progress_hud(box: RigidBody3D) -> void:
	seal_bar.value = box.seal_progress * 100.0
	var side_text := ""
	if box.box_kind == "parcel": side_text = "%s封条 · " % box.active_parcel_side_name()
	var remaining_nodes := maxi(0, box.seal_detach_points.size() - box.seal_detach_index)
	var shake_text := ""
	if box.box_kind == "blind" and box.seal_progress <= 0.001:
		shake_text = "摇盒 %d/%d · " % [box.shake_count, shake_limit_for_box(box)]
	detail_hint.text = "%s%s%s · 撕开 %d%% · 节点 %d · 脱手率 %d%%" % [shake_text, side_text, seal_pattern_name(box), int(round(box.seal_progress * 100.0)), remaining_nodes, int(round(seal_detach_probability(box) * 100.0))]

func complete_drag_opening() -> void:
	if not focused_box: return
	var box := focused_box
	box.tear_seal()
	seal_bar.value = 100.0
	detail_hint.text = "封条完全撕开，盒盖正在弹开……"
	toast("最后一段封条撕开，盒盖立即弹开！")
	if box.box_kind == "blind":
		# Begin the reveal the instant the lid moves, instead of waiting for the
		# lid tween to finish and creating a visible pause.
		box.play_auto_open()
		await get_tree().create_timer(0.035).timeout
		if is_instance_valid(box) and focused_box == box:
			seal_bar.visible = false
			await begin_content_review()
		opening_sequence = false
		return
	await box.play_auto_open()
	if not is_instance_valid(box) or focused_box != box:
		opening_sequence = false
		return
	if box.has_more_parcel_seals():
		configure_seal_detaches(box)
		seal_bar.visible = true
		update_seal_progress_hud(box)
		detail_title.text = "快递盒 · 翻至下面"
		toast("上面的双盖已打开，视角自动翻到下面。重新抓住中央封条。")
		opening_sequence = false
		return
	seal_bar.visible = false
	detail_hint.text = "上下盖均已打开，正在压扁纸箱……"
	toast("两面的盖子都打开了，纸箱正在被压扁。")
	await box.play_flatten_animation()
	finish_parcel_processing()
	opening_sequence = false

func exit_focus() -> void:
	if not focused_box or opening_sequence: return
	var box := focused_box
	if shake_return_tween and shake_return_tween.is_valid():
		shake_return_tween.kill()
	shake_return_tween = null
	set_focus_depth_of_field(false)
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
	var payout := int(round(rng.randi_range(2,3) * (1.0 + parcel_level * PROFICIENCY_PRICE_BONUS)))
	var payout_position: Vector3 = box.global_position
	cash += payout
	earned += payout
	boxes.erase(box)
	focused_box = null
	set_focus_depth_of_field(false)
	detail_panel.visible = false
	loot_preview_panel.visible = false
	seal_bar.visible = false
	box.queue_free()
	show_income_popup(payout, payout_position)
	toast("纸箱压扁完成，立即回收结算 +¥%d。" % payout)
	refresh_ui()

func begin_content_review() -> void:
	if not focused_box or focused_box.box_kind != "blind": return
	var box := focused_box
	var series_index: int = box.series_index
	var rarity: int = box.rarity
	var item_index: int = box.item_index
	var item_name: String = SERIES[series_index]["items"][item_index]
	pending_item = {"series":series_index, "item_index":item_index, "rarity":rarity, "name":item_name}
	series_open_counts[series_index] += 1
	update_proficiency_level(series_index)
	register_discovery(pending_item)
	boxes.erase(box)
	focused_box = null
	loot_preview_panel.visible = false
	box.queue_free()
	review_animation_playing = true
	review_item = Node3D.new()
	add_child(review_item)
	var start_position := camera.global_position - camera.global_basis.z * 3.55
	var impact_position := camera.global_position - camera.global_basis.z * 3.30
	var screen_pop_position := camera.global_position - camera.global_basis.z * 2.18
	review_item.global_transform = Transform3D(camera.global_basis, start_position)
	review_item.scale = Vector3.ONE * 0.18
	review_glow = create_reveal_burst(rarity)
	add_child(review_glow)
	review_glow.global_transform = Transform3D(camera.global_basis, impact_position - camera.global_basis.z * 0.18)
	review_glow.visible = false
	var shape := CSGSphere3D.new()
	shape.radius = 0.44 + rarity * 0.025
	shape.radial_segments = 20
	shape.rings = 10
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#050609")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.metallic = 0.15 + rarity * 0.12
	material.roughness = 0.5
	shape.material = material
	review_item.add_child(shape)
	var accent := CSGTorus3D.new()
	accent.inner_radius = 0.40
	accent.outer_radius = 0.49
	accent.rotation.x = PI / 2.0
	accent.material = material
	review_item.add_child(accent)
	var price := collectible_price(series_index, item_index)
	detail_panel.visible = true
	detail_title.text = "？？？"
	detail_title.add_theme_color_override("font_color", Color("#c8cbd0"))
	detail_hint.text = "内容物正在弹出……"
	seal_bar.visible = false
	action_row.visible = false
	sell_button.disabled = true
	sell_button.text = "直接出售  ¥%s" % comma(price)
	toast("一个黑色剪影从盒中迎面弹出！")

	# First rush toward the screen as an oversized silhouette.
	var pop_tween := create_tween().set_parallel(true)
	pop_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(review_item, "global_position", screen_pop_position, 0.28)
	pop_tween.tween_property(review_item, "scale", Vector3.ONE * 1.12, 0.28)
	await pop_tween.finished

	# Then pull back rapidly and hit the center with a short, weighty rebound.
	var land_tween := create_tween().set_parallel(true)
	land_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	land_tween.tween_property(review_item, "global_position", impact_position, 0.40)
	land_tween.tween_property(review_item, "scale", Vector3.ONE * 0.78, 0.40)
	await land_tween.finished
	var settle_tween := create_tween()
	settle_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	settle_tween.tween_property(review_item, "scale", Vector3.ONE * 0.84, 0.18)
	await settle_tween.finished

	# Reveal the real color only after impact, then expand the rarity rays behind it.
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.albedo_color = RARITY_COLORS[rarity]
	material.emission_enabled = rarity >= 1
	var effect_tier := rarity
	material.emission = REVEAL_EFFECT_COLORS[effect_tier] * (0.20 + effect_tier * 0.09)
	review_glow.visible = true
	review_glow.scale = Vector3.ONE * 0.05
	var burst_tween := create_tween()
	burst_tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	burst_tween.tween_property(review_glow, "scale", Vector3.ONE, 0.34)
	await burst_tween.finished

	detail_title.text = "%s · %s" % [RARITIES[rarity], item_name]
	detail_title.add_theme_color_override("font_color", RARITY_COLORS[rarity])
	detail_hint.text = "所属：%s  ·  当前概率：%s  ·  当前市价：¥%s\n熟练 Lv.%d（售价 +%d%%）· 按住物品可自由旋转查看" % [SERIES[series_index]["name"], item_probability_text(series_index, item_index), comma(price), series_levels[series_index], int(series_levels[series_index] * PROFICIENCY_PRICE_BONUS * 100.0)]
	action_row.visible = true
	sell_button.disabled = false
	review_animation_playing = false
	toast("内容物落定。查看后选择直接出售或保留库存。")

func create_reveal_burst(rarity: int) -> Node3D:
	var tier := rarity
	var burst := Node3D.new()
	var effect_color: Color = REVEAL_EFFECT_COLORS[tier]
	var glow_shader := Shader.new()
	glow_shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;

uniform vec4 glow_color : source_color = vec4(1.0);
uniform float glow_strength = 1.0;
uniform float rotation_speed = 0.22;
uniform float spoke_count = 16.0;
uniform float phase_offset = 0.0;
uniform float rainbow_mode = 0.0;

vec3 spectrum(float hue) {
	vec3 rgb = clamp(abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	return rgb * rgb * (3.0 - 2.0 * rgb);
}

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float radius = length(p);
	float angle = atan(p.y, p.x) + TIME * rotation_speed + phase_offset;
	float circle_mask = 1.0 - smoothstep(0.76, 1.0, radius);
	float core_glow = pow(max(1.0 - radius, 0.0), 2.15);
	float halo_ring = exp(-pow((radius - 0.34) * 5.2, 2.0));
	float soft_spokes = pow(0.5 + 0.5 * cos(angle * spoke_count), 3.2);
	float spoke_fade = smoothstep(0.08, 0.26, radius) * (1.0 - smoothstep(0.54, 0.96, radius));
	float rotating_rays = soft_spokes * spoke_fade;
	float pulse = 0.66 + 0.34 * sin(TIME * 1.32 + phase_offset);
	float glow = (core_glow * 0.48 + halo_ring * 0.34 + rotating_rays * 0.55) * circle_mask;
	vec3 animated_color = glow_color.rgb;
	if (rainbow_mode > 0.5) {
		animated_color = spectrum(fract(angle / 6.283185 + radius * 0.32 + TIME * 0.075));
	}
	ALBEDO = animated_color;
	EMISSION = animated_color * glow * glow_strength * (1.35 + pulse * 0.65);
	ALPHA = glow * glow_color.a * pulse;
}
"""
	var glow_material := ShaderMaterial.new()
	glow_material.shader = glow_shader
	glow_material.set_shader_parameter("glow_color", Color(effect_color.r, effect_color.g, effect_color.b, 0.76))
	glow_material.set_shader_parameter("glow_strength", 0.76 + tier * 0.27)
	glow_material.set_shader_parameter("rotation_speed", 0.15 + tier * 0.035)
	glow_material.set_shader_parameter("spoke_count", 10.0 + tier * 1.6)
	glow_material.set_shader_parameter("phase_offset", float(rarity) * 0.73)
	glow_material.set_shader_parameter("rainbow_mode", 1.0 if rarity == 5 else 0.0)
	var glow_size: float = [1.55, 1.75, 1.95, 2.15, 2.35, 2.52][tier]
	var glow_mesh := QuadMesh.new()
	glow_mesh.size = Vector2(glow_size, glow_size)
	var glow := MeshInstance3D.new()
	glow.mesh = glow_mesh
	glow.material_override = glow_material
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	burst.add_child(glow)
	return burst

func resolve_review(sell_now: bool) -> void:
	if review_animation_playing or not review_item or pending_item.is_empty(): return
	if sell_now:
		var price := collectible_price(pending_item["series"], pending_item["item_index"])
		cash += price
		earned += price
		toast("藏品出售，到账 ¥%s。" % comma(price))
	else:
		collectibles.append(pending_item.duplicate(true))
		toast("藏品已保留在库存。")
	review_item.queue_free()
	review_item = null
	if review_glow:
		review_glow.queue_free()
		review_glow = null
	pending_item.clear()
	set_focus_depth_of_field(false)
	detail_panel.visible = false
	action_row.visible = false
	pointer_mode = ""
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
	var key := "%d_%d" % [item["series"], item["item_index"]]
	if not discovered.has(key):
		discovered[key] = true
		var bonus: int = max(1, int(SERIES[item["series"]]["base"] * 0.1))
		cash += bonus
		earned += bonus

func sell_collectible(index: int) -> void:
	if index < 0 or index >= collectibles.size(): return
	var item := collectibles[index]
	var value := collectible_price(item["series"], item["item_index"])
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
	value_label.text = "库存价值\n¥%s" % comma(total_inventory_value())
	date_label.text = "日期  ·  第 %d 天" % day
	refresh_player_level()
	parcel_label.text = "不限量 · 买 ¥1 / 压扁即结算 ¥2–3"
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
			card["detail"].text = "总赚取 ¥%s 升级解锁" % comma(SERIES[i]["unlock"])
			card["button"].text = "未解锁"
			card["button"].disabled = true
		refresh_mastery_card(i, card)
	refresh_inventory()
	refresh_collection()

func refresh_luck_panel() -> void:
	luck_level_label.text = "目前等级：%d级" % global_luck_level
	if global_luck_level >= GLOBAL_LUCK_COSTS.size():
		luck_button.text = "已满级"
		luck_button.disabled = true
	else:
		var cost: int = GLOBAL_LUCK_COSTS[global_luck_level]
		luck_button.text = "整体升级  ¥%s" % comma(cost)
		luck_button.disabled = cash < cost
	shake_level_label.text = "目前等级：%d级" % shake_upgrade_level
	if shake_upgrade_level >= SHAKE_UPGRADE_COSTS.size():
		shake_button.text = "已满级"
		shake_button.disabled = true
	else:
		var shake_cost: int = SHAKE_UPGRADE_COSTS[shake_upgrade_level]
		shake_button.text = "增加 1 次  ¥%s" % comma(shake_cost)
		shake_button.disabled = cash < shake_cost
	tear_skill_level_label.text = "目前等级：%d级" % tear_skill_level
	if tear_skill_level >= TEAR_SKILL_UPGRADE_COSTS.size():
		tear_skill_button.text = "已满级"
		tear_skill_button.disabled = true
	else:
		var skill_cost: int = TEAR_SKILL_UPGRADE_COSTS[tear_skill_level]
		tear_skill_button.text = "练习技巧  ¥%s" % comma(skill_cost)
		tear_skill_button.disabled = cash < skill_cost

func refresh_player_level() -> void:
	var level := player_level()
	player_level_label.text = "等级 Lv.%d · 总赚取 ¥%s" % [level, comma(earned)]
	if level >= SERIES.size():
		player_level_bar.value = 100
		player_level_bar.tooltip_text = "当前已解锁全部盲盒等级"
		return
	var current_threshold: int = int(SERIES[level - 1]["unlock"])
	var next_threshold: int = int(SERIES[level]["unlock"])
	player_level_bar.value = clampf(float(earned - current_threshold) / float(next_threshold - current_threshold) * 100.0, 0.0, 100.0)
	player_level_bar.tooltip_text = "总赚取 ¥%s / ¥%s，达到后解锁盲盒%d" % [comma(earned), comma(next_threshold), level + 1]

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
		toast("快递拆箱熟练度升至 Lv.%d，压扁后的即时结算收益提高！" % parcel_level)

func refresh_parcel_mastery() -> void:
	parcel_card_data["mastery_label"].text = "拆箱熟练 Lv.%d/5 · 结算 +%d%%" % [parcel_level, int(parcel_level * PROFICIENCY_PRICE_BONUS * 100.0)]
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
		var label := make_label("%s · %s\n¥%s" % [RARITIES[item["rarity"]], item["name"], comma(collectible_price(item["series"], item["item_index"]))], 13, RARITY_COLORS[item["rarity"]], true)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(label)
		var sell := button("出售", Color("#8a5e41"))
		sell.pressed.connect(sell_collectible.bind(i))
		h.add_child(sell)

func refresh_collection() -> void:
	clear_children(collection_grid)
	for s in SERIES.size():
		for item_index in SERIES[s]["items"].size():
			var rarity: int = SERIES[s]["rarities"][item_index]
			var found := discovered.has("%d_%d" % [s,item_index])
			var card := PanelContainer.new()
			card.custom_minimum_size = Vector2(105,86)
			card.add_theme_stylebox_override("panel", style(Color("#232b33"), 7, RARITY_COLORS[rarity] if found else Color("#46515b")))
			collection_grid.add_child(card)
			var text := "%s\n%s" % [RARITIES[rarity], SERIES[s]["items"][item_index]] if found else "%s\n???" % RARITIES[rarity]
			var label := make_label(text, 12, RARITY_COLORS[rarity] if found else Color("#66717b"), found)
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
	return player_level() >= index + 1

func player_level() -> int:
	var level := 1
	for index in range(1, SERIES.size()):
		if earned >= int(SERIES[index]["unlock"]):
			level = index + 1
	return level

func box_price(index: int) -> int:
	return max(1, int(round(SERIES[index]["base"] * FACTORS[(day - 1) % FACTORS.size()][index])))

func collectible_price(series_index: int, item_index: int) -> int:
	var mastery_multiplier: float = 1.0 + series_levels[series_index] * PROFICIENCY_PRICE_BONUS
	return max(1, int(round(market_price_at_day(series_index, item_index, day) * mastery_multiplier)))

func market_price_at_day(series_index: int, item_index: int, date_index: int) -> int:
	var rarity: int = SERIES[series_index]["rarities"][item_index]
	var market: float = FACTORS[(date_index - 1) % FACTORS.size()][series_index]
	var factor: float = 1.0 + (market - 1.0) * (1.0 + rarity * 0.16)
	return max(1, int(round(SERIES[series_index]["values"][item_index] * factor)))

func total_inventory_value() -> int:
	var value := 0
	for box in boxes:
		if is_instance_valid(box) and box.box_kind == "blind" and not box.opened: value += int(round(box_price(box.series_index) * 0.9))
	for item in collectibles: value += collectible_price(item["series"], item["item_index"])
	return value

func roll_content(series_index: int) -> int:
	var roll := rng.randi_range(1,10000)
	var total := 0
	var weights := item_weights_for_series(series_index)
	for i in weights.size():
		total += weights[i]
		if roll <= total: return i
	return weights.size() - 1

func item_weights_for_series(series_index: int) -> Array[int]:
	var progress := float(min(global_luck_level, SERIES_LUCK_MAX[series_index])) / float(SERIES_LUCK_MAX[series_index])
	var raw_weights: Array[float] = []
	var raw_total := 0.0
	for item_index in SERIES[series_index]["items"].size():
		var rarity: int = SERIES[series_index]["rarities"][item_index]
		var luck_factor: float = lerp(1.0, LUCK_RARITY_MULTIPLIERS[rarity], progress)
		var raw_weight: float = float(SERIES[series_index]["weights"][item_index]) * luck_factor
		raw_weights.append(raw_weight)
		raw_total += raw_weight
	var weights: Array[int] = []
	var used := 0
	for item_index in raw_weights.size():
		var weight := int(round(raw_weights[item_index] / raw_total * 10000.0))
		weights.append(weight)
		used += weight
	weights[weights.size() - 1] += 10000 - used
	return weights

func weights_for_series(series_index: int) -> Array[int]:
	var rarity_weights: Array[int] = []
	rarity_weights.resize(RARITIES.size())
	rarity_weights.fill(0)
	var item_weights := item_weights_for_series(series_index)
	for item_index in item_weights.size():
		var rarity: int = SERIES[series_index]["rarities"][item_index]
		rarity_weights[rarity] += item_weights[item_index]
	return rarity_weights

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

func item_probability_text(series_index: int, item_index: int) -> String:
	var weight: int = item_weights_for_series(series_index)[item_index]
	var percent := float(weight) / 100.0
	return "%.2f%%" % percent if weight % 100 != 0 else "%d%%" % int(percent)

func total_collectible_definitions() -> int:
	var total := 0
	for series in SERIES: total += series["items"].size()
	return total

func toast(text_value: String) -> void: toast_label.text = text_value

func make_shop_card(title_text: String, detail_text: String, color: Color) -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style(Color("#202831"), 9, color.darkened(0.2), 2))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	panel.add_child(col)
	var title := make_label(title_text, 14, color.lightened(0.2), true)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(title)
	var detail := make_label(detail_text, 11, Color("#9ba8b3"))
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
