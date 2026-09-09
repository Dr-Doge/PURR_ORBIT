extends SceneTree

const STALL := preload("res://scripts/stall_demo/stall_demo.gd")


func _init() -> void:
	var packed := load("res://scenes/stall_demo/stall_demo.tscn") as PackedScene
	if packed == null:
		push_error("无法载入摆摊场景。")
		quit(1)
		return
	var scene := packed.instantiate() as Node3D
	var street := scene.get_node("CSGAnimePedestrianStreet") as Node3D
	var customer_root := scene.get_node("CSGAnimePedestrianStreet/CSGCustomers") as Node3D
	var pedestrian_root := scene.get_node("CSGAnimePedestrianStreet/CSGStreetPedestrians") as Node3D
	var sidewalk := scene.get_node("CSGAnimePedestrianStreet/Sidewalk") as CSGBox3D
	var desk := scene.get_node("Room/Desk") as CSGBox3D
	var failed := false
	if customer_root.get_parent() != street or pedestrian_root.get_parent() != street:
		push_error("顾客与行人必须继承步行街根节点的缩放。")
		failed = true
	var expected_surface_y := sidewalk.position.y + sidewalk.size.y * 0.5
	if not is_equal_approx(expected_surface_y, STALL.STREET_SURFACE_Y):
		push_error("人物脚底高度没有贴合步行街人行道表面。")
		failed = true
	var customer_feet := street.transform * Vector3(0.5, STALL.STREET_SURFACE_Y, STALL.STREET_CUSTOMER_Z)
	var desk_top := desk.position.y + desk.size.y * 0.5
	var desk_front := desk.position.z - desk.size.z * 0.5
	if customer_feet.y >= desk_top or customer_feet.z >= desk_front:
		push_error("顾客驻足点必须位于桌面以下、桌子前方的街道上。")
		failed = true
	var customer_head_y := customer_feet.y + street.basis.get_scale().y * 2.68 * 1.06
	if customer_head_y <= desk_top:
		push_error("继承街道缩放后的顾客仍小于桌面高度。")
		failed = true
	scene.free()
	if failed:
		quit(1)
	else:
		print("STALL_SCALE_OK: street-local customers and pedestrians inherit authored scale")
		quit(0)
