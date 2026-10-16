@tool
extends Node3D
## Art-only vertical split door. O or click opens/closes.
var opened := false
var busy := false
@export var cinematic_controlled: bool = false
@export var slide_distance: float = 1.65
@export var opening_half_width: float = 1.52
@onready var rotor: Node3D = $LockMount/LockRotor
@onready var upper: Node3D = $LockMount/LockRotor/UpperHalf
@onready var lower: Node3D = $LockMount/LockRotor/LowerHalf
@onready var top: Node3D = $TopLeaf
@onready var bottom: Node3D = $BottomLeaf
var top_start: Vector3
var bottom_start: Vector3
var cached_transform: Transform3D
var materials: Array[ShaderMaterial] = []
func _ready() -> void:
	top_start=top.position
	bottom_start=bottom.position
	for image in [$TopLeaf/TopImage,$BottomLeaf/BottomImage,upper,lower,upper.get_node("LeftIndicator"),lower.get_node("RightIndicator")]:
		var mat: ShaderMaterial=image.material_override.duplicate()
		mat.set_shader_parameter("frame_mask",$Frame.material_override.get_shader_parameter("art"))
		mat.set_shader_parameter("opening_bounds",Vector4(-1.3942080643544505,0.5878522420278007,1.391180468123496,3.483193457072772))
		mat.set_shader_parameter("clip_ready",true)
		image.material_override=mat
		materials.append(mat)
	sync_transform()
func sync_transform() -> void:
	cached_transform=global_transform
	$LockMount.scale.x=global_basis.y.length()/global_basis.x.length()
	for mat in materials:
		mat.set_shader_parameter("portal_inverse",global_transform.affine_inverse())
func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and global_transform!=cached_transform:
		sync_transform()
func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or cinematic_controlled: return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_O:
		toggle_door()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var camera=get_viewport().get_camera_3d()
		if camera==null:return
		var hit=Plane(global_basis.z.normalized(),global_position).intersects_ray(camera.project_ray_origin(event.position),camera.project_ray_normal(event.position))
		if hit==null:return
		var p=to_local(hit)
		if absf(p.x)<opening_half_width and p.y>0.5 and p.y<3.6:
			toggle_door()
			get_viewport().set_input_as_handled()
func toggle_door(rotation_time: float = 0.65, slide_time: float = 0.9) -> void:
	if busy or Engine.is_editor_hint():return
	busy=true
	if not opened:
		# Turn the initially vertical seam 90 degrees to horizontal before splitting.
		var unlock=create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		unlock.tween_property(rotor,"rotation:z",0.0,rotation_time)
		await unlock.finished
		rotor.rotation.z=0.0
		upper.reparent(top,true)
		lower.reparent(bottom,true)
	var distance=0.0 if opened else slide_distance
	var tween=create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(top,"position",top_start+Vector3(0,distance,0),slide_time)
	tween.tween_property(bottom,"position",bottom_start-Vector3(0,distance,0),slide_time)
	await tween.finished
	if opened:
		upper.reparent(rotor,true)
		lower.reparent(rotor,true)
		var lock=create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		lock.tween_property(rotor,"rotation:z",PI / 2.0,rotation_time)
		await lock.finished
		rotor.rotation.z=PI / 2.0
	opened=not opened
	busy=false

func close_immediately() -> void:
	if busy: return
	top.position = top_start
	bottom.position = bottom_start
	if upper.get_parent() != rotor:
		upper.reparent(rotor, true)
		lower.reparent(rotor, true)
	rotor.rotation.z = PI / 2.0
	opened = false
