extends Node3D

const BOX_SCENE := preload("res://scenes/entities/physical_box.tscn")
const PRICE_CHART_SCENE := preload("res://scripts/ui/price_chart.gd")
const REVEAL_SPRITESHEET_VFX := preload("res://scripts/vfx/reveal_spritesheet_vfx.gd")
const WORLD_SPRITESHEET_VFX := preload("res://scripts/vfx/spritesheet_vfx_3d.gd")
const SCREEN_SPRITESHEET_VFX := preload("res://scripts/vfx/spritesheet_vfx_2d.gd")
const REVEAL_VFX_SCREEN_FRACTION := 1.60
const REVIEW_MODEL_SCALE_MULTIPLIER := 2.0
const REVIEW_ITEM_CAMERA_DISTANCE := 2.65
const REVIEW_VFX_CAMERA_DISTANCE := 3.30
const REVIEW_VERTICAL_OFFSET := 0.40
const OPENED_BOX_SHRINK_DURATION := 0.34
const OPENED_BOX_FINAL_SCALE := 0.002
const NEW_DISCOVERY_SIDE_VFX_PATH := "res://assets/VFX/屏幕边缘礼花.png"
const REVEAL_OPEN_VFX_PATHS := {
	"regular":"res://assets/VFX/开出特效_普通款.png",
	"small_hidden":"res://assets/VFX/开出特效_小隐藏.png",
	"big_hidden":"res://assets/VFX/开出特效_大隐藏.png",
}
const REVEAL_IDLE_VFX_PATHS := {
	"regular":"res://assets/VFX/待机背景_普通款.png",
	"small_hidden":"res://assets/VFX/待机背景_小隐藏.png",
	"big_hidden":"res://assets/VFX/待机背景_大隐藏.png",
}
const DEVELOPER_CASH := 999999999999
const AUTO_OPENER_COST := 1000
const AUTO_OPENER_BASE_TIME := 6.0
const AUTO_SPEED_BASE_COST := 500
const AUTO_CAPACITY_BASE_COST := 1000
const AUTO_UPGRADE_MAX_LEVEL := 20
const TABLE_DRAG_HEIGHT := 1.85
const AUTO_GRABBER_COST := 2000
const AUTO_GRABBER_SPEED_BASE_COST := 1000
const AUTO_GRABBER_COUNT_BASE_COST := 2000
const AUTO_INTAKE_HALF_EXTENTS := Vector2(1.55, 1.35)
const AUTO_INTAKE_LOCAL_CENTER := Vector3(0.0, 0.0, 1.28)
const AUTO_VACUUM_BASE_SPEED := 1.85
const AUTO_VACUUM_EFFECT_RADIUS := 6.0
const LEFT_PANEL_X := 18.0
const LEFT_PANEL_WIDTH := 182.0
const LEFT_HUD_Y := 18.0
const LEFT_HUD_HEIGHT := 200.0
const LEFT_PANEL_GAP := 6.0
const LEFT_SHOP_BOTTOM := 702.0
const UI_PRIMARY := Color("#e60012")
const UI_SIGNAL := Color("#f68d1f")
const UI_AMBER := Color("#ecab37")
const UI_NAV_GOLD := Color("#e48600")
const UI_CANVAS := Color("#7a8aba")
const UI_CANVAS_SOFT := Color("#9fbee7")
const UI_PERIWINKLE := Color("#8ba1d4")
const UI_CHROME_INDIGO := Color("#3d4f97")
const UI_MUTED_INDIGO := Color("#60619c")
const UI_PLATINUM := Color("#dedede")
const UI_SURFACE := Color("#ffffff")
const UI_CARBON := Color("#21242e")
const UI_INK := Color("#21242e")
const UI_INK_SOFT := Color("#3d4f97")
const RARITIES := ["常规款", "未使用", "未使用", "未使用", "小隐藏", "大隐藏"]
const SERIES_LUCK_MAX := [5, 10, 15, 20, 25]
const MAX_LUCK_PEAK_TOTAL := 8000
const MAX_LUCK_JACKPOT_TOTAL := 1000
const MAX_LUCK_REMAINING_TOTAL := 1000
const MAX_LUCK_NO_HIDDEN_REMAINING_TOTAL := 2000
const LUCK_RARITY_ORDER := [0, 1, 2, 3, 5]
const LUCK_KEYFRAMES_WITH_HIDDEN := [
	[6000, 2800, 1090, 100, 10],
	[2400, 5000, 1900, 600, 100],
	[600, 1800, 5500, 1600, 500],
	[167, 333, 500, 8000, 1000],
]
const LUCK_KEYFRAMES_NO_HIDDEN := [
	[6000, 2800, 1100, 100, 0],
	[2500, 5000, 1900, 600, 0],
	[800, 2000, 5500, 1700, 0],
	[333, 667, 1000, 8000, 0],
]
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
const PARCEL_MIN_DETACH_MULTIPLIER := 0.18
const SERIES_MIN_DETACH_CHANCE := 0.01
const TEAR_MIN_FORCE_MULTIPLIER := 0.50
const REVEAL_EFFECT_COLORS := [Color("#f2f4f7"), Color("#65e582"), Color("#4e9cff"), Color("#a568ff"), Color("#ffc34d"), Color.WHITE]
const GLOBAL_LUCK_COSTS := [50,100,1000,5000,10000,25000,50000,100000,250000,500000,1000000,2500000,5000000,10000000,25000000,50000000,100000000,250000000,500000000,1000000000,2500000000,5000000000,10000000000,25000000000,50000000000]
const SHAKE_UPGRADE_COSTS := [100, 1000, 10000, 100000, 1000000]
const SERIES_SHAKE_TRAVEL := [420.0, 520.0, 650.0, 800.0, 980.0]
const SERIES_SHAKE_REVERSALS := [6, 8, 10, 12, 14]
const TEAR_SKILL_UPGRADE_COSTS := [50,100,1000,5000,10000,25000,50000,100000,250000,500000,1000000,2500000,5000000,10000000,25000000,50000000,100000000,250000000,500000000,1000000000,2500000000,5000000000,10000000000,25000000000,50000000000]
const RARITY_COLORS := [Color("#d9e0df"), Color("#65d77d"), Color("#62a8ff"), Color("#b989ff"), Color("#ffb347"), Color("#ff76d8")]
const COLLECTIBLE_MODEL_PATHS := [
	[
		"res://assets/3D assets/肥嘟嘟袋鼠/袋鼠-冬日暖意.fbx",
		"res://assets/3D assets/肥嘟嘟袋鼠/袋鼠-度假搭档.fbx",
		"res://assets/3D assets/肥嘟嘟袋鼠/袋鼠-煎扒厨师.fbx",
		"res://assets/3D assets/肥嘟嘟袋鼠/袋鼠-骑士.fbx",
		"res://assets/3D assets/肥嘟嘟袋鼠/袋鼠-人生一串.fbx",
		"res://assets/3D assets/肥嘟嘟袋鼠/袋鼠-送达.fbx",
		"res://assets/3D assets/肥嘟嘟袋鼠/袋鼠-外卖侠.fbx",
		"res://assets/3D assets/肥嘟嘟袋鼠/袋鼠-外卖小哥.fbx",
		"res://assets/3D assets/肥嘟嘟袋鼠/袋鼠-最爱甜筒.fbx",
		"res://assets/3D assets/肥嘟嘟袋鼠/袋鼠-国王（小隐藏）.fbx",
	],
	[
		"res://assets/3D assets/高雅企鹅/高雅企鹅-厨子.fbx",
		"res://assets/3D assets/高雅企鹅/高雅企鹅-钓鱼.fbx",
		"res://assets/3D assets/高雅企鹅/高雅企鹅-滑板.fbx",
		"res://assets/3D assets/高雅企鹅/高雅企鹅-卖萌.fbx",
		"res://assets/3D assets/高雅企鹅/高雅企鹅-迷人.fbx",
		"res://assets/3D assets/高雅企鹅/高雅企鹅-商务.fbx",
		"res://assets/3D assets/高雅企鹅/高雅企鹅-摄影.fbx",
		"res://assets/3D assets/高雅企鹅/高雅企鹅-休憩.fbx",
		"res://assets/3D assets/高雅企鹅/高雅企鹅-炫技.fbx",
		"res://assets/3D assets/高雅企鹅/高雅企鹅-国王（小隐藏）.fbx",
	],
	[
		"res://assets/3D assets/奶蛙/奶蛙-子鼠.fbx",
		"res://assets/3D assets/奶蛙/奶蛙-丑牛.fbx",
		"res://assets/3D assets/奶蛙/奶蛙-寅虎.fbx",
		"res://assets/3D assets/奶蛙/奶蛙-卯兔.fbx",
		"res://assets/3D assets/奶蛙/奶蛙-辰龙.fbx",
		"res://assets/3D assets/奶蛙/奶蛙-巳蛇.fbx",
		"res://assets/3D assets/奶蛙/奶蛙-午马.fbx",
		"res://assets/3D assets/奶蛙/奶蛙-未羊.fbx",
		"res://assets/3D assets/奶蛙/奶蛙-申猴.fbx",
		"res://assets/3D assets/奶蛙/奶蛙-酉鸡.fbx",
		"res://assets/3D assets/奶蛙/奶蛙-戌狗.fbx",
		"res://assets/3D assets/奶蛙/奶蛙-亥猪.fbx",
		"res://assets/3D assets/奶蛙/奶蛙-奶蛙.fbx",
	],
	[
		"res://assets/3D assets/牛来/牛来-豹拉.fbx",
		"res://assets/3D assets/牛来/牛来-大牛来.fbx",
		"res://assets/3D assets/牛来/牛来-坏狼A.fbx",
		"res://assets/3D assets/牛来/牛来-坏狼B.fbx",
		"res://assets/3D assets/牛来/牛来-牛爸爸.fbx",
		"res://assets/3D assets/牛来/牛来-牛来.fbx",
		"res://assets/3D assets/牛来/牛来-牛妈妈.fbx",
		"res://assets/3D assets/牛来/牛来-普通牛.fbx",
		"res://assets/3D assets/牛来/牛来-小绳头.fbx",
		"res://assets/3D assets/牛来/牛来-云雀.fbx",
		"res://assets/3D assets/牛来/牛来-票房王（小隐藏）.fbx",
		"res://assets/3D assets/牛来/牛来-奥德牛斯（大隐藏）.fbx",
	],
	[
		"res://assets/3D assets/胖企鹅/胖企鹅-Debug.fbx",
		"res://assets/3D assets/胖企鹅/胖企鹅-花花.fbx",
		"res://assets/3D assets/胖企鹅/胖企鹅-酷酷.fbx",
		"res://assets/3D assets/胖企鹅/胖企鹅-困困.fbx",
		"res://assets/3D assets/胖企鹅/胖企鹅-摸鱼.fbx",
		"res://assets/3D assets/胖企鹅/胖企鹅-派对.fbx",
		"res://assets/3D assets/胖企鹅/胖企鹅-取景.fbx",
		"res://assets/3D assets/胖企鹅/胖企鹅-蛙蛙.fbx",
		"res://assets/3D assets/胖企鹅/胖企鹅-西部.fbx",
		"res://assets/3D assets/胖企鹅/胖企鹅-嫌弃.fbx",
		"res://assets/3D assets/胖企鹅/胖企鹅-音乐.fbx",
		"res://assets/3D assets/胖企鹅/胖企鹅-宇宙.fbx",
		"res://assets/3D assets/胖企鹅/胖企鹅-破壳（小隐藏）.fbx",
		"res://assets/3D assets/胖企鹅/胖企鹅-胖大王（大隐藏） (1).fbx",
	],
]
const COLLECTIBLE_MODEL_TARGET_SIZE := 1.0
const COLLECTIBLE_FRONT_AXIS := Vector3.DOWN # 内容物统一使用本地 -Y 作为正面。
const COLLECTIBLE_UP_AXIS := Vector3.BACK # 与 -Y 正面配套，使用本地 +Z 作为上方。
const FAT_PARTNER_REVIEW_YAW := deg_to_rad(-25.0)
const REVIEW_TITLE_SMALL_HIDDEN_COLOR := Color("#a85bea")
const REVIEW_TITLE_BIG_HIDDEN_COLOR := Color("#f28a2e")
const SERIES := [
	{"name":"肥嘟嘟伙伴", "slogan":"9 款常规伙伴，另有 1 款金色小隐藏。", "base":20, "unlock":0, "color":Color("#59c7b5"), "items":["冬日暖意","度假搭档","煎扒厨师","骑士","人生一串","送达","外卖侠","外卖小哥","最爱甜筒","国王"], "rarities":[0,0,0,0,0,0,0,0,0,4], "weights":[95,95,95,95,95,95,95,95,95,45], "values":[30,30,30,30,30,30,30,30,30,150]},
	{"name":"高雅企鹅", "slogan":"戴着墨镜的高雅企鹅主题系列。", "base":48, "unlock":80, "color":Color("#8d66c7"), "items":["厨子","钓鱼","滑板","卖萌","迷人","商务","摄影","休憩","炫技","国王"], "rarities":[0,0,0,0,0,0,0,0,0,4], "weights":[95,95,95,95,95,95,95,95,95,45], "values":[72,72,72,72,72,72,72,72,72,600]},
	{"name":"奶蛙-生肖系列", "slogan":"12 款生肖常规款，另有 1 款金色小隐藏。", "base":120, "unlock":300, "color":Color("#526cb7"), "items":["子鼠","丑牛","寅虎","卯兔","辰龙","巳蛇","午马","未羊","申猴","酉鸡","戌狗","亥猪","奶蛙"], "rarities":[0,0,0,0,0,0,0,0,0,0,0,0,4], "weights":[19,19,19,19,19,19,19,19,19,19,19,19,12], "values":[180,180,180,180,180,180,180,180,180,180,180,180,1200]},
	{"name":"牛来", "slogan":"10 款角色常规款，并包含小隐藏与大隐藏。", "base":260, "unlock":1000, "color":Color("#dc759b"), "items":["豹拉","大牛来","坏狼A","坏狼B","牛爸爸","牛来","牛妈妈","普通牛","小绳头","云雀","票房王","奥德牛斯"], "rarities":[0,0,0,0,0,0,0,0,0,0,4,5], "weights":[94,94,94,94,94,94,94,94,94,94,50,10], "values":[390,390,390,390,390,390,390,390,390,390,2000,10000]},
	{"name":"胖企鹅系列", "slogan":"12 款红围巾企鹅常规款，并包含小隐藏与大隐藏。", "base":520, "unlock":3000, "color":Color("#dd7048"), "items":["Debug","花花","酷酷","困困","摸鱼","派对","取景","蛙蛙","西部","嫌弃","音乐","宇宙","破壳","胖大王"], "rarities":[0,0,0,0,0,0,0,0,0,0,0,0,4,5], "weights":[47,47,47,47,47,47,47,47,47,47,47,47,30,6], "values":[780,780,780,780,780,780,780,780,780,780,780,780,4000,12000]}
]
const COMBINATION_COLLECTIBLES := []
const NEWS := ["肥嘟嘟伙伴补货到店，九款常规款等概率出货。","高雅企鹅新品在步行街亮相。","奶蛙生肖系列开启预热。","牛来角色系列开放预订。","收藏家正在寻找金色小隐藏。","胖企鹅系列彩虹大隐藏引发讨论。","收藏节成交活跃，市场进入新周期。"]
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
var review_new_badge: Label
var pending_item: Dictionary = {}
var collectible_model_cache: Dictionary = {}

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
var keep_button: Button
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
var shop_scroll: ScrollContainer
var item_shop_scroll: ScrollContainer
var shop_tab_button: Button
var item_shop_tab_button: Button
var auto_opener_card: Dictionary
var auto_speed_card: Dictionary
var auto_capacity_card: Dictionary
var auto_grabber_card: Dictionary
var auto_grabber_speed_card: Dictionary
var auto_grabber_count_card: Dictionary
var auto_opener_owned := false
var auto_opener_speed_level := 0
var auto_opener_capacity := 5
var auto_opener_root: Node3D
var auto_basket_root: Node3D
var auto_left_arm: Node3D
var auto_right_arm: Node3D
var auto_processing_box: RigidBody3D
var auto_processing_elapsed := 0.0
var auto_basket_boxes: Array[RigidBody3D] = []
var auto_processed_boxes: Array[RigidBody3D] = []
var auto_settlement_active := false
var auto_grabber_owned := false
var auto_grabber_speed_level := 0
var auto_grabber_count_level := 0
var auto_grabber_panel_root: Node3D
var auto_grabber_holding := false
var auto_vacuum_root: Node3D
var auto_vacuum_particles: GPUParticles3D
var developer_panel: PanelContainer
var developer_toggle_button: Button
var developer_panel_hidden := false
var developer_panel_tween: Tween

