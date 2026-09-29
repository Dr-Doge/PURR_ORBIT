extends Control
var game
@onready var panel: PanelContainer=$Panel
@onready var tab: Button=$Tab
@onready var content: VBoxContainer=$Panel/Margin/Body/Scroll/Content
@onready var feedback: Label=$Panel/Margin/Body/Feedback
func bind_game(controller) -> void:
 game=controller
 tab.pressed.connect(func():game.close_modal() if panel.visible else game.show_developer())
 $Panel/Margin/Body/Header/Close.pressed.connect(func():game.close_modal())
 var group=""
 for command in game.Dev.COMMANDS:
  if command[1]!=group:
   group=command[1];content.add_child(game.label(group,19))
  var key: String=command[0]
  var action: Button=game.button(command[2],func():game.developer_command(key),content)
  action.name="Command_"+key
  action.add_theme_font_size_override("font_size",16)
 if game.has_method("show_lab"):
  content.add_child(game.label("独立测试场景",19))
  for item in [["测试说明与原演示台","show_lab"],["猫咪身份档案","show_cat_list"],["保存测试进度","save_test"],["读取测试进度","load_test"],["重置测试预置","start_game"]]:
   var method: String=item[1]
   game.button(item[0],func():game.close_modal();game.call(method),content)
 hide_panel()
 visible=game.active
func _process(_dt: float) -> void:
 if game==null:return
 visible=game.active and game.modal in ["","developer"]
func open_panel() -> void:
 visible=true;panel.show();tab.text="收\n起\n‹"
 tab.tooltip_text="点击收起开发者工具（Esc也可收起）"
 feedback.text="模拟已暂停；指令立即生效。"
func hide_panel() -> void:
 panel.hide();tab.text="开\n发\n工\n具\n›"
 tab.tooltip_text="开发者工具 · 点击展开"
