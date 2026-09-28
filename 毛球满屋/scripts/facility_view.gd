@tool
extends Node2D
@export_enum("feeder","sun","arcade","altar","worker") var kind: String="feeder":
 set(value):kind=value;queue_redraw()
const FEED_TEXTURE=preload("res://Art/Feed.png")
const LIGHT_TEXTURE=preload("res://Art/Light.png")
const INK=Color("e3efef")
const MINT=Color("91e2c6")
const GOLD=Color("f3ca86")
var model=preload("res://scripts/model.gd").new()
var clock: float=0
var interactive: bool=false
var pointer=Vector2.INF
var data: Dictionary={}
func apply(room,item: Dictionary) -> void:
 model=room.model;clock=room.clock;interactive=room.interactive;pointer=room.pointer-item.pos
 data=item.duplicate();data.pos=Vector2.ZERO
 position=room.screen_position(item.pos);scale=Vector2.ONE*room.stage_scale()*0.9
 queue_redraw()
func _draw() -> void:
 var item=data if not data.is_empty() else {"kind":kind,"id":-100,"pos":Vector2.ZERO,"grain":20,"bugs":0,"broken":false,"role":"general","status":"待命"}
 if kind=="worker":draw_worker(item)
 else:draw_facility(item)
func text(at: Vector2,value: String,sz: int=16,color: Color=INK) -> void:
 draw_string(ThemeDB.fallback_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,color)
func panel(rect: Rect2,color: Color,border: Color=Color.TRANSPARENT,radius: int=6) -> void:
 var style=StyleBoxFlat.new();style.bg_color=color;style.set_corner_radius_all(radius)
 if border.a>0:style.border_color=border;style.set_border_width_all(2)
 draw_style_box(style,rect)
func ellipse(at: Vector2,radius: Vector2,color: Color) -> void:
 var points=PackedVector2Array()
 for i in range(32):points.append(at+Vector2(cos(TAU*i/32),sin(TAU*i/32))*radius)
 draw_colored_polygon(points,color)
func draw_facility(f: Dictionary) -> void:
 var at: Vector2 = f.pos
 ellipse(at+Vector2(0,40),Vector2(64,15),Color(0.01,0.05,0.09,0.3))
 if f.kind == "feeder":

  pass # Authored Artwork Sprite2D renders the original image.
  text(at+Vector2(-47,70),"猫粮 %d/%d" % [f.grain,model.feed_capacity()],13,GOLD)
  if f.bugs > 0:
   panel(Rect2(at+Vector2(23,-57),Vector2(36,27)),Color("c96f78"))
   text(at+Vector2(29,-37),"虫！",14)
 elif f.kind == "sun":
  pass # Authored Artwork Sprite2D renders the original image.
  for side in [-1,1]:
   # New 1024px artwork: apertures at (306,165)/(718,165), platform center near (512,620).
   var bulb: Vector2=at+Vector2(side*40.234375,-77.7734375)
   var mouth:=Vector2(8.5,-side*1.8)
   var landing: Vector2=at+Vector2(side*16,11.09375)
   for spread in [1.25,1.0,0.75]:
    var points:=PackedVector2Array([bulb-mouth,bulb+mouth,landing+Vector2(24*spread,0),landing-Vector2(24*spread,0)])
    var colors:=PackedColorArray([Color(1.0,0.90,0.58,0.16),Color(1.0,0.90,0.58,0.16),Color(1.0,0.88,0.53,0.015),Color(1.0,0.88,0.53,0.015)])
    draw_polygon(points,colors)
   ellipse(landing,Vector2(26,15),Color(1.0,0.88,0.53,0.18))
   draw_line(bulb-mouth,bulb+mouth,Color(1.0,0.96,0.75,0.4),2.5)
  text(at+Vector2(-62,82),"日光浴  %d/%d" % [model.occupants(f.id).size(),model.capacity(f)],14,GOLD)
 elif f.kind == "arcade":
  panel(Rect2(at-Vector2(42,65),Vector2(84,111)),Color("766a9c"),Color("b7a5da"))
  panel(Rect2(at-Vector2(31,53),Vector2(62,51)),Color("101522") if f.broken else Color("32586a"))
  if not f.broken:
   text(at+Vector2(-23,-20),"=^.^=",17,MINT)
   draw_circle(at+Vector2(sin(clock)*15,-40),3,GOLD)
  draw_line(at+Vector2(17,23),at+Vector2(30,4),Color("c5cad6"),5)
  draw_circle(at+Vector2(30,4),7,Color("dc999b"))
  text(at+Vector2(-40,70),"黑屏 · 捶打" if f.broken else "猫用娱乐",14,Color("ee9da1") if f.broken else INK)
 elif f.kind == "altar":
  ellipse(at+Vector2(0,16),Vector2(80,45),Color("596780"))
  draw_arc(at,79,0,TAU,45,Color("b6a2e7"),3)
  for i in range(6):
   var q: Vector2 = at+Vector2.from_angle(i*TAU/6)*58
   draw_rect(Rect2(q-Vector2(5,5),Vector2(10,10)),Color("a9c8d2"))
  draw_colored_polygon(PackedVector2Array([at+Vector2(-25,5),at+Vector2(-18,-61),at+Vector2(0,-42),at+Vector2(19,-61),at+Vector2(27,5)]),Color("82aeaf"))
  for side in [-1,1]: draw_circle(at+Vector2(side*10,-20),5,Color("112d39"))
  text(at+Vector2(-64,76),"密语祭坛 %d/%d" % [model.occupants(f.id).size(),model.capacity(f)],14,Color("c6b0eb"))
 if pointer.distance_to(at) < 70 and interactive:
  draw_arc(at,85,0,TAU,40,Color(MINT,0.65),2)
func draw_worker(w: Dictionary) -> void:
 var at: Vector2 = w.pos
 ellipse(at+Vector2(0,18),Vector2(18,6),Color(0.02,0.06,0.1,0.2))
 var color := Color("b7cad5")
 draw_rect(Rect2(at+Vector2(-11,-13),Vector2(22,22)),color)
 draw_rect(Rect2(at+Vector2(-8,8),Vector2(16,13)),color.darkened(0.12))
 for side in [-1,1]:
  draw_rect(Rect2(at+Vector2(side*7-3,-5),Vector2(4,4)),Color("193944"))
  draw_line(at+Vector2(side*9,10),at+Vector2(side*17,4+sin(clock*5)*6),color,4)
 if w.role != "general":
  draw_rect(Rect2(at+Vector2(-15,-18),Vector2(30,5)),GOLD)
  draw_rect(Rect2(at+Vector2(-10,-27),Vector2(20,10)),GOLD)
 text(at+Vector2(-25,39),w.status,11,Color("a1b8c7"))
