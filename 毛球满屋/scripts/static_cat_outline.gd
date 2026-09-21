extends Node2D
const EDGE = preload("res://Art/static_cat_outline.gdshader")
var sprites: Dictionary = {}
func update_outlines(room) -> void:
 var alive: Dictionary = {}
 for c in room.model.cats:
  if c.kind!="static":continue
  alive[c.id]=true
  if not sprites.has(c.id):
   var sprite:=Sprite2D.new();sprite.centered=false
   var effect:=ShaderMaterial.new();effect.shader=EDGE;sprite.material=effect
   add_child(sprite);sprites[c.id]=sprite
  var sprite: Sprite2D=sprites[c.id]
  sprite.texture=room.cat_visuals.texture(c.id)
  sprite.flip_h=room.cat_visuals.flipped(c.id)
  var extent: float=100.0*(1.0+minf(c.layers,8)*0.026)
  var factor: float=room.stage_scale()*0.9
  sprite.position=room.screen_position(c.pos)+Vector2(-extent/2.0,26.0-extent*0.80)*factor
  sprite.scale=Vector2.ONE*extent/sprite.texture.get_width()*factor
  # Soft periodic flashes, with a brighter peak during the produce animation.
  var pulse: float=0.15+0.85*pow(0.5+0.5*sin(room.clock*TAU/1.4),2.0)
  if room.cat_visuals.states.get(c.id,{}).get("animation","")=="produce":pulse=maxf(pulse,0.75)
  sprite.material.set_shader_parameter("pulse",pulse)
 for id in sprites.keys():
  if not alive.has(id):sprites[id].queue_free();sprites.erase(id)
