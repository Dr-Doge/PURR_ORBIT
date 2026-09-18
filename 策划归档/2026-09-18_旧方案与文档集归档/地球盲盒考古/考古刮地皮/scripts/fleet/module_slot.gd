extends Button
signal module_dropped(index: int, key: String)
var index: int = 0
var key: String = ""
var palette: bool = false
func _get_drag_data(_position: Vector2) -> Variant:
	var preview := Label.new(); preview.text = text; set_drag_preview(preview)
	return {"module":key}
func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return not palette and data is Dictionary and data.has("module")
func _drop_data(_position: Vector2, data: Variant) -> void:
	module_dropped.emit(index,str(data.module))
