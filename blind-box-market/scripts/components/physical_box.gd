extends RigidBody3D

var box_kind := "parcel"
var series_index := -1
var rarity := -1
var item_index := -1
var paid_price: int = 0
var opened := false
var seal_removed := false
var lid_opened := false
var seal_progress := 0.0
var seal_base_transforms: Array[Transform3D] = []
var bottom_seal_base_transforms: Array[Transform3D] = []
var top_seal_path: Array[Vector3] = []
var bottom_seal_path: Array[Vector3] = []
var seal_path_points: Array[Vector3] = []
var top_seal_segment_count := 0
var bottom_seal_segment_count := 0
var seal_detach_points: Array[float] = []
var seal_detach_index := 0
var parcel_seal_side := 0
var parcel_top_opened := false
var parcel_bottom_opened := false
var shake_count := 0
var shake_eliminated: Array[int] = []

@onready var shell_parts: Array[Node] = $Shell.get_children()
@onready var shell: Node3D = $Shell
@onready var body_collision: CollisionShape3D = $BodyCollision
@onready var left_wall: CSGBox3D = $Shell/LeftWall
@onready var right_wall: CSGBox3D = $Shell/RightWall
@onready var front_wall: CSGBox3D = $Shell/FrontWall
@onready var back_wall: CSGBox3D = $Shell/BackWall
@onready var lid: CSGBox3D = $LidPivot/Lid
@onready var lid_pivot: Node3D = $LidPivot
@onready var lid_b: CSGBox3D = $LidPivotB/Lid
@onready var lid_pivot_b: Node3D = $LidPivotB
@onready var bottom_lid: CSGBox3D = $BottomLidPivot/BottomLid
@onready var bottom_lid_pivot: Node3D = $BottomLidPivot
@onready var bottom_lid_b: CSGBox3D = $BottomLidPivotB/BottomLid
@onready var bottom_lid_pivot_b: Node3D = $BottomLidPivotB
@onready var seal_ring: Node3D = $SealRing
@onready var bottom_seal_ring: Node3D = $BottomSealRing
@onready var seal_grip: CSGSphere3D = $SealGrip
@onready var seal_area: Area3D = $SealArea
@onready var lid_area: Area3D = $LidArea
@onready var content: CSGSphere3D = $Content
@onready var content_area: Area3D = $ContentArea
@onready var label_3d: Label3D = $FrontLabel

func setup(kind: String, box_series: int, box_rarity: int, paid: int, color: Color, box_item_index := -1) -> void:
	box_kind = kind
	series_index = box_series
	rarity = box_rarity
	item_index = box_item_index
	paid_price = paid
	if not is_node_ready(): await ready
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = color
	body_material.roughness = 0.82
	for part in shell_parts:
		if part is CSGShape3D:
			part.material = body_material
			if part.name == "Bottom": part.visible = kind != "parcel"
	if kind == "parcel":
		configure_parcel_cube()
	lid.material = body_material
	lid_b.material = body_material
	bottom_lid.material = body_material
	bottom_lid_b.material = body_material
	bottom_lid.visible = kind == "parcel"
	bottom_lid_b.visible = kind == "parcel"
	lid_b.visible = kind == "parcel"
	bottom_seal_ring.visible = kind == "parcel"
	configure_lids(kind)
	label_3d.text = "快递 ¥1" if kind == "parcel" else "盲盒 %d" % (box_series + 1)
	var content_material := StandardMaterial3D.new()
	content_material.albedo_color = Color("#8dd7bd") if kind == "parcel" else color.lightened(0.32)
	content_material.emission_enabled = kind == "blind"
	content_material.emission = color * 0.4
	content.material = content_material
	configure_seal_pattern(-1 if kind == "parcel" else box_series)
	set_seal_progress(0.0)

func configure_parcel_cube() -> void:
	# Equal outer dimensions on all three axes make the delivery carton a true
	# cube while retaining separate, rigid wall panels.
	body_collision.shape = body_collision.shape.duplicate()
	(body_collision.shape as BoxShape3D).size = Vector3(1.2, 1.2, 1.2)
	left_wall.position = Vector3(-0.55, 0, 0)
	left_wall.size = Vector3(0.1, 1.12, 1.2)
	right_wall.position = Vector3(0.55, 0, 0)
	right_wall.size = Vector3(0.1, 1.12, 1.2)
	front_wall.position = Vector3(0, 0, 0.55)
	front_wall.size = Vector3(1.0, 1.12, 0.1)
	back_wall.position = Vector3(0, 0, -0.55)
	back_wall.size = Vector3(1.0, 1.12, 0.1)
	label_3d.position = Vector3(0, -0.02, 0.615)

