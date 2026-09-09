extends RefCounted

# Imported Pixel Modern UI assets are kept behind one skin adapter so layouts can
# continue to be authored in Godot while the visual source files remain swappable.
const HUD_ROOT := "res://assets/ui/Pixel Modern UI Bundle/PixelHudDialogueUI_Resource_v1.0/UI Elements"
const DIARY_ROOT := "res://assets/ui/Pixel Modern UI Bundle/PixelInventoryDiaryUI_v1.1/UI Elements"
const PHONE_ROOT := "res://assets/ui/Pixel Modern UI Bundle/PixelPocketPhoneUI_Resources_v1.0/UI_Elements"

const HUD_BACKGROUND := HUD_ROOT + "/Background/UI_Image_BG.png"
const HUD_PANEL := HUD_ROOT + "/Panel/UI_Panel_Basic.png"
const HUD_DIALOGUE_PANEL := HUD_ROOT + "/Panel/UI_Panel_Dialogue.png"
const HUD_POPUP_PANEL := HUD_ROOT + "/Panel/UI_Panel_Popup_BG.png"
const HUD_PAUSE_PANEL := HUD_ROOT + "/Panel/UI_Panel_Pause_BG.png"
const HUD_CURRENCY_PANEL := HUD_ROOT + "/Panel/UI_Panel_Currency.png"
const HUD_DIALOGUE_TITLE := HUD_ROOT + "/Panel/UI_Panel_Dialogue_Title.png"
const HUD_SHORTCUT_BG := HUD_ROOT + "/Buttons/UI_Button_HUD.png"
const HUD_CLOSE_BUTTON := HUD_ROOT + "/Buttons/UI_Button_Close.png"
const HUD_CONFIRM_BUTTON := HUD_ROOT + "/Buttons/UI_Button_Confirm.png"
const HUD_CANCEL_BUTTON := HUD_ROOT + "/Buttons/UI_Button_Cancel.png"
const HUD_DIALOGUE_BUTTON := HUD_ROOT + "/Buttons/UI_Button_Dialogue.png"
const HUD_TAB_NORMAL := HUD_ROOT + "/Buttons/UI_Button_Tab_Normal.png"
const HUD_TAB_HOVER := HUD_ROOT + "/Buttons/UI_Button_Tab_Hover.png"
const HUD_TAB_SELECTED := HUD_ROOT + "/Buttons/UI_Button_Tab_Selected.png"
const HUD_QUEST_LIST_OFF := HUD_ROOT + "/Lists/UI_List_QuestItem_Off.png"
const HUD_QUEST_LIST_ON := HUD_ROOT + "/Lists/UI_List_QuestItem_On.png"
const HUD_BUTTON_NORMAL := HUD_ROOT + "/Buttons/UI_Button_Choice_Normal.png"
const HUD_BUTTON_HOVER := HUD_ROOT + "/Buttons/UI_Button_Choice_Hover.png"
const HUD_BUTTON_PRESSED := HUD_ROOT + "/Buttons/UI_Button_Choice_Selected.png"
const HUD_BUTTON_DISABLED := HUD_ROOT + "/Buttons/UI_Button_Choice_Dim.png"
const HUD_PAUSE_BUTTON_NORMAL := HUD_ROOT + "/Buttons/UI_Button_Pause_Normal.png"
const HUD_PAUSE_BUTTON_HOVER := HUD_ROOT + "/Buttons/UI_Button_Pause_Hover.png"
const HUD_PAUSE_BUTTON_PRESSED := HUD_ROOT + "/Buttons/UI_Button_Pause_Selected.png"
const HUD_PROGRESS_BG := HUD_ROOT + "/Progress/UI_Progress_BG.png"
const HUD_PROGRESS_FILL := HUD_ROOT + "/Progress/UI_Progress_Fill_Yellow.png"

