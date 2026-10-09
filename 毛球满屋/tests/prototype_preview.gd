extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 root.size=Vector2i(1440,810)
 var game=load("res://scenes/测试场景.tscn").instantiate()
 root.add_child(game)
 await process_frame;await process_frame
 game.set_process(false);game.view.step(0.01)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://reports/prototype_20261009/preview.png")
 game.queue_free();await process_frame;quit()
