extends RefCounted
# Trial design: contact + resistance + duration, not a speed-triggered penalty.
const GRACE=.22
const RECOVERY_DELAY=.20
const RECOVERY_RATE=.85
const WARNING=.45
const ALERT=.75
const PAIN_INTERVAL=2.0
const PAIN_COST=3
const EXTREME_SPEED=3000.0
const KNOT_STALL_SPEED=850.0
var load: float=0.0
var grace_left: float=GRACE
var last_bad: float=-100.0
var protected_until: float=-100.0
var recoil_left: float=0.0
func reset() -> void:
 load=0.0;grace_left=GRACE;last_bad=-100.0;protected_until=-100.0;recoil_left=0.0
func recover(dt: float,now: float) -> void:
 recoil_left=maxf(0.0,recoil_left-dt)
 if now-last_bad>RECOVERY_DELAY:
  load=maxf(0.0,load-RECOVERY_RATE*dt)
  if load<=0.0:grace_left=GRACE
func strain(exposure: float,strength: float,now: float) -> bool:
 if exposure<=0.0 or strength<=0.0:return false
 last_bad=now
 var free: float=minf(grace_left,exposure);grace_left-=free
 load=minf(1.0,load+maxf(0.0,exposure-free)*strength)
 if load<1.0 or now<protected_until:return false
 load=.25;protected_until=now+PAIN_INTERVAL;recoil_left=.40
 return true