const DIARY_PANEL := DIARY_ROOT + "/Panels/UI_Panel_List.png"
const DIARY_PANEL_DIM := DIARY_ROOT + "/Panels/UI_Panel_List_Dim.png"
const DIARY_SLOT := DIARY_ROOT + "/Panels/UI_Panel_Slot.png"
const DIARY_PROGRESS_BG := DIARY_ROOT + "/ProgressBar/UI_Progress_BG.png"
const DIARY_PROGRESS_FILL := DIARY_ROOT + "/ProgressBar/UI_Progress_Fill_Orange.png"

const PHONE_FRAME := PHONE_ROOT + "/Backgrounds/UI_Image_Mobile.png"
const PHONE_WALLPAPER := PHONE_ROOT + "/Backgrounds/UI_Image_Bg_Mobile_01.png"
const PHONE_HOME_PANEL := PHONE_ROOT + "/Panels/UI_Panels_home.png"
const PHONE_LIST_NORMAL := PHONE_ROOT + "/Lists/UI_ListItem_Normal.png"
const PHONE_LIST_PRESSED := PHONE_ROOT + "/Lists/UI_ListItem_Pressed.png"
const PHONE_BUTTON_NORMAL := PHONE_ROOT + "/Buttons/UI_Btn_Play_Yellow_Normal.png"
const PHONE_BUTTON_HOVER := PHONE_ROOT + "/Buttons/UI_Btn_Play_Yellow_Hover.png"
const PHONE_BUTTON_PRESSED := PHONE_ROOT + "/Buttons/UI_Btn_Play_Yellow_Click.png"
const PHONE_BUTTON_DISABLED := PHONE_ROOT + "/Buttons/UI_Btn_Play_Dim.png"
const PHONE_BUTTON_PINK_NORMAL := PHONE_ROOT + "/Buttons/UI_Btn_Play_Pink_Normal.png"
const PHONE_BUTTON_PINK_HOVER := PHONE_ROOT + "/Buttons/UI_Btn_Play_Pink_Hover.png"
const PHONE_BUTTON_PINK_PRESSED := PHONE_ROOT + "/Buttons/UI_Btn_Play_Pink_Click.png"
const PHONE_BUTTON_GRAY_NORMAL := PHONE_ROOT + "/Buttons/UI_Btn_Play_Gray_Normal.png"
const PHONE_BUTTON_GRAY_HOVER := PHONE_ROOT + "/Buttons/UI_Btn_Play_Gray_Hover.png"
const PHONE_BUTTON_GRAY_PRESSED := PHONE_ROOT + "/Buttons/UI_Btn_Play_Gray_Click.png"
const PHONE_FLAT_NORMAL := PHONE_ROOT + "/Buttons/UI_Btn_Flat_Yellow_Normal.png"
const PHONE_FLAT_HOVER := PHONE_ROOT + "/Buttons/UI_Btn_Flat_Yellow_Hover.png"
const PHONE_FLAT_PRESSED := PHONE_ROOT + "/Buttons/UI_Btn_Flat_Yellow_Click.png"
const PHONE_FLAT_DISABLED := PHONE_ROOT + "/Buttons/UI_Btn_Flat_Gray.png"
const PHONE_PROGRESS_BG := PHONE_ROOT + "/Bars/UI_Progress_Bg.png"
const PHONE_PROGRESS_FILL := PHONE_ROOT + "/Bars/UI_Progress_Fill.png"

const INK := Color("#5b1727")
const INK_DISABLED := Color("#9f8990")
const LIGHT_TEXT := Color("#fff6df")


static func texture(path: String) -> Texture2D:
	return load(path) as Texture2D


static func box(path: String, patch := 18.0, content := 10.0, tint := Color.WHITE) -> StyleBoxTexture:
	var result := StyleBoxTexture.new()
	result.texture = texture(path)
	result.modulate_color = tint
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		result.set_texture_margin(side, patch)
		result.set_content_margin(side, content)
	result.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	result.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return result


