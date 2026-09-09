extends Node

const SAVE_PATH := "user://stall_save.json"

var pending_load_state: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if not get_tree().paused: return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		var scene := get_tree().current_scene
		if scene and scene.has_method("close_pause_menu"):
			scene.call("close_pause_menu")
			get_viewport().set_input_as_handled()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func begin_new_game() -> void:
	pending_load_state.clear()


func request_continue() -> bool:
	var state := read_save()
	if state.is_empty(): return false
	pending_load_state = state
	return true


func take_pending_state() -> Dictionary:
	var state := pending_load_state.duplicate(true)
	pending_load_state.clear()
	return state


func write_save(state: Dictionary) -> Error:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(state, "\t"))
	file.close()
	return OK


func read_save() -> Dictionary:
	if not has_save(): return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null: return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed as Dictionary if parsed is Dictionary else {}
