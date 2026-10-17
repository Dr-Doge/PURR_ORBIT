extends "res://scripts/prototype_grooming/model.gd"
const FurAssets=preload("res://scripts/prototype_grooming_fur/assets.gd")
const Tool=preload("res://scripts/prototype_grooming_fur/tool_geometry.gd")
const PATCH_SIZE=Vector2(96,72)
const PATCH_STEP=Vector2(46,32)
const Brush=preload("res://scripts/prototype_grooming_fur/brush_config.gd")
const AuthoredOutline=preload("res://scripts/prototype_grooming_fur/authored_outline.gd")
const EDGE_PASSES=Brush.PASSES
const PATCH_ANGLE_LIMIT=6.0
const OUTLINE_INK_OFFSET=4.0
var fur_ready: bool=false
var cat_scale: float=1.0
var next_cat_scale: float=0.0
var outline_profiles: Dictionary={}
var paw_exclusions: Array=[]
var outline_paths: Array=[]
var layout_index: Dictionary={}
var platform_offset: float=Brush.PLATFORM_TRAVEL
var cat_inertia: float=0.0
var automatic_cycle: bool=true
var queued_presentation: Resource
var authored_outline_errors: Array=[]
signal customer_ready(customer_serial: int)
signal customer_completed(customer_serial: int,amount: int)
signal customer_prepared(customer_serial: int)
signal customer_departed(customer_serial: int)

func configure_presentation(value: Resource) -> bool:
 if value==null or not value.has_method("validation_errors"):return false
 if not value.validation_errors().is_empty():return false
 apply_presentation(value)
 start_order(0)
 return true

func apply_presentation(value: Resource) -> void:
 assets.configure_presentation(value);outline_profiles.clear()
 service_chest=value.service_chest;service_body=value.service_body;service_tail=value.service_tail
 paw_exclusions=value.paw_exclusions;outline_paths=value.outline_paths

func queue_customer(value: Resource=null,scale: float=0.0) -> bool:
 if value!=null and (not value.has_method("validation_errors") or not value.validation_errors().is_empty()):return false
 if scale!=0 and scale not in [1.0,.5]:return false
 if value!=null:queued_presentation=value
 if scale>0:next_cat_scale=scale
 return true

func release_customer() -> bool:
 if stage!="reward" or not settled:return false
 stage="departure";stage_left=Brush.PLATFORM_LOWER_TIME
 return true

func prepare_claw() -> void:
 # This pure-grooming model does not load or analyse unused nail art.
 pass

func _init() -> void:
 super()
 assets=FurAssets.new();apply_presentation(assets.presentation);claw_spans=[];prepare_claw();fur_ready=true;start_order(0)

func start_order(_index: int=0,_nail_practice: bool=false) -> void:
 if fur_ready:
  if queued_presentation!=null:apply_presentation(queued_presentation);queued_presentation=null
  if next_cat_scale>0:cat_scale=next_cat_scale;next_cat_scale=0
  assets.subject_scale=cat_scale
 # This scene only hosts the beginner cat. Legacy order arguments cannot
 # reintroduce the robot, nail stage or special objects.
 super.start_order(0,false)
 if not fur_ready:return
 needs_nails=false;title=("大" if cat_scale==1 else "小")+assets.presentation.cat_name+" · 纯梳毛"
 objects=[];layout_index.clear();build_fur_objects()
 stage="arrival";stage_left=Brush.PLATFORM_RISE_TIME;platform_offset=Brush.PLATFORM_TRAVEL;cat_inertia=0
 note="从左向右梳两遍：第一遍拉松，第二遍回弹后脱落。松手保留进度。"
 note_left=4.0
 customer_prepared.emit(serial)

func build_body_mask() -> void:
 if not fur_ready:super.build_body_mask();return
 var raw: Image=assets.image(kind+"_clean").duplicate()
 raw.resize(C.BODY_GRID.x,C.BODY_GRID.y,Image.INTERPOLATE_NEAREST)
 body_mask=Image.create(C.BODY_GRID.x,C.BODY_GRID.y,false,Image.FORMAT_RGBA8)
 body_valid.resize(C.BODY_GRID.x*C.BODY_GRID.y)
 for y in range(C.BODY_GRID.y):
  for x in range(C.BODY_GRID.x):
   var valid: bool=raw.get_pixel(x,y).a>0.15
   body_valid[y*C.BODY_GRID.x+x]=int(valid)
   body_mask.set_pixel(x,y,Color(float(valid),0,0,1))

