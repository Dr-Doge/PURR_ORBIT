extends SceneTree
const Main=preload("res://scenes/main.tscn")
const M=preload("res://scripts/model.gd")
var game
var checks: int=0
var failures: int=0
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func motion(at: Vector2) -> void:
 var e:=InputEventMouseMotion.new();e.position=at;root.push_input(e,true)
func click(at: Vector2,down: bool) -> void:
 var e:=InputEventMouseButton.new();e.position=at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e,true)
func advance(seconds: float) -> void:
 for i in range(roundi(seconds/0.05)):game._process(0.05)
func walking(c: Dictionary,at: Vector2) -> void:
 game.model.reset_activity(c);c.pos=at;c.dest=at+Vector2(100,0);c.walk_left=6;c.fed=0;c.layers=1;c.growth=0
func _initialize() -> void:call_deferred("run")
func run() -> void:
 root.size=Vector2i(1440,900);game=Main.instantiate();game.testing=true;root.add_child(game);game.set_process(false);game.start_game();await process_frame
 var m=game.model;var room=game.room
 var c: Dictionary=m.cats[0];var other: Dictionary=m.cats[1]
 for dimensions in [Vector2i(1440,900),Vector2i(1280,800)]:
  root.size=dimensions;await process_frame;await process_frame
  walking(c,Vector2(550,470));walking(other,Vector2(900,600));room.step(0)
  motion(room.screen_position(c.pos));room.refresh_hover();advance(0.05);room.step(0)
  var at: Vector2=c.pos;var dest: Vector2=c.dest;var walk: float=c.walk_left;var other_at: Vector2=other.pos
  check(m.hovered(c) and room.cat_visuals.states[c.id].animation=="idle","Effective hit selects idle on first stationary simulation step at "+str(dimensions))
  advance(0.5)
  check(c.pos==at and c.dest==dest and c.walk_left==walk,"Hover freezes actual position and preserves route/timer")
  check(other.pos!=other_at and c.growth>0,"Other cats and hovered cat growth continue")
  check(m.harvests==0 and c.pet==0,"Stationary hover has no harvesting progress")
  motion(room.screen_position(Vector2(200,700)));advance(0.1)
  check(not m.hovered(c) and c.pos.x>at.x and c.dest==dest and c.walk_left<walk,"Pointer departure resumes original walk")
  # No further mouse movement: move a cat into a stationary pointer's hit area.
  var target:=Vector2(650,470);motion(room.screen_position(target));room.refresh_hover()
  c.pos=target;room.refresh_hover();advance(0.1)
  check(m.hovered(c) and c.pos==target,"Stationary cursor catches a cat entering the hit region")
  c.pos=Vector2(900,700);room.refresh_hover()
  check(not m.hovered(c),"State-driven departure clears hover without mouse motion")
 motion(Vector2(-20,-20));advance(0.1)
 check(m.hovered_cat_id==-1,"Pointer outside viewport does not re-acquire a stale hit")
 walking(c,Vector2(600,500));c.idle_left=0.8;c.walk_left=0;room.step(0)
 motion(room.screen_position(c.pos));room.refresh_hover();advance(0.4)
 check(c.idle_left==0.8 and c.walk_left==0,"Idle pause timer is retained while hovering")
 motion(room.screen_position(Vector2(200,700)));advance(0.1)
 check(c.idle_left<0.8 and c.idle_left>0,"Release resumes remaining idle interval")
 # Overlap uses front-to-back display order, not nearest center or stale input.
 walking(c,Vector2(600,500));walking(other,Vector2(600,510));room.step(0)
 motion(room.screen_position(other.pos));room.refresh_hover();advance(0.1)
 check(m.hovered(other) and not m.hovered(c),"Only frontmost overlapping cat is held")
 var p: Vector2=other.pos
 click(room.screen_position(p),true)
 check(other.dragging and not m.hovered(other),"Drag uses same displayed hit and overrides hover")
 motion(room.screen_position(Vector2(850,650)));click(room.screen_position(Vector2(850,650)),false)
 motion(room.screen_position(Vector2(200,700)));advance(0.1)
 check(not other.dragging and not m.hovered(other),"Drop/departure never leaves a hover lock")
 walking(c,Vector2(600,500));room.step(0);motion(room.screen_position(c.pos));room.refresh_hover()
 var dest: Vector2=c.dest;var left: float=c.walk_left
 game.show_shop();advance(0.2)
 check(m.hovered_cat_id==-1 and c.pos.x>600 and c.dest==dest and c.walk_left<left,"Opening live UI releases hover and resumes activity")
 game.close_modal();await process_frame
 motion(room.screen_position(c.pos));room.refresh_hover();room.get_window().focus_exited.emit();advance(0.1)
 check(m.hovered_cat_id==-1,"Focus loss releases temporary input")
 room.get_window().focus_entered.emit();room.refresh_hover();check(m.hovered(c),"Focus return can re-evaluate stationary pointer")
 room.mouse_exited.emit();check(m.hovered_cat_id==-1,"Leaving room clears immediately")
 # UI moves under an unchanged pointer; GUI ownership must invalidate the hold.
 motion(room.screen_position(c.pos));room.refresh_hover()
 var cover:=ColorRect.new();cover.position=room.screen_position(c.pos)-Vector2(60,60);cover.size=Vector2(120,120);game.add_child(cover)
 await process_frame;await process_frame;room.refresh_hover()
 check(m.hovered_cat_id==-1,"UI obstruction without mouse motion clears hover")
 cover.queue_free();await process_frame;room.refresh_hover()
 check(m.hovered(c),"Removing UI re-evaluates unchanged pointer")
 # Preserve production clocks and produce priority while autonomous actions are held.
 walking(c,Vector2(600,500));c.fed=5;c.growth=9.9;room.step(0)
 motion(room.screen_position(c.pos));room.refresh_hover();advance(0.2)
 check(c.layers==2 and c.fed<5 and m.hovered(c),"Fur growth and food buff count during hover")
 c.layers=1;var count: int=m.harvests
 for i in range(10):motion(room.screen_position(c.pos+Vector2(-18 if i%2 else 18,0)))
 room.step(0)
 check(m.harvests==count+1 and room.cat_visuals.states[c.id].animation=="produce","Rubbing stopped cat harvests; produce overrides idle")
 for i in range(10):motion(room.screen_position(c.pos+Vector2(-18 if i%2 else 18,0)))
 check(m.harvests==count+1 and c.pet==0,"Hover cannot bypass reaction CD or store a gesture")
 advance(1.2);room.step(0)
 check(m.hovered(c) and room.cat_visuals.states[c.id].animation=="idle" and c.pet==0,"Reaction ends in idle while still hovered")
 var snap: Dictionary=m.snapshot();check(not snap.has("hovered_cat_id"),"Hover is absent from saved state")
 check(m.restore(snap) and m.hovered_cat_id==-1,"Restore clears input reference")
 room.reset_pointer();check(m.hovered_cat_id==-1,"Pointer reset clears restored session")
 # Feeding targets/activity clocks resume; no extra random route or grain spending while held.
 c=m.cats[0];m.wallet=50000;m.research("worker");m.research("feeder");m.buy("feeder",Vector2(1000,500));m.refill(m.facilities[0].id)
 walking(c,Vector2(600,500));m.tick(0.1);var feed_id: int=c.feed_target;dest=c.dest;m.set_hovered_cat(c.id);p=c.pos
 m.tick(0.5)
 check(c.pos==p and c.feed_target==feed_id and c.dest==dest,"Hover preserves feeding destination")
 m.set_hovered_cat(-1);m.tick(0.1);check(c.pos!=p and c.feed_target==feed_id,"Feeding walk resumes after release")
 c.pos=m.feeding_spot(m.facilities[0]);c.eat_time=0.4;m.set_hovered_cat(c.id)
 var grain: int=m.facilities[0].grain;m.tick(0.3)
 check(c.eat_time==0.4 and m.facilities[0].grain==grain,"Hovered feeding activity retains partial meal without spending grain")
 m.buy("worker",Vector2(300,700));m.workers[0].cooldown=1.0;m.tick(0.1)
 check(m.workers[0].cooldown<1.0,"Worker cooldown continues while cat is hovered")
 m.set_hovered_cat(c.id);m.research("sun");m.buy("sun",Vector2(800,500));m.assign(c.id,m.facilities.back().id);m.tick(0.1)
 check(not m.hovered(c) and c.timer>0,"Facility occupancy retains control and processing")
 m.move_cat(c.id,Vector2(600,500));m.set_hovered_cat(c.id);c.station=-99;p=c.pos;m.tick(0.1)
 check(not m.hovered(c) and c.station==-99 and c.pos==p,"Carried cat cannot be captured by hover")
 c.station=-1;c.dragging=false;m.set_hovered_cat(-1)
 walking(c,Vector2(600,500));room.step(0);motion(room.screen_position(c.pos));room.refresh_hover();game.refresh()
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/idle_009"))
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://reports/idle_009/20_hover_idle.png"))
 game.queue_free();await process_frame
 print("HOVER 008: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
