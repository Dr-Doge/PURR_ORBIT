extends SceneTree
const C=preload("res://scripts/prototype_harvest/config.gd")
var game
var checks: int=0
var failures: Array=[]
var samples: Array=[]
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures.append(why);push_error(why)
func _initialize() -> void:call_deferred("run")
func motion(at: Vector2,held: bool=false) -> void:
 var e:=InputEventMouseMotion.new();e.position=at;e.button_mask=MOUSE_BUTTON_MASK_LEFT if held else 0;root.push_input(e,true)
func mouse(at: Vector2,key: int=MOUSE_BUTTON_LEFT,down: bool=true) -> void:
 var e:=InputEventMouseButton.new();e.position=at;e.button_index=key;e.pressed=down;root.push_input(e,true)
 if down and key in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
  var release: InputEventMouseButton=e.duplicate();release.pressed=false;root.push_input(release,true)
func click(at: Vector2) -> void:motion(at);mouse(at);mouse(at,MOUSE_BUTTON_LEFT,false)
func advance(seconds: float) -> void:
 for i in int(ceil(seconds/0.02)):game._process(0.02)
func draw_wait() -> void:
 game.view.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
func capture(name: String) -> void:
 await draw_wait()
 root.get_texture().get_image().save_png("res://reports/prototype_20261009/"+name+".png")
func press(key: String) -> void:
 var b: Control=game.buttons[key]
 if game.content.is_ancestor_of(b):game.get_node("Sidebar/Scroll").ensure_control_visible(b)
 elif b.get_parent()==game.menu_items:game.get_node("MeetingMenu/Scroll").ensure_control_visible(b)
 await process_frame;await process_frame
 click(b.get_global_rect().get_center());await process_frame
func load_by_menu(index: int) -> void:
 if not game.drawer.visible:click(game.get_node("MenuButton").get_global_rect().get_center())
 await process_frame
 check(game.drawer.visible and game.model.paused,"Menu pauses model")
 await press("stage_"+str(index))
 check(game.model.stage==index and not game.drawer.visible,"Mouse stage selection %d"%index)
 game.focus_lost=false;game.sync_pause();await draw_wait()
func hair_point(c: Dictionary,kind: String="normal") -> Vector2:
 for h in c.hairs.values():
  if h.kind==kind and not game.model.locked(c,h.id):return game.view.to_screen(c.id,h.pos)
 return Vector2(-999,-999)
