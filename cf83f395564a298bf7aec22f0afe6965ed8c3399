extends Control

const STALL_SCENE := "res://scenes/stall_demo/stall_demo.tscn"
const PIXEL_UI_SKIN := preload("res://scripts/ui/pixel_ui_skin.gd")
const INTRO_TEXTURES := [
	preload("res://assets/placeholders/story/sky.jpg"),
	preload("res://assets/placeholders/story/GDA6.jpg"),
	preload("res://assets/placeholders/story/balance.jpg"),
	preload("res://assets/placeholders/story/moon_city.jpg"),
	preload("res://assets/placeholders/story/table.jpg"),
]
const INTRO_TEXTS := [
	"暑假某天的下午：",
	"我去！GDA6？这不玩是人啊？",
	"可是......这游戏要想爽玩怎么也得配一台高端PC吧？跟家里要肯定是不可能的了，我一个穷学生哪能搞到这么多钱去配电脑啊？",
	"有了！最近那个什么盲盒经济不是特别火吗？我去开一堆盲盒然后把里面的东西在我家旁边的动漫月亮城那摆个摊子卖给别人岂不是很赚？",
	"爷，你委屈一下这几天别去公园创象棋对战房了，桌子和板凳借我用一下。",
]

@onready var continue_button: Button = $MenuContent/Buttons/ContinueGame
@onready var notice_label: Label = $MenuContent/Notice
@onready var story_layer: Control = $StoryLayer
@onready var story_background: TextureRect = $StoryLayer/Background
@onready var story_text: Label = $StoryLayer/CaptionPanel/CaptionContent/StoryText
@onready var story_progress: Label = $StoryLayer/CaptionPanel/CaptionContent/Progress

var intro_index := -1


func _ready() -> void:
	get_tree().paused = false
	_apply_pixel_ui_assets()
	$MenuContent/Buttons/NewGame.pressed.connect(_start_new_game)
	continue_button.pressed.connect(_continue_game)
	$MenuContent/Buttons/Settings.pressed.connect(_show_settings_placeholder)
	continue_button.disabled = not _session().has_save()
	continue_button.tooltip_text = "尚无存档" if continue_button.disabled else "读取最近一次手动存档"


func _input(event: InputEvent) -> void:
	# _input runs before child Controls consume the event, so the entire story
	# viewport—including the caption panel and its labels—advances reliably.
	if not story_layer.visible: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# The final page changes scene and detaches this menu immediately, so the
		# viewport must consume the click before _advance_intro can switch scenes.
		var viewport := get_viewport()
		if viewport: viewport.set_input_as_handled()
		_advance_intro()


func _unhandled_input(event: InputEvent) -> void:
	if not story_layer.visible: return
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
		_advance_intro()


func _apply_pixel_ui_assets() -> void:
	# 最终素材、位置和尺寸已经直接保存在 main_menu.tscn。运行时不再
	# 创建或移动 UI，因此编辑器 2D 视图就是实际游戏画面。
	pass


func _start_new_game() -> void:
	_session().begin_new_game()
	intro_index = 0
	story_layer.visible = true
	story_layer.grab_focus()
	_show_intro_page()


func _continue_game() -> void:
	if not _session().request_continue():
		continue_button.disabled = true
		notice_label.text = "存档不存在或已经损坏。"
		return
	get_tree().change_scene_to_file(STALL_SCENE)


func _show_settings_placeholder() -> void:
	notice_label.text = "设置界面占位：后续可接入音量、画质、分辨率与操作灵敏度。"


func _advance_intro() -> void:
	intro_index += 1
	if intro_index >= INTRO_TEXTS.size():
		get_tree().change_scene_to_file(STALL_SCENE)
		return
	_show_intro_page()


func _show_intro_page() -> void:
	story_background.texture = INTRO_TEXTURES[intro_index]
	story_text.text = INTRO_TEXTS[intro_index]
	story_progress.text = "%d / %d　点击鼠标进入下一段" % [intro_index + 1, INTRO_TEXTS.size()]


func _session() -> Node:
	return get_node("/root/GameSession")
