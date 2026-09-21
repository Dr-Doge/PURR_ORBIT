extends Node2D
const COIN = preload("res://Art/Coin.png")
const LIFETIME = 2.1
var room
func pose(event: Dictionary) -> Dictionary:
 var age: float=event.age
 var factor: float=room.stage_scale()
 var origin: Vector2=room.screen_position(event.pos)+Vector2(0,-68)*factor
 var destination: Vector2=room.stage_origin()+Vector2(1250,137)*factor
 var travel: float=smoothstep(0.85,1.85,age)
 var position: Vector2=origin.lerp(destination,travel)+Vector2(0,-sin(travel*PI)*75)*factor
 var diameter: float=lerpf(12.0,62.0,1.0-pow(1.0-clampf(age/0.35,0,1),3.0))
 diameter=lerpf(diameter,16.0,travel)
 var alpha: float=1.0-smoothstep(1.85,LIFETIME,age)
 return {"position":position,"diameter":diameter*factor,"alpha":alpha,"travel":travel}
func _draw() -> void:
 if room==null:return
 for event in room.effects:
  if event.kind!="token":continue
  var state: Dictionary=pose(event)
  var at: Vector2=state.position
  var radius: float=state.diameter*0.57
  var flash: float=0.55+0.45*sin(event.age*TAU*3.0)
  var glow: float=state.alpha*(1.0-state.travel*0.8)
  for i in range(4,0,-1):
   draw_circle(at,radius*(1.0+i*0.24),Color(0.55,0.90,1.0,glow*(0.025+flash*0.02)))
  for i in range(8):
   var angle: float=event.age*2.8+i*TAU/8.0
   var direction:=Vector2.from_angle(angle)
   var across:=direction.orthogonal()
   var base: Vector2=at+direction*radius*0.8
   var tip: Vector2=at+direction*radius*(1.5+flash*0.25)
   draw_colored_polygon(PackedVector2Array([base-across*radius*0.12,tip,base+across*radius*0.12]),Color(0.72,0.95,1.0,glow*(0.25+flash*0.45)))
  draw_texture_rect(COIN,Rect2(at-Vector2.ONE*state.diameter/2.0,Vector2.ONE*state.diameter),false,Color(1,1,1,state.alpha))
