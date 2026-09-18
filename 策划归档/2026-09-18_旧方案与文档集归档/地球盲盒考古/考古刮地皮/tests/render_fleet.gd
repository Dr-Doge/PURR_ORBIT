extends SceneTree
const Main = preload("res://scripts/fleet/main.gd")
func _initialize() -> void:
	root.size = Vector2i(1366,850)
	call_deferred("run")
func capture(path: String) -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path)) == OK)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var game = Main.new(); game.testing = true; root.add_child(game)
	game.start_session()
	await capture("res://reports/fleet_start.png")
	var click := InputEventMouseButton.new(); click.button_index = MOUSE_BUTTON_LEFT; click.pressed = true
	click.position = game.board.global_position + (game.board.point(0.37)-Vector2(0,28))*game.board.size/Vector2(1000,750)
	root.push_input(click)
	await process_frame
	assert(game.model.manual_target == game.model.targets[1].id and game.model.held)
	click.pressed = false; root.push_input(click); await process_frame
	assert(not game.model.held)
	game.model.wallet = 3000; game.model.unlocked = true
	for key in ["auto","light","drone","heavy","piercing"]: game.model.buy(key)
	game.model.add_hotspot("cache"); game.model.command(game.model.targets.back().id)
	for i in range(180): await process_frame
	game.refresh()
	await capture("res://reports/fleet_battle.png")
	game.show_pause(); var elapsed: float = game.model.elapsed
	for i in range(5): await process_frame
	assert(game.model.elapsed == elapsed)
	await capture("res://reports/fleet_pause.png")
	game.paused = false; game.model.receive({"id":9999,"source":"cache","value":120}); game.show_inventory()
	await capture("res://reports/fleet_inventory.png")
	print("FLEET UI: render and pause passed")
	quit()
