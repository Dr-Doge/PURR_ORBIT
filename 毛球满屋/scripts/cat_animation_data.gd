extends RefCounted
## One resource definition for model reaction cooldown and visible produce frames.
const FRAMES = preload("res://Art/cat1_animations.tres")
const GIANT_FRAMES = preload("res://Art/cat5_animations.tres")
const STATIC_FRAMES = preload("res://Art/cat8_animations.tres")
const LUCKY_FRAMES = preload("res://Art/cat10_animations.tres")
static func frames_for(kind: String) -> SpriteFrames:
 match kind:
  "giant":return GIANT_FRAMES
  "static":return STATIC_FRAMES
  "lucky":return LUCKY_FRAMES
 return FRAMES
static func duration(animation: String,frames: SpriteFrames) -> float:
 var units: float=0.0
 for i in range(frames.get_frame_count(animation)):units+=frames.get_frame_duration(animation,i)
 return units/frames.get_animation_speed(animation)
static func reaction_duration(kind: String) -> float:
 return duration("produce",frames_for(kind))
static func frame_at(animation: String,frames: SpriteFrames,age: float) -> int:
 var time: float=maxf(age,0.0)
 if frames.get_animation_loop(animation):time=fmod(time,duration(animation,frames))
 var units: float=time*frames.get_animation_speed(animation)
 for i in range(frames.get_frame_count(animation)):
  units-=frames.get_frame_duration(animation,i)
  if units<0:return i
 return frames.get_frame_count(animation)-1
