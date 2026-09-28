extends RefCounted
const FRAMES = preload("res://Art/cat14_animations.tres")

static func begin(state: Dictionary, animation: String) -> void:
 state.animation = animation
 state.age = 0.0
 state.from_y = state.get("float_y",0.0)

static func step(state: Dictionary, walking: bool, harvested: bool) -> void:
 if state.get("frames") != FRAMES:
  state.frames = FRAMES
  state.float_y = 0.0
  begin(state,"idle")
 if harvested:
  begin(state,"produce")
 elif state.animation == "produce":
  if state.age >= 1.7: begin(state,"lift" if walking else "idle")
 elif walking:
  if state.animation in ["idle","land"]: begin(state,"lift")
  elif state.animation == "lift" and state.age >= 0.4: begin(state,"hover")
 else:
  if state.animation in ["lift","hover"]: begin(state,"land")
  elif state.animation == "land" and state.age >= 0.4: begin(state,"idle")
 var age: float = state.age
 match state.animation:
  "lift":
   state.float_y = lerpf(state.from_y,-6.0,smoothstep(0.0,0.4,age))
  "hover":
   state.float_y = -6.0-2.0*sin(age*TAU/1.6)
  "land":
   state.float_y = lerpf(state.from_y,0.0,smoothstep(0.0,0.4,age))
  "produce":
   # The second frame begins retracting the legs; land for the last frame.
   var phase: float = smoothstep(0.1,1.6,age)
   state.float_y = lerpf(state.from_y,0.0,smoothstep(0.0,1.6,age))-8.0*sin(PI*phase)
  _:
   state.float_y = 0.0
