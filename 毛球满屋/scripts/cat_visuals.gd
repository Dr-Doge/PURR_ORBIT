extends RefCounted
## Presentation-only animation state; never writes to the simulation or saves.
const FRAMES = preload("res://Art/cat1_animations.tres")
const GIANT_FRAMES = preload("res://Art/cat5_animations.tres")
const STATIC_FRAMES = preload("res://Art/cat8_animations.tres")
const LUCKY_FRAMES = preload("res://Art/cat10_animations.tres")
const Alien = preload("res://scripts/alien_cat_visuals.gd")
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
   states[c.id] = {"pos":c.pos,"layers":c.layers,"animation":"idle","age":0.0,"flip":false}
  var state: Dictionary = states[c.id]
  if c.kind != "alien": state.frames = GIANT_FRAMES if c.kind == "giant" else FRAMES
  if c.kind == "static":state.frames = STATIC_FRAMES
  if c.kind == "lucky":state.frames = LUCKY_FRAMES
  var movement: Vector2 = c.pos-state.pos
  var walking: bool = movement.length_squared()>0.000001 and not c.dragging and c.station == -1
  if walking and absf(movement.x)>0.001: state.flip = movement.x>0
  state.age += dt
  # A completed harvest clears stored layers. Growth alone must not play produce.
  if c.kind == "alien":
   Alien.step(state,walking,state.layers>0 and c.layers==0 and c.pop>0)
  elif state.layers>0 and c.layers==0 and c.pop>0:
   state.animation = "produce"
   state.age = 0.0
  elif state.animation != "produce" or state.age>=duration("produce",state.frames):
   var next: String = "walk" if walking else "idle"
   if state.animation != next:
    state.animation = next
    state.age = 0.0
  state.pos = c.pos
  state.layers = c.layers
 for id in states.keys():
  if not alive.has(id): states.erase(id)

func duration(animation: String, frames: SpriteFrames = FRAMES) -> float:
 return frames.get_frame_count(animation)/frames.get_animation_speed(animation)

func texture(id: int) -> Texture2D:
 var state: Dictionary = states.get(id,{"animation":"idle","age":0.0})
 var animation: String = state.animation
 var frames: SpriteFrames = state.get("frames",FRAMES)
 var count: int = frames.get_frame_count(animation)
 var frame: int = int(state.age*frames.get_animation_speed(animation))
 frame = frame%count if frames.get_animation_loop(animation) else mini(frame,count-1)
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
