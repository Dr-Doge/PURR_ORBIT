extends RefCounted
## IMP-20261016-004: all exact values below are prototype playtest choices.
const NORMAL_COUNT=Vector2i(8,14)
const STUBBORN_COUNT=Vector2i(2,3)
const NORMAL_TYPES=["fingerprints","oil"]
const STUBBORN_TYPES=["soot","tar"]
const OPACITY=Vector2(.45,.70)
const NORMAL_WIDTH=Vector2(.12,.18)
const STUBBORN_WIDTH=Vector2(.18,.24)
const MAX_ATTEMPTS=32
const MAX_RECT_OVERLAP=.42
const NORMAL_RESISTANCE=3.0
const STUBBORN_PASSES={"soot":4,"tar":5}
const PASS_TRAVEL=.50
const BASE_PAY=120
const DEFAULT_DEMO_SEED=6101604
const SERVICE=[
 Vector2(.46,.52),Vector2(.54,.46),Vector2(.69,.45),Vector2(.82,.50),
 Vector2(.88,.58),Vector2(.87,.68),Vector2(.80,.74),Vector2(.57,.75),
 Vector2(.46,.70),Vector2(.43,.61)]
const FALLBACK_COLUMNS=9
const FALLBACK_ROWS=6
