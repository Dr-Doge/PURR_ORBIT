extends Node2D
const EDGE = preload("res://Art/static_cat_outline.gdshader")
var sprites: Dictionary = {}
var frames: Dictionary = {}
func update_outlines(room) -> void:
 if not visible:return
 var alive: Dictionary = {}
 for c in room.model.cats:
  if c.kind not in ["short","static"]:continue
  alive[c.id]=true
  if not sprites.has(c.id) or not is_instance_valid(sprites[c.id]):
   var sprite:=Sprite2D.new();sprite.centered=false
   var effect:=ShaderMaterial.new();effect.shader=EDGE;sprite.material=effect
   room.cat_nodes[c.id].add_child(sprite);sprites[c.id]=sprite
  var sprite: Sprite2D=sprites[c.id]
  var source: Texture2D=room.cat_visuals.texture(c.id)
  if not frames.has(source):frames[source]=ImageTexture.create_from_image(room.cat_visuals.read_frame_image(source))
  sprite.texture=frames[source]
  sprite.flip_h=room.cat_visuals.flipped(c.id)
  var rect: Rect2=room.cat_rect(c)
  var factor: float=room.object_scale(c.pos)
  sprite.position=(rect.position-c.pos)*factor
  sprite.scale=rect.size/sprite.texture.get_size()*factor
  # Soft periodic flashes, with a brighter peak during the produce animation.
  var pulse: float=pow(0.5-0.5*cos(room.clock*TAU/1.4),2.0)
  if room.cat_visuals.states.get(c.id,{}).get("animation","")=="produce":pulse=sqrt(pulse)
  sprite.material.set_shader_parameter("pulse",pulse if c.kind=="static" else 0.0)
 for id in sprites.keys():
  if not alive.has(id):
   if is_instance_valid(sprites[id]):sprites[id].queue_free()
   sprites.erase(id)
