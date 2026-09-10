extends SceneTree
const Main=preload("res://scripts/shovel/main.gd")
const D=preload("res://scripts/ea/decimal.gd")
var game: Control
func _initialize() -> void:
	root.size=Vector2i(1366,850); call_deferred("run")
func capture(name: String) -> void:
	game.board.step(0.04); game.board.hover=false; game.board.get_node("BrushOverlay").queue_redraw(); game._refresh()
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://"+name+".png")
func run() -> void:
	game=Main.new(); root.add_child(game); game.save_enabled=false
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); game._start_new_game(); game.set_process(false)
	await capture("shovel_fleet_idle")
	game.model.dispatch(Vector2(480,420)); game.model.tick(0.22)
	await capture("shovel_fleet_outbound")
	game.model.tick(2); game.model.tick(12)
	game.model.wallet=D.new("300"); game._buy_shovel(); game._buy_shovel()
	game.model.dispatch(Vector2(720,300)); game.model.dispatch(Vector2(750,600))
	game.model.tick(2); game.model.tick(4)
	await capture("shovel_fleet_parallel")
	var recall_click:=InputEventMouseButton.new(); recall_click.pressed=true; recall_click.button_index=MOUSE_BUTTON_LEFT
	recall_click.position=game.model.unit_draw_position(game.model.shovels[0])
	game.board._gui_input(recall_click); game.model.tick(0.35)
	await capture("shovel_recalled")
	game.model.tick(2); game.model.tick(0.35)
	await capture("shovel_fleet_return")
	game.model.tick(14); game.model.tick(1)
	await capture("shovel_fleet_stowed")
	game.model.wallet=D.new("100000")
	while game.model.shovel_count<10: game.model.buy_shovel()
	await capture("shovel_fleet_max")
	game._buy_power(); game._buy_range()
	game.upgrade_scroll.scroll_vertical=10000
	game.model.dispatch(Vector2(500,280)); game.model.tick(2); game.model.tick(5)
	await capture("shovel_upgrades")
	game.queue_free(); await process_frame
	game=Main.new(); root.add_child(game); game.save_enabled=false; game.set_process(false)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); game._start_new_game()
	for find in game.model.layers[0].finds:
		if find.kind!="scrap" or not Rect2(200,180,680,450).has_point(find.position): continue
		if game.model.scrap_reward(game.model.layers[0],find).exact()=="10":
			game.model.dispatch(find.position); break
	game.model.tick(2)
	for i in range(200):
		game.model.tick(0.1); game.board.step(0.1)
		var has_gold:=false
		for event in game.model.recent_finds:
			if event.kind=="scrap" and event.text=="+10": has_gold=true
		game.board.consume_find_events()
		if has_gold: break
	await capture("shovel_gold_reward")
	print("CAPTURES: "+ProjectSettings.globalize_path("user://")); quit()
