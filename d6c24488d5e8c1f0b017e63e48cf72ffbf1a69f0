extends "res://scripts/ui/main.gd"

# 摆摊版只替换经营循环。桌面、物理盲盒、封条、镜头、内容物 FBX、
# 弹出展示及 Nintendo 风格 UI 全部继承自上一版 Main。

const BUSINESS_SECONDS := 300.0
const BUSINESS_START := 10.0
const BUSINESS_END := 20.0
const STALL_BOX_PRICES := [20, 48, 120, 260, 520]
# 第一个系列默认解锁；其余系列分别要求上一系列达到指定累计开盒数。
const SERIES_OPEN_REQUIREMENTS := [0, 8, 12, 18, 25]
const RESALE_MULTIPLIER := 0.60
const MAIN_MENU_SCENE := "res://scenes/frontend/main_menu.tscn"
const STALL_PRICE_CHART := preload("res://scripts/ui/price_chart.gd")
const UI_SPRITESHEET_VFX := preload("res://scripts/vfx/spritesheet_vfx_2d.gd")
const PIXEL_UI_SKIN := preload("res://scripts/ui/pixel_ui_skin.gd")
const INCOME_LOW_VFX_PATH := "res://assets/VFX/收入_少.png"
const INCOME_HIGH_VFX_PATH := "res://assets/VFX/收入_多.png"
const PC_UNLOCK_CENTER_VFX_PATH := "res://assets/VFX/屏幕中央礼花.png"
const PC_UNLOCK_EDGE_VFX_PATH := "res://assets/VFX/屏幕边缘礼花.png"
const INCOME_VFX_SCREEN_FRACTION := 0.72
const PC_UNLOCK_VFX_SCALE_MULTIPLIER := 2.0
const PHONE_ICON_ROOT := "res://assets/ui/Pixel Modern UI Bundle/PixelPocketPhoneUI_Resources_v1.0/Icons"
const DIARY_ICON_ROOT := "res://assets/ui/Pixel Modern UI Bundle/PixelInventoryDiaryUI_v1.1/Icons"
const CUSTOM_APP_ICON_ROOT := "res://assets/ui/app_icon"
const PHONE_APP_ICONS := {
	"social":CUSTOM_APP_ICON_ROOT + "/大蓝书.png",
	"supply":PHONE_ICON_ROOT + "/AppIcon/UI_AppIcon_File.png",
	"inventory":PHONE_ICON_ROOT + "/AppIcon/UI_AppIcon_Picture.png",
	"orders":CUSTOM_APP_ICON_ROOT + "/毒.png",
	"resale":CUSTOM_APP_ICON_ROOT + "/扭扭.png",
	"exchange":CUSTOM_APP_ICON_ROOT + "/交换社.png",
	"superdog":CUSTOM_APP_ICON_ROOT + "/超级小狗.png",
	"jimi":CUSTOM_APP_ICON_ROOT + "/基米.png",
	"business":PHONE_ICON_ROOT + "/AppIcon/UI_AppIcon_Notes.png",
}
const PC_PARTS := [
	{"id":"case", "name":"全塔机箱", "detail":"提交肥嘟嘟伙伴小隐藏", "series":0, "rarity":4, "count":1},
	{"id":"cooler", "name":"360mm 水冷风扇", "detail":"提交高雅企鹅小隐藏", "series":1, "rarity":4, "count":1},
	{"id":"psu", "name":"1600W 电源", "detail":"提交奶蛙生肖小隐藏", "series":2, "rarity":4, "count":1},
	{"id":"storage", "name":"4TB 高速固态硬盘", "detail":"提交任意两件小隐藏", "series":-1, "rarity":4, "count":2},
	{"id":"motherboard", "name":"旗舰主板", "detail":"提交牛来小隐藏", "series":3, "rarity":4, "count":1},
	{"id":"cpu", "name":"旗舰游戏 CPU", "detail":"提交牛来大隐藏", "series":3, "rarity":5, "count":1},
	{"id":"memory", "name":"96GB DDR5 内存", "detail":"提交胖企鹅小隐藏", "series":4, "rarity":4, "count":1},
	{"id":"gpu", "name":"旗舰显卡", "detail":"提交胖企鹅大隐藏", "series":4, "rarity":5, "count":1},
]
const APP_UNLOCK_RULES := {
	"social":{"order":0, "cash":0, "series":1, "label":"默认解锁"},
	"orders":{"order":1, "cash":250, "series":2, "label":"现金达到 ¥250，并解锁高雅企鹅"},
	"resale":{"order":2, "cash":500, "series":3, "label":"现金达到 ¥500，并解锁奶蛙生肖"},
	"exchange":{"order":3, "cash":1000, "series":4, "label":"现金达到 ¥1,000，并解锁牛来"},
}
const SOCIAL_POSTS := [
	"路人阿宅：这家摊子的摆件朝向终于不是屁股对着我了。",
	"月亮城探店员：价格可以谈，摊主表情比顾客还紧张。",
	"补全党小林：今天看到有人开出隐藏款，我承认我酸了。",
	"学生会路过：放学后围观可以，记得别把生活费全抽掉。",
	"收藏柜擦灰员：常规款也很好看，真的，不是在安慰自己。",
	"神秘家长：孩子喜欢就行。孩子是谁？当然是我。",
]
const MARKET_EVENTS := [
	{"headline":"短视频博主晒出整柜肥嘟嘟伙伴", "detail":"可爱系摆件讨论度上升，肥嘟嘟伙伴今日领涨。", "modifiers":[1.16, 1.03, 0.98, 1.00, 0.97]},
	{"headline":"墨镜穿搭挑战登上同城热榜", "detail":"高雅企鹅突然成为拍照搭子，相关款式需求增加。", "modifiers":[0.98, 1.18, 1.01, 0.99, 1.00]},
	{"headline":"生肖礼物采购提前启动", "detail":"奶蛙生肖系列受到送礼客群关注。", "modifiers":[1.00, 0.97, 1.17, 1.02, 0.99]},
	{"headline":"动画电影发布新预告", "detail":"牛来角色话题升温，收藏者开始补齐系列。", "modifiers":[0.99, 1.01, 1.03, 1.20, 0.98]},
	{"headline":"红围巾企鹅表情包二次走红", "detail":"胖企鹅系列成交活跃，隐藏款询价明显增加。", "modifiers":[0.97, 1.00, 0.99, 1.04, 1.19]},
	{"headline":"周中客流转淡，买家普遍观望", "detail":"全市场短暂回调，适合留意低价补货机会。", "modifiers":[0.93, 0.95, 0.94, 0.96, 0.95]},
	{"headline":"动漫月亮城周末收藏祭预热", "detail":"各系列关注度同步上升，热门常规款更容易成交。", "modifiers":[1.09, 1.08, 1.10, 1.07, 1.09]},
	{"headline":"玩家晒出隐藏款鉴定视频", "detail":"高价收藏市场活跃，但普通买家仍然十分谨慎。", "modifiers":[1.02, 1.04, 1.03, 1.08, 1.06]},
	{"headline":"同城二手平台集中放货", "detail":"供给突然增加，多数系列价格承压。", "modifiers":[0.96, 0.92, 0.95, 0.94, 0.93]},
	{"headline":"暑期最后一轮逛街潮到来", "detail":"线下成交回暖，各系列价格温和上扬。", "modifiers":[1.06, 1.05, 1.07, 1.05, 1.08]},
]
const ENDING_TEXTS := [
	"终于，最后一块配件也到手了。我把这台梦中情机一口气装了起来。",
	"开机、联网、打开游戏购买网站——GDA6，我来了！",
	"……等等。『GDA6 为主机平台独占，PC 版本暂无计划。』",
	"为了赚钱配电脑，我选择在动漫街摆摊卖盲盒。可我是不是……先买台主机就行了？",
]
const ENDING_TEXTURES := [
	preload("res://assets/placeholders/story/pc.jpg"),
	preload("res://assets/placeholders/story/pc.jpg"),
	preload("res://assets/placeholders/story/exclusive.jpg"),
	preload("res://assets/placeholders/story/exclusive.jpg"),
]
# 摆摊版不再读取旧版幸运等级。常规款共享一个总概率并严格平分，
# 只有小隐藏（金色，内部索引 4）和大隐藏（彩虹，内部索引 5）拥有独立爆率。
const STALL_FIXED_RARITY_WEIGHTS := [
	[855, 0, 0, 0, 45, 0],
	[855, 0, 0, 0, 45, 0],
	[228, 0, 0, 0, 12, 0],
	[940, 0, 0, 0, 50, 10],
	[564, 0, 0, 0, 30, 6],
]
# 以下路线值均为 CSGAnimePedestrianStreet 的局部坐标，会随美术根节点等比缩放。
const STREET_SURFACE_Y := -1.04
const STREET_CUSTOMER_Z := -5.15
const STREET_PEDESTRIAN_LIMIT := 12
const CITY_PERSON := preload("res://scripts/stall_demo/city_pedestrian.gd")
const STALL_VALUES := [
	[30, 30, 30, 30, 30, 30, 30, 30, 30, 150],
	[72, 72, 72, 72, 72, 72, 72, 72, 72, 600],
	[180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 1200],
	[390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 2000, 10000],
	[780, 780, 780, 780, 780, 780, 780, 780, 780, 780, 780, 780, 4000, 12000]
]
const CUSTOMER_PROFILES := [
	{"name":"穷学生", "quote":"我还是学生，能便宜点给我吗？", "offer":0.62, "budget":0.78},
	{"name":"普通爱好者", "quote":"这个系列我关注很久了。", "offer":0.84, "budget":1.00},
	{"name":"补全党", "quote":"就差这一只，我的强迫症有救了。", "offer":0.94, "budget":1.12},
	{"name":"土豪父母", "quote":"我不太懂这些，孩子喜欢就行。", "offer":1.12, "budget":1.35},
	{"name":"收藏家", "quote":"品相不错。价格合适，我现在就带走。", "offer":0.98, "budget":1.22}
]

var stall_ready := false
var stall_preparing := true
var stall_day_finished := false
var stall_business_elapsed := 0.0
var stall_time_speed := 1.0
var stall_reputation := 0
var stall_daily_revenue := 0
var stall_daily_sales := 0
var stall_daily_visitors := 0

var stall_shelf_level := 0
var stall_inventory_level := 0
var stall_location_level := 0
var stall_showcase_level := 0
var stall_multi_open_level := 0
var stall_eloquence_level := 0
var stall_inventory_capacity := 12
var stall_listings: Array = [null, null, null, null]

var stall_fixture_root: Node3D
var stall_shelf_root: Node3D
var stall_customer_root: Node3D
var stall_street_root: Node3D
var stall_pedestrian_root: Node3D
var stall_pedestrians: Array[Dictionary] = []
var stall_pedestrian_spawn_wait := 0.0
var stall_customer: Node3D
var stall_customer_phase := ""
var stall_customer_lane := -6.15
var stall_customer_direction := 1.0
var stall_customer_exit_target := Vector3.ZERO
var stall_customer_wait := 0.0
var stall_spawn_wait := 5.0
var stall_offer_slot := -1
var stall_offer_price := 0
var stall_customer_max := 0.0
var stall_customer_profile: Dictionary = {}

var stall_phone: PanelContainer
var stall_phone_frame: TextureRect
var stall_phone_screen: VBoxContainer
var stall_phone_page: VBoxContainer
var stall_phone_wallpaper: TextureRect
var stall_phone_page_backdrop: ColorRect
var stall_phone_toggle: TextureButton
var stall_backpack_toggle: TextureButton
var stall_phone_collapse_button: Button
var stall_phone_home_button: Button
var stall_phone_clock: Label
var stall_phone_signal: Label
var stall_phone_status: Label
var stall_phone_visible := true
var stall_phone_tween: Tween
var stall_current_app := "home"

var stall_offer_panel: PanelContainer
var stall_offer_text: Label
var stall_offer_button: Button
var stall_bargain_panel: PanelContainer
var stall_bargain_content: VBoxContainer
var stall_bargain_slider: VSlider
var stall_bargain_amount: Label
var stall_bargain_round := 0

var stall_price_panel: PanelContainer
var stall_price_content: VBoxContainer
var stall_price_value := 0
var stall_price_item: Dictionary = {}
var stall_price_source := ""
var stall_price_inventory_index := -1

var stall_day_panel: PanelContainer
var stall_day_content: VBoxContainer
var stall_order_accepted := false
var stall_order_completed := false
var pc_parts_owned := 0
var unlocked_apps := {"social":true}
var item_price_memory := {}
var stall_price_listing_index := -1
var stall_social_boost := false
var stall_business_button: Button
var stall_pc_shop_owner: Node3D

var pause_overlay: ColorRect
var pause_panel: PanelContainer
var pause_status: Label
var pause_load_button: Button
var ending_overlay: Control
var ending_background: TextureRect
var ending_text: Label
var ending_progress: Label
var ending_index := -1
var day_one_story: Control
var day_one_story_seen := false


func _ready() -> void:
	cash = 130
	day = 1
	earned = 0
	super._ready()
	_bind_authored_stall_scene()
	_spawn_pc_shop_owner()
	var load_state: Dictionary = _session().take_pending_state()
	if load_state.is_empty():
		for index in range(2):
			spawn_box("blind", 0, roll_content(0), box_price(0), index)
	else:
		_apply_save_state(load_state)
	stall_ready = true
	refresh_ui()
	toast("存档读取完成。" if not load_state.is_empty() else "开摊准备中：点击桌面盲盒，沿用原版点击聚焦、撕封与内容物弹出操作。")


var ui_fit_elapsed := 0.0

func _process(delta: float) -> void:
	ui_fit_elapsed += delta
	if ui_fit_elapsed > 0.2:
		ui_fit_elapsed = 0.0
		_fit_game_panels()
	if ending_overlay and ending_overlay.visible: return
	super._process(delta)
	if not stall_ready or stall_preparing or stall_day_finished:
		return
	if focused_box or review_item or stall_price_panel.visible or stall_bargain_panel.visible:
		return
	stall_business_elapsed += delta * stall_time_speed
	if stall_business_elapsed >= BUSINESS_SECONDS:
		stall_business_elapsed = BUSINESS_SECONDS
		_finish_business_day()
		return
	_update_stall_clock()
	_update_pedestrians(delta * stall_time_speed)
	_update_customer(delta * stall_time_speed)


func build_ui() -> void:
	super.build_ui()
	_reframe_legacy_ui()
	_build_phone_ui()
	_build_stall_offer_ui()
	_build_stall_price_ui()
	_build_stall_day_ui()
	_build_pause_menu()
	_build_ending_ui()
	day_one_story = preload("res://scenes/stall_demo/day_one_story.tscn").instantiate()
	ui_canvas.add_child(day_one_story)
	day_one_story.completed.connect(_finish_day_one_story)
	_apply_pixel_ui_assets()
	_apply_authored_ui_layout()


