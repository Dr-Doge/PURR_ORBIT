extends RefCounted
## New art is presentation-only; the existing model owns movement and harvest timing.
const FRAMES = preload("res://Art/cat1new_animations.tres")
const A = preload("res://scripts/cat_animation_data.gd")

static func step(state: Dictionary, model, c: Dictionary, motion: Vector2, walking: bool, dt: float) -> void:
 if not state.has("facing"):
  state.facing="side";state.side_flip=false
  state.groom_wait=9.0+float(c.id%7)
 if motion!=Vector2.ZERO:
  if absf(motion.x)>=absf(motion.y):
   state.facing="side";state.side_flip=motion.x>0
  else:state.facing="up" if motion.y<0 else "down"
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
  state.age=maxf(0.0,A.duration("produce",FRAMES)-c.reaction_left)
