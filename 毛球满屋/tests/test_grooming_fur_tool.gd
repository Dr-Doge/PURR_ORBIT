extends SceneTree
const Tool=preload("res://scripts/prototype_grooming_fur/tool_geometry.gd")
const Model=preload("res://scripts/prototype_grooming_fur/model.gd")
const OUT="res://reports/grooming_fur_service_20261016/"
var checks: int=0
var failures: Array=[]
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var origin:=Vector2(900,700)
 check(Tool.covered_length(origin,origin+Vector2(20,0),origin+Vector2(10,54))>0,"tooth-line tip can comb, even outside old circle")
 check(Tool.covered_length(origin,origin+Vector2(20,0),origin+Vector2(10,62))==0,"outside tooth ends cannot comb")
 check(Tool.covered_length(origin,origin+Vector2(0,20),origin+Vector2(20,10))==0,"handle-side pixels are outside narrow tooth band")
 check(Tool.covered_length(origin,origin,origin)==0,"stationary teeth do not clean")
 var center: Vector2=origin+Tool.center_offset(Vector2(585,398))
 var first: Vector2=center+Tool.project_texture_point(Tool.TOOTH_FIRST,Vector2(585,398))
 var last: Vector2=center+Tool.project_texture_point(Tool.TOOTH_LAST,Vector2(585,398))
 check(first.distance_to(Tool.edge_points(origin)[0])<.01 and last.distance_to(Tool.edge_points(origin)[1])<.01,"rendered tooth tips and hit line share exact endpoints")
 var handle: Vector2=center+Tool.project_texture_point(Vector2(510,75),Vector2(585,398))
 check(handle.y>last.y,"comb head up and handle down")
 var back: Vector2=center+Tool.project_texture_point(Vector2(290,180),Vector2(585,398))
 check(back.x<origin.x,"teeth face right, ahead of the comb back")
 for uv in [Vector2(.42,.42),Vector2(.58,.74),Vector2(.76,.70)]:
  var m=Model.new();m.tick(1)
  var target: Dictionary={};var best: float=INF
  for obj in m.objects:
   if obj.rule!="patch":continue
   var distance: float=((obj.rect.get_center()-m.body_rect.position)/m.body_rect.size-uv).length()
   if distance<best:best=distance;target=obj
  var p: Vector2=target.rect.get_center();var a:=Vector2(m.body_rect.position.x+m.body_rect.size.x*.28,p.y)
  m.begin_gesture(a);m.stroke(a,p+Vector2(30,0),a.distance_to(p+Vector2(30,0))/900.0)
  check(target.done and m.score==100,"upper/lower body cleans without penalty at 900 px/s "+str(uv))
 var m=Model.new();m.tick(1);var target: Dictionary=m.objects[0];var p: Vector2=target.rect.get_center()
 m.begin_gesture(p-Vector2(30,0));m.stroke(p-Vector2(30,0),p+Vector2(30,0),60.0/1200.0)
 check(target.done and m.score==100,"exactly 1200 px/s is allowed")
 m.start_order(0);m.tick(1);target=m.objects[0];p=target.rect.get_center()
 m.begin_gesture(p-Vector2(30,0));m.stroke(p-Vector2(30,0),p+Vector2(30,0),60.0/1500.0)
 check(not target.done and m.score==95,"above threshold with real tooth contact causes one penalty")
 var vp:=SubViewport.new();vp.size=Vector2i(1920,1080);vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(vp)
 var game=load("res://scenes/prototype_grooming/fur_demo.tscn").instantiate();vp.add_child(game);await create_timer(.6).timeout
 game.set_process(false)
 game.view.foreground.hide();game.view.tool.hide();await process_frame;await RenderingServer.frame_post_draw
 var covered: Image=vp.get_texture().get_image()
 game.view.dirt.hide();await process_frame;await RenderingServer.frame_post_draw
 var clean: Image=vp.get_texture().get_image()
 var error: float=0.0;var maximum: float=0.0;var count: int=0
 for obj in game.model.objects:
  if obj.rule!="patch":continue
  var source: Image=game.model.assets.image(obj.type)
  for y in range(3,30,3):
   for x in range(3,30,3):
    if obj.left[y*32+x]<.9:continue
    var uv:=Vector2((x+.5)/32.0,(y+.5)/32.0)
    if source.get_pixel(int(uv.x*source.get_width()),int(uv.y*source.get_height())).a<.90:continue
    var at: Vector2=obj.rect.position+obj.rect.size*uv
    var special: bool=false
    for other in game.model.objects:
     if other.rule!="patch" and other.rect.grow(12).has_point(at):special=true
    if special:continue
    var a: Color=covered.get_pixel(int(at.x),int(at.y));var b: Color=clean.get_pixel(int(at.x),int(at.y))
    if b.r<.35:continue
    var delta: float=maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))
    error+=delta;maximum=maxf(maximum,delta);count+=1
 var average: float=error/maxi(1,count)
 check(count>200,"colour comparison samples many actual visible fur pixels")
 check(average>.035 and average<.16,"fur follows underlying pigment but has readable moderate contrast")
 game.view.dirt.show();game.view.foreground.show();game.view.tool.show();game.set_process(true)
 game.speed_history.clear()
 for i in range(15):check(absf(game.measure_speed(15.0,1.0/60.0)-900.0)<1,"stable 900 px/s independent of OS event intervals "+str(i))
 for fps in [60,144,240]:
  game.speed_history.clear()
  for i in range(40):game.measure_speed(900.0/fps,1.0/fps)
  check(absf(game.grooming_speed-900)<1,"same measured speed at "+str(fps)+" fps")
 # Dense events are gathered without judging microsecond gaps.
 game.speed_history.clear();game.pending_paths.clear();game.model.start_order(0);game.model.tick(1)
 target=game.model.objects[0];p=target.rect.get_center();var begin:=p-Vector2(15,0)
 game.model.begin_gesture(begin)
 for i in range(30):game.pending_paths.append({"a":begin+Vector2(i*.5,0),"b":begin+Vector2((i+1)*.5,0),"distance":.5})
 game.flush_grooming(1.0/60.0)
 check(game.model.score==100 and absf(game.grooming_speed-900)<1,"thirty dense events in one frame do not fake extreme speed")
 game.model.reaction=.28;game.view.sync();game.speed_history.clear();game.pending_paths=[{"a":begin,"b":begin+Vector2(15,0),"distance":15.0}]
 game.flush_grooming(1.0/60.0)
 check(absf(game.grooming_speed-900)<1,"reaction movement is excluded from speed calculation")
 DirAccess.make_dir_recursive_absolute(OUT)
 FileAccess.open(OUT+"tool.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"colour_samples":count,"average_colour_error":average,"maximum_colour_error":maximum,"speed_limit":Tool.SPEED_LIMIT,"edge_length":Tool.EDGE_LENGTH,"edge_half_width":Tool.EDGE_HALF_WIDTH}," "))
 print("FUR TOOL: ",checks," checks; ",failures.size()," failures")
 game.queue_free();vp.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
