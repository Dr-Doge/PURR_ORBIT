extends RefCounted
const CANVAS := Vector2(1920,1080)
const BODY_BOX := Rect2(160,155,1600,780)
const BODY_GRID := Vector2i(256,128)
const OBJECT_GRID := 32
const BRUSH_RADIUS := 48.0
const MAX_SPEED := 0.55 # calico only; robot permits rapid movement
const KNOT_SPEED := 0.22
const LIFT_SPEED := 0.35
const COMB_DIRECTION_COS := 0.70
const COMB_START_X := 0.50
const ROBOT_RESISTANCE := 3.0
const ROBOT_SOOT_PASSES := 3
const ROBOT_TAR_PASSES := 4
const NORMAL_RESISTANCE := 1.0
const KNOT_RESISTANCE := 1.55
const STICKY_PASSES := 2
const STICKY_TRAVEL := 0.6
const FINISH_TOLERANCE := 0.015
const PAIN_COST := 5
const PAIN_INTERVAL := 0.75
const DEEP_COST := 20
const ARRIVAL_TIME := 0.45
const NAIL_TRANSITION := 0.55
const REWARD_TIME := 1.15
const DEPARTURE_TIME := 0.35
const PARTICLE_LIMIT := 64
const PARTICLE_TIME := 0.45
const PAW_BOX := Rect2(490,350,930,670)
const CLAW_HEIGHT := 210.0
# Each anchor sits 25px inside its toe silhouette; the rest of the pink quick
# protrudes beyond the fur while the paw draws over the nail root.
const CLAW_ROOTS := [Vector2(757,476),Vector2(874,376),Vector2(1033,376),Vector2(1155,476)]
const NAIL_BAND_WIDTH := 42.0
const NAIL_ANGLE_TOLERANCE := 48.0
const ORDER_KINDS := ["calico","robot","calico"]
const ORDER_NAMES := ["三花猫 · 全身梳理","机器猫 · 机体擦拭","三花猫 · 梳理＋修甲"]
const ORDER_PAY := [100,120,150]
const ORDINARY_POINTS := [
 Vector2(0.43,0.49),Vector2(0.54,0.47),Vector2(0.66,0.49),Vector2(0.78,0.53),
 Vector2(0.87,0.63),Vector2(0.43,0.67),Vector2(0.55,0.66),Vector2(0.67,0.67),
 Vector2(0.79,0.72),Vector2(0.54,0.84),Vector2(0.70,0.82),Vector2(0.83,0.84)]

static func payment(base: int, score: int) -> int:
 return roundi(base*(0.25+0.75*clampf(score/100.0,0.0,1.0)))
