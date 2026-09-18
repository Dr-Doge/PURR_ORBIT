extends SubViewportContainer

const RevealVFX = preload("res://scripts/vfx/reveal_spritesheet_vfx.gd")
const COLLECTIBLE_UP_AXIS := Vector3.BACK
const FAT_PARTNER_REVIEW_YAW := deg_to_rad(-25.0)
# 旧版在全屏3D视口中使用2.0；当前590px高展示框按可见高度等比适配。
const REVIEW_MODEL_SCALE_MULTIPLIER := 1.65
const REVIEW_ITEM_CAMERA_DISTANCE := 2.65
const REVIEW_VFX_CAMERA_DISTANCE := 3.30
const REVIEW_VERTICAL_OFFSET := 0.40
const REVEAL_VFX_SCREEN_FRACTION := 1.60
const OPEN_VFX := {"regular":"res://assets/VFX/开出特效_普通款.png", "small_hidden":"res://assets/VFX/开出特效_小隐藏.png", "big_hidden":"res://assets/VFX/开出特效_大隐藏.png"}
const IDLE_VFX := {"regular":"res://assets/VFX/待机背景_普通款.png", "small_hidden":"res://assets/VFX/待机背景_小隐藏.png", "big_hidden":"res://assets/VFX/待机背景_大隐藏.png"}

var item: Dictionary
var viewport: SubViewport
var world: Node3D
var content: Node3D
var camera: Camera3D
var box_root: Node3D
var lid_pivot: Node3D
var review_item: Node3D
var imported_meshes: Array[MeshInstance3D] = []
var rotation_enabled := false
var dragging := false

func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	viewport = SubViewport.new()
	viewport.size = Vector2i(920, 590)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)
	camera = Camera3D.new()
	camera.fov = 42.0
	camera.position = Vector3(0, 0, 5)
	world.add_child(camera)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-28, -32, 0)
	key.light_energy = 1.2
	world.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(30, 145, 0)
	fill.light_energy = 0.4
	world.add_child(fill)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("d9e2df")
	environment.environment.ambient_light_energy = 0.62
	world.add_child(environment)
	content = Node3D.new()
	world.add_child(content)
	gui_input.connect(_on_gui_input)

func configure(found: Dictionary) -> void:
	item = found.duplicate(true)
	rotation_enabled = false
	dragging = false
	for child in content.get_children(): child.queue_free()
	box_root = _create_box()
	content.add_child(box_root)

func _create_box() -> Node3D:
	var root := Node3D.new()
	root.position = Vector3(0, -0.64, 1.82)
	var material := StandardMaterial3D.new()
	material.albedo_color = item.color.darkened(0.24)
	material.roughness = 0.72
	for data in [
		[Vector3(0,-0.31,0),Vector3(1.4,0.1,1.0)], [Vector3(-0.65,0,0),Vector3(0.1,0.62,1.0)],
		[Vector3(0.65,0,0),Vector3(0.1,0.62,1.0)], [Vector3(0,0,0.45),Vector3(1.2,0.62,0.1)],
		[Vector3(0,0,-0.45),Vector3(1.2,0.62,0.1)]]:
		var part := CSGBox3D.new()
		part.position = data[0]
		part.size = data[1]
		part.material = material
		root.add_child(part)
	lid_pivot = Node3D.new()
	lid_pivot.position = Vector3(0, 0.35, -0.48)
	root.add_child(lid_pivot)
	var lid := CSGBox3D.new()
	lid.position = Vector3(0,0,0.48)
	lid.size = Vector3(1.42,0.08,1.02)
	lid.material = material
	lid_pivot.add_child(lid)
	return root

