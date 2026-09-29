extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 root.size=Vector2i(1440,810)
 var game=preload("res://scenes/3D scene.tscn").instantiate();game.testing=true;root.add_child(game)
 game.start_game();game.set_process(false);game.room.set_process(false);game.room.step(0)
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://reports/windows")
 var name: String="after" if OS.get_cmdline_user_args().is_empty() else OS.get_cmdline_user_args()[0]
 root.get_texture().get_image().save_png("res://reports/windows/"+name+".png")
 print("WINDOW RENDER: ",name)
 game.queue_free();await process_frame;quit()
