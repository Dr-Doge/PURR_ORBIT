extends SceneTree
const M=preload("res://scripts/model.gd")
const A=preload("res://scripts/cat_animation_data.gd")
const V=preload("res://scripts/cat_visuals.gd")
const Main=preload("res://scenes/main.tscn")
var checks: int=0
var failures: int=0
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func rub(m,c: Dictionary) -> void:
 for i in range(20):m.pet(c.id,45)
func completed(m,c: Dictionary) -> Dictionary:
 var action: Dictionary=m.harvest_ticket(c);action.progress=m.harvest_time(c.layers);return action
func motion(game,c: Dictionary,i: int) -> void:
 var e:=InputEventMouseMotion.new();e.position=game.room.screen_position(c.pos+Vector2(-18 if i%2 else 18,0));root.push_input(e,true)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 for kind in ["short","giant","static","lucky"]:
  var m=M.new();m.cats.resize(1);var c: Dictionary=m.cats[0];c.kind=kind
  var v=V.new();v.step(m,0);rub(m,c);v.step(m,0)
  var duration: float=A.reaction_duration(kind)
  check(is_equal_approx(duration,1.1) and c.reaction_left==duration,"Actual produce resource sets cooldown: "+kind)
  check(v.states[c.id].animation=="produce" and v.states[c.id].age==0,"Model and visual start together: "+kind)
  var cash: float=m.wallet;var count: int=m.harvests
  rub(m,c);check(c.pet==0 and not m.harvest(c.id,completed(m,c)) and m.wallet==cash,"Manual/complete callback blocked during reaction: "+kind)
  v.states.clear();v.step(m,8)
  check(c.reaction_left==duration and v.states[c.id].age==0,"Visual rebuild or visual-only elapsed cannot clear cooldown: "+kind)
  m.tick(duration-0.01);v.step(m,0)
  check(m.reacting(c) and v.states[c.id].animation=="produce" and v.texture(c.id)==A.frames_for(kind).get_frame_texture("produce",A.frames_for(kind).get_frame_count("produce")-1),"Last frame and lock stay aligned: "+kind)
  rub(m,c);check(m.harvests==count and c.pet==0,"No queued gesture near cooldown end: "+kind)
  m.tick(0.011);v.step(m,0)
  check(not m.reacting(c) and v.states[c.id].animation!="produce" and m.harvests==count,"End unlocks without automatic payout: "+kind)
  m.pet(c.id,45);check(c.pet==45,"Fresh gesture required after reaction: "+kind)
 var m=M.new();var c: Dictionary=m.cats[0];var other: Dictionary=m.cats[1]
 m.pet(c.id,45);m.pet(c.id,45);m.pet(c.id,45);m.pet(c.id,29)
 check(c.pet==164 and m.harvests==0,"164 pixels cannot settle")
 m.pet(c.id,1);check(m.harvests==1 and m.reacting(c),"165 pixels settles and starts cooldown")
 rub(m,other);check(m.harvests==2 and m.reacting(other),"Other cats remain independently harvestable")
 c.growth=9.95;m.tick(0.1)
 check(c.layers==2 and c.pop>0 and m.reacting(c),"Natural growth and expansion continue during reaction")
 c.dragging=true;var left: float=c.reaction_left;m.tick(0.1)
 check(c.reaction_left<left and m.reacting(c),"Dragging counts normal elapsed time without clearing reaction")
 c.dragging=false;m.move_cat(c.id,Vector2(600,500));left=c.reaction_left
 check(m.reacting(c),"Dropping cat cannot clear reaction")
 var snap: Dictionary=m.snapshot();var loaded=M.new()
 check(loaded.restore(snap) and loaded.cats[0].reaction_left==left,"Save reload preserves reaction remaining")
 var restored_visuals=V.new();restored_visuals.step(loaded,0)
 check(restored_visuals.states[c.id].animation=="produce" and restored_visuals.states[c.id].age>0,"Reload resumes produce at saved time")
 var path: String="user://reaction_007_isolated.save"
 check(m.save_to(path)==OK and loaded.load_from(path) and loaded.cats[0].reaction_left==left,"Isolated disk save preserves cooldown")
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 var legacy: Dictionary=snap.duplicate(true)
 for cat in legacy.cats:cat.erase("reaction_left");cat.erase("reaction_kind")
 check(loaded.restore(legacy) and not loaded.reacting(loaded.cats[0]),"Legacy cats default to no reaction")
 for value in [-1.0,INF,NAN,"invalid"]:
  var bad: Dictionary=snap.duplicate(true);bad.cats[0].reaction_left=value
  check(not loaded.restore(bad),"Invalid saved reaction rejected")
 m=M.new();m.cats.resize(1);c=m.cats[0];m.wallet=1000;m.research("worker");m.buy("worker",c.pos)
 var w: Dictionary=m.workers[0];rub(m,c)
 check(m.choose_job(w,{}).is_empty(),"Worker cannot reserve a reacting cat")
 w.job={"kind":"harvest","target":c.id,"cat":c.id,"revision":m.c_revision(c),"action":completed(m,c)};w.clock=99
 m.tick_worker(w,0.1,{})
 check(w.job.is_empty() and w.clock==0 and m.harvests==1,"Existing worker job cannot bypass reaction")
 for i in range(12):m.tick(0.1)
 check(not w.job.is_empty() and m.harvests==1,"Worker starts fresh after cat cooldown ends")
 for i in range(25):
  m.tick(0.1)
  if m.harvests==2:break
 check(m.harvests==2 and w.cooldown>0 and m.reacting(c),"Worker output starts separate overlapping cat and worker cooldowns")
 m=M.new();c=m.cats[0];other=m.cats[1];c.kind="static";other.pos=c.pos+Vector2(10,0)
 rub(m,c);check(m.wallet==6 and m.reacting(c) and not m.reacting(other) and m.c_revision(other)==0,"Static bonus does not start neighbour produce or reaction")
 var v=V.new();v.step(m,0)
 check(v.states[other.id].animation!="produce","Static neighbour bonus preserves its existing presentation")
 # Real viewport input and paused main loop; no player save writes.
 root.size=Vector2i(1440,900)
 var game=Main.instantiate();game.testing=true;root.add_child(game);game.set_process(false);game.start_game();await process_frame
 c=game.model.cats[0]
 for i in range(12):motion(game,c,i)
 check(game.model.harvests==1 and game.model.reacting(c) and c.pet==0,"Real rapid mouse input cannot harvest twice during reaction")
 game.room.step(0);left=c.reaction_left
 game.show_pause()
 for i in range(20):game._process(0.1)
 check(c.reaction_left==left and game.room.cat_visuals.states[c.id].age==0,"Paused UI preserves both model and produce clock")
 game.close_modal();check(c.reaction_left==left,"Closing panel cannot clear cooldown")
 for i in range(20):motion(game,c,i)
 check(game.model.harvests==1 and c.pet==0,"Inputs after closing modal still respect cooldown")
 for i in range(12):game._process(0.1)
 check(not game.model.reacting(c) and c.pet==0 and game.model.harvests==1,"Unpause ends reaction without cached gesture")
 for i in range(12):motion(game,c,i)
 check(game.model.harvests==2,"New actual motion works after reaction")
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/editor_928"))
 game.room.step(0);await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://reports/editor_928/20_reaction.png"))
 game.queue_free();await process_frame
 print("REACTION 007: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
