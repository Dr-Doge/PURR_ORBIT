extends Node2D
var view: Control
func _draw() -> void:
 if is_instance_valid(view):view.draw_foreground(self)