func _ready() -> void:
	rng.randomize()
	focus_camera_attributes = CameraAttributesPractical.new()
	camera.attributes = focus_camera_attributes
	set_focus_depth_of_field(false)
	shake_audio = AudioStreamPlayer.new()
	add_child(shake_audio)
	build_ui()
	refresh_ui()
	toast("点击盲盒查看并摇盒；重复内容物可在手机里的“扭扭”按当前市价六折立即出售。")

func _process(delta: float) -> void:
	if not ticker_source.is_empty():
		ticker_scroll_x -= delta * 0.82
		if ticker_scroll_x <= -6.4: ticker_scroll_x += 6.4
		wall_ticker.position.x = ticker_scroll_x
		wall_ticker_b.position.x = ticker_scroll_x + 6.4
	update_auto_opener(delta)
	update_auto_grabber(delta)

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
	left_hud.name = "LeftStatusPanel"
	left_hud.position = Vector2(LEFT_PANEL_X, LEFT_HUD_Y)
	left_hud.size = Vector2(LEFT_PANEL_WIDTH, LEFT_HUD_HEIGHT)
	left_hud.add_theme_stylebox_override("panel", chrome_style(UI_CANVAS))
	canvas.add_child(left_hud)
	var hud_column := VBoxContainer.new()
	hud_column.add_theme_constant_override("separation", 5)
	left_hud.add_child(hud_column)
	hud_column.add_child(section_label("PLAYER STATUS / 玩家状态"))
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
	player_level_label = make_label("等级", 11, UI_INK, true)
	level_block.add_child(player_level_label)
	player_level_bar = ProgressBar.new()
	player_level_bar.custom_minimum_size.y = 10
	player_level_bar.max_value = 100
	player_level_bar.show_percentage = false
	decorate_progress_bar(player_level_bar, UI_SIGNAL)
	level_block.add_child(player_level_bar)
	var end_day := button("▶ 结束今天", UI_SIGNAL)
	end_day.pressed.connect(end_day_pressed)
	hud_column.add_child(end_day)

	var left_shop := PanelContainer.new()
	left_shop.name = "LeftShopPanel"
	var left_shop_y := LEFT_HUD_Y + LEFT_HUD_HEIGHT + LEFT_PANEL_GAP
	left_shop.position = Vector2(LEFT_PANEL_X, left_shop_y)
	left_shop.size = Vector2(LEFT_PANEL_WIDTH, LEFT_SHOP_BOTTOM - left_shop_y)
	left_shop.add_theme_stylebox_override("panel", chrome_style(UI_CANVAS))
	canvas.add_child(left_shop)
	var shop_shell := VBoxContainer.new()
	shop_shell.add_theme_constant_override("separation", 5)
	left_shop.add_child(shop_shell)
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 4)
	shop_shell.add_child(tab_row)
	shop_tab_button = button("◀ 盲盒", UI_CARBON)
	shop_tab_button.custom_minimum_size = Vector2(72, 32)
	shop_tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_tab_button.add_theme_font_size_override("font_size", 11)
	shop_tab_button.pressed.connect(show_left_shop_tab.bind(false))
	shop_tab_button.disabled = true
	tab_row.add_child(shop_tab_button)
	item_shop_tab_button = button("道具 ▶", UI_CARBON)
	item_shop_tab_button.custom_minimum_size = Vector2(72, 32)
	item_shop_tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_shop_tab_button.add_theme_font_size_override("font_size", 11)
	item_shop_tab_button.pressed.connect(show_left_shop_tab.bind(true))
	tab_row.add_child(item_shop_tab_button)
	shop_scroll = ScrollContainer.new()
	shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shop_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	shop_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_shell.add_child(shop_scroll)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 148
	column.add_theme_constant_override("separation", 5)
	shop_scroll.add_child(column)
	var parcel_card := make_shop_card("快递盒", "买入 ¥1 · 压扁即结算 ¥2–3", Color("#a87e55"))
	parcel_label = parcel_card["detail"]
	parcel_card["button"].text = "购买  ¥1"
	parcel_card["button"].pressed.connect(buy_parcel)
	var parcel_mastery_label := make_label("拆箱熟练 Lv.0/5", 10, UI_INK_SOFT, true)
	parcel_card["column"].add_child(parcel_mastery_label)
	var parcel_mastery_bar := ProgressBar.new()
	parcel_mastery_bar.custom_minimum_size.y = 9
	parcel_mastery_bar.max_value = 100
	parcel_mastery_bar.show_percentage = false
	decorate_progress_bar(parcel_mastery_bar, UI_NAV_GOLD)
	parcel_card["column"].add_child(parcel_mastery_bar)
	parcel_card["mastery_label"] = parcel_mastery_label
	parcel_card["mastery_bar"] = parcel_mastery_bar
	parcel_card_data = parcel_card
	column.add_child(parcel_card["panel"])
	for i in SERIES.size():
		var data: Dictionary = SERIES[i]
		var card := make_shop_card("盲盒 %d · %s" % [i + 1, data["name"]], "按图鉴逐件公开概率", data["color"])
		card["button"].pressed.connect(buy_box.bind(i))
		var mastery_label := make_label("熟练 Lv.0 / 5", 10, UI_INK_SOFT, true)
		card["column"].add_child(mastery_label)
		var mastery_bar := ProgressBar.new()
		mastery_bar.custom_minimum_size.y = 9
		mastery_bar.max_value = 100
		mastery_bar.show_percentage = false
		decorate_progress_bar(mastery_bar, data["color"])
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
	unknown.add_theme_stylebox_override("panel", inset_style(UI_MUTED_INDIGO))
	var unknown_label := make_label("？  新系列预留栏位", 13, UI_CANVAS_SOFT, true)
	unknown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unknown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	unknown.add_child(unknown_label)
	column.add_child(unknown)

	item_shop_scroll = ScrollContainer.new()
	item_shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	item_shop_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	item_shop_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_shop_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_shop_scroll.visible = false
	shop_shell.add_child(item_shop_scroll)
	var item_column := VBoxContainer.new()
	item_column.custom_minimum_size.x = 148
	item_column.add_theme_constant_override("separation", 6)
	item_shop_scroll.add_child(item_column)
	var item_intro := section_label("HARDWARE SHOP / 自动化道具")
	item_intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_column.add_child(item_intro)
	auto_opener_card = make_shop_card("自动开盒机", "容量 5 · 将盲盒投入头顶篮子", Color("#c07b48"))
	auto_opener_card["button"].pressed.connect(buy_auto_opener)
	item_column.add_child(auto_opener_card["panel"])
	auto_speed_card = make_shop_card("开盒机速度", "每级加速 10%", Color("#4c87a4"))
	auto_speed_card["button"].pressed.connect(upgrade_auto_opener_speed)
	item_column.add_child(auto_speed_card["panel"])
	auto_capacity_card = make_shop_card("开盒机容量", "每级增加 5 个待结算位", Color("#6e6aa8"))
	auto_capacity_card["button"].pressed.connect(upgrade_auto_opener_capacity)
	item_column.add_child(auto_capacity_card["panel"])
	auto_grabber_card = make_shop_card("自动吸尘器", "按住桌面红色按钮，将未拆盲盒吸向开盒区", Color("#4a8f77"))
	auto_grabber_card["button"].pressed.connect(buy_auto_grabber)
	item_column.add_child(auto_grabber_card["panel"])
	auto_grabber_speed_card = make_shop_card("吸尘速度", "每级使盲盒移动速度提高 10%", Color("#3f7899"))
	auto_grabber_speed_card["button"].pressed.connect(upgrade_auto_grabber_speed)
	item_column.add_child(auto_grabber_speed_card["panel"])
	auto_grabber_count_card = make_shop_card("吸尘器吸力", "每级提高吸力强度 15%", Color("#7c5793"))
	auto_grabber_count_card["button"].pressed.connect(upgrade_auto_grabber_count)
	item_column.add_child(auto_grabber_count_card["panel"])

	var top_buttons := HBoxContainer.new()
	top_buttons.position = Vector2(890, 18)
	top_buttons.size = Vector2(372, 48)
	top_buttons.add_theme_constant_override("separation", 8)
	canvas.add_child(top_buttons)
	var market_button := button("MARKET 行情", UI_CARBON)
	market_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_button.pressed.connect(toggle_market)
	top_buttons.add_child(market_button)
	var inv_button := button("STOCK 库存", UI_CARBON)
	inv_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_button.pressed.connect(toggle_inventory)
	top_buttons.add_child(inv_button)
	var collect_button := button("COLLECT 收藏", UI_CARBON)
	collect_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collect_button.pressed.connect(toggle_collection)
	top_buttons.add_child(collect_button)
	build_upgrade_panel(canvas)
	build_developer_panel(canvas)

	detail_panel = PanelContainer.new()
	detail_panel.position = Vector2(365, 535)
	detail_panel.size = Vector2(580, 155)
	detail_panel.visible = false
	detail_panel.add_theme_stylebox_override("panel", chrome_style(UI_CANVAS_SOFT))
	canvas.add_child(detail_panel)
	var detail_col := VBoxContainer.new()
	detail_col.add_theme_constant_override("separation", 5)
	detail_panel.add_child(detail_col)
	detail_title = make_label("", 20, UI_CHROME_INDIGO, true)
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_col.add_child(detail_title)
	detail_hint = make_label("", 13, UI_INK)
	detail_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_col.add_child(detail_hint)
	seal_bar = ProgressBar.new()
	seal_bar.max_value = 100
	seal_bar.show_percentage = false
	seal_bar.visible = false
	decorate_progress_bar(seal_bar, UI_SIGNAL)
	detail_col.add_child(seal_bar)
	action_row = HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 12)
	action_row.visible = false
	detail_col.add_child(action_row)
	sell_button = button("▶ 直接出售", UI_SIGNAL)
	sell_button.custom_minimum_size.x = 210
	sell_button.pressed.connect(resolve_review.bind(true))
	action_row.add_child(sell_button)
	keep_button = button("计入库存（同款 0）", UI_AMBER)
	keep_button.custom_minimum_size.x = 180
	keep_button.pressed.connect(resolve_review.bind(false))
	action_row.add_child(keep_button)
	toast_label = make_label("点击桌面上的箱子，将它拿到眼前查看。", 13, UI_INK, true)
	toast_label.position = Vector2(350, 665)
	toast_label.size = Vector2(600, 38)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_stylebox_override("normal", chrome_style(UI_SURFACE))
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

