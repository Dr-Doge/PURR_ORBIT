extends Control

var model: RefCounted
var depth := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if model == null: return
	for find in model.layer_finds(depth):
		if bool(find.collected) or find.kind == "scrap": continue
		var p: Vector2 = find.position
		var color: Color = find.color
		draw_rect(Rect2(p - Vector2(13, 13), Vector2(26, 26)), Color("0f171b"))
		draw_rect(Rect2(p - Vector2(11, 11), Vector2(22, 22)), color)
		draw_rect(Rect2(p - Vector2(7, 2), Vector2(14, 4)), Color("f4d48a"))
