extends Control
var model: RefCounted
var depth := 0
func _ready() -> void: mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	for find in model.layers[depth].finds:
		if find.collected or find.kind!="artifact": continue
		var p: Vector2=find.position
		draw_rect(Rect2(p-Vector2(12,12),Vector2(24,24)),Color("74bdaa"))
		draw_rect(Rect2(p-Vector2(7,3),Vector2(14,6)),Color("f8e2a1"))
		if model.talents.has("T11"):
			draw_rect(Rect2(p-Vector2(16,16),Vector2(32,32)),Color("f4d591"),false,2.0)
