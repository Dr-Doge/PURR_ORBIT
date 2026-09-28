extends Control
var title_art: TextureRect
var game
var drawer: PanelContainer
var toggle: Button
var status: PanelContainer
var opened: bool=false
func bind_game(controller) -> void:
 game=controller
 title_art=$TitleArt;status=$Status;toggle=$MenuToggle;drawer=$Drawer
 game.header_label=$Status/Header
 game.hint_label=$Drawer/Content/Info/Hint
 game.signal_bar=$Drawer/Content/Info/Signal
 game.notice_label=$Drawer/Content/Info/Notice
 toggle.pressed.connect(toggle_drawer)
 var actions={"Shop":game.show_shop,"Tree":func():game.show_tree(),"Workers":game.show_workers,"Inventory":game.show_inventory,"Gacha":game.show_gacha,"Pause":game.show_pause}
 for key in actions:
  var action: Callable=actions[key]
  var button: Button=get_node("Drawer/Content/"+key)
  button.pressed.connect(func():set_open(false);action.call())
  game.nav_buttons[key.to_lower()]=button
 $Drawer/Content/Help.pressed.connect(func():set_open(false);game.show_help())
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
