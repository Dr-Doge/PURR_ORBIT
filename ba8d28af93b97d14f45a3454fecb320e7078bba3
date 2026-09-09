@tool
extends Node3D

@export_range(0, 20) var upgrade_level := 0:
	set(value):
		upgrade_level = value
		if is_inside_tree(): rebuild()

func _ready() -> void:
	rebuild()

func slot_position(index: int) -> Vector3:
	var row := index / 2
	var pitch := minf(0.9, 3.6 / float(upgrade_level + 2))
	return Vector3(-0.8 + (index % 2) * 2.2, 0.56 + row * 0.70, -2.35 + row * pitch)

func rebuild() -> void:
	for child in get_children():
		if child.name.begins_with("Acrylic_"):
			remove_child(child)
			child.queue_free()
		elif child.name.begins_with("Slot_") or child.name in ["ShelfBase", "ShelfBackRail"]:
			child.hide()
	var acrylic := StandardMaterial3D.new()
	acrylic.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	acrylic.albedo_color = Color(0.72, 0.93, 1.0, 0.30)
	acrylic.roughness = 0.16
	acrylic.cull_mode = BaseMaterial3D.CULL_DISABLED
	var pitch := minf(0.9, 3.6 / float(upgrade_level + 2))
	for row in upgrade_level + 2:
		var surface := slot_position(row * 2)
		var top := CSGBox3D.new()
		top.name = "Acrylic_Tier_%d" % row
		top.size = Vector3(4.5, 0.08, pitch)
		top.position = Vector3(0.3, surface.y - 0.04, surface.z)
		top.material = acrylic
		top.use_collision = true
		top.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(top)
		for side in [-1, 1]:
			var leg := CSGBox3D.new()
			leg.name = "Acrylic_Support_%d_%d" % [row, side]
			leg.size = Vector3(0.06, surface.y - 0.08, pitch)
			leg.position = Vector3(0.3 + side * 2.2, (surface.y - 0.08) / 2.0, surface.z)
			leg.material = acrylic
			leg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(leg)
