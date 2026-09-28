extends RefCounted
## New art is presentation-only; the existing model owns movement and harvest timing.
const FRAMES = preload("res://Art/cat1new_animations.tres")
const A = preload("res://scripts/cat_animation_data.gd")

static func step(state: Dictionary, model, c: Dictionary, motion: Vector2, walking: bool, dt: float) -> void:
 if not state.has("facing"):
  state.facing="side";state.side_flip=false
  state.groom_wait=9.0+float(c.id%7)
 if motion!=Vector2.ZERO:
  var target: String=("right" if motion.x>0 else "left") if absf(motion.x)>=absf(motion.y) else ("up" if motion.y<0 else "down")
  var current: String=("right" if state.side_flip else "left") if state.facing=="side" else state.facing
  if target==current:
   state.direction_distance=0.0;state.direction_target=target
  else:
   if state.get("direction_target","")!=target:state.direction_distance=0.0
   state.direction_target=target
   state.direction_distance=state.get("direction_distance",0.0)+maxf(absf(motion.x),absf(motion.y))
   # Preserve the pulled version's steering-jitter filter for all four directions.
   if state.direction_distance>=3.0:
    state.facing="side" if target in ["left","right"] else target
    if state.facing=="side":state.side_flip=target=="right"
    state.direction_distance=0.0
 elif not walking:state.direction_distance=0.0
 var clip: String=""
 if model.reacting(c):
  state.animation="produce";clip="produce"
 elif c.pet>0 and model.hovered(c):
  state.animation="pet";clip="pet"
 elif walking:
  state.animation="walk"
 else:
  state.animation="idle"
  if not model.hovered(c) and c.station==-1 and not c.dragging:
   state.groom_wait-=dt
   if state.get("clip","")=="groom" and state.age<A.duration("groom",FRAMES):clip="groom"
   elif state.groom_wait<=0:
    state.groom_wait=12.0+float(c.id%9);clip="groom"
 if clip=="":clip=state.animation+("_"+state.facing if state.facing!="side" else "")
 if state.get("clip","")!=clip:state.age=0.0
 state.clip=clip;state.frames=FRAMES
 state.flip=state.side_flip if state.facing=="side" or clip in ["pet","groom","produce"] else false
 if model.reacting(c):
  # Advance from the original model clock; faster art holds its last frame until unlock.
  state.age=maxf(0.0,A.reaction_duration(c.get("reaction_kind",c.kind))-c.reaction_left)
