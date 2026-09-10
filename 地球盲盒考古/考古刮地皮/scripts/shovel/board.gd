extends "res://scripts/ea/board.gd"

const ShovelModel = preload("res://scripts/shovel/model.gd")
const C = preload("res://scripts/ea/config.gd")
const CRACK_SHADER = preload("res://shaders/shovel_crack.gdshader")
var shovel_texture: Texture2D
var crack_texture: Texture2D
var crack_planes: Dictionary = {}
var job_signatures: Dictionary = {}

func _ready() -> void:
	shovel_texture=load("res://assets/Jomin Assets/shovel1-transparent.png")
	crack_texture=load("res://assets/Jomin Assets/A_jomin_Crack.png")
	super._ready()

func _build_layers() -> void:
	super._build_layers()
	crack_planes.clear(); job_signatures.clear()

func consume_find_events() -> void:
	var first := pickup_numbers.size()
	# Reuse the original scratch board's upward drift, fade, outline and colours.
	super.consume_find_events()
	for i in range(first,pickup_numbers.size()):
		pickup_numbers[i].font_size=28 if pickup_numbers[i].text=="+10" else 18

func _make_cracks(index: int) -> TextureRect:
	var plane := TextureRect.new()
	plane.mouse_filter=Control.MOUSE_FILTER_IGNORE
	plane.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plane.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	var material := ShaderMaterial.new(); material.shader=CRACK_SHADER
	material.set_shader_parameter("crack_art",crack_texture)
	material.set_shader_parameter("world_size",C.WORLD)
	plane.material=material
	add_child(plane); move_child(plane,get_child_count()-2)
	crack_planes[index]=plane
	return plane

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		var index := shovel_at(event.position)
		if index>=0:
			model.recall(index)
			step(0.0)
		else: model.dispatch(event.position)
		accept_event()
	elif event is InputEventMouseMotion: cursor=event.position

func shovel_at(point: Vector2) -> int:
	# Reverse draw order picks the frontmost sprite if flight paths overlap.
	for i in range(model.shovels.size()-1,-1,-1):
		var unit: Dictionary = model.shovels[i]
		if unit.phase=="idle": continue
		var center: Vector2 = model.unit_draw_position(unit)
		var hit_size: Vector2 = Vector2(34,102)*model.unit_scale(unit)+Vector2(8,8)
		if Rect2(center-hit_size*0.5,hit_size).has_point(point): return i
	return -1

func step(delta: float) -> void:
	drawing=false
	super.step(delta)
	var hovered := shovel_at(cursor)
	mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND if hovered>=0 else Control.CURSOR_CROSS
	tooltip_text="点击铲子召回，挖掘进度归零" if hovered>=0 and model.shovels[hovered].phase in ["moving","digging"] else ""
	for plane in crack_planes.values(): plane.hide()
	for i in range(model.shovels.size()):
		var unit: Dictionary = model.shovels[i]
		if unit.phase!="digging": job_signatures.erase(i); continue
		var job: Dictionary = unit.job
		var plane: TextureRect = crack_planes[i] if crack_planes.has(i) else _make_cracks(i)
		plane.show()
		var signature := str(job.depth)+str(job.target)+str(job.radius)
		if job_signatures.get(i,"")!=signature:
			job_signatures[i]=signature
			var mask := PackedByteArray(); mask.resize(Model.PIXELS); mask.fill(0)
			for pixel in job.pixels: mask[pixel]=255
			plane.texture=ImageTexture.create_from_image(Image.create_from_data(Model.WIDTH,Model.HEIGHT,false,Image.FORMAT_L8,mask))
			plane.material.set_shader_parameter("center",job.target)
			plane.material.set_shader_parameter("radius",job.radius)
		plane.material.set_shader_parameter("progress",float(job.time)/float(job.duration))

func _draw_overlay(canvas: Control) -> void:
	var was_hover := hover; hover=false
	super._draw_overlay(canvas)
	hover=was_hover
	if hover and not model.paused and model.idle_count()>0 and shovel_at(cursor)<0:
		canvas.draw_circle(cursor,model.dig_radius(),Color(0.65,0.89,0.74,0.08))
		canvas.draw_arc(cursor,model.dig_radius(),0,TAU,96,Color("a3e3bd"),1.5,true)
	for unit in model.shovels:
		if unit.phase=="idle": continue
		var position: Vector2 = model.unit_draw_position(unit)
		if unit.phase in ["moving","digging"]:
			var job: Dictionary = unit.job
			var target: Vector2 = job.target
			canvas.draw_arc(target,float(job.radius),0,TAU,96,Color(0.92,0.78,0.48,0.75),1.5,true)
			if unit.phase=="digging":
				var progress := float(job.time)/float(job.duration)
				var bar_pos := Vector2(clampf(target.x-45,8,size.x-98),clampf(target.y+float(job.radius)+12,8,size.y-30))
				canvas.draw_style_box(_bar_style(Color("102125")),Rect2(bar_pos,Vector2(90,10)))
				canvas.draw_style_box(_bar_style(Color("a3e3bd")),Rect2(bar_pos+Vector2(2,2),Vector2(86*progress,6)))
				canvas.draw_string(get_theme_default_font(),bar_pos+Vector2(0,26),"%.1f / %.1f s"%[float(job.time),float(job.duration)],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("f4dfaa"))
				canvas.draw_circle(target+Vector2(0,4),14,Color(0,0,0,0.23))
		if shovel_texture:
			var sprite_size: Vector2 = Vector2(60,102)*model.unit_scale(unit)
			canvas.draw_texture_rect(shovel_texture,Rect2(position-sprite_size*0.5,sprite_size),false)

func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color=color; style.set_corner_radius_all(4); return style
