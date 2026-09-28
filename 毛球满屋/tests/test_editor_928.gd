extends SceneTree
const Main=preload("res://scenes/main.tscn")
const A=preload("res://scripts/cat_animation_data.gd")
var checks=0
var failures=0
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(why)
func frames() -> void:
 for i in range(4):await process_frame
func capture(name: String) -> void:
 await frames();await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png("res://reports/merge_cat1new_928/"+name+".png")==OK,"Screenshot "+name)
func _initialize() -> void:root.size=Vector2i(1440,810);call_deferred("run")
func run() -> void:
 var scene=Main.instantiate()
 for path in ["Room/Backdrop","Room/Cats/StarterCat1/Animation","Room/Cats/StarterCat2/Animation","Room/Facilities","Room/Workers","Room/HarvestEffects/GachaMachine","HUD/Status/Content/Header","HUD/Actions/Content/Buttons/Tree","Overlay/Center/Card/Body/StartMenu/NewGame"]:
  check(scene.has_node(path),"Authored node before ready: "+path)
 # Preview the saved visual graph without running the main/room gameplay scripts.
 scene.set_script(null);scene.get_node("Room").set_script(null)
 var cursor=scene.get_node("Cursor");scene.remove_child(cursor);cursor.free()
 root.add_child(scene);await capture("01_authored_main")
 scene.queue_free();await frames()
 var library=load("res://scenes/art_library.tscn").instantiate();root.add_child(library)
 await capture("02_art_library");library.queue_free();await frames()
 var game=Main.instantiate();game.testing=true;root.add_child(game);game.set_process(false);await frames();game.start_game();game.room.step(0)
 check(game.get_node("Room/Cats").get_child_count()==game.model.cats.size(),"No duplicated preview cats in runtime")
 var m=game.model
 for i in range(3):game.start_game();game.room.step(0)
 check(game.get_child_count()==4 and game.room.get_node("Cats").get_child_count()==2,"Repeated new game keeps exactly one UI/room and two cats")
 m=game.model;m.cats.clear()
 for kind in ["short","giant","static","lucky"]:
  var c=m.add_cat(Vector2(350+m.cats.size()*220,500));c.kind=kind;c.variant=3
 game.room.step(0)
 for c in m.cats:
  var sprite: AnimatedSprite2D=game.room.cat_nodes[c.id].get_node("Animation")
  check(sprite.sprite_frames==(preload("res://Art/cat1new_animations.tres") if c.kind=="short" else A.frames_for(c.kind)),"Original animation set: "+c.kind)
  check(sprite.modulate==Color.WHITE,"No color overlay: "+c.kind)
  for anim in ["idle","walk","produce"]:
   check(sprite.sprite_frames.has_animation(anim) and sprite.sprite_frames.get_frame_count(anim)>1,"Complete animation "+c.kind+"/"+anim)
  c.reaction_kind=c.kind;c.reaction_left=A.reaction_duration(c.kind);game.room.step(0)
  check(sprite.animation=="produce" and sprite.sprite_frames==(preload("res://Art/cat1new_animations.tres") if c.kind=="short" else A.frames_for(c.kind)),"Produce keeps its own original asset "+c.kind)
 await capture("03_runtime_original_cats")
 var changed: Dictionary=m.cats[0];changed.kind="giant";changed.reaction_left=0;game.room.step(0)
 check(game.room.cat_nodes[changed.id].scene_file_path=="res://scenes/cats/giant_cat.tscn","Transformation replaces the live instance with the matching species scene")
 var old_count=m.cats.size();var saved=m.snapshot();check(m.restore(saved),"Existing snapshot remains readable");game.room.step(0)
 check(game.room.cat_nodes.size()==old_count,"Restore reconciles one visual per cat")
 game.show_start();check(game.body.get_child(0).scene_file_path=="res://scenes/ui/start_menu.tscn","Runtime menu uses authored scene")
 print("EDITOR 928: ",checks," checks, ",failures," failures")
 game.queue_free();await frames();quit(0 if failures==0 else 1)
