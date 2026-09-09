@tool
extends Node3D
## Keep the supplied FBX UVs and expose the packaging material in the editor.
@export var packaging_material: Material:
	set(value):
		packaging_material = value
		if is_inside_tree(): _apply_material()

func _ready() -> void:
	_apply_material()

func _apply_material() -> void:
	if not packaging_material: return
	for mesh in find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = packaging_material
