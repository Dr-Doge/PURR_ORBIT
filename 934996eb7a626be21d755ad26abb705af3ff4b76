@tool
extends Node3D

const MAX_UPGRADE := 10
@export_range(0, 10) var upgrade_level := 0:
	set(value):
		upgrade_level = clampi(value, 0, MAX_UPGRADE)
		if is_inside_tree(): rebuild()

func _ready() -> void:
	rebuild()

func slot_position(index: int) -> Vector3:
	var tier := index / 2
	var stand := mini(2, tier / 4)
	var row := tier % 4
	# Side displays leave the central five units clear for box deliveries.
	var center: float = [-4.0, 4.0, -7.6][stand]
	return Vector3(center - 0.80 + (index % 2) * 1.6, 0.56 + row * 1.25, -3.45 + row * 1.25)

func rebuild() -> void:
	for child in get_children():
		if child.name.begins_with("Acrylic_"):
			remove_child(child)
			child.queue_free()
		elif child.name.begins_with("Slot_") or child.name in ["ShelfBase", "ShelfBackRail"]:
			child.hide()
	var acrylic := StandardMaterial3D.new()
	acrylic.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	acrylic.albedo_color = Color(0.72, 0.93, 1.0, 0.18)
	acrylic.roughness = 0.16
	acrylic.cull_mode = BaseMaterial3D.CULL_DISABLED
	var pitch := 1.25
	for row in upgrade_level + 2:
		var surface := slot_position(row * 2)
		var top := CSGBox3D.new()
		top.name = "Acrylic_Tier_%d" % row
		top.size = Vector3(3.4, 0.08, pitch)
		top.position = Vector3(surface.x + 0.80, surface.y - 0.04, surface.z)
		top.material = acrylic
		top.use_collision = true
		top.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(top)
		for side in [-1, 1]:
			var leg := CSGBox3D.new()
			leg.name = "Acrylic_Support_%d_%d" % [row, side]
			leg.size = Vector3(0.06, surface.y - 0.08, pitch)
			leg.position = Vector3(surface.x + 0.80 + side * 1.67, (surface.y - 0.08) / 2.0, surface.z)
			leg.material = acrylic
			leg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(leg)
