extends Control
const C = preload("res://scripts/ea/config.gd")
const Preview = preload("res://scripts/model_preview_3d.gd")
signal completed(id: int)
var model: RefCounted
var item_id := -1
var polishing := false
var held := false
var last := Vector2.ZERO
var cursor := Vector2.ZERO
var current_step := -1
var finished := false
var awaiting_continue := false
var title: Label
var hint: Label
var bar: ProgressBar
var next_button: Button
var visual: Control
var stain_overlay: Control
var cells: Array[Vector2] = []
var tool_area := Rect2(190,125,510,340)
var shake_offset := Vector2.ZERO
var movement_budget := 0.0
var particles: Array[Dictionary] = []

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	for pos in [Vector2(24,8),Vector2(24,50)]:
		var label := Label.new(); label.position=pos; label.size=Vector2(950,40); label.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(label)
		if title==null: title=label; title.add_theme_font_size_override("font_size",20)
		else: hint=label
	bar=ProgressBar.new(); bar.position=Vector2(120,540); bar.size=Vector2(720,22); add_child(bar)
	next_button=Button.new(); next_button.text="剥土完成 · 估值 +30%基础市价 · 开始甩沙"
	next_button.position=Vector2(200,478); next_button.size=Vector2(540,42)
	next_button.pressed.connect(func(): awaiting_continue=false; next_button.hide(); cancel_input())
	add_child(next_button); next_button.hide()
	var r: Dictionary=model.record(item_id)
	if polishing:
		visual=Preview.new(); visual.position=tool_area.position; visual.size=tool_area.size
		visual.build(C.model_item(int(r.series),int(r.variant)).model_path,Vector2i(510,340))
		visual.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(visual); move_child(visual,0)
		stain_overlay=Control.new(); stain_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
		stain_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(stain_overlay)
		stain_overlay.draw.connect(_draw_stains)
	_init_surfaces()
	_refresh_stage()
	if polishing: _fit_stains_to_model.call_deferred()

func _init_surfaces() -> void:
	var r: Dictionary=model.record(item_id)
	if not r.has("clods"):
		var random := RandomNumberGenerator.new(); random.seed=int(r.id)*731
		r.clods=[]
		var count:=random.randi_range(6,10)
		var total:=0.0
		for i in range(count):
			var hp:=float(random.randi_range(2,3)); total+=hp
			r.clods.append({"rect":Rect2(tool_area.position+Vector2((i%5)*94+10,(i/5)*150+20),Vector2(88,136)),"hp":hp,"max":hp})
		r.clod_total=total
	# Match partially completed machine work without throwing away click damage.
	var remaining:=0.0
	for c in r.clods: remaining+=float(c.hp)
	var target:float=(1.0-float(r.progress[0]))*float(r.clod_total)
	if remaining>target and remaining>0:
		for c in r.clods: c.hp=float(c.hp)*target/remaining
	cells.clear()
	for y in range(10):
		for x in range(15):
			if Vector2((x-7)/7.0,(y-4.5)/4.5).length()<=1.0: cells.append(Vector2(x,y))
	if r.has("polish_cells"):
		cells.assign(r.polish_cells)
	if r.marks[2].size()!=cells.size():
		r.marks[2]=[]
		for p in cells: r.marks[2].append(float(r.polish)/8.0)

func _fit_stains_to_model() -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	if not is_instance_valid(visual): return
	var r: Dictionary=model.record(item_id)
	var picture:Image=visual.viewport.get_texture().get_image()
	var fitted: Array[Vector2]=[]
	for y in range(10):
		for x in range(15):
			var px:=clampi(int((x+0.5)/15.0*picture.get_width()),0,picture.get_width()-1)
			var py:=clampi(int((y+0.5)/10.0*picture.get_height()),0,picture.get_height()-1)
			if picture.get_pixel(px,py).a>0.1: fitted.append(Vector2(x,y))
	if fitted.is_empty(): return
	var old_cells:=cells.duplicate()
	var old_marks:Array=r.marks[2].duplicate()
	cells=fitted
	r.polish_cells=cells.duplicate()
	r.marks[2]=[]
	for p in cells:
		var index:=old_cells.find(p)
		r.marks[2].append(old_marks[index] if index>=0 else float(r.polish)/8.0)
	stain_overlay.queue_redraw()

func cancel_input() -> void:
	held=false; movement_budget=0; last=Vector2.ZERO

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT: cancel_input()

func _refresh_stage() -> void:
	var r: Dictionary=model.record(item_id)
	current_step=int(r.step)
	if polishing:
		title.text="可选抛光 · "+C.model_item(int(r.series),int(r.variant)).name
		hint.text="拖动擦除实际污渍；干净处无收益 · 完成估值 +25%基础市价"
	else:
		title.text=model.unknown_title(r)+" · "+("连点剥土" if current_step==0 else "来回甩沙")
		hint.text="连续点击实体土块，空处无效 · 本步完成估值 +30%基础市价" if current_step==0 else "按住物件并来回移动，静止不推进 · 完成后揭晓，估值 +30%基础市价"

