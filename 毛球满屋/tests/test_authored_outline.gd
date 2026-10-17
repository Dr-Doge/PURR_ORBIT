extends SceneTree
const Model = preload("res://scripts/prototype_grooming_fur/model.gd")
const Brush = preload("res://scripts/prototype_grooming_fur/brush_config.gd")
const SCENE = "res://scenes/prototype_grooming/轮廓毛发摆放.tscn"
const OUT = "res://reports/fur_asset_cleanup_20261017/"
const ORIGINAL_HANDOFF = "res://reports/authored_outline_20261017/"
var checks = 0
var failures: Array = []
var measurements: Array = []

func check(ok: bool, note: String) -> void:
 checks += 1
 if not ok:failures.append(note);push_error(note)

func _initialize() -> void:call_deferred("run")

func contours(node: Node) -> Array:
 var found: Array = []
 for child in node.get_children():
  if child is Sprite2D:found.append(child)
  found.append_array(contours(child))
 return found

func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 var saved_sha: String = FileAccess.get_file_as_string(SCENE).sha256_text()
 var authored = load(SCENE).instantiate()
 # Reconstruct the untouched handoff only in a report fixture for comparison.
 var original_text: String = FileAccess.get_file_as_string(ORIGINAL_HANDOFF + "user_handoff_original.txt")
 var newline: int = original_text.find("\n")
 FileAccess.open(OUT + "original_geometry_fixture.tscn", FileAccess.WRITE).store_string("[gd_scene format=3]\n" + original_text.substr(newline + 1))
 var original = load(OUT + "original_geometry_fixture.tscn").instantiate()
 var normalized: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ORIGINAL_HANDOFF + "handoff.json"))
 for piece in normalized.moved_palette_pieces:
  var before: Sprite2D = original.get_node(piece.from)
  var after: Sprite2D = authored.get_node(piece.to)
  check(before.global_transform.is_equal_approx(after.global_transform), "placed palette transform unchanged: " + str(piece.from))
  check(before.texture.resource_path == after.texture.resource_path, "placed palette texture unchanged: " + str(piece.from))
 for size in [1.0, .5]:
  var area = authored.get_node("大猫摆放区" if size == 1.0 else "小猫摆放区")
  var group = area.get_node("可编辑轮廓")
  var expected: Array = contours(group)
  check(expected.size() == 52, "52 authored pieces in size " + str(size))
  var m = Model.new();m.next_cat_scale = size;m.start_order(0)
  check(m.authored_outline_errors.is_empty(), "saved layout accepted without fallback " + str(size))
  var imported: Array = m.objects.filter(func(obj):return obj.rule == "edge")
  check(imported.size() == expected.size(), "no procedural extras or missing authored pieces " + str(size))
  var indexed = {};var ids = {}
  for obj in m.objects:
   check(not ids.has(obj.id), "unique runtime source ID " + str(obj.id) + "/" + str(size))
   ids[obj.id] = true
   if obj.rule == "edge":indexed[obj.authored_path] = obj
  for node in expected:
   var path: String = str(authored.get_path_to(node))
   var obj: Dictionary = indexed[path]
   var relative: Transform2D = area.global_transform.affine_inverse() * node.global_transform
   var dimensions: Vector2 = Vector2(node.texture.get_size()) * relative.get_scale().abs()
   check(obj.rect.get_center().distance_to(relative.origin) < .003, "manual center retained: " + path)
   check(obj.rect.size.distance_to(dimensions) < .003, "manual size retained: " + path)
   check(is_equal_approx(obj.draw_angle, relative.get_rotation()), "manual angle retained: " + path)
   check(obj.authored_texture_path == node.texture.resource_path, "actual texture identity retained: " + path)
   check(obj.region == node.get_parent().get_meta("service_region"), "parent region retained: " + path)
   var earlier: String = str(node.get_meta("authoring_origin_path", path))
   var original_node: Sprite2D = original.get_node_or_null(earlier)
   check(original_node != null and original_node.global_transform.is_equal_approx(node.global_transform), "all user transforms preserved: " + earlier)
  var source_body: Array = contours(area.get_node("参考底层_请勿移动/当前身躯毛片_锁定"))
  var actual_body: Array = m.objects.filter(func(obj):return obj.rule == "patch")
  check(actual_body.size() == source_body.size(), "unchanged body count " + str(size))
  for i in range(actual_body.size()):
   var obj: Dictionary = actual_body[i];var s: Sprite2D = source_body[i]
   check(obj.rect.get_center().distance_to(s.position) < .003 and is_equal_approx(obj.draw_angle,s.rotation), "body backdrop unchanged " + str(i) + "/" + str(size))
  measurements.append({"scale":size,"body_count":actual_body.size(),"authored_outline_count":imported.size(),"total":m.objects.size()})
  # Changing generation must not lose the authoring choice on subsequent cats.
  var before_paths: Array = indexed.keys()
  m.start_order(0)
  var after_paths: Array = m.objects.filter(func(obj):return obj.rule == "edge").map(func(obj):return obj.authored_path)
  check(before_paths == after_paths, "next customer uses saved manual contours " + str(size))
 original.free();authored.free()
 if DisplayServer.get_name() != "headless":await render_layering()
 check(saved_sha == FileAccess.get_file_as_string(SCENE).sha256_text(), "verification cannot overwrite artist scene")
 FileAccess.open(OUT + "integration.json", FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"layouts":measurements},"  "))
 print("AUTHORED OUTLINE: ",checks," checks; ",failures.size()," failures")
 quit(0 if failures.is_empty() else 1)