static func apply_hud_button(target: Button, pause_variant := false) -> void:
	var normal_path := HUD_PAUSE_BUTTON_NORMAL if pause_variant else HUD_BUTTON_NORMAL
	var hover_path := HUD_PAUSE_BUTTON_HOVER if pause_variant else HUD_BUTTON_HOVER
	var pressed_path := HUD_PAUSE_BUTTON_PRESSED if pause_variant else HUD_BUTTON_PRESSED
	target.add_theme_stylebox_override("normal", box(normal_path, 18.0, 8.0))
	target.add_theme_stylebox_override("hover", box(hover_path, 18.0, 8.0))
	target.add_theme_stylebox_override("pressed", box(pressed_path, 18.0, 8.0))
	target.add_theme_stylebox_override("focus", box(pressed_path, 18.0, 8.0))
	target.add_theme_stylebox_override("disabled", box(HUD_BUTTON_DISABLED, 18.0, 8.0))
	_apply_button_text(target)


static func apply_quest_button(target: Button) -> void:
	target.add_theme_stylebox_override("normal", box(HUD_QUEST_LIST_OFF, 34.0, 16.0))
	target.add_theme_stylebox_override("hover", box(HUD_QUEST_LIST_ON, 34.0, 16.0, Color(1.06, 1.06, 1.06, 1.0)))
	target.add_theme_stylebox_override("pressed", box(HUD_QUEST_LIST_ON, 34.0, 16.0, Color(0.90, 0.90, 0.90, 1.0)))
	target.add_theme_stylebox_override("focus", box(HUD_QUEST_LIST_ON, 34.0, 16.0))
	target.add_theme_stylebox_override("disabled", box(HUD_QUEST_LIST_OFF, 34.0, 16.0, Color(0.62, 0.62, 0.62, 0.82)))
	_apply_button_text(target)


static func apply_hud_action_button(target: Button, variant := "confirm") -> void:
	# Confirm/cancel icon plaques have almost no rectangular text-safe area.
	# Text actions use the full-width dialogue/choice plates instead.
	var path := HUD_DIALOGUE_BUTTON
	if variant == "cancel": path = HUD_BUTTON_NORMAL
	elif variant == "dialogue": path = HUD_DIALOGUE_BUTTON
	elif variant == "tab": path = HUD_TAB_NORMAL
	var hover_path := HUD_TAB_HOVER if variant == "tab" else path
	var pressed_path := HUD_TAB_SELECTED if variant == "tab" else path
	target.add_theme_stylebox_override("normal", box(path, 18.0, 7.0))
	target.add_theme_stylebox_override("hover", box(hover_path, 18.0, 7.0, Color(1.08, 1.08, 1.08, 1.0)))
	target.add_theme_stylebox_override("pressed", box(pressed_path, 18.0, 7.0, Color(0.86, 0.86, 0.86, 1.0)))
	target.add_theme_stylebox_override("focus", box(pressed_path, 18.0, 7.0))
	target.add_theme_stylebox_override("disabled", box(HUD_BUTTON_DISABLED, 18.0, 7.0))
	_apply_button_text(target)


static func apply_phone_button(target: Button, variant: Variant = "yellow") -> void:
	if variant is bool: variant = "flat" if variant else "yellow"
	var normal_path := PHONE_BUTTON_NORMAL
	var hover_path := PHONE_BUTTON_HOVER
	var pressed_path := PHONE_BUTTON_PRESSED
	if variant == "flat":
		normal_path = PHONE_FLAT_NORMAL
		hover_path = PHONE_FLAT_HOVER
		pressed_path = PHONE_FLAT_PRESSED
	elif variant == "pink":
		normal_path = PHONE_BUTTON_PINK_NORMAL
		hover_path = PHONE_BUTTON_PINK_HOVER
		pressed_path = PHONE_BUTTON_PINK_PRESSED
	elif variant == "gray":
		normal_path = PHONE_BUTTON_GRAY_NORMAL
		hover_path = PHONE_BUTTON_GRAY_HOVER
		pressed_path = PHONE_BUTTON_GRAY_PRESSED
	target.add_theme_stylebox_override("normal", box(normal_path, 18.0, 7.0))
	target.add_theme_stylebox_override("hover", box(hover_path, 18.0, 7.0))
	target.add_theme_stylebox_override("pressed", box(pressed_path, 18.0, 7.0))
	target.add_theme_stylebox_override("focus", box(pressed_path, 18.0, 7.0))
	target.add_theme_stylebox_override("disabled", box(PHONE_FLAT_DISABLED if variant == "flat" else PHONE_BUTTON_DISABLED, 18.0, 7.0))
	_apply_button_text(target)


