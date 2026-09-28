extends SceneTree
const Main=preload("res://scenes/3D scene.tscn")
var checks=0
var failures=0
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(why)
func frames() -> void:
 for i in range(4):await process_frame
func _initialize() -> void:
 root.size=Vector2i(1440,810);call_deferred("run")
func run() -> void:
 check(ProjectSettings.get_setting("application/run/main_scene")=="res://scenes/3D scene.tscn","Project launches merged scene")
 var scene=Main.instantiate()
 for path in ["Room/WhiteboxViewport/World3D/WhiteboxRoom/Floor","Room/WhiteboxViewport/World3D/WhiteboxRoom/MainLamp","Room/WhiteboxViewport/World3D/WhiteboxRoom/Camera","Room/WhiteboxViewport/World3D/WhiteboxRoom/ActorLighting/Cat_1","Room/WhiteboxViewport/World3D/WhiteboxRoom/ActorLighting/Cat_2","HUD/Status/Header","HUD/Drawer/Content/Tree","Overlay/Center/Card/Body/StartMenu/NewGame"]:
  check(scene.has_node(path),"Authored before scripts: "+path)
 scene.set_script(null);scene.get_node("Room").set_script(null)
 var cursor=scene.get_node("Cursor");scene.remove_child(cursor);cursor.free()
 root.add_child(scene);await frames();await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://reports/merge_3d_928/05_authored_scene.png")
 scene.queue_free();await frames()
 var library=load("res://scenes/art_library.tscn").instantiate();root.add_child(library)
 await frames();await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://reports/merge_3d_928/06_art_library.png")
 library.queue_free();await frames()
 var game=Main.instantiate();game.testing=true;root.add_child(game);game.set_process(false);await frames()
 for i in range(3):
  game.start_game();game.room.step(0);await frames()
  check(game.room.actor_lighting.sprites.size()==2,"Repeated new game reuses two live cards")
  check(game.room.shell.get_child_count()==9,"No duplicated inherited room geometry or lamps")
  check(not game.room.get_node("Cats").visible,"Legacy previews do not double render")
 var m=game.model;m.cats.clear()
 var prefixes=["Cat1","Cat5","Cat8","Cat10","Cat14"]
 var index=0
 for kind in ["short","giant","static","lucky","alien"]:
  var c=m.add_cat(Vector2(350+index*160,500));c.kind=kind;c.variant=3;index+=1
 game.room.step(0);await frames();index=0
 for c in m.cats:
  var sprite=game.room.actor_lighting.sprites["Cat_%d"%c.id]
  check((sprite.texture is AtlasTexture and sprite.texture.atlas.resource_path.begins_with("res://Art/cat1new1/")) if c.kind=="short" else sprite.texture.resource_path.contains(prefixes[index]),"Independent original art: "+c.kind)
  check(sprite.modulate==Color.WHITE and sprite.material_override.albedo_color==Color.WHITE,"No tint on original art: "+c.kind)
  c.reaction_kind=c.kind;c.reaction_left=game.room.cat_visuals.A.reaction_duration(c.kind);game.room.step(0)
  check((sprite.texture is AtlasTexture and sprite.texture.atlas.resource_path.ends_with("侧面 · 产毛.png")) if c.kind=="short" else sprite.texture.resource_path.to_lower().contains(prefixes[index].to_lower()+"produce"),"Original produce art: "+c.kind)
  index+=1
 var snap=m.snapshot();check(m.restore(snap),"Existing save schema loads after scene merge");game.room.step(0);await frames()
 check(game.room.actor_lighting.sprites.size()==5,"Restore reconciles five visual cards")
 game.queue_free();await frames()
 print("MERGED STRUCTURE: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
