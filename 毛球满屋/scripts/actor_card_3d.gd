extends "res://scripts/room.gd"
## Reuse procedural worker/device artwork as transparent, lit 3D cards.
var entity: Dictionary={}
var actor_kind: String=""
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 pointer=Vector2(-10000,-10000)
func _draw() -> void:
 if entity.is_empty():return
 draw_set_transform(Vector2(128,148)-entity.pos)
 if actor_kind=="worker":super.draw_worker(entity)
 else:super.draw_facility(entity)
func text(_at: Vector2,_value: String,_sz: int=16,_color: Color=INK) -> void:
 pass
func ellipse(at: Vector2,radius: Vector2,color: Color) -> void:
 # Exclude the legacy painted contact ellipse from the projected artwork.
 if color.r<0.1 and color.g<0.1 and color.a<=0.31:return
 super.ellipse(at,radius,color)