func coat_at(uv: Vector2) -> String:
 var raw: Image=assets.image("calico_clean")
 var p: Color=raw.get_pixel(clampi(int(uv.x*raw.get_width()),0,raw.get_width()-1),clampi(int(uv.y*raw.get_height()),0,raw.get_height()-1))
 return "cream" if p.r>0.82 and p.g>0.79 and p.b>0.72 else "gray"

# Service polygons are declared by the replaceable presentation profile.
var service_chest:=PackedVector2Array()
var service_body:=PackedVector2Array()
var service_tail:=PackedVector2Array()
func paw_zone(uv: Vector2) -> bool:
 if uv.y<.86:return false
 for polygon in paw_exclusions:
  if Geometry2D.is_point_in_polygon(uv,polygon):return true
 return false

func region_at(uv: Vector2) -> String:
 if paw_zone(uv):return ""
 if Geometry2D.is_point_in_polygon(uv,service_tail):return "tail"
 if Geometry2D.is_point_in_polygon(uv,service_chest):return "chest"
 if Geometry2D.is_point_in_polygon(uv,service_body):return "body"
 return ""

func service_zone(uv: Vector2) -> bool:
 return not region_at(uv).is_empty()

func service_margin(uv: Vector2) -> bool:
 if paw_zone(uv):return false
 if service_zone(uv):return true
 var p: Vector2=uv*body_rect.size
 for polygon in [service_chest,service_body,service_tail]:
  for i in range(polygon.size()):
   var a: Vector2=polygon[i]*body_rect.size;var b: Vector2=polygon[(i+1)%polygon.size()]*body_rect.size
   var t: float=clampf((p-a).dot(b-a)/maxf((b-a).length_squared(),.001),0,1)
   if p.distance_squared_to(a+(b-a)*t)<=196.0:return true
 return false

func sample_point(obj: Dictionary,x: int,y: int) -> Vector2:
 var offset: Vector2=obj.rect.size*(Vector2((x+.5)/C.OBJECT_GRID,(y+.5)/C.OBJECT_GRID)-Vector2(.5,.5))
 var angle: float=obj.get("draw_angle",0.0)
 var world: Vector2=offset.rotated(angle)
 var extent: float=maxf(1,absf(cos(angle))*obj.rect.size.x*.5+absf(sin(angle))*obj.rect.size.y*.5)
 var weight: float=clampf((world.x+extent)/(2.0*extent),0,1)
 var pull: float=obj.get("pull_amount",0.0)
 return obj.rect.get_center()+world+Vector2(pull*weight,-pull*.10*sin(weight*PI))

func patch_fits(type: String,uv: Vector2,angle: float) -> bool:
 var raw: Image=assets.image(type)
 # Test the complete visible silhouette before placement; never crop it to fit.
 for y in range(32):
  for x in range(32):
   if raw.get_pixel(int((x+.5)/32*raw.get_width()),int((y+.5)/32*raw.get_height())).a<.12:continue
   var point: Vector2=body_rect.position+body_rect.size*uv+(PATCH_SIZE*(Vector2((x+.5)/32,(y+.5)/32)-Vector2(.5,.5))).rotated(angle)
   var at: Vector2=(point-body_rect.position)/body_rect.size
   if not service_margin(at) or not body_hit(at) or paw_zone(at+Vector2(Brush.MAX_PULL,0)/body_rect.size):return false
 return true

func module_angle(type: String,tail: bool) -> float:
 var angle: float=-12.0
 if type.ends_with("ruffle"):angle=-48.0
 elif type.ends_with("fold"):angle=78.0
 return deg_to_rad(angle+(-66.0 if tail else 0.0))