func configure_lids(kind: String) -> void:
	if kind == "parcel":
		# A conventional carton: two rigid flaps meet at the center seam on both
		# faces and hinge from the left/right wall edges.
		lid_pivot.position = Vector3(-0.6, 0.58, 0)
		lid.position = Vector3(0.30, 0, 0)
		lid.size = Vector3(0.60, 0.04, 1.20)
		lid_pivot_b.position = Vector3(0.6, 0.58, 0)
		lid_b.position = Vector3(-0.30, 0, 0)
		lid_b.size = Vector3(0.60, 0.04, 1.20)
		bottom_lid_pivot.position = Vector3(-0.6, -0.58, 0)
		bottom_lid.position = Vector3(0.30, 0, 0)
		bottom_lid.size = Vector3(0.60, 0.04, 1.20)
		bottom_lid_pivot_b.position = Vector3(0.6, -0.58, 0)
		bottom_lid_b.position = Vector3(-0.30, 0, 0)
		bottom_lid_b.size = Vector3(0.60, 0.04, 1.20)
	else:
		lid_pivot.position = Vector3(0, 0.35, -0.48)
		lid.position = Vector3(0, 0, 0.48)
		lid.size = Vector3(1.42, 0.08, 1.02)

func configure_seal_pattern(pattern_index: int) -> void:
	var points_2d: Array[Vector2] = []
	match pattern_index:
		-1: # Parcel: a central strip joining the two doors.
			points_2d = [Vector2(0, -0.48), Vector2(0, -0.24), Vector2(0, 0), Vector2(0, 0.24), Vector2(0, 0.48)]
		0: # Desk partners: one clean horizontal pull.
			points_2d = [Vector2(-0.58, 0), Vector2(-0.29, 0), Vector2(0, 0), Vector2(0.29, 0), Vector2(0.58, 0)]
		1: # LADUDU: broad zigzag.
			points_2d = [Vector2(-0.58, -0.28), Vector2(-0.30, 0.24), Vector2(0, -0.24), Vector2(0.30, 0.24), Vector2(0.58, -0.28)]
		2: # Night shift: vertical zipper.
			points_2d = [Vector2(0, -0.48), Vector2(0, -0.25), Vector2(0, 0), Vector2(0, 0.25), Vector2(0, 0.48)]
		3: # Tear babies: fine alternating stitch.
			points_2d = [Vector2(-0.58, 0), Vector2(-0.40, 0.27), Vector2(-0.20, -0.27), Vector2(0, 0.27), Vector2(0.20, -0.27), Vector2(0.40, 0.27), Vector2(0.58, 0)]
		_: # Starport: an angular spiral trace.
			points_2d = [Vector2(-0.58, -0.38), Vector2(0.58, -0.38), Vector2(0.58, 0.38), Vector2(-0.42, 0.38), Vector2(-0.42, -0.18), Vector2(0.30, -0.18), Vector2(0.30, 0.18), Vector2(-0.12, 0.18)]
	top_seal_path.clear()
	bottom_seal_path.clear()
	var seal_height := 0.625 if pattern_index == -1 else 0.405
	for point in points_2d:
		top_seal_path.append(Vector3(point.x, seal_height, point.y))
		bottom_seal_path.append(Vector3(point.x, -seal_height, point.y))
	top_seal_segment_count = configure_ring_from_path(seal_ring, top_seal_path, seal_base_transforms)
	bottom_seal_segment_count = configure_ring_from_path(bottom_seal_ring, bottom_seal_path, bottom_seal_base_transforms)
	seal_path_points = top_seal_path.duplicate()

func configure_ring_from_path(ring: Node3D, path: Array[Vector3], transforms: Array[Transform3D]) -> int:
	transforms.clear()
	var segments := ring.get_children()
	var active_count := mini(path.size() - 1, segments.size())
	for index in segments.size():
		var segment := segments[index] as CSGBox3D
		if not segment: continue
		segment.scale = Vector3.ONE
		segment.visible = index < active_count
		if index >= active_count: continue
		var start := path[index]
		var finish := path[index + 1]
		var delta := finish - start
		segment.position = (start + finish) * 0.5
		segment.rotation = Vector3(0, -atan2(delta.z, delta.x), 0)
		segment.size = Vector3(delta.length() + 0.035, 0.055, 0.105)
		transforms.append(segment.transform)
	return active_count

