extends SceneTree
const Main=preload("res://scripts/ea/main.gd")
const D=preload("res://scripts/ea/decimal.gd")
var game:Control
var failures:=0
var captures:="test_captures"
func check(value: bool,label: String) -> void:
	if not value: failures+=1; printerr("FAIL: "+label)
func _initialize() -> void:
	Engine.max_fps=60; root.size=Vector2i(1366,850); call_deferred("run")
func frames(n: int=3) -> void:
	for i in range(n): await process_frame
func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(captures.path_join("v03_"+label+".png"))
func click(w:Control,p:Vector2) -> void:
	var event:=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_LEFT; event.position=p; event.pressed=true; w._gui_input(event)
	event.pressed=false; w._gui_input(event)
func escape() -> void:
	var event:=InputEventKey.new(); event.keycode=KEY_ESCAPE; event.pressed=true
	game._unhandled_key_input(event)
func wheel(point:Vector2) -> void:
	var motion:=InputEventMouseMotion.new(); motion.position=point; motion.global_position=point; root.push_input(motion)
	var event:=InputEventMouseButton.new(); event.position=point; event.global_position=point; event.button_index=MOUSE_BUTTON_WHEEL_DOWN; event.pressed=true; root.push_input(event)
func texts(node:Node) -> String:
	var value:=""
	if node is Control and not node.is_visible_in_tree(): return value
	if node is Label or node is Button: value+=node.text+"\n"
	for child in node.get_children(): value+=texts(child)
	return value
func run() -> void:
	game=Main.new(); root.add_child(game); game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.save_enabled=false
	game._start_new_game()
	await frames(6)
	check(game.upgrade_scroll.visible and game.view=="","permanent upgrade list")
	check(game.depth_clip.global_position.y>630 and game.depth_clip.get_global_rect().end.y<=850,"depth meter at bottom")
	await capture("01_field")
	game.upgrade_scroll.scroll_vertical=0
	wheel(Vector2(1210,350)); await frames()
	check(game.upgrade_scroll.scroll_vertical>0,"wheel inside list scrolls")
	var scroll_before:int=game.upgrade_scroll.scroll_vertical
	wheel(Vector2(700,350)); await frames()
	check(game.upgrade_scroll.scroll_vertical==scroll_before,"wheel over soil does not scroll list")
	game.model.wallet=D.new("10000")
	game.upgrade_scroll.scroll_vertical=140
	await frames()
	game._buy_upgrade("radius")
	check(game.upgrade_scroll.scroll_vertical==140 and game.view=="","purchase keeps scroll and no popup")
	game._dev_artifacts()
	game.open_page("inventory"); await frames()
	var raw_text:=texts(game.page_body)
	check(raw_text.contains("未知土块") and not raw_text.contains("潜在系列") and not raw_text.contains("S01"),"unknown inventory hides series")
	await capture("02_unknown")
	var id:int=game.model.records[0].id
	game._start_work(id,false); await frames()
	var w:Control=game.workbench
	var r:Dictionary=game.model.record(id)
	click(w,Vector2(50,400))
	check(r.progress[0]==0.0,"empty click no clod work")
	await capture("03_clods")
	var clods:Array=r.clods
	for clod in clods:
		for i in range(3):
			if r.step==0: click(w,clod.rect.get_center())
	check(r.step==1 and w.awaiting_continue,"clod clicks finish stage and await tool switch")
	check(r.progress[1]==0.0 and game.model.discovered.is_empty(),"stage1 no reveal")
	w.next_button.pressed.emit()
	var press:=InputEventMouseButton.new(); press.button_index=MOUSE_BUTTON_LEFT; press.position=w.tool_area.get_center(); press.pressed=true; w._gui_input(press)
	for i in range(10): w._process(0.1)
	check(r.progress[1]==0,"stationary holding no sand work")
	w._stroke(w.tool_area.get_center(),Vector2(20000,20000))
	check(r.progress[1]<=0.013,"single teleport capped")
	w._process(0.125); w._stroke(Vector2(450,280),Vector2(510,280))
	var prior:float=r.progress[1]
	escape()
	check(game.model.paused and game.pause_menu.visible and not w.held,"Esc pauses and releases grab")
	w._stroke(Vector2(450,280),Vector2(550,280))
	check(r.progress[1]==prior,"paused work cannot advance")
	game._open_settings(); await frames()
	game.settings_draft.reduce_fx=true
	await capture("04_settings")
	escape()
	check(game.pause_menu.visible and not game.settings_dialog.visible and not game.model.reduce_fx,"settings Esc cancels and returns menu")
	escape()
	check(not game.model.paused and not game.pause_menu.visible and not w.held,"menu Esc resumes without stuck input")
	game.open_page("inventory"); game._start_work(id,false); await frames()
	w=game.workbench
	check(is_equal_approx(r.progress[1],prior),"resume keeps progress")
	w.held=true
	for i in range(90):
		if r.status=="identified": break
		w._process(0.125)
		w._stroke(Vector2(420,280),Vector2(485,280) if i%2==0 else Vector2(355,280))
	await frames(3)
	for i in range(240):
		if not game.reveal_busy and game.view=="review": break
		await process_frame
	check(r.status=="identified" and not r.quality and game.view=="review","sand reveals without mandatory polish")
	await capture("05_reveal")
	game._start_work(id,true); await frames()
	w=game.workbench; w.held=true
	await capture("08_polish")
	var before:float=r.polish
	w._stroke(Vector2(10,10),Vector2(50,10))
	check(r.polish==before,"outside polish no work")
	for iteration in range(8):
		for y in range(10):
			if r.quality: break
			w._stroke(Vector2(190,142+y*34),Vector2(699,142+y*34))
	check(r.quality,"actual swept stain area completes polish")
	game.open_page("inventory"); await frames()
	game.model.buy_analyzer(); game._render_page(); await frames()
	check(texts(game.page_body).contains("潜在系列"),"analyzer reveals existing unknown series")
	await capture("06_analyzed")
	game.close_page(); game.upgrade_scroll.scroll_vertical=2000; await frames()
	await capture("07_machines")
	game._open_pause(); game._open_settings()
	game.settings_draft.reduce_fx=true; game._close_settings(true)
	check(game.model.reduce_fx and game.model.paused,"apply settings keeps pause")
	game._resume_game()
	print("EA_V03_UI: %d failure(s)"%failures)
	game.queue_free(); await frames(); quit(1 if failures else 0)
