extends Control
var title_art: TextureRect
var game
var drawer: PanelContainer
var toggle: Button
var status: PanelContainer
var opened: bool=false
func panel_box() -> PanelContainer:
 var p:=PanelContainer.new()
 p.add_theme_stylebox_override("panel",game.style("182630ed","4e626b",12))
 add_child(p)
 return p
func _ready() -> void:
 mouse_filter=MOUSE_FILTER_IGNORE
 title_art=TextureRect.new();title_art.texture=preload("res://Art/title.jpg")
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

 status=panel_box();status.position=Vector2(24,4);status.size=Vector2(370,52)
 game.header_label=game.label("",14,"e7eef1");status.add_child(game.header_label)
 toggle=game.button("☰  舱室功能",toggle_drawer,self)
 toggle.custom_minimum_size=Vector2(180,48)
 drawer=panel_box();drawer.custom_minimum_size=Vector2(290,0)
 var box: VBoxContainer=game.column(drawer)
 box.add_child(game.label("3D scene · 舱室功能",20,"e7eef1"))
 for spec in [["shop","补给",game.show_shop],["tree","成长",func():game.show_tree()],["workers","小帮手",game.show_workers],["inventory","仓库",game.show_inventory],["gacha","未知信号",game.show_gacha],["pause","暂停 · Esc",game.show_pause]]:
  var action: Callable=spec[2]
  var b: Button=game.button(spec[1],func():set_open(false);action.call(),box)
  game.nav_buttons[spec[0]]=b
 game.button("操作帮助",func():set_open(false);game.show_help(),box)
 # Keep progression and notices available inside the expandable menu.
 var info:=VBoxContainer.new();box.add_child(info)
 game.hint_label=game.label("",14,"d5dfe3");info.add_child(game.hint_label)
 game.signal_bar=ProgressBar.new();game.signal_bar.custom_minimum_size.y=5;game.signal_bar.show_percentage=false;info.add_child(game.signal_bar)
 game.notice_label=game.label("",15,"e7eef1")
 game.notice_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;info.add_child(game.notice_label)
 resized.connect(layout_controls);layout_controls();set_open(false)
func layout_controls() -> void:
 if toggle==null:return
 var title_scale: float=minf(size.x/1440.0,size.y/900.0)
 var plaque: Control=title_art.get_child(0)
 plaque.scale=Vector2.ONE*title_scale
 plaque.position=Vector2((size.x-710*title_scale)*0.5,65*title_scale)
 toggle.position=Vector2(size.x-204,22);toggle.size=Vector2(180,48)
 drawer.position=Vector2(size.x-314,84);drawer.size=Vector2(290,430)
func set_open(value: bool) -> void:
 opened=value;drawer.visible=value
 toggle.text="×  收起功能" if value else "☰  舱室功能"
 # Ignore the covered room and clear any pending drag when opening the drawer.
 game.room.reset_pointer()
 game.room.interactive=game.active and game.modal=="" and not value
func toggle_drawer() -> void:
 set_open(not opened)
func show_title(enabled: bool) -> void:
 title_art.visible=enabled
 status.visible=not enabled;toggle.visible=not enabled
 if enabled:drawer.hide();opened=false