func set_seal_progress(progress: float) -> void:
	seal_progress = clampf(progress, 0.0, 1.0)
	if not is_node_ready(): return
	if box_kind == "parcel" and parcel_seal_side == 1:
		set_ring_progress(bottom_seal_ring, bottom_seal_base_transforms, seal_progress, bottom_seal_segment_count)
	else:
		set_ring_progress(seal_ring, seal_base_transforms, seal_progress, top_seal_segment_count)
	update_seal_grip()

func update_seal_grip() -> void:
	if seal_path_points.size() < 2: return
	seal_grip.visible = seal_progress < 0.995
	var outward := -0.075 if box_kind == "parcel" and parcel_seal_side == 1 else 0.075
	seal_grip.position = seal_point_at_progress(seal_progress) + Vector3(0, outward, 0)
	seal_grip.scale = Vector3.ONE

func set_ring_progress(ring: Node3D, base_transforms: Array[Transform3D], progress: float, active_count: int) -> void:
	var all_segments := ring.get_children()
	var peel_direction := -1.0 if ring == bottom_seal_ring else 1.0
	if base_transforms.is_empty():
		for child in all_segments:
			base_transforms.append((child as Node3D).transform)
	for index in all_segments.size():
		var segment := all_segments[index] as CSGBox3D
		if not segment: continue
		if index >= active_count:
			segment.visible = false
			continue
		segment.transform = base_transforms[index]
		var local_tear := clampf(progress * float(active_count) - float(index), 0.0, 1.0)
		segment.visible = local_tear < 0.995
		segment.scale = Vector3(maxf(0.015, 1.0 - local_tear), 1.0, 1.0)
		# The free end visibly peels up. When input detaches, this pose remains,
		# making the next clickable end easy to find.
		segment.position.y += sin(local_tear * PI * 0.5) * 0.12 * peel_direction
		segment.rotation.z += local_tear * 0.48 * peel_direction

func seal_point_at_progress(progress: float) -> Vector3:
	if seal_path_points.size() < 2: return Vector3.ZERO
	var lengths: Array[float] = []
	var total := 0.0
	for index in seal_path_points.size() - 1:
		var length := seal_path_points[index].distance_to(seal_path_points[index + 1])
		lengths.append(length)
		total += length
	var target := clampf(progress, 0.0, 1.0) * total
	for index in lengths.size():
		if target <= lengths[index] or index == lengths.size() - 1:
			return seal_path_points[index].lerp(seal_path_points[index + 1], clampf(target / maxf(lengths[index], 0.001), 0.0, 1.0))
		target -= lengths[index]
	return seal_path_points[-1]

func active_seal_anchor_global() -> Vector3:
	var outward := -0.06 if box_kind == "parcel" and parcel_seal_side == 1 else 0.06
	return to_global(seal_point_at_progress(seal_progress) + Vector3(0, outward, 0))

func next_seal_anchor_global(step := 0.025) -> Vector3:
	var outward := -0.06 if box_kind == "parcel" and parcel_seal_side == 1 else 0.06
	return to_global(seal_point_at_progress(minf(1.0, seal_progress + step)) + Vector3(0, outward, 0))

func tear_seal() -> void:
	if box_kind == "parcel":
		if parcel_seal_side == 0:
			set_ring_progress(seal_ring, seal_base_transforms, 1.0, top_seal_segment_count)
		else:
			set_ring_progress(bottom_seal_ring, bottom_seal_base_transforms, 1.0, bottom_seal_segment_count)
			seal_removed = true
	else:
		if seal_removed: return
		seal_removed = true
		set_seal_progress(1.0)
	seal_area.collision_layer = 0

func set_lid_progress(progress: float) -> void:
	lid_pivot.rotation.x = -clamp(progress, 0.0, 1.0) * 1.9

func finish_open_lid() -> void:
	if lid_opened: return
	lid_opened = true
	set_lid_progress(1.0)
	lid_area.collision_layer = 0
	if box_kind == "blind":
		content.visible = true
		content_area.collision_layer = 2
	else:
		mark_empty()

