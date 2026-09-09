extends SubViewportContainer

var viewport: SubViewport
var holder: Node3D

func build(model_path: String, render_size: Vector2i = Vector2i(256, 256)) -> void:
	stretch = true
	viewport = SubViewport.new()
	viewport.size = render_size
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	holder = Node3D.new()
	world.add_child(holder)
	var packed := load(model_path) as PackedScene
	if packed:
		var asset := packed.instantiate() as Node3D
		if asset: holder.add_child(asset)
	if holder.get_child_count() == 0:
		var fallback := MeshInstance3D.new()
		fallback.mesh = SphereMesh.new()
		holder.add_child(fallback)
	var bounds_data := _bounds(holder)
	var extent := 1.0
	if bool(bounds_data.valid):
		var bounds: AABB = bounds_data.bounds
		holder.position = -bounds.get_center()
		extent = maxf(bounds.size.x, bounds.size.y)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = maxf(extent * 1.18, 0.1)
	camera.position = Vector3(0, 0, maxf(extent * 2.0, 2.0))
	world.add_child(camera)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-28, -32, 0)
	key.light_energy = 1.25
	world.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(25, 145, 0)
	fill.light_energy = 0.45
	world.add_child(fill)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("d8e1df")
	environment.environment.ambient_light_energy = 0.55
	world.add_child(environment)

func _bounds(root: Node) -> Dictionary:
	var result := {"valid":false, "bounds":AABB()}
	_accumulate(root, Transform3D.IDENTITY, result)
	return result

func _accumulate(node: Node, parent_transform: Transform3D, result: Dictionary) -> void:
	var current := parent_transform
	if node is Node3D: current = parent_transform * (node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh:
		var value: AABB = current * (node as MeshInstance3D).mesh.get_aabb()
		if bool(result.valid): result.bounds = (result.bounds as AABB).merge(value)
		else: result.bounds = value; result.valid = true
	for child in node.get_children(): _accumulate(child, current, result)
