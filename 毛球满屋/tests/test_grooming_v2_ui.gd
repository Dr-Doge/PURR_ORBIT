extends SceneTree
const C=preload("res://scripts/prototype_grooming/config.gd")
const OUT="res://reports/grooming_v2_20261015/"
var vp: SubViewport
var game: Control
var checks: int=0
var failures: Array=[]
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func input_at(p: Vector2,press: int=0,held: bool=true) -> void:
 if press!=0:
  var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=press==1;e.position=p;e.global_position=p;vp.push_input(e,true)
 else:
  var e:=InputEventMouseMotion.new();e.position=p;e.global_position=p;e.button_mask=MOUSE_BUTTON_MASK_LEFT if held else 0;vp.push_input(e,true)
func snapshot(name: String) -> void:
 await process_frame;await RenderingServer.frame_post_draw
 vp.get_texture().get_image().save_png(OUT+name+".png")
func swipe(a: Vector2,b: Vector2,speed: float) -> void:
 input_at(a,0,false);input_at(a,1);await process_frame
 game.previous_tick=Time.get_ticks_usec()-int(a.distance_to(b)/game.model.body_rect.size.x/speed*1000000)
 input_at(b);input_at(b,2);await process_frame
func _initialize() -> void:call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 vp=SubViewport.new();vp.size=Vector2i(1920,1080);vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(vp)
 game=load("res://scenes/prototype_grooming/main.tscn").instantiate();vp.add_child(game);await create_timer(0.55).timeout
 var obj: Dictionary=game.model.objects[0];var p: Vector2=obj.rect.get_center();var before: float=obj.sum
 # Short gestures are actual GUI input; model check covers complete continuous rows.
 await swipe(p+Vector2(40,0),p-Vector2(40,0),0.3)
 check(obj.sum==before,"GUI calico reverse rejected")
 await swipe(p-Vector2(45,0),p+Vector2(45,0),0.3)
 check(obj.sum<before,"GUI calico gentle forward works")
 await snapshot("calico_direction")
 game.jump_order(1);await create_timer(0.55).timeout
 obj=game.model.objects[1];p=obj.rect.get_center();before=obj.sum
 await swipe(p-Vector2(80,0),p+Vector2(80,0),3.0)
 check(obj.sum<before and obj.sum>0 and game.model.score==100,"GUI robot rapid wipe partially cleans without pain")
 await snapshot("robot_rapid")
 game.jump_order(0,true);await process_frame
 check(game.view.claw_root.get_index()<game.view.base.get_index(),"claws render beneath paw, above table")
 await snapshot("nails_aligned")
 for n in game.model.nails:
  var at: Vector2=n.root-Vector2(0,game.model.quick_height-12)
  var img: Image=vp.get_texture().get_image()
  var pink: int=0
  for yy in range(int(at.y)-20,int(at.y)+21):
   for xx in range(int(at.x)-45,int(at.x)+46):
    var color: Color=img.get_pixel(xx,yy)
    if color.r>0.85 and color.g>0.30 and color.g<0.78 and color.b>0.35 and color.r>color.g+0.14:pink+=1
  check(pink>12,"visible pink quick for toe "+str(n.id))
 var n: Dictionary=game.model.nails[0];var edges: Vector2=game.model.nail_edges(n,game.model.perfect_height());var yy: float=n.root.y-game.model.perfect_height()
 await swipe(Vector2(edges.x-15,yy),Vector2(edges.y+15,yy),1.0)
 check(n.done and n.result=="perfect","GUI trim follows new nail anchor")
 await snapshot("nail_trimmed")
 FileAccess.open(OUT+"ui.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"resolution":[1920,1080]}," "))
 print("GROOMING V2 GUI: ",checks," checks; ",failures.size()," failures")
 game.queue_free();vp.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
