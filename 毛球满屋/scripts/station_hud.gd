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
 # Preserve the supplied image while presenting the project's official name.
 var plaque:=PanelContainer.new();plaque.position=Vector2(365,65);plaque.size=Vector2(710,218)
 plaque.mouse_filter=MOUSE_FILTER_IGNORE;plaque.add_theme_stylebox_override("panel",game.style("263f48","cda67d",36));title_art.add_child(plaque)
 var title_box:=VBoxContainer.new();title_box.alignment=BoxContainer.ALIGNMENT_CENTER;title_box.mouse_filter=MOUSE_FILTER_IGNORE;plaque.add_child(title_box)
 for line in [["P U R R  O R B I T",40,"f7d395"],["毛 球 计 划",55,"e9f0df"]]:
  var title_label: Label=game.label(line[0],line[1],line[2]);title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title_box.add_child(title_label)
 var status := region(Rect2(1098,61,278,133))
 status.add_child(game.label("毛 球 计 划",17,"85e7ee"))
 game.header_label=game.label("",16,"fff1df")
 game.header_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 status.add_child(game.header_label)
 var actions := region(Rect2(1098,239,278,152))
 var grid := GridContainer.new();grid.columns=2
 grid.add_theme_constant_override("h_separation",8)
 grid.add_theme_constant_override("v_separation",7);actions.add_child(grid)
 for spec in [["shop","补给",game.show_shop],["tree","成长",func():game.show_tree()],["workers","小帮手",game.show_workers],["inventory","仓库",game.show_inventory],["gacha","未知信号",game.show_gacha],["pause","暂停 · Esc",game.show_pause]]:
  var b: Button=game.button(spec[1],spec[2],grid)
  game.nav_buttons[spec[0]]=b
  b.custom_minimum_size=Vector2(125,39)
  b.add_theme_font_size_override("font_size",15)
 var info := region(Rect2(1098,434,278,292))
 info.add_child(game.label("舱 内 通 讯",17,"85e7ee"))
 game.hint_label=game.label("",16,"f1d5b7")
 game.hint_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;info.add_child(game.hint_label)
 game.signal_bar=ProgressBar.new();game.signal_bar.custom_minimum_size.y=8;game.signal_bar.show_percentage=false
 info.add_child(game.signal_bar)
 var line := HSeparator.new();info.add_child(line)
 game.notice_label=game.label("来回移动鼠标抚摸；按住可以搬猫。",17,"fff1df")
 game.notice_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 game.notice_label.size_flags_vertical=SIZE_EXPAND_FILL;info.add_child(game.notice_label)
 game.button("操作帮助",game.show_help,info)
func show_title(enabled: bool) -> void:
 title_art.visible=enabled
 for panel in panels:panel.visible=not enabled
