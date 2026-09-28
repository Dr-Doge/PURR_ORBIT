extends RefCounted
## Presentation-only animation state; never writes to the simulation or saves.
const Alien = preload("res://scripts/alien_cat_visuals.gd")
const A = preload("res://scripts/cat_animation_data.gd")
const FRAMES = A.FRAMES
const GIANT_FRAMES = A.GIANT_FRAMES
const STATIC_FRAMES = A.STATIC_FRAMES
const LUCKY_FRAMES = A.LUCKY_FRAMES
var states: Dictionary = {}
var source_model

func step(model, dt: float) -> void:
 if source_model != model:
  states.clear()
  source_model = model
 var alive: Dictionary = {}
 for c in model.cats:
  alive[c.id] = true
  if not states.has(c.id):
   states[c.id] = {"pos":c.pos,"layers":c.layers,"revision":c.get("harvest_revision",0),"animation":"idle","age":0.0,"flip":false,"motion_tick":-1,"displaced":false}
  var state: Dictionary = states[c.id]
  var visual_kind: String = c.get("reaction_kind",c.kind) if model.reacting(c) else c.kind
  if visual_kind != "alien":
   state.frames = A.frames_for(visual_kind)
   state.float_y = 0.0
  var movement: Vector2 = c.pos-state.pos
  var tick_motion: Vector2=model.cat_displacements.get(c.id,Vector2.ZERO)
  # Repeated render updates must not erase this simulation step's movement.
  # A position change takes priority over idle, even if hover/control changed afterwards.
  if state.motion_tick!=model.motion_tick:
   state.motion_tick=model.motion_tick;state.displaced=false
  state.displaced=state.displaced or movement!=Vector2.ZERO
  var walking: bool=state.displaced or tick_motion!=Vector2.ZERO
  if walking and absf(movement.x)>0.001: state.flip = movement.x>0
  state.age += dt
  # Simulation owns this clock, including pause/load/offscreen and animation interruption.
  if visual_kind == "alien":
   if model.reacting(c):
    if state.get("frames") != Alien.FRAMES: Alien.step(state,false,false)
    if state.animation != "produce": Alien.begin(state,"produce")
    # Retiming the presentation preserves the remote simulation's reaction clock.
    var total: float = A.reaction_duration(c.get("reaction_kind",c.kind))
    state.age = clampf(1.0-c.reaction_left/total,0.0,0.99999)*duration("produce",Alien.FRAMES)
    Alien.step(state,walking,false)
   else:
    if state.animation == "produce": Alien.begin(state,"lift" if walking else "idle")
    Alien.step(state,walking,false)
  elif model.reacting(c):
   state.animation = "produce"
   state.age = maxf(0.0,duration("produce",state.frames)-c.reaction_left)
  else:
   var next: String = "walk" if walking else "idle"
   if state.animation != next:
    state.animation = next
    state.age = 0.0
  state.pos = c.pos
  state.layers = c.layers
  state.revision=c.get("harvest_revision",0)
 for id in states.keys():
  if not alive.has(id): states.erase(id)

func duration(animation: String, frames: SpriteFrames = FRAMES) -> float:
 return A.duration(animation,frames)

func texture(id: int) -> Texture2D:
 var state: Dictionary = states.get(id,{"animation":"idle","age":0.0})
 var animation: String = state.animation
 var frames: SpriteFrames = state.get("frames",FRAMES)
 var frame: int = A.frame_at(animation,frames,state.age)
 return frames.get_frame_texture(animation,frame)

func flipped(id: int) -> bool:
 return states.get(id,{}).get("flip",false)

var foot_anchors: Dictionary = {}
func foot_anchor(id: int) -> float:
 var frame: Texture2D=texture(id)
 if states.get(id,{}).get("frames") == Alien.FRAMES:
  frame = Alien.FRAMES.get_frame_texture("idle",0)
 if not foot_anchors.has(frame):
  var bounds: Rect2i=frame.get_image().get_used_rect()
  foot_anchors[frame]=float(bounds.end.y)/frame.get_height()
 return foot_anchors[frame]

func visual_offset(id: int) -> Vector2:
 return Vector2(0.0,states.get(id,{}).get("float_y",0.0))
