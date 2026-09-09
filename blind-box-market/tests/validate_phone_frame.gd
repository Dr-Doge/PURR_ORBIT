extends SceneTree

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/stall_demo/stall_demo.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.unlocked_apps = {"social":true, "orders":true, "resale":true, "exchange":true}
	game._set_phone_visible(true, true)
	for app in ["home", "supply", "jimi", "resale", "social", "orders", "exchange", "superdog", "business"]:
		if app == "home": game._show_phone_home()
		else: game._open_phone_app(app)
		await create_timer(0.7).timeout
		assert(game.stall_phone_frame.z_index > game.stall_phone_screen.z_index)
		assert(game.stall_phone_frame.mouse_filter == Control.MOUSE_FILTER_IGNORE)
		var rect: Rect2 = game.stall_phone.get_global_rect()
		assert(is_equal_approx(rect.size.x, 334.0), "Phone contents expanded authored frame width")
		assert(game.stall_phone.find_child("BatteryIcon", true, false).get_theme_stylebox("fill") is StyleBoxFlat)
		var page: Rect2 = game.stall_phone_page.get_global_rect()
		assert(page.position.x >= rect.position.x + 31 and page.end.x <= rect.end.x - 31)
		assert(game.stall_phone_page.get_parent().clip_contents)
		var status = game.stall_phone.find_child("PhoneStatusBar", true, false)
		var model = status.find_child("PhoneModel", true, false)
		assert(game.stall_phone_clock.get_global_rect().end.x <= model.global_position.x)
		assert(model.get_global_rect().end.x <= game.stall_phone_signal.global_position.x)
		assert(game.stall_phone_clock.get_theme_color("font_color") == Color.WHITE)
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("user://phone_frame_%s.png" % app)
	game.queue_free()
	await process_frame
	print("PHONE_FRAME_OK: all 9 screens below bezel, safe margins, clipped pages, nonoverlapping status bar")
	quit()
