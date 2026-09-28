extends Control
## Authored controls live in main.tscn; this script only binds game state and actions.
var game
var panels: Array[Control]=[]
var title_art: TextureRect
func bind_game(controller) -> void:
 game=controller
 title_art=$TitleArt
 panels.assign([$Status,$Actions,$Info])
 game.header_label=$Status/Content/Header
 game.hint_label=$Info/Content/Hint
 game.notice_label=$Info/Content/Notice
 game.signal_bar=$Info/Content/Signal
 var callbacks={"Shop":game.show_shop,"Tree":func():game.show_tree(),"Workers":game.show_workers,"Inventory":game.show_inventory,"Gacha":game.show_gacha,"Pause":game.show_pause}
 for key in callbacks:
  var b: Button=get_node("Actions/Content/Buttons/"+key)
  b.pressed.connect(callbacks[key]);game.nav_buttons[key.to_lower()]=b
 $Info/Content/Help.pressed.connect(game.show_help)
func show_title(enabled: bool) -> void:
 title_art.visible=enabled
 for panel in panels:panel.visible=not enabled
