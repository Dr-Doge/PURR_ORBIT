extends SceneTree
const M=preload("res://scripts/prototype_grooming_fur/model.gd")
const Comfort=preload("res://scripts/prototype_grooming_fur/comfort.gd")
const OUT="res://reports/grooming_fur_feedback_20261016/"
var checks: int=0
var failures: Array=[]
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func make(scale: float=1.0) -> RefCounted:
 var m=M.new();m.next_cat_scale=scale;m.start_order(0);m.tick(1);return m
func find(m: RefCounted,rule: String) -> Dictionary:
 for obj in m.objects:
  if obj.rule==rule and not obj.done:return obj
 return {}
func source_point(m: RefCounted,obj: Dictionary) -> Vector2:
 var p: Vector2=obj.rect.get_center();var best: float=INF
 for y in range(32):
  for x in range(32):
   if obj.left[y*32+x]<=0:continue
   var at: Vector2=m.sample_point(obj,x,y)
   if at.distance_squared_to(obj.rect.get_center())<best:best=at.distance_squared_to(obj.rect.get_center());p=at
 return p
func _initialize() -> void:call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 var c=Comfort.new()
 check(not c.strain(.10,1,0) and c.load==0,"first brief spike consumes grace without discomfort")
 check(not c.strain(.10,1,.1) and c.load==0,"grace lasts actual contact time across separate events")
 c.strain(.10,1,.2);check(c.load>0 and c.load<Comfort.WARNING,"load builds gradually after grace")
 c.strain(.40,1,.6);check(c.load>=Comfort.WARNING and c.load<1,"warning appears before pain")
 c.strain(.30,1,.9);check(c.load>=Comfort.ALERT and c.load<1,"strong warning still allows stopping")
 check(c.strain(.30,1,1.2),"sustained strain eventually reaches pain")
 check(not c.strain(1.0,1,1.3),"pain protection blocks rapid repeated deductions")
 c.recover(.5,2);check(c.load<1,"stopping begins automatic recovery")
 c.recover(2,4);check(c.load==0 and c.grace_left==Comfort.GRACE,"rest restores tolerance")
 var sparse=Comfort.new();var dense=Comfort.new();sparse.strain(.40,1.1,0)
 for i in range(20):dense.strain(.02,1.1,0)
 check(absf(sparse.load-dense.load)<.0001,"exposure is independent of event count")
 var m=make();var obj: Dictionary=find(m,"patch");var p: Vector2=source_point(m,obj)
 var r: Dictionary=m.stroke(p-Vector2(30,0),p+Vector2(30,0),.04)
 check(obj.done and not r.pain and m.score==100,"ordinary 1500px/s sweep harvests without pain")
 m=make();obj=find(m,"patch");p=source_point(m,obj)
 m.stroke(p+Vector2(25,0),p-Vector2(25,0),.2,250)
 check(not obj.done and m.score==100,"gentle wrong direction is ineffective, not painful")
 m=make();obj=find(m,"knot");p=source_point(m,obj)
 for i in range(12):m.stroke(p-Vector2(150,0),p+Vector2(150,0),.2,1500);m.tick(.05)
 check(m.comfort.load==0 and m.score==100,"passing through knot during broad strokes cannot build local pulling strain")
 m=make();obj=find(m,"knot");p=source_point(m,obj)
 r=m.stroke(p-Vector2(10,0),p+Vector2(10,0),.015,1300)
 check(not obj.done and not r.pain and m.score==100,"brief fast knot contact stalls without penalty")
 var warning: bool=false;var pain_count: int=0
 for i in range(40):
  r=m.stroke(p-Vector2(10,0),p+Vector2(10,0),.05,1300)
  warning=warning or m.comfort.load>=Comfort.WARNING
  pain_count+=int(r.pain);m.tick(.05)
 check(warning and pain_count==1 and m.score==97,"continued force warns before one mild deduction")
 check(not obj.done,"forcing a knot cannot replace correct slow combing")
 m.tick(3);check(m.comfort.load==0,"rest on model cools load completely")
 r=m.stroke(p-Vector2(25,0),p+Vector2(25,0),.2,250)
 check(obj.done and not r.pain,"safe slow treatment releases knot")
 m=make();m.stroke(Vector2(20,700),Vector2(150,700),.025,5000)
 check(m.score==100 and m.comfort.load==0,"fast movement outside uncleared objects is harmless")
 m.comfort.strain(.7,1,m.now);m.paused=true;var before: float=m.comfort.load;m.tick(1)
 check(m.comfort.load==before,"pause freezes recovery and strain")
 m.paused=false;m.start_order(1);check(m.comfort.load==0,"switching cat resets cat-specific load")
 var single=make();var crowded=make();var knot: Dictionary=find(crowded,"knot")
 crowded.objects.append(knot.duplicate(true));p=source_point(single,find(single,"knot"))
 for i in range(15):
  single.stroke(p-Vector2(10,0),p+Vector2(10,0),.05,1300);single.tick(.05)
  crowded.stroke(p-Vector2(10,0),p+Vector2(10,0),.05,1300);crowded.tick(.05)
 check(absf(single.comfort.load-crowded.comfort.load)<.0001,"overlapping targets do not multiply strain")
 var layouts: Array=[]
 for scale in [1.0,.5]:
  m=make(scale);var variants: Dictionary={};var edge_types: Dictionary={};var overlapping: int=0;var patches: Array=[]
  for item in m.objects:
   if item.rule=="patch":variants[item.type.split("_")[1]]=true;patches.append(item)
   elif item.rule=="edge":edge_types[item.type]=true
  for item in patches:
   var overlap: bool=false
   for other in patches:
    if other.id==item.id:continue
    if item.rect.get_center().distance_to(other.rect.get_center())<75:overlap=true;break
   overlapping+=int(overlap)
  check(variants.size()>=3,"multiple source hairlock shapes on cat "+str(scale))
  check(edge_types.size()>=6,"multiple complete contour source assets on cat "+str(scale))
  check(overlapping>patches.size()*.60,"neighbouring patches overlap instead of isolated grid cells "+str(scale))
  layouts.append({"scale":scale,"patches":patches.size(),"variants":variants.keys(),"edge_types":edge_types.keys(),"overlapping":overlapping})
 var vp:=SubViewport.new();vp.size=Vector2i(1920,1080);vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(vp)
 var game=load("res://scenes/prototype_grooming/fur_demo.tscn").instantiate();vp.add_child(game);await create_timer(.6).timeout;game.set_process(false)
 game.view.tool.hide();game.view.foreground.hide()
 await process_frame;await RenderingServer.frame_post_draw;var covered: Image=vp.get_texture().get_image();covered.save_png(OUT+"14_base_contour_concealed.png")
 var mask: Image=game.model.build_edge_cover();game.view.dirt.hide()
 await process_frame;await RenderingServer.frame_post_draw;var original: Image=vp.get_texture().get_image();original.save_png(OUT+"15_original_contour.png")
 var raw: Image=game.model.assets.image("calico_clean");var tested: int=0;var hidden: int=0
 for y in range(2,raw.get_height()-2,4):
  for x in range(2,raw.get_width()-2,4):
   var color: Color=raw.get_pixel(x,y);var uv:=Vector2(float(x)/raw.get_width(),float(y)/raw.get_height())
   if color.a<.9 or maxf(color.r,maxf(color.g,color.b))>.30 or mask.get_pixel(int(uv.x*512),int(uv.y*256)).r<.95:continue
   var boundary: bool=false
   var world: Vector2=game.model.body_rect.position+uv*game.model.body_rect.size
   var actual_lock: bool=false
   for item in game.model.objects:
    if item.rule!="edge":continue
    var lock_uv: Vector2=((world-item.rect.get_center()).rotated(-item.draw_angle)/item.rect.size)+Vector2(.5,.5)
    if lock_uv.x<0 or lock_uv.x>=1 or lock_uv.y<0 or lock_uv.y>=1:continue
    var sprite_source: Image=game.model.assets.image(item.type)
    if sprite_source.get_pixel(int(lock_uv.x*sprite_source.get_width()),int(lock_uv.y*sprite_source.get_height())).a>.9:actual_lock=true
   if not actual_lock:continue
   for offset in [Vector2i(20,0),Vector2i(-20,0),Vector2i(0,20),Vector2i(0,-20)]:
    var at: Vector2i=Vector2i(x,y)+offset
    if at.x>=0 and at.y>=0 and at.x<raw.get_width() and at.y<raw.get_height() and raw.get_pixelv(at).a<.05:boundary=true
   if not boundary:continue
   var at: Vector2=game.model.body_rect.position+uv*game.model.body_rect.size
   if at.y<105:continue
   tested+=1
   var a: Color=covered.get_pixel(int(at.x),int(at.y));var b: Color=original.get_pixel(int(at.x),int(at.y))
   if a.r-b.r>.12:hidden+=1
 check(tested>100 and hidden>tested*.80,"active messy locks conceal most covered original black contour pixels")
 for item in game.model.objects:
  if item.rule=="edge":game.model.clear_object(item)
 game.view.sync();game.view.dirt.hide();game.view.tool.hide();game.view.foreground.hide()
 for item in game.view.particles:item.sprite.hide()
 await process_frame;await RenderingServer.frame_post_draw;var restored: Image=vp.get_texture().get_image();restored.save_png(OUT+"16_contour_restored.png")
 var changed: int=0
 for y in range(130,970,8):
  for x in range(200,1720,8):
   if restored.get_pixel(x,y)!=original.get_pixel(x,y):changed+=1
 check(changed==0,"original base contour restores exactly when all outline locks are removed")
 # Render the warning, pain and recovery states; scripted model state, not a human play recording.
 game.jump_order(0);game.model.tick(1);game.set_process(false)
 knot=find(game.model,"knot");p=source_point(game.model,knot);game.view.mouse=p;game.dragging=true
 for i in range(30):
  game.model.stroke(p-Vector2(10,0),p+Vector2(10,0),.05,1300);game.model.tick(.05)
  if game.model.comfort.load>.55:break
 check(game.model.comfort.load>=Comfort.WARNING and game.model.score==100,"visible amber warning precedes any penalty")
 game.view.sync();game.update_ui();await process_frame;await RenderingServer.frame_post_draw;vp.get_texture().get_image().save_png(OUT+"17_strain_warning.png")
 for i in range(30):
  game.model.stroke(p-Vector2(10,0),p+Vector2(10,0),.05,1300);game.model.tick(.05)
  if game.model.score<100:break
 check(game.model.score==97 and game.model.reaction>0,"pain occurs only after continued warned force")
 game.view.sync();game.update_ui();await process_frame;await RenderingServer.frame_post_draw;vp.get_texture().get_image().save_png(OUT+"18_pain_after_warning.png")
 game.model.tick(2.5);game.dragging=false;game.view.sync();game.update_ui()
 check(game.model.comfort.load==0 and game.model.reaction==0,"rest clears visual strain and reaction")
 await process_frame;await RenderingServer.frame_post_draw;vp.get_texture().get_image().save_png(OUT+"19_recovered.png")
 FileAccess.open(OUT+"feedback.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"layouts":layouts,"contour_tested":tested,"contour_concealed":hidden,"restored_changed_pixels":changed}," "))
 print("FUR FEEDBACK: ",checks," checks; ",failures.size()," failures")
 game.queue_free();vp.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
