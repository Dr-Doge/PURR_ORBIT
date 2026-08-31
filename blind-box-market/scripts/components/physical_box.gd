extends RigidBody3D

var box_kind := "parcel"
var series_index := -1
var rarity := -1
var paid_price: int = 0
var opened := false
var seal_removed := false
var lid_opened := false

@onready var shell_parts: Array[Node] = $Shell.get_children()
@onready var lid: CSGBox3D = $LidPivot/Lid
@onready var lid_pivot: Node3D = $LidPivot
@onready var seal: CSGBox3D = $Seal
@onready var seal_area: Area3D = $SealArea
@onready var lid_area: Area3D = $LidArea
@onready var content: CSGSphere3D = $Content
@onready var content_area: Area3D = $ContentArea
@onready var label_3d: Label3D = $FrontLabel

func setup(kind: String, box_series: int, box_rarity: int, paid: int, color: Color) -> void:
	box_kind = kind
	series_index = box_series
	rarity = box_rarity
	paid_price = paid
	if not is_node_ready(): await ready
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = color
	body_material.roughness = 0.82
	for part in shell_parts:
		if part is CSGShape3D: part.material = body_material
	lid.material = body_material
	label_3d.text = "快递 ¥1" if kind == "parcel" else "盲盒 %d" % (box_series + 1)
	var content_material := StandardMaterial3D.new()
	content_material.albedo_color = Color("#8dd7bd") if kind == "parcel" else color.lightened(0.32)
	content_material.emission_enabled = kind == "blind"
	content_material.emission = color * 0.4
	content.material = content_material

func tear_seal() -> void:
	if seal_removed: return
	seal_removed = true
	seal.visible = false
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