func play_auto_open() -> void:
	if box_kind == "blind":
		if lid_opened: return
		lid_opened = true
		lid_area.collision_layer = 0
		var blind_lid_tween := create_tween()
		blind_lid_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		blind_lid_tween.tween_property(lid_pivot, "rotation:x", -1.9, 0.22)
		await blind_lid_tween.finished
		content.visible = true
		return
	if parcel_seal_side == 0 and not parcel_top_opened:
		parcel_top_opened = true
		var top_tween := create_tween().set_parallel(true)
		top_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		top_tween.tween_property(lid_pivot, "rotation:z", 1.85, 0.28)
		top_tween.tween_property(lid_pivot_b, "rotation:z", -1.85, 0.28)
		await top_tween.finished
		parcel_seal_side = 1
		seal_progress = 0.0
		seal_path_points = bottom_seal_path.duplicate()
		seal_detach_points.clear()
		seal_detach_index = 0
		set_seal_progress(0.0)
		var flip_tween := create_tween()
		flip_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		flip_tween.tween_property(self, "rotation:x", rotation.x + PI, 0.42)
		await flip_tween.finished
		return
	if parcel_seal_side == 1 and not parcel_bottom_opened:
		parcel_bottom_opened = true
		lid_opened = true
		var bottom_tween := create_tween().set_parallel(true)
		bottom_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		bottom_tween.tween_property(bottom_lid_pivot, "rotation:z", -1.85, 0.28)
		bottom_tween.tween_property(bottom_lid_pivot_b, "rotation:z", 1.85, 0.28)
		await bottom_tween.finished

func has_more_parcel_seals() -> bool:
	return box_kind == "parcel" and not parcel_bottom_opened

func active_parcel_side_name() -> String:
	return "上面" if parcel_seal_side == 0 else "下面"

func play_flatten_animation() -> void:
	if box_kind != "parcel" or not parcel_top_opened or not parcel_bottom_opened: return
	var fold_tween := create_tween()
	fold_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	fold_tween.tween_method(set_wall_fold_progress, 0.0, 1.0, 0.58)
	await fold_tween.finished
	# The physics proxy follows the thin parallelogram envelope. No visible face
	# is scaled: all four CSG wall panels retain their original dimensions.
	body_collision.scale = Vector3(1.5, 1.0, 0.2)
	mark_empty()
	label_3d.text = "压扁纸箱"

func set_wall_fold_progress(progress: float) -> void:
	# A four-bar parallelogram viewed from above. The long front/back edges keep
	# their length and the side edges rotate around their shared vertical seams.
	var angle: float = lerpf(PI * 0.5, deg_to_rad(10.0), clampf(progress, 0.0, 1.0))
	var front_back_length := 1.1
	var side_length := 1.1
	var side_vector := Vector2(cos(angle) * side_length, sin(angle) * side_length)
	var half_long := front_back_length * 0.5
	front_wall.position.x = side_vector.x * 0.5
	front_wall.position.z = side_vector.y * 0.5
	back_wall.position.x = -side_vector.x * 0.5
	back_wall.position.z = -side_vector.y * 0.5
	right_wall.position.x = half_long
	right_wall.position.z = 0.0
	left_wall.position.x = -half_long
	left_wall.position.z = 0.0
	var side_rotation: float = PI * 0.5 - angle
	right_wall.rotation.y = side_rotation
	left_wall.rotation.y = side_rotation
	front_wall.rotation.y = 0.0
	back_wall.rotation.y = 0.0
	# All four opened door panels remain rigid; the wall fold changes only their
	# shared wall hinges and never scales a visible panel.
	lid_pivot.position.x = left_wall.position.x
	lid_pivot.position.z = left_wall.position.z
	lid_pivot.rotation.y = left_wall.rotation.y
	lid_pivot_b.position.x = right_wall.position.x
	lid_pivot_b.position.z = right_wall.position.z
	lid_pivot_b.rotation.y = right_wall.rotation.y
	bottom_lid_pivot.position.x = left_wall.position.x
	bottom_lid_pivot.position.z = left_wall.position.z
	bottom_lid_pivot.rotation.y = left_wall.rotation.y
	bottom_lid_pivot_b.position.x = right_wall.position.x
	bottom_lid_pivot_b.position.z = right_wall.position.z
	bottom_lid_pivot_b.rotation.y = right_wall.rotation.y
	label_3d.position.x = front_wall.position.x
	label_3d.position.z = front_wall.position.z + 0.065

func set_content_lift(progress: float) -> void:
	content.position.y = 0.45 + clamp(progress, 0.0, 1.0) * 0.85
	content_area.position.y = content.position.y

func mark_empty() -> void:
	opened = true
	content.visible = false
	content_area.collision_layer = 0
	label_3d.text = "空盒"

func content_color() -> Color:
	var material := content.material as StandardMaterial3D
	return material.albedo_color if material else Color.WHITE
