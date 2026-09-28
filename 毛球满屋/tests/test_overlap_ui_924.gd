extends SceneTree
const Main=preload("res://scenes/main.tscn")
var checks=0
var failures=0
var game
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(why)
func motion(at: Vector2) -> void:
 var e=InputEventMouseMotion.new();e.position=at;root.push_input(e,true)
func click(at: Vector2,down: bool) -> void:
 var e=InputEventMouseButton.new();e.position=at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e,true)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 root.size=Vector2i(1440,810);game=Main.instantiate();game.testing=true;root.add_child(game);game.set_process(false);game.start_game()
 for i in range(4):await process_frame
 var m=game.model;var room=game.room;var a=m.cats[0];var b=m.cats[1]
 m.move_cat(a.id,Vector2(480,460));m.move_cat(b.id,Vector2(760,460));room.step(0)
 a.idle_left=100;b.idle_left=100;a.fed=100;b.fed=100
 var source: Vector2=room.screen_position(a.pos);var target: Vector2=room.screen_position(b.pos)
 motion(source);click(source,true);motion(target)
 check(a.dragging and a.pos.distance_to(b.pos)<0.1,"Real mouse drag stays at overlapped cursor position")
 for i in range(60):game._process(0.05)
 check(a.pos.distance_to(b.pos)<0.1,"Holding overlapping cat does not displace it")
 click(target,false);a.idle_left=100;b.idle_left=100;a.fed=100;b.fed=100
 check(not a.dragging and a.pos.distance_to(b.pos)<0.1,"Mouse release keeps requested overlap position")
 motion(room.screen_position(Vector2(300,700)))
 for i in range(40):game._process(0.05)
 check(a.pos.distance_to(b.pos)<0.1,"Two second drop grace preserves overlap")
 game._process(0.05)
 check(a.pos.distance_to(b.pos)>0.1,"Automatic separation begins after grace")
 var before: Vector2=b.pos;game.show_pause()
 for i in range(80):game._process(0.05)
 check(b.pos==before,"Pause freezes escape motion")
 game.close_modal()
 for i in range(240):game._process(0.05)
 check(not m.Space.overlaps(a,b),"Actual game loop completes soft separation")
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://reports/editor_928/drag_release.png")
 print("OVERLAP UI: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
