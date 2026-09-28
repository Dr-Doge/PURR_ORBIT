extends "res://scripts/main.gd"
## Alternate presentation; all progression and player saves use the original game.
func create_room():
 return preload("res://scripts/room_3d.gd").new()
func create_hud():
 return preload("res://scripts/hud_3d.gd").new()
func layout_presentation() -> void:
 if hud == null:return
 hud.position=Vector2.ZERO;hud.scale=Vector2.ONE;hud.size=size
 hud.show_title(modal=="start")
func resize_panel() -> void:
 super.resize_panel()
 if modal=="start" and is_instance_valid(card):
  overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
  overlay.offset_top=size.y*0.55
  card.custom_minimum_size=Vector2(minf(390,size.x-48),260)