func build_fur_objects() -> void:
 # When repairing asset alpha, retain the saved reference-body arrangement too;
 # cleaner silhouettes must not cause the procedural fitter to move the cat's fur.
 if assets.presentation.outline_layout!=null:
  var saved: Dictionary=AuthoredOutline.read(assets.presentation.outline_layout,cat_scale)
  if saved.errors.is_empty() and not saved.body_pieces.is_empty():
   authored_outline_errors=[]
   for piece in saved.body_pieces:apply_authored_piece(piece,"patch",saved.body_rect)
   for piece in saved.pieces:apply_authored_piece(piece,"edge",saved.body_rect)
   return
 var rng:=RandomNumberGenerator.new();rng.seed=6101602+int(cat_scale*100)+order_index
 var variants: Array=["ruffle","wide","fold","cross"]
 for row in range(ceili(body_rect.size.y/PATCH_STEP.y)):
  for column in range(ceili(body_rect.size.x/PATCH_STEP.x)):
   var local:=Vector2((column+.5)*PATCH_STEP.x+(23 if row%2 else 0),(row+.5)*PATCH_STEP.y)+Vector2(rng.randf_range(-4,4),rng.randf_range(-3,3))
   var uv: Vector2=local/body_rect.size
   if not service_zone(uv) or not body_hit(uv):continue
   var tail: bool=region_at(uv)=="tail"
   var coat: String=coat_at(uv)
   if coat_at(uv-Vector2(.022,0))!=coat_at(uv+Vector2(.022,0)):coat="mixed"
   var first: int=rng.randi_range(0,3)
   for attempt in range(4):
    var type: String=coat+"_"+variants[(first+attempt)%4]
    var angle: float=module_angle(type,tail)+deg_to_rad(rng.randf_range(-PATCH_ANGLE_LIMIT,PATCH_ANGLE_LIMIT))
    if not patch_fits(type,uv,angle):continue
    add_full_object(type,"patch",uv,PATCH_SIZE,angle);objects[-1].region=region_at(uv);break
 # Each anatomical path follows the actual alpha boundary; feet are excluded.
 var anchors: Array=[]
 for path in outline_paths:
  var points: PackedVector2Array=path.points
  for i in range(points.size()-1):
   var delta: Vector2=(points[i+1]-points[i])*body_rect.size
   var steps: int=maxi(1,ceili(delta.length()/(54.0*cat_scale)))
   for j in range(steps):
    var uv: Vector2=points[i].lerp(points[i+1],float(j)/steps)
    var guide_position: Vector2=body_rect.position+uv*body_rect.size
    var tangent: Vector2=delta.normalized()
    var outward: Vector2=tangent.rotated(float(path.side)*PI/2)
    uv=snap_to_contour(uv,outward)
    var at: Vector2=body_rect.position+uv*body_rect.size
    if paw_zone(uv) or not service_margin(uv) or at.distance_to(guide_position)>60.0*cat_scale or anchors.any(func(p):return p.distance_to(at)<25.0*cat_scale):continue
    var cream: bool=coat_at(uv-outward*12.0*cat_scale/body_rect.size)=="cream"
    var type: String=("edge_cream_belly" if j%2==0 else "edge_cream_leg") if cream else ("edge_gray_back" if j%2==0 else "edge_gray_flank")
    var previous_count: int=objects.size()
    add_outline(type,uv,Vector2(140,54)*cat_scale,outward)
    if objects.size()>previous_count:
     objects[-1].region=path.region;objects[-1].outline_section=path.name;anchors.append(at)
 fill_service_gaps()
 replace_authored_outline()

func replace_authored_outline() -> void:
 authored_outline_errors=[]
 if assets.presentation.outline_layout==null:return
 var layout: Dictionary=AuthoredOutline.read(assets.presentation.outline_layout,cat_scale)
 authored_outline_errors=layout.errors
 if not authored_outline_errors.is_empty():
  for error in authored_outline_errors:push_error(str(error))
  return
 # Generate body coverage using the previous reference geometry first; replacing
 # contour sprites must not unexpectedly rearrange the artist's body backdrop.
 objects=objects.filter(func(obj):return obj.rule!="edge")
 layout_index.clear()
 for i in range(objects.size()):
  objects[i].id=i;index_object(objects[i])
 var authored_box: Rect2=layout.get("body_rect",body_rect)
 for piece in layout.pieces:
  apply_authored_piece(piece,"edge",authored_box)

func apply_authored_piece(piece: Dictionary,rule: String,authored_box: Rect2) -> void:
 var type: String=piece.type
 # Keep the actual saved texture authoritative, but upload each shared crop
 # once per asset cache rather than once per placed sprite on every customer.
 if assets.authored_sources.get(type,"")!=piece.resource_path or not assets.textures.has(type):
  var raw: Image=piece.texture.get_image()
  if raw.is_compressed():raw.decompress()
  assets.images[type]=raw
  # Shader UVs are local to a cropped image, not the original atlas page.
  assets.textures[type]=ImageTexture.create_from_image(raw)
  assets.authored_sources[type]=piece.resource_path
 var center_uv: Vector2=(piece.center-authored_box.position)/authored_box.size
 var drawn: Vector2=piece.size*body_rect.size/authored_box.size
 add_full_object(type,rule,center_uv,drawn,piece.angle,piece.flip_h,piece.flip_v)
 var obj: Dictionary=objects[-1]
 obj.region=piece.region;obj.authored_path=piece.path;obj.authored_texture_path=piece.resource_path
 obj.manual_outline=rule=="edge"

