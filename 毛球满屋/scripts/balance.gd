extends RefCounted
## v0.27 playable calibration. Parameter IDs refer to design document 17, sections 12 and 13.5.1.
## Trial values, not a claim of a validated human completion time.
const BASE_YIELD = 3.0 # CAT-05
const STACK_BONUS = 1.0
const PRICE_GROWTH = {"short":1.48,"worker":1.55,"feeder":1.65,"sun":1.65,"arcade":1.65}
const BRANCH_GROWTH = 1.8
const FOOD_MULT = [1.65,1.95,2.25]
const FOOD_BATCH = 10
const FEED_RADIUS = 200.0
const FEED_EAT_TIME = 1.0
const FEED_REACH = 6.0
const FEED_COST = 1
const CAT_WALK_MIN = 2.0
const CAT_WALK_MAX = 6.0
const CAT_IDLE_MIN = 1.0
const CAT_IDLE_MAX = 3.5
const FEED_DURATION = 11.0
const FEED_CAPACITY = 80
const FEED_CAPACITY_STEP = 40
const GIANT_FED = 3.0
const GIANT_HUNGRY = 1.4
const TRANSFORM_BASE = 0.02
const TRANSFORM_STEP = 0.025
const STATIC_RADIUS = 185.0
const LUCKY_CHANCE = 0.5
const LUCKY_VALUE = 18.0
const SUN_TIME = 2.2
const SUN_SPEED_STEP = 0.30
const ENT_TIME = 5.0
const ENT_SPEED_STEP = 0.25
const ENT_WIN = 0.55
const ENT_WIN_STEP = 0.08
const ENT_VALUE = 90.0
const ENT_VALUE_STEP = 0.40
const BUG_COUNT = 3
const BUG_HITS = 2
const BUG_MULT = 0.65
const WORK_SPEED = 155.0
const WORK_REACH = 36.0
const HARVEST_BASE_TIME = 2.0 # Worker first-layer seconds; manual input uses pixels.
const HARVEST_CURVE_EXTRA = 2.0
const HARVEST_CURVE_DECAY = 0.7 # Trial saturation rate; extra=2 gives the confirmed 3x limit.
const PET_BASE_DISTANCE = 165.0
const PET_MAX_DISTANCE = 45.0
const PET_BREAK_TIME = 0.25
const WORK_POST_CD = 3.0
const WORK_CD_RATIO = 0.85
const WORK_CD_MIN = 0.6
const WORK_ACTION = 0.6
const WORK_STEP = 0.15
const REFILL_THRESHOLD = 12
const FIRST_TOKEN_LAYERS = 3
const DRAW_COST = 1
# Fixed cumulative production thresholds. Generated offline, never based on live play time.
const TOKEN_THRESHOLDS = [9.0, 520.0, 1480.0, 3700.0, 6430.0, 9080.0, 12520.0, 15960.0, 20040.0, 23740.0, 27680.0, 32030.0, 34710.0, 37350.0, 39990.0, 43070.0, 46510.0, 50130.0, 54860.0, 60350.0, 67130.0, 74290.0, 82440.0, 89090.0, 98550.0, 108840.0, 119820.0, 131600.0, 144760.0, 157980.0, 174320.0, 191430.0, 210050.0, 228840.0, 248590.0, 268190.0]
