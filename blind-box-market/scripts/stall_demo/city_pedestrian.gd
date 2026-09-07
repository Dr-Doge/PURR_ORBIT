extends Node3D
## Imported city character. +Z is the actor's face; movement controls heading.
const ASSET_ROOT := "res://assets/Cartoon City Massive Megapack/gLTF/"
const CHARACTERS := ["Character_11_1_1", "Character_2_1_1", "Character_6_1_1", "Character_5_1_1", "Character_7_1_1", "Character_8_1_1", "Character_10_1_1", "Character_3_1_1"]
const MODEL_POOLS := [
	["Character_11_1_1", "Character_11_2_1", "Character_11_3_1"],
	["Character_2_1_1", "Character_2_2_1", "Character_2_3_1"],
	["Character_6_1_1", "Character_6_2_1", "Character_6_3_1"],
	["Character_5_1_1", "Character_5_2_1", "Character_5_3_1"],
	["Character_7_1_1", "Character_7_2_1", "Character_9_1_1"],
	["Character_8_1_1", "Character_8_2_1", "Character_8_3_1"],
	["Character_10_1_1", "Character_10_2_1", "Character_10_3_1"],
	["Character_3_1_1", "Character_3_2_1", "Character_3_3_1"],
	["Character_9_2_1", "Character_9_3_1", "Character_9_4_1"],
]
const CATEGORY_NAMES := ["穷学生", "普通爱好者", "补全党", "土豪父母", "收藏家", "上班族", "休闲游客", "街坊长者", "装机店老板"]
static var animation_libraries: Dictionary = {}
var animation_player: AnimationPlayer
var profile_index := 1
var walk_clip := "Walk_A"

func setup(category: int, height_scale := 1.0, variant := 0) -> void:
	profile_index = category
	name = "CityPedestrian_%d" % category
	set_meta("category", CATEGORY_NAMES[category])
	var model_name: String = MODEL_POOLS[category][posmod(variant, 3)]
	set_meta("model_asset", model_name)
	var visual := Node3D.new()
	visual.name = "Visual"
	# Rendered Walk/Idle clips face -Z. Rotate the rig to actor-local +Z.
	visual.rotation.y = PI
	visual.scale = Vector3.ONE * (1.52 * height_scale)
	add_child(visual)
	var asset: Node3D = load(ASSET_ROOT + "Characters/" + model_name + ".glb").instantiate()
	visual.add_child(asset)
	var skeleton := asset.find_child("Skeleton3D", true, false) as Skeleton3D
	assert(skeleton != null, "City character must contain a skeleton")
	animation_player = AnimationPlayer.new()
	animation_player.name = "Locomotion"
	asset.add_child(animation_player)
	var skeleton_path := String(asset.get_path_to(skeleton))
	var cache_key := skeleton_path + str(skeleton.get_bone_count())
	if not animation_libraries.has(cache_key):
		var source: Node = load(ASSET_ROOT + "Animations/Animations.glb").instantiate()
		var source_player := source.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var library := AnimationLibrary.new()
		for clip in ["Walk_A", "Walk_B", "Walk_C", "Idle_A", "LookingAround"]:
			var animation := source_player.get_animation(clip).duplicate() as Animation
			animation.loop_mode = Animation.LOOP_LINEAR
			for track in range(animation.get_track_count() - 1, -1, -1):
				var path := animation.track_get_path(track)
				var bone := String(path.get_subname(0)) if path.get_subname_count() > 0 else ""
				if skeleton.find_bone(bone) < 0:
					animation.remove_track(track)
					continue
				animation.track_set_path(track, NodePath(skeleton_path + ":" + bone))
				# Keep locomotion in place; the street controller owns world movement.
				if bone == "Hips" and animation.track_get_type(track) == Animation.TYPE_POSITION_3D:
					var origin: Vector3 = animation.track_get_key_value(track, 0)
					for key in animation.track_get_key_count(track):
						var value: Vector3 = animation.track_get_key_value(track, key)
						value.x = origin.x
						value.z = origin.z
						animation.track_set_key_value(track, key, value)
			library.add_animation(clip, animation)
		source.free()
		animation_libraries[cache_key] = library
	animation_player.add_animation_library("", animation_libraries[cache_key])
	walk_clip = ["Walk_A", "Walk_B", "Walk_C"][category % 3]
	set_walking(false)

func set_walking(walking: bool, speed := 1.4) -> void:
	var clip := walk_clip if walking else "Idle_A"
	if animation_player.current_animation != clip: animation_player.play(clip, 0.18)
	animation_player.speed_scale = clampf(speed / 1.4, 0.65, 1.6) if walking else 1.0

func face_direction(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.00001: return
	rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), minf(delta * 9.0, 1.0))

func walk_to(target: Vector3, speed: float, delta: float) -> bool:
	var direction := target - position
	face_direction(direction, delta)
	set_walking(true, speed)
	position = position.move_toward(target, speed * delta)
	return position.distance_to(target) < 0.02
