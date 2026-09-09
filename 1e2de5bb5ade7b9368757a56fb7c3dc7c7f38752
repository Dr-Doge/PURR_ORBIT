extends SceneTree

const STALL := preload("res://scripts/stall_demo/stall_demo.gd")
const MENU := preload("res://scripts/frontend/main_menu.gd")


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _run() -> void:
	if MENU.INTRO_TEXTS.size() != 5 or MENU.INTRO_TEXTURES.size() != 5:
		_fail("序章必须包含五段字幕和五张可替换背景。")
		return
	if MENU.INTRO_TEXTS[0] != "暑假某天的下午：" or not MENU.INTRO_TEXTS[4].begins_with("爷，你委屈一下"):
		_fail("序章字幕内容与策划台词不一致。")
		return
	if STALL.RESALE_MULTIPLIER != 0.60:
		_fail("扭扭回收倍率必须为当前市价的0.6倍。")
		return
	if STALL.REVEAL_VFX_SCREEN_FRACTION != 1.60 or STALL.INCOME_VFX_SCREEN_FRACTION != 0.72 or STALL.PC_UNLOCK_VFX_SCALE_MULTIPLIER != 2.0:
		_fail("VFX 缩放未按要求设置：开盒背景需要在上一版基础上再放大 2 倍。")
		return
	if STALL.REVIEW_MODEL_SCALE_MULTIPLIER != 2.0 or STALL.REVIEW_ITEM_CAMERA_DISTANCE >= STALL.REVIEW_VFX_CAMERA_DISTANCE:
		_fail("开盒展示模型没有放大 2 倍，或模型没有位于 VFX 前方。")
		return
	if STALL.REVIEW_VERTICAL_OFFSET <= 0.0:
		_fail("开盒摆件与 VFX 没有整体上移，仍可能被底部详情 UI 遮挡。")
		return
	if STALL.OPENED_BOX_SHRINK_DURATION != 0.34 or STALL.OPENED_BOX_FINAL_SCALE > 0.002:
		_fail("打开后的盲盒没有使用快速平滑缩小退场。")
		return
	if STALL.PC_PARTS.size() != 8:
		_fail("装机主线必须包含八个阶段。")
		return
	var expected_parts := ["case", "cooler", "psu", "storage", "motherboard", "cpu", "memory", "gpu"]
	for index in expected_parts.size():
		if String(STALL.PC_PARTS[index]["id"]) != expected_parts[index] or STALL.PC_PARTS[index].has("price"):
			_fail("电脑配件顺序错误，或仍然与现金价格强绑定。")
			return
	if STALL.SERIES_OPEN_REQUIREMENTS != [0, 8, 12, 18, 25]:
		_fail("盲盒系列没有按上一系列开盒数量阶段解锁。")
		return
	for series_index in STALL.STALL_VALUES.size():
		for item_index in STALL.SERIES[series_index]["items"].size():
			if int(STALL.SERIES[series_index]["rarities"][item_index]) != 0: continue
			var ratio := float(STALL.STALL_VALUES[series_index][item_index]) / float(STALL.STALL_BOX_PRICES[series_index])
			if not is_equal_approx(ratio, 1.5):
				_fail("%s常规款基础市价不是盒价1.5倍。" % STALL.SERIES[series_index]["name"])
				return
	for asset_path in [
		"res://assets/ui/app_icon/大蓝书.png",
		"res://assets/ui/app_icon/毒.png",
		"res://assets/ui/app_icon/扭扭.png",
		"res://assets/ui/app_icon/交换社.png",
		"res://assets/ui/app_icon/超级小狗.png",
		"res://assets/ui/app_icon/基米.png",
		"res://assets/placeholders/story/sky.jpg",
		"res://assets/placeholders/story/GDA6.jpg",
		"res://assets/placeholders/story/balance.jpg",
		"res://assets/placeholders/story/moon_city.jpg",
		"res://assets/placeholders/story/table.jpg",
		"res://assets/placeholders/story/pc.jpg",
		"res://assets/placeholders/story/exclusive.jpg",
		"res://assets/VFX/开出特效_普通款.png",
		"res://assets/VFX/开出特效_小隐藏.png",
		"res://assets/VFX/开出特效_大隐藏.png",
		"res://assets/VFX/待机背景_普通款.png",
		"res://assets/VFX/待机背景_小隐藏.png",
		"res://assets/VFX/待机背景_大隐藏.png",
		"res://assets/VFX/收入_多.png",
		"res://assets/VFX/收入_少.png",
		"res://assets/VFX/屏幕中央礼花.png",
		"res://assets/VFX/屏幕边缘礼花.png",
	]:
		if not ResourceLoader.exists(asset_path):
			_fail("缺少剧情或应用图标资产：%s" % asset_path)
			return
	var expected_custom_icons := {
		"social":"res://assets/ui/app_icon/大蓝书.png",
		"orders":"res://assets/ui/app_icon/毒.png",
		"resale":"res://assets/ui/app_icon/扭扭.png",
		"exchange":"res://assets/ui/app_icon/交换社.png",
		"superdog":"res://assets/ui/app_icon/超级小狗.png",
		"jimi":"res://assets/ui/app_icon/基米.png",
	}
	for app_id in expected_custom_icons:
		if String(STALL.PHONE_APP_ICONS[app_id]) != String(expected_custom_icons[app_id]):
			_fail("手机应用没有使用对应的新图标：%s" % app_id)
			return
	for removed_placeholder in [
		"res://assets/placeholders/story/intro_sky.svg",
		"res://assets/placeholders/story/intro_gda6.svg",
		"res://assets/placeholders/story/intro_balance.svg",
		"res://assets/placeholders/story/intro_moon_city.svg",
		"res://assets/placeholders/story/intro_table.svg",
		"res://assets/placeholders/story/ending_pc.svg",
		"res://assets/placeholders/story/ending_exclusive.svg",
	]:
		if FileAccess.file_exists(removed_placeholder):
			_fail("旧剧情占位资产仍未删除：%s" % removed_placeholder)
			return
	var menu_packed := load("res://scenes/frontend/main_menu.tscn") as PackedScene
	var menu = menu_packed.instantiate()
	root.add_child(menu)
	await process_frame
	if (menu.get_node("Background") as TextureRect).texture != MENU.INTRO_TEXTURES[0]:
		_fail("开始界面没有使用序章 SKY 背景图。")
		return
	var caption_panel := menu.get_node("StoryLayer/CaptionPanel") as PanelContainer
	var caption_style := caption_panel.get_theme_stylebox("panel") as StyleBoxTexture
	var caption_color := (menu.get_node("StoryLayer/CaptionPanel/CaptionContent/StoryText") as Label).get_theme_color("font_color")
	if caption_panel.position.y < 480.0 or caption_style == null or caption_style.texture.resource_path != STALL.PIXEL_UI_SKIN.HUD_DIALOGUE_PANEL:
		_fail("序章字幕没有位于屏幕下方，或没有换用 HUD 对话框素材。")
		return
	if not caption_color.is_equal_approx(STALL.PIXEL_UI_SKIN.INK):
		_fail("序章字幕没有使用 Dialogue 预览对应的深色文字。")
		return
	if menu.get_node_or_null("StoryLayer/StorySpeakerPlate") == null:
		_fail("剧情对话框缺少 Dialogue 预览中的说话者名牌组合。")
		return
	if menu.get_node("MenuContent/PixelTitlePlate").owner != menu or caption_panel.owner != menu:
		_fail("主菜单最终 UI 仍由脚本临时生成，无法在编辑器中直接编排。")
		return
	menu._start_new_game()
	var caption_click := InputEventMouseButton.new()
	caption_click.button_index = MOUSE_BUTTON_LEFT
	caption_click.pressed = true
	caption_click.position = Vector2(640, 600)
	menu._input(caption_click)
	if menu.intro_index != 1:
		_fail("点击剧情文本框范围没有进入下一段字幕。")
		return
	var menu_button_style := (menu.get_node("MenuContent/Buttons/NewGame") as Button).get_theme_stylebox("normal") as StyleBoxTexture
	if menu_button_style == null or menu_button_style.texture.resource_path != STALL.PIXEL_UI_SKIN.HUD_QUEST_LIST_OFF:
		_fail("开始界面按钮没有替换为图示要求的 Lists 卡片素材。")
		return
	menu.story_layer.visible = false
	menu.queue_free()
	await process_frame
	var packed := load("res://scenes/stall_demo/stall_demo.tscn") as PackedScene
	var stall = packed.instantiate()
	root.add_child(stall)
	await process_frame
	var count_probe := {"series":0, "item_index":0, "rarity":0, "name":"冬日暖意"}
	stall.collectibles.clear()
	stall.collectibles.append(count_probe.duplicate(true))
	stall.collectibles.append(count_probe.duplicate(true))
	stall.collectibles.append({"series":0, "item_index":1, "rarity":0, "name":"度假搭档"})
	if stall.inventory_same_item_count(count_probe) != 2:
		_fail("开盒结算没有正确统计库存中的同款摆件数量。")
		return
	stall.collectibles.clear()
	stall.pending_item = count_probe.duplicate(true)
	stall.stall_price_panel.visible = false
	stall.item_price_memory.erase(stall._item_price_key(count_probe))
	stall._prepare_stall_review_actions(true)
	if stall.stall_price_panel.visible or not stall.sell_button.text.begins_with("定价上市"):
		_fail("首次开出摆件时仍会自动弹出定价面板，或左侧按钮文案错误。")
		return
	stall._refresh_review_inventory_count()
	if stall.keep_button.text != "计入库存（同款 0）":
		_fail("右下角计入库存按钮没有显示同款库存数量。")
		return
	stall._show_new_discovery_feedback()
	await process_frame
	var side_confetti := stall.ui_canvas.find_child("NewDiscoverySideConfettiVFX", true, false) as Sprite2D
	var new_badge := stall.ui_canvas.find_child("NewDiscoveryBadge", true, false) as Label
	if side_confetti == null or new_badge == null or new_badge.text != "NEW!":
		_fail("首次发现没有建立双侧礼花与红色 NEW 艺术字。")
		return
	var visible_size := stall.get_viewport().get_visible_rect().size
	var frame_size := Vector2(float(side_confetti.texture.get_width()) / 8.0, float(side_confetti.texture.get_height()) / 8.0)
	if not is_equal_approx(side_confetti.scale.x * frame_size.x, visible_size.x) or not is_equal_approx(side_confetti.scale.y * frame_size.y, visible_size.y):
		_fail("首次发现双侧礼花没有精确拉伸匹配游戏窗口。")
		return
	stall._clear_new_discovery_badge()
	stall.pending_item.clear()
	var shrink_box := RigidBody3D.new()
	stall.add_child(shrink_box)
	stall._shrink_opened_blind_box(shrink_box)
	await create_timer(STALL.OPENED_BOX_SHRINK_DURATION * 0.5).timeout
	if not is_instance_valid(shrink_box) or shrink_box.scale.x >= 0.95:
		_fail("盲盒退场中途没有保留节点并平滑缩小。")
		return
	await create_timer(STALL.OPENED_BOX_SHRINK_DURATION * 0.65).timeout
	await process_frame
	if is_instance_valid(shrink_box):
		_fail("盲盒缩小至不可见后没有释放节点。")
		return
	var owner_npc := stall.find_child("PCShopOwnerNPC", true, false)
	if owner_npc == null or owner_npc.find_child("PCShopOwnerHitbox", true, false) == null:
		_fail("步行街场景中缺少装机店老板 NPC。")
		return
	if stall.stall_phone_home_button == null or stall.stall_phone_home_button.name != "PhysicalHomeButton":
		_fail("手机屏幕下方缺少实体主页导航键。")
		return
	var phone_frame := stall.stall_phone.get_node_or_null("PixelPhoneFrame") as TextureRect
	if phone_frame == null or phone_frame.texture.resource_path != STALL.PIXEL_UI_SKIN.PHONE_FRAME:
		_fail("手机没有替换为 Phone UI elements 外壳素材。")
		return
	var phone_rect: Rect2 = stall.stall_phone.get_global_rect()
	var viewport_rect: Rect2 = stall.get_viewport().get_visible_rect()
	if not viewport_rect.encloses(phone_rect):
		_fail("展开手机超出游戏窗口，文字与图标无法全部留在完整边框内。")
		return
	var layout_authoring := stall.get_node_or_null("UILayoutAuthoring") as CanvasLayer
	var authored_phone := stall.get_node_or_null("UILayoutAuthoring/Slots/BaseHUD/Phone") as Control
	if layout_authoring == null or layout_authoring.visible or authored_phone == null or authored_phone.get_rect() != stall.stall_phone.get_rect():
		_fail("经营 UI 没有读取编辑器可见的 UILayoutAuthoring 编排场景。")
		return
	var authored_bag_icon := stall.get_node("UILayoutAuthoring/Slots/CollapsedShortcuts/BackpackShortcut/Icon") as TextureRect
	var runtime_bag_icon := stall.stall_backpack_toggle.get_node("ShortcutIcon") as TextureRect
	if authored_bag_icon.get_rect() != runtime_bag_icon.get_rect():
		_fail("手工编排的背包快捷图标内部位置与尺寸没有同步到游戏。")
		return
	var projected_item: Vector2 = stall.camera.unproject_position(stall.review_layer_position(STALL.REVIEW_ITEM_CAMERA_DISTANCE))
	var projected_vfx: Vector2 = stall.camera.unproject_position(stall.review_layer_position(STALL.REVIEW_VFX_CAMERA_DISTANCE))
	if projected_item.distance_to(projected_vfx) > 1.0 or projected_item.y >= stall.get_viewport().get_visible_rect().size.y * 0.5:
		_fail("上移后的摆件与 VFX 没有保持屏幕中心对齐，或仍停留在画面下半部。")
		return
	var collapse_rect: Rect2 = stall.stall_phone_collapse_button.get_global_rect()
	if not stall.stall_phone_collapse_button.visible or not viewport_rect.encloses(collapse_rect) or collapse_rect.position.y < phone_rect.end.y - 8.0:
		_fail("手机下方缺少清晰可见且不越界的下箭头收起按钮。")
		return
	var phone_grids: Array[Node] = stall.stall_phone_page.find_children("*", "GridContainer", true, false)
	var phone_grid: GridContainer = phone_grids[0] as GridContainer if not phone_grids.is_empty() else null
	if phone_grid == null or phone_grid.columns != 3 or phone_grid.get_child_count() != 8 or phone_grid.find_child("AppTile_inventory", true, false) != null:
		_fail("手机主页没有保持三列布局，或仍然保留了库存 App 图标。")
		return
	var review_detail: String = stall.review_detail_text(0)
	for forbidden_text in ["熟练", "当前概率", "当前市价"]:
		if review_detail.contains(forbidden_text):
			_fail("开盒内容物面板仍显示不需要的信息：%s" % forbidden_text)
			return
	if stall.review_title_color(4) != STALL.REVIEW_TITLE_SMALL_HIDDEN_COLOR or stall.review_title_color(5) != STALL.REVIEW_TITLE_BIG_HIDDEN_COLOR:
		_fail("小隐藏与大隐藏名称没有分别使用紫色和橙色。")
		return
	stall._set_phone_visible(false, true)
	if not stall.stall_phone_toggle.visible or not stall.stall_backpack_toggle.visible:
		_fail("手机收起后没有显示手机与背包 HUD 快捷图标。")
		return
	var phone_shortcut_icon := stall.stall_phone_toggle.get_node("ShortcutIcon") as TextureRect
	var backpack_shortcut_icon := stall.stall_backpack_toggle.get_node("ShortcutIcon") as TextureRect
	if not phone_shortcut_icon.texture.resource_path.ends_with("UI_Icon_Phone.png") or not backpack_shortcut_icon.texture.resource_path.ends_with("UI_Icon_SchoolBag.png"):
		_fail("手机／背包快捷入口没有使用 Diary 的 Phone 与 SchoolBag 图标。")
		return
	if stall.stall_phone_collapse_button.visible:
		_fail("手机收起后下箭头仍未隐藏。")
		return
	if not viewport_rect.encloses(stall.stall_phone_toggle.get_global_rect()) or not viewport_rect.encloses(stall.stall_backpack_toggle.get_global_rect()) or stall.stall_phone_toggle.get_global_rect().intersects(stall.stall_backpack_toggle.get_global_rect()):
		_fail("右下角手机与背包图标越界或互相重叠。")
		return
	stall._set_phone_visible(true, true)
	var pause_skin := stall.pause_panel.get_theme_stylebox("panel") as StyleBoxTexture
	if pause_skin == null or pause_skin.texture.resource_path != STALL.PIXEL_UI_SKIN.HUD_PAUSE_PANEL:
		_fail("Esc 菜单没有替换为 HUD 暂停面板素材。")
		return
	if stall.stall_business_button == null or stall.stall_business_button.text != "开店":
		_fail("左上 HUD 底部没有复用开店／提前闭店按键。")
		return
	if STALL.MARKET_EVENTS.size() < 7:
		_fail("集换处需要足够的每日行情事件形成价格走势。")
		return
	if stall._income_vfx_path(79, 100) != STALL.INCOME_LOW_VFX_PATH or stall._income_vfx_path(121, 100) != STALL.INCOME_HIGH_VFX_PATH or not stall._income_vfx_path(100, 100).is_empty():
		_fail("顾客成交 VFX 没有按成交价与挂牌价的高低正确分流。")
		return
	var reveal_vfx: Node3D = stall.create_reveal_burst(4)
	if reveal_vfx.find_child("OpeningVFX", true, false) == null or reveal_vfx.find_child("StandbyVFX", true, false) == null:
		_fail("开盒揭晓没有同时建立开出特效与待机背景 spritesheet。")
		return
	stall.add_child(reveal_vfx)
	await create_timer(1.05).timeout
	var standby_vfx := reveal_vfx.find_child("StandbyVFX", true, false) as Sprite3D
	if reveal_vfx.find_child("OpeningVFX", true, false) != null or standby_vfx == null or not standby_vfx.visible:
		_fail("开出特效结束后没有自动过渡到循环待机背景。")
		return
	reveal_vfx.queue_free()
	for event in STALL.MARKET_EVENTS:
		if not event.has("headline") or (event["modifiers"] as Array).size() != STALL.SERIES.size():
			_fail("集换处行情事件缺少标题或五系列修正值。")
			return
	for series_index in STALL.SERIES.size():
		if stall.box_price(series_index) != STALL.STALL_BOX_PRICES[series_index]:
			_fail("行情事件不应改变盲盒进货价。")
			return
	if stall.series_unlocked(1):
		_fail("第二系列不应在未开启足量第一系列盲盒时解锁。")
		return
	stall.series_open_counts = [8, 12, 18, 0, 0]
	if not stall.series_unlocked(1) or not stall.series_unlocked(2) or not stall.series_unlocked(3) or stall.series_unlocked(4):
		_fail("盲盒系列开盒数量解锁链计算错误。")
		return
	stall.cash = 249
	stall._update_app_unlocks()
	if not stall._app_unlocked("social") or stall._app_unlocked("orders") or stall._app_unlocked("resale") or stall._app_unlocked("exchange"):
		_fail("手机阶段应用的初始锁定状态错误。")
		return
	stall.cash = 250
	stall._update_app_unlocks()
	if not stall._app_unlocked("orders") or stall._app_unlocked("resale"):
		_fail("毒 App 没有在第二阶段单独解锁。")
		return
	stall.cash = 500
	stall._update_app_unlocks()
	if not stall._app_unlocked("resale") or stall._app_unlocked("exchange"):
		_fail("扭扭 App 没有在第三阶段单独解锁。")
		return
	stall.cash = 1000
	stall._update_app_unlocks()
	if not stall._app_unlocked("exchange"):
		_fail("集换处 App 没有在第四阶段解锁。")
		return
	stall._open_phone_app("exchange")
	var exchange_content := stall.stall_phone_page.find_child("AppContent", true, false) as VBoxContainer
	if exchange_content == null:
		_fail("手机集换处没有成功建立内容页。")
		return
	var has_market_news := false
	for label in exchange_content.find_children("*", "Label", true, false):
		if (label as Label).text.contains("今日快讯"):
			has_market_news = true
			break
	if not has_market_news:
		_fail("集换处没有显示当日行情快讯。")
		return
	stall._show_exchange_series(exchange_content, 0)
	if exchange_content.find_child("TrendThumbnail_0", true, false) == null:
		_fail("集换处摆件卡片右侧没有可点击趋势缩略图。")
		return
	stall._show_exchange_chart(exchange_content, 0, 0)
	if exchange_content.find_child("PriceHistoryChart", true, false) == null:
		_fail("集换处没有生成内容物价格曲线。")
		return
	stall.collectibles.clear()
	stall.collectibles.append({"series":0, "item_index":9, "rarity":4, "name":"国王"})
	var cash_before_exchange: int = int(stall.cash)
	stall.pc_parts_owned = 0
	stall._buy_pc_part(0)
	if stall.pc_parts_owned != 1 or stall.cash != cash_before_exchange or not stall.collectibles.is_empty():
		_fail("装机店老板没有用隐藏款兑换配件，或仍然扣除了现金。")
		return
	if stall.ui_canvas.find_child("PCUnlockCenterVFX", true, false) == null or stall.ui_canvas.find_child("PCUnlockEdgeVFX", true, false) == null:
		_fail("电脑配件解锁没有播放屏幕中央与边缘礼花。")
		return
	var price_memory_item := {"series":0, "item_index":0, "rarity":0, "name":"冬日暖意"}
	stall.item_price_memory[stall._item_price_key(price_memory_item)] = 45
	if stall._remembered_price(price_memory_item) != 45:
		_fail("同款摆件没有记住单次定价。")
		return
	stall.stall_listings[0] = {"item":price_memory_item.duplicate(true), "price":45}
	stall.stall_price_source = "listing"
	stall.stall_price_listing_index = 0
	stall._withdraw_listing_to_inventory()
	if stall.stall_listings[0] != null or stall.collectibles.is_empty():
		_fail("已上架藏品无法撤回库存用于修改定价或交付任务。")
		return
	stall.cash = 4321
	stall.day = 6
	stall.stall_reputation = 17
	stall.pc_parts_owned = 3
	stall.collectibles.clear()
	stall.collectibles.append({"series":0, "item_index":0, "rarity":0, "name":"冬日暖意"})
	stall.collectibles.append({"series":0, "item_index":0, "rarity":0, "name":"冬日暖意"})
	stall.collectibles.append({"series":0, "item_index":1, "rarity":0, "name":"度假搭档"})
	if stall._duplicate_resale_indices() != [1]:
		_fail("扭扭没有只选中重复件，或未给每款保留一件。")
		return
	var state: Dictionary = stall._capture_save_state()
	state["collectibles"][0]["name"] = "旧版袋鼠名称"
	state["collectibles"][0]["rarity"] = 5
	state["stall_listings"][0] = {"item":{"series":0, "item_index":1, "rarity":5, "name":"旧版占位名"}, "price":45}
	stall.cash = 1
	stall.day = 1
	stall.stall_reputation = 0
	stall.pc_parts_owned = 0
	stall._apply_save_state(state)
	if stall.cash != 4321 or stall.day != 6 or stall.stall_reputation != 17 or stall.pc_parts_owned != 3:
		_fail("经营与主线状态无法从存档快照恢复。")
		return
	if stall.collectibles[0]["name"] != "冬日暖意" or int(stall.collectibles[0]["rarity"]) != 0:
		_fail("旧存档中的内容物名称与稀有度没有迁移到新资产数据。")
		return
	if stall.stall_listings[0]["item"]["name"] != "度假搭档" or int(stall.stall_listings[0]["item"]["rarity"]) != 0:
		_fail("旧存档中的上架商品没有迁移到新资产数据。")
		return
	stall.open_pause_menu()
	if not paused or not stall.pause_overlay.visible:
		_fail("Esc暂停菜单没有真正暂停场景。")
		return
	stall.close_pause_menu()
	if paused or stall.pause_overlay.visible:
		_fail("暂停菜单无法恢复游戏。")
		return
	stall.queue_free()
	await process_frame
	print("CAMPAIGN_FLOW_OK: menu, economy, apps, 8-stage goal, save snapshot and pause")
	quit(0)
