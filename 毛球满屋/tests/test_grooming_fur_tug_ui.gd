extends SceneTree
const Brush=preload("res://scripts/prototype_grooming_fur/brush_config.gd")
var OUT: String=OS.get_environment("PURR_FUR_REPORT") if not OS.get_environment("PURR_FUR_REPORT").is_empty() else "res://reports/fur_asset_cleanup_20261017/"
var checks: int=0
var failures: Array=[]
var metrics: Array=[]
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize() -> void:call_deferred("run")
func sample_point(m: RefCounted,obj: Dictionary) -> Vector2:
 var best: float=INF;var at: Vector2=obj.rect.get_center()
 for y in range(32):
  for x in range(32):
   if obj.left[y*32+x]<=0:continue
   var p: Vector2=m.sample_point(obj,x,y)
   if p.distance_squared_to(obj.rect.get_center())<best:at=p;best=p.distance_squared_to(obj.rect.get_center())
 return at
func shot(vp: SubViewport,name: String) -> Image:
 await process_frame;await RenderingServer.frame_post_draw
 var img: Image=vp.get_texture().get_image();img.save_png(OUT+name);return img
func button(vp: SubViewport,p: Vector2,pressed: bool) -> void:
  # Real clicks include moving the cursor onto the control before pressing.
 if pressed:
  var motion:=InputEventMouseMotion.new();motion.position=p;vp.push_input(motion,true);await process_frame
 var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;e.position=p;vp.push_input(e,true)
 await process_frame
func movement(vp: SubViewport,a: Vector2,b: Vector2) -> void:
 var e:=InputEventMouseMotion.new();e.position=b;e.relative=b-a;e.button_mask=MOUSE_BUTTON_MASK_LEFT;vp.push_input(e,true)
 await create_timer(.018).timeout
func groom(vp: SubViewport,p: Vector2) -> void:
 var factor:=Vector2(vp.size)/Vector2(1920,1080)
 var a: Vector2=(p-Vector2(36,0))*factor
 await button(vp,a,true)
 for i in range(8):await movement(vp,a+Vector2(9*i,0)*factor,a+Vector2(9*(i+1),0)*factor)
 await button(vp,(p+Vector2(36,0))*factor,false)
