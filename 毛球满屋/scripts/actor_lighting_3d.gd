extends Node3D
## Alpha-tested animation cards cast actual per-frame shadows into the room.
var room
var sprites: Dictionary={}
var cards: Dictionary={}
var lamps: Dictionary={}
var seen: Dictionary={}
func _ready() -> void:
 for child in get_children():
  if child is Sprite3D:sprites[str(child.name)]=child
func ray_at(at: Vector2) -> Vector3:
 var ndc:=Vector4(at.x/room.size.x*2-1,1-at.y/room.size.y*2,-1,1)
 var p: Vector4=room.camera.get_camera_projection().inverse()*ndc
 return room.camera.global_basis*Vector3(p.x,p.y,p.z)/p.w
func floor_at(at: Vector2) -> Vector3:
 var ray: Vector3=ray_at(at)
 return room.camera.global_position+ray*(-room.camera.global_position.y/ray.y)
func place(key: String,texture: Texture2D,rect: Rect2,foot: Vector2,flipped: bool=false) -> void:
 seen[key]=true
 if not sprites.has(key):
  var actor:=Sprite3D.new();actor.name=key
  actor.shaded=true
  actor.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
  actor.alpha_scissor_threshold=0.35
  actor.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
  actor.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
  actor.double_sided=true
  var surface:=StandardMaterial3D.new()
  surface.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
  surface.alpha_scissor_threshold=0.35
  surface.cull_mode=BaseMaterial3D.CULL_DISABLED
  surface.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
  surface.roughness=1.0;surface.metallic_specular=0.0
  # Flat illustrated cards receive light but not their own shadow-map acne.
  # Their alpha silhouettes still cast detailed shadows onto the room.
  surface.disable_receive_shadows=true
  actor.material_override=surface
  add_child(actor);sprites[key]=actor
 var sprite: Sprite3D=sprites[key]
 sprite.texture=texture;sprite.flip_h=flipped
 sprite.material_override.albedo_texture=texture
 var ground: Vector3=floor_at(foot)
 var center_ray: Vector3=ray_at(rect.get_center())
 var eye: Vector3=room.camera.global_position
 sprite.position=eye+center_ray*((ground.z-eye.z)/center_ray.z)
 var unit: float=(eye.z-ground.z)*room.FRUSTUM_HEIGHT/room.size.y
 sprite.pixel_size=unit*rect.size.x/texture.get_width()
 sprite.scale=Vector3(1,rect.size.y/rect.size.x*texture.get_width()/texture.get_height(),1)
func procedural(key: String,entity: Dictionary,kind: String) -> Texture2D:
 if not cards.has(key):
  var viewport:=SubViewport.new();viewport.size=Vector2i(256,256)
  viewport.transparent_bg=true;viewport.disable_3d=true
  viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
  add_child(viewport)
  var card=preload("res://scripts/actor_card_3d.gd").new()
  viewport.add_child(card)
  cards[key]={"viewport":viewport,"card":card}
 var entry: Dictionary=cards[key]
 entry.card.model=room.model;entry.card.entity=entity;entry.card.actor_kind=kind
 entry.card.clock=room.clock;entry.card.queue_redraw()
 return entry.viewport.get_texture()
func sync() -> void:
 seen.clear()
 var active_lamps: Dictionary={}
 for c in room.model.cats:
  var factor: float=room.object_scale(c.pos)
  var rect: Rect2=room.cat_rect(c)
  var at: Vector2=room.screen_position(c.pos)
  place("Cat_%d"%c.id,room.cat_visuals.texture(c.id),Rect2(at+(rect.position-c.pos)*factor,rect.size*factor),at+Vector2(0,26)*factor,room.cat_visuals.flipped(c.id))
 for f in room.model.facilities:
  var key: String="Facility_%d"%f.id
  var factor: float=room.object_scale(f.pos)
  var at: Vector2=room.screen_position(f.pos)
  var texture: Texture2D
  var rect: Rect2
  if f.kind=="feeder":texture=room.FEED_TEXTURE;rect=Rect2(-78,-101,156,156)
  elif f.kind=="sun":texture=room.LIGHT_TEXTURE;rect=Rect2(-100,-110,200,200)
  else:texture=procedural(key,f,"facility");rect=Rect2(-128,-148,256,256)
  place(key,texture,Rect2(at+rect.position*factor,rect.size*factor),at+Vector2(0,40)*factor)
  if f.kind=="sun":
   active_lamps[key]=true
   if not lamps.has(key):
    var lamp:=SpotLight3D.new();lamp.name="SunLamp_%d"%f.id
    lamp.light_color=Color(1.0,0.84,0.58);lamp.light_energy=0.75
    lamp.spot_range=4.5;lamp.spot_angle=48;lamp.spot_attenuation=0.7
    lamp.shadow_enabled=true;lamp.shadow_bias=0.1;lamp.shadow_normal_bias=1.0
    lamp.shadow_opacity=0.35
    lamp.light_size=0.03;lamp.shadow_blur=0.5
    add_child(lamp);lamps[key]=lamp
   var base: Vector3=floor_at(at+Vector2(0,40)*factor)
   lamps[key].position=base+Vector3(-0.3,2.0,0.5)
   lamps[key].look_at(base)
 for w in room.model.workers:
  var key: String="Worker_%d"%w.id
  var factor: float=room.object_scale(w.pos)
  var at: Vector2=room.screen_position(w.pos)
  place(key,procedural(key,w,"worker"),Rect2(at+Vector2(-128,-148)*factor,Vector2(256,256)*factor),at+Vector2(0,18)*factor)
 if room.model.gacha_ready:
  var factor: float=room.object_scale(room.gacha_position)
  var at: Vector2=room.screen_position(room.gacha_position)
  place("Gacha",preload("res://Art/Gachapon.png"),Rect2(at-Vector2(88,129)*factor,Vector2(176,211)*factor),at+Vector2(0,70)*factor)
 for key in sprites.keys():
  if seen.has(key):continue
  sprites[key].queue_free();sprites.erase(key)
  if cards.has(key):cards[key].viewport.queue_free();cards.erase(key)
  if lamps.has(key):lamps[key].queue_free();lamps.erase(key)
 for key in lamps.keys():
  if not active_lamps.has(key):lamps[key].queue_free();lamps.erase(key)
