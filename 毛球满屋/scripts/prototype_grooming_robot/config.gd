extends RefCounted
## IMP-20261016-004: all exact values below are prototype playtest choices.
const NORMAL_COUNT=Vector2i(8,14)
const STUBBORN_COUNT=Vector2i(2,3)
const NORMAL_TYPES=["fingerprints","oil"]
const STUBBORN_TYPES=["soot","tar"]
const OPACITY=Vector2(.45,.70)
const NORMAL_WIDTH=Vector2(.16,.23)
const STUBBORN_WIDTH=Vector2(.23,.30)
const MAX_ATTEMPTS=32
const MAX_RECT_OVERLAP=.65
const NORMAL_RESISTANCE=3.0
const STUBBORN_PASSES={"soot":8,"tar":10}
const PASS_TRAVEL=.50
const BASE_PAY=120
const DEFAULT_DEMO_SEED=6101604
const SERVICE=[
 Vector2(.30,.61),Vector2(.40,.57),Vector2(.46,.47),Vector2(.57,.43),
 Vector2(.75,.43),Vector2(.88,.50),Vector2(.93,.62),Vector2(.87,.76),
 Vector2(.72,.80),Vector2(.48,.79),Vector2(.35,.75),Vector2(.29,.66)]
const ZONES={
 "shoulder":Rect2(.31,.62,.18,.14),"back":Rect2(.50,.46,.32,.15),
 "belly":Rect2(.46,.65,.35,.14),"hind":Rect2(.78,.53,.13,.23)}
const NORMAL_ZONE_ORDER=["shoulder","back","belly","hind"]
const FALLBACK_COLUMNS=9
const FALLBACK_ROWS=6
