extends SceneTree
var game
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 game=load("res://scenes/3D scene.tscn").instantiate()
 game.testing=true
 root.add_child(game)
 root.title="Purr Orbit - isolated startup check"