func show_left_shop_tab(show_items: bool) -> void:
	shop_scroll.visible = not show_items
	item_shop_scroll.visible = show_items
	shop_tab_button.disabled = not show_items
	item_shop_tab_button.disabled = show_items
	if show_items: refresh_item_shop()

func buy_auto_opener() -> void:
	if auto_opener_owned:
		toast("自动开盒机已经安装在桌面左上角。")
		return
	if cash < AUTO_OPENER_COST:
		toast("购买自动开盒机还需要 ¥%s。" % comma(AUTO_OPENER_COST - cash))
		return
	cash -= AUTO_OPENER_COST
	auto_opener_owned = true
	build_auto_opener_robot()
	toast("自动开盒机已安装：将未拆盲盒拖进头顶篮子，它才会开始处理。")
	refresh_ui()

func upgrade_auto_opener_speed() -> void:
	if not auto_opener_owned:
		toast("需要先购买自动开盒机。")
		return
	if auto_opener_speed_level >= AUTO_UPGRADE_MAX_LEVEL:
		toast("自动开盒机速度已经满级。")
		return
	var cost := auto_speed_upgrade_cost()
	if cash < cost:
		toast("升级开盒速度还需要 ¥%s。" % comma(cost - cash))
		return
	cash -= cost
	auto_opener_speed_level += 1
	toast("自动开盒机速度升至 %d 级，当前加速 %d%%。" % [auto_opener_speed_level, auto_opener_speed_level * 10])
	refresh_ui()

func upgrade_auto_opener_capacity() -> void:
	if not auto_opener_owned:
		toast("需要先购买自动开盒机。")
		return
	var capacity_level := (auto_opener_capacity - 5) / 5
	if capacity_level >= AUTO_UPGRADE_MAX_LEVEL:
		toast("自动开盒机容量已经满级。")
		return
	var cost := auto_capacity_upgrade_cost()
	if cash < cost:
		toast("升级开盒容量还需要 ¥%s。" % comma(cost - cash))
		return
	cash -= cost
	auto_opener_capacity += 5
	toast("自动开盒机容量提升至 %d。" % auto_opener_capacity)
	refresh_ui()

func buy_auto_grabber() -> void:
	if auto_grabber_owned:
		toast("自动吸尘器和红色控制按钮已经安装。")
		return
	if not auto_opener_owned:
		toast("自动吸尘器需要安装在自动开盒机上。")
		return
	if cash < AUTO_GRABBER_COST:
		toast("购买自动吸尘器还需要 ¥%s。" % comma(AUTO_GRABBER_COST - cash))
		return
	cash -= AUTO_GRABBER_COST
	auto_grabber_owned = true
	build_auto_grabber_panel()
	build_auto_vacuum_on_opener()
	toast("吸尘器已安装。按住右下角红色按钮，未拆盲盒会被吸向开盒机感应区。")
	refresh_ui()

func upgrade_auto_grabber_speed() -> void:
	if not auto_grabber_owned:
		toast("需要先购买自动吸尘器。")
		return
	if auto_grabber_speed_level >= AUTO_UPGRADE_MAX_LEVEL:
		toast("吸尘速度已经满级。")
		return
	var cost := auto_grabber_speed_upgrade_cost()
	if cash < cost:
		toast("升级吸尘速度还需要 ¥%s。" % comma(cost - cash))
		return
	cash -= cost
	auto_grabber_speed_level += 1
	toast("吸尘速度升至 %d 级，盲盒移动速度提高 %d%%。" % [auto_grabber_speed_level, auto_grabber_speed_level * 10])
	refresh_ui()

func upgrade_auto_grabber_count() -> void:
	if not auto_grabber_owned:
		toast("需要先购买自动吸尘器。")
		return
	if auto_grabber_count_level >= AUTO_UPGRADE_MAX_LEVEL:
		toast("吸尘器吸力已经满级。")
		return
	var cost := auto_grabber_count_upgrade_cost()
	if cash < cost:
		toast("升级吸尘器吸力还需要 ¥%s。" % comma(cost - cash))
		return
	cash -= cost
	auto_grabber_count_level += 1
	toast("吸尘器吸力升至 %d 级，当前吸力提高 %d%%。" % [auto_grabber_count_level, auto_grabber_count_level * 15])
	refresh_ui()

func auto_speed_upgrade_cost() -> int:
	return int(AUTO_SPEED_BASE_COST * pow(2.0, auto_opener_speed_level))

func auto_capacity_upgrade_cost() -> int:
	var capacity_level := (auto_opener_capacity - 5) / 5
	return int(AUTO_CAPACITY_BASE_COST * pow(2.0, capacity_level))

func auto_grabber_speed_upgrade_cost() -> int:
	return int(AUTO_GRABBER_SPEED_BASE_COST * pow(2.0, auto_grabber_speed_level))

func auto_grabber_count_upgrade_cost() -> int:
	return int(AUTO_GRABBER_COUNT_BASE_COST * pow(2.0, auto_grabber_count_level))

func refresh_item_shop() -> void:
	if auto_opener_card.is_empty(): return
	if auto_opener_owned:
		auto_opener_card["detail"].text = "篮中 %d/%d · 待结算 %d" % [auto_basket_boxes.size(), auto_opener_capacity, auto_processed_boxes.size()]
		auto_opener_card["button"].text = "已拥有"
		auto_opener_card["button"].disabled = true
	else:
		auto_opener_card["detail"].text = "初始篮容量 5 · 需手动投入盲盒"
		auto_opener_card["button"].text = "购买  ¥%s" % comma(AUTO_OPENER_COST)
		auto_opener_card["button"].disabled = cash < AUTO_OPENER_COST
	if auto_opener_speed_level >= AUTO_UPGRADE_MAX_LEVEL:
		auto_speed_card["detail"].text = "速度 Lv.%d · 加速 %d%%" % [auto_opener_speed_level, auto_opener_speed_level * 10]
		auto_speed_card["button"].text = "已满级"
		auto_speed_card["button"].disabled = true
	else:
		auto_speed_card["detail"].text = "速度 Lv.%d · 当前加速 %d%%" % [auto_opener_speed_level, auto_opener_speed_level * 10]
		auto_speed_card["button"].text = "加速 10%%  ¥%s" % comma(auto_speed_upgrade_cost())
		auto_speed_card["button"].disabled = not auto_opener_owned or cash < auto_speed_upgrade_cost()
	var capacity_level := (auto_opener_capacity - 5) / 5
	if capacity_level >= AUTO_UPGRADE_MAX_LEVEL:
		auto_capacity_card["detail"].text = "容量 Lv.%d · 当前 %d" % [capacity_level, auto_opener_capacity]
		auto_capacity_card["button"].text = "已满级"
		auto_capacity_card["button"].disabled = true
	else:
		auto_capacity_card["detail"].text = "容量 Lv.%d · 当前 %d" % [capacity_level, auto_opener_capacity]
		auto_capacity_card["button"].text = "+5 容量  ¥%s" % comma(auto_capacity_upgrade_cost())
		auto_capacity_card["button"].disabled = not auto_opener_owned or cash < auto_capacity_upgrade_cost()
	if auto_grabber_owned:
		auto_grabber_card["detail"].text = "已安装 · 按住右下角红色按钮运行"
		auto_grabber_card["button"].text = "已拥有"
		auto_grabber_card["button"].disabled = true
	else:
		auto_grabber_card["detail"].text = "把桌面盲盒吸向开盒机感应区"
		auto_grabber_card["button"].text = "购买  ¥%s" % comma(AUTO_GRABBER_COST)
		auto_grabber_card["button"].disabled = not auto_opener_owned or cash < AUTO_GRABBER_COST
	if auto_grabber_speed_level >= AUTO_UPGRADE_MAX_LEVEL:
		auto_grabber_speed_card["detail"].text = "速度 Lv.%d · 加速 %d%%" % [auto_grabber_speed_level, auto_grabber_speed_level * 10]
		auto_grabber_speed_card["button"].text = "已满级"
		auto_grabber_speed_card["button"].disabled = true
	else:
		auto_grabber_speed_card["detail"].text = "速度 Lv.%d · 加速 %d%%" % [auto_grabber_speed_level, auto_grabber_speed_level * 10]
		auto_grabber_speed_card["button"].text = "加速 10%%  ¥%s" % comma(auto_grabber_speed_upgrade_cost())
		auto_grabber_speed_card["button"].disabled = not auto_grabber_owned or cash < auto_grabber_speed_upgrade_cost()
	if auto_grabber_count_level >= AUTO_UPGRADE_MAX_LEVEL:
		auto_grabber_count_card["detail"].text = "吸力 Lv.%d · 加成 %d%%" % [auto_grabber_count_level, auto_grabber_count_level * 15]
		auto_grabber_count_card["button"].text = "已满级"
		auto_grabber_count_card["button"].disabled = true
	else:
		auto_grabber_count_card["detail"].text = "吸力 Lv.%d · 加成 %d%%" % [auto_grabber_count_level, auto_grabber_count_level * 15]
		auto_grabber_count_card["button"].text = "+15%% 吸力  ¥%s" % comma(auto_grabber_count_upgrade_cost())
		auto_grabber_count_card["button"].disabled = not auto_grabber_owned or cash < auto_grabber_count_upgrade_cost()