func _gui_input(event: InputEvent) -> void:
	if model.paused or finished: return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		cursor=event.position
		if event.pressed and not polishing and current_step==0: _click_clod(cursor)
		held=event.pressed and tool_area.has_point(event.position) and not awaiting_continue
		last=event.position; accept_event()
	elif event is InputEventMouseMotion:
		cursor=event.position
		if held: _stroke(last,cursor)
		last=cursor; accept_event()

func _click_clod(point: Vector2) -> void:
	if model.paused or current_step!=0 or finished: return
	var r: Dictionary=model.record(item_id)
	for c in r.clods:
		if c.hp<=0 or not (c.rect as Rect2).has_point(point): continue
		var work:=minf(1.0,float(c.hp)); c.hp-=work
		model.add_cleaning(item_id,work/float(r.clod_total))
		_dust(point,7)
		if r.step==1:
			cancel_input(); _refresh_stage()
			awaiting_continue=not model.talents.has("T21")
			next_button.visible=awaiting_continue
		break
	queue_redraw()

func _stroke(a: Vector2,b: Vector2) -> void:
	if model.paused or finished or not held or awaiting_continue: return
	var distance:=a.distance_to(b)
	if distance<0.5: return
	var r: Dictionary=model.record(item_id)
	if polishing:
		if not tool_area.has_point(a) and not tool_area.has_point(b): return
		var ab:=b-a
		var work:=0.0
		for i in range(cells.size()):
			var p:=tool_area.position+(cells[i]+Vector2.ONE*0.5)*Vector2(34,34)
			var t:=clampf((p-a).dot(ab)/maxf(ab.length_squared(),0.01),0,1)
			if p.distance_to(a+ab*t)>30: continue
			var old:float=r.marks[2][i]
			r.marks[2][i]=minf(1.0,old+minf(distance/220.0,0.16))
			work+=float(r.marks[2][i])-old
		if work>0: model.polish(item_id,work/cells.size()*8.0)
	elif current_step==1:
		# Budget accumulates with time, not event count; one teleport cannot finish.
		var work:=minf(distance,movement_budget)
		movement_budget-=work
		if work>0:
			model.add_cleaning(item_id,work/5200.0)
			shake_offset=(b-a).limit_length(25)
			_dust(tool_area.get_center()+shake_offset,3)
	queue_redraw()

func _dust(point: Vector2,count: int) -> void:
	if model.reduce_fx: return
	for i in range(count):
		particles.append({"p":point,"v":Vector2(randf_range(-120,120),randf_range(-80,40)),"life":0.7})

func _process(delta: float) -> void:
	if model.paused:
		cancel_input(); return
	movement_budget=minf(65.0,movement_budget+delta*520.0)
	shake_offset=shake_offset.move_toward(Vector2.ZERO,delta*80)
	for i in range(particles.size()-1,-1,-1):
		particles[i].v.y+=delta*360
		particles[i].p+=particles[i].v*delta; particles[i].life-=delta
		if particles[i].life<=0: particles.remove_at(i)
	if finished: return
	var r: Dictionary=model.record(item_id)
	if (polishing and r.quality) or (not polishing and r.status in ["identified","sold"]):
		finished=true; cancel_input(); completed.emit(item_id); return
	bar.value=float(r.polish)/8.0*100 if polishing else float(r.progress[int(r.step)])*100
	if is_instance_valid(stain_overlay): stain_overlay.queue_redraw()
	queue_redraw()

func _draw() -> void:
	var r: Dictionary=model.record(item_id)
	if r.is_empty(): return
	if not polishing:
		draw_rect(tool_area.grow(12),Color("183036"))
		var offset:=shake_offset if current_step==1 else Vector2.ZERO
		draw_rect(Rect2(tool_area.position+offset,tool_area.size),Color("6c5140"))
		if current_step==0 and r.has("clods"):
			for c in r.clods:
				if c.hp<=0: continue
				draw_rect(c.rect,Color("a78055").darkened((float(c.max)-float(c.hp))*0.12))
				draw_line(c.rect.position+Vector2(8,12),c.rect.end-Vector2(12,18),Color("59412e"),3)
		else:
			var sand:=1.0-float(r.progress[1])
			for i in range(int(150*sand)):
				var p:=tool_area.position+Vector2((i*71)%490+10,(i*47)%320+10)+offset
				draw_rect(Rect2(p,Vector2(8,8)),Color("d8b880"))
	for particle in particles: draw_rect(Rect2(particle.p,Vector2(5,5)),Color("bb9869"))
	if held and polishing: draw_arc(cursor,30,0,TAU,28,Color("f2d791"),2)

func _draw_stains() -> void:
	var r: Dictionary=model.record(item_id)
	for i in range(cells.size()):
		var alpha:=1.0-float(r.marks[2][i])
		if alpha>0: stain_overlay.draw_rect(Rect2(tool_area.position+cells[i]*34,Vector2(32,32)),Color(0.55,0.42,0.27,alpha*0.9))