func run() -> void:
 root.size=Vector2i(1440,810)
 game=load("res://scenes/测试场景.tscn").instantiate();game.testing=true;root.add_child(game)
 await process_frame;await process_frame
 game.set_process(false);game.focus_lost=false;game.sync_pause()
 check(game.get_node("Room/WhiteboxViewport/World3D/WhiteboxRoom/Camera") is Camera3D,"Copied 3D shell exists")
 check(not "save_game" in game and not "lab_model" in game,"Prototype controller independent")
 await load_by_menu(0)
 var c: Dictionary=game.model.cats[0]
 var wallet: int=game.model.wallet
 click(hair_point(c));check(game.model.wallet>wallet,"S01 real mouse click pays")
 var ids: Array=c.hairs.keys();var elapsed: float=game.model.time
 motion(Vector2(800,220));mouse(Vector2(800,220),MOUSE_BUTTON_WHEEL_DOWN)
 check(game.transition_left>0 and game.model.paused,"Wheel starts continuous transition and pause")
 var transition: float=game.transition_left;mouse(Vector2(800,220),MOUSE_BUTTON_WHEEL_DOWN)
 check(game.transition_left==transition,"Wheel reentry ignored")
 advance(0.3);check(game.view.close_amount>0.1 and game.view.close_amount<0.9,"Continuous intermediate scale")
 await capture("transition_mid")
 advance(0.3);check(game.model.time==elapsed and c.hairs.keys()==ids,"Transition no income, growth or identity reset")
 advance(0.3)
 var cabin_at: Vector2=game.view.cabin_center(1)
 motion(cabin_at);mouse(cabin_at,MOUSE_BUTTON_WHEEL_UP);advance(0.62)
 check(game.view.close_amount==1.0 and game.view.selected==1,"Return to same cat")
 await capture("S01_1440")
 await load_by_menu(1)
 await press("touch");await press("chain")
 check(game.model.level("touch")==1 and game.model.level("chain")==1 and game.model.wallet==0,"S02 both real tool purchases")
 c=game.model.cats[0];wallet=game.model.wallet
 motion(game.view.to_screen(1,Vector2(-0.4,0)));motion(game.view.to_screen(1,Vector2(0.4,0)))
 check(game.model.wallet>wallet,"S02 real motion harvest and chain")
 await capture("S02_1440")
 await load_by_menu(2);c=game.model.cats[0]
 var king_point: Vector2=hair_point(c,"king");wallet=game.model.wallet
 for i in 5:click(king_point)
 check(game.model.wallet==wallet,"S03 first five king clicks no payout")
 click(king_point);check(game.model.wallet>wallet,"S03 sixth king click burst")
 game.view.step(0.02);await capture("S03_1440")
 await load_by_menu(3)
 await press("buy_buff");await press("buff_assign");await press("buy_decor")
 check(game.model.buff_owned and game.model.decor and game.model.buff_target==1 and game.model.wallet==0,"S04 actual purchases and assignment")
 var normal_before: int=game.model.cats[0].hairs.size();var fast_before: int=game.model.cats[1].hairs.size()
 advance(4)
 check(game.model.cats[0].hairs.size()>normal_before and game.model.cats[1].hairs.size()-fast_before>game.model.cats[0].hairs.size()-normal_before,"S04 independent real growth")
 motion(game.view.cabin_center(1));await capture("S04_1440")
 await load_by_menu(4);await press("recruit")
 await press("assign_1_1")
 check(game.model.workers[0].cat==1,"S05 real button assigns cat")
 click(game.get_node("Sidebar/TreeButton").get_global_rect().get_center());await process_frame
 await press("worker_rate")
 check(game.model.level("worker_rate")==1,"S05 worker efficiency bought")
 wallet=game.model.wallet;advance(2);check(game.model.wallet>wallet,"S05 worker actual production")
 await capture("S05_1440")
 motion(Vector2(800,200));mouse(Vector2(800,200),MOUSE_BUTTON_WHEEL_DOWN);advance(0.9)
 motion(game.view.cabin_center(2));mouse(game.view.cabin_center(2),MOUSE_BUTTON_WHEEL_UP);advance(0.62)
 wallet=game.model.wallet;advance(2)
 check(game.view.selected==2 and game.model.wallet>wallet,"S05 other cat view keeps worker income")
 await load_by_menu(5);c=game.model.cats[0]
 await capture("S06_active_1440")
 var knot_at: Vector2=c.knot.pos
 var start: Vector2=game.view.to_screen(1,knot_at-Vector2(0.045,0))
 motion(start);mouse(start)
 for i in 14:motion(game.view.to_screen(1,knot_at+Vector2(0.045 if i%2==0 else -0.045,0)),true)
 mouse(start,MOUSE_BUTTON_LEFT,false)
 check(c.knot.is_empty(),"S06 real held reversals untie knot")
 game.view.step(0.02);await capture("S06_1440")
 await load_by_menu(6);c=game.model.cats[0]
 await capture("S07_active_1440")
 var flea_before: Dictionary=c.flea.duplicate(true)
 click(game.get_node("MenuButton").get_global_rect().get_center());await process_frame
 advance(2)
 check(c.flea==flea_before,"Active flea movement, stealing and deadline pause together")
 await press("resume")
 var esc:=InputEventKey.new();esc.keycode=KEY_ESCAPE;esc.pressed=true;root.push_input(esc,true)
 advance(2);check(c.flea==flea_before and game.manual_pause,"Esc preserves same active event")
 root.push_input(esc,true);check(not game.manual_pause,"Esc resumes event clock")
 advance(1.05);wallet=game.model.wallet
 click(hair_point(c));check(game.model.wallet==wallet,"S07 ordinary hair click blocked")
 for i in 6:click(game.view.to_screen(1,c.flea.pos) if not c.flea.is_empty() else Vector2.ZERO)
 check(c.flea.is_empty() and game.model.wallet>wallet,"S07 real flea clicks return loot")
 game.view.step(0.02);await capture("S07_success_1440")
 await load_by_menu(6);wallet=game.model.wallet;advance(12)
 check(game.model.cats[0].flea.is_empty() and game.model.wallet==wallet,"S07 retry then fail only loses stolen hairs")
 await capture("S07_escape_1440")
 await load_by_menu(7)
 await press("assign_2_3")
 check(game.model.workers[1].cat==3,"S08 assign special using button")
 advance(1.1);check(game.model.cats[2].lost>0,"S08 actual local automation penalty")
 await capture("S08_1440")
 await press("unassign_2")
 var special_lost: int=game.model.cats[2].lost
 advance(2);check(game.model.cats[2].lost==special_lost,"S08 real withdrawal stops local loss")
 motion(game.view.cabin_center(3));mouse(game.view.cabin_center(3),MOUSE_BUTTON_WHEEL_UP);advance(0.62)
 wallet=game.model.wallet;click(hair_point(game.model.cats[2]));game.view.step(0)
 check(game.view.selected==3 and game.model.wallet>wallet,"S08 special manual harvest after withdrawal")
 await capture("S08_manual_1440")
 # A blocking overlay must consume wheel and click without harvesting or zooming.
 click(game.get_node("MenuButton").get_global_rect().get_center());await process_frame
 elapsed=game.model.time;wallet=game.model.wallet
 mouse(game.drawer.get_global_rect().get_center(),MOUSE_BUTTON_WHEEL_UP);advance(1)
 check(game.model.time==elapsed and game.model.wallet==wallet and game.transition_left==0,"Menu blocks simulation and wheel")
 await capture("menu_1440")
 for i in 8:
  await load_by_menu(i)
  await press_menu_retry()
  check(game.model.time==0 and game.model.wallet==C.STAGES[i].wallet,"Retry fresh preset %d"%i)
 # Second window size and all stages, including reading and scrolling the menu.
 root.size=Vector2i(960,540);await process_frame;await process_frame
 for i in 8:
  await load_by_menu(i)
  check(game.get_node("Sidebar").get_global_rect().end.x<=game.size.x+1,"Sidebar within small viewport")
  await capture("S%02d_960"%[i+1])
 # Real-input continuous run: no preset jumps, no resource grants, exact model production.
 await load_by_menu(0);var naturally_bought: Array=[]
 var continuous_seconds: int=0
 for i in 240:
  continuous_seconds=i+1
  advance(1)
  c=game.model.cats[0]
  if not c.flea.is_empty():
   for hit in 6:click(game.view.to_screen(1,c.flea.pos) if not c.flea.is_empty() else Vector2.ZERO)
  if not c.knot.is_empty():
   var knot_center: Vector2=c.knot.pos
   var brush_start: Vector2=game.view.to_screen(1,knot_center-Vector2(0.045,0))
   motion(brush_start);mouse(brush_start)
   for brush in 14:motion(game.view.to_screen(1,knot_center+Vector2(0.045 if brush%2==0 else -0.045,0)),true)
   mouse(brush_start,MOUSE_BUTTON_LEFT,false)
  for h in c.hairs.values():
   if h.kind=="king":
    var king_at: Vector2=game.view.to_screen(1,h.pos)
    for hit in 6:click(king_at)
    break
  for action in 4:
   var target: Vector2=hair_point(c)
   if target.x>=0:click(target)
  game.refresh_ui()
  for n in C.NODES:
   var key: String=n.key
   if game.model.reason(key)=="":
    await press(key)
    if game.model.level(key)>0 and not naturally_bought.has(key):naturally_bought.append(key)
  if game.model.level("worker")>0 and game.model.workers.is_empty() and game.model.wallet>=C.WORKER_COST:
   click(game.get_node("Sidebar/TeamButton").get_global_rect().get_center());await process_frame
   await press("recruit");await press("assign_1_1")
   click(game.get_node("Sidebar/TreeButton").get_global_rect().get_center());await process_frame
  if game.model.level("buff")>0 and not game.model.buff_owned and game.model.wallet>=25:
   click(game.get_node("Sidebar/TeamButton").get_global_rect().get_center());await process_frame
   await press("buy_buff");await press("buff_assign");await press("buy_decor")
   click(game.get_node("Sidebar/TreeButton").get_global_rect().get_center());await process_frame
  var done: bool=game.model.cats.size()==3 and game.model.enabled.flea and game.model.buff_owned and not game.model.workers.is_empty()
  for n in C.NODES:done=done and game.model.level(n.key)==n.costs.size()
  if done:break
 check(naturally_bought.size()==C.NODES.size() and game.model.lifetime>=300 and game.model.cats.size()==3 and not game.model.workers.is_empty() and game.model.buff_owned,"Continuous mouse run earns all systems without menu gifts")
 await capture("continuous_960")
 # Render load samples keep all model hairs; sampling only reduces drawing.
 root.size=Vector2i(1440,810);await process_frame;await load_by_menu(1)
 c=game.model.cats[0]
 for target_count in [1000,10000,50000]:
  while c.hairs.size()<target_count:game.model.spawn(c,"normal")
  game.view.sample_revision=-1
  var begin: int=Time.get_ticks_usec()
  for frame in 60:
   game._process(1.0/60.0);await process_frame
  var ms: float=(Time.get_ticks_usec()-begin)/1000.0
  check(c.hairs.size()>=target_count and c.pending>=target_count*2,"Render density preserves all value and keeps growing")
  samples.append({"initial_hairs":target_count,"final_hairs":c.hairs.size(),"frames":60,"wall_ms":ms,"observed_frame_delivery_fps":60000.0/ms,"engine_fps":Engine.get_frames_per_second(),"display_hairs":game.view.samples[c.id].size()})
 await capture("density_50000")
 var out=FileAccess.open("res://reports/prototype_20261009/ui_results.json",FileAccess.WRITE)
 out.store_string(JSON.stringify({"checks":checks,"failures":failures,"render_performance":samples,"continuous_mouse_upgrades":naturally_bought,"continuous_simulated_seconds":continuous_seconds,"note":"Injected mouse inputs plus accelerated simulation, not a human playthrough"},"  "))
 game.queue_free();await process_frame
 print("PROTOTYPE UI: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
func press_menu_retry() -> void:
 click(game.get_node("MenuButton").get_global_rect().get_center());await process_frame
 await press("retry")

