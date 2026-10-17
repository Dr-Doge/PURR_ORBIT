extends SceneTree
const ROOT = "res://Art/grooming_fur_v1/"
const OUT = "res://reports/fur_asset_cleanup_20261017/"
const ShaderSource = preload("res://scripts/prototype_grooming_fur/coat_cleaning.gdshader")
var checks = 0
var failures: Array = []
var metrics: Array = []

func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:failures.append(message);push_error(message)

func _initialize() -> void:call_deferred("run")

func one_connected_core(image: Image, expected: int) -> bool:
 var w = image.get_width();var h = image.get_height()
 var active = PackedByteArray();active.resize(w*h)
 var seed: int = -1;var count = 0
 for y in range(h):
  for x in range(w):
   var opaque: bool = image.get_pixel(x,y).a > 32.0/255.0
   active[y*w+x] = int(opaque)
   if opaque:seed = y*w+x;count += 1
 if count != expected or seed < 0:return false
 var stack: Array[int] = [seed];active[seed] = 0;var visited = 0
 while not stack.is_empty():
  var p: int = stack.pop_back();visited += 1
  var px: int = p%w;var py: int = p/w
  for dy in range(-1,2):
   for dx in range(-1,2):
    var x: int = px+dx;var y: int = py+dy
    if x<0 or x>=w or y<0 or y>=h:continue
    var i = y*w+x
    if active[i]:active[i] = 0;stack.append(i)
 return visited == count

func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "isolated_patches.json"))
 var sheets = {}
 for name in manifest.source_sha256:
  check(FileAccess.get_sha256(ROOT + name) == manifest.source_sha256[name], "source PNG untouched " + name)
  var image: Image = load(ROOT + name).get_image()
  if image.is_compressed():image.decompress()
  sheets[name] = image
 var assets = load("res://scripts/prototype_grooming_fur/assets.gd").new()
 check(manifest.sprites.size() == 20, "all 12 body and 8 contour assets fixed")
 for key in manifest.sprites:
  var e: Dictionary = manifest.sprites[key]
  var atlas: AtlasTexture = load(ROOT + e.resource)
  var cut: Image = atlas.get_image()
  var r: Array = e.original_region
  var old: Image = sheets[e.original_file].get_region(Rect2i(r[0],r[1],r[2],r[3]))
  check(cut.get_size() == old.get_size(), "original canvas and placement scale retained " + key)
  check(atlas.region.position == Vector2.ZERO and atlas.region.size == Vector2(old.get_size()), "atlas only addresses its isolated canvas " + key)
  check(one_connected_core(cut,e.core_pixels), "exactly one continuous primary silhouette, no neighbouring chunks " + key)
  var retained_ok = true;var clear_ok = true;var old_count = 0;var cut_count = 0
  for y in range(cut.get_height()):
   for x in range(cut.get_width()):
    var source: Color = old.get_pixel(x,y);var pixel: Color = cut.get_pixel(x,y)
    old_count += int(source.a > 32.0/255.0);cut_count += int(pixel.a > 32.0/255.0)
    if pixel.a > 0 and pixel != source:retained_ok = false
    if pixel.a == 0 and pixel != Color(0,0,0,0):clear_ok = false
  check(retained_ok, "kept fur RGBA unchanged, including antialias alpha " + key)
  check(clear_ok, "removed fragments fully transparent with no colour halo " + key)
  check(old_count-cut_count == e.removed_visible, "removed fragment count matches actual cut " + key)
  check(assets.image(key).get_data() == cut.get_data(), "runtime opacity/contact uses same clean asset as editor " + key)
  metrics.append({"asset":key,"opaque_removed":e.removed_visible,"canvas":e.canvas})
 if DisplayServer.get_name() != "headless":
  await compare_materials()
  await render_scene()
 FileAccess.open(OUT + "cleanup.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"assets":metrics},"  "))
 print("FUR ASSET CLEANUP: ",checks," checks; ",failures.size()," failures")
 quit(0 if failures.is_empty() else 1)

func shot(vp: SubViewport, name: String) -> Image:
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 var pixels: Image = vp.get_texture().get_image();pixels.save_png(OUT+name);return pixels

func compare_materials() -> void:
 var vp = SubViewport.new();vp.size = Vector2i(320,220);vp.transparent_bg = true;vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 get_root().add_child(vp)
 var sprite = Sprite2D.new();sprite.texture = load(ROOT + "resources/edge_gray_back.tres")
 sprite.position = Vector2(160,110);sprite.scale = Vector2(.45,.45);vp.add_child(sprite)
 var material = ShaderMaterial.new();material.shader = ShaderSource;sprite.material = material
 var white: Texture2D = load(ROOT + "editor_placement/white.res")
 var coat: Texture2D = load(ROOT + "editor_placement/coat_reference.res")
 material.set_shader_parameter("remaining_mask",white);material.set_shader_parameter("body_mask",white)
 material.set_shader_parameter("coat_map",coat);material.set_shader_parameter("match_coat",true)
 material.set_shader_parameter("complete_sprite",true);material.set_shader_parameter("body_dimensions",Vector2(1497.4314,870))
 material.set_shader_parameter("region_in_body",Vector4(.5,.35,.16,.1))
 material.set_shader_parameter("source_dimensions",Vector2(sprite.texture.get_size()))
 material.set_shader_parameter("patch_dimensions",Vector2(sprite.texture.get_size())*.45)
 material.set_shader_parameter("preserve_outline",false)
 var body: Image = await shot(vp,"same_asset_body_material.png")
 material.set_shader_parameter("preserve_outline",true)
 var contour: Image = await shot(vp,"same_asset_contour_material.png")
 check(body.get_data() == contour.get_data(), "body/contour render identical RGB and alpha for the same asset")
 var visible = 0;var translucent = 0;var darkest = 1.0
 for y in range(contour.get_height()):
  for x in range(contour.get_width()):
   var p: Color = contour.get_pixel(x,y)
   if p.a > .01:visible += 1
   if p.a > .01 and p.a < .99:translucent += 1
   if p.a > .75:darkest = minf(darkest,maxf(p.r,maxf(p.g,p.b)))
 check(visible > 1000 and translucent > 100, "antialiased alpha survives isolation and unified shader")
 check(darkest > .25, "contour black ink no longer bypasses coat recolouring")
 metrics.append({"gpu_same_material":true,"visible_pixels":visible,"soft_alpha_pixels":translucent,"darkest_visible_channel":darkest})
 vp.queue_free();await process_frame

func render_scene() -> void:
 var Model = load("res://scripts/prototype_grooming_fur/model.gd")
 var Brush = load("res://scripts/prototype_grooming_fur/brush_config.gd")
 for size in [1.0,.5]:
  var vp = SubViewport.new();vp.size = Vector2i(1920,1080);vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
  get_root().add_child(vp)
  var game = load("res://scenes/prototype_grooming/fur_demo.tscn").instantiate();vp.add_child(game);await process_frame
  game.set_process(false);game.model.next_cat_scale = size;game.model.start_order(0);game.model.tick(Brush.PLATFORM_RISE_TIME+.01);game.view.sync()
  game.view.tool.hide();game.view.foreground.hide()
  check(game.model.objects.size() == (389 if size==1.0 else 128), "fixed assets cannot rearrange saved fur " + str(size))
  for obj in game.model.objects:
   check(game.view.object_sprites[obj.id].sprite.z_index == (1 if obj.rule=="edge" else 2), "contours remain below body " + str(obj.id)+"/"+str(size))
  await shot(vp,"clean_runtime_"+str(size)+".png")
  game.queue_free();vp.queue_free();await process_frame