static func _apply_button_text(target: Button) -> void:
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		target.add_theme_color_override(state, INK)
	target.add_theme_color_override("font_disabled_color", INK_DISABLED)
	target.add_theme_constant_override("outline_size", 0)


static func apply_phone_icon_button(target: Button) -> void:
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = 4.0
	empty.content_margin_top = 4.0
	empty.content_margin_right = 4.0
	empty.content_margin_bottom = 4.0
	target.add_theme_stylebox_override("normal", empty)
	target.add_theme_stylebox_override("hover", box(PHONE_LIST_PRESSED, 18.0, 5.0, Color(1.0, 1.0, 1.0, 0.72)))
	target.add_theme_stylebox_override("pressed", box(PHONE_LIST_PRESSED, 18.0, 5.0, Color(0.88, 0.88, 0.88, 0.82)))
	target.add_theme_stylebox_override("focus", empty)
	target.add_theme_stylebox_override("disabled", empty)


static func apply_panel(target: PanelContainer, variant := "hud") -> void:
	match variant:
		"dialogue": target.add_theme_stylebox_override("panel", box(HUD_DIALOGUE_PANEL, 34.0, 24.0))
		"dialogue_dark": target.add_theme_stylebox_override("panel", box(HUD_DIALOGUE_PANEL, 34.0, 24.0, Color(0.14, 0.15, 0.20, 0.94)))
		"popup": target.add_theme_stylebox_override("panel", box(HUD_POPUP_PANEL, 34.0, 24.0))
		"pause": target.add_theme_stylebox_override("panel", box(HUD_PAUSE_PANEL, 38.0, 32.0))
		"currency": target.add_theme_stylebox_override("panel", box(HUD_CURRENCY_PANEL, 17.0, 8.0))
		"diary": target.add_theme_stylebox_override("panel", box(DIARY_PANEL, 26.0, 12.0))
		"diary_dim": target.add_theme_stylebox_override("panel", box(DIARY_PANEL_DIM, 26.0, 12.0))
		"phone": target.add_theme_stylebox_override("panel", box(PHONE_HOME_PANEL, 22.0, 11.0))
		_: target.add_theme_stylebox_override("panel", box(HUD_PANEL, 17.0, 11.0))


static func apply_progress(target: ProgressBar, phone_variant := false) -> void:
	if phone_variant:
		target.add_theme_stylebox_override("background", box(PHONE_PROGRESS_BG, 7.0, 0.0))
		target.add_theme_stylebox_override("fill", box(PHONE_PROGRESS_FILL, 7.0, 0.0))
	else:
		target.add_theme_stylebox_override("background", box(HUD_PROGRESS_BG, 9.0, 0.0))
		target.add_theme_stylebox_override("fill", box(HUD_PROGRESS_FILL, 9.0, 0.0))


static func frame_rect(path: String) -> TextureRect:
	var result := TextureRect.new()
	result.texture = texture(path)
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_SCALE
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


# Layout widths come from the authored scene, never the length of a translated
# string. Long descriptions wrap; action captions fit their actual safe area.
static func fit_content(root: Node) -> void:
	if root is Label:
		root.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		root.custom_minimum_size.x = 0
	elif root is Button:
		var target := root as Button
		target.clip_text = true
		target.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if not target.has_meta("fit_font_size"):
			target.set_meta("fit_font_size", target.get_theme_font_size("font_size"))
		var font := target.get_theme_font("font")
		var font_size := int(target.get_meta("fit_font_size"))
		var available := maxf(1.0, target.size.x - 36.0)
		while font_size > 10:
			var widest := 0.0
			for line in target.text.split("\n"):
				widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
			if widest <= available: break
			font_size -= 1
		target.add_theme_font_size_override("font_size", font_size)
		if target.tooltip_text.is_empty(): target.tooltip_text = target.text
	for child in root.get_children(): fit_content(child)
