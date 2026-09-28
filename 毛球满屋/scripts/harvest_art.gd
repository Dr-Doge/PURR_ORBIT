extends Node2D
const GACHA = preload("res://Art/Gachapon.png")
const FUR = preload("res://Art/Furryball.png")
const CUTOUT = preload("res://Art/imported_art.gdshader")
var machine: Sprite2D
var particles: Array[Sprite2D] = []
var badges: Array[Sprite2D] = []
var cutout: ShaderMaterial
func _ready() -> void:
 cutout=ShaderMaterial.new();cutout.shader=CUTOUT
 machine=Sprite2D.new();machine.texture=GACHA
 add_child(machine);machine.hide()
func fur_sprite() -> Sprite2D:
 var sprite:=Sprite2D.new();sprite.texture=FUR;sprite.material=cutout
 sprite.region_enabled=true;sprite.region_rect=Rect2(250,210,530,540)
 add_child(sprite)
 return sprite
func badge_position(room,at: Vector2,kind: String,layers: int,index: int) -> Vector2:
 var extent: float=100.0*(1.35 if kind=="giant" else 1.0)*(1.0+minf(layers,room.D.MAX_LAYERS)*room.D.CAT_LAYER_SIZE_STEP)
 return room.screen_position(at)+Vector2(extent*0.2+index*12.0,26.0-extent*0.72)*room.object_scale(at)
func update_art(room) -> void:
 var scale_factor: float=room.object_scale(room.gacha_position)
 machine.visible=room.model.gacha_ready
 # Use the PNG's own alpha; extend the body vertically without widening it.
 machine.position=room.screen_position(room.gacha_position)+Vector2(0,-23)*scale_factor
 machine.scale=Vector2(1.0,1.2)*(176.0/1024.0)*scale_factor
 var badge_count: int=0
 for c in room.model.cats:
  for i in range(int(c.layers)):
   if badge_count==badges.size():badges.append(fur_sprite())
   var badge: Sprite2D=badges[badge_count];badge_count+=1
   badge.position=badge_position(room,c.pos,c.kind,c.layers,i)
   badge.scale=Vector2.ONE*(11.0/530.0)*room.object_scale(c.pos)
   badge.show()
 for i in range(badge_count,badges.size()):badges[i].hide()
 var used: int=0
 for e in room.effects:
  if e.kind!="money" or room.reduced:continue
  var count: int=int(e.get("fur_count",0))
  for i in range(count):
   if used==particles.size():
    particles.append(fur_sprite())
   var particle: Sprite2D=particles[used];used+=1
   var t: float=clampf((e.age-i*0.07)/1.1,0.0,1.0)
   var start: Vector2=badge_position(room,e.pos,e.get("cat_kind","short"),count,i)
   var destination: Vector2=room.reward_target()
   particle.position=start.lerp(destination,t)+Vector2(sin(t*PI)*(i-(count-1)*0.5)*8,-sin(t*PI)*60)*room.stage_scale()
   particle.scale=Vector2.ONE*(lerpf(11.0,15.0,smoothstep(0.0,0.12,t))/530.0)*scale_factor
   particle.modulate=Color(1,1,1,1.0-smoothstep(0.8,1.0,t))
   particle.visible=t<1.0
 for i in range(used,particles.size()):particles[i].hide()
