extends Control
## All panel positions are registered to Scene.jpg's three console recesses.
const TITLE = preload("res://Art/title.jpg")
var game
var panels: Array[Control] = []
var title_art: TextureRect
func region(at: Rect2) -> VBoxContainer:
 var margin := MarginContainer.new()
 margin.position=at.position; margin.size=at.size
 margin.add_theme_constant_override("margin_left",8)
 margin.add_theme_constant_override("margin_right",8)
 margin.add_theme_constant_override("margin_top",6)
 margin.add_theme_constant_override("margin_bottom",6)
 add_child(margin); panels.append(margin)
 var box := VBoxContainer.new()
 box.add_theme_constant_override("separation",8)
 margin.add_child(box)
 return box
func _ready() -> void:
 mouse_filter=MOUSE_FILTER_IGNORE
 title_art=TextureRect.new();title_art.texture=TITLE
 title_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 title_art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 title_art.mouse_filter=MOUSE_FILTER_IGNORE
 title_art.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 add_child(title_art);title_art.hide()
 var status := region(Rect2(1098,61,278,133))
 status.add_child(game.label("驻 留 舱  /  STATUS",17,"85e7ee"))
 game.header_label=game.label("",17,"fff1df")
 game.header_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 status.add_child(game.header_label)
 var actions := region(Rect2(1098,239,278,152))
 var grid := GridContainer.new();grid.columns=2
 grid.add_theme_constant_override("h_separation",8)
 grid.add_theme_constant_override("v_separation",7);actions.add_child(grid)
 for spec in [["猫咪与设施",game.show_shop],["成长树 ↑",func():game.show_tree()],["工人分工",game.show_workers],["库存 / 换金",game.show_inventory],["神秘收藏",game.show_gacha],["暂停 · Esc",game.show_pause]]:
  var b: Button=game.button(spec[0],spec[1],grid)
  b.custom_minimum_size=Vector2(125,39)
  b.add_theme_font_size_override("font_size",15)
 var info := region(Rect2(1098,434,278,292))
 info.add_child(game.label("舱 内 通 讯",17,"85e7ee"))
 game.hint_label=game.label("",16,"f1d5b7")
 game.hint_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;info.add_child(game.hint_label)
 var line := HSeparator.new();info.add_child(line)
 game.notice_label=game.label("来回移动鼠标抚摸；按住可以搬猫。",17,"fff1df")
 game.notice_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 game.notice_label.size_flags_vertical=SIZE_EXPAND_FILL;info.add_child(game.notice_label)
 game.button("操作帮助",game.show_help,info)
func show_title(enabled: bool) -> void:
 title_art.visible=enabled
 for panel in panels:panel.visible=not enabled