func button(text_value: String, color: Color) -> Button:
	var result := super.button(text_value, color)
	if text_value.contains("返回") or text_value.contains("取消") or text_value.contains("撤回"):
		PIXEL_UI_SKIN.apply_hud_action_button(result, "cancel")
	elif text_value.contains("盲盒") or text_value.contains("道具"):
		PIXEL_UI_SKIN.apply_hud_action_button(result, "tab")
	elif color == UI_SIGNAL or color == UI_AMBER:
		PIXEL_UI_SKIN.apply_hud_action_button(result, "confirm")
	elif color == UI_CARBON:
		PIXEL_UI_SKIN.apply_hud_action_button(result, "dialogue")
	else:
		PIXEL_UI_SKIN.apply_hud_button(result)
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return result


func _apply_pixel_ui_assets() -> void:
	var left_hud := ui_canvas.get_node_or_null("LeftStatusPanel") as PanelContainer
	if left_hud: PIXEL_UI_SKIN.apply_panel(left_hud, "hud")
	if detail_panel: PIXEL_UI_SKIN.apply_panel(detail_panel, "dialogue")
	if loot_preview_panel: PIXEL_UI_SKIN.apply_panel(loot_preview_panel, "popup")
	if inventory_panel: PIXEL_UI_SKIN.apply_panel(inventory_panel, "diary")
	if collection_panel: PIXEL_UI_SKIN.apply_panel(collection_panel, "diary")
	if market_panel: PIXEL_UI_SKIN.apply_panel(market_panel, "diary")
	if stall_offer_panel: PIXEL_UI_SKIN.apply_panel(stall_offer_panel, "dialogue")
	if stall_bargain_panel: PIXEL_UI_SKIN.apply_panel(stall_bargain_panel, "popup")
	if stall_price_panel: PIXEL_UI_SKIN.apply_panel(stall_price_panel, "popup")
	if stall_day_panel: PIXEL_UI_SKIN.apply_panel(stall_day_panel, "popup")
	if pause_panel: PIXEL_UI_SKIN.apply_panel(pause_panel, "pause")
	for progress in ui_canvas.find_children("*", "ProgressBar", true, false):
		PIXEL_UI_SKIN.apply_progress(progress as ProgressBar, false)
	for pause_button in pause_panel.find_children("*", "Button", true, false):
		PIXEL_UI_SKIN.apply_hud_button(pause_button as Button, true)
	_skin_phone_page()


func _reframe_legacy_ui() -> void:
	var left_hud := ui_canvas.get_node_or_null("LeftStatusPanel") as PanelContainer
	if left_hud:
		left_hud.size = Vector2(230, 220)
		for child in left_hud.find_children("*", "Button", true, false):
			if (child as Button).text.contains("结束今天"):
				stall_business_button = child as Button
				stall_business_button.visible = true
				stall_business_button.text = "开店"
	var left_shop := ui_canvas.get_node_or_null("LeftShopPanel")
	if left_shop:
		left_shop.visible = false
	for child in ui_canvas.get_children():
		if child is HBoxContainer and child.position.x > 800.0:
			child.visible = false
	if inventory_panel: inventory_panel.visible = false
	if collection_panel: collection_panel.visible = false
	if market_panel: market_panel.visible = false
	if developer_panel: developer_panel.visible = false
	# 旧升级面板是右侧顶层 Panel；开盒详情与奖池预览仍然保留。
	for child in ui_canvas.get_children():
		if child is PanelContainer and child.position.x > 900.0:
			if child != detail_panel and child != loot_preview_panel:
				child.visible = false
	detail_panel.position = Vector2(300, 514)
	detail_panel.size = Vector2(680, 170)
	detail_title.custom_minimum_size.y = 28
	detail_hint.custom_minimum_size.y = 32
	detail_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sell_button.custom_minimum_size = Vector2(270, 46)
	keep_button.custom_minimum_size = Vector2(250, 46)
	toast_label.position = Vector2(295, 686)
	toast_label.size = Vector2(690, 28)
	sell_button.text = "上架并定价"


func _build_phone_ui() -> void:
	stall_phone = PanelContainer.new()
	stall_phone.name = "ClickablePhone"
	stall_phone.position = Vector2(928, 34)
	stall_phone.size = Vector2(334, 652)
	stall_phone.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	ui_canvas.add_child(stall_phone)
	stall_phone_frame = PIXEL_UI_SKIN.frame_rect(PIXEL_UI_SKIN.PHONE_FRAME)
	stall_phone_frame.name = "PixelPhoneFrame"
	stall_phone_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stall_phone_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stall_phone.add_child(stall_phone_frame)

	var phone_margin := MarginContainer.new()
	phone_margin.add_theme_constant_override("margin_left", 25)
	phone_margin.add_theme_constant_override("margin_right", 25)
	phone_margin.add_theme_constant_override("margin_top", 25)
	phone_margin.add_theme_constant_override("margin_bottom", 25)
	stall_phone.add_child(phone_margin)
	stall_phone_wallpaper = PIXEL_UI_SKIN.frame_rect(PIXEL_UI_SKIN.PHONE_WALLPAPER)
	stall_phone_wallpaper.name = "PhoneWallpaper"
	stall_phone_wallpaper.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	phone_margin.add_child(stall_phone_wallpaper)
	stall_phone_page_backdrop = ColorRect.new()
	stall_phone_page_backdrop.name = "PhonePageBackdrop"
	stall_phone_page_backdrop.color = Color(1.0, 0.98, 0.97, 0.0)
	stall_phone_page_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phone_margin.add_child(stall_phone_page_backdrop)
	stall_phone_screen = VBoxContainer.new()
	stall_phone_screen.add_theme_constant_override("separation", 4)
	phone_margin.add_child(stall_phone_screen)

	var status_row := HBoxContainer.new()
	status_row.custom_minimum_size.y = 28
	stall_phone_screen.add_child(status_row)
	stall_phone_clock = make_label("◉  10:00", 12, Color.WHITE, true)
	stall_phone_clock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(stall_phone_clock)
	stall_phone_signal = make_label("5G  100%", 10, Color.WHITE, true)
	status_row.add_child(stall_phone_signal)

	var screen := PanelContainer.new()
	screen.name = "PixelPhoneScreen"
	screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	stall_phone_screen.add_child(screen)
	stall_phone_page = VBoxContainer.new()
	stall_phone_page.add_theme_constant_override("separation", 4)
	screen.add_child(stall_phone_page)

	stall_phone_home_button = Button.new()
	stall_phone_home_button.name = "PhysicalHomeButton"
	stall_phone_home_button.tooltip_text = "返回手机主页"
	stall_phone_home_button.icon = load(PHONE_ICON_ROOT + "/SystemIcon/UI_Icon_Home.png") as Texture2D
	stall_phone_home_button.expand_icon = true
	stall_phone_home_button.add_theme_constant_override("icon_max_width", 23)
	stall_phone_home_button.custom_minimum_size = Vector2(104, 34)
	stall_phone_home_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stall_phone_home_button.pressed.connect(_show_phone_home)
	PIXEL_UI_SKIN.apply_phone_button(stall_phone_home_button, "flat")
	stall_phone_screen.add_child(stall_phone_home_button)

	# 收起入口独立放在机身正下方，不再藏进狭窄的状态栏。
	stall_phone_collapse_button = Button.new()
	stall_phone_collapse_button.name = "PhoneCollapseButton"
	stall_phone_collapse_button.position = Vector2(1043, 681)
	stall_phone_collapse_button.size = Vector2(104, 34)
	stall_phone_collapse_button.tooltip_text = "收起手机"
	stall_phone_collapse_button.icon = load(PHONE_ICON_ROOT + "/SystemIcon/UI_Icon_ChevronDown.png") as Texture2D
	stall_phone_collapse_button.expand_icon = true
	stall_phone_collapse_button.add_theme_constant_override("icon_max_width", 22)
	PIXEL_UI_SKIN.apply_phone_button(stall_phone_collapse_button, "gray")
	stall_phone_collapse_button.pressed.connect(_toggle_phone)
	ui_canvas.add_child(stall_phone_collapse_button)

	stall_phone_toggle = _make_hud_shortcut("PhonePullTab", "手机", DIARY_ICON_ROOT + "/Gadget/UI_Icon_Phone.png", _toggle_phone)
	stall_phone_toggle.position = Vector2(1170, 608)
	ui_canvas.add_child(stall_phone_toggle)
	stall_backpack_toggle = _make_hud_shortcut("BackpackShortcut", "背包", DIARY_ICON_ROOT + "/Daily/UI_Icon_SchoolBag.png", _open_backpack_shortcut)
	stall_backpack_toggle.position = Vector2(1170, 506)
	ui_canvas.add_child(stall_backpack_toggle)
	stall_phone_toggle.visible = false
	stall_backpack_toggle.visible = false
	_show_phone_home()


func _apply_authored_ui_layout(final_pass := false) -> void:
	var authoring := get_node_or_null("UILayoutAuthoring") as CanvasLayer
	if authoring == null: return
	var slots := authoring.get_node_or_null("Slots") as Control
	if slots == null:
		authoring.visible = false
		return
	var targets := {
		"LeftStatusPanel":ui_canvas.get_node_or_null("LeftStatusPanel"),
		"DetailPanel":detail_panel,
		"LootPreviewPanel":loot_preview_panel,
		"ToastBar":toast_label,
		"Phone":stall_phone,
		"PhoneCollapse":stall_phone_collapse_button,
		"BackpackShortcut":stall_backpack_toggle,
		"PhoneShortcut":stall_phone_toggle,
		"OfferPanel":stall_offer_panel,
		"BargainPanel":stall_bargain_panel,
		"PricePanel":stall_price_panel,
		"DayPanel":stall_day_panel,
		"PausePanel":pause_panel,
	}
	for slot_name in targets:
		var slot := slots.find_child(slot_name, true, false) as Control
		var target := targets[slot_name] as Control
		if slot == null or target == null: continue
		target.position = slot.position
		target.size = slot.size
		# 面板预览使用的纹理也可以直接在布局场景 Inspector 中替换。
		if target is PanelContainer and slot is NinePatchRect:
			var current_style := (target as PanelContainer).get_theme_stylebox("panel")
			if current_style is StyleBoxTexture and (slot as NinePatchRect).texture:
				var authored_style := current_style.duplicate() as StyleBoxTexture
				authored_style.texture = (slot as NinePatchRect).texture
				(target as PanelContainer).add_theme_stylebox_override("panel", authored_style)
	if stall_phone_frame:
		var phone_slot := slots.find_child("Phone", true, false) as TextureRect
		if phone_slot and phone_slot.texture: stall_phone_frame.texture = phone_slot.texture
	var backpack_slot := slots.find_child("BackpackShortcut", true, false) as TextureRect
	if backpack_slot and backpack_slot.texture:
		stall_backpack_toggle.texture_normal = backpack_slot.texture
		stall_backpack_toggle.texture_hover = backpack_slot.texture
		stall_backpack_toggle.texture_pressed = backpack_slot.texture
	var phone_shortcut_slot := slots.find_child("PhoneShortcut", true, false) as TextureRect
	if phone_shortcut_slot and phone_shortcut_slot.texture:
		stall_phone_toggle.texture_normal = phone_shortcut_slot.texture
		stall_phone_toggle.texture_hover = phone_shortcut_slot.texture
		stall_phone_toggle.texture_pressed = phone_shortcut_slot.texture
	_sync_authored_shortcut_contents(backpack_slot, stall_backpack_toggle)
	_sync_authored_shortcut_contents(phone_shortcut_slot, stall_phone_toggle)
	authoring.visible = false
	# 等所有 Container 完成首次最小尺寸计算后再落一次最终矩形，避免导入
	# 纹理的首帧尺寸把编辑器中编排好的边界撑开。
	if not final_pass: call_deferred("_apply_authored_ui_layout", true)


func _fit_game_panels() -> void:
	if not ui_canvas: return
	var authored_slots := get_node_or_null("UILayoutAuthoring/Slots")
	var names := ["LeftStatusPanel", "DetailPanel", "LootPreviewPanel", "OfferPanel", "BargainPanel", "PricePanel", "DayPanel", "PausePanel"]
	var panel_index := 0
	# Deliberately exclude the hand-authored shortcuts and phone home screen.
	for panel in [ui_canvas.get_node_or_null("LeftStatusPanel"), detail_panel, loot_preview_panel, stall_offer_panel, stall_bargain_panel, stall_price_panel, stall_day_panel, pause_panel]:
		if is_instance_valid(panel):
			PIXEL_UI_SKIN.fit_content(panel)
			var slot: Control = authored_slots.find_child(names[panel_index], true, false) if authored_slots else null
			if slot:
				panel.size = slot.size
				panel.position = slot.position
			if panel.visible:
				panel.position.y = maxf(12.0, minf(panel.position.y, 674.0 - panel.size.y))
		panel_index += 1
	if stall_current_app != "home" and is_instance_valid(stall_phone_page):
		PIXEL_UI_SKIN.fit_content(stall_phone_page)
	if toast_label:
		toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		toast_label.add_theme_font_size_override("font_size", 11)
		toast_label.size.y = 34
		toast_label.position.y = minf(toast_label.position.y, 680)


func _sync_authored_shortcut_contents(slot: TextureRect, target: TextureButton) -> void:
	if slot == null or target == null: return
	var authored_icon := slot.get_node_or_null("Icon") as TextureRect
	var runtime_icon := target.get_node_or_null("ShortcutIcon") as TextureRect
	if authored_icon and runtime_icon:
		runtime_icon.position = authored_icon.position
		runtime_icon.size = authored_icon.size
		if authored_icon.texture: runtime_icon.texture = authored_icon.texture
		runtime_icon.stretch_mode = authored_icon.stretch_mode
	var authored_label := slot.get_node_or_null("GuideLabel") as Label
	var runtime_label: Label = null
	for child in target.get_children():
		if child is Label:
			runtime_label = child as Label
			break
	if authored_label and runtime_label:
		runtime_label.position = authored_label.position
		runtime_label.size = authored_label.size
		runtime_label.horizontal_alignment = authored_label.horizontal_alignment
		runtime_label.vertical_alignment = authored_label.vertical_alignment
		runtime_label.add_theme_font_size_override("font_size", authored_label.get_theme_font_size("font_size"))


func _make_hud_shortcut(node_name: String, caption: String, icon_path: String, action: Callable) -> TextureButton:
	var shortcut := TextureButton.new()
	shortcut.name = node_name
	shortcut.size = Vector2(92, 96)
	shortcut.ignore_texture_size = true
	shortcut.stretch_mode = TextureButton.STRETCH_SCALE
	shortcut.texture_normal = PIXEL_UI_SKIN.texture(PIXEL_UI_SKIN.HUD_SHORTCUT_BG)
	shortcut.texture_hover = shortcut.texture_normal
	shortcut.texture_pressed = shortcut.texture_normal
	shortcut.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shortcut.pressed.connect(action)
	var icon := TextureRect.new()
	icon.name = "ShortcutIcon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = load(icon_path) as Texture2D
	icon.position = Vector2(23, 7)
	icon.size = Vector2(46, 50)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shortcut.add_child(icon)
	var label := make_label(caption, 13, PIXEL_UI_SKIN.INK, true)
	label.position = Vector2(6, 62)
	label.size = Vector2(80, 25)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shortcut.add_child(label)
	return shortcut