func play_reveal() -> void:
	var lid_tween := create_tween()
	lid_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	lid_tween.tween_property(lid_pivot, "rotation:x", -1.9, 0.85)
	await lid_tween.finished
	_spawn_collectible()
	var start_position := box_root.position + Vector3(0, 0.30, 0.24)
	var impact_position := _review_layer_position(REVIEW_ITEM_CAMERA_DISTANCE)
	var screen_pop_position := _review_layer_position(2.18)
	review_item.position = start_position
	review_item.basis = _front_facing_basis(start_position)
	review_item.scale = Vector3.ONE * (0.18 * REVIEW_MODEL_SCALE_MULTIPLIER)
	_create_reveal_burst()
	var shrink := create_tween()
	shrink.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	shrink.tween_property(box_root, "scale", Vector3.ONE * 0.18, 0.45)
	shrink.tween_callback(box_root.queue_free)
	var pop := create_tween().set_parallel(true)
	pop.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	pop.tween_property(review_item, "position", screen_pop_position, 0.28)
	pop.tween_property(review_item, "scale", Vector3.ONE * (1.12 * REVIEW_MODEL_SCALE_MULTIPLIER), 0.28)
	await pop.finished
	var land := create_tween().set_parallel(true)
	land.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	land.tween_property(review_item, "position", impact_position, 0.40)
	land.tween_property(review_item, "scale", Vector3.ONE * (0.78 * REVIEW_MODEL_SCALE_MULTIPLIER), 0.40)
	await land.finished
	var settle := create_tween()
	settle.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	settle.tween_property(review_item, "scale", Vector3.ONE * (0.84 * REVIEW_MODEL_SCALE_MULTIPLIER), 0.18)
	await settle.finished
	for mesh in imported_meshes:
		if is_instance_valid(mesh): mesh.material_override = null
	rotation_enabled = true

func _spawn_collectible() -> void:
	review_item = Node3D.new()
	content.add_child(review_item)
	var packed := load(String(item.model_path)) as PackedScene
	if packed == null: return
	var asset := packed.instantiate() as Node3D
	if asset == null: return
	var display_root := Node3D.new()
	display_root.add_child(asset)
	var bounds_data := _bounds(asset)
	if bool(bounds_data.valid):
		var source: AABB = bounds_data.bounds
		var correction := Basis(Vector3.RIGHT, PI/2.0)
		if int(item.series) == 0: correction = Basis(COLLECTIBLE_UP_AXIS, FAT_PARTNER_REVIEW_YAW) * correction
		var corrected: AABB = Transform3D(correction,Vector3.ZERO) * source
		var largest := maxf(corrected.size.x,maxf(corrected.size.y,corrected.size.z))
		var uniform := 1.0/maxf(largest,0.001)
		asset.basis = correction.scaled(Vector3.ONE*uniform)
		asset.position = -corrected.get_center()*uniform
	review_item.add_child(display_root)
	var silhouette := StandardMaterial3D.new()
	silhouette.albedo_color = Color("050609")
	silhouette.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	silhouette.roughness = 0.5
	for child in display_root.find_children("*","MeshInstance3D",true,false):
		var mesh := child as MeshInstance3D
		mesh.material_override = silhouette
		imported_meshes.append(mesh)

func _create_reveal_burst() -> void:
	var rarity := int(item.rarity)
	var category := "big_hidden" if rarity==5 else ("small_hidden" if rarity==4 else "regular")
	var effect := RevealVFX.new()
	effect.name = "RevealSpritesheetVFX_%s" % category
	content.add_child(effect)
	effect.basis = camera.basis
	effect.position = _review_layer_position(REVIEW_VFX_CAMERA_DISTANCE)
	var target_world_size := 2.0*3.5*tan(deg_to_rad(camera.fov*0.5))*REVEAL_VFX_SCREEN_FRACTION
	effect.configure(load(OPEN_VFX[category]),load(IDLE_VFX[category]),target_world_size)

func _review_layer_position(distance: float) -> Vector3:
	var offset := REVIEW_VERTICAL_OFFSET*distance/REVIEW_ITEM_CAMERA_DISTANCE
	return camera.position-camera.basis.z*distance+camera.basis.y*offset

func _front_facing_basis(position: Vector3) -> Basis:
	var front := (camera.position-position).normalized()
	var up := camera.basis.y.normalized()
	var right := up.cross(front).normalized()
	return Basis(right,-front,front.cross(right).normalized()).orthonormalized()

func _bounds(root: Node) -> Dictionary:
	var result := {"valid":false,"bounds":AABB()}
	_accumulate(root,Transform3D.IDENTITY,result)
	return result

func _accumulate(node: Node,parent: Transform3D,result: Dictionary) -> void:
	var current := parent
	if node is Node3D: current=parent*(node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh:
		var value: AABB=current*(node as MeshInstance3D).mesh.get_aabb()
		if bool(result.valid): result.bounds=(result.bounds as AABB).merge(value)
		else: result.bounds=value; result.valid=true
	for child in node.get_children(): _accumulate(child,current,result)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		dragging=event.pressed and rotation_enabled
		accept_event()
	elif event is InputEventMouseMotion and dragging and rotation_enabled and review_item:
		review_item.rotate_object_local(COLLECTIBLE_UP_AXIS,event.relative.x*0.012)
		review_item.rotate_object_local(Vector3.RIGHT,event.relative.y*0.012)
		accept_event()
