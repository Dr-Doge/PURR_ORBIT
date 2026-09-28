@tool
extends Node2D
## The same scene is visible in the editor and instantiated for live cats.
@export_enum("short","giant","static","lucky","alien") var kind: String="short"
func apply(room,c: Dictionary) -> void:
 var sprite: AnimatedSprite2D=$Animation
 var state: Dictionary=room.cat_visuals.states[c.id]
 kind=c.kind
 sprite.sprite_frames=state.frames
 sprite.animation=state.animation
 sprite.frame=room.cat_visuals.A.frame_at(state.animation,state.frames,state.age)
 sprite.flip_h=room.cat_visuals.flipped(c.id)
 sprite.modulate=Color("8cdf8e") if c.kind=="alien" else Color.WHITE
 var rect: Rect2=room.cat_rect(c)
 var factor: float=room.stage_scale()*0.9
 position=room.screen_position(c.pos)
 sprite.position=(rect.position-c.pos)*factor
 var texture: Texture2D=room.cat_visuals.texture(c.id)
 sprite.scale=rect.size/texture.get_size()*factor