func point_covered(point: Vector2) -> bool:
 var cell:=Vector2i(floori(point.x/80.0),floori(point.y/80.0))
 for id in layout_index.get(cell,[]):
  var obj: Dictionary=objects[id]
  var uv: Vector2=(point-obj.rect.get_center()).rotated(-obj.draw_angle)/obj.rect.size+Vector2(.5,.5)
  if uv.x<0 or uv.x>=1 or uv.y<0 or uv.y>=1:continue
  var raw: Image=assets.image(obj.type)
  if raw.get_pixel(int(uv.x*raw.get_width()),int(uv.y*raw.get_height())).a>.12:return true
 return false

func fill_service_gaps() -> void:
 var variants: Array=["wide","cross","ruffle","fold"]
 var probes: Array=[Vector2.ZERO,Vector2(-25,0),Vector2(25,0),Vector2(0,-18),Vector2(0,18)]
 for row in range(ceili(body_rect.size.y/16.0)):
  for column in range(ceili(body_rect.size.x/23.0)):
   var center: Vector2=body_rect.position+Vector2((column+.5)*23,(row+.5)*16)
   var uv: Vector2=(center-body_rect.position)/body_rect.size
   if not service_zone(uv) or not body_hit(uv):continue
   var gaps: Array=[]
   for offset in probes:
    var p: Vector2=center+offset;var at: Vector2=(p-body_rect.position)/body_rect.size
    if service_zone(at) and body_hit(at) and not point_covered(p):gaps.append(p)
   if gaps.is_empty():continue
   var coat: String=coat_at(uv)
   if coat_at(uv-Vector2(.022,0))!=coat_at(uv+Vector2(.022,0)):coat="mixed"
   for suffix in variants:
    var type: String=coat+"_"+suffix;var angle: float=module_angle(type,region_at(uv)=="tail")
    var raw: Image=assets.image(type);var covers: bool=false
    for p in gaps:
     var local: Vector2=(p-center).rotated(-angle)/PATCH_SIZE+Vector2(.5,.5)
     if local.x>=0 and local.x<1 and local.y>=0 and local.y<1 and raw.get_pixel(int(local.x*raw.get_width()),int(local.y*raw.get_height())).a>.12:covers=true;break
    if not covers or not patch_fits(type,uv,angle):continue
    add_full_object(type,"patch",uv,PATCH_SIZE,angle);objects[-1].region=region_at(uv);break

func boundary_at_x(x: float,low: float,high: float,bottom: bool) -> Vector2:
 var raw: Image=assets.image("calico_clean")
 var first: int=int(low*raw.get_height());var last: int=int(high*raw.get_height())
 for i in range(last-first):
  var y: int=last-1-i if bottom else first+i
  if raw.get_pixel(int(x*raw.get_width()),y).a>.6:return Vector2(x,float(y)/raw.get_height())
 return Vector2(x,(low+high)*.5)

func boundary_at_y(y: float,low: float,high: float,right: bool) -> Vector2:
 var raw: Image=assets.image("calico_clean")
 var first: int=int(low*raw.get_width());var last: int=int(high*raw.get_width())
 for i in range(last-first):
  var x: int=last-1-i if right else first+i
  if raw.get_pixel(x,int(y*raw.get_height())).a>.6:return Vector2(float(x)/raw.get_width(),y)
 return Vector2((low+high)*.5,y)

func add_object(type: String,rule: String,center: Vector2,drawn: Vector2) -> void:
 # Parent order setup still owns counters. Skip its unused dust/knot/trash
 # construction; this scene builds only explicit fur modules below.
 pass