func screenshot(viewport: SubViewport, filename: String) -> Image:
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 var image: Image = viewport.get_texture().get_image()
 image.save_png(OUT + filename)
 return image

func render_layering() -> void:
 for size in [1.0,.5]:
  var vp = SubViewport.new();vp.size = Vector2i(1920,1080);vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
  get_root().add_child(vp)
  var game = load("res://scenes/prototype_grooming/fur_demo.tscn").instantiate();vp.add_child(game)
  await process_frame
  game.set_process(false);game.model.next_cat_scale = size;game.model.start_order(0);game.model.tick(Brush.PLATFORM_RISE_TIME+.01);game.view.sync()
  game.view.tool.hide();game.view.foreground.hide()
  for obj in game.model.objects:
   var sprite: Sprite2D = game.view.object_sprites[obj.id].sprite
   check(sprite.z_index == (1 if obj.rule == "edge" else 2), "runtime contour under body " + str(obj.id) + "/" + str(size))
   if obj.rule == "edge":
    check(sprite.position.is_equal_approx(obj.rect.get_center()) and is_equal_approx(sprite.rotation,obj.draw_angle), "runtime matches authored transform " + obj.authored_path)
  var correct: Image = await screenshot(vp, "runtime_under_body_" + str(size) + ".png")
  for obj in game.model.objects:
   if obj.rule == "edge":game.view.object_sprites[obj.id].sprite.z_index = 3
  var above: Image = await screenshot(vp, "layer_comparison_above_" + str(size) + ".png")
  var pixels = 0
  for y in range(0,1080,2):
   for x in range(0,1920,2):
    var difference: Color=correct.get_pixel(x,y)-above.get_pixel(x,y)
    if maxf(absf(difference.r),maxf(absf(difference.g),absf(difference.b))) > .015:pixels += 1
  check(pixels > 100, "real GPU overlap order is visibly different " + str(size))
  for obj in game.model.objects:
   if obj.rule == "edge":game.view.object_sprites[obj.id].sprite.z_index = 1
  var restored: Image = await screenshot(vp, "restored_layering_" + str(size) + ".png")
  check(correct.get_data() == restored.get_data(), "layering restores identical real pixels " + str(size))
  measurements.append({"scale":size,"gpu_layer_difference_probes":pixels})
  game.queue_free();vp.queue_free();await process_frame
