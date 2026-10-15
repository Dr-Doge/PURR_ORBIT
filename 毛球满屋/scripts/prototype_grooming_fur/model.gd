extends "res://scripts/prototype_grooming/model.gd"
const FurAssets=preload("res://scripts/prototype_grooming_fur/assets.gd")
const PATCH_SIZE=Vector2(175,138)
const EDGE_RADIUS=5
const FLEA_CLICKS=3
const DUST_PASSES=2
var fur_ready: bool=false
var edge_mask: Image

func _init() -> void:
 super()
 assets=FurAssets.new();claw_spans=[];prepare_claw();fur_ready=true;start_order(0)

func start_order(index: int,nail_practice: bool=false) -> void:
 super.start_order(index,nail_practice)
 if not fur_ready:return
 if kind=="calico":
  title="灰白猫 · 分层梳理" if order_index==0 else "灰白猫 · 梳理＋修甲"
  if nail_practice:title="灰白猫 · 修甲练习";return
  objects=[];build_fur_objects()
  note="按住轻柔向右梳：毛块整片脱落；轮廓局部擦除。跳蚤点三下。"
  note_left=4.0

func build_body_mask() -> void:
 if not fur_ready:super.build_body_mask();return
 var raw: Image=assets.image(kind+"_clean").duplicate()
 raw.resize(C.BODY_GRID.x,C.BODY_GRID.y,Image.INTERPOLATE_NEAREST)
 body_mask=Image.create(C.BODY_GRID.x,C.BODY_GRID.y,false,Image.FORMAT_RGBA8)
 edge_mask=Image.create(C.BODY_GRID.x,C.BODY_GRID.y,false,Image.FORMAT_RGBA8)
 body_valid.resize(C.BODY_GRID.x*C.BODY_GRID.y)
 for y in range(C.BODY_GRID.y):
  for x in range(C.BODY_GRID.x):
   var uv:=Vector2(float(x)/C.BODY_GRID.x,float(y)/C.BODY_GRID.y)
   var valid: bool=raw.get_pixel(x,y).a>0.15
   body_valid[y*C.BODY_GRID.x+x]=int(valid)
   body_mask.set_pixel(x,y,Color(float(valid),0,0,1))
   if kind!="calico":continue
   var outside: bool=false;var inside: bool=false
   for dy in range(-EDGE_RADIUS,EDGE_RADIUS+1,2):
    for dx in range(-EDGE_RADIUS,EDGE_RADIUS+1,2):
     var xx: int=x+dx;var yy: int=y+dy
     if xx<0 or yy<0 or xx>=raw.get_width() or yy>=raw.get_height():outside=true
     elif raw.get_pixel(xx,yy).a>0.15:inside=true
     else:outside=true
   # Protect eyes, ears and toes; ragged overlays are only on fur outlines.
   var band: bool=inside and outside and uv.y>0.25 and uv.y<0.88
   edge_mask.set_pixel(x,y,Color(float(band),0,0,1))

func coat_at(uv: Vector2) -> String:
 var raw: Image=assets.image("calico_clean")
 var p: Color=raw.get_pixel(clampi(int(uv.x*raw.get_width()),0,raw.get_width()-1),clampi(int(uv.y*raw.get_height()),0,raw.get_height()-1))
 return "cream" if p.r>0.82 and p.g>0.79 and p.b>0.72 else "gray"

func build_fur_objects() -> void:
 var variants: Array=["ruffle","wide","fold","cross"]
 var count: int=0
 for row in range(5):
  for column in range(7):
   var uv:=Vector2(0.37+column*0.071+(0.018 if row%2 else 0.0),0.40+row*0.087)
   if not body_hit(uv):continue
   var type: String=coat_at(uv)+"_"+str(variants[count%4])
   add_object(type,"patch",uv,PATCH_SIZE);count+=1
 # No face stickers. Head hair and raised tail use the same matching palette.
 for uv in [Vector2(0.22,0.27),Vector2(0.30,0.32),Vector2(0.87,0.18),Vector2(0.92,0.37)]:
  if body_hit(uv):add_object(coat_at(uv)+"_fold","patch",uv,PATCH_SIZE)
 for item in [
  ["edge_gray_back",Vector2(.55,.365),Vector2(390,170)],
  ["edge_gray_back",Vector2(.70,.43),Vector2(340,170)],
  ["edge_gray_flank",Vector2(.80,.65),Vector2(220,270)],
  ["edge_cream_cheek",Vector2(.10,.58),Vector2(200,220)],
  ["edge_cream_belly",Vector2(.47,.83),Vector2(350,180)],
  ["edge_cream_belly",Vector2(.68,.83),Vector2(330,180)],
  ["edge_gray_tail",Vector2(.93,.47),Vector2(220,210)]]:
  add_outline(item[0],item[1],item[2])
 add_object("knot_gray","knot",Vector2(.56,.47),Vector2(150,135))
 add_object("knot_cream","knot",Vector2(.48,.72),Vector2(150,135))
 add_object("dust_gray","dust",Vector2(.75,.53),Vector2(145,110))
 add_object("dust_cream","dust",Vector2(.66,.75),Vector2(145,110))
 add_object("flea_idle","flea",Vector2(.72,.40),Vector2(92,78))
 objects[-1].home=objects[-1].rect.position