func add_full_object(type: String,rule: String,center: Vector2,drawn: Vector2,angle: float=0.0,flip_h: bool=false,flip_v: bool=false) -> void:
 var raw: Image=assets.image(type)
 var mask:=Image.create(C.OBJECT_GRID,C.OBJECT_GRID,false,Image.FORMAT_RGBA8)
 # Source alpha is the only visual clipping. Collision samples do not cut sprites.
 mask.fill(Color.WHITE)
 var left:=PackedFloat32Array();left.resize(C.OBJECT_GRID*C.OBJECT_GRID)
 var count: int=0
 for y in range(C.OBJECT_GRID):
  for x in range(C.OBJECT_GRID):
   var sx: int=C.OBJECT_GRID-1-x if flip_h else x
   var sy: int=C.OBJECT_GRID-1-y if flip_v else y
   var valid: bool=raw.get_pixel(int((sx+.5)/C.OBJECT_GRID*raw.get_width()),int((sy+.5)/C.OBJECT_GRID*raw.get_height())).a>.12
   left[y*C.OBJECT_GRID+x]=float(valid);count+=int(valid)
 if count==0:return
 objects.append({"id":objects.size(),"type":type,"rule":rule,"rect":Rect2(body_rect.position+body_rect.size*center-drawn*.5,drawn),"draw_angle":angle,"mask":mask,"left":left,"initial":count,"sum":float(count),"version":0,"done":false,"passes":0,"travel":0.0,"dir":0.0,"axis":-1,"last_pass_dir":0.0,"last_pass_gesture":-1,"touching":false,"counted":false,"stroke_travel":0.0,"pull_amount":0.0,"last_touch":-100.0,"returning":false,"return_left":0.0,"return_from":0.0,"detach_pending":false})
 var obj: Dictionary=objects[-1];obj.flip_h=flip_h;obj.flip_v=flip_v
 index_object(obj)

func index_object(obj: Dictionary) -> void:
 var radius: float=obj.rect.size.length()*.5
 var low:=Vector2i(floori((obj.rect.get_center().x-radius)/80),floori((obj.rect.get_center().y-radius)/80))
 var high:=Vector2i(floori((obj.rect.get_center().x+radius)/80),floori((obj.rect.get_center().y+radius)/80))
 for gy in range(low.y,high.y+1):
  for gx in range(low.x,high.x+1):
   var cell:=Vector2i(gx,gy)
   if not layout_index.has(cell):layout_index[cell]=[]
   layout_index[cell].append(obj.id)

func outline_profile(type: String) -> Dictionary:
 if outline_profiles.has(type):return outline_profiles[type]
 # Source art has an inked outer edge and a soft, uninked inner seam.
 # Profile direction is in the unrotated sprite's coordinates, never the
 # required mouse movement direction. Curled tail art has its ink on the right.
 var outward: Vector2=Vector2.RIGHT if type.ends_with("tail") else Vector2.UP
 var raw: Image=assets.image(type)
 var ink: Array=[];var peak: float=-INF
 for y in range(64):
  for x in range(64):
   var color: Color=raw.get_pixel(int((x+.5)/64*raw.get_width()),int((y+.5)/64*raw.get_height()))
   if color.a<.65 or maxf(color.r,maxf(color.g,color.b))>.27:continue
   var local:=Vector2((x+.5)/64-.5,(y+.5)/64-.5)
   peak=maxf(peak,local.dot(outward));ink.append(local)
 var anchor:=Vector2.ZERO;var n: int=0
 for local in ink:
  if local.dot(outward)>=peak-.13:anchor+=local;n+=1
 if n>0:anchor/=float(n)
 else:anchor=outward*.35
 var profile: Dictionary={"outward":outward,"anchor":anchor}
 outline_profiles[type]=profile;return profile

func contour_normal(uv: Vector2,fallback: Vector2) -> Vector2:
 var raw: Image=assets.image("calico_clean")
 var normal:=Vector2.ZERO
 # Average a local alpha neighbourhood, avoiding a jagged single-pixel tangent.
 var radius: float=26.0*cat_scale
 for i in range(32):
  var direction:=Vector2.from_angle(TAU*i/32.0)
  var at: Vector2=uv+direction*radius/body_rect.size
  var alpha: float=0.0
  if at.x>=0 and at.x<1 and at.y>=0 and at.y<1:
   alpha=raw.get_pixel(int(at.x*raw.get_width()),int(at.y*raw.get_height())).a
  normal+=direction*(1.0-alpha)
 if normal.length()<.5 or normal.normalized().dot(fallback)<.20:return fallback
 return normal.normalized()

