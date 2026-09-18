extends SceneTree
const Main = preload("res://scripts/fleet/bridge.gd")
func _initialize() -> void:
	root.size = Vector2i(1366,850); call_deferred("run")
func capture(path: String) -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path)) == OK)
func run() -> void:
	var game = Main.new(); game.testing = true; root.add_child(game)
	await capture("res://reports/fleet_v3_menu.png")
	game.start_session()
	var key := InputEventKey.new(); key.physical_keycode = KEY_D; key.pressed = true; root.push_input(key)
	await process_frame; await process_frame
	assert(game.model.turn > 0)
	game.show_pause(); assert(game.model.turn == 0 and game.held_keys.is_empty())
	key.pressed = false; root.push_input(key); game.close_screen()
	for i in range(100): game.model.tick(0.05); game.board.step(0.05)
	game.refresh(); await capture("res://reports/fleet_v3_bridge.png")
	game.model.wallet = 2000; game.show_tree(1,"kinetic:attack")
	assert(game.graph.get_connection_list().size() == 14)
	await process_frame; await process_frame; await process_frame
	assert(is_equal_approx(game.graph.scroll_offset.y,-40))
	var elapsed: float = game.model.elapsed
	await capture("res://reports/fleet_v3_tree.png"); assert(game.model.elapsed == elapsed)
	game.open_build("frigate"); game.set_slot(1,"kinetic")
	assert(game.edit_keys == ["kinetic","kinetic"] and game.current_quote().price == 120)
	await capture("res://reports/fleet_v3_loadout.png")
	game.confirm_loadout(); await capture("res://reports/fleet_v3_confirm.png")
	game.close_screen(); game.model.planet = 1; game.model.make_planet(); game.model.angle = 70
	for i in range(100): game.model.tick(0.05); game.board.step(0.05)
	game.refresh(); await capture("res://reports/fleet_v3_enemy.png")
	game.show_inventory(); elapsed = game.model.elapsed; await capture("res://reports/fleet_v3_inventory.png"); assert(game.model.elapsed > elapsed)
	game.show_pause(); elapsed = game.model.elapsed; await capture("res://reports/fleet_v3_pause.png"); assert(game.model.elapsed == elapsed)
	game.close_screen(); game.model.ships.clear(); game.model.modules.clear(); game.model.drones.clear(); game.model.levels.command = 3; game.model.levels.hangar = 3
	for i in range(48):
		var s: Dictionary = game.model.add_ship("carrier" if i >= 36 else "frigate",["aa","aa"] if i >= 36 else ["kinetic","kinetic"])
		if i >= 36:
			for j in range(8): game.model.add_drone(s.id)
	for i in range(60): game.model.tick(0.05); game.board.step(0.05)
	game.refresh(); await capture("res://reports/fleet_v3_large_fleet.png")
	print("FLEET V3 UI: rendered, research/refit/pause frozen, inventory live"); quit()