func _open_backpack_shortcut() -> void:
	_set_phone_visible(true)
	_open_phone_app("inventory")


func _show_phone_home() -> void:
	stall_current_app = "home"
	_update_app_unlocks()
	if stall_phone_page_backdrop: stall_phone_page_backdrop.color = Color(1.0, 0.98, 0.97, 0.0)
	stall_phone_clock.add_theme_color_override("font_color", Color.WHITE)
	stall_phone_signal.add_theme_color_override("font_color", Color.WHITE)
	if stall_phone_home_button: stall_phone_home_button.disabled = true
	clear_children(stall_phone_page)
	var title := make_label("爽开摊主机", 16, Color.WHITE, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stall_phone_page.add_child(title)
	stall_phone_status = make_label(_phone_status_text(), 9, Color.WHITE, true)
	stall_phone_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stall_phone_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stall_phone_page.add_child(stall_phone_status)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	stall_phone_page.add_child(grid)
	_add_app_icon(grid, "大蓝书", UI_CANVAS_SOFT, "social")
	_add_app_icon(grid, "进货", UI_AMBER, "supply")
	_add_app_icon(grid, "毒", Color("#8d66c7"), "orders")
	_add_app_icon(grid, "扭扭", Color("#59c7b5"), "resale")
	_add_app_icon(grid, "集换处", Color("#3f9fb3"), "exchange")
	_add_app_icon(grid, "超级小狗", Color("#f3b43f"), "superdog")
	_add_app_icon(grid, "基米", Color("#6176c8"), "jimi")
	_add_app_icon(grid, "经营", UI_SIGNAL, "business")
	_skin_phone_page()


func _add_app_icon(parent: Control, title: String, _color: Color, app_id: String) -> void:
	var tile := VBoxContainer.new()
	tile.name = "AppTile_%s" % app_id
	tile.custom_minimum_size = Vector2(91, 104)
	tile.add_theme_constant_override("separation", 0)
	var app_button := Button.new()
	app_button.name = "AppButton_%s" % app_id
	app_button.set_meta("phone_app_icon", true)
	app_button.custom_minimum_size = Vector2(82, 78)
	app_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	app_button.icon = load(String(PHONE_APP_ICONS[app_id])) as Texture2D
	app_button.expand_icon = true
	app_button.add_theme_constant_override("icon_max_width", 64)
	app_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	app_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	PIXEL_UI_SKIN.apply_phone_icon_button(app_button)
	var locked := APP_UNLOCK_RULES.has(app_id) and not _app_unlocked(app_id)
	app_button.disabled = locked
	app_button.modulate = Color(0.48, 0.48, 0.48, 0.86) if locked else Color.WHITE
	if locked:
		app_button.tooltip_text = _app_unlock_hint(app_id)
	else:
		app_button.pressed.connect(_open_phone_app.bind(app_id))
	tile.add_child(app_button)
	var label := make_label("🔒 %s" % title if locked else title, 10, PIXEL_UI_SKIN.INK, true)
	label.custom_minimum_size = Vector2(91, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(label)
	parent.add_child(tile)


func _open_phone_app(app_id: String) -> void:
	if APP_UNLOCK_RULES.has(app_id) and not _app_unlocked(app_id):
		toast(_app_unlock_hint(app_id))
		return
	stall_current_app = app_id
	if stall_phone_page_backdrop: stall_phone_page_backdrop.color = Color(1.0, 0.985, 0.975, 0.96)
	stall_phone_clock.add_theme_color_override("font_color", PIXEL_UI_SKIN.INK)
	stall_phone_signal.add_theme_color_override("font_color", PIXEL_UI_SKIN.INK)
	if stall_phone_home_button: stall_phone_home_button.disabled = false
	clear_children(stall_phone_page)
	var header := HBoxContainer.new()
	stall_phone_page.add_child(header)
	var names := {"social":"大蓝书", "supply":"进货", "inventory":"库存", "resale":"扭扭", "orders":"毒", "exchange":"集换处", "superdog":"超级小狗", "jimi":"基米", "business":"经营"}
	var title := make_label(String(names[app_id]), 18, UI_CHROME_INDIGO, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stall_phone_page.add_child(scroll)
	var content := VBoxContainer.new()
	content.name = "AppContent"
	content.custom_minimum_size.x = 0
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	scroll.add_child(content)
	match app_id:
		"social": _build_social_app(content)
		"supply": _build_supply_app(content)
		"inventory": _build_inventory_app(content)
		"resale": _build_resale_app(content)
		"orders": _build_orders_app(content)
		"exchange": _build_exchange_app(content)
		"superdog": _build_superdog_app(content)
		"jimi": _build_jimi_app(content)
		"business": _build_business_app(content)
	_skin_phone_page()


func _skin_phone_page() -> void:
	if not stall_phone or not is_instance_valid(stall_phone): return
	for phone_button in stall_phone.find_children("*", "Button", true, false):
		if (phone_button as Button).has_meta("phone_app_icon") or (phone_button as Button) == stall_phone_collapse_button: continue
		var phone_variant: String = "flat" if (phone_button as Button) == stall_phone_home_button else String({"social":"pink", "orders":"gray", "resale":"pink", "business":"gray"}.get(stall_current_app, "yellow"))
		PIXEL_UI_SKIN.apply_phone_button(phone_button as Button, phone_variant)
	for phone_panel in stall_phone_page.find_children("*", "PanelContainer", true, false):
		var variant := "diary" if stall_current_app in ["inventory", "exchange"] else "phone"
		PIXEL_UI_SKIN.apply_panel(phone_panel as PanelContainer, variant)
	for phone_progress in stall_phone.find_children("*", "ProgressBar", true, false):
		PIXEL_UI_SKIN.apply_progress(phone_progress as ProgressBar, true)
	call_deferred("_fit_game_panels")


func _build_social_app(content: VBoxContainer) -> void:
	content.add_child(section_label("大蓝书 / 月亮城动态"))
	content.add_child(make_label("社区帖子不会控制开店。营业请使用左上角最下方按钮。", 10, UI_INK_SOFT))
	for offset in 3:
		var post_index := posmod(day * 2 + offset, SOCIAL_POSTS.size())
		var post := make_label(String(SOCIAL_POSTS[post_index]), 11, UI_INK, true)
		post.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		post.custom_minimum_size.y = 64
		post.add_theme_stylebox_override("normal", inset_style(UI_SURFACE, UI_PERIWINKLE))
		content.add_child(post)
	var rare_post := button("发布隐藏款照片揽客", UI_SIGNAL)
	rare_post.disabled = stall_social_boost or not _has_hidden_collectible()
	rare_post.text = "今日已发布隐藏款照片" if stall_social_boost else ("需要持有隐藏款" if not _has_hidden_collectible() else "发布隐藏款照片揽客")
	rare_post.pressed.connect(_publish_rare_photo)
	content.add_child(rare_post)


func _build_supply_app(content: VBoxContainer) -> void:
	content.add_child(section_label("盲盒商城 / 到货即落到桌面"))
	for series_index in SERIES.size():
		var progress_text := "初始解锁" if series_index == 0 else "需开上一系列 %d 盒（%d/%d）" % [SERIES_OPEN_REQUIREMENTS[series_index], mini(series_open_counts[series_index - 1], SERIES_OPEN_REQUIREMENTS[series_index]), SERIES_OPEN_REQUIREMENTS[series_index]]
		var card := make_shop_card(SERIES[series_index]["name"], "%s｜单盒 ¥%s" % [progress_text, comma(box_price(series_index))], SERIES[series_index]["color"])
		card["button"].text = "购入 1 盒"
		card["button"].disabled = not series_unlocked(series_index) or cash < box_price(series_index)
		if not series_unlocked(series_index): card["button"].text = "尚未解锁"
		card["button"].pressed.connect(_buy_series_count.bind(series_index, 1))
		var row := HBoxContainer.new()
		card["column"].add_child(row)
		if stall_multi_open_level >= 1:
			var five := button("购入 5 盒", UI_NAV_GOLD)
			five.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			five.disabled = cash < box_price(series_index) * 5 or not series_unlocked(series_index)
			five.pressed.connect(_buy_series_count.bind(series_index, 5))
			row.add_child(five)
		if stall_multi_open_level >= 2:
			var ten := button("购入 10 盒", UI_SIGNAL)
			ten.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ten.disabled = cash < box_price(series_index) * 10 or not series_unlocked(series_index)
			ten.pressed.connect(_buy_series_count.bind(series_index, 10))
			row.add_child(ten)
		content.add_child(card["panel"])


func _build_inventory_app(content: VBoxContainer) -> void:
	content.add_child(section_label("库存 %d / %d" % [collectibles.size(), stall_inventory_capacity]))
	if collectibles.is_empty():
		content.add_child(make_label("库存为空。开盒后选择“保留库存”。", 12, UI_INK_SOFT))
		return
	for index in collectibles.size():
		var item: Dictionary = collectibles[index]
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", inset_style(UI_SURFACE, RARITY_COLORS[int(item["rarity"])]))
		var column := VBoxContainer.new()
		panel.add_child(column)
		column.add_child(make_label("%s｜%s" % [item["name"], RARITIES[int(item["rarity"])]], 12, UI_INK, true))
		column.add_child(make_label("今日市价 ¥%s" % comma(inventory_item_price(item)), 11, UI_INK_SOFT))
		var list_button := button("上架并定价", UI_AMBER)
		list_button.disabled = _first_empty_listing() < 0
		list_button.pressed.connect(_price_inventory_item.bind(index))
		column.add_child(list_button)
		content.add_child(panel)


func _build_resale_app(content: VBoxContainer) -> void:
	content.add_child(section_label("扭扭 / 重复款快速处理"))
	var resale_indices := _duplicate_resale_indices()
	var total := 0
	for index in resale_indices:
		total += int(round(inventory_item_price(collectibles[index]) * RESALE_MULTIPLIER))
	content.add_child(make_label("检测到 %d 件重复款\n按今日市价 60%% 结算：¥%s" % [resale_indices.size(), comma(total)], 13, UI_INK, true))
	var sell_all := button("出售全部重复款", Color("#59c7b5"))
	sell_all.disabled = resale_indices.is_empty()
	sell_all.pressed.connect(_resale_all_inventory)
	content.add_child(sell_all)
	content.add_child(make_label("收藏保护已开启：每个款式至少保留 1 件。", 10, UI_INK_SOFT))


func _build_orders_app(content: VBoxContainer) -> void:
	content.add_child(section_label("毒 / 每日悬赏"))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", inset_style(UI_SURFACE, Color("#8d66c7")))
	var column := VBoxContainer.new()
	panel.add_child(column)
	column.add_child(make_label("社团抽奖急用", 14, UI_INK, true))
	column.add_child(make_label("需求：肥嘟嘟伙伴任意 2 件\n奖励：¥120 + 声望 3", 11, UI_INK_SOFT))
	var action := button("接取", Color("#8d66c7"))
	if stall_order_completed:
		action.text = "今日已完成"
		action.disabled = true
	elif stall_order_accepted:
		action.text = "交付订单"
		action.pressed.connect(_deliver_daily_order)
	else:
		action.pressed.connect(_accept_daily_order)
	column.add_child(action)
	content.add_child(panel)


func _build_exchange_app(content: VBoxContainer) -> void:
	_show_exchange_overview(content)


func _show_exchange_overview(content: VBoxContainer) -> void:
	clear_children(content)
	content.add_child(section_label("集换处 / 第 %d 天行情" % day))
	var event := _market_event_for_day(day)
	var news_panel := PanelContainer.new()
	news_panel.add_theme_stylebox_override("panel", inset_style(Color("#eaf7f8"), Color("#3f9fb3")))
	var news_column := VBoxContainer.new()
	news_panel.add_child(news_column)
	news_column.add_child(make_label("今日快讯｜%s" % event["headline"], 13, UI_INK, true))
	var detail := make_label(String(event["detail"]), 11, UI_INK_SOFT)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	news_column.add_child(detail)
	content.add_child(news_panel)
	content.add_child(make_label("行情每天更新。点开系列，再选择具体内容物查看历史价格曲线。", 10, UI_INK_SOFT))
	for series_index in SERIES.size():
		var regular_index := _first_regular_item_index(series_index)
		var current := market_price_at_day(series_index, regular_index, day)
		var previous := _market_reference_price(series_index, regular_index, day - 1)
		var change := _market_change_percent(current, previous)
		var card := make_shop_card(String(SERIES[series_index]["name"]), "常规款参考 ¥%s｜%s" % [comma(current), _market_change_text(change)], SERIES[series_index]["color"])
		card["button"].text = "查看系列曲线"
		card["button"].disabled = not series_unlocked(series_index)
		if card["button"].disabled:
			card["button"].text = "开上一系列 %d 盒解锁" % SERIES_OPEN_REQUIREMENTS[series_index]
		else:
			card["button"].pressed.connect(_show_exchange_series.bind(content, series_index))
		content.add_child(card["panel"])


func _show_exchange_series(content: VBoxContainer, series_index: int) -> void:
	clear_children(content)
	var back := button("◀ 全部系列", UI_CARBON)
	back.pressed.connect(_show_exchange_overview.bind(content))
	content.add_child(back)
	content.add_child(section_label(String(SERIES[series_index]["name"])))
	content.add_child(make_label("第 %d 天｜逐件市价与当日涨跌" % day, 11, UI_INK_SOFT))
	for item_index in SERIES[series_index]["items"].size():
		var current := market_price_at_day(series_index, item_index, day)
		var previous := _market_reference_price(series_index, item_index, day - 1)
		var change := _market_change_percent(current, previous)
		var rarity := int(SERIES[series_index]["rarities"][item_index])
		var card := PanelContainer.new()
		card.custom_minimum_size.y = 108
		card.add_theme_stylebox_override("panel", inset_style(UI_SURFACE, RARITY_COLORS[rarity]))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 7)
		card.add_child(row)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(copy)
		var item_name := make_label(String(SERIES[series_index]["items"][item_index]), 12, UI_INK, true)
		item_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(item_name)
		copy.add_child(make_label("等级：%s" % RARITIES[rarity], 10, UI_INK_SOFT))
		copy.add_child(make_label("现价：¥%s" % comma(current), 11, UI_INK, true))
		copy.add_child(make_label("波动：%s" % _market_change_text(change), 10, UI_INK_SOFT))
		var thumbnail := button("", Color("#17202a"))
		thumbnail.name = "TrendThumbnail_%d" % item_index
		thumbnail.tooltip_text = "点击放大价格走势图"
		thumbnail.custom_minimum_size = Vector2(116, 88)
		thumbnail.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		thumbnail.pressed.connect(_show_exchange_chart.bind(content, series_index, item_index))
		row.add_child(thumbnail)
		var mini_prices: Array[float] = []
		var mini_dates: Array[int] = []
		for date_index in range(maxi(1, day - 6), day + 1):
			mini_prices.append(float(market_price_at_day(series_index, item_index, date_index)))
			mini_dates.append(date_index)
		var mini_chart := STALL_PRICE_CHART.new() as Control
		mini_chart.compact = true
		mini_chart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		thumbnail.add_child(mini_chart)
		mini_chart.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mini_chart.setup(mini_prices, mini_dates, RARITY_COLORS[rarity])
		content.add_child(card)


func _show_exchange_chart(content: VBoxContainer, series_index: int, item_index: int) -> void:
	clear_children(content)
	var back := button("◀ 返回%s" % SERIES[series_index]["name"], UI_CARBON)
	back.pressed.connect(_show_exchange_series.bind(content, series_index))
	content.add_child(back)
	var rarity := int(SERIES[series_index]["rarities"][item_index])
	content.add_child(section_label(String(SERIES[series_index]["items"][item_index])))
	content.add_child(make_label("%s｜今日市价 ¥%s" % [RARITIES[rarity], comma(market_price_at_day(series_index, item_index, day))], 12, RARITY_COLORS[rarity], true))
	var prices: Array[float] = []
	var dates: Array[int] = []
	for date_index in range(1, day + 1):
		prices.append(float(market_price_at_day(series_index, item_index, date_index)))
		dates.append(date_index)
	var chart := STALL_PRICE_CHART.new() as Control
	chart.name = "PriceHistoryChart"
	chart.custom_minimum_size = Vector2(282, 230)
	chart.clip_contents = true
	chart.setup(prices, dates, RARITY_COLORS[rarity])
	content.add_child(chart)
	var event := _market_event_for_day(day)
	var note := make_label("今日信息：%s\n%s" % [event["headline"], event["detail"]], 10, UI_INK_SOFT)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(note)


func _market_event_for_day(date_index: int) -> Dictionary:
	return MARKET_EVENTS[posmod(date_index - 1, MARKET_EVENTS.size())]


func _first_regular_item_index(series_index: int) -> int:
	for item_index in SERIES[series_index]["items"].size():
		if int(SERIES[series_index]["rarities"][item_index]) == 0:
			return item_index
	return 0


func _market_reference_price(series_index: int, item_index: int, date_index: int) -> int:
	if date_index <= 0:
		return int(STALL_VALUES[series_index][item_index])
	return market_price_at_day(series_index, item_index, date_index)


func _market_change_percent(current: int, previous: int) -> float:
	if previous <= 0: return 0.0
	return (float(current) / float(previous) - 1.0) * 100.0


func _market_change_text(change: float) -> String:
	if absf(change) < 0.05: return "— 0.0%"
	return "%s %.1f%%" % ["▲" if change > 0.0 else "▼", absf(change)]


func _build_superdog_app(content: VBoxContainer) -> void:
	content.add_child(section_label("超级小狗 / 装机店老板委托"))
	var dialogue := make_label("装机店老板：我儿子特别爱收集盲盒，为了集齐隐藏款已经花了大好几万。你把开出的隐藏款交给我，我拿电脑配件跟你换。\n\n主角：这样真的划算吗？\n老板：这个和我家小子花的钱比不算什么。", 11, UI_INK, true)
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.add_theme_stylebox_override("normal", inset_style(UI_SURFACE, UI_AMBER))
	content.add_child(dialogue)
	var progress := ProgressBar.new()
	progress.max_value = PC_PARTS.size()
	progress.value = pc_parts_owned
	progress.show_percentage = false
	progress.custom_minimum_size.y = 18
	content.add_child(progress)
	content.add_child(make_label("装机进度 %d / %d" % [pc_parts_owned, PC_PARTS.size()], 13, UI_CHROME_INDIGO, true))
	for index in PC_PARTS.size():
		var part: Dictionary = PC_PARTS[index]
		var owned_count := _matching_hidden_indices(part).size()
		var card := make_shop_card("阶段 %d｜%s" % [index + 1, part["name"]], "%s\n任务进度 %d/%d" % [part["detail"], mini(owned_count, int(part["count"])), int(part["count"])], Color("#f3b43f"))
		if index < pc_parts_owned:
			card["button"].text = "✓ 已购入"
			card["button"].disabled = true
		elif index == pc_parts_owned:
			card["button"].text = "提交隐藏款兑换"
			card["button"].disabled = owned_count < int(part["count"])
			card["button"].pressed.connect(_buy_pc_part.bind(index))
		else:
			card["button"].text = "完成上一阶段后解锁"
			card["button"].disabled = true
		content.add_child(card["panel"])
	if pc_parts_owned >= PC_PARTS.size():
		content.add_child(make_label("整机配件已经集齐。主角迫不及待地打开了游戏商店……", 12, UI_SIGNAL, true))


func _build_jimi_app(content: VBoxContainer) -> void:
	content.add_child(section_label("基米百货 / 摊位用品与经营升级"))
	content.add_child(make_label("白色大头小猫严选：货架、展示柜和摊位服务都在这里购买。", 11, UI_INK_SOFT))
	_add_upgrade_card(content, "亚克力展示台 Lv.%d" % stall_shelf_level, "增加 2 个桌面陈列位", 160 + stall_shelf_level * 240, _upgrade_shelf)
	_add_upgrade_card(content, "运动型背包 Lv.%d" % stall_inventory_level, "背包容量 +6", 120 + stall_inventory_level * 180, _upgrade_inventory)
	_add_upgrade_card(content, "给市场主管买的烟 Lv.%d" % stall_location_level, "将摊位移动到更好的位置，增加客流量。", 250 + stall_location_level * 400, _upgrade_location, stall_reputation >= (stall_location_level + 1) * 4)
	_add_upgrade_card(content, "特殊展示盒 Lv.%d" % stall_showcase_level, "高价值藏品提高驻足率", 400 + stall_showcase_level * 600, _upgrade_showcase)
	_add_upgrade_card(content, "十九子作剪刀 Lv.%d" % stall_multi_open_level, "进货批量：1 → 5 → 10", 300 + stall_multi_open_level * 700, _upgrade_multi, stall_multi_open_level < 2 and stall_reputation >= (stall_multi_open_level + 1) * 4)
	_add_upgrade_card(content, "《演员的自我修养》 Lv.%d" % stall_eloquence_level, "扩大顾客接受报价范围", 180 + stall_eloquence_level * 260, _upgrade_eloquence, stall_reputation >= (stall_eloquence_level + 1) * 3)


func _build_business_app(content: VBoxContainer) -> void:
	content.add_child(section_label("经营中心 / 今日账本"))
	content.add_child(make_label("今日访客 %d\n今日成交 %d\n今日营业额 ¥%s\n摊位声望 %d" % [stall_daily_visitors, stall_daily_sales, comma(stall_daily_revenue), stall_reputation], 13, UI_INK, true))
	var speed := button("试玩时间倍率：x%s" % str(stall_time_speed), UI_CARBON)
	speed.pressed.connect(_cycle_time_speed)
	content.add_child(speed)


func _add_upgrade_card(content: VBoxContainer, title: String, detail: String, cost: int, callable: Callable, gate := true) -> void:
	var card := make_shop_card(title, detail, UI_PERIWINKLE)
	card["button"].text = "升级 ¥%s" % comma(cost)
	card["button"].disabled = cash < cost or not gate
	card["button"].pressed.connect(callable)
	content.add_child(card["panel"])


func _toggle_phone() -> void:
	_set_phone_visible(not stall_phone_visible)


func _set_phone_visible(visible: bool, instant := false) -> void:
	stall_phone_visible = visible
	if stall_phone_toggle: stall_phone_toggle.visible = not visible
	if stall_backpack_toggle: stall_backpack_toggle.visible = not visible
	if stall_phone_collapse_button: stall_phone_collapse_button.visible = visible
	if stall_phone_tween and stall_phone_tween.is_valid():
		stall_phone_tween.kill()
	var target_y := 34.0 if visible else 735.0
	if instant:
		stall_phone.position.y = target_y
	else:
		stall_phone_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		stall_phone_tween.tween_property(stall_phone, "position:y", target_y, 0.28)


func _phone_status_text() -> String:
	if stall_day_finished: return "今日收摊｜等待结算"
	if stall_preparing: return "第 %d 天｜准备中 10:00｜现金 ¥%s" % [day, comma(cash)]
	return "第 %d 天｜营业 %s｜声望 %d" % [day, _clock_text(), stall_reputation]


func _update_app_unlocks() -> Array[String]:
	var newly_unlocked: Array[String] = []
	for app_id in APP_UNLOCK_RULES:
		if unlocked_apps.get(app_id, false): continue
		var rule: Dictionary = APP_UNLOCK_RULES[app_id]
		if cash >= int(rule["cash"]) and unlocked_series_count() >= int(rule["series"]):
			unlocked_apps[app_id] = true
			newly_unlocked.append(app_id)
	return newly_unlocked


func _app_unlocked(app_id: String) -> bool:
	return bool(unlocked_apps.get(app_id, false)) if APP_UNLOCK_RULES.has(app_id) else true


func _app_unlock_hint(app_id: String) -> String:
	if not APP_UNLOCK_RULES.has(app_id): return ""
	return "解锁条件：%s" % APP_UNLOCK_RULES[app_id]["label"]


func unlocked_series_count() -> int:
	var count := 0
	for index in SERIES.size():
		if series_unlocked(index): count += 1
	return count


func _has_hidden_collectible() -> bool:
	for item in collectibles:
		if not item.has("combination_id") and int(item.get("rarity", 0)) >= 4:
			return true
	for listing in stall_listings:
		if listing == null: continue
		var listed_item: Dictionary = listing["item"]
		if not listed_item.has("combination_id") and int(listed_item.get("rarity", 0)) >= 4:
			return true
	return false


func _publish_rare_photo() -> void:
	if stall_social_boost or not _has_hidden_collectible(): return
	stall_social_boost = true
	stall_spawn_wait = minf(stall_spawn_wait, 2.0)
	toast("隐藏款照片发布成功，今天更容易有顾客驻足。")
	_open_phone_app("social")


func _bind_authored_stall_scene() -> void:
	# 所有固定白盒都真实保存在 stall_demo.tscn；脚本只绑定节点并生成动态对象。
	stall_street_root = get_node("CSGAnimePedestrianStreet") as Node3D
	stall_fixture_root = get_node("StallCSGFixtures") as Node3D
	stall_shelf_root = get_node("StallCSGFixtures/CSGDisplayShelf") as Node3D
	# 顾客与行人使用步行街局部坐标，自动继承编辑器中对整条街设置的缩放与位移。
	stall_customer_root = get_node("CSGAnimePedestrianStreet/CSGCustomers") as Node3D
	stall_pedestrian_root = get_node("CSGAnimePedestrianStreet/CSGStreetPedestrians") as Node3D
	_rebuild_stall_shelf()


func _spawn_pc_shop_owner() -> void:
	if stall_pc_shop_owner and is_instance_valid(stall_pc_shop_owner): return
	stall_pc_shop_owner = _create_city_person(8, 1.10, 0)
	stall_pc_shop_owner.name = "PCShopOwnerNPC"
	stall_pc_shop_owner.position = Vector3(5.7, STREET_SURFACE_Y, STREET_CUSTOMER_Z - 0.35)
	stall_pc_shop_owner.rotation.y = 0.0
	stall_customer_root.add_child(stall_pc_shop_owner)
	var nameplate := Label3D.new()
	nameplate.text = "装机店老板\n隐藏款换电脑配件"
	nameplate.font_size = 28
	nameplate.pixel_size = 0.007
	nameplate.position = Vector3(0.0, 3.02, 0.0)
	nameplate.modulate = Color("#fff2c4")
	nameplate.outline_modulate = Color("#292237")
	nameplate.outline_size = 8
	nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	stall_pc_shop_owner.add_child(nameplate)
	var owner_hitbox := StaticBody3D.new()
	owner_hitbox.name = "PCShopOwnerHitbox"
	owner_hitbox.set_meta("stall_pc_shop_owner", true)
	var owner_collision := CollisionShape3D.new()
	var owner_shape := CapsuleShape3D.new()
	owner_shape.radius = 0.48
	owner_shape.height = 2.65
	owner_collision.shape = owner_shape
	owner_collision.position = Vector3(0.0, 1.35, 0.0)
	owner_hitbox.add_child(owner_collision)
	stall_pc_shop_owner.add_child(owner_hitbox)


func _rebuild_stall_shelf() -> void:
	stall_shelf_root.set("upgrade_level", stall_shelf_level)
	_render_stall_listings()


func _render_stall_listings() -> void:
	for child in stall_shelf_root.get_children():
		if child.name.begins_with("Listed_"):
			# 先从场景树移除，确保成交当帧货架上就看不到已售商品。
			stall_shelf_root.remove_child(child)
			child.queue_free()
	for index in stall_listings.size():
		if stall_listings[index] == null: continue
		var listing: Dictionary = stall_listings[index]
		var item: Dictionary = listing["item"]
		var holder := Node3D.new()
		holder.name = "Listed_%d" % index
		holder.position = _stall_slot_position(index)
		# 内容物统一以本地 -Y 为脸部正面；货架朝街一侧是世界 -Z。
		holder.basis = _stall_collectible_basis(Vector3(0.0, 0.0, -1.0))
		stall_shelf_root.add_child(holder)
		var listing_body := StaticBody3D.new()
		listing_body.name = "ListingHitbox_%d" % index
		listing_body.set_meta("stall_listing_slot", index)
		var listing_shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = Vector3(0.90, 1.55, 0.90)
		listing_shape.shape = box_shape
		listing_shape.position = Vector3(0.0, 0.65, 0.0)
		listing_body.add_child(listing_shape)
		holder.add_child(listing_body)
		var model := instantiate_collectible_model(int(item["series"]), int(item["item_index"]))
		if model:
			model.scale *= 0.72
			holder.add_child(model)
			var bounds_data := collectible_model_bounds(model)
			if bounds_data["valid"]:
				var shelf_bounds: AABB = Transform3D(holder.basis, Vector3.ZERO) * (bounds_data["bounds"] as AABB)
				model.position += holder.basis.inverse() * Vector3(0, -shelf_bounds.position.y, 0)
				listing_shape.position = holder.basis.inverse() * Vector3(0, shelf_bounds.size.y / 2.0, 0)
				listing_shape.basis = holder.basis.inverse()
				box_shape.size = Vector3(maxf(0.3, shelf_bounds.size.x), shelf_bounds.size.y, maxf(0.3, shelf_bounds.size.z))
		else:
			var fallback := CSGSphere3D.new()
			fallback.radius = 0.32
			fallback.position = holder.basis.inverse() * Vector3.UP * 0.32
			fallback.material = _stall_material(RARITY_COLORS[int(item["rarity"])] )
			holder.add_child(fallback)
		var tag := Label3D.new()
		tag.text = "%s\n¥%s" % [item["name"], comma(int(listing["price"]))]
		tag.font_size = 24
		tag.pixel_size = 0.006
		tag.modulate = UI_INK
		tag.outline_modulate = UI_SURFACE
		tag.outline_size = 5
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.position = Vector3(0, 0.92, 0)
		holder.add_child(tag)


func _stall_collectible_basis(front_direction: Vector3) -> Basis:
	var normalized_front := front_direction.normalized()
	var right_direction := Vector3.UP.cross(normalized_front).normalized()
	var up_direction := normalized_front.cross(right_direction).normalized()
	return Basis(right_direction, -normalized_front, up_direction).orthonormalized()


func _stall_slot_position(index: int) -> Vector3:
	return stall_shelf_root.call("slot_position", index)


func _stall_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	return material


func _build_stall_offer_ui() -> void:
	stall_offer_panel = PanelContainer.new()
	stall_offer_panel.position = Vector2(906, 18)
	stall_offer_panel.size = Vector2(354, 156)
	stall_offer_panel.visible = false
	stall_offer_panel.add_theme_stylebox_override("panel", chrome_style(UI_CANVAS))
	ui_canvas.add_child(stall_offer_panel)
	var column := VBoxContainer.new()
	stall_offer_panel.add_child(column)
	stall_offer_text = make_label("", 12, UI_INK, true)
	stall_offer_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stall_offer_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(stall_offer_text)
	stall_offer_button = button("查看报价", UI_SIGNAL)
	stall_offer_button.pressed.connect(_open_bargain)
	column.add_child(stall_offer_button)

	stall_bargain_panel = PanelContainer.new()
	stall_bargain_panel.position = Vector2(365, 82)
	stall_bargain_panel.size = Vector2(550, 554)
	stall_bargain_panel.visible = false
	stall_bargain_panel.add_theme_stylebox_override("panel", chrome_style(UI_CANVAS_SOFT))
	ui_canvas.add_child(stall_bargain_panel)
	var bargain_margin := MarginContainer.new()
	bargain_margin.add_theme_constant_override("margin_left", 18)
	bargain_margin.add_theme_constant_override("margin_right", 18)
	bargain_margin.add_theme_constant_override("margin_top", 30)
	bargain_margin.add_theme_constant_override("margin_bottom", 14)
	stall_bargain_panel.add_child(bargain_margin)
	stall_bargain_content = VBoxContainer.new()
	stall_bargain_content.add_theme_constant_override("separation", 7)
	bargain_margin.add_child(stall_bargain_content)


func _build_stall_price_ui() -> void:
	stall_price_panel = PanelContainer.new()
	stall_price_panel.position = Vector2(405, 185)
	stall_price_panel.size = Vector2(470, 350)
	stall_price_panel.visible = false
	stall_price_panel.add_theme_stylebox_override("panel", chrome_style(UI_CANVAS_SOFT))
	ui_canvas.add_child(stall_price_panel)
	var price_margin := MarginContainer.new()
	price_margin.add_theme_constant_override("margin_left", 16)
	price_margin.add_theme_constant_override("margin_right", 16)
	price_margin.add_theme_constant_override("margin_top", 18)
	price_margin.add_theme_constant_override("margin_bottom", 14)
	stall_price_panel.add_child(price_margin)
	stall_price_content = VBoxContainer.new()
	stall_price_content.add_theme_constant_override("separation", 8)
	price_margin.add_child(stall_price_content)


func _build_stall_day_ui() -> void:
	stall_day_panel = PanelContainer.new()
	stall_day_panel.position = Vector2(400, 170)
	stall_day_panel.size = Vector2(480, 370)
	stall_day_panel.visible = false
	stall_day_panel.add_theme_stylebox_override("panel", chrome_style(UI_CANVAS_SOFT))
	ui_canvas.add_child(stall_day_panel)
	var day_margin := MarginContainer.new()
	day_margin.add_theme_constant_override("margin_left", 16)
	day_margin.add_theme_constant_override("margin_right", 16)
	day_margin.add_theme_constant_override("margin_top", 18)
	day_margin.add_theme_constant_override("margin_bottom", 14)
	stall_day_panel.add_child(day_margin)
	stall_day_content = VBoxContainer.new()
	stall_day_content.add_theme_constant_override("separation", 9)
	day_margin.add_child(stall_day_content)


func _build_pause_menu() -> void:
	pause_overlay = ColorRect.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.color = Color(0.0, 0.0, 0.0, 0.68)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.z_index = 100
	pause_overlay.visible = false
	ui_canvas.add_child(pause_overlay)
	pause_panel = PanelContainer.new()
	pause_panel.position = Vector2(430, 128)
	pause_panel.size = Vector2(420, 464)
	pause_panel.add_theme_stylebox_override("panel", chrome_style(UI_CANVAS_SOFT))
	pause_overlay.add_child(pause_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	pause_panel.add_child(column)
	var title := make_label("暂停菜单", 30, UI_CHROME_INDIGO, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	column.add_child(make_label("当前经营进度可以随时保存，没有通关时限。", 12, UI_INK_SOFT))
	var save_button := button("保存游戏", UI_AMBER)
	save_button.custom_minimum_size.y = 56
	save_button.pressed.connect(_save_from_pause)
	column.add_child(save_button)
	pause_load_button = button("读取游戏", UI_PERIWINKLE)
	pause_load_button.custom_minimum_size.y = 56
	pause_load_button.pressed.connect(_load_from_pause)
	column.add_child(pause_load_button)
	var settings_button := button("设置", UI_SIGNAL)
	settings_button.custom_minimum_size.y = 56
	settings_button.pressed.connect(_pause_settings_placeholder)
	column.add_child(settings_button)
	var resume_button := button("返回游戏", UI_CARBON)
	resume_button.custom_minimum_size.y = 48
	resume_button.pressed.connect(close_pause_menu)
	column.add_child(resume_button)
	pause_status = make_label("再次按 Esc 或点击返回游戏即可继续。", 11, UI_INK_SOFT)
	pause_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(pause_status)


func _build_ending_ui() -> void:
	ending_overlay = Control.new()
	ending_overlay.name = "EndingSequence"
	ending_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ending_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ending_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	ending_overlay.z_index = 110
	ending_overlay.visible = false
	ending_overlay.gui_input.connect(_on_ending_gui_input)
	ui_canvas.add_child(ending_overlay)
	ending_background = TextureRect.new()
	ending_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ending_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ending_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ending_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_overlay.add_child(ending_background)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.24)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_overlay.add_child(shade)
	var caption := PanelContainer.new()
	caption.name = "EndingCaptionPanel"
	caption.position = Vector2(100, 500)
	caption.size = Vector2(1080, 180)
	PIXEL_UI_SKIN.apply_panel(caption, "dialogue_dark")
	ending_overlay.add_child(caption)
	var column := VBoxContainer.new()
	caption.add_child(column)
	ending_text = make_label("", 23, UI_SURFACE, true)
	ending_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ending_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ending_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(ending_text)
	ending_progress = make_label("", 12, UI_AMBER, true)
	ending_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(ending_progress)
	# Let the process-always overlay receive clicks even when the tree is paused.
	# No child, including the caption panel, may consume a story-advance click.
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in caption.find_children("*", "Control", true, false):
		(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func _unhandled_input(event: InputEvent) -> void:
	if ending_overlay and ending_overlay.visible: return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		open_pause_menu()
		get_viewport().set_input_as_handled()
		return
	if pause_overlay and pause_overlay.visible: return
	super._unhandled_input(event)


func open_pause_menu() -> void:
	if is_instance_valid(day_one_story) and day_one_story.visible: return
	if pause_overlay.visible: return
	pause_load_button.disabled = not _session().has_save()
	pause_status.text = "当前进度尚未保存。" if not _session().has_save() else "可以覆盖存档，或读取最近一次保存。"
	pause_overlay.visible = true
	_fit_game_panels()
	get_tree().process_frame.connect(_fit_game_panels, CONNECT_ONE_SHOT)
	get_tree().paused = true


func close_pause_menu() -> void:
	get_tree().paused = false
	if pause_overlay: pause_overlay.visible = false


func _save_from_pause() -> void:
	var error: int = _session().write_save(_capture_save_state())
	if error == OK:
		pause_status.text = "保存成功。继续游戏按钮现在已经可用。"
		pause_load_button.disabled = false
	else:
		pause_status.text = "保存失败，错误码：%d" % error


func _load_from_pause() -> void:
	if not _session().request_continue():
		pause_status.text = "没有找到可读取的存档。"
		pause_load_button.disabled = true
		return
	close_pause_menu()
	get_tree().reload_current_scene()


func _pause_settings_placeholder() -> void:
	pause_status.text = "设置界面占位：后续接入音量、画质、分辨率与操作灵敏度。"


func _start_ending_sequence() -> void:
	ending_index = 0
	_set_phone_visible(false, true)
	ending_overlay.visible = true
	_show_ending_page()
	get_tree().paused = true


func _on_ending_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		ending_index += 1
		if ending_index >= ENDING_TEXTS.size():
			get_tree().paused = false
			get_tree().change_scene_to_file(MAIN_MENU_SCENE)
			return
		_show_ending_page()
		ending_overlay.accept_event()


func _show_ending_page() -> void:
	ending_background.texture = ENDING_TEXTURES[ending_index]
	ending_text.text = ENDING_TEXTS[ending_index]
	ending_progress.text = "%d / %d　点击继续" % [ending_index + 1, ENDING_TEXTS.size()]


func focus_box(box: RigidBody3D) -> void:
	_set_phone_visible(false, true)
	super.focus_box(box)


func on_pointer_down(mouse_pos: Vector2) -> void:
	if not focused_box and not review_item and not stall_price_panel.visible and not stall_bargain_panel.visible:
		var hit := ray_hit(mouse_pos, false)
		var collider: Object = hit.get("collider") if not hit.is_empty() else null
		if collider and collider.has_meta("stall_listing_slot"):
			_edit_listing_price(int(collider.get_meta("stall_listing_slot")))
			return
		if collider and collider.has_meta("stall_pc_shop_owner"):
			_set_phone_visible(true)
			_open_phone_app("superdog")
			toast("装机店老板拿出了当前的隐藏款交换委托。")
			return
	super.on_pointer_down(mouse_pos)


func _edit_listing_price(slot: int) -> void:
	if slot < 0 or slot >= stall_listings.size() or stall_listings[slot] == null: return
	stall_price_item = (stall_listings[slot]["item"] as Dictionary).duplicate(true)
	stall_price_source = "listing"
	stall_price_listing_index = slot
	stall_price_inventory_index = -1
	_open_price_panel(inventory_item_price(stall_price_item))


func configure_seal_detaches(box: RigidBody3D) -> void:
	# 摆摊版彻底取消概率脱手节点。
	box.seal_detach_points.clear()
	box.seal_detach_index = 0


func seal_detach_probability(_box: RigidBody3D) -> float:
	return 0.0


func begin_seal_drag(mouse_pos: Vector2) -> void:
	if not focused_box: return
	pointer_mode = "seal_drag"
	seal_drag_last_position = mouse_pos
	detail_hint.text = "按住左键，沿%s连续撕开" % seal_pattern_name(focused_box)
	toast("抓住封条了。沿黄色纹路持续拖动即可撕开，不会随机脱手。")


func update_seal_drag(event: InputEventMouseMotion) -> void:
	if not focused_box or pointer_mode != "seal_drag": return
	var anchor_screen := camera.unproject_position(focused_box.active_seal_anchor_global())
	var next_screen := camera.unproject_position(focused_box.next_seal_anchor_global())
	var expected := (next_screen - anchor_screen).normalized()
	var motion := event.position - seal_drag_last_position
	seal_drag_last_position = event.position
	if motion.length() < 0.4 or expected.length() < 0.1: return
	var aligned_motion := motion.dot(expected)
	if aligned_motion <= 0.0: return
	var next_progress: float = focused_box.seal_progress + aligned_motion / seal_drag_force(focused_box)
	focused_box.set_seal_progress(next_progress)
	update_seal_progress_hud(focused_box)
	if focused_box.seal_progress >= 0.999:
		pointer_mode = "seal_detached"
		opening_sequence = true
		complete_drag_opening()


func update_seal_progress_hud(box: RigidBody3D) -> void:
	seal_bar.value = box.seal_progress * 100.0
	var side_text := ""
	if box.box_kind == "parcel": side_text = "%s封条 · " % box.active_parcel_side_name()
	var shake_text := ""
	if box.box_kind == "blind" and box.seal_progress <= 0.001:
		shake_text = "摇盒 %d/%d · " % [box.shake_count, shake_limit_for_box(box)]
	detail_hint.text = "%s%s%s · 撕开 %d%% · 无脱手判定" % [shake_text, side_text, seal_pattern_name(box), int(round(box.seal_progress * 100.0))]


func on_pointer_up(mouse_pos: Vector2) -> void:
	if pointer_mode == "seal_drag":
		pointer_mode = ""
		if focused_box and not opening_sequence:
			update_seal_progress_hud(focused_box)
			toast("封条进度已保留；可以从当前掀起端继续撕开。")
		return
	super.on_pointer_up(mouse_pos)


func begin_content_review() -> void:
	await super.begin_content_review()
	if review_item and not pending_item.is_empty():
		_prepare_stall_review_actions(review_new_badge != null)


func _prepare_stall_review_actions(is_new_discovery: bool) -> void:
	if pending_item.is_empty(): return
	var price := collectible_price(int(pending_item["series"]), int(pending_item["item_index"]))
	var remembered := _remembered_price(pending_item)
	_set_review_actions_disabled(false)
	sell_button.text = "按既定价上市｜¥%s" % comma(remembered) if remembered > 0 else "定价上市｜市价 ¥%s" % comma(price)
	# 新发现只负责收藏演出，绝不在这里自动打开定价面板。
	if is_new_discovery:
		toast("首次发现新摆件！选择“定价上市”时才会打开定价界面。")
	elif remembered <= 0:
		toast("这款尚未定价；选择“定价上市”后再设置挂牌价。")
	else:
		toast("内容物落定。再次上市将沿用既定价格，也可以计入库存。")


func resolve_review(list_now: bool) -> void:
	if review_animation_playing or not review_item or pending_item.is_empty(): return
	if list_now:
		if _first_empty_listing() < 0:
			toast("货架已满，请先售出或升级货架。")
			return
		if _remembered_price(pending_item) > 0:
			_list_item_with_remembered_price(pending_item, "review", -1)
			return
		stall_price_item = pending_item.duplicate(true)
		stall_price_source = "review"
		stall_price_inventory_index = -1
		_open_price_panel(inventory_item_price(stall_price_item))
		return
	if collectibles.size() >= stall_inventory_capacity:
		toast("库存已满，请先上架或使用扭扭处理重复款。")
		return
	var combinations := add_collectible_to_inventory(pending_item)
	_finish_review_choice("藏品已保留在手机库存。" if combinations.is_empty() else "自动合成：%s" % "、".join(combinations))


func _open_price_panel(market_value: int) -> void:
	stall_price_panel.visible = true
	clear_children(stall_price_content)
	var title_text := "修改 %s 的挂牌价" % stall_price_item["name"] if stall_price_source == "listing" else "为 %s 定价" % stall_price_item["name"]
	var title := make_label(title_text, 22, UI_CHROME_INDIGO, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stall_price_content.add_child(title)
	var market := make_label("今日参考市价 ¥%s" % comma(market_value), 14, UI_INK_SOFT, true)
	market.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stall_price_content.add_child(market)
	for ratio in [0.8, 1.0, 1.2, 1.5]:
		var price := maxi(1, int(round(market_value * ratio)))
		var price_button := button("%d%%｜挂牌 ¥%s" % [int(ratio * 100), comma(price)], UI_AMBER if ratio <= 1.0 else UI_SIGNAL)
		price_button.pressed.connect(_confirm_listing_price.bind(price))
		stall_price_content.add_child(price_button)
	if stall_price_source == "listing":
		var withdraw := button("撤回库存", UI_AMBER)
		withdraw.disabled = collectibles.size() >= stall_inventory_capacity
		withdraw.tooltip_text = "库存已满" if withdraw.disabled else "从货架取回，便于交付隐藏款任务"
		withdraw.pressed.connect(_withdraw_listing_to_inventory)
		stall_price_content.add_child(withdraw)
	var cancel := button("返回查看", UI_CARBON)
	cancel.pressed.connect(_cancel_price_panel)
	stall_price_content.add_child(cancel)
	call_deferred("_fit_game_panels")


func _confirm_listing_price(price: int) -> void:
	item_price_memory[_item_price_key(stall_price_item)] = price
	if stall_price_source == "listing":
		if stall_price_listing_index >= 0 and stall_price_listing_index < stall_listings.size() and stall_listings[stall_price_listing_index] != null:
			stall_listings[stall_price_listing_index]["price"] = price
			var edited_name := String(stall_price_item["name"])
			stall_price_panel.visible = false
			_render_stall_listings()
			toast("%s 的挂牌价已修改为 ¥%s，今后同款继续沿用。" % [edited_name, comma(price)])
			stall_price_item.clear()
			stall_price_source = ""
			stall_price_listing_index = -1
			return
	var slot := _first_empty_listing()
	if slot < 0:
		toast("货架已满。")
		return
	var item_name := String(stall_price_item["name"])
	stall_listings[slot] = {"item":stall_price_item.duplicate(true), "price":price}
	if stall_price_source == "inventory" and stall_price_inventory_index >= 0 and stall_price_inventory_index < collectibles.size():
		collectibles.remove_at(stall_price_inventory_index)
	stall_price_panel.visible = false
	_render_stall_listings()
	if stall_price_source == "review":
		_finish_review_choice("%s 已上架，挂牌 ¥%s。" % [item_name, comma(price)])
	else:
		toast("%s 已从库存上架，挂牌 ¥%s。" % [item_name, comma(price)])
		refresh_ui()
		if stall_phone_visible:
			_open_phone_app("inventory")
	stall_price_item.clear()
	stall_price_source = ""
	stall_price_inventory_index = -1
	stall_price_listing_index = -1


func _cancel_price_panel() -> void:
	stall_price_panel.visible = false
	stall_price_item.clear()
	stall_price_source = ""
	stall_price_inventory_index = -1
	stall_price_listing_index = -1


func _withdraw_listing_to_inventory() -> void:
	if stall_price_source != "listing": return
	if stall_price_listing_index < 0 or stall_price_listing_index >= stall_listings.size(): return
	if stall_listings[stall_price_listing_index] == null: return
	if collectibles.size() >= stall_inventory_capacity:
		toast("库存已满，无法撤回。")
		return
	var withdrawn_item: Dictionary = (stall_listings[stall_price_listing_index]["item"] as Dictionary).duplicate(true)
	stall_listings[stall_price_listing_index] = null
	collectibles.append(withdrawn_item)
	stall_price_panel.visible = false
	stall_price_item.clear()
	stall_price_source = ""
	stall_price_inventory_index = -1
	stall_price_listing_index = -1
	_render_stall_listings()
	refresh_ui()
	toast("%s 已撤回库存。" % withdrawn_item["name"])


func _finish_review_choice(message: String) -> void:
	if review_item:
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
	toast(message)
	refresh_ui()


func _price_inventory_item(index: int) -> void:
	if index < 0 or index >= collectibles.size() or _first_empty_listing() < 0: return
	if _remembered_price(collectibles[index]) > 0:
		_list_item_with_remembered_price(collectibles[index], "inventory", index)
		return
	stall_price_item = collectibles[index].duplicate(true)
	stall_price_source = "inventory"
	stall_price_inventory_index = index
	_open_price_panel(inventory_item_price(stall_price_item))


func _item_price_key(item: Dictionary) -> String:
	if item.has("combination_id"): return "combo:%s" % String(item["combination_id"])
	return "%d:%d" % [int(item.get("series", -1)), int(item.get("item_index", -1))]


func _set_review_actions_disabled(disabled: bool) -> void:
	for child in action_row.get_children():
		if child is Button: (child as Button).disabled = disabled


func _remembered_price(item: Dictionary) -> int:
	return int(item_price_memory.get(_item_price_key(item), 0))


func _list_item_with_remembered_price(item: Dictionary, source: String, inventory_index: int) -> void:
	var slot := _first_empty_listing()
	if slot < 0: return
	var price := _remembered_price(item)
	if price <= 0: return
	stall_listings[slot] = {"item":item.duplicate(true), "price":price}
	if source == "inventory" and inventory_index >= 0 and inventory_index < collectibles.size():
		collectibles.remove_at(inventory_index)
	_render_stall_listings()
	if source == "review":
		_finish_review_choice("%s 已按既定价 ¥%s 上架。" % [item["name"], comma(price)])
	else:
		toast("%s 已按既定价 ¥%s 从库存上架。" % [item["name"], comma(price)])
		refresh_ui()
		if stall_phone_visible: _open_phone_app("inventory")


func _first_empty_listing() -> int:
	for index in stall_listings.size():
		if stall_listings[index] == null: return index
	return -1


func _start_business() -> void:
	if not stall_preparing or stall_day_finished: return
	stall_preparing = false
	stall_business_elapsed = 0.0
	stall_daily_revenue = 0
	stall_daily_sales = 0
	stall_daily_visitors = 0
	stall_spawn_wait = 2.0
	stall_pedestrian_spawn_wait = 0.2
	# Opening never seeds people inside the visible street.
	_set_phone_visible(false)
	toast("摊位开店。顾客开始经过，营业时间开始流逝。")
	refresh_ui()


func _finish_business_day() -> void:
	if stall_day_finished: return
	var closing_clock := _clock_text()
	var closed_early := stall_business_elapsed < BUSINESS_SECONDS - 0.1
	stall_day_finished = true
	stall_offer_panel.visible = false
	_clear_customer()
	_clear_pedestrians()
	_set_phone_visible(false, true)
	clear_children(stall_day_content)
	var title := make_label("%s｜第 %d 天%s" % [closing_clock, day, "提前闭店" if closed_early else "打烊"], 26, UI_CHROME_INDIGO, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stall_day_content.add_child(title)
	var report := make_label("今日路过顾客：%d\n成交：%d 单\n营业额：¥%s\n当前现金：¥%s\n当前声望：%d" % [stall_daily_visitors, stall_daily_sales, comma(stall_daily_revenue), comma(cash), stall_reputation], 16, UI_INK, true)
	report.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stall_day_content.add_child(report)
	var next := button("进入第 %d 天准备阶段" % (day + 1), UI_SIGNAL)
	next.pressed.connect(_begin_next_day)
	stall_day_content.add_child(next)
	stall_day_panel.visible = true
	refresh_ui()
	if day == 1 and not day_one_story_seen: _start_day_one_story()


func _start_day_one_story() -> void:
	stall_day_panel.hide()
	day_one_story.start()
	get_tree().paused = true


func _finish_day_one_story() -> void:
	day_one_story_seen = true
	get_tree().paused = false
	stall_day_panel.show()


func _begin_next_day() -> void:
	day += 1
	stall_preparing = true
	stall_day_finished = false
	stall_business_elapsed = 0.0
	stall_order_accepted = false
	stall_order_completed = false
	stall_social_boost = false
	stall_day_panel.visible = false
	_set_phone_visible(true)
	_show_phone_home()
	var event := _market_event_for_day(day)
	toast("第 %d 天准备阶段｜集换处已更新：%s" % [day, event["headline"]])
	refresh_ui()


func _buy_series_count(series_index: int, count: int) -> void:
	if not series_unlocked(series_index):
		var previous := series_index - 1
		toast("需要累计开启 %d 盒%s，当前 %d/%d。" % [SERIES_OPEN_REQUIREMENTS[series_index], SERIES[previous]["name"], series_open_counts[previous], SERIES_OPEN_REQUIREMENTS[series_index]])
		return
	var cost := box_price(series_index) * count
	if cash < cost:
		toast("现金不足，还差 ¥%s。" % comma(cost - cash))
		return
	cash -= cost
	for index in count:
		spawn_box("blind", series_index, roll_content(series_index), box_price(series_index), index % 5)
	toast("%d 盒 %s 已送到桌面。" % [count, SERIES[series_index]["name"]])
	refresh_ui()
	_open_phone_app("supply")


func buy_box(series_index: int) -> void:
	_buy_series_count(series_index, 1)


func _resale_all_inventory() -> void:
	var resale_indices := _duplicate_resale_indices()
	var payout := 0
	for index in resale_indices:
		payout += int(round(inventory_item_price(collectibles[index]) * RESALE_MULTIPLIER))
	resale_indices.reverse()
	for index in resale_indices:
		collectibles.remove_at(index)
	cash += payout
	toast("扭扭已回收重复款，按当前市价六折到账 ¥%s。" % comma(payout))
	refresh_ui()
	_open_phone_app("resale")


func _duplicate_resale_indices() -> Array[int]:
	var protected_once := {}
	var result: Array[int] = []
	for index in collectibles.size():
		var item: Dictionary = collectibles[index]
		var key := "combo:%s" % String(item.get("combination_id", "")) if item.has("combination_id") else "%d:%d" % [int(item.get("series", -1)), int(item.get("item_index", -1))]
		if protected_once.has(key):
			result.append(index)
		else:
			protected_once[key] = true
	return result


func _accept_daily_order() -> void:
	stall_order_accepted = true
	toast("已接取悬赏：提交两件肥嘟嘟伙伴。")
	_open_phone_app("orders")


func _deliver_daily_order() -> void:
	var indices: Array[int] = []
	for index in collectibles.size():
		if int(collectibles[index]["series"]) == 0:
			indices.append(index)
			if indices.size() == 2: break
	if indices.size() < 2:
		toast("库存中还没有两件肥嘟嘟伙伴。")
		return
	indices.reverse()
	for index in indices: collectibles.remove_at(index)
	cash += 120
	stall_reputation += 3
	stall_order_completed = true
	toast("悬赏完成：到账 ¥120，声望 +3。")
	refresh_ui()
	_open_phone_app("orders")


func _upgrade_shelf() -> void:
	var cost := 160 + stall_shelf_level * 240
	if not _pay_upgrade(cost): return
	stall_shelf_level += 1
	stall_listings.append_array([null, null])
	_rebuild_stall_shelf()
	_after_upgrade("货架增加 2 个陈列位。")


func _upgrade_inventory() -> void:
	var cost := 120 + stall_inventory_level * 180
	if not _pay_upgrade(cost): return
	stall_inventory_level += 1
	stall_inventory_capacity += 6
	_after_upgrade("库存容量增加 6。")


func _upgrade_location() -> void:
	var cost := 250 + stall_location_level * 400
	if stall_reputation < (stall_location_level + 1) * 4 or not _pay_upgrade(cost): return
	stall_location_level += 1
	_after_upgrade("摊位位置升级，顾客经过得更频繁。")


func _upgrade_showcase() -> void:
	var cost := 400 + stall_showcase_level * 600
	if not _pay_upgrade(cost): return
	stall_showcase_level += 1
	_after_upgrade("特殊展示盒升级，高价藏品更容易吸引顾客。")


func _upgrade_multi() -> void:
	var cost := 300 + stall_multi_open_level * 700
	if stall_multi_open_level >= 2 or stall_reputation < (stall_multi_open_level + 1) * 4 or not _pay_upgrade(cost): return
	stall_multi_open_level += 1
	_after_upgrade("连开能力升级，进货页已开放更大批量。")


func _upgrade_eloquence() -> void:
	var cost := 180 + stall_eloquence_level * 260
	if stall_reputation < (stall_eloquence_level + 1) * 3 or not _pay_upgrade(cost): return
	stall_eloquence_level += 1
	_after_upgrade("口才升级，顾客的接受区间扩大。")


func _pay_upgrade(cost: int) -> bool:
	if cash < cost:
		toast("现金不足。")
		return false
	cash -= cost
	return true


func _after_upgrade(message: String) -> void:
	toast(message)
	refresh_ui()
	_open_phone_app("jimi")


func _buy_pc_part(index: int) -> void:
	if index != pc_parts_owned or index < 0 or index >= PC_PARTS.size(): return
	var part: Dictionary = PC_PARTS[index]
	var matching := _matching_hidden_indices(part)
	var required := int(part["count"])
	if matching.size() < required:
		toast("隐藏款不足：%s。" % part["detail"])
		return
	matching.resize(required)
	matching.sort()
	matching.reverse()
	for inventory_index in matching:
		collectibles.remove_at(inventory_index)
	pc_parts_owned += 1
	_play_pc_part_unlock_vfx()
	toast("老板收下隐藏款，交付了%s。装机阶段 %d/8 完成。" % [part["name"], pc_parts_owned])
	refresh_ui()
	_session().write_save(_capture_save_state())
	if pc_parts_owned >= PC_PARTS.size():
		call_deferred("_start_ending_sequence")
	else:
		_open_phone_app("superdog")


func _matching_hidden_indices(part: Dictionary) -> Array[int]:
	var result: Array[int] = []
	for index in collectibles.size():
		var item: Dictionary = collectibles[index]
		if item.has("combination_id"): continue
		if int(item.get("rarity", 0)) != int(part["rarity"]): continue
		if int(part["series"]) >= 0 and int(item.get("series", -1)) != int(part["series"]): continue
		result.append(index)
	return result


func _cycle_time_speed() -> void:
	stall_time_speed = 4.0 if stall_time_speed == 1.0 else (12.0 if stall_time_speed == 4.0 else 1.0)
	toast("试玩营业时间倍率切换为 x%s。" % str(stall_time_speed))
	_open_phone_app("business")


func _update_pedestrians(delta: float) -> void:
	# Substeps prevent tunnelling when the demo time multiplier is enabled.
	if delta > 0.05:
		var count := int(ceil(delta / 0.05))
		for step in count: _update_pedestrians(delta / count)
		return
	stall_pedestrian_spawn_wait -= delta
	var arrival_factor := clampf((BUSINESS_SECONDS - stall_business_elapsed) / (BUSINESS_SECONDS / 10.0), 0.0, 1.0)
	var crowd_limit := int(ceil(mini(22, 3 + stall_location_level * 3) * arrival_factor))
	if arrival_factor > 0.05 and stall_pedestrian_spawn_wait <= 0.0 and stall_pedestrians.size() < crowd_limit:
		_spawn_background_pedestrian()
		stall_pedestrian_spawn_wait = rng.randf_range(5.0, 7.0) / (1.0 + stall_location_level * 0.65) / maxf(arrival_factor, 0.05)
	for index in range(stall_pedestrians.size() - 1, -1, -1):
		var data: Dictionary = stall_pedestrians[index]
		var pedestrian = data["node"]
		if not is_instance_valid(pedestrian):
			stall_pedestrians.remove_at(index)
			continue
		var direction := float(data["direction"])
		var speed := float(data["speed"])
		_walk_with_avoidance(pedestrian, Vector3(pedestrian.position.x + direction * 2.0, STREET_SURFACE_Y, float(data["lane"])), speed, delta)
		if pedestrian.position.x * direction > 14.0:
			pedestrian.queue_free()
			stall_pedestrians.remove_at(index)


func _spawn_background_pedestrian(initial_x: float = INF) -> void:
	var direction := 1.0 if rng.randf() < 0.5 else -1.0
	var lane_z: float = -6.5 if direction > 0 else -9.3
	var start_x := -14.0 if direction > 0.0 else 14.0
	if is_finite(initial_x): start_x = initial_x
	if not _street_position_clear(null, Vector3(start_x, STREET_SURFACE_Y, lane_z)): return
	# Identity is assigned before entering view and stays with this person.
	# Most potential buyers are ordinary fans; a separate pool only passes by.
	var roll := rng.randf()
	var category: int = 1 if roll < 0.60 else ([0, 2, 3, 4][rng.randi_range(0, 3)] if roll < 0.75 else rng.randi_range(5, 7))
	var used: Array = []
	for entry in stall_pedestrians: used.append(entry["node"].get_meta("model_asset"))
	if is_instance_valid(stall_customer): used.append(stall_customer.get_meta("model_asset"))
	var variants: Array[int] = []
	for variant in 3:
		if not CITY_PERSON.MODEL_POOLS[category][variant] in used: variants.append(variant)
	if variants.is_empty(): return
	var pedestrian = _create_city_person(category, rng.randf_range(0.90, 1.05), variants[rng.randi_range(0, variants.size() - 1)])
	pedestrian.position = Vector3(start_x, STREET_SURFACE_Y, lane_z)
	pedestrian.rotation.y = atan2(direction, 0.0)
	stall_pedestrian_root.add_child(pedestrian)
	var speed := rng.randf_range(1.05, 1.75)
	pedestrian.set_walking(true, speed)
	stall_pedestrians.append({"node":pedestrian, "direction":direction, "speed":speed, "profile":category, "lane":lane_z})


func _clear_pedestrians() -> void:
	for data in stall_pedestrians:
		var pedestrian := data["node"] as Node3D
		if is_instance_valid(pedestrian): pedestrian.queue_free()
	stall_pedestrians.clear()


func _create_city_person(category: int, person_scale: float, variant := -1) -> Node3D:
	var person := CITY_PERSON.new()
	person.setup(category, person_scale, rng.randi_range(0, 2) if variant < 0 else variant)
	return person


func _street_position_clear(actor: Node3D, point: Vector3) -> bool:
	var others: Array = []
	for entry in stall_pedestrians: others.append(entry["node"])
	if is_instance_valid(stall_customer): others.append(stall_customer)
	for other in others:
		if other == actor or not is_instance_valid(other): continue
		if point.distance_to(other.position) < 1.35: return false
	return true


func _walk_with_avoidance(actor: Node3D, target: Vector3, speed: float, delta: float) -> bool:
	var remaining := delta
	while remaining > 0.00001:
		var dt := minf(remaining, 0.04)
		remaining -= dt
		var old := actor.position
		var next := old.move_toward(target, speed * dt)
		if not _street_position_clear(actor, next):
			# Yield into the central passing lane, or wait if both sides are busy.
			var preferred := 1.0 if old.z < -7.9 else -1.0
			for side in [preferred, -preferred]:
				var detour := old + Vector3(0, 0, side * speed * dt)
				if detour.z < -9.5 or detour.z > -6.1: continue
				if _street_position_clear(actor, detour):
					next = detour
					break
			if not _street_position_clear(actor, next): next = old
		actor.position = next
		actor.face_direction(next - old, dt)
		actor.set_walking(next.distance_squared_to(old) > 0.000001, speed)
	return actor.position.distance_to(target) < 0.02


func _update_customer(delta: float) -> void:
	if stall_customer == null:
		stall_spawn_wait -= delta
		if stall_spawn_wait <= 0.0: _spawn_customer()
		return
	match stall_customer_phase:
		"approach":
			# Walk diagonally out of the passing lane, easing into a front-facing stop.
			if _walk_with_avoidance(stall_customer, Vector3(0.5, STREET_SURFACE_Y, STREET_CUSTOMER_Z), 1.25, delta):
				stall_customer.set_walking(false)
				stall_customer_phase = "browse"
				stall_customer_wait = 2.2
		"browse", "offer":
			stall_customer.set_walking(false)
			stall_customer.face_direction(Vector3(0, 0, 1), delta)
			stall_customer_wait -= delta
			if stall_customer_wait <= 0.0:
				if stall_customer_phase == "browse":
					_make_customer_offer()
				else:
					toast("顾客等得有点久，先去别处逛了。")
					stall_offer_panel.visible = false
					stall_customer_phase = "leave"
		"leave":
			if _walk_with_avoidance(stall_customer, stall_customer_exit_target, 1.35, delta):
				# Rejoin the original stream as the exact same actor.
				var returning := stall_customer
				returning.reparent(stall_pedestrian_root, true)
				stall_pedestrians.append({"node":returning, "direction":stall_customer_direction, "speed":1.35, "profile":returning.profile_index, "lane":stall_customer_lane})
				stall_customer = null
				_clear_customer()


func _spawn_customer() -> void:
	# Recruit an existing, visible walker; never spawn a sideways-sliding customer.
	var candidates: Array[int] = []
	for index in stall_pedestrians.size():
		var data: Dictionary = stall_pedestrians[index]
		var person := data["node"] as Node3D
		if not is_instance_valid(person) or int(data["profile"]) >= CUSTOMER_PROFILES.size(): continue
		var x := person.position.x
		if absf(x - 0.5) < 3.5 and absf(x - 0.5) > 0.7 and (0.5 - x) * float(data["direction"]) > 0.0:
			candidates.append(index)
	if candidates.is_empty():
		stall_spawn_wait = 0.5
		return
	var selected := candidates[rng.randi_range(0, candidates.size() - 1)]
	var data: Dictionary = stall_pedestrians[selected]
	stall_customer = data["node"]
	stall_customer_profile = CUSTOMER_PROFILES[int(data["profile"])]
	stall_customer_lane = float(data["lane"])
	stall_customer_direction = float(data["direction"])
	stall_customer_exit_target = Vector3(0.5 + stall_customer_direction * 2.4, STREET_SURFACE_Y, stall_customer_lane)
	stall_pedestrians.remove_at(selected)
	stall_customer.reparent(stall_customer_root, true)
	stall_customer_phase = "approach"
	stall_daily_visitors += 1


func _make_customer_offer() -> void:
	var filled: Array[int] = []
	for index in stall_listings.size():
		if stall_listings[index] != null: filled.append(index)
	if filled.is_empty():
		stall_customer_phase = "leave"
		return
	stall_offer_slot = filled[rng.randi_range(0, filled.size() - 1)]
	var listing: Dictionary = stall_listings[stall_offer_slot]
	var item: Dictionary = listing["item"]
	var market_value := inventory_item_price(item)
	stall_offer_price = mini(int(listing["price"]), maxi(1, int(round(market_value * float(stall_customer_profile["offer"])))))
	stall_customer_max = minf(float(listing["price"]) * 1.05, market_value * float(stall_customer_profile["budget"]))
	if stall_customer_profile["name"] == "普通爱好者":
		# A normal fan either accepts the tag or asks for a modest 10% discount.
		stall_offer_price = maxi(1, int(round(int(listing["price"]) * (1.0 if rng.randf() < 0.65 else 0.90))))
		stall_customer_max = float(listing["price"])
	stall_bargain_round = 0
	stall_offer_text.text = "%s：\n“%s”\n看中 %s，报价 ¥%s" % [stall_customer_profile["name"], stall_customer_profile["quote"], item["name"], comma(stall_offer_price)]
	stall_offer_button.text = "查看报价 ¥%s" % comma(stall_offer_price)
	stall_offer_panel.visible = true
	stall_customer_wait = 15.0
	stall_customer_phase = "offer"
	_set_phone_visible(false)


func _open_bargain() -> void:
	if stall_offer_slot < 0 or stall_listings[stall_offer_slot] == null: return
	stall_offer_panel.visible = false
	stall_bargain_panel.visible = true
	if stall_offer_price >= int(stall_listings[stall_offer_slot]["price"]):
		clear_children(stall_bargain_content)
		stall_bargain_content.alignment = BoxContainer.ALIGNMENT_CENTER
		stall_bargain_slider = null
		var title := make_label("按挂牌价购买", 22, UI_CHROME_INDIGO, true)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stall_bargain_content.add_child(title)
		var detail := make_label("%s 想以 ¥%s 购买 %s。" % [stall_customer_profile["name"], comma(stall_offer_price), stall_listings[stall_offer_slot]["item"]["name"]], 16, UI_INK)
		stall_bargain_content.add_child(detail)
		var accept := button("成交 · ¥%s" % comma(stall_offer_price), UI_AMBER)
		accept.pressed.connect(_complete_customer_sale.bind(stall_offer_price))
		stall_bargain_content.add_child(accept)
		var decline := button("暂不出售", UI_CARBON)
		decline.pressed.connect(_decline_offer)
		stall_bargain_content.add_child(decline)
		call_deferred("_fit_game_panels")
		return
	_rebuild_bargain("上下拖动滑块，给出你的价格。")


func _rebuild_bargain(message: String) -> void:
	clear_children(stall_bargain_content)
	stall_bargain_content.alignment = BoxContainer.ALIGNMENT_BEGIN
	var listing: Dictionary = stall_listings[stall_offer_slot]
	var item: Dictionary = listing["item"]
	var title := make_label("与 %s 讲价" % stall_customer_profile["name"], 21, UI_CHROME_INDIGO, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.custom_minimum_size.y = 36
	stall_bargain_content.add_child(title)
	var quote := make_label("“%s”" % stall_customer_profile["quote"], 13, UI_SIGNAL, true)
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote.custom_minimum_size.y = 42
	stall_bargain_content.add_child(quote)
	var detail := make_label("%s｜挂牌 ¥%s｜顾客报价 ¥%s" % [item["name"], comma(int(listing["price"])), comma(stall_offer_price)], 11, UI_INK, true)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size.y = 25
	stall_bargain_content.add_child(detail)
	var status := make_label(message, 11, UI_INK_SOFT)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 28
	stall_bargain_content.add_child(status)
	var slider_row := HBoxContainer.new()
	slider_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stall_bargain_content.add_child(slider_row)
	stall_bargain_slider = VSlider.new()
	stall_bargain_slider.custom_minimum_size = Vector2(90, 140)
	stall_bargain_slider.min_value = maxi(1, int(round(inventory_item_price(item) * 0.55)))
	stall_bargain_slider.max_value = maxi(int(listing["price"] * 1.15), int(stall_customer_max * 1.18))
	stall_bargain_slider.step = 1
	stall_bargain_slider.value = stall_offer_price
	stall_bargain_slider.value_changed.connect(_on_bargain_changed)
	slider_row.add_child(stall_bargain_slider)
	stall_bargain_amount = make_label("你的报价：¥%s" % comma(stall_offer_price), 18, UI_SIGNAL, true)
	stall_bargain_amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stall_bargain_content.add_child(stall_bargain_amount)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 8)
	var accept := button("接受 ¥%s" % comma(stall_offer_price), Color("#59c7b5"))
	accept.custom_minimum_size.y = 46
	accept.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	accept.pressed.connect(_complete_customer_sale.bind(stall_offer_price))
	stall_bargain_content.add_child(accept)
	stall_bargain_content.add_child(buttons)
	var counter := button("提交报价", UI_SIGNAL)
	counter.custom_minimum_size.y = 46
	counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	counter.pressed.connect(_submit_counter_offer)
	buttons.add_child(counter)
	var decline := button("不卖了", UI_CARBON)
	decline.custom_minimum_size.y = 46
	decline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	decline.pressed.connect(_decline_offer)
	buttons.add_child(decline)
	call_deferred("_fit_game_panels")


func _on_bargain_changed(value: float) -> void:
	if stall_bargain_amount:
		stall_bargain_amount.text = "你的报价：¥%s" % comma(int(value))


func _submit_counter_offer() -> void:
	var proposed := int(stall_bargain_slider.value)
	var effective_max := stall_customer_max * (1.0 + stall_eloquence_level * 0.055)
	if proposed <= effective_max:
		_complete_customer_sale(proposed)
		return
	stall_bargain_round += 1
	if proposed <= effective_max * 1.12 and stall_bargain_round < 3:
		stall_offer_price = int(round((stall_offer_price + effective_max) * 0.5))
		_rebuild_bargain("顾客皱了皱眉，又加了一点。口才 Lv.%d" % stall_eloquence_level)
	else:
		stall_bargain_panel.visible = false
		toast("价格谈崩了：顾客说下次一定。")
		stall_customer_phase = "leave"


func _complete_customer_sale(price: int) -> void:
	if stall_offer_slot < 0 or stall_listings[stall_offer_slot] == null: return
	var listing: Dictionary = stall_listings[stall_offer_slot]
	var item: Dictionary = listing["item"]
	var listed_price := int(listing["price"])
	var income_vfx_position := Vector3.ZERO
	if stall_customer and is_instance_valid(stall_customer):
		income_vfx_position = stall_customer.to_global(Vector3(0.0, 1.62, 0.0))
		income_vfx_position += (camera.global_position - income_vfx_position).normalized() * 0.18
	stall_listings[stall_offer_slot] = null
	cash += price
	earned += price
	stall_daily_revenue += price
	stall_daily_sales += 1
	var rep_gain := 1 + int(item["rarity"]) / 2
	stall_reputation += rep_gain
	stall_offer_panel.visible = false
	stall_bargain_panel.visible = false
	stall_customer_phase = "leave"
	stall_offer_slot = -1
	_render_stall_listings()
	if not income_vfx_position.is_zero_approx():
		_play_customer_income_vfx(price, listed_price, income_vfx_position)
	toast("成交！%s 售出 ¥%s，声望 +%d。" % [item["name"], comma(price), rep_gain])
	refresh_ui()


func _play_customer_income_vfx(sale_price: int, listed_price: int, world_position: Vector3) -> void:
	if sale_price == listed_price: return
	var path := _income_vfx_path(sale_price, listed_price)
	var effect := play_world_spritesheet_vfx(path, world_position, INCOME_VFX_SCREEN_FRACTION, 42.0)
	if effect: effect.name = "IncomeLowVFX" if sale_price < listed_price else "IncomeHighVFX"


func _income_vfx_path(sale_price: int, listed_price: int) -> String:
	if sale_price < listed_price: return INCOME_LOW_VFX_PATH
	if sale_price > listed_price: return INCOME_HIGH_VFX_PATH
	return ""


func _play_pc_part_unlock_vfx() -> void:
	if not ui_canvas: return
	var viewport_size := get_viewport().get_visible_rect().size
	var frame_size := 512.0
	var edge_texture := load(PC_UNLOCK_EDGE_VFX_PATH) as Texture2D
	if edge_texture:
		var edge = UI_SPRITESHEET_VFX.new()
		edge.name = "PCUnlockEdgeVFX"
		edge.position = viewport_size * 0.5
		edge.scale = Vector2(viewport_size.x / frame_size, viewport_size.y / frame_size) * PC_UNLOCK_VFX_SCALE_MULTIPLIER
		edge.z_index = 500
		ui_canvas.add_child(edge)
		edge.configure(edge_texture, 48.0, true)
	var center_texture := load(PC_UNLOCK_CENTER_VFX_PATH) as Texture2D
	if center_texture:
		var center = UI_SPRITESHEET_VFX.new()
		center.name = "PCUnlockCenterVFX"
		center.position = viewport_size * 0.5
		var center_size := minf(viewport_size.x, viewport_size.y) * 0.80
		center.scale = Vector2.ONE * (center_size / frame_size)
		center.z_index = 501
		ui_canvas.add_child(center)
		center.configure(center_texture, 48.0, true)


func _decline_offer() -> void:
	stall_offer_panel.visible = false
	stall_bargain_panel.visible = false
	stall_customer_phase = "leave"
	stall_offer_slot = -1
	toast("你拒绝了报价，商品继续留在货架。")


func _clear_customer() -> void:
	if stall_customer:
		stall_customer.queue_free()
	stall_customer = null
	stall_customer_phase = ""
	stall_offer_slot = -1
	stall_offer_panel.visible = false
	stall_spawn_wait = maxf(3.0, rng.randf_range(10.0, 16.0) - stall_location_level * 1.4 - (3.0 if stall_social_boost else 0.0))


func refresh_ui() -> void:
	super.refresh_ui()
	if not ui_canvas: return
	money_label.text = "现金\n¥%s" % comma(cash)
	value_label.text = "库存总价值\n¥%s" % comma(total_inventory_value())
	date_label.text = "第 %d 天 · %s" % [day, "准备中 10:00" if stall_preparing else ("已闭店 %s" % _clock_text() if stall_day_finished else "营业中 %s" % _clock_text())]
	var next_series: int = unlocked_series_count()
	if next_series >= SERIES.size():
		player_level_label.text = "盲盒系列 5/5 · 全部解锁"
		player_level_bar.value = 100.0
	else:
		var required: int = int(SERIES_OPEN_REQUIREMENTS[next_series])
		var opened: int = int(series_open_counts[next_series - 1])
		player_level_label.text = "下一系列：开%s %d/%d" % [SERIES[next_series - 1]["name"], mini(opened, required), required]
		player_level_bar.value = float(opened) / float(required) * 100.0
	if stall_business_button:
		stall_business_button.text = "已闭店" if stall_day_finished else ("开店" if stall_preparing else "提前闭店")
		stall_business_button.disabled = stall_day_finished
	var newly_unlocked := _update_app_unlocks()
	if stall_ready:
		if not newly_unlocked.is_empty():
			if stall_current_app == "home": _show_phone_home()
			var app_names := {"social":"大蓝书", "orders":"毒", "resale":"扭扭", "exchange":"集换处"}
			var unlocked_names: Array[String] = []
			for app_id in newly_unlocked: unlocked_names.append(String(app_names[app_id]))
			toast("新手机应用已解锁：%s。" % "、".join(unlocked_names))
		_update_stall_clock()
		if stall_current_app == "home" and stall_phone_status:
			stall_phone_status.text = _phone_status_text()


func _update_stall_clock() -> void:
	if not stall_phone_clock: return
	stall_phone_clock.text = _clock_text()
	if not stall_preparing and not stall_day_finished:
		date_label.text = "第 %d 天 · 营业中 %s" % [day, _clock_text()]


func _clock_text() -> String:
	if stall_preparing: return "10:00"
	var hour_value: float = BUSINESS_START + clampf(stall_business_elapsed / BUSINESS_SECONDS, 0.0, 1.0) * (BUSINESS_END - BUSINESS_START)
	var hour := int(floor(hour_value))
	var minute := int(floor((hour_value - hour) * 60.0))
	return "%02d:%02d" % [hour, minute]


func item_weights_for_series(series_index: int) -> Array[int]:
	var result: Array[int] = []
	if series_index < 0 or series_index >= SERIES.size(): return result
	result.resize(SERIES[series_index]["items"].size())
	result.fill(0)
	var rarity_totals: Array = STALL_FIXED_RARITY_WEIGHTS[series_index]
	for rarity in RARITIES.size():
		var indices := item_indices_for_rarity(series_index, rarity)
		if not indices.is_empty() and int(rarity_totals[rarity]) > 0:
			assign_weight_total(result, series_index, indices, int(rarity_totals[rarity]))
	return result


func upgrade_luck() -> void:
	toast("摆摊版爆率固定；幸运只会作为单次道具或事件加成出现。")


func series_unlocked(index: int) -> bool:
	if index < 0 or index >= SERIES_OPEN_REQUIREMENTS.size(): return false
	if index == 0: return true
	return series_open_counts[index - 1] >= SERIES_OPEN_REQUIREMENTS[index]


func player_level() -> int:
	return unlocked_series_count()


func box_price(index: int) -> int:
	if index < 0 or index >= STALL_BOX_PRICES.size(): return 1
	return STALL_BOX_PRICES[index]


func market_price_at_day(series_index: int, item_index: int, date_index: int) -> int:
	if series_index < 0 or series_index >= STALL_VALUES.size(): return 1
	if item_index < 0 or item_index >= STALL_VALUES[series_index].size(): return 1
	var rarity: int = int(SERIES[series_index]["rarities"][item_index])
	var market_factor: float = float(FACTORS[(date_index - 1) % FACTORS.size()][series_index])
	var event: Dictionary = _market_event_for_day(date_index)
	var event_factor := float(event["modifiers"][series_index])
	var softened := 1.0 + (market_factor - 1.0) * (0.35 + rarity * 0.06) + (event_factor - 1.0) * (0.72 + rarity * 0.04)
	return maxi(1, int(round(float(STALL_VALUES[series_index][item_index]) * softened)))


func inventory_item_price(item: Dictionary) -> int:
	if not item.has("combination_id"):
		return collectible_price(int(item["series"]), int(item["item_index"]))
	return 8000 if String(item["combination_id"]) == "angel_complete" else 18000


func register_discovery(item: Dictionary) -> void:
	var key := "%d_%d" % [item["series"], item["item_index"]]
	if not discovered.has(key):
		discovered[key] = true
		toast("NEW！首次发现 %s。" % item["name"])


func _capture_save_state() -> Dictionary:
	var inventory_snapshot: Array = collectibles.duplicate(true)
	if not pending_item.is_empty(): inventory_snapshot.append(pending_item.duplicate(true))
	var saved_boxes: Array = []
	for node in boxes:
		if not is_instance_valid(node) or node.opened: continue
		var box := node as RigidBody3D
		var saved_transform := focus_origin if box == focused_box else box.global_transform
		saved_boxes.append({
			"kind": box.box_kind, "series": box.series_index, "item": box.item_index, "paid": box.paid_price,
			"position": _vector_to_array(saved_transform.origin), "rotation": _vector_to_array(saved_transform.basis.get_euler()),
			"seal_progress": box.seal_progress, "parcel_side": box.parcel_seal_side,
		})
	return {
		"save_version": 1, "cash": cash, "day": day, "earned": earned,
		"day_one_story_seen": day_one_story_seen,
		"collectibles": inventory_snapshot, "discovered": discovered.duplicate(true),
		"series_open_counts": series_open_counts.duplicate(), "series_levels": series_levels.duplicate(),
		"parcel_open_count": parcel_open_count, "parcel_level": parcel_level,
		"stall_reputation": stall_reputation, "stall_shelf_level": stall_shelf_level,
		"stall_inventory_level": stall_inventory_level, "stall_location_level": stall_location_level,
		"stall_showcase_level": stall_showcase_level, "stall_multi_open_level": stall_multi_open_level,
		"stall_eloquence_level": stall_eloquence_level, "stall_inventory_capacity": stall_inventory_capacity,
		"stall_listings": stall_listings.duplicate(true), "stall_preparing": stall_preparing,
		"stall_day_finished": stall_day_finished, "stall_business_elapsed": stall_business_elapsed,
		"stall_time_speed": stall_time_speed, "stall_daily_revenue": stall_daily_revenue,
		"stall_daily_sales": stall_daily_sales, "stall_daily_visitors": stall_daily_visitors,
		"stall_order_accepted": stall_order_accepted, "stall_order_completed": stall_order_completed,
		"stall_social_boost": stall_social_boost, "unlocked_apps": unlocked_apps.duplicate(true),
		"item_price_memory": item_price_memory.duplicate(true),
		"pc_parts_owned": pc_parts_owned, "boxes": saved_boxes,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
	}


func _apply_save_state(state: Dictionary) -> void:
	cash = int(state.get("cash", 130))
	day = maxi(1, int(state.get("day", 1)))
	day_one_story_seen = bool(state.get("day_one_story_seen", day > 1))
	earned = int(state.get("earned", 0))
	stall_reputation = int(state.get("stall_reputation", 0))
	stall_shelf_level = int(state.get("stall_shelf_level", 0))
	stall_inventory_level = int(state.get("stall_inventory_level", 0))
	stall_location_level = int(state.get("stall_location_level", 0))
	stall_showcase_level = int(state.get("stall_showcase_level", 0))
	stall_multi_open_level = int(state.get("stall_multi_open_level", 0))
	stall_eloquence_level = int(state.get("stall_eloquence_level", 0))
	stall_inventory_capacity = int(state.get("stall_inventory_capacity", 12))
	stall_preparing = bool(state.get("stall_preparing", true))
	stall_day_finished = bool(state.get("stall_day_finished", false))
	stall_business_elapsed = float(state.get("stall_business_elapsed", 0.0))
	stall_time_speed = float(state.get("stall_time_speed", 1.0))
	stall_daily_revenue = int(state.get("stall_daily_revenue", 0))
	stall_daily_sales = int(state.get("stall_daily_sales", 0))
	stall_daily_visitors = int(state.get("stall_daily_visitors", 0))
	stall_order_accepted = bool(state.get("stall_order_accepted", false))
	stall_order_completed = bool(state.get("stall_order_completed", false))
	stall_social_boost = bool(state.get("stall_social_boost", false))
	unlocked_apps = (state.get("unlocked_apps", {"social":true}) as Dictionary).duplicate(true)
	unlocked_apps["social"] = true
	item_price_memory = (state.get("item_price_memory", {}) as Dictionary).duplicate(true)
	pc_parts_owned = clampi(int(state.get("pc_parts_owned", 0)), 0, PC_PARTS.size())
	collectibles.clear()
	for value in state.get("collectibles", []):
		if value is Dictionary: collectibles.append(_canonicalize_collectible_data(value as Dictionary))
	discovered = (state.get("discovered", {}) as Dictionary).duplicate(true)
	series_open_counts = _restore_int_array(state.get("series_open_counts", []), SERIES.size())
	series_levels = _restore_int_array(state.get("series_levels", []), SERIES.size())
	parcel_open_count = int(state.get("parcel_open_count", 0))
	parcel_level = int(state.get("parcel_level", 0))
	stall_listings.clear()
	for value in state.get("stall_listings", []):
		if value is Dictionary:
			var listing_data := (value as Dictionary).duplicate(true)
			if listing_data.get("item") is Dictionary:
				listing_data["item"] = _canonicalize_collectible_data(listing_data["item"] as Dictionary)
			stall_listings.append(listing_data)
		else:
			stall_listings.append(null)
	while stall_listings.size() < 4 + stall_shelf_level * 2: stall_listings.append(null)
	for listing in stall_listings:
		if listing is Dictionary and listing.has("item") and listing.has("price"):
			var listed_item := listing["item"] as Dictionary
			if not item_price_memory.has(_item_price_key(listed_item)):
				item_price_memory[_item_price_key(listed_item)] = int(listing["price"])
	for node in boxes.duplicate():
		if is_instance_valid(node): node.queue_free()
	boxes.clear()
	var box_slot := 0
	for value in state.get("boxes", []):
		if not value is Dictionary: continue
		var data := value as Dictionary
		var series_index := int(data.get("series", -1))
		var item_index := int(data.get("item", -1))
		if series_index >= SERIES.size() or (series_index >= 0 and item_index >= SERIES[series_index]["items"].size()): continue
		spawn_box(String(data.get("kind", "blind")), series_index, item_index, int(data.get("paid", 0)), box_slot % 5)
		box_slot += 1
		var box := boxes.back() as RigidBody3D
		box.global_position = _array_to_vector(data.get("position", []), box.global_position)
		box.rotation = _array_to_vector(data.get("rotation", []), box.rotation)
		box.parcel_seal_side = int(data.get("parcel_side", 0))
		box.set_seal_progress(clampf(float(data.get("seal_progress", 0.0)), 0.0, 1.0))
	_rebuild_stall_shelf()
	if pc_parts_owned >= PC_PARTS.size(): call_deferred("_start_ending_sequence")
	elif stall_day_finished: call_deferred("_restore_day_end_ui")


func _restore_day_end_ui() -> void:
	stall_day_finished = false
	_finish_business_day()


func _canonicalize_collectible_data(source: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	var series_index := int(result.get("series", -1))
	var item_index := int(result.get("item_index", -1))
	if series_index >= 0 and series_index < SERIES.size() and item_index >= 0 and item_index < SERIES[series_index]["items"].size():
		result["name"] = SERIES[series_index]["items"][item_index]
		result["rarity"] = SERIES[series_index]["rarities"][item_index]
	return result


func _restore_int_array(source: Array, target_size: int) -> Array:
	var result: Array = []
	for index in target_size: result.append(int(source[index]) if index < source.size() else 0)
	return result


func _vector_to_array(value: Vector3) -> Array:
	return [value.x, value.y, value.z]


func _array_to_vector(value: Array, fallback: Vector3) -> Vector3:
	if value.size() < 3: return fallback
	return Vector3(float(value[0]), float(value[1]), float(value[2]))


func _session() -> Node:
	return get_node("/root/GameSession")


func end_day_pressed() -> void:
	if stall_day_finished: return
	if stall_preparing:
		_start_business()
	else:
		_finish_business_day()


func is_over_secondhand_bin(_world_position: Vector3) -> bool:
	return false
