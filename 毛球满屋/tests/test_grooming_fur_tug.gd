extends SceneTree
const M=preload("res://scripts/prototype_grooming_fur/model.gd")
const Brush=preload("res://scripts/prototype_grooming_fur/brush_config.gd")
var OUT: String=OS.get_environment("PURR_FUR_REPORT") if not OS.get_environment("PURR_FUR_REPORT").is_empty() else "res://reports/fur_asset_cleanup_20261017/"
var checks: int=0
var failures: Array=[]
var layouts: Array=[]
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func make(scale: float=1.0) -> RefCounted:
 var m=M.new();m.next_cat_scale=scale;m.start_order(0);m.tick(Brush.PLATFORM_RISE_TIME+.01);return m
func point(m: RefCounted,obj: Dictionary) -> Vector2:
 var best: float=INF;var at: Vector2=obj.rect.get_center()
 for y in range(32):
  for x in range(32):
   if obj.left[y*32+x]<=0:continue
   var p: Vector2=m.sample_point(obj,x,y)
   if p.distance_squared_to(obj.rect.get_center())<best:at=p;best=p.distance_squared_to(obj.rect.get_center())
 return at
func pass_once(m: RefCounted,p: Vector2) -> void:
 m.begin_gesture(p-Vector2(32,0));m.stroke(p-Vector2(32,0),p+Vector2(32,0),.1);m.end_brush()