func add_outline(type: String,uv: Vector2,drawn: Vector2,fallback: Vector2) -> void:
 uv=snap_to_contour(uv,fallback)
 var profile: Dictionary=outline_profile(type)
 var normal: Vector2=contour_normal(uv,fallback)
 var source_out: Vector2=Vector2.UP
 var angle: float=normal.angle()+PI/2.0
 var boundary: Vector2=body_rect.position+body_rect.size*uv
 # Anchor the outer ink at the real boundary, with most of the sprite inside.
 var center: Vector2=boundary+normal*(OUTLINE_INK_OFFSET*cat_scale)-(profile.anchor*drawn).rotated(angle)
 # On concave belly/paw joins, a tangent alone can bridge empty background.
 # Reduce the whole source sprite until most coloured hair actually covers cat.
 var overlap: float=outline_body_overlap(type,center,drawn,angle)
 for attempt in range(8):
  if overlap>=.65 and outline_avoids_paws(type,center,drawn,angle):break
  drawn*=.86
  center=boundary+normal*(OUTLINE_INK_OFFSET*cat_scale)-(profile.anchor*drawn).rotated(angle)
  overlap=outline_body_overlap(type,center,drawn,angle)
 if overlap<.65 or not outline_avoids_paws(type,center,drawn,angle) or drawn.x<55.0*cat_scale:return
 add_full_object(type,"edge",(center-body_rect.position)/body_rect.size,drawn,angle)
 objects[-1].outline_tangent=Vector2.RIGHT.rotated(angle)
 objects[-1].outline_normal=normal
 objects[-1].outline_boundary=boundary
 objects[-1].outline_anchor=profile.anchor
 objects[-1].outline_outward=source_out
 objects[-1].outline_overlap=overlap

func outline_avoids_paws(type: String,center: Vector2,drawn: Vector2,angle: float) -> bool:
 var raw: Image=assets.image(type)
 for y in range(32):
  for x in range(32):
   if raw.get_pixel(int((x+.5)/32*raw.get_width()),int((y+.5)/32*raw.get_height())).a<.12:continue
   var p: Vector2=center+(drawn*(Vector2((x+.5)/32,(y+.5)/32)-Vector2(.5,.5))).rotated(angle)
   var uv: Vector2=(p-body_rect.position)/body_rect.size
   if paw_zone(uv) or paw_zone(uv+Vector2(Brush.MAX_PULL,0)/body_rect.size):return false
 return true

func outline_body_overlap(type: String,center: Vector2,drawn: Vector2,angle: float) -> float:
 var source: Image=assets.image(type)
 var body: Image=assets.image("calico_clean")
 var visible: int=0;var inside: int=0
 for y in range(24):
  for x in range(24):
   if source.get_pixel(int((x+.5)/24*source.get_width()),int((y+.5)/24*source.get_height())).a<.6:continue
   visible+=1
   var local:=drawn*(Vector2((x+.5)/24,(y+.5)/24)-Vector2(.5,.5))
   var at: Vector2=(center+local.rotated(angle)-body_rect.position)/body_rect.size
   if at.x>=0 and at.x<1 and at.y>=0 and at.y<1 and body.get_pixel(int(at.x*body.get_width()),int(at.y*body.get_height())).a>.15:inside+=1
 return float(inside)/maxi(1,visible)

func snap_to_contour(uv: Vector2,outward: Vector2) -> Vector2:
 var raw: Image=assets.image("calico_clean")
 var dimensions:=Vector2(raw.get_size())
 var origin:=Vector2i(uv*dimensions)
 var radius:=Vector2i(dimensions*.14)
 var step:=Vector2i(outward*2.0)
 var closest: Vector2=uv;var best: float=INF
 # The old limited scan could stop inside the coat at the end of its window.
 # Project that estimate onto a genuine opaque-to-transparent outer boundary.
 for y in range(maxi(0,origin.y-radius.y),mini(raw.get_height(),origin.y+radius.y),2):
  for x in range(maxi(0,origin.x-radius.x),mini(raw.get_width(),origin.x+radius.x),2):
   if raw.get_pixel(x,y).a<.6:continue
   var neighbour:=Vector2i(x,y)+step
   if neighbour.x>=0 and neighbour.y>=0 and neighbour.x<raw.get_width() and neighbour.y<raw.get_height() and raw.get_pixelv(neighbour).a>.2:continue
   var candidate:=Vector2(x,y)/dimensions
   var distance: float=((candidate-uv)*body_rect.size).length_squared()
   if distance<best:best=distance;closest=candidate
 return closest

func begin_gesture(at: Vector2=Vector2(INF,INF)) -> void:
 end_brush()
 super.begin_gesture(at)
 comb_armed=true

