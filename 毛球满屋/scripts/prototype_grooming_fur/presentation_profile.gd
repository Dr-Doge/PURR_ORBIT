extends Resource
## Replaceable presentation contract; all geometry is in 1920x1080 logical pixels.
@export var room_texture: Texture2D
@export var table_texture: Texture2D
@export var cat_texture: Texture2D
## Optional explicit hand-authored contours. Null keeps procedural fallback.
@export var outline_layout: PackedScene
@export var table_rect:=Rect2(-100,550,2120,1193)
@export var cat_fit_rect:=Rect2(100,105,1720,870)
@export var cat_name: String="灰白猫"
@export var service_chest:=PackedVector2Array([Vector2(.01,.59),Vector2(.39,.58),Vector2(.44,.68),Vector2(.38,.88),Vector2(.30,.91),Vector2(.16,.90),Vector2(.07,.81),Vector2(.01,.69)])
@export var service_body:=PackedVector2Array([Vector2(.465,.345),Vector2(.66,.38),Vector2(.78,.46),Vector2(.86,.62),Vector2(.875,.82),Vector2(.79,.915),Vector2(.53,.93),Vector2(.35,.88),Vector2(.33,.79),Vector2(.40,.60),Vector2(.46,.46)])
@export var service_tail:=PackedVector2Array([Vector2(.74,.015),Vector2(.88,.005),Vector2(.97,.08),Vector2(.999,.24),Vector2(.99,.51),Vector2(.94,.67),Vector2(.86,.715),Vector2(.79,.56),Vector2(.785,.39),Vector2(.73,.32),Vector2(.69,.18)])
@export var paw_exclusions: Array[PackedVector2Array]=[
 PackedVector2Array([Vector2(.14,.88),Vector2(.25,.88),Vector2(.255,.995),Vector2(.14,.995)]),
 PackedVector2Array([Vector2(.253,.902),Vector2(.39,.902),Vector2(.39,1),Vector2(.253,1)]),
 PackedVector2Array([Vector2(.495,.911),Vector2(.625,.911),Vector2(.625,1),Vector2(.495,1)]),
 PackedVector2Array([Vector2(.627,.914),Vector2(.79,.897),Vector2(.81,1),Vector2(.627,1)])]
@export var outline_paths: Array[Dictionary]=[
 {"name":"chest_left","region":"chest","side":1,"points":PackedVector2Array([Vector2(.015,.60),Vector2(.045,.70),Vector2(.085,.80),Vector2(.14,.855),Vector2(.22,.89)])},
 {"name":"body_back","region":"body","side":-1,"points":PackedVector2Array([Vector2(.465,.345),Vector2(.60,.36),Vector2(.73,.41),Vector2(.81,.50),Vector2(.86,.61),Vector2(.865,.76),Vector2(.84,.845)])},
 {"name":"body_belly","region":"body","side":1,"points":PackedVector2Array([Vector2(.38,.88),Vector2(.43,.92),Vector2(.49,.927),Vector2(.55,.91),Vector2(.62,.915),Vector2(.70,.90),Vector2(.78,.88),Vector2(.84,.845)])},
 {"name":"tail_rim","region":"tail","side":-1,"points":PackedVector2Array([Vector2(.75,.07),Vector2(.83,.02),Vector2(.90,.08),Vector2(.95,.20),Vector2(.985,.32),Vector2(.985,.47),Vector2(.95,.60),Vector2(.90,.65),Vector2(.835,.62),Vector2(.79,.54),Vector2(.805,.40),Vector2(.79,.34),Vector2(.73,.30),Vector2(.70,.22),Vector2(.71,.14),Vector2(.75,.07)])}]

func validation_errors() -> PackedStringArray:
 var errors:=PackedStringArray()
 for key in ["room_texture","table_texture","cat_texture"]:
  var tex: Texture2D=get(key)
  if tex==null or tex.get_width()<=0 or tex.get_height()<=0:errors.append(key+": missing or empty texture")
 if table_rect.size.x<=0 or table_rect.size.y<=0:errors.append("table_rect: invalid dimensions")
 if cat_fit_rect.size.x<=0 or cat_fit_rect.size.y<=0:errors.append("cat_fit_rect: invalid dimensions")
 for key in ["service_chest","service_body","service_tail"]:
  var polygon: PackedVector2Array=get(key)
  if polygon.size()<3:errors.append(key+": needs at least 3 UV points")
  for uv in polygon:
   if uv.x<0 or uv.x>1 or uv.y<0 or uv.y>1:errors.append(key+": UV outside 0..1")
 for polygon in paw_exclusions:
  if polygon.size()<3:errors.append("paw_exclusions: invalid polygon")
 for path in outline_paths:
  if not path.has("points") or path.points.size()<2:errors.append("outline_paths: missing polyline")
 return errors