func _initialize() -> void:call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 for scale in [1.0,.5]:
  var m=make(scale);var normal: int=0;var edge: int=0
  for item in m.objects:
   normal+=int(item.rule=="patch");edge+=int(item.rule=="edge")
  layouts.append({"scale":scale,"patches":normal,"edges":edge})
  check(normal>0 and edge>23,"expanded service regions and fitted outline retained "+str(scale))
  audit_regions(m,scale)
  check(m.kind=="calico" and not m.needs_nails,"only beginner cat, no nail stage "+str(scale))
  var template: Array=m.objects.duplicate(true)
  for original in template:
   check(original.rule in ["patch","edge"],"no knot dust flea or robot dirt "+str(scale)+"/"+str(original.id))
   var o: Dictionary=original.duplicate(true)
   m.objects=[o];m.stage="cleaning";m.settled=false
   var p: Vector2=point(m,o)
   m.stroke(p+Vector2(32,0),p-Vector2(32,0),.1)
   check(o.passes==0,"reverse does not count "+str(scale)+"/"+str(o.id))
   pass_once(m,p)
   check(o.passes==1 and not o.done and o.pull_amount>0,"first stroke pulls and retains whole patch "+str(scale)+"/"+str(o.id))
   m.tick(Brush.RETURN_TIME+.01)
   check(o.pull_amount==0 and not o.done and o.passes==1,"first recoil restores without detaching "+str(scale)+"/"+str(o.id))
   pass_once(m,p)
   check(o.passes==2 and o.detach_pending and not o.done,"second stroke schedules, never instantly detaches "+str(scale)+"/"+str(o.id))
   m.tick(Brush.RETURN_TIME*.5)
   check(o.pull_amount>0 and not o.done,"second patch still attached halfway through recoil "+str(scale)+"/"+str(o.id))
   m.tick(Brush.RETURN_TIME*.5+.001)
   check(o.done and o.pull_amount==0 and o.sum==0,"detach only at fully restored pose "+str(scale)+"/"+str(o.id))
  # Full service needs no special handling and cannot auto-return as a robot.
  m=make(scale)
  for o in m.objects:
   if o.done:continue
   var p: Vector2=point(m,o)
   for i in range(2):
    pass_once(m,p);m.tick(Brush.RETURN_TIME+.01)
  check(m.settled and m.served==1,"complete all hair with grooming alone "+str(scale))
  var version: int=m.version;var serial: int=m.serial
  m.tick(10)
  check(m.kind=="calico" and m.version==version+1 and m.serial==serial+1 and m.stage=="cleaning" and m.cleaning_progress()==0,"automatically prepared next cleanable coat, no robot "+str(scale))
  var wallet: int=m.wallet;m.settle();check(m.wallet==wallet,"completion cannot settle twice "+str(scale))
 var m=make();var o: Dictionary=m.objects[0];var p: Vector2=point(m,o)
 m.objects=[o];m.begin_gesture(p-Vector2(40,0))
 for i in range(20):m.stroke(p+Vector2(-40+i*4,0),p+Vector2(-36+i*4,0),.01)
 check(o.passes==1 and not o.detach_pending,"dense motion events in one stroke count once")
 m.tick(.5);m.stroke(p,p+Vector2(24,0),.1)
 check(o.passes==1,"waiting while held cannot fake another pass")
 m.end_brush();pass_once(m,p);m.tick(.1);var pull: float=o.pull_amount
 m.paused=true;m.tick(1)
 check(o.pull_amount==pull and not o.done,"pause freezes final recoil, not premature detachment")
 m.paused=false;m.tick(.3);check(o.done,"resume completes pending recoil")
 m=make();o=m.objects[0];m.objects=[o];p=point(m,o)
 for i in range(30):
  m.begin_gesture(p);m.stroke(p,p+Vector2(3,0),.01);m.end_brush()
 check(o.passes==0 and not o.done,"click spam and tiny resets cannot count full strokes")
 var sparse=make();var dense=make()
 for cat in [sparse,dense]:cat.objects=[cat.objects[0]]
 p=point(sparse,sparse.objects[0])
 sparse.begin_gesture(p-Vector2(40,0));sparse.stroke(p-Vector2(40,0),p+Vector2(40,0),.2)
 dense.begin_gesture(p-Vector2(40,0))
 for i in range(16):dense.stroke(p+Vector2(-40+i*5,0),p+Vector2(-35+i*5,0),.0125)
 check(sparse.objects[0].passes==dense.objects[0].passes,"event density does not change counted passes")
 var gaps=make();o=gaps.objects[0];gaps.objects=[o];p=point(gaps,o)
 gaps.begin_gesture(p-Vector2(90,0))
 for i in range(36):gaps.stroke(p+Vector2(-90+i*5,0),p+Vector2(-85+i*5,0),.01)
 check(o.passes==1,"transparent shape gaps and leaving target do not split one forward sweep")
 gaps.end_brush();pass_once(gaps,p)
 check(o.passes==2 and o.detach_pending,"release outside target properly rearms the next stroke")
 gaps.tick(.3);check(o.done,"second stroke after leaving still finishes at return")
 var fast=make();o=fast.objects[0];fast.objects=[o];p=point(fast,o)
 fast.begin_gesture(p-Vector2(32,0));var r: Dictionary=fast.stroke(p-Vector2(32,0),p+Vector2(32,0),.002,32000)
 check(not r.pain and fast.score==100 and o.passes==1,"beginner fast grooming has no punishment")
 for arguments in [[1,false],[2,true],[0,true]]:
  m.start_order(arguments[0],arguments[1]);check(m.kind=="calico" and not m.needs_nails and m.objects.all(func(item):return item.rule in ["patch","edge"]),"legacy order arguments cannot restore removed mechanics "+str(arguments))
 audit_cycle_and_profile()
 FileAccess.open(OUT+"model.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"layouts":layouts}," "))
 print("FUR TUG MODEL: ",checks," checks; ",failures.size()," failures")
 quit(0 if failures.is_empty() else 1)

func audit_cycle_and_profile() -> void:
 var seam=M.new();var epsilon: float=.0001
 var at_top: float=Brush.PLATFORM_RISE_FRACTION*Brush.PLATFORM_RISE_TIME
 seam.tick(at_top-epsilon)
 var before_platform: float=seam.platform_offset
 check(seam.cat_inertia==0 and before_platform>=0,"no cat recoil before platform reaches highest point")
 seam.tick(epsilon)
 check(absf(seam.platform_offset)<.001 and absf(seam.cat_inertia)<.001,"platform and inertia meet without positional jump")
 seam.tick(epsilon)
 check(seam.platform_offset==0 and seam.cat_inertia<0 and absf(seam.cat_inertia)<.001,"recoil starts immediately with no velocity kick or waiting gap")
 seam.tick(Brush.PLATFORM_RISE_TIME*.14)
 check(seam.platform_offset==0 and seam.cat_inertia<-8,"platform stays at highest point throughout cat recoil")
 var m=M.new();var serial: int=m.serial
 check(m.platform_offset>1080 and m.stage=="arrival","cat and platform begin below screen")
 var o: Dictionary=m.objects[0];var p: Vector2=point(m,o)
 pass_once(m,p);check(o.passes==0,"cannot groom during ascent")
 m.tick(Brush.PLATFORM_RISE_TIME*.5)
 check(m.platform_offset>0 and m.platform_offset<400,"platform rises smoothly toward service height")
 m.tick(Brush.PLATFORM_RISE_TIME*.36)
 check(m.cat_inertia<0 and absf(m.platform_offset)<6,"top arrival has restrained inertial settling")
 var left: float=m.stage_left;var offset: float=m.platform_offset;var inertia: float=m.cat_inertia
 m.paused=true;m.tick(3)
 check(m.stage_left==left and m.platform_offset==offset and m.cat_inertia==inertia,"pause freezes arrival and inertial pose")
 m.paused=false;m.tick(3)
 check(m.stage=="cleaning" and m.platform_offset==0 and m.cat_inertia==0 and m.serial==serial,"stop exactly at service height before accepting input")
 for round in range(3):
  for obj in m.objects:m.clear_object(obj)
  m.check_clean_finished();var wallet: int=m.wallet
  check(m.served==round+1 and m.stage=="reward","finish one customer once "+str(round))
  m.tick(Brush.SERVICE_HOLD*.5)
  check(m.stage=="reward" and m.platform_offset==0,"brief completion feedback before departure "+str(round))
  m.settle();check(m.wallet==wallet,"no repeated completion payment "+str(round))
  m.tick(Brush.SERVICE_HOLD*.5+Brush.PLATFORM_LOWER_TIME*.5)
  check(m.stage=="departure" and m.platform_offset>100 and m.serial==serial,"departing customer not replaced on screen "+str(round))
  offset=m.platform_offset;m.paused=true;m.tick(2);check(m.platform_offset==offset,"pause freezes lowering "+str(round));m.paused=false
  pass_once(m,p);check(m.stage=="departure","cannot groom during lowering "+str(round))
  m.tick(Brush.PLATFORM_LOWER_TIME+Brush.PLATFORM_RISE_TIME+1)
  serial+=1
  check(m.stage=="cleaning" and m.serial==serial and not m.settled and m.cleaning_progress()==0,"next customer resets only after offscreen departure "+str(round))
  check(m.wallet==wallet and m.served==round+1,"customer reset preserves accumulated completion count "+str(round))
 var profile: Resource=preload("res://Art/grooming_environment_v1/grooming_presentation.tres").duplicate()
 var old_texture: Texture2D=m.assets.texture("calico_clean")
 var fixture:=Image.create(300,200,false,Image.FORMAT_RGBA8);fixture.fill(Color(.7,.8,.6,1))
 profile.cat_texture=ImageTexture.create_from_image(fixture);profile.cat_fit_rect=Rect2(240,200,1200,720);profile.cat_name="移植样本"
 profile.outline_layout=null # New art requires its own hand-authored geometry.
 check(profile.validation_errors().is_empty() and m.configure_presentation(profile),"replaceable presentation accepts alternate cat dimensions")
 check(m.assets.image("calico_clean").get_size()==Vector2i(300,200) and m.assets.texture("calico_clean")!=old_texture,"replacement clears both CPU and GPU texture caches")
 check(is_equal_approx(m.body_rect.size.x/m.body_rect.size.y,1.5) and m.title.contains("移植样本"),"replacement respects aspect ratio and declared fit rectangle")
 profile=profile.duplicate();profile.cat_texture=null;serial=m.serial
 check(not m.configure_presentation(profile) and m.serial==serial,"invalid replacement cannot discard current customer")
 m.automatic_cycle=false;m.tick(Brush.PLATFORM_RISE_TIME+1)
 for obj in m.objects:m.clear_object(obj)
 m.check_clean_finished();m.tick(10)
 check(m.stage=="reward","host game can own next-customer scheduling without forced restart")
 profile=preload("res://Art/grooming_environment_v1/grooming_presentation.tres").duplicate()
 serial=m.serial;var current_texture: Texture2D=m.assets.texture("calico_clean")
 check(m.queue_customer(profile,.5) and m.serial==serial and m.assets.texture("calico_clean")==current_texture,"queued replacement cannot change visible customer")
 check(m.release_customer() and not m.release_customer(),"host releases completed customer exactly once")
 m.tick(Brush.PLATFORM_LOWER_TIME+Brush.PLATFORM_RISE_TIME+1)
 check(m.stage=="cleaning" and m.cat_scale==.5 and m.assets.presentation==profile and m.serial==serial+1,"host queued profile applies only after offscreen lowering")

func audit_regions(m: RefCounted,scale: float) -> void:
 var counts: Dictionary={"chest":0,"body":0,"tail":0}
 var edges: Dictionary={"chest":0,"body":0,"tail":0}
 var manual_foot_overlaps: Array=[]
 for obj in m.objects:
  counts[obj.region]+=1
  if obj.rule=="edge":
   edges[obj.region]+=1
   if obj.get("manual_outline",false):
    check(not obj.authored_path.is_empty(),"manual contour keeps authored identity "+str(scale)+"/"+str(obj.id))
   else:
    var along: Vector2=Vector2.RIGHT.rotated(obj.draw_angle)
    var normal: Vector2=m.contour_normal((obj.outline_boundary-m.body_rect.position)/m.body_rect.size,obj.outline_normal)
    var error: float=rad_to_deg(asin(clampf(absf(along.dot(normal)),0,1)))
    check(error<=15.0,"procedural contour follows local tangent within 15 degrees "+str(scale)+"/"+str(obj.id))
  var safe: bool=true
  for y in range(32):
   for x in range(32):
    if obj.left[y*32+x]<=0:continue
    var uv: Vector2=(m.sample_point(obj,x,y)-m.body_rect.position)/m.body_rect.size
    if m.paw_zone(uv) or m.paw_zone(uv+Vector2(Brush.MAX_PULL,0)/m.body_rect.size):safe=false
  if obj.get("manual_outline",false):
   if not safe:manual_foot_overlaps.append(obj.authored_path)
  else:check(safe,"procedural fur cannot cover feet even during pull "+str(scale)+"/"+str(obj.id))
 for region in counts:
  check(counts[region]>0 and edges[region]>0,"both body modules and rim present in "+region+str(scale))
 var coverage: Dictionary={"chest":[0,0],"body":[0,0],"tail":[0,0]}
 for y in range(56):
  for x in range(96):
   var uv:=Vector2((x+.5)/96,(y+.5)/56);var region: String=m.region_at(uv)
   if region.is_empty() or not m.body_hit(uv):continue
   coverage[region][1]+=1
   var point: Vector2=m.body_rect.position+uv*m.body_rect.size
   for obj in m.objects:
    var local: Vector2=(point-obj.rect.get_center()).rotated(-obj.draw_angle)/obj.rect.size+Vector2(.5,.5)
    if local.x<0 or local.x>=1 or local.y<0 or local.y>=1:continue
    var raw: Image=m.assets.image(obj.type)
    if raw.get_pixel(int(local.x*raw.get_width()),int(local.y*raw.get_height())).a>.12:
     coverage[region][0]+=1;break
 for region in coverage:
  var ratio: float=float(coverage[region][0])/maxi(1,coverage[region][1])
  check(ratio>=.9,"service region visibly covered: "+region+str(scale)+" = "+str(ratio))
 layouts[-1].merge({"regions":counts,"outline_regions":edges,"coverage":coverage,"manual_foot_overlaps":manual_foot_overlaps})