func end_brush() -> void:
 for obj in objects:
  if obj.get("touching",false) or obj.get("counted",false) or obj.get("stroke_travel",0.0)>0:release_lock(obj)

func release_lock(obj: Dictionary,rearm: bool=true) -> void:
 obj.touching=false
 if rearm:obj.counted=false;obj.stroke_travel=0.0
 if obj.pull_amount>0 and not obj.returning:start_return(obj)

func start_return(obj: Dictionary) -> void:
 obj.returning=true;obj.return_from=obj.pull_amount;obj.return_left=Brush.RETURN_TIME

func cleaning_progress() -> float:
 if not fur_ready:return super.cleaning_progress()
 if objects.is_empty():return 1.0
 var completed: float=0.0
 for obj in objects:
  completed+=1.0 if obj.done else minf(float(obj.passes)/Brush.PASSES,.95)
 return completed/objects.size()

func tick(dt: float) -> void:
 if not fur_ready:super.tick(dt);return
 if paused:return
 now+=dt;note_left=maxf(0,note_left-dt)
 if stage in ["arrival","reward","departure"]:
  advance_transition(dt);return
 for obj in objects:
  if obj.done:continue
  if not obj.returning and obj.pull_amount>0 and now-obj.last_touch>=Brush.IDLE_RELEASE:start_return(obj)
  if not obj.returning:continue
  obj.return_left=maxf(0,obj.return_left-dt)
  var t: float=obj.return_left/Brush.RETURN_TIME
  obj.pull_amount=obj.return_from*t*t*(3.0-2.0*t)
  if obj.return_left<=0:
   obj.pull_amount=0.0;obj.returning=false
   if obj.detach_pending:clear_object(obj)
 if stage=="cleaning":check_clean_finished()

func settle() -> int:
 var already: bool=settled
 var amount: int=super.settle()
 if settled and not already:
  stage_left=Brush.SERVICE_HOLD;customer_completed.emit(serial,amount)
 return amount

func advance_transition(dt: float) -> void:
 var remaining: float=dt
 while remaining>0 and stage in ["arrival","reward","departure"]:
  if stage=="reward" and not automatic_cycle:return
  var step: float=minf(remaining,stage_left)
  stage_left=maxf(0,stage_left-step);remaining-=step
  update_platform_pose()
  if stage_left>0:return
  match stage:
   "arrival":
    stage="cleaning";platform_offset=0;cat_inertia=0;customer_ready.emit(serial)
   "reward":stage="departure";stage_left=Brush.PLATFORM_LOWER_TIME
   "departure":customer_departed.emit(serial);start_order(0)

func update_platform_pose() -> void:
 cat_inertia=0
 if stage=="arrival":
  var t: float=clampf(1.0-stage_left/Brush.PLATFORM_RISE_TIME,0,1)
  if t<Brush.PLATFORM_RISE_FRACTION:
   var u: float=t/Brush.PLATFORM_RISE_FRACTION
   platform_offset=Brush.PLATFORM_TRAVEL*pow(1.0-u,3)
  else:
   var u: float=(t-Brush.PLATFORM_RISE_FRACTION)/(1.0-Brush.PLATFORM_RISE_FRACTION)
   # Platform is already at its highest point. The cat immediately continues
   # with one soft recoil, starting and ending with zero velocity (no kick).
   platform_offset=0.0
   cat_inertia=-Brush.CAT_INERTIA*16.0*u*u*(1.0-u)*(1.0-u)
 elif stage=="departure":
  var t: float=clampf(1.0-stage_left/Brush.PLATFORM_LOWER_TIME,0,1)
  platform_offset=Brush.PLATFORM_TRAVEL*t*t
 else:platform_offset=0

