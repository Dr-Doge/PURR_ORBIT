extends SceneTree
const M=preload("res://scripts/prototype_grooming_fur/model.gd")
const Tool=preload("res://scripts/prototype_grooming_fur/tool_geometry.gd")
const OUT="res://reports/grooming_fur_activation_20261016/"
var checks: int=0
var failures: Array=[]
var layouts: Array=[]
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func make(scale: float=1.0) -> RefCounted:
 var m=M.new();m.next_cat_scale=scale;m.start_order(0);m.tick(1);return m
func source_point(m: RefCounted,obj: Dictionary) -> Vector2:
 var best: float=INF;var at: Vector2=obj.rect.get_center()
 for y in range(32):
  for x in range(32):
   if obj.left[y*32+x]<=0:continue
   var p: Vector2=m.sample_point(obj,x,y)
   if p.distance_squared_to(obj.rect.get_center())<best:best=p.distance_squared_to(obj.rect.get_center());at=p
 return at
func swipe(m: RefCounted,a: Vector2,b: Vector2) -> void:
 m.begin_gesture(a);m.stroke(a,b,a.distance_to(b)/350.0)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 for scale in [1.0,.5]:
  var m=make(scale);var edges: int=0;var max_out: float=0
  for original in m.objects.duplicate():
   if original.rule not in ["patch","edge"]:continue
   var obj: Dictionary=original.duplicate(true)
   m.objects=[obj];m.stage="cleaning";m.settled=false
   var p: Vector2=source_point(m,obj)
   swipe(m,p+Vector2(16,0),p-Vector2(16,0))
   check(not obj.done,"reverse is ineffective "+str(scale)+"/"+str(obj.id))
   swipe(m,p+Vector2(0,16),p-Vector2(0,16))
   check(not obj.done,"vertical cannot bypass rightward direction "+str(scale)+"/"+str(obj.id))
   swipe(m,p-Vector2(16,0),p+Vector2(16,0))
   check(obj.done and obj.sum==0 and m.score==100,"one local rightward stroke clears full patch "+str(scale)+"/"+str(obj.id))
   if obj.rule!="edge":continue
   edges+=1
   var out: Vector2=obj.outline_outward.rotated(obj.draw_angle)
   check(out.dot(obj.outline_normal)>.999,"source ink points outward "+str(scale)+"/"+str(obj.id))
   var anchor: Vector2=obj.rect.get_center()+(obj.outline_anchor*obj.rect.size).rotated(obj.draw_angle)
   check(anchor.distance_to(obj.outline_boundary+obj.outline_normal*M.OUTLINE_INK_OFFSET*scale)<.01,"ink anchor hugs actual boundary "+str(scale)+"/"+str(obj.id))
   check(obj.outline_overlap>=.65,"contour patch covers actual cat rather than bridging empty gaps "+str(scale)+"/"+str(obj.id))
   var boundary_uv: Vector2=(obj.outline_boundary-m.body_rect.position)/m.body_rect.size
   var boundary_source: Image=m.assets.image("calico_clean")
   var px: Vector2i=Vector2i(boundary_uv*Vector2(boundary_source.get_size()))
   var neighbour_outside: bool=false
   for dy in range(-2,3):
    for dx in range(-2,3):
     var sample:=px+Vector2i(dx,dy)
     if sample.x<0 or sample.y<0 or sample.x>=boundary_source.get_width() or sample.y>=boundary_source.get_height() or boundary_source.get_pixelv(sample).a<.2:neighbour_outside=true
   check(neighbour_outside,"anchor uses real alpha silhouette rather than a truncated search window "+str(scale)+"/"+str(obj.id))
   var raw: Image=m.assets.image(obj.type);var inner: int=0;var visible: int=0;var exterior: float=0
   for y in range(32):
    for x in range(32):
     var c: Color=raw.get_pixel(int((x+.5)/32*raw.get_width()),int((y+.5)/32*raw.get_height()))
     if c.a<.6:continue
     visible+=1
     var at: Vector2=m.sample_point(obj,x,y)
     inner+=int((at-obj.outline_boundary).dot(obj.outline_normal)<0)
     exterior=maxf(exterior,(at-obj.outline_boundary).dot(obj.outline_normal))
   check(inner>visible*.5,"most contour patch is inside rather than floating outside "+str(scale)+"/"+str(obj.id))
   max_out=maxf(max_out,exterior)
  layouts.append({"scale":scale,"edges":edges,"max_outward_pixels":max_out})
  check(edges==23,"all contour anchors retained "+str(scale))
  # Complete a normal order using rightward strokes plus existing specials.
  m=make(scale)
  for obj in m.objects:
   if obj.done:continue
   var p: Vector2=source_point(m,obj)
   if obj.rule in ["patch","edge","knot"]:swipe(m,p-Vector2(25,0),p+Vector2(25,0))
   elif obj.rule=="dust":
    p=obj.rect.get_center();swipe(m,p-Vector2(0,80),p+Vector2(0,80));swipe(m,p+Vector2(0,80),p-Vector2(0,80))
   elif obj.rule=="flea":
    for i in range(3):m.click_at(obj.rect.get_center())
  check(m.settled and m.wallet==100,"all torso tail and outlines are reachable "+str(scale))
 # Robot regressions only: no robot production edits in this task.
 var robot=M.new();robot.start_order(1);robot.tick(1)
 check(robot.objects.size()==14,"robot fixed existing layout remains unchanged")
 var obj: Dictionary=robot.objects[1];var p: Vector2=obj.rect.get_center();var before: float=obj.sum
 robot.begin_gesture(p);robot.stroke(p-Vector2(80,0),p+Vector2(80,0),.02)
 check(obj.sum<before and obj.sum>0 and robot.score==100,"robot fast repeated wiping preserved")
 before=obj.sum;robot.stroke(p+Vector2(80,0),p-Vector2(80,0),.02)
 check(obj.sum<before and robot.score==100,"robot reverse wiping preserved")
 for dimensions in [Vector2i(1920,1080),Vector2i(1440,810)]:
  var vp:=SubViewport.new();vp.size=dimensions;vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(vp)
  var game=load("res://scenes/prototype_grooming/fur_demo.tscn").instantiate();vp.add_child(game);await create_timer(.6).timeout
  var idle_rotation: float=game.view.tool.rotation
  var background:=Vector2(100,600)*Vector2(dimensions)/Vector2(1920,1080)
  await mouse(vp,background,false,true)
  check(game.dragging and game.model.comb_armed,"background press activates comb "+str(dimensions))
  check(game.model.cleaning_progress()==0.0,"press without movement does not clear fur "+str(dimensions))
  check(absf(game.view.tool.rotation+Tool.rotation_angle())<.001,"held comb has vertical working pose "+str(dimensions))
  check(absf(idle_rotation-game.view.tool.rotation-Tool.IDLE_TILT)<.001,"idle lifted tilt differs clearly from held pose "+str(dimensions))
  var target: Dictionary={}
  for item in game.model.objects:
   if item.rule=="patch":target=item;break
  p=source_point(game.model,target)
  # Move in from background without re-pressing; use timed input, not model calls.
  var start: Vector2=p-Vector2(28,0)
  await motion(vp,background,start*Vector2(dimensions)/Vector2(1920,1080))
  if not target.done:
   for step in range(8):
    var a: Vector2=(start+Vector2(step*7,0))*Vector2(dimensions)/Vector2(1920,1080)
    var b: Vector2=(start+Vector2((step+1)*7,0))*Vector2(dimensions)/Vector2(1920,1080)
    await motion(vp,a,b)
  check(target.done and game.dragging,"press outside then sweep into fur is actionable "+str(dimensions))
  await mouse(vp,p*Vector2(dimensions)/Vector2(1920,1080),false,false)
  check(not game.dragging and absf(game.view.tool.rotation+Tool.rotation_angle()-Tool.IDLE_TILT)<.001,"release lifts comb "+str(dimensions))
  await screenshot(vp,"idle_"+str(dimensions.x)+".png")
  game.jump_order(0);await create_timer(.6).timeout
  await mouse(vp,background,false,true)
  await screenshot(vp,"active_"+str(dimensions.x)+".png")
  game._notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_OUT);await process_frame
  check(not game.dragging,"focus loss deactivates comb "+str(dimensions))
  await mouse(vp,background,false,true);game.toggle_pause();await process_frame
  check(not game.dragging and not game.view.tool.visible,"pause clears held pose "+str(dimensions))
  game.toggle_pause();await mouse(vp,background,false,true);game.jump_order(1);await create_timer(.6).timeout
  check(not game.dragging and game.model.kind=="robot" and game.view.tool.rotation==0,"switch leaves robot cloth pose intact "+str(dimensions))
  var button: Vector2=Vector2(95,75)*Vector2(dimensions)/Vector2(1920,1080)
  await mouse(vp,button,false,true);await mouse(vp,button,false,false)
  check(not game.dragging,"top UI button does not activate or penetrate to comb "+str(dimensions))
  game.queue_free();vp.queue_free();await process_frame
 FileAccess.open(OUT+"activation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"layouts":layouts}," "))
 print("FUR ACTIVATION: ",checks," checks; ",failures.size()," failures")
 quit(0 if failures.is_empty() else 1)
func mouse(vp: SubViewport,at: Vector2,_unused: bool,pressed: bool) -> void:
 var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=at;e.pressed=pressed;vp.push_input(e,true)
 await process_frame;await process_frame
func motion(vp: SubViewport,a: Vector2,b: Vector2) -> void:
 var e:=InputEventMouseMotion.new();e.position=b;e.relative=b-a;e.button_mask=MOUSE_BUTTON_MASK_LEFT;vp.push_input(e,true)
 await create_timer(.025).timeout
func screenshot(vp: SubViewport,name: String) -> void:
 await process_frame;await RenderingServer.frame_post_draw;vp.get_texture().get_image().save_png(OUT+name)
