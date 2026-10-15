extends SceneTree
const M=preload("res://scripts/prototype_grooming_fur/model.gd")
const OUT="res://reports/grooming_fur_sizes_20261015/"
var checks: int=0
var failures: Array=[]
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func make(scale: float) -> RefCounted:
 var m=M.new();m.next_cat_scale=scale;m.start_order(0);m.tick(1);return m
func count(m: RefCounted,rule: String) -> int:
 var n: int=0
 for obj in m.objects:
  if obj.rule==rule:n+=1
 return n
func point(obj: Dictionary) -> Vector2:
 var best: Vector2=Vector2.ZERO;var distance: float=INF
 for y in range(32):
  for x in range(32):
   if obj.left[y*32+x]<=0:continue
   var p: Vector2=obj.rect.position+obj.rect.size*Vector2((x+.5)/32.0,(y+.5)/32.0)
   var d: float=p.distance_squared_to(obj.rect.get_center())
   if d<distance:distance=d;best=p
 return best
func swipe(m: RefCounted,a: Vector2,b: Vector2,speed: float=600) -> void:
 m.begin_gesture(a);m.stroke(a,b,a.distance_to(b)/speed)
func finish(m: RefCounted) -> void:
 for obj in m.objects:
  if obj.done:continue
  var p: Vector2=point(obj)
  if obj.rule=="patch":swipe(m,p-Vector2(15,0),p+Vector2(15,0))
  elif obj.rule=="knot":
   p=obj.rect.get_center();swipe(m,p-Vector2(25,0),p+Vector2(25,0),300)
  elif obj.rule=="dust":
   p=obj.rect.get_center();swipe(m,p-Vector2(0,80),p+Vector2(0,80));swipe(m,p+Vector2(0,80),p-Vector2(0,80))
  elif obj.rule=="flea":
   for i in range(3):m.click_at(obj.rect.get_center())
  elif obj.rule=="edge":
   for y in range(int(obj.rect.position.y),int(obj.rect.end.y)+10,16):
    swipe(m,Vector2(obj.rect.position.x-8,y),Vector2(obj.rect.end.x+8,y))
func _initialize() -> void:call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 var big=make(1);var small=make(.5)
 check(small.body_rect.size.is_equal_approx(big.body_rect.size*.5),"small cat is exactly half in each dimension")
 check(small.body_rect.get_center().x==big.body_rect.get_center().x and small.body_rect.end.y==big.body_rect.end.y,"both sizes stand on same tabletop")
 check(count(big,"patch")>count(small,"patch") and count(small,"patch")>0,"large cat has more fixed-size fur patches")
 var all_fixed: bool=true
 for m in [big,small]:
  for obj in m.objects:
   if obj.rule=="patch" and obj.rect.size!=Vector2(175,138):all_fixed=false
 check(all_fixed,"patches stay 175x138 on both cat sizes")
 var tail_tests: int=0
 for scale in [1.0,.5]:
  var template=make(scale)
  for obj in template.objects:
   var uv: Vector2=(obj.rect.get_center()-template.body_rect.position)/template.body_rect.size
   if obj.rule!="patch" or uv.x<.83:continue
   for axis in [Vector2(12,0),Vector2(0,-12)]:
    var m=make(scale);var target: Dictionary=m.objects[obj.id];var p: Vector2=point(target)
    swipe(m,p-axis,p+axis)
    check(target.done and m.score==100,"local tail patch accepts right/up without head start "+str(scale)+"/"+str(obj.id)+"/"+str(axis));tail_tests+=1
  var m=make(scale);var tail: Dictionary={}
  for obj in m.objects:
   if obj.type=="edge_gray_tail":tail=obj
  check(not tail.is_empty(),"tail outline exists at size "+str(scale))
  for y in range(int(tail.rect.position.y),int(tail.rect.end.y)+10,12):
   swipe(m,Vector2(tail.rect.position.x-8,y),Vector2(tail.rect.end.x+8,y))
  check(tail.done,"tail outline erases locally at size "+str(scale))
 check(tail_tests>=4,"both tail variants contain tested visible patches")
 finish(big);finish(small)
 check(big.settled and big.wallet==100,"big cat finishes using local object strokes")
 check(small.settled and small.wallet==100,"small cat finishes using local object strokes")
 var cycle=M.new();cycle.start_order(2)
 check(cycle.cat_scale==.5 and cycle.needs_nails,"normal third order includes small cat full service")
 cycle.tick(1);finish(cycle)
 check(cycle.stage=="to_nails","small full service transitions from brushing to nails")
 cycle.tick(1)
 for nail in cycle.nails:
  var edges: Vector2=cycle.nail_edges(nail,cycle.perfect_height());var y: float=nail.root.y-cycle.perfect_height()
  cycle.cut_gesture(PackedVector2Array([Vector2(edges.x-15,y),Vector2(edges.y+15,y)]))
 check(cycle.settled and cycle.wallet==150,"small full service pays after all four nails")
 var vp:=SubViewport.new();vp.size=Vector2i(1920,1080);vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(vp)
 var game=load("res://scenes/prototype_grooming/fur_demo.tscn").instantiate();vp.add_child(game);await create_timer(.6).timeout
 await process_frame;await RenderingServer.frame_post_draw;vp.get_texture().get_image().save_png(OUT+"08_large_cat.png")
 var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=Vector2(895,65);e.pressed=true;vp.push_input(e,true)
 e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=Vector2(895,65);e.pressed=false;vp.push_input(e,true);await create_timer(.55).timeout
 check(game.model.cat_scale==.5,"actual size button selects half-size cat")
 check(game.model.body_rect.size.is_equal_approx(big.body_rect.size*.5),"rendered half-size cat uses correct model bounds")
 all_fixed=true
 for obj in game.model.objects:
  if obj.rule!="patch":continue
  var sprite: Sprite2D=game.view.object_sprites[obj.id].sprite
  if not (Vector2(sprite.texture.get_size())*sprite.scale).is_equal_approx(Vector2(175,138)):all_fixed=false
 check(all_fixed,"rendered small-cat patches retain full logical size")
 await process_frame;await RenderingServer.frame_post_draw;vp.get_texture().get_image().save_png(OUT+"09_small_cat.png")
 # Local tail operation through real GUI mouse input, with controlled frame time.
 var tail: Dictionary={}
 for obj in game.model.objects:
  var uv: Vector2=(obj.rect.get_center()-game.model.body_rect.position)/game.model.body_rect.size
  if obj.rule=="patch" and uv.x>=.83:tail=obj;break
 var at: Vector2=point(tail)
 e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=at-Vector2(12,0);e.pressed=true;vp.push_input(e,true);await process_frame
 var move:=InputEventMouseMotion.new();move.position=at+Vector2(12,0);move.button_mask=MOUSE_BUTTON_MASK_LEFT;vp.push_input(move,true);game.flush_grooming(.04)
 e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=at+Vector2(12,0);e.pressed=false;vp.push_input(e,true);await process_frame
 check(tail.done and game.model.score==100,"real GUI locally brushes small cat tail without penalty")
 await process_frame;await RenderingServer.frame_post_draw;vp.get_texture().get_image().save_png(OUT+"10_small_tail_brushed.png")
 FileAccess.open(OUT+"sizes.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"large_patch_count":count(big,"patch"),"small_patch_count":count(small,"patch"),"patch_size":[175,138],"tail_patch_tests":tail_tests}," "))
 print("FUR SIZES: ",checks," checks; ",failures.size()," failures")
 game.queue_free();vp.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