func stroke(a: Vector2,b: Vector2,dt: float,_measured_speed: float=-1.0) -> Dictionary:
 var result: Dictionary={"changed":0,"pain":false,"particle":"fall_gray_peel","point":b}
 if not fur_ready or paused or stage!="cleaning" or dt<=0 or a.distance_to(b)<.05:return result
 var delta: Vector2=b-a
 var forward: bool=delta.x/delta.length()>=C.COMB_DIRECTION_COS
 var area:=Rect2(a,Vector2.ZERO).expand(b).grow(Tool.EDGE_LENGTH*.5)
 for obj in objects:
  if obj.done or obj.detach_pending:continue
  var contact: bool=area.intersects(obj.rect.grow(maxf(obj.rect.size.x,obj.rect.size.y)*.25)) and object_contact(obj,a,b)
  if not forward:
   if obj.touching or obj.counted:release_lock(obj)
   continue
  if not contact:
   # Transparent gaps must not turn one forward sweep into several passes.
   if obj.touching:release_lock(obj,false)
   continue
  obj.touching=true;obj.last_touch=now;obj.returning=false
  obj.pull_amount=minf(Brush.MAX_PULL,obj.pull_amount+delta.x*Brush.PULL_PER_PIXEL)
  if obj.counted:continue
  obj.stroke_travel+=delta.length()*contact_fraction(obj,a,b)
  if obj.stroke_travel<Brush.PASS_TRAVEL:continue
  obj.counted=true;obj.passes+=1;obj.version+=1;result.changed+=1
  result.particle="fall_cream_peel" if obj.type.begins_with("cream") else "fall_gray_peel"
  if obj.passes>=Brush.PASSES:
   obj.detach_pending=true;start_return(obj)
  else:hint("已拉松 · 再从左向右梳一遍")
 if not forward:hint("请从左向右梳 →；返回时不会扣评")
 return result

func contact_fraction(obj: Dictionary,a: Vector2,b: Vector2) -> float:
 var lo: float=1.0;var hi: float=0.0
 for y in range(C.OBJECT_GRID):
  for x in range(C.OBJECT_GRID):
   if obj.left[y*C.OBJECT_GRID+x]<=0:continue
   var span: Vector2=Tool.coverage_interval(a,b,sample_point(obj,x,y))
   if span.y>span.x:lo=minf(lo,span.x);hi=maxf(hi,span.y)
 return maxf(0.0,hi-lo)

func build_edge_cover() -> Image:
 var cover:=Image.create(512,256,false,Image.FORMAT_RGBA8);cover.fill(Color(0,0,0,1))
 # Diagnostic footprint for coverage checks. It never alters the base ink
 # or the lock alpha; actual coverage is ordinary sprite compositing.
 for obj in objects:
  if obj.rule!="edge" or obj.done:continue
  var radius: float=obj.rect.size.length()*.5+18.0
  var center_uv: Vector2=(obj.rect.get_center()-body_rect.position)/body_rect.size
  var low:=Vector2i(maxi(0,int((center_uv.x-radius/body_rect.size.x)*512)),maxi(0,int((center_uv.y-radius/body_rect.size.y)*256)))
  var high:=Vector2i(mini(512,ceili((center_uv.x+radius/body_rect.size.x)*512)),mini(256,ceili((center_uv.y+radius/body_rect.size.y)*256)))
  for y in range(low.y,high.y):
   for x in range(low.x,high.x):
    var point: Vector2=body_rect.position+body_rect.size*Vector2((x+.5)/512,(y+.5)/256)
    var local: Vector2=(point-obj.rect.get_center()).rotated(-obj.draw_angle)
    var edge: float=maxf(absf(local.x)-obj.rect.size.x*.5,absf(local.y)-obj.rect.size.y*.5)
    var amount: float=clampf((18.0-edge)/8.0,0,1)
    if amount>cover.get_pixel(x,y).r:cover.set_pixel(x,y,Color(amount,0,0,1))
 return cover

func object_contact(obj: Dictionary,a: Vector2,b: Vector2) -> bool:
 if not fur_ready or kind=="robot":return super.object_contact(obj,a,b)
 for y in range(C.OBJECT_GRID):
  for x in range(C.OBJECT_GRID):
   if obj.left[y*C.OBJECT_GRID+x]<=0:continue
   var p: Vector2=sample_point(obj,x,y)
   if Tool.covered_length(a,b,p)>0:return true
 return false

func erase_segment(obj: Dictionary,a: Vector2,b: Vector2,resistance: float,one_pass: bool=false) -> int:
 if not fur_ready or kind=="robot":return super.erase_segment(obj,a,b,resistance,one_pass)
 var changed: int=0
 for y in range(C.OBJECT_GRID):
  for x in range(C.OBJECT_GRID):
   var i: int=y*C.OBJECT_GRID+x
   if obj.left[i]<=0:continue
   var p: Vector2=sample_point(obj,x,y)
   if Tool.covered_length(a,b,p)<=0:continue
   obj.sum-=obj.left[i];obj.left[i]=0;obj.mask.set_pixel(x,y,Color(0,0,0,1));changed+=1
 if changed>0:
  obj.version+=1
  if obj.sum/obj.initial<=C.FINISH_TOLERANCE:clear_object(obj)
 return changed