func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 for dimensions in [Vector2i(1920,1080),Vector2i(1440,810)]:
  metrics.append({"viewport":str(dimensions)})
  var vp:=SubViewport.new();vp.size=dimensions;vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(vp)
  var game=load("res://scenes/prototype_grooming/fur_demo.tscn").instantiate();vp.add_child(game)
  await create_timer(.35).timeout
  check(game.model.stage=="arrival" and game.view.platform.position.y>0,"actual platform and cat entering from below "+str(dimensions))
  check(game.view.base.get_parent().get_parent()==game.view.platform and game.view.table.get_parent()==game.view.platform,"cat and table share real platform transform "+str(dimensions))
  await shot(vp,"00_rising_"+str(dimensions.x)+".png")
  await create_timer(1.05).timeout
  for name in game.model.assets.fall_index.sprites:
   var asset: AtlasTexture=load("res://Art/grooming_fur_v1/fall_variants/"+name+".tres")
   var raw: Image=game.model.assets.image(name)
   check(asset!=null and Vector2(asset.get_size())==Vector2(raw.get_size()),"independent AtlasTexture matches runtime cut "+name+str(dimensions))
  check(game.get_node_or_null("HUD/Top/Robot")==null and game.get_node_or_null("HUD/Top/Nails")==null and game.get_node_or_null("HUD/Top/Full")==null,"removed robot/nail/full entry nodes "+str(dimensions))
  check(game.get_node_or_null("HUD/Top/Quality")==null,"no rating/negative-feedback UI "+str(dimensions))
  check(game.get_node_or_null("HUD/Top/Retry")==null and game.get_node_or_null("HUD/Top/Calico")==null,"no restart buttons required "+str(dimensions))
  check(game.model.objects.all(func(obj):return obj.rule in ["patch","edge"]),"only grooming targets in runtime "+str(dimensions))
  await shot(vp,"01_initial_"+str(dimensions.x)+".png")
  var authored: Dictionary=game.model.objects.filter(func(item):return item.get("manual_outline",false))[0]
  var edge_point: Vector2=sample_point(game.model,authored)
  await groom(vp,edge_point)
  check(authored.passes==1 and not authored.done,"real mouse first pass activates saved manual contour "+str(dimensions))
  await create_timer(.35).timeout
  await groom(vp,edge_point)
  check(authored.detach_pending and not authored.done,"manual contour waits for final recoil "+str(dimensions))
  await create_timer(.35).timeout
  check(authored.done and not game.view.object_sprites[authored.id].sprite.visible,"manual contour disappears after recoil "+str(dimensions))
  check(game.view.particles.any(func(item):return item.kind=="detached" and item.source_id==authored.id and item.left>0),"manual contour gets its own falling effect "+str(dimensions))
  await shot(vp,"14_manual_contour_after_groom_"+str(dimensions.x)+".png")
  game.model.start_order(0);game.model.tick(Brush.PLATFORM_RISE_TIME+.01);game.view.sync()
  await create_timer(.06).timeout # Let the controller observe the fixture's new serial before input.
  var obj: Dictionary=game.model.objects[0];var p: Vector2=sample_point(game.model,obj)
  await groom(vp,p)
  check(obj.passes==1 and not obj.done,"real first mouse stroke cannot detach "+str(dimensions))
  check(obj.pull_amount>0 and game.view.object_sprites[obj.id].sprite.visible,"actual shader remains attached while recoiling "+str(dimensions))
  await shot(vp,"02_first_recoil_"+str(dimensions.x)+".png")
  await create_timer(.4).timeout
  check(obj.pull_amount==0 and not obj.done,"real first stroke restores whole patch "+str(dimensions))
  await shot(vp,"03_first_restored_"+str(dimensions.x)+".png")
  await groom(vp,p)
  check(obj.detach_pending and not obj.done,"real second stroke waits for recoil "+str(dimensions))
  await shot(vp,"04_final_recoil_"+str(dimensions.x)+".png")
  await create_timer(.4).timeout
  check(obj.done and not game.view.object_sprites[obj.id].sprite.visible,"original patch disappears only after return "+str(dimensions))
  var fallen: Dictionary={}
  for particle in game.view.particles:
   if particle.left>0 and particle.kind=="detached" and particle.source_id==obj.id:fallen=particle;break
  check(not fallen.is_empty(),"whole detached patch enters falling pool "+str(dimensions))
  if not fallen.is_empty():
   check(fallen.variant.begins_with("fall_variant_") and fallen.sprite.material==null,"detached source replaced by loose-fur graphic, no old outlined tile shader "+str(dimensions))
   var start: Vector2=fallen.sprite.position
   var alpha: float=fallen.sprite.modulate.a
   await create_timer(.75).timeout
   var fall: float=(fallen.sprite.position.y-start.y)*1080.0/dimensions.y
   check(fall>45 and fall<110,"hair has visible weight: faster than old 10-55px range "+str(dimensions))
   check(fallen.left>0 and fallen.sprite.modulate.a>.1 and fallen.sprite.modulate.a<.38,"whole fur is translucent and gradually fades "+str(dimensions))
   metrics[-1].merge({"fall_075s":fall,"alpha_initial":alpha,"alpha_after":fallen.sprite.modulate.a})
  await shot(vp,"05_weighted_translucent_fall_"+str(dimensions.x)+".png")
  # Force a fresh particle only to measure size/rate/motion independently.
  for particle in game.view.particles:particle.left=0;particle.sprite.hide()
  game.view.burst("fall_gray_peel",Vector2(960,500),9)
  var active: Array=game.view.particles.filter(func(item):return item.left>0)
  check(active.size()==1,"burst request emits only one larger clump "+str(dimensions))
  var particle: Dictionary=active[0]
  var width: float=particle.sprite.texture.get_width()*particle.sprite.scale.x*1920.0/dimensions.x
  check(width>=26 and width<=76,"clumps and shards use different bounded sizes "+str(dimensions))
  check(particle.velocity.y>=68 and absf(particle.velocity.x)<=10,"weighted downward start with limited lateral drift "+str(dimensions))
  game.toggle_pause();var before: Vector2=particle.sprite.position;await create_timer(.3).timeout
  check(particle.sprite.position==before,"pause freezes hair fall and recoil "+str(dimensions));game.toggle_pause()
  await audit_fall_variants(game,vp,dimensions)
  var serial: int=game.model.serial
  var size_at: Vector2=game.get_node("HUD/Top/Size").get_global_rect().get_center()
  await button(vp,size_at,true);await button(vp,size_at,false)
  metrics[-1].merge({"size_button_at":str(size_at),"size_after_click":game.model.cat_scale,"queued_size_after_click":game.model.next_cat_scale,"serial_before_click":serial,"serial_after_click":game.model.serial})
  check(game.model.cat_scale==1 and game.model.next_cat_scale==.5 and game.model.serial==serial,"size selection schedules next cat without resetting current "+str(dimensions))
  for obj2 in game.model.objects:game.model.clear_object(obj2)
  game.model.check_clean_finished();await create_timer(.2).timeout
  check(game.model.stage=="reward" and game.model.serial==serial,"brief finish presentation, no immediate replacement "+str(dimensions))
  await create_timer(.6).timeout
  check(game.model.stage=="departure" and game.view.platform.position.y>0,"table carrying finished cat descends "+str(dimensions))
  await shot(vp,"12_lowering_"+str(dimensions.x)+".png")
  game.toggle_pause();var height: float=game.view.platform.position.y;await create_timer(.2).timeout
  check(game.view.platform.position.y==height,"pause freezes actual platform transform "+str(dimensions));game.toggle_pause()
  await create_timer(.72).timeout
  check(game.model.serial==serial+1 and game.model.stage=="arrival","new cat appears only after offscreen lowering "+str(dimensions))
  await button(vp,Vector2(600,600),true)
  check(not game.dragging,"click during arrival does not arm grooming "+str(dimensions))
  await button(vp,Vector2(600,600),false)
  await shot(vp,"13_next_rising_"+str(dimensions.x)+".png")
  await create_timer(1.4).timeout
  check(game.model.cat_scale==.5 and game.model.stage=="cleaning" and game.model.kind=="calico" and not game.model.needs_nails,"new small cat ready with clean stroke progress, no removed mechanics "+str(dimensions))
  await shot(vp,"06_small_cat_"+str(dimensions.x)+".png")
  # Measure actual GPU deformation in a transparent isolated viewport.
  obj=game.model.objects[0]
  var isolated:=SubViewport.new();isolated.size=Vector2i(300,200);isolated.transparent_bg=true;isolated.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(isolated)
  var sprite:=Sprite2D.new();sprite.texture=game.model.assets.texture(obj.type);sprite.material=game.view.object_sprites[obj.id].sprite.material.duplicate()
  sprite.position=Vector2(150,100);sprite.rotation=obj.draw_angle;sprite.scale=obj.rect.size/Vector2(sprite.texture.get_size());isolated.add_child(sprite)
  sprite.material.set_shader_parameter("pull_amount",0.0)
  var rest: Image=await shot(isolated,"07_gpu_rest_"+str(dimensions.x)+".png")
  sprite.material.set_shader_parameter("pull_amount",18.0)
  var stretched: Image=await shot(isolated,"08_gpu_pull_"+str(dimensions.x)+".png")
  var changed: int=0
  for y in range(200):
   for x in range(300):
    if absf(rest.get_pixel(x,y).a-stretched.get_pixel(x,y).a)>.15:changed+=1
  check(changed>100,"real GPU silhouette deforms rather than only changing a counter "+str(dimensions))
  sprite.material.set_shader_parameter("pull_amount",0.0)
  var returned: Image=await shot(isolated,"09_gpu_returned_"+str(dimensions.x)+".png")
  check(rest.get_data()==returned.get_data(),"GPU returns exactly to original shape "+str(dimensions))
  metrics[-1].deformed_pixels=changed
  isolated.queue_free();game.queue_free();vp.queue_free();await process_frame
 FileAccess.open(OUT+"ui.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"metrics":metrics}," "))
 print("FUR TUG UI: ",checks," checks; ",failures.size()," failures")
 quit(0 if failures.is_empty() else 1)

func audit_fall_variants(game: Control,vp: SubViewport,dimensions: Vector2i) -> void:
 game.set_process(false)
 game.view.fx_rng.seed=17002
 var seen: Dictionary={};var angles: Dictionary={};var widths: Dictionary={}
 var previous: String=""
 for palette in ["gray","cream"]:
  for i in range(80):
   for p in game.view.particles:p.left=0;p.sprite.hide()
   game.view.burst("fall_"+palette+"_peel",Vector2(960,500),9)
   var p: Dictionary=game.view.particles.filter(func(item):return item.left>0)[0]
   seen[p.variant]=true;angles[snappedf(p.sprite.rotation,.1)]=true
   widths[snappedf(p.sprite.scale.x*p.sprite.texture.get_width()*1920.0/dimensions.x,1.0)]=true
   check(p.variant.contains(palette),"particle retains regional coat palette "+str(dimensions)+" "+str(i))
   check(p.variant!=previous,"particle never immediately repeats the same source "+str(dimensions)+" "+str(i));previous=p.variant
 check(seen.size()==12,"all 12 individually cut assets participate "+str(dimensions))
 check(angles.size()>20 and widths.size()>20,"seeded variations include multiple angles and sizes "+str(dimensions))
 for p in game.view.particles:p.left=0;p.sprite.hide()
 for i in range(20):game.view.burst("fall_gray_peel",Vector2(700+i*25,430),1)
 for obj in game.model.objects.slice(0,12):game.view.detach_patch(obj)
 check(game.view.active_particles("loose")==10 and game.view.active_particles("detached")==12,"all 12 detached pieces appear even with loose pool occupied "+str(dimensions))
 check(game.view.particles.filter(func(p):return p.left>0).size()==22,"fall pool expands beyond former 16 slots without suppressing pieces "+str(dimensions))
 var p: Dictionary=game.view.particles.filter(func(item):return item.kind=="detached" and item.left>0)[0]
 var start: Vector2=p.sprite.position;game.view.animate(.75)
 var distance: float=(p.sprite.position.y-start.y)*1080.0/dimensions.y
 check(distance>60 and distance<110 and p.sprite.modulate.a<.3,"controlled fall advances while remaining unobtrusive "+str(dimensions))
 await shot(vp,"10_conserved_varied_fall_"+str(dimensions.x)+".png")
 game.view.animate(1.5)
 check(game.view.particles.all(func(item):return item.left==0 and not item.sprite.visible),"all fall effects expire without becoming opaque again "+str(dimensions))
 metrics[-1].merge({"variants":seen.keys(),"angle_count":angles.size(),"width_count":widths.size(),"capped_fall_075s":distance})
 # Entire-coat stress: route completion through sync, not just direct FX calls.
 for scale in [1.0,.5]:
  game.model.next_cat_scale=scale;game.model.start_order(0);game.model.tick(Brush.PLATFORM_RISE_TIME+.01);game.view.sync()
  for i in range(20):game.view.burst("fall_gray_peel",Vector2(950,500),1)
  for obj in game.model.objects:obj.done=true;obj.pull_amount=0
  game.view.sync()
  var detached: Array=game.view.particles.filter(func(item):return item.left>0 and item.kind=="detached")
  check(detached.size()==game.model.objects.size(),"every whole coat patch has one fall at size "+str(scale)+str(dimensions))
  var ids: Dictionary={}
  for item in detached:ids[item.source_id]=true
  check(ids.size()==game.model.objects.size(),"fall source IDs are unique at size "+str(scale)+str(dimensions))
  check(detached.all(func(item):return is_equal_approx(item.sprite.modulate.a,.38)),"all detached patches retain current transparency "+str(scale)+str(dimensions))
  var shapes: Dictionary={}
  for item in detached:
   shapes[item.variant]=true
   var source: Dictionary=game.model.objects[item.source_id]
   var pixel_size: Vector2=Vector2(item.sprite.texture.get_size())*item.sprite.scale/(Vector2(dimensions)/Vector2(1920,1080))
   var relative: Vector2=pixel_size/source.rect.size
   var ratio: float=maxf(relative.x,relative.y)
   check(ratio>=.899 and ratio<=1.101 and item.sprite.material==null,"large loose-fur fall stays comparable to source patch "+str(source.id)+str(scale)+str(dimensions))
  check(shapes.size()>=8,"whole coat uses varied loose-fur graphics "+str(scale)+str(dimensions))
  check(game.view.object_sprites.values().all(func(entry):return not entry.sprite.visible),"all completed source patches replaced by falling counterparts "+str(scale)+str(dimensions))
  game.view.sync()
  check(game.view.active_particles("detached")==detached.size(),"repeated sync cannot duplicate falling patches "+str(scale)+str(dimensions))
  game.view.animate(.3)
  var at: Vector2=detached[0].sprite.position
  game.view.animate(.3)
  check(detached[0].sprite.position.y>at.y and detached[0].sprite.modulate.a<.38,"whole-coat fall moves and fades "+str(scale)+str(dimensions))
  await shot(vp,"11_whole_coat_"+str(scale)+"_"+str(dimensions.x)+".png")
  game.view.animate(2.2)
  check(game.view.active_particles("detached")==0,"whole-coat effects expire for pool reuse "+str(scale)+str(dimensions))
  metrics[-1]["conserved_"+str(scale)]=detached.size()
 game.model.next_cat_scale=1.0;game.model.start_order(0);game.model.tick(Brush.PLATFORM_RISE_TIME+.01);game.view.sync()
 game.set_process(true)
