extends SceneTree
const DEST = "res://scenes/prototype_grooming/轮廓毛发摆放.tscn"
const REPORT = "res://reports/authored_outline_20261017/editor_round_trip/"
var checks = 0
var failures: Array[String] = []

func check(value: bool, note: String) -> void:
 checks += 1
 if not value:failures.append(note);push_error(note)

func _initialize() -> void:
 call_deferred("run")

func leaves(node: Node, type: String) -> Array:
 var found: Array = []
 for child in node.get_children():
  if child is Sprite2D and child.get_meta("placement_role", "") == type:found.append(child)
  found.append_array(leaves(child, type))
 return found

func clear_owners(node: Node) -> void:
 node.owner = null
 for child in node.get_children():clear_owners(child)

func run() -> void:
 DirAccess.make_dir_recursive_absolute(REPORT)
 var scene: PackedScene = load(DEST)
 check(scene != null, "authoring scene loads")
 var instance = scene.instantiate()
 get_root().add_child(instance)
 await process_frame
 var all = leaves(instance, "outline")
 check(all.size() == 104, "104 hand-authored contour pieces including moved palette copies")
 var large = instance.get_node("大猫摆放区")
 var small = instance.get_node("小猫摆放区")
 check(leaves(large, "outline").size() == 52, "large has 52 contours")
 check(leaves(small, "outline").size() == 52, "small has 52 contours")
 check(large.get_node("参考底层_请勿移动/当前身躯毛片_锁定").get_child_count() == 337, "large body snapshot")
 check(small.get_node("参考底层_请勿移动/当前身躯毛片_锁定").get_child_count() == 76, "small body snapshot")
 check(instance.get_node("轮廓素材区_仅供复制").get_child_count() == 17, "eight independently cropped palette sprites and captions")
 for piece in all:
  check(piece.owner == instance, "%s saved owner" % piece.name)
  check(piece.texture is AtlasTexture, "%s actual cropped atlas asset" % piece.name)
  check(not piece.has_meta("_edit_lock_"), "%s selectable" % piece.name)
  check(piece.material is ShaderMaterial, "%s tinted preview" % piece.name)
  check(piece.material.get_shader_parameter("coat_map") != null, "%s coat reference persisted" % piece.name)
 var first: Sprite2D = all[0]
 var second: Sprite2D = all[1]
 check(first.material != second.material, "each piece owns an independent preview material")
 var duplicate: Sprite2D = first.duplicate()
 first.get_parent().add_child(duplicate)
 duplicate.owner = instance
 duplicate.name = "手工新毛条_保存验证"
 duplicate.position += Vector2(31, -13)
 duplicate.rotation += deg_to_rad(11)
 duplicate.scale *= 1.12
 duplicate.flip_h = true
 duplicate.refresh_preview()
 var saved_at = duplicate.position
 var saved_angle = duplicate.rotation
 var saved_scale = duplicate.scale
 var saved_path = instance.get_path_to(duplicate)
 check(duplicate.material != first.material, "duplicated preview material remains independent")
 var held = all[2].position
 all[2].refresh_preview()
 check(all[2].position == held, "preview never rearranges authored geometry")
 var packed = PackedScene.new()
 check(packed.pack(instance) == OK, "manual edit packs")
 check(ResourceSaver.save(packed, REPORT + "manual_round_trip.tscn") == OK, "manual edit saves only isolated report")
 var restored = load(REPORT + "manual_round_trip.tscn").instantiate()
 get_root().add_child(restored)
 var edited: Sprite2D = restored.get_node(saved_path)
 check(edited.position.is_equal_approx(saved_at), "position survives reopen")
 check(is_equal_approx(edited.rotation, saved_angle), "angle survives reopen")
 check(edited.scale.is_equal_approx(saved_scale), "scale survives reopen")
 check(edited.flip_h, "flip survives reopen")
 check(edited.texture.resource_path == first.texture.resource_path, "asset identity survives reopen")
 check(leaves(restored, "outline").size() == 105, "duplicated contour survives reopen")
 # A template moved to the small cat must use its new host's body rectangle.
 var template: Sprite2D = instance.get_node("轮廓素材区_仅供复制/edge_cream_belly").duplicate()
 var group: Node = small.get_node("可编辑轮廓/胸前")
 group.add_child(template);template.owner = instance
 template.position = Vector2(690, 820);template.scale = Vector2(.2, .2)
 template.refresh_preview()
 check(template.material.get_shader_parameter("body_dimensions").is_equal_approx(small.get_meta("body_rect").size), "palette duplicate maps to small cat automatically")
 group.remove_child(template);template.free()
 restored.free();instance.free()
 if DisplayServer.get_name() != "headless":
  for title in ["大猫摆放区", "小猫摆放区"]:
   var source = scene.instantiate()
   var area = source.get_node(title)
   clear_owners(area)
   source.remove_child(area);area.position = Vector2.ZERO
   var viewport = SubViewport.new()
   viewport.size = Vector2i(1920,1080)
   viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
   get_root().add_child(viewport);viewport.add_child(area)
   source.free()
   await process_frame
   await process_frame
   await RenderingServer.frame_post_draw
   check(viewport.get_texture().get_image().save_png(REPORT + title + ".png") == OK, title + " rendered")
   viewport.queue_free()
 var file = FileAccess.open(REPORT + "checks.json", FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":checks,"failures":failures,"runtime_imported":false}, "  "))
 print("OUTLINE_PLACEMENT_CHECKS ", checks, " failures=", failures.size())
 quit(0 if failures.is_empty() else 1)
