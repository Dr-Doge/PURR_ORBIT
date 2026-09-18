extends SceneTree
var game: Control
var failures:=0
var capture_dir:=""
func check(ok:bool,what:String)->void:
	if not ok: failures+=1; printerr("FAIL: "+what)
func _initialize()->void:
	Engine.max_fps=60; root.size=Vector2i(1366,850)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--captures="): capture_dir=arg.trim_prefix("--captures=")
	call_deferred("run")
func frames(count:int=3)->void:
	for i in range(count): await process_frame
func capture(value:String)->void:
	if capture_dir.is_empty() or DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image(); check(not image.is_empty(),"viewport image"); image.save_png(capture_dir.path_join(value+".png"))
func clear_find(find:Dictionary)->void:
	var p:Vector2=find.position; var h:Vector2=find.size*0.5
	for point in [p,p-h,p+h,p+Vector2(-h.x,h.y),p+Vector2(h.x,-h.y)]:
		var x:=clampi(int(point.x/game.model.WORLD_WIDTH*game.model.WIDTH),0,game.model.WIDTH-1)
		var y:=clampi(int(point.y/game.model.WORLD_HEIGHT*game.model.HEIGHT),0,game.model.HEIGHT-1)
		game.model.layers[int(find.depth)].health[y*game.model.WIDTH+x]=0.0
func run()->void:
	change_scene_to_file("res://scenes/main.tscn"); await frames(8); game=current_scene
	check(game.board.size==Vector2(1096,822),"land fills left side at 4:3")
	check(game.scrap_label.text=="0","currency label is scrap"); await capture("01_start")
	game.board.hover=true; game.board.drawing=true; game.board.previous=Vector2(150,170); game.board.motion_points.append(Vector2(650,170)); await frames(8); game.board.cancel_drag()
	check(game.model.progress(0)>0.0 and game.model.started,"held drag scratches soil")
	check(game.model.scrap==0,"soil does not mint scrap")
	game.model.scrap=120; game._refresh(); game.shop_buttons.power.pressed.emit()
	check(game.model.power_level==1 and game.model.scrap==0,"shop spends scrap")
	var scrap_find:Dictionary; var artifact:Dictionary
	for find in game.model.layer_finds(0):
		if find.kind=="scrap" and scrap_find.is_empty(): scrap_find=find
		if find.kind=="artifact": artifact=find
	clear_find(scrap_find); game.model.scan_exposed_finds(); game.board.consume_find_events()
	check(game.model.scrap==1 and game.board.pickup_numbers.back().text=="+1","pickup grants scrap and floating number")
	var premium:Dictionary=game.model.layer_finds(0)[19]
	clear_find(premium); game.model.scan_exposed_finds(); game.board.consume_find_events()
	check(game.model.scrap==11 and game.board.pickup_numbers.back().text=="+10" and game.board.pickup_numbers.back().color==Color("ffd44f"),"premium pickup pays ten and displays gold text")
	await capture("02_scratched")
	artifact.soil_chunks=6; game.reveal_panel.show_artifact(artifact); await frames(2)
	check(game.reveal_panel.chunks_left==6 and game.model.paused,"artifact soil-cleaning stage")
	for child in game.reveal_panel.chunk_layer.get_children().duplicate():
		if child is Button:
			while int(child.get_meta("hits",0))>0: child.pressed.emit()
	await create_timer(2.2).timeout
	check(game.model.inventory.size()==1 and game.reveal_panel.continue_button.visible,"opening stores artifact")
	var before_rotation:Basis=game.reveal_panel.reveal_3d.review_item.basis
	var press:=InputEventMouseButton.new(); press.button_index=MOUSE_BUTTON_LEFT; press.pressed=true
	game.reveal_panel.reveal_3d._on_gui_input(press)
	var rotate:=InputEventMouseMotion.new(); rotate.relative=Vector2(35,12)
	game.reveal_panel.reveal_3d._on_gui_input(rotate)
	check(not game.reveal_panel.reveal_3d.review_item.basis.is_equal_approx(before_rotation),"revealed 3D model rotates by held drag")
	await capture("03_reveal"); game.reveal_panel.continue_button.pressed.emit(); game._open_inventory(); await frames(4)
	check(game.inventory_panel.visible and game.inventory_panel.grid.get_child_count()==10,"catalog inventory grid")
	var inventory_before:int=game.model.inventory.size()
	game.model.scrap=0
	game.inventory_panel._sell_item(int(artifact.series),int(artifact.item_index))
	check(game.model.inventory.size()==inventory_before-1 and game.model.scrap==int(artifact.price),"inventory sells owned item")
	check(not game.inventory_panel.has_method("_buy_series_box"),"inventory has no purchase action")
	game.model.scrap=0
	await capture("04_inventory"); game.inventory_panel.close_panel(); game.model.elapsed=179.99; await frames(5)
	game.model.elapsed=10.0; game.summary_shown=false; game.modal.hide(); game.model.paused=false
	game._open_developer(); game._developer_add_scrap(); game._developer_toggle("power"); game._developer_toggle("radius"); game._developer_toggle("auto")
	check(game.model.scrap==10000 and game.model.power_level==4 and game.model.radius_level==3 and game.model.auto_level==3,"developer panel adds scrap and enables every upgrade")
	await capture("05_developer")
	game._close_developer(); game.model.elapsed=179.99; await frames(5)
	check(game.summary_shown and game.modal.visible and game.model.paused,"three-minute summary")
	print("UI_CHECKS: %d failure(s)"%failures); quit(1 if failures>0 else 0)
