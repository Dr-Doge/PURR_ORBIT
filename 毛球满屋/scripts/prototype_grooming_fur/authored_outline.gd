extends RefCounted
## Read geometry from the saved scene without entering its @tool nodes into
## the tree. Art and node transforms are authoritative; preview scripts are not.
static func read(scene: PackedScene, cat_scale: float) -> Dictionary:
 var result: Dictionary = {"pieces":[],"body_pieces":[],"errors":[]}
 if scene == null:return result
 var instance: Node = scene.instantiate()
 var area: Node2D = instance.get_node_or_null("大猫摆放区" if cat_scale == 1.0 else "小猫摆放区")
 if area == null:
  result.errors.append("Missing authoring cat area");instance.free();return result
 result.body_rect = area.get_meta("body_rect", Rect2())
 var outlines: Node = area.get_node_or_null("可编辑轮廓")
 if outlines == null:
  result.errors.append("Missing authored contour group");instance.free();return result
 collect(outlines, area, instance, true, "body", result)
 var bodies: Node=area.get_node_or_null("参考底层_请勿移动/当前身躯毛片_锁定")
 if bodies!=null:collect(bodies,area,instance,true,"body",result,false)
 instance.free()
 return result

static func collect(node: Node, area: Node2D, owner_scene: Node, ancestors_visible: bool, region: String, result: Dictionary, is_outline: bool=true) -> void:
 var shown: bool = ancestors_visible and (not node is CanvasItem or node.visible)
 if not shown:return
 region = str(node.get_meta("service_region", region)) if not node is Sprite2D else region
 if node is Sprite2D:
  var s: Sprite2D = node
  if s.texture == null:return
  var source_path: String = s.texture.resource_path
  var type: String = source_path.get_file().get_basename()
  if is_outline and not type.begins_with("edge_"):
   result.errors.append("Unsupported contour texture at " + str(owner_scene.get_path_to(s)));return
  var relative: Transform2D = area.global_transform.affine_inverse() * s.global_transform
  var dimensions: Vector2 = Vector2(s.texture.get_size())
  var signed_scale: Vector2 = relative.get_scale()
  var size: Vector2 = dimensions * signed_scale.abs()
  if size.x <= 0 or size.y <= 0:
   result.errors.append("Zero-size contour at " + str(owner_scene.get_path_to(s)));return
  if absf(relative.x.normalized().dot(relative.y.normalized())) > .001:
   result.errors.append("Skewed contour needs calibration: " + str(owner_scene.get_path_to(s)));return
  var center: Vector2 = relative * (s.offset + (Vector2.ZERO if s.centered else dimensions * .5))
  var bucket: String="pieces" if is_outline else "body_pieces"
  var assigned_region: String=region if is_outline else str(s.get_meta("service_region",region))
  result[bucket].append({"path":str(owner_scene.get_path_to(s)),"type":type,"texture":s.texture,"resource_path":source_path,"center":center,"size":size,"angle":relative.get_rotation(),"flip_h":s.flip_h != (signed_scale.x < 0),"flip_v":s.flip_v != (signed_scale.y < 0),"region":assigned_region})
 for child in node.get_children():collect(child, area, owner_scene, shown, region, result,is_outline)
