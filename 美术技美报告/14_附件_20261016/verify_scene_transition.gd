extends SceneTree
func _initialize():
 call_deferred("check")
func check():
 var s=load("res://scenes/Concept Whitebox.tscn").instantiate()
 root.add_child(s)
 var main=s.get_node("GameCamera")
 main.set_process(false)
 var door=s.get_node("21_ArtAirlock")
 var home=main.global_transform
 var key=InputEventKey.new()
 key.physical_keycode=KEY_P
 key.pressed=true
 main._input(key)
 main._unhandled_input(key)
 assert(main.is_current() and not main.free_view and not main._closeup_active)
 assert(main._fade_rect.size==root.get_visible_rect().size)
 main.transition_chamber()
 await create_timer(0.4).timeout
 assert(main.global_transform.is_equal_approx(home))
 assert(door.busy)
 await create_timer(0.46).timeout
 assert(door.opened and not door.busy)
 assert(not main.global_transform.is_equal_approx(home))
 await create_timer(0.22).timeout
 assert(main._closeup_active and main._fade_rect.color.a==1.0)
 await create_timer(0.42).timeout
 assert(not main._transition_busy and main._fade_rect.color.a==0)
 main.transition_chamber()
 await create_timer(0.7).timeout
 assert(main.is_current() and door.opened and not door.busy)
 await create_timer(0.4).timeout
 assert(door.busy)
 await create_timer(0.8).timeout
 assert(not door.opened and not door.busy and not main._transition_busy)
 assert(main.global_transform.is_equal_approx(home))
 print("PASS: opening/zoom timing, full-screen black hold, visible delayed closing, camera restoration.")
 quit()
