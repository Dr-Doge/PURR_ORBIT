extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://scenes/3D scene.tscn").instantiate();game.testing=true;root.add_child(game)
 print(game.room.shell.get_tree_string_pretty())
 game.queue_free();await process_frame;await process_frame;quit()
