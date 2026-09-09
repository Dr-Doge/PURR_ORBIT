extends SceneTree
const Main=preload("res://scripts/ea/main.gd")
const M=preload("res://scripts/ea/model.gd")
const D=preload("res://scripts/ea/decimal.gd")
var failures:=0
func check(value:bool,label:String)->void:
	if not value: failures+=1; printerr("FAIL: "+label)
func _initialize()->void:
	root.size=Vector2i(1366,850); call_deferred("run")
func run()->void:
	var path:="user://start_menu_test.dat"
	var saved:=M.new(); saved.wallet=D.new("4321"); saved.levels.power=4; saved.save_to(path)
	var original:=FileAccess.get_file_as_bytes(path)
	var game:=Main.new(); game.save_path=path; game.settings_path=path+".cfg"; root.add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	check(game.start_menu.visible and not game.session_active and game.model.paused,"boots to inactive menu")
	check(game.model.wallet.exact()=="0" and game.model.levels.power==0,"does not auto-load")
	game.save_enabled=true; game._process(60); game.save_enabled=false
	check(FileAccess.get_file_as_bytes(path)==original,"idle menu cannot overwrite save")
	game.save_enabled=true
	game._open_settings(); game.settings_draft.reduce_fx=true; game._close_settings(true)
	game.save_enabled=false
	check(game.start_menu.visible and not game.settings_dialog.visible and not game.session_active,"settings returns to menu")
	check(FileAccess.get_file_as_bytes(path)==original,"menu settings preserve progress save")
	check(FileAccess.file_exists(path+".cfg"),"settings saved separately")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test_captures/start_menu.png")
	game._start_new_game()
	check(game.session_active and not game.model.paused and game.model.wallet.exact()=="0","start new game from zero")
	check(FileAccess.get_file_as_bytes(path)==original,"new game does not immediately erase old save")
	game.queue_free(); await process_frame
	var restarted:=Main.new(); restarted.save_path=path; root.add_child(restarted)
	await process_frame
	check(restarted.start_menu.visible and restarted.model.wallet.exact()=="0","restart again stays in menu")
	restarted._load_start_game()
	check(restarted.session_active and restarted.model.wallet.exact()=="4321" and restarted.model.levels.power==4,"explicit load restores save")
	restarted.queue_free(); await process_frame
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path+".cfg")
	var empty:=Main.new(); empty.save_path=path; root.add_child(empty); await process_frame
	check(empty.load_button.disabled,"missing save disables load")
	empty._load_start_game()
	check(not empty.session_active and empty.model.paused,"failed load remains in menu")
	empty.queue_free(); await process_frame
	print("START_MENU: %d failure(s)"%failures); quit(1 if failures else 0)
