extends SceneTree
const M=preload("res://scripts/prototype_grooming_fur/model.gd")
const OUT="res://reports/grooming_fur_service_20261016/"
var checks: int=0
var failures: Array=[]
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func swipe(m: RefCounted,a: Vector2,b: Vector2,speed: float=500.0) -> void:
 m.begin_gesture(a);m.stroke(a,b,a.distance_to(b)/speed)
func choose(m: RefCounted,rule: String) -> Dictionary:
 for obj in m.objects:
  if obj.rule==rule and not obj.done:return obj
 return {}
func _initialize() -> void:call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 var counts: Array=[]
 for scale in [1.0,.5]:
  var m=M.new();m.next_cat_scale=scale;m.start_order(0);m.tick(1)
  var patches: int=0;var outlines: int=0;var complete: bool=true;var service: bool=true;var aligned: bool=true
  for obj in m.objects:
   if obj.rule=="edge":outlines+=1
   if obj.rule!="patch":continue
   patches+=1
   var uv: Vector2=(obj.rect.get_center()-m.body_rect.position)/m.body_rect.size
   var expected: float=deg_to_rad(-78 if uv.x>=.835 else -12)
   aligned=aligned and absf(obj.draw_angle-expected)<=deg_to_rad(M.PATCH_ANGLE_LIMIT)+.0001
   complete=complete and obj.mask.get_pixel(0,0)==Color.WHITE and obj.mask.get_pixel(16,16)==Color.WHITE
   for y in range(32):
    for x in range(32):
     if obj.left[y*32+x]<=0:continue
     var at: Vector2=(m.sample_point(obj,x,y)-m.body_rect.position)/m.body_rect.size
     service=service and m.service_zone(at) and m.body_hit(at)
  counts.append({"scale":scale,"patches":patches,"outlines":outlines})
  check(service,"entire visible patch silhouette stays in torso/tail service zone "+str(scale))
  check(aligned,"patches vary only six degrees around their local hair flow "+str(scale))
  check(complete,"full white visual mask retains source sprite without fragmented clipping "+str(scale))
  check(outlines>=12,"more complete contour hairlocks distributed on torso/tail "+str(scale))
  var edge: Dictionary=choose(m,"edge");var before: float=edge.sum;var saved: PackedByteArray=edge.mask.get_data()
  var p: Vector2=edge.rect.get_center();var a: Vector2=p-Vector2(edge.rect.size.x*.65,0);var b: Vector2=p+Vector2(edge.rect.size.x*.65,0)
  swipe(m,a,b)
  check(edge.passes==1 and not edge.done and edge.sum==before,"first full pass loosens but does not erase contour "+str(scale))
  check(edge.mask.get_data()==saved,"first pass leaves every visible contour pixel intact "+str(scale))
  swipe(m,a,b);check(edge.passes==1,"same-direction restarts cannot fake an alternating pass "+str(scale))
  swipe(m,b,a);check(edge.passes==2 and not edge.done,"one round trip is insufficient "+str(scale))
  m.paused=true;swipe(m,a,b);check(edge.passes==2,"pause blocks contour work "+str(scale));m.paused=false
  swipe(m,a,b,1500);check(edge.passes==2 and not edge.done,"over-speed contour strokes do not count "+str(scale))
  swipe(m,a,b);check(edge.passes==3 and not edge.done,"third pass keeps complete sprite "+str(scale))
  swipe(m,b,a);check(edge.done and edge.sum==0,"four alternating passes detach entire contour "+str(scale))
  var fresh=M.new();fresh.next_cat_scale=scale;fresh.start_order(0);fresh.tick(1);edge=choose(fresh,"edge");p=edge.rect.get_center()
  for i in range(20):swipe(fresh,p-Vector2(2,0),p+Vector2(2,0));swipe(fresh,p+Vector2(2,0),p-Vector2(2,0))
  check(edge.passes==0,"tiny oscillations cannot substitute real travel "+str(scale))
  var split=M.new();split.next_cat_scale=scale;split.start_order(0);split.tick(1);edge=choose(split,"edge");p=edge.rect.get_center();a=p-Vector2(edge.rect.size.x*.65,0);b=p+Vector2(edge.rect.size.x*.65,0)
  for i in range(30):swipe(split,a.lerp(b,float(i)/30),a.lerp(b,float(i+1)/30))
  check(edge.passes==1,"dense and sparse input produce same contour pass count "+str(scale))
 check(counts[0].patches>counts[1].patches and counts[1].patches>0,"half-size cat has fewer same-size patches")
 var vp:=SubViewport.new();vp.size=Vector2i(1920,1080);vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(vp)
 var game=load("res://scenes/prototype_grooming/fur_demo.tscn").instantiate();vp.add_child(game);await create_timer(.55).timeout
 var edge: Dictionary=choose(game.model,"edge");var entry: Dictionary=game.view.object_sprites[edge.id];var p: Vector2=edge.rect.get_center()
 var a: Vector2=p-Vector2(edge.rect.size.x*.65,0);var b: Vector2=p+Vector2(edge.rect.size.x*.65,0)
 swipe(game.model,a,b);game.view.sync()
 check(entry.sprite.visible and edge.passes==1,"rendered contour remains after first pass")
 await process_frame;await RenderingServer.frame_post_draw;vp.get_texture().get_image().save_png(OUT+"11_outline_one_pass.png")
 for pair in [[b,a],[a,b],[b,a]]:swipe(game.model,pair[0],pair[1]);game.view.sync()
 check(not entry.sprite.visible,"rendered contour disappears as one whole object")
 var fall: bool=false
 for particle in game.view.particles:
  if particle.left>0 and particle.sprite.texture==game.model.assets.texture(edge.type):fall=true
 check(fall,"detached contour uses its complete source texture for falling feedback")
 await process_frame;await RenderingServer.frame_post_draw;vp.get_texture().get_image().save_png(OUT+"12_outline_detached.png")
 # Compare shader-rendered alpha with unmasked source, including external tips.
 var isolated:=SubViewport.new();isolated.size=Vector2i(320,180);isolated.transparent_bg=true;isolated.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(isolated)
 var sprite:=Sprite2D.new();sprite.texture=game.model.assets.texture(edge.type);sprite.position=Vector2(160,90);sprite.scale=Vector2(260,110)/Vector2(sprite.texture.get_size());isolated.add_child(sprite)
 await process_frame;await RenderingServer.frame_post_draw;var reference: Image=isolated.get_texture().get_image()
 sprite.material=entry.sprite.material.duplicate()
 var white:=Image.create(2,2,false,Image.FORMAT_RGBA8);white.fill(Color.WHITE);sprite.material.set_shader_parameter("remaining_mask",ImageTexture.create_from_image(white))
 await process_frame;await RenderingServer.frame_post_draw;var actual: Image=isolated.get_texture().get_image();var source_pixels: int=0;var lost: int=0
 for y in range(180):
  for x in range(320):
   if reference.get_pixel(x,y).a>.8:
    source_pixels+=1
    if actual.get_pixel(x,y).a<.75:lost+=1
 check(source_pixels>5000 and lost==0,"GPU preserves complete source contour silhouette without narrow edge mask")
 actual.save_png(OUT+"13_complete_contour_alpha.png")
 FileAccess.open(OUT+"service.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"layout":counts,"source_opaque_pixels":source_pixels,"lost_opaque_pixels":lost}," "))
 print("FUR SERVICE: ",checks," checks; ",failures.size()," failures")
 game.queue_free();vp.queue_free();isolated.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
