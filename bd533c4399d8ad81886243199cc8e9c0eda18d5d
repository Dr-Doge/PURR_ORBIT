extends SceneTree

func _init() -> void:
	call_deferred("run")

func capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://" + filename + ".png")

func make_walker(stall: Node, x: float, z: float, direction: float, category: int) -> Node3D:
	var person: Node3D = stall._create_city_person(category, 1.0)
	person.position = Vector3(x, stall.STREET_SURFACE_Y, z)
	person.set_meta("travel_direction", direction)
	person.set_meta("avoid_side", -direction)
	person.set_meta("avoid_time", 0.0)
	person.set_meta("avoid_lane", z)
	stall.stall_pedestrian_root.add_child(person)
	return person

func run() -> void:
	var stall = load("res://scenes/stall_demo/stall_demo.tscn").instantiate()
	root.add_child(stall)
	await process_frame
	stall.set_process(false)
	assert(stall.BUSINESS_START == 10.0 and stall.BUSINESS_END == 18.0)
	assert(stall.BUSINESS_SECONDS == 240.0)

	# Oncoming actors use their own fixed right side and cross without deadlock.
	stall._clear_pedestrians()
	var east := make_walker(stall, -3.0, -7.85, 1.0, 5)
	var west := make_walker(stall, 3.0, -7.85, -1.0, 6)
	stall.stall_pedestrians.append_array([
		{"node":east, "direction":1.0, "speed":1.35, "profile":5, "lane":-7.85},
		{"node":west, "direction":-1.0, "speed":1.35, "profile":6, "lane":-7.85},
	])
	var east_min_z := east.position.z
	var west_max_z := west.position.z
	for frame in 600:
		stall._walk_with_avoidance(east, Vector3(5, stall.STREET_SURFACE_Y, -7.85), 1.35, 1.0 / 60.0)
		stall._walk_with_avoidance(west, Vector3(-5, stall.STREET_SURFACE_Y, -7.85), 1.35, 1.0 / 60.0)
		east_min_z = minf(east_min_z, east.position.z)
		west_max_z = maxf(west_max_z, west.position.z)
	assert(east.position.x > 4.5 and west.position.x < -4.5, "Oncoming walkers must pass")
	assert(east_min_z < -8.1 and west_max_z > -7.6, "Each walker must keep right relative to facing")

	# Exactly two recruited walkers can occupy separate browsing positions.
	stall._clear_pedestrians()
	var first := make_walker(stall, -2.5, -6.5, 1.0, 1)
	var second := make_walker(stall, 2.5, -9.3, -1.0, 2)
	stall.stall_pedestrians.append_array([
		{"node":first, "direction":1.0, "speed":1.2, "profile":1, "lane":-6.5},
		{"node":second, "direction":-1.0, "speed":1.2, "profile":2, "lane":-9.3},
	])
	stall._spawn_customer()
	stall._spawn_customer()
	assert(stall.stall_customer != null and stall.stall_waiting_customers.size() == 1)
	var street_count_before_third: int = stall.stall_pedestrians.size()
	stall._spawn_customer()
	assert(stall.stall_waiting_customers.size() == 1 and stall.stall_pedestrians.size() == street_count_before_third)
	var active_id: int = stall.stall_customer.get_instance_id()
	var waiting_id: int = stall.stall_waiting_customers[0]["node"].get_instance_id()
	assert(active_id != waiting_id)
	for frame in 300:
		stall._update_customer(1.0 / 60.0)
		if stall.stall_customer_phase == "browse" and stall.stall_waiting_customers[0]["phase"] == "browse": break
	assert(stall.stall_customer_phase == "browse")
	assert(stall.stall_waiting_customers[0]["phase"] == "browse")
	assert(stall.stall_customer.position.distance_to(stall.stall_waiting_customers[0]["node"].position) > 1.8)
	await capture("two_stall_visitors")

	# Interaction layers no longer stop the clock or moving street actors.
	stall._clear_customer()
	stall._clear_pedestrians()
	stall.stall_ready = true
	stall.stall_preparing = false
	stall.stall_day_finished = false
	stall.stall_business_elapsed = 20.0
	var passer := make_walker(stall, -4.0, -6.5, 1.0, 5)
	stall.stall_pedestrians.append({"node":passer, "direction":1.0, "speed":1.3, "profile":5, "lane":-6.5})
	var start_x: float = passer.position.x
	stall.stall_bargain_panel.show()
	stall._process(0.5)
	assert(stall.stall_business_elapsed > 20.45)
	assert(passer.position.x > start_x)
	stall.stall_bargain_panel.hide()
	stall.spawn_box("blind", 0, 0, 20)
	var box: RigidBody3D = stall.boxes.back()
	stall.focus_box(box)
	var before_focus_time: float = stall.stall_business_elapsed
	start_x = passer.position.x
	stall._process(0.5)
	assert(stall.stall_business_elapsed > before_focus_time + 0.45)
	assert(passer.position.x > start_x)

	stall.queue_free()
	await process_frame
	print("LIVE_BUSINESS_TRAFFIC_OK: fixed-right passing, two visitor slots, 10-18 in four minutes, live time during interactions")
	quit()