func build_auto_opener_robot() -> void:
	if is_instance_valid(auto_opener_root): return
	auto_opener_root = Node3D.new()
	auto_opener_root.name = "AutoBoxOpener"
	auto_opener_root.position = Vector3(-4.65, 0.32, -3.25)
	items_root.add_child(auto_opener_root)
	var orange := Color("#d07b3e")
	var dark := Color("#263744")
	var metal := Color("#91a6ad")
	add_robot_box(auto_opener_root, Vector3(0, 0.82, 0), Vector3(1.15, 1.15, 0.72), orange)
	add_robot_box(auto_opener_root, Vector3(0, 1.55, 0.03), Vector3(0.82, 0.42, 0.60), dark)
	add_robot_box(auto_opener_root, Vector3(-0.31, 1.58, 0.35), Vector3(0.14, 0.12, 0.05), Color("#7df3ff"), true)
	add_robot_box(auto_opener_root, Vector3(0.31, 1.58, 0.35), Vector3(0.14, 0.12, 0.05), Color("#7df3ff"), true)
	add_robot_box(auto_opener_root, Vector3(-0.34, 0.12, 0), Vector3(0.28, 0.42, 0.42), dark)
	add_robot_box(auto_opener_root, Vector3(0.34, 0.12, 0), Vector3(0.28, 0.42, 0.42), dark)
	auto_left_arm = Node3D.new()
	auto_left_arm.position = Vector3(-0.72, 1.14, 0.18)
	auto_opener_root.add_child(auto_left_arm)
	add_robot_box(auto_left_arm, Vector3(0, 0, 0.53), Vector3(0.22, 0.22, 1.06), metal)
	add_robot_box(auto_left_arm, Vector3(0, -0.02, 1.08), Vector3(0.40, 0.16, 0.30), dark)
	auto_right_arm = Node3D.new()
	auto_right_arm.position = Vector3(0.72, 1.14, 0.18)
	auto_opener_root.add_child(auto_right_arm)
	add_robot_box(auto_right_arm, Vector3(0, 0, 0.53), Vector3(0.22, 0.22, 1.06), metal)
	add_robot_box(auto_right_arm, Vector3(0, -0.02, 1.08), Vector3(0.40, 0.16, 0.30), dark)
	var label := Label3D.new()
	label.text = "自动开盒"
	label.position = Vector3(0, 0.80, 0.385)
	label.font_size = 24
	label.modulate = Color("#fff0c7")
	label.outline_size = 8
	auto_opener_root.add_child(label)
	auto_basket_root = Node3D.new()
	auto_basket_root.name = "InputBasket"
	auto_basket_root.position = Vector3(0, 2.08, 0.02)
	auto_opener_root.add_child(auto_basket_root)
	var basket_color := Color("#c49a58")
	add_robot_box(auto_basket_root, Vector3(0, 0, 0), Vector3(1.62, 0.10, 1.18), basket_color)
	add_robot_box(auto_basket_root, Vector3(-0.76, 0.30, 0), Vector3(0.10, 0.62, 1.18), basket_color)
	add_robot_box(auto_basket_root, Vector3(0.76, 0.30, 0), Vector3(0.10, 0.62, 1.18), basket_color)
	add_robot_box(auto_basket_root, Vector3(0, 0.30, -0.54), Vector3(1.62, 0.62, 0.10), basket_color)
	add_robot_box(auto_basket_root, Vector3(0, 0.18, 0.54), Vector3(1.62, 0.36, 0.10), basket_color)
	var basket_label := Label3D.new()
	basket_label.text = "投入盲盒"
	basket_label.position = Vector3(0, 0.34, 0.60)
	basket_label.font_size = 20
	basket_label.modulate = Color("#fff1bf")
	basket_label.outline_size = 7
	auto_basket_root.add_child(basket_label)
	build_auto_intake_zone()

func add_robot_box(parent: Node3D, part_position: Vector3, part_size: Vector3, color: Color, glow := false) -> CSGBox3D:
	var part := CSGBox3D.new()
	part.position = part_position
	part.size = part_size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.55
	material.metallic = 0.35
	material.emission_enabled = glow
	if glow: material.emission = color * 0.7
	part.material = material
	parent.add_child(part)
	return part

func build_auto_intake_zone() -> void:
	var zone := Node3D.new()
	zone.name = "AutomaticIntakeZone"
	zone.position = AUTO_INTAKE_LOCAL_CENTER + Vector3(0, 0.025, 0)
	auto_opener_root.add_child(zone)
	var edge_color := Color("#f0a52f")
	var width := AUTO_INTAKE_HALF_EXTENTS.x * 2.0
	var depth := AUTO_INTAKE_HALF_EXTENTS.y * 2.0
	add_robot_box(zone, Vector3(0, 0, -AUTO_INTAKE_HALF_EXTENTS.y), Vector3(width, 0.035, 0.055), edge_color, true)
	add_robot_box(zone, Vector3(0, 0, AUTO_INTAKE_HALF_EXTENTS.y), Vector3(width, 0.035, 0.055), edge_color, true)
	add_robot_box(zone, Vector3(-AUTO_INTAKE_HALF_EXTENTS.x, 0, 0), Vector3(0.055, 0.035, depth), edge_color, true)
	add_robot_box(zone, Vector3(AUTO_INTAKE_HALF_EXTENTS.x, 0, 0), Vector3(0.055, 0.035, depth), edge_color, true)
	var zone_label := Label3D.new()
	zone_label.text = "AUTO INTAKE"
	zone_label.position = Vector3(0, 0.04, AUTO_INTAKE_HALF_EXTENTS.y - 0.12)
	zone_label.rotation.x = deg_to_rad(-90.0)
	zone_label.font_size = 18
	zone_label.modulate = Color("#ffe0a0")
	zone_label.outline_size = 5
	zone.add_child(zone_label)

func is_in_auto_intake_zone(world_position: Vector3) -> bool:
	if not auto_opener_owned or not is_instance_valid(auto_opener_root): return false
	var local := auto_opener_root.to_local(world_position) - AUTO_INTAKE_LOCAL_CENTER
	return absf(local.x) <= AUTO_INTAKE_HALF_EXTENTS.x and absf(local.z) <= AUTO_INTAKE_HALF_EXTENTS.y and local.y >= -0.55 and local.y <= 1.8

func update_auto_intake_zone() -> void:
	if not auto_opener_owned or not is_instance_valid(auto_basket_root): return
	if auto_basket_boxes.size() >= auto_opener_capacity: return
	for box in boxes:
		if auto_basket_boxes.size() >= auto_opener_capacity: break
		if not is_vacuum_box_candidate(box): continue
		if is_in_auto_intake_zone(box.global_position): enqueue_auto_opener_box(box, false)

func enqueue_auto_opener_box(box: RigidBody3D, announce := true) -> bool:
	if not auto_opener_owned or not is_instance_valid(auto_basket_root): return false
	if auto_basket_boxes.size() >= auto_opener_capacity:
		toast("自动开盒机的篮子已满（%d/%d），请等待机械臂取走盒子。" % [auto_basket_boxes.size(), auto_opener_capacity])
		return false
	box.set_meta("auto_basket", true)
	box.freeze = true
	box.linear_velocity = Vector3.ZERO
	box.angular_velocity = Vector3.ZERO
	box.scale = Vector3.ONE * 0.28
	auto_basket_boxes.append(box)
	restack_auto_basket_boxes()
	if announce: toast("盲盒进入开盒机感应区，已自动缩小收入篮中。")
	refresh_item_shop()
	return true

func restack_auto_basket_boxes() -> void:
	for index in auto_basket_boxes.size():
		var box := auto_basket_boxes[index]
		if not is_instance_valid(box): continue
		var column := index % 5
		var row := (index / 5) % 3
		var layer := index / 15
		box.global_position = auto_basket_root.to_global(Vector3((column - 2) * 0.28, 0.16 + layer * 0.20, (row - 1) * 0.30))
		box.rotation = Vector3(0, 0.10 * (column - 2), 0)

func build_auto_grabber_panel() -> void:
	if is_instance_valid(auto_grabber_panel_root): return
	auto_grabber_panel_root = Node3D.new()
	auto_grabber_panel_root.name = "VacuumControlButton"
	auto_grabber_panel_root.position = Vector3(3.75, 0.42, 3.0)
	items_root.add_child(auto_grabber_panel_root)
	var base := add_robot_box(auto_grabber_panel_root, Vector3.ZERO, Vector3(1.55, 0.24, 1.18), Color("#262d3b"))
	base.rotation.x = deg_to_rad(-8.0)
	var button_pad := CSGCylinder3D.new()
	button_pad.radius = 0.52
	button_pad.height = 0.22
	button_pad.position = Vector3(0, 0.25, 0.02)
	button_pad.material = robot_material(Color("#e32628"), true)
	auto_grabber_panel_root.add_child(button_pad)
	var label := Label3D.new()
	label.text = "按住吸尘"
	label.position = Vector3(0, 0.25, 0.64)
	label.font_size = 22
	label.modulate = Color("#ffffff")
	label.outline_size = 7
	auto_grabber_panel_root.add_child(label)

func build_auto_vacuum_on_opener() -> void:
	if not is_instance_valid(auto_opener_root) or is_instance_valid(auto_vacuum_root): return
	auto_vacuum_root = Node3D.new()
	auto_vacuum_root.name = "OpenerVacuum"
	auto_vacuum_root.position = Vector3(0, 1.05, 0.72)
	auto_opener_root.add_child(auto_vacuum_root)
	add_robot_box(auto_vacuum_root, Vector3(0, 0, 0), Vector3(0.82, 0.58, 0.62), Color("#33495d"))
	var nozzle := CSGCylinder3D.new()
	nozzle.radius = 0.34
	nozzle.height = 0.82
	nozzle.rotation.x = deg_to_rad(90.0)
	nozzle.position = Vector3(0, -0.03, 0.62)
	nozzle.material = robot_material(Color("#718c9a"))
	auto_vacuum_root.add_child(nozzle)
	var nozzle_ring := CSGCylinder3D.new()
	nozzle_ring.radius = 0.43
	nozzle_ring.height = 0.12
	nozzle_ring.rotation.x = deg_to_rad(90.0)
	nozzle_ring.position = Vector3(0, -0.03, 1.05)
	nozzle_ring.material = robot_material(Color("#f0a52f"), true)
	auto_vacuum_root.add_child(nozzle_ring)
	build_vacuum_particles()

func build_vacuum_particles() -> void:
	auto_vacuum_particles = GPUParticles3D.new()
	auto_vacuum_particles.name = "VacuumFlowParticles"
	# Keep the whole effect in a thin layer above the desk. Particles are born
	# around a desk-scale ring and expire as they converge on the opener center.
	auto_vacuum_particles.position = Vector3(0, 0.16, 0)
	auto_vacuum_particles.amount = 480
	auto_vacuum_particles.lifetime = 1.7
	auto_vacuum_particles.randomness = 0.12
	auto_vacuum_particles.emitting = false
	auto_vacuum_particles.visibility_aabb = AABB(Vector3(-AUTO_VACUUM_EFFECT_RADIUS - 0.5, -0.2, -AUTO_VACUUM_EFFECT_RADIUS - 0.5), Vector3(AUTO_VACUUM_EFFECT_RADIUS * 2.0 + 1.0, 0.8, AUTO_VACUUM_EFFECT_RADIUS * 2.0 + 1.0))
	var particle_material := ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	particle_material.emission_ring_axis = Vector3.UP
	particle_material.emission_ring_height = 0.08
	particle_material.emission_ring_radius = AUTO_VACUUM_EFFECT_RADIUS
	particle_material.emission_ring_inner_radius = AUTO_VACUUM_EFFECT_RADIUS - 0.18
	particle_material.emission_ring_cone_angle = 0.0
	particle_material.direction = Vector3.RIGHT
	particle_material.spread = 180.0
	particle_material.gravity = Vector3.ZERO
	particle_material.initial_velocity_min = 0.0
	particle_material.initial_velocity_max = 0.12
	particle_material.radial_accel_min = -4.2
	particle_material.radial_accel_max = -4.2
	particle_material.scale_min = 0.35
	particle_material.scale_max = 1.0
	auto_vacuum_particles.process_material = particle_material
	var particle_quad := QuadMesh.new()
	particle_quad.size = Vector2(0.075, 0.075)
	var particle_draw_material := StandardMaterial3D.new()
	particle_draw_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	particle_draw_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	particle_draw_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	particle_draw_material.albedo_color = Color(0.45, 0.92, 1.0, 0.68)
	particle_draw_material.emission_enabled = true
	particle_draw_material.emission = Color("#65dff5")
	particle_quad.material = particle_draw_material
	auto_vacuum_particles.draw_pass_1 = particle_quad
	auto_opener_root.add_child(auto_vacuum_particles)