func add_outline(type: String,uv: Vector2,drawn: Vector2) -> void:
 var index: int=objects.size()
 # The normal object builder clips to the base; replace with a boundary mask,
 # allowing messy silhouette pixels outside the clean cat to be erased too.
 add_object(type,"edge",uv,drawn)
 if objects.size()==index:return
 var obj: Dictionary=objects[-1];var raw: Image=assets.image(type).duplicate()
 raw.resize(C.OBJECT_GRID,C.OBJECT_GRID,Image.INTERPOLATE_BILINEAR)
 obj.sum=0.0;obj.initial=0
 for y in range(C.OBJECT_GRID):
  for x in range(C.OBJECT_GRID):
   var p: Vector2=obj.rect.position+obj.rect.size*Vector2((x+.5)/C.OBJECT_GRID,(y+.5)/C.OBJECT_GRID)
   var v: Vector2=(p-body_rect.position)/body_rect.size
   var valid: bool=v.x>=0 and v.y>=0 and v.x<1 and v.y<1
   var amount: float=0.0
   if valid and raw.get_pixel(x,y).a>.08:
    amount=edge_mask.get_pixel(clampi(int(v.x*C.BODY_GRID.x),0,C.BODY_GRID.x-1),clampi(int(v.y*C.BODY_GRID.y),0,C.BODY_GRID.y-1)).r
   obj.left[y*C.OBJECT_GRID+x]=amount;obj.mask.set_pixel(x,y,Color(amount,0,0,1))
   obj.sum+=amount;obj.initial+=int(amount>0)
 if obj.initial==0:objects.pop_back()

func tick(dt: float) -> void:
 super.tick(dt)
 if not fur_ready or paused or kind!="calico" or stage!="cleaning":return
 for obj in objects:
  if obj.rule=="flea" and not obj.done:
   obj.rect.position=obj.home+Vector2(sin(now*3.0)*28.0,cos(now*4.0)*10.0)

func click_at(at: Vector2) -> Dictionary:
 var result: Dictionary={"changed":0,"particle":"fall_gray_wisps","point":at}
 if paused or stage!="cleaning" or kind!="calico":return result
 for obj in objects:
  if obj.rule!="flea" or obj.done or not obj.rect.grow(12).has_point(at):continue
  obj.passes+=1;obj.version+=1;result.changed=1
  hint("跳蚤 %d/%d"%[obj.passes,FLEA_CLICKS])
  if obj.passes>=FLEA_CLICKS:clear_object(obj);hint("跳蚤清除了！");check_clean_finished()
  break
 return result

func stroke(a: Vector2,b: Vector2,dt: float) -> Dictionary:
 if not fur_ready or kind=="robot":return super.stroke(a,b,dt)
 var result: Dictionary={"changed":0,"pain":false,"particle":"fall_gray_peel","point":b}
 if paused or stage!="cleaning" or dt<=0 or a.distance_to(b)<.05:return result
 var delta: Vector2=b-a;var speed: float=delta.length()/dt/body_rect.size.x
 var forward: bool=delta.x/delta.length()>=C.COMB_DIRECTION_COS
 if not forward:comb_armed=false
 elif (a.x-body_rect.position.x)/body_rect.size.x<=C.COMB_START_X:comb_armed=true
 var area:=Rect2(a,Vector2.ZERO).expand(b).grow(C.BRUSH_RADIUS)
 var touched: bool=false
 for obj in objects:
  if obj.done or obj.rule=="flea" or not area.intersects(obj.rect) or not object_contact(obj,a,b):continue
  touched=true
  if speed>C.MAX_SPEED:continue
  if obj.rule=="dust":
   if absf(delta.y)/delta.length()<.70:hint("灰尘上下轻扫 ↕");continue
   var dir: float=signf(delta.y)
   if obj.last_pass_dir==dir:continue
   if obj.dir!=dir:obj.travel=0.0;obj.dir=dir
   obj.travel+=minf(absf(delta.y),obj.rect.size.y)
   if obj.travel>=obj.rect.size.y*.50:
    obj.passes+=1;obj.travel=0;obj.last_pass_dir=dir;result.changed+=1
    hint("灰尘 %d/%d · 换向再扫"%[obj.passes,DUST_PASSES])
    if obj.passes>=DUST_PASSES:clear_object(obj)
   continue
  if not forward or not comb_armed:hint("从头侧开始，轻柔向尾巴梳 →");continue
  if obj.rule=="edge":result.changed+=erase_segment(obj,a,b,1.0,true);continue
  if obj.rule=="knot":
   if speed>C.KNOT_SPEED:hint("打结处更慢地向右梳 →");continue
   obj.travel+=covered_length(a,b,obj.rect.get_center(),C.BRUSH_RADIUS)
   if obj.travel<obj.rect.size.x*.70:continue
  # Whole-patch removal: the moving brush must cross the patch's core.
  if covered_length(a,b,obj.rect.get_center(),C.BRUSH_RADIUS)<=0:continue
  clear_object(obj);result.changed+=obj.initial
  result.particle="fall_cream_peel" if obj.type.begins_with("cream") or obj.type=="knot_cream" else "fall_gray_peel"
 if touched and speed>C.MAX_SPEED:result.pain=pain("太快了，轻一点 · 评价 -5")
 if result.changed>0:check_clean_finished()
 return result
