extends SceneTree
const Main = preload("res://scripts/main.gd")
func _initialize() -> void:
	root.size = Vector2i(1280,800); call_deferred("run")
func capture(name: String) -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://reports/"+name+".png")) == OK)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var game = Main.new(); game.testing = true; root.add_child(game)
	await capture("menu"); game.start_game(); await capture("room_start")
	# Send real mouse motion, without any button press.
	for i in range(100):
		var ev := InputEventMouseMotion.new(); ev.position = game.room.global_position+(game.model.cats[0].pos+Vector2(-20 if i%2 else 20,0))*game.room.size/Vector2(900,640)
		root.push_input(ev); await process_frame
	assert(game.model.cats[0].progress > 0 or game.model.satisfied > 0)
	game.model.wallet = 1000
	for i in range(1,7): game.model.research(i)
	for kind in ["short","long","static","spirit","spark","wand","heater"]: game.model.buy(kind)
	for t in game.model.tools:
		if t.kind == "wand": game.model.place(t.id,Vector2(350,400))
		if t.kind == "heater": game.model.place(t.id,Vector2(600,350))
	for key in ["bed","bell","post"]: game.model.buy_decor(key)
	for i in range(120): game.model.tick(0.05); game.room.step(0.05)
	game.refresh(); await capture("room_grown")
	game.show_tree("hand"); var elapsed: float = game.model.elapsed; await capture("tree"); assert(game.model.elapsed == elapsed)
	game.close_modal(); assert(game.model.pet_id == -1)
	game.model.auto_unlocked = true; game.model.tickets = 1; game.model.start_minigame(); game.show_minigame()
	elapsed = game.model.elapsed; await capture("minigame"); assert(game.model.elapsed > elapsed)
	game.show_pause(); elapsed = game.model.elapsed; await capture("pause"); assert(game.model.elapsed == elapsed)
	print("CAT UI: actual mouse motion, tree pause, minigame live, menu freeze passed")
	game.queue_free(); await process_frame; quit()