func robot_material(color: Color, glow := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.52
	material.metallic = 0.30
	material.emission_enabled = glow
	if glow: material.emission = color * 0.65
	return material

func is_pointer_over_grabber_panel(mouse_pos: Vector2) -> bool:
	if not auto_grabber_owned or not is_instance_valid(auto_grabber_panel_root): return false
	var panel_screen := camera.unproject_position(auto_grabber_panel_root.global_position + Vector3(0, 0.25, 0))
	return mouse_pos.distance_to(panel_screen) <= 88.0

func begin_auto_grabber_hold() -> void:
	auto_grabber_holding = true
	pointer_mode = "grabber_hold"
	if is_instance_valid(auto_vacuum_particles): auto_vacuum_particles.emitting = true
	toast("吸尘器已开启：保持按住，桌面上的未拆盲盒会持续靠近开盒机。")

func update_auto_grabber(delta: float) -> void:
	update_auto_intake_zone()
	if not auto_grabber_holding or not auto_grabber_owned or not is_instance_valid(auto_opener_root):
		if is_instance_valid(auto_vacuum_particles): auto_vacuum_particles.emitting = false
		return
	if is_instance_valid(auto_vacuum_particles): auto_vacuum_particles.emitting = true
	var target := auto_opener_root.to_global(AUTO_INTAKE_LOCAL_CENTER + Vector3(0, 0.42, 0))
	var target_speed := AUTO_VACUUM_BASE_SPEED * (1.0 + auto_grabber_speed_level * 0.10)
	var response := 1.65 * (1.0 + auto_grabber_count_level * 0.15)
	for box in boxes:
		if not is_vacuum_box_candidate(box): continue
		var offset: Vector3 = target - box.global_position
		offset.y = clampf(offset.y, -0.08, 0.32)
		if offset.length_squared() <= 0.01: continue
		box.freeze = false
		box.sleeping = false
		var desired_velocity := offset.normalized() * minf(target_speed, 0.65 + offset.length() * 0.38)
		box.linear_velocity = box.linear_velocity.lerp(desired_velocity, minf(delta * response, 1.0))
		box.angular_velocity = box.angular_velocity.lerp(Vector3.ZERO, minf(delta * 2.4, 1.0))

func is_vacuum_box_candidate(box: RigidBody3D) -> bool:
	if not is_instance_valid(box) or box.box_kind != "blind" or box.opened: return false
	if box == focused_box or box == table_drag_box: return false
	return not box.get_meta("auto_basket", false) and not box.get_meta("auto_processing", false) and not box.get_meta("auto_processed", false)

func update_auto_opener(delta: float) -> void:
	if not auto_opener_owned or not is_instance_valid(auto_opener_root): return
	for index in range(auto_basket_boxes.size() - 1, -1, -1):
		if not is_instance_valid(auto_basket_boxes[index]): auto_basket_boxes.remove_at(index)
	for index in range(auto_processed_boxes.size() - 1, -1, -1):
		if not is_instance_valid(auto_processed_boxes[index]): auto_processed_boxes.remove_at(index)
	if is_instance_valid(auto_processing_box):
		auto_processing_elapsed += delta
		var cycle := auto_processing_elapsed / auto_opener_cycle_time()
		var arm_swing := sin(cycle * TAU * 4.0) * 0.58
		auto_left_arm.rotation.x = -0.38 + arm_swing
		auto_right_arm.rotation.x = -0.38 - arm_swing
		if auto_processing_elapsed >= auto_opener_cycle_time(): complete_auto_opening()
		return
	auto_left_arm.rotation.x = lerpf(auto_left_arm.rotation.x, 0.0, minf(delta * 7.0, 1.0))
	auto_right_arm.rotation.x = lerpf(auto_right_arm.rotation.x, 0.0, minf(delta * 7.0, 1.0))
	if auto_basket_boxes.is_empty(): return
	var next_box: RigidBody3D = auto_basket_boxes.pop_front()
	restack_auto_basket_boxes()
	start_auto_opening(next_box)

func auto_opener_cycle_time() -> float:
	return AUTO_OPENER_BASE_TIME / (1.0 + auto_opener_speed_level * 0.10)

func start_auto_opening(box: RigidBody3D) -> void:
	auto_processing_box = box
	auto_processing_elapsed = 0.0
	box.remove_meta("auto_basket")
	box.set_meta("auto_processing", true)
	box.freeze = true
	box.linear_velocity = Vector3.ZERO
	box.angular_velocity = Vector3.ZERO
	var work_position := auto_opener_root.to_global(Vector3(0, 0.62, 1.05))
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(box, "global_position", work_position, 0.45)
	tween.tween_property(box, "rotation", Vector3.ZERO, 0.45)
	tween.tween_property(box, "scale", Vector3.ONE * 0.72, 0.45)
	toast("机械臂从头顶篮子取出一个盲盒，正在处理。")
	refresh_item_shop()

func complete_auto_opening() -> void:
	if not is_instance_valid(auto_processing_box):
		auto_processing_box = null
		return
	var box := auto_processing_box
	auto_processing_box = null
	auto_processing_elapsed = 0.0
	box.remove_meta("auto_processing")
	box.set_meta("auto_processed", true)
	box.tear_seal()
	box.finish_open_lid()
	box.mark_empty()
	box.label_3d.text = "点击结算"
	box.freeze = true
	box.scale = Vector3.ONE * 0.48
	auto_processed_boxes.append(box)
	restack_auto_processed_boxes()
	toast("自动开盒完成。点击机器人前方堆叠的盒子查看并结算内容物。")
	refresh_item_shop()

func restack_auto_processed_boxes() -> void:
	for index in auto_processed_boxes.size():
		var box := auto_processed_boxes[index]
		if not is_instance_valid(box): continue
		var column := index % 3
		var layer := index / 3
		box.global_position = auto_opener_root.to_global(Vector3((column - 1) * 0.48, 0.18 + layer * 0.34, 1.58 - layer * 0.02))
		box.rotation = Vector3(0, 0.08 * (column - 1), 0)

func settle_auto_processed_box(box: RigidBody3D) -> void:
	if review_item or focused_box or opening_sequence:
		toast("请先完成当前查看流程，再结算自动开盒结果。")
		return
	auto_processed_boxes.erase(box)
	auto_processed_boxes.push_front(box)
	auto_settlement_active = true
	settle_next_auto_processed_box()

func settle_next_auto_processed_box() -> void:
	if review_item or focused_box or opening_sequence: return
	while not auto_processed_boxes.is_empty() and not is_instance_valid(auto_processed_boxes[0]):
		auto_processed_boxes.pop_front()
	if auto_processed_boxes.is_empty():
		auto_settlement_active = false
		restack_auto_processed_boxes()
		refresh_item_shop()
		toast("自动开盒机当前所有完成结果已经结算完毕。")
		return
	var box: RigidBody3D = auto_processed_boxes.pop_front()
	box.remove_meta("auto_processed")
	restack_auto_processed_boxes()
	focused_box = box
	set_focus_depth_of_field(true)
	begin_content_review()
	refresh_item_shop()

func build_upgrade_panel(canvas: CanvasLayer) -> void:
	var panel := PanelContainer.new()
	panel.name = "UpgradePanel"
	panel.position = Vector2(1080, 74)
	panel.size = Vector2(182, 330)
	panel.add_theme_stylebox_override("panel", command_style())
	canvas.add_child(panel)
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = 148
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)
	col.add_child(make_label("UPGRADE 01 · 整体幸运", 12, UI_NAV_GOLD, true))
	luck_level_label = make_label("", 11, UI_CANVAS_SOFT, true)
	col.add_child(luck_level_label)
	luck_button = button("整体升级 ▶", UI_AMBER)
	luck_button.custom_minimum_size.y = 32
	luck_button.add_theme_font_size_override("font_size", 11)
	luck_button.pressed.connect(upgrade_luck)
	col.add_child(luck_button)
	col.add_child(line())
	col.add_child(make_label("UPGRADE 02 · 摇盒次数", 12, UI_NAV_GOLD, true))
	shake_level_label = make_label("", 11, UI_CANVAS_SOFT)
	col.add_child(shake_level_label)
	shake_button = button("升级摇盒次数 ▶", UI_AMBER)
	shake_button.custom_minimum_size.y = 32
	shake_button.add_theme_font_size_override("font_size", 11)
	shake_button.pressed.connect(upgrade_shake)
	col.add_child(shake_button)
	col.add_child(line())
	col.add_child(make_label("UPGRADE 03 · 撕封技巧", 12, UI_NAV_GOLD, true))
	tear_skill_level_label = make_label("", 11, UI_CANVAS_SOFT)
	col.add_child(tear_skill_level_label)
	tear_skill_button = button("练习撕封技巧 ▶", UI_AMBER)
	tear_skill_button.custom_minimum_size.y = 32
	tear_skill_button.add_theme_font_size_override("font_size", 11)
	tear_skill_button.pressed.connect(upgrade_tear_skill)
	col.add_child(tear_skill_button)

