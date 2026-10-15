extends SceneTree
const Preview := preload("res://scripts/prototype_grooming/art_preview.gd")
const OUT := "res://reports/grooming_art_20261015/"
var preview: Control
var viewport: SubViewport
var failures: int = 0

func _initialize() -> void:
 root.size = Vector2i(1920,1080)
 call_deferred("run")

func capture(filename: String) -> void:
 preview.queue_redraw()
 for i in range(4): await process_frame
 await RenderingServer.frame_post_draw
 var image: Image = viewport.get_texture().get_image()
 if image.get_size() != Vector2i(1920,1080):
  failures += 1
  push_error("Unexpected capture size")
 var target: String = ProjectSettings.globalize_path(OUT+filename)
 if image.save_png(target) != OK:
  failures += 1
  push_error("Capture failed "+filename)

func run() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
 viewport = SubViewport.new()
 viewport.size = Vector2i(1920,1080)
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 preview = Preview.new()
 preview.size = Vector2(1920,1080)
 viewport.add_child(preview)
 await process_frame
 for name in preview.index.sprites:
  var resource_path: String = "res://Art/grooming_demo_v1/" + str(preview.index.sprites[name].atlas_resource)
  var resource = load(resource_path)
  if not resource is AtlasTexture:
   failures += 1
   push_error("Missing atlas " + str(name))
 preview.toolbar.hide()
 preview.background_only = true
 await capture("background_1920x1080.png")
 preview.background_only = false
 for kind in ["calico", "robot", "nails"]:
  preview.select_view(kind)
  for state in ["dirty", "half", "clean", "happy", "discomfort"]:
   preview.select_state(state)
   await capture(kind+"_"+state+".png")
 print("GROOMING_ART_CAPTURE failures="+str(failures)+" images=16 resources="+str(preview.index.sprites.size()))
 quit(1 if failures else 0)
