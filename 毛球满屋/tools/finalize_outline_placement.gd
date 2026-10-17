extends SceneTree
## Preserve artist geometry; only normalize already-placed palette duplicates
## and set the requested compositing order. Never regenerate the layout.
const PATH = "res://scenes/prototype_grooming/轮廓毛发摆放.tscn"
const OUT = "res://reports/authored_outline_20261017/"

func _initialize() -> void:call_deferred("run")

func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 var source: String = FileAccess.get_file_as_string(PATH)
 # Keep the exact handoff outside .tscn import to avoid duplicate scene UIDs.
 if not FileAccess.file_exists(OUT + "user_handoff_original.txt"):
  FileAccess.open(OUT + "user_handoff_original.txt", FileAccess.WRITE).store_string(source)
 var scene: Node2D = load(PATH).instantiate()
 var large: Node2D = scene.get_node("大猫摆放区")
 var small: Node2D = scene.get_node("小猫摆放区")
 var moved: Array = []
 var palette: Node2D = scene.get_node("轮廓素材区_仅供复制")
 for node in palette.get_children():
  if not node is Sprite2D or not node.visible:continue
  var target: Node2D = null
  for area in [large, small]:
   if Rect2(0,0,1920,1080).has_point(area.to_local(node.global_position)):target = area;break
  if target == null:continue
  var before: Transform2D = node.global_transform
  var previous_path: String = str(scene.get_path_to(node))
  # These hand-placed duplicates lie on the large cat's back, not in the
  # original palette showcase. Body group is the correct handoff destination.
  var group: Node2D = target.get_node("可编辑轮廓/躯干")
  node.owner = null
  node.reparent(group, true);node.owner = scene
  node.set_meta("placement_role", "outline")
  node.set_meta("authoring_origin_path", previous_path)
  node.set_meta("service_region", "body")
  node.service_region = "body"
  node.reference_body_rect = target.get_meta("body_rect")
  if not node.global_transform.is_equal_approx(before):
   push_error("Reparent changed artist geometry: " + previous_path);quit(1);return
  moved.append({"from":previous_path,"to":str(scene.get_path_to(node)),"position":[node.global_position.x,node.global_position.y],"angle":node.global_rotation,"scale":[node.global_scale.x,node.global_scale.y]})
 for area in [large, small]:
  area.get_node("参考底层_请勿移动/当前身躯毛片_锁定").z_index = 2
  area.get_node("可编辑轮廓").z_index = 1
 scene.set_meta("runtime_applied", true)
 scene.set_meta("runtime_task", "IMP-20261017-008")
 scene.set_meta("authoring_note", "编辑后Ctrl+S并重新运行fur_demo；实机已读取轮廓，位于躯干毛片下方。不要重新生成覆盖。")
 var packed = PackedScene.new()
 if packed.pack(scene) != OK or ResourceSaver.save(packed, PATH) != OK:
  push_error("Cannot preserve final authored scene");quit(1);return
 FileAccess.open(OUT + "handoff.json", FileAccess.WRITE).store_string(JSON.stringify({"moved_palette_pieces":moved,"source_sha256":source.sha256_text(),"result_sha256":FileAccess.get_file_as_string(PATH).sha256_text(),"edge_z":1,"body_z":2}, "  "))
 print("HANDOFF normalized ", moved.size(), " placed palette duplicates; transforms retained")
 scene.free();quit()