func build_developer_panel(canvas: CanvasLayer) -> void:
	developer_panel = PanelContainer.new()
	developer_panel.name = "DeveloperPanel"
	developer_panel.position = Vector2(1010, 510)
	developer_panel.size = Vector2(252, 192)
	developer_panel.add_theme_stylebox_override("panel", command_style(UI_PRIMARY))
	canvas.add_child(developer_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	developer_panel.add_child(col)
	var title := make_label("DEBUG SYSTEM / 开发者模式", 12, UI_NAV_GOLD, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var cash_button := button("现金 → ¥%s" % comma(DEVELOPER_CASH), UI_AMBER)
	cash_button.name = "MaxCashButton"
	cash_button.custom_minimum_size.y = 34
	cash_button.add_theme_font_size_override("font_size", 12)
	cash_button.pressed.connect(developer_grant_cash)
	col.add_child(cash_button)
	var unlock_button := button("解锁全部盲盒 ▶", UI_AMBER)
	unlock_button.name = "UnlockAllButton"
	unlock_button.custom_minimum_size.y = 34
	unlock_button.add_theme_font_size_override("font_size", 12)
	unlock_button.pressed.connect(developer_unlock_all_series)
	col.add_child(unlock_button)
	var skills_button := button("全部技能满级 ▶", UI_AMBER)
	skills_button.name = "MaxSkillsButton"
	skills_button.custom_minimum_size.y = 34
	skills_button.add_theme_font_size_override("font_size", 12)
	skills_button.pressed.connect(developer_max_all_skills)
	col.add_child(skills_button)
	developer_toggle_button = button("▶", UI_SIGNAL)
	developer_toggle_button.name = "DeveloperToggleButton"
	developer_toggle_button.position = Vector2(1236, 510)
	developer_toggle_button.size = Vector2(26, 48)
	developer_toggle_button.custom_minimum_size = Vector2(26, 48)
	developer_toggle_button.add_theme_font_size_override("font_size", 16)
	developer_toggle_button.tooltip_text = "隐藏开发者模式"
	developer_toggle_button.pressed.connect(toggle_developer_panel)
	canvas.add_child(developer_toggle_button)

func toggle_developer_panel() -> void:
	developer_panel_hidden = not developer_panel_hidden
	if developer_panel_tween and developer_panel_tween.is_valid(): developer_panel_tween.kill()
	developer_panel_tween = create_tween()
	developer_panel_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	developer_panel_tween.tween_property(developer_panel, "position:x", 1288.0 if developer_panel_hidden else 1010.0, 0.30)
	developer_toggle_button.text = "◀" if developer_panel_hidden else "▶"
	developer_toggle_button.tooltip_text = "展开开发者模式" if developer_panel_hidden else "隐藏开发者模式"

func developer_grant_cash() -> void:
	cash = DEVELOPER_CASH
	refresh_ui()
	toast("开发者模式：现金已设为 ¥%s。" % comma(cash))

func developer_unlock_all_series() -> void:
	earned = maxi(earned, int(SERIES[-1]["unlock"]))
	refresh_ui()
	toast("开发者模式：所有盲盒系列已解锁。")

func developer_max_all_skills() -> void:
	global_luck_level = GLOBAL_LUCK_COSTS.size()
	shake_upgrade_level = SHAKE_UPGRADE_COSTS.size()
	tear_skill_level = TEAR_SKILL_UPGRADE_COSTS.size()
	auto_opener_speed_level = AUTO_UPGRADE_MAX_LEVEL
	auto_opener_capacity = 5 + AUTO_UPGRADE_MAX_LEVEL * 5
	auto_grabber_speed_level = AUTO_UPGRADE_MAX_LEVEL
	auto_grabber_count_level = AUTO_UPGRADE_MAX_LEVEL
	refresh_ui()
	toast("开发者模式：所有基础技能与自动化升级均已满级。")

func side_panel(canvas: CanvasLayer, title_text: String, height: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(888, 285)
	panel.size = Vector2(374, height)
	panel.visible = false
	panel.add_theme_stylebox_override("panel", chrome_style(UI_CANVAS))
	canvas.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	var title := make_label(title_text.to_upper(), 18, UI_INK, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := button("×", UI_CARBON)
	close.custom_minimum_size.x = 42
	close.pressed.connect(func(): panel.visible = false)
	head.add_child(close)
	return panel

func build_market_panel(canvas: CanvasLayer) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(320, 72)
	panel.size = Vector2(850, 610)
	panel.visible = false
	panel.add_theme_stylebox_override("panel", chrome_style(UI_CANVAS))
	canvas.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	var title := make_label("MARKET DATABASE / 收藏市场行情", 20, UI_INK, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := button("×", UI_CARBON)
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
	var intro := make_label("按系列查看全部内容物。点击任意图标可查看以日期为横轴、市价为纵轴的历史曲线。", 12, UI_INK)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	market_content.add_child(intro)
	for s in SERIES.size():
		var group := PanelContainer.new()
		group.add_theme_stylebox_override("panel", inset_style(UI_PLATINUM, SERIES[s]["color"]))
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
	var back := button("◀ 返回系列陈列", UI_CARBON)
	back.pressed.connect(show_market_overview)
	market_content.add_child(back)
	var rarity: int = SERIES[series_index]["rarities"][item_index]
	var item_name: String = SERIES[series_index]["items"][item_index]
	market_content.add_child(make_label("%s · %s · %s" % [SERIES[series_index]["name"], RARITIES[rarity], item_name], 22, RARITY_COLORS[rarity], true))
	var current_market := market_price_at_day(series_index, item_index, day)
	market_content.add_child(make_label("第 %d 天市场价：¥%s  ·  熟练度后的实际售价：¥%s" % [day, comma(current_market), comma(collectible_price(series_index, item_index))], 13, UI_INK))
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
	panel.add_theme_stylebox_override("panel", command_style())
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
	var slogan := make_label(SERIES[series_index]["slogan"], 12, UI_CANVAS_SOFT)
	slogan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loot_preview_list.add_child(slogan)
	var catalog_summary := "共 %d 款可开内容物" % SERIES[series_index]["items"].size()
	loot_preview_list.add_child(make_label(catalog_summary, 11, UI_AMBER, true))
	if inspected_box:
		var allowed := shake_limit_for_box(inspected_box)
		var shake_info := make_label("摇盒机会 %d / %d  ·  每次排除一个错误候选" % [inspected_box.shake_count, allowed], 11, UI_AMBER, true)
		shake_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		loot_preview_list.add_child(shake_info)
	loot_preview_list.add_child(line())
	for item_index in SERIES[series_index]["items"].size():
		var rarity: int = SERIES[series_index]["rarities"][item_index]
		var eliminated: bool = inspected_box != null and item_index in inspected_box.shake_eliminated
		var row := PanelContainer.new()
		row.custom_minimum_size.y = 58
		row.add_theme_stylebox_override("panel", inset_style(Color("#e4c9cd") if eliminated else UI_PLATINUM, Color("#b9575f") if eliminated else RARITY_COLORS[rarity]))
		loot_preview_list.add_child(row)
		var hbox := HBoxContainer.new()
		row.add_child(hbox)
		var prefix := "✕  已排除 · " if eliminated else ""
		var item_label := make_label("%s%s · %s\n概率 %s  ·  市价 ¥%s" % [prefix, RARITIES[rarity], SERIES[series_index]["items"][item_index], item_probability_text(series_index, item_index), comma(collectible_price(series_index, item_index))], 12, Color("#9d3441") if eliminated else UI_INK, true)
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
	toast("购买成功。点击盲盒可摇盒判断；重复内容物可在“扭扭”按当前市价六折处理。")
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
	if is_pointer_over_grabber_panel(mouse_pos):
		begin_auto_grabber_hold()
		return
	var hit := ray_hit(mouse_pos, false)
	var box := box_from_collider(hit.collider if hit else null)
	if box:
		if box.get_meta("auto_processed", false):
			settle_auto_processed_box(box)
			return
		if box.get_meta("auto_basket", false):
			toast("这个盲盒已经投入自动开盒篮，无法再取出。")
			return
		if box.get_meta("auto_processing", false):
			toast("双机械臂正在处理这个盲盒，请等待它进入待结算盒堆。")
			return
		click_candidate = box
		if box.opened or box.box_kind == "blind":
			table_drag_box = box
			table_drag_box.freeze = true
			table_drag_moved = false
			pointer_mode = "table_drag"

func on_pointer_move(event: InputEventMouseMotion) -> void:
	if pointer_mode == "review_rotate" and review_item:
		review_item.rotate_object_local(COLLECTIBLE_UP_AXIS, event.relative.x * 0.012)
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
		var point: Variant = Plane(Vector3.UP, TABLE_DRAG_HEIGHT).intersects_ray(origin, direction)
		if point != null: table_drag_box.global_position = point

func on_pointer_up(mouse_pos: Vector2) -> void:
	if pointer_mode == "grabber_hold":
		auto_grabber_holding = false
		if is_instance_valid(auto_vacuum_particles): auto_vacuum_particles.emitting = false
		pointer_mode = ""
		toast("红色按钮已松开，吸尘器停止。盲盒保留当前位置和惯性。")
		return
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
		if not table_drag_box.opened and table_drag_box.box_kind == "blind" and is_in_auto_intake_zone(table_drag_box.global_position):
			var box_to_enqueue := table_drag_box
			table_drag_box = null
			click_candidate = null
			pointer_mode = ""
			if enqueue_auto_opener_box(box_to_enqueue): return
			table_drag_box = box_to_enqueue
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
	if box.box_kind == "parcel":
		return base_chance * lerpf(1.0, PARCEL_MIN_DETACH_MULTIPLIER, tear_skill_progress_for_box(box))
	return lerpf(base_chance, SERIES_MIN_DETACH_CHANCE, tear_skill_progress_for_box(box))

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
	if focused_box.shake_count < shake_limit_for_box(focused_box) and not shake_result_triggered and shake_distance >= SERIES_SHAKE_TRAVEL[focused_box.series_index] and shake_reversals >= SERIES_SHAKE_REVERSALS[focused_box.series_index]:
		perform_box_shake()

func perform_box_shake() -> void:
	if not focused_box or pointer_mode != "shake" or shake_result_triggered: return
	if focused_box.shake_count >= shake_limit_for_box(focused_box): return
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
	shake_distance = 0.0
	shake_reversals = 0
	shake_last_direction = 0
	shake_result_triggered = false
	if focused_box.shake_count >= shake_limit_for_box(focused_box):
		toast("已连续排除一个错误候选；这只盲盒的摇盒次数已经用完，松手后盒体回中。")
	else:
		toast("已连续排除一个错误候选；保持按住并继续往返摇动，可直接累计下一次结果。")

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
	var payout := maxi(1, int(round(box_price(box.series_index) * 0.6)))
	var sale_position := secondhand_bin.global_position + Vector3(0, 0.7, 0)
	cash += payout
	earned += payout
	boxes.erase(box)
	box.queue_free()
	show_income_popup(payout, sale_position)
	toast("未拆盲盒已卖给扭扭二手市场，按当前市价六折到账 ¥%s。" % comma(payout))
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
	detail_title.add_theme_color_override("font_color", UI_CHROME_INDIGO)
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
	toast("纸箱压扁完成，立即回收结算 +¥%s。" % comma(payout))
	refresh_ui()

func begin_content_review() -> void:
	if not focused_box or focused_box.box_kind != "blind": return
	var box := focused_box
	var series_index: int = box.series_index
	var rarity: int = box.rarity
	var item_index: int = box.item_index
	var item_name: String = SERIES[series_index]["items"][item_index]
	var discovery_key := "%d_%d" % [series_index, item_index]
	var is_new_discovery := not discovered.has(discovery_key)
	pending_item = {"series":series_index, "item_index":item_index, "rarity":rarity, "name":item_name}
	series_open_counts[series_index] += 1
	update_proficiency_level(series_index)
	register_discovery(pending_item)
	boxes.erase(box)
	focused_box = null
	loot_preview_panel.visible = false
	_shrink_opened_blind_box(box)
	review_animation_playing = true
	review_item = Node3D.new()
	add_child(review_item)
	var box_reveal_position: Vector3 = box.global_position
	# 摆件从盒体的屏幕上方且更靠近相机的位置起跳，确保盒体不再压在出货层上。
	var start_position := box_reveal_position + camera.global_basis.y * 0.30 + camera.global_basis.z * 0.24
	var impact_position := review_layer_position(REVIEW_ITEM_CAMERA_DISTANCE)
	var screen_pop_position := review_layer_position(2.18)
	# 内容物统一以本地 -Y 为正面、本地 +Z 为上方；弹出、回落全过程都沿相机视线移动，
	# 因此在起点建立一次面向玩家的基矩阵即可始终保持正面朝向。
	review_item.global_transform = Transform3D(collectible_front_facing_basis(start_position), start_position)
	review_item.scale = Vector3.ONE * (0.18 * REVIEW_MODEL_SCALE_MULTIPLIER)
	review_glow = create_reveal_burst(rarity)
	add_child(review_glow)
	# VFX 固定在摆件后方的独立景深层，避免放大的模型与 spritesheet 平面穿插。
	var reveal_vfx_position := review_layer_position(REVIEW_VFX_CAMERA_DISTANCE)
	review_glow.global_transform = Transform3D(camera.global_basis, reveal_vfx_position)
	review_glow.visible = true
	_refresh_review_inventory_count()
	_clear_new_discovery_badge()
	if is_new_discovery: _show_new_discovery_feedback()
	var silhouette_material := StandardMaterial3D.new()
	silhouette_material.albedo_color = Color("#050609")
	silhouette_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	silhouette_material.roughness = 0.5
	var imported_meshes: Array[MeshInstance3D] = []
	var collectible_model := instantiate_collectible_model(series_index, item_index, true)
	if collectible_model:
		review_item.add_child(collectible_model)
		for child in collectible_model.find_children("*", "MeshInstance3D", true, false):
			var mesh_instance := child as MeshInstance3D
			mesh_instance.material_override = silhouette_material
			imported_meshes.append(mesh_instance)
	else:
		var shape := CSGSphere3D.new()
		shape.radius = 0.44 + rarity * 0.025
		shape.radial_segments = 20
		shape.rings = 10
		shape.material = silhouette_material
		review_item.add_child(shape)
		var accent := CSGTorus3D.new()
		accent.inner_radius = 0.40
		accent.outer_radius = 0.49
		accent.rotation.x = PI / 2.0
		accent.material = silhouette_material
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
	pop_tween.tween_property(review_item, "scale", Vector3.ONE * (1.12 * REVIEW_MODEL_SCALE_MULTIPLIER), 0.28)
	await pop_tween.finished

	# Then pull back rapidly and hit the center with a short, weighty rebound.
	var land_tween := create_tween().set_parallel(true)
	land_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	land_tween.tween_property(review_item, "global_position", impact_position, 0.40)
	land_tween.tween_property(review_item, "scale", Vector3.ONE * (0.78 * REVIEW_MODEL_SCALE_MULTIPLIER), 0.40)
	await land_tween.finished
	var settle_tween := create_tween()
	settle_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	settle_tween.tween_property(review_item, "scale", Vector3.ONE * (0.84 * REVIEW_MODEL_SCALE_MULTIPLIER), 0.18)
	await settle_tween.finished

	# 落定时只恢复模型本色；开出 spritesheet 已在开盒瞬间播放，
	# 并会自动过渡为逐渐放大、循环播放的待机背景。
	if imported_meshes.is_empty():
		silhouette_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		silhouette_material.albedo_color = RARITY_COLORS[rarity]
		silhouette_material.emission_enabled = rarity >= 1
		silhouette_material.emission = REVEAL_EFFECT_COLORS[rarity] * (0.20 + rarity * 0.09)
	else:
		for mesh_instance in imported_meshes:
			if is_instance_valid(mesh_instance): mesh_instance.material_override = null
	detail_title.text = "%s · %s" % [RARITIES[rarity], item_name]
	detail_title.add_theme_color_override("font_color", review_title_color(rarity))
	detail_hint.text = review_detail_text(series_index)
	action_row.visible = true
	sell_button.disabled = false
	review_animation_playing = false
	toast("内容物落定。查看后选择直接出售或保留库存。")


func _shrink_opened_blind_box(box: RigidBody3D) -> void:
	if not is_instance_valid(box): return
	box.freeze = true
	box.collision_layer = 0
	box.collision_mask = 0
	var start_scale := box.scale
	var shrink := create_tween()
	shrink.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	shrink.tween_property(box, "scale", start_scale * OPENED_BOX_FINAL_SCALE, OPENED_BOX_SHRINK_DURATION)
	await shrink.finished
	if is_instance_valid(box): box.queue_free()


func inventory_same_item_count(item: Dictionary) -> int:
	var count := 0
	for stored_item in collectibles:
		if stored_item.has("combination_id"): continue
		if int(stored_item.get("series", -1)) == int(item.get("series", -2)) and int(stored_item.get("item_index", -1)) == int(item.get("item_index", -2)):
			count += 1
	return count


func _refresh_review_inventory_count() -> void:
	if keep_button == null: return
	keep_button.text = "计入库存（同款 %d）" % inventory_same_item_count(pending_item)


func _show_new_discovery_feedback() -> void:
	if not ui_canvas: return
	var viewport_size := get_viewport().get_visible_rect().size
	var side_texture := load(NEW_DISCOVERY_SIDE_VFX_PATH) as Texture2D
	if side_texture:
		var side_vfx = SCREEN_SPRITESHEET_VFX.new()
		side_vfx.name = "NewDiscoverySideConfettiVFX"
		side_vfx.position = viewport_size * 0.5
		var frame_size := Vector2(float(side_texture.get_width()) / 8.0, float(side_texture.get_height()) / 8.0)
		# 非等比拉伸到可视窗口的完整宽高，不留黑边或空白区。
		side_vfx.scale = Vector2(viewport_size.x / frame_size.x, viewport_size.y / frame_size.y)
		side_vfx.z_index = 500
		ui_canvas.add_child(side_vfx)
		side_vfx.configure(side_texture, 48.0, true)
	review_new_badge = Label.new()
	review_new_badge.name = "NewDiscoveryBadge"
	review_new_badge.text = "NEW!"
	review_new_badge.position = viewport_size * 0.5 + Vector2(105.0, -165.0)
	review_new_badge.size = Vector2(170.0, 76.0)
	review_new_badge.pivot_offset = review_new_badge.size * 0.5
	review_new_badge.rotation = deg_to_rad(-9.0)
	review_new_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	review_new_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	review_new_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	review_new_badge.z_index = 600
	review_new_badge.add_theme_font_size_override("font_size", 46)
	review_new_badge.add_theme_color_override("font_color", Color("#ef2538"))
	review_new_badge.add_theme_color_override("font_outline_color", Color("#fff7e8"))
	review_new_badge.add_theme_constant_override("outline_size", 8)
	review_new_badge.scale = Vector2.ONE * 0.05
	ui_canvas.add_child(review_new_badge)
	var badge_pop := create_tween()
	badge_pop.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	badge_pop.tween_property(review_new_badge, "scale", Vector2.ONE, 0.34)


func _clear_new_discovery_badge() -> void:
	if review_new_badge and is_instance_valid(review_new_badge): review_new_badge.queue_free()
	review_new_badge = null

func collectible_front_facing_basis(world_position: Vector3) -> Basis:
	var front_direction := (camera.global_position - world_position).normalized()
	if front_direction.is_zero_approx(): front_direction = camera.global_basis.z.normalized()
	var reference_up := camera.global_basis.y.normalized()
	if absf(reference_up.dot(front_direction)) > 0.999: reference_up = Vector3.UP
	var right_direction := reference_up.cross(front_direction).normalized()
	var up_direction := front_direction.cross(right_direction).normalized()
	# Basis 第二列是本地 +Y、第三列是本地 +Z：令 -Y 指向玩家、+Z 指向屏幕上方。
	return Basis(right_direction, -front_direction, up_direction).orthonormalized()


func review_title_color(rarity: int) -> Color:
	if rarity == 4: return REVIEW_TITLE_SMALL_HIDDEN_COLOR
	if rarity == 5: return REVIEW_TITLE_BIG_HIDDEN_COLOR
	return UI_INK


func review_detail_text(series_index: int) -> String:
	return "所属：%s\n按住物品可自由旋转查看" % SERIES[series_index]["name"]

func instantiate_collectible_model(series_index: int, item_index: int, focused_preview := false) -> Node3D:
	if series_index < 0 or series_index >= COLLECTIBLE_MODEL_PATHS.size(): return null
	var series_paths: Array = COLLECTIBLE_MODEL_PATHS[series_index]
	if item_index < 0 or item_index >= series_paths.size(): return null
	var path := String(series_paths[item_index])
	if path.is_empty(): return null
	if not collectible_model_cache.has(path):
		var resource := load(path) as PackedScene
		if resource == null:
			push_warning("内容物 FBX 无法加载：%s" % path)
			return null
		collectible_model_cache[path] = resource
	var packed_scene := collectible_model_cache[path] as PackedScene
	var asset := packed_scene.instantiate() as Node3D
	if asset == null: return null
	var display_root := Node3D.new()
	display_root.name = "CollectibleModel_NegativeYFront"
	display_root.add_child(asset)
	var bounds_data := collectible_model_bounds(asset)
	if not bool(bounds_data["valid"]): return display_root
	var source_bounds: AABB = bounds_data["bounds"]
	# 六向渲染实测：FBX 的有脸正面是原始 +Z，头顶方向是原始 +Y。
	# 绕本地 +X 旋转 +90°，将原始 +Z（脸）映射到统一 -Y 正面，
	# 同时将原始 +Y（头顶）映射到统一 +Z 上方。
	var correction_basis := Basis(Vector3.RIGHT, PI / 2.0)
	if series_index == 0 and focused_preview:
		# 先让脸部正对镜头，再以“袋鼠-骑士”的正确朝向为基准向左偏转 25°。
		correction_basis = Basis(COLLECTIBLE_UP_AXIS, FAT_PARTNER_REVIEW_YAW) * correction_basis
	var axis_correction := Transform3D(correction_basis, Vector3.ZERO)
	var corrected_bounds: AABB = axis_correction * source_bounds
	var largest_dimension := maxf(corrected_bounds.size.x, maxf(corrected_bounds.size.y, corrected_bounds.size.z))
	var uniform_scale := COLLECTIBLE_MODEL_TARGET_SIZE / maxf(largest_dimension, 0.001)
	asset.basis = correction_basis.scaled(Vector3.ONE * uniform_scale)
	asset.position = -corrected_bounds.get_center() * uniform_scale
	return display_root

func collectible_model_bounds(root: Node) -> Dictionary:
	var accumulator := {"valid":false, "bounds":AABB()}
	accumulate_collectible_model_bounds(root, Transform3D.IDENTITY, accumulator)
	return accumulator

func accumulate_collectible_model_bounds(node: Node, parent_transform: Transform3D, accumulator: Dictionary) -> void:
	var current_transform := parent_transform
	if node is Node3D: current_transform = parent_transform * (node as Node3D).transform
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh:
			var transformed_bounds: AABB = current_transform * mesh_instance.mesh.get_aabb()
			if bool(accumulator["valid"]): accumulator["bounds"] = (accumulator["bounds"] as AABB).merge(transformed_bounds)
			else:
				accumulator["bounds"] = transformed_bounds
				accumulator["valid"] = true
	for child in node.get_children(): accumulate_collectible_model_bounds(child, current_transform, accumulator)

func create_reveal_burst(rarity: int) -> Node3D:
	var category := "big_hidden" if rarity == 5 else ("small_hidden" if rarity == 4 else "regular")
	var opening_texture := load(String(REVEAL_OPEN_VFX_PATHS[category])) as Texture2D
	var standby_texture := load(String(REVEAL_IDLE_VFX_PATHS[category])) as Texture2D
	var effect := REVEAL_SPRITESHEET_VFX.new()
	effect.name = "RevealSpritesheetVFX_%s" % category
	# 开出与待机背景保持同一尺寸；当前为上一版的 2 倍。
	var target_world_size := 2.0 * 3.5 * tan(deg_to_rad(camera.fov * 0.5)) * REVEAL_VFX_SCREEN_FRACTION
	effect.configure(opening_texture, standby_texture, target_world_size)
	return effect


func review_layer_position(camera_distance: float) -> Vector3:
	# 纵向位移随景深同比例放大，使摆件和更远处的 VFX 投影到同一个
	# 屏幕中心；两层整体上移，同时仍保留清晰的前后间距。
	var depth_scaled_offset := REVIEW_VERTICAL_OFFSET * camera_distance / REVIEW_ITEM_CAMERA_DISTANCE
	return camera.global_position - camera.global_basis.z * camera_distance + camera.global_basis.y * depth_scaled_offset


func play_world_spritesheet_vfx(sheet_path: String, world_position: Vector3, screen_fraction := 0.18, fps := 36.0) -> Sprite3D:
	var texture := load(sheet_path) as Texture2D
	if texture == null: return null
	var effect = WORLD_SPRITESHEET_VFX.new()
	effect.name = "WorldSpritesheetVFX_%s" % sheet_path.get_file().get_basename()
	add_child(effect)
	var distance := maxf(camera.global_position.distance_to(world_position), 0.5)
	var target_world_size := 2.0 * distance * tan(deg_to_rad(camera.fov * 0.5)) * screen_fraction
	effect.global_transform = Transform3D(camera.global_basis, world_position)
	effect.configure(texture, target_world_size, fps, false, true)
	return effect

func resolve_review(sell_now: bool) -> void:
	if review_animation_playing or not review_item or pending_item.is_empty(): return
	if sell_now:
		var price := collectible_price(pending_item["series"], pending_item["item_index"])
		cash += price
		earned += price
		toast("藏品出售，到账 ¥%s。" % comma(price))
	else:
		var completed_combinations := add_collectible_to_inventory(pending_item)
		if completed_combinations.is_empty():
			toast("藏品已保留在库存。")
		else:
			toast("配对隐藏款已自动合成：%s！" % "、".join(completed_combinations))
	review_item.queue_free()
	review_item = null
	if review_glow:
		review_glow.queue_free()
		review_glow = null
	_clear_new_discovery_badge()
	pending_item.clear()
	set_focus_depth_of_field(false)
	detail_panel.visible = false
	action_row.visible = false
	pointer_mode = ""
	refresh_ui()
	if auto_settlement_active:
		call_deferred("settle_next_auto_processed_box")

func add_collectible_to_inventory(item: Dictionary) -> Array[String]:
	collectibles.append(item.duplicate(true))
	return resolve_available_combinations()

func resolve_available_combinations() -> Array[String]:
	var completed: Array[String] = []
	for definition in COMBINATION_COLLECTIBLES:
		while true:
			var component_indices: Array[int] = []
			for component_index in definition["components"]:
				var inventory_index := find_component_in_inventory(int(definition["series"]), int(component_index), component_indices)
				if inventory_index < 0: break
				component_indices.append(inventory_index)
			if component_indices.size() != definition["components"].size(): break
			component_indices.sort()
			component_indices.reverse()
			for inventory_index in component_indices: collectibles.remove_at(inventory_index)
			var combined_item := {
				"series":int(definition["series"]),
				"item_index":-1,
				"rarity":int(definition["rarity"]),
				"name":String(definition["name"]),
				"combination_id":String(definition["id"])
			}
			collectibles.append(combined_item)
			register_combination_discovery(definition)
			completed.append(String(definition["name"]))
	return completed

func find_component_in_inventory(series_index: int, item_index: int, excluded_indices: Array[int]) -> int:
	for inventory_index in collectibles.size():
		if inventory_index in excluded_indices: continue
		var item: Dictionary = collectibles[inventory_index]
		if item.has("combination_id"): continue
		if int(item["series"]) == series_index and int(item["item_index"]) == item_index: return inventory_index
	return -1

func register_combination_discovery(definition: Dictionary) -> void:
	var key := "combo_%s" % String(definition["id"])
	if discovered.has(key): return
	discovered[key] = true
	var bonus := maxi(1, int(SERIES[int(definition["series"])]["base"] * 0.1))
	cash += bonus
	earned += bonus

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
	var value := inventory_item_price(item)
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
	refresh_item_shop()
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
	inventory_list.add_child(section_label("STOCK STATUS / 桌面未拆盲盒 %d" % unopened_count))
	inventory_list.add_child(make_label("藏品  %d" % collectibles.size(), 17, UI_INK, true))
	inventory_list.add_child(make_label(combination_progress_text(), 11, UI_INK_SOFT))
	if collectibles.is_empty(): inventory_list.add_child(make_label("拆开盲盒并选择保留后，藏品会进入这里。", 13, UI_INK_SOFT))
	for i in collectibles.size():
		var item := collectibles[i]
		var row := PanelContainer.new()
		var item_color: Color = UI_NAV_GOLD if item.has("combination_id") else RARITY_COLORS[item["rarity"]]
		row.add_theme_stylebox_override("panel", inset_style(UI_PLATINUM, item_color))
		inventory_list.add_child(row)
		var h := HBoxContainer.new()
		row.add_child(h)
		var rarity_name: String = "组合款" if item.has("combination_id") else RARITIES[item["rarity"]]
		var label := make_label("%s · %s\n¥%s" % [rarity_name, item["name"], comma(inventory_item_price(item))], 13, item_color, true)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(label)
		var sell := button("出售 ▶", UI_SIGNAL)
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
			card.add_theme_stylebox_override("panel", inset_style(UI_PLATINUM if found else UI_CANVAS_SOFT, RARITY_COLORS[rarity] if found else UI_MUTED_INDIGO))
			collection_grid.add_child(card)
			var text := "%s\n%s" % [RARITIES[rarity], SERIES[s]["items"][item_index]] if found else "%s\n???" % RARITIES[rarity]
			var label := make_label(text, 12, UI_INK if found else UI_MUTED_INDIGO, found)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(label)
	for definition in COMBINATION_COLLECTIBLES:
		var found := discovered.has("combo_%s" % String(definition["id"]))
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(105,86)
		card.add_theme_stylebox_override("panel", inset_style(UI_PLATINUM if found else UI_CANVAS_SOFT, UI_NAV_GOLD if found else UI_MUTED_INDIGO))
		collection_grid.add_child(card)
		var text := "组合款\n%s" % String(definition["name"]) if found else "组合款\n???"
		var label := make_label(text, 12, UI_NAV_GOLD if found else UI_MUTED_INDIGO, found)
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

func inventory_item_price(item: Dictionary) -> int:
	if not item.has("combination_id"): return collectible_price(int(item["series"]), int(item["item_index"]))
	var definition := combination_definition(String(item["combination_id"]))
	if definition.is_empty(): return 0
	var series_index := int(definition["series"])
	var rarity := int(definition["rarity"])
	var market: float = FACTORS[(day - 1) % FACTORS.size()][series_index]
	var factor: float = 1.0 + (market - 1.0) * (1.0 + rarity * 0.16)
	var mastery_multiplier: float = 1.0 + series_levels[series_index] * PROFICIENCY_PRICE_BONUS
	return maxi(1, int(round(float(definition["base_value"]) * factor * mastery_multiplier)))

func combination_definition(combination_id: String) -> Dictionary:
	for definition in COMBINATION_COLLECTIBLES:
		if String(definition["id"]) == combination_id: return definition
	return {}

func market_price_at_day(series_index: int, item_index: int, date_index: int) -> int:
	var rarity: int = SERIES[series_index]["rarities"][item_index]
	var market: float = FACTORS[(date_index - 1) % FACTORS.size()][series_index]
	var factor: float = 1.0 + (market - 1.0) * (1.0 + rarity * 0.16)
	return max(1, int(round(SERIES[series_index]["values"][item_index] * factor)))

func total_inventory_value() -> int:
	var value := 0
	for box in boxes:
		if is_instance_valid(box) and box.box_kind == "blind" and not box.opened: value += int(round(box_price(box.series_index) * 0.9))
	for item in collectibles: value += inventory_item_price(item)
	return value

func combination_progress_text() -> String:
	if COMBINATION_COLLECTIBLES.is_empty():
		return "常规款等概率 · 小隐藏金色 · 大隐藏彩虹色"
	var parts: Array[String] = []
	for definition in COMBINATION_COLLECTIBLES:
		var owned_components := 0
		for component_index in definition["components"]:
			if find_component_in_inventory(int(definition["series"]), int(component_index), []) >= 0: owned_components += 1
		var short_name := String(definition["name"])
		parts.append("%s %d/%d" % [short_name, owned_components, definition["components"].size()])
	return "配对隐藏款自动合成 · %s" % " · ".join(parts)

func roll_content(series_index: int) -> int:
	var weights := item_weights_for_series(series_index)
	var total_weight := 0
	for weight in weights: total_weight += maxi(0, weight)
	if total_weight <= 0: return 0
	return content_index_for_roll(series_index, rng.randi_range(1, total_weight))

func content_index_for_roll(series_index: int, roll: int) -> int:
	var total := 0
	var weights := item_weights_for_series(series_index)
	for i in weights.size():
		total += weights[i]
		if roll <= total: return i
	return weights.size() - 1

func item_weights_for_series(series_index: int) -> Array[int]:
	var weights: Array[int] = []
	for weight in SERIES[series_index]["weights"]: weights.append(int(weight))
	return weights

func luck_keyframe_item_weights(series_index: int, keyframe_index: int) -> Array[int]:
	if keyframe_index <= 0:
		var initial: Array[int] = []
		for value in SERIES[series_index]["weights"]: initial.append(int(value))
		return initial
	if keyframe_index >= 3: return max_luck_item_weights(series_index)
	var result: Array[int] = []
	result.resize(SERIES[series_index]["items"].size())
	result.fill(0)
	var has_hidden := not item_indices_for_rarity(series_index, 5).is_empty()
	var keyframes: Array = LUCK_KEYFRAMES_WITH_HIDDEN if has_hidden else LUCK_KEYFRAMES_NO_HIDDEN
	var rarity_totals: Array = keyframes[keyframe_index]
	for order_index in LUCK_RARITY_ORDER.size():
		var indices := item_indices_for_rarity(series_index, LUCK_RARITY_ORDER[order_index])
		if not indices.is_empty(): assign_weight_total(result, series_index, indices, int(rarity_totals[order_index]))
	return result

func peak_rarity_for_item_weights(series_index: int, item_weights: Array[int]) -> int:
	var totals: Dictionary = {}
	for item_index in item_weights.size():
		var rarity := int(SERIES[series_index]["rarities"][item_index])
		totals[rarity] = int(totals.get(rarity, 0)) + item_weights[item_index]
	var peak_rarity := int(totals.keys()[0])
	for rarity in totals:
		if int(totals[rarity]) > int(totals[peak_rarity]): peak_rarity = int(rarity)
	return peak_rarity

func max_luck_item_weights(series_index: int) -> Array[int]:
	var result: Array[int] = []
	result.resize(SERIES[series_index]["items"].size())
	result.fill(0)
	var hidden_indices: Array[int] = []
	var non_hidden_rarities: Array[int] = []
	for item_index in SERIES[series_index]["items"].size():
		var rarity := int(SERIES[series_index]["rarities"][item_index])
		if rarity == 5:
			hidden_indices.append(item_index)
		elif rarity not in non_hidden_rarities:
			non_hidden_rarities.append(rarity)
	non_hidden_rarities.sort()
	var peak_rarity: int = non_hidden_rarities.pop_back()
	var peak_indices := item_indices_for_rarity(series_index, peak_rarity)
	assign_weight_total(result, series_index, peak_indices, MAX_LUCK_PEAK_TOTAL)
	var remaining_probability := MAX_LUCK_NO_HIDDEN_REMAINING_TOTAL
	if not hidden_indices.is_empty():
		assign_weight_total(result, series_index, hidden_indices, MAX_LUCK_JACKPOT_TOTAL)
		remaining_probability = MAX_LUCK_REMAINING_TOTAL
	var rank_total := non_hidden_rarities.size() * (non_hidden_rarities.size() + 1) / 2
	var remaining_used := 0
	for rank_index in non_hidden_rarities.size():
		var group_total := remaining_probability - remaining_used if rank_index == non_hidden_rarities.size() - 1 else int(round(float(remaining_probability) * float(rank_index + 1) / float(rank_total)))
		remaining_used += group_total
		assign_weight_total(result, series_index, item_indices_for_rarity(series_index, non_hidden_rarities[rank_index]), group_total)
	return result

func item_indices_for_rarity(series_index: int, rarity: int) -> Array[int]:
	var indices: Array[int] = []
	for item_index in SERIES[series_index]["items"].size():
		if int(SERIES[series_index]["rarities"][item_index]) == rarity: indices.append(item_index)
	return indices

func assign_weight_total(result: Array[int], series_index: int, indices: Array[int], total_weight: int) -> void:
	var base_total := 0
	for item_index in indices: base_total += int(SERIES[series_index]["weights"][item_index])
	var used := 0
	for position in indices.size():
		var assigned := total_weight - used if position == indices.size() - 1 else int(round(float(total_weight) * float(SERIES[series_index]["weights"][indices[position]]) / float(base_total)))
		result[indices[position]] = assigned
		used += assigned

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
	var total_weight := 0
	for weight in weights: total_weight += weight
	var parts: Array[String] = []
	for weight in weights:
		parts.append(probability_text_for_weight(weight, total_weight))
	return " / ".join(parts)

func rarity_probability_text(series_index: int, rarity: int) -> String:
	var weights := weights_for_series(series_index)
	var total_weight := 0
	for value in weights: total_weight += value
	return probability_text_for_weight(weights[rarity], total_weight)

func item_probability_text(series_index: int, item_index: int) -> String:
	var weights := item_weights_for_series(series_index)
	var total_weight := 0
	for value in weights: total_weight += value
	return probability_text_for_weight(weights[item_index], total_weight, 2)

func probability_text_for_weight(weight: int, total_weight: int, decimals := 1) -> String:
	if total_weight <= 0: return "0%"
	var percent := float(weight) * 100.0 / float(total_weight)
	if is_equal_approx(percent, round(percent)): return "%d%%" % int(round(percent))
	return ("%%.%df%%%%" % decimals) % percent

func total_collectible_definitions() -> int:
	var total := COMBINATION_COLLECTIBLES.size()
	for series in SERIES: total += series["items"].size()
	return total

func toast(text_value: String) -> void: toast_label.text = text_value

func make_shop_card(title_text: String, detail_text: String, color: Color) -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", inset_style(UI_PLATINUM, color.darkened(0.18)))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	panel.add_child(col)
	var title := make_label(title_text, 13, UI_INK, true)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(title)
	var detail := make_label(detail_text, 10, UI_INK_SOFT)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(detail)
	var buy := button("购买 ▶", UI_AMBER)
	buy.custom_minimum_size.y = 28
	col.add_child(buy)
	return {"panel":panel,"detail":detail,"button":buy,"column":col}

func stat_label(title_text: String) -> Label:
	var label := make_label(title_text, 13, UI_INK, true)
	label.custom_minimum_size.y = 36
	return label

func section_label(text_value: String) -> Label:
	var label := make_label(text_value.to_upper(), 10, UI_NAV_GOLD, true)
	label.custom_minimum_size.y = 18
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_stylebox_override("normal", command_style())
	return label

func make_label(text_value: String, font_size := 14, color := Color.WHITE, _bold := false) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func button(text_value: String, color: Color) -> Button:
	var result := Button.new()
	result.text = text_value
	result.custom_minimum_size.y = 38
	result.add_theme_font_size_override("font_size", 12)
	var text_color := UI_INK if color.get_luminance() > 0.48 else UI_SURFACE
	result.add_theme_color_override("font_color", text_color)
	result.add_theme_color_override("font_hover_color", UI_INK if color != UI_CARBON else UI_NAV_GOLD)
	result.add_theme_color_override("font_pressed_color", UI_SURFACE if color == UI_SIGNAL else UI_INK)
	result.add_theme_color_override("font_disabled_color", UI_INK_SOFT)
	result.add_theme_stylebox_override("normal", raised_style(color))
	result.add_theme_stylebox_override("hover", raised_style(UI_SIGNAL if color != UI_CARBON else UI_MUTED_INDIGO))
	result.add_theme_stylebox_override("pressed", raised_style(UI_NAV_GOLD))
	result.add_theme_stylebox_override("disabled", inset_style(UI_CANVAS_SOFT, UI_MUTED_INDIGO))
	return result

func style(color: Color, radius := 8, border := Color.TRANSPARENT, width := 1) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	var hard_radius := mini(radius, 4)
	result.corner_radius_top_left = hard_radius
	result.corner_radius_top_right = hard_radius
	result.corner_radius_bottom_left = hard_radius
	result.corner_radius_bottom_right = hard_radius
	result.border_width_left = width
	result.border_width_top = width
	result.border_width_right = width
	result.border_width_bottom = width
	result.border_color = border
	result.content_margin_left = 8
	result.content_margin_right = 8
	result.content_margin_top = 6
	result.content_margin_bottom = 6
	return result

func chrome_style(fill := UI_CANVAS) -> StyleBoxFlat:
	var result := style(fill, 4, UI_CHROME_INDIGO, 2)
	result.shadow_color = Color(UI_CHROME_INDIGO, 0.85)
	result.shadow_size = 2
	result.shadow_offset = Vector2(0, 2)
	return result

func command_style(border := UI_CHROME_INDIGO) -> StyleBoxFlat:
	var result := style(UI_CARBON, 0, border, 2)
	result.shadow_color = Color(0.05, 0.06, 0.10, 0.9)
	result.shadow_size = 2
	result.shadow_offset = Vector2(0, 2)
	return result

func inset_style(fill := UI_PLATINUM, border := UI_CHROME_INDIGO) -> StyleBoxFlat:
	var result := style(fill, 3, border, 1)
	result.shadow_color = Color(UI_CHROME_INDIGO, 0.35)
	result.shadow_size = 1
	result.shadow_offset = Vector2(0, -1)
	return result

func raised_style(fill := UI_AMBER) -> StyleBoxFlat:
	var result := style(fill, 2, fill.lightened(0.28), 1)
	result.shadow_color = Color(UI_CHROME_INDIGO, 0.9)
	result.shadow_size = 2
	result.shadow_offset = Vector2(0, 2)
	return result

func decorate_progress_bar(bar: ProgressBar, fill := UI_SIGNAL) -> void:
	bar.add_theme_stylebox_override("background", inset_style(UI_CARBON, UI_MUTED_INDIGO))
	bar.add_theme_stylebox_override("fill", raised_style(fill))

func line() -> HSeparator:
	var result := HSeparator.new()
	result.modulate = UI_MUTED_INDIGO
	return result

func clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func comma(value: int) -> String:
	var magnitude := absi(value)
	if magnitude >= 100000000: return compact_unit(value, 100000000.0, "亿")
	if magnitude >= 1000000: return compact_unit(value, 1000000.0, "百万")
	if magnitude >= 10000: return compact_unit(value, 10000.0, "万")
	return comma_integer(value)

func compact_unit(value: int, divisor: float, suffix: String) -> String:
	var scaled := float(value) / divisor
	var number := "%.2f" % scaled
	while number.ends_with("0"): number = number.left(-1)
	if number.ends_with("."): number = number.left(-1)
	return "%s%s" % [number, suffix]

func comma_integer(value: int) -> String:
	var raw := str(absi(value))
	var result := ""
	for i in raw.length():
		if i > 0 and (raw.length() - i) % 3 == 0: result += ","
		result += raw[i]
	return "-" + result if value < 0 else result
