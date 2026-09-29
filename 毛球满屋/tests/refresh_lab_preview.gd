extends SceneTree
# Explicit preview refresh for this lab only; never serializes the inherited room.
func _initialize() -> void:call_deferred("run")
func run() -> void:
 if not ("--textures" in OS.get_cmdline_user_args() or "--actors" in OS.get_cmdline_user_args()):
  print("Use --textures, import assets, then --actors to update only test_actors.tscn.");quit();return
 root.size=Vector2i(1440,810)
 var game=load("res://scenes/测试场景.tscn").instantiate();game.testing=true;root.add_child(game);game.set_process(false)
 for i in range(4):await process_frame
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://data/lab_previews"))
 var actors=Node3D.new();actors.name="ActorLighting";actors.set_script(preload("res://scripts/actor_lighting_3d.gd"))
 for key in game.room.actor_lighting.sprites:
  var source: Sprite3D=game.room.actor_lighting.sprites[key]
  var sprite: Sprite3D=source.duplicate()
  sprite.name=key
  sprite.material_override=source.material_override.duplicate(false)
  if source.texture is ViewportTexture:
   var path="res://data/lab_previews/"+key+".png"
   if "--textures" in OS.get_cmdline_user_args():source.texture.get_image().save_png(path)
   else:sprite.texture=load(path);sprite.material_override.albedo_texture=sprite.texture
  actors.add_child(sprite);sprite.owner=actors
 if "--actors" in OS.get_cmdline_user_args():
  var packed=PackedScene.new();packed.pack(actors)
  var err=ResourceSaver.save(packed,"res://scenes/test_actors.tscn")
  if err!=OK:push_error("Unable to save test actors");quit(1);return
 actors.free();game.queue_free();await process_frame;quit()
