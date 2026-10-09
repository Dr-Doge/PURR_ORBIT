extends RefCounted
## IMP-20261009-001. All values are prototype playtest choices, not final balance.
const TRANSITION = 0.6
const RATE_WINDOW = 10.0
const BODY_RADIUS = Vector2(0.46, 0.28)
const HIT_RADIUS = 0.018
const CHAIN_RADIUS = 0.08
const KING_CLICKS = 6
const KING_MULTIPLIER = 20
const KING_RATES = [0.02, 0.04]
const WORKER_COST = 20
const BUFF_COST = 20
const DECOR_COST = 5
const BUFF_MULTIPLIER = 1.5
const KNOT_RADIUS = 0.08
const KNOT_DISTANCE = 0.8
const KNOT_REVERSALS = 2
const FLEA_TIME = 12.0
const FLEA_CLICKS = 6
const FLEA_STEAL_INTERVAL = 1.0
const FLEA_STEAL_COUNT = 2
const FLEA_HOLD = 0.4
const FLEA_SPEED = 0.48
const FLEA_RADIUS = 0.04
const EVENT_INTERVALS = {"knot":45.0,"flea":60.0}
const MILESTONES = {"fast":80,"knot":150,"special":220,"flea":300}
const CATS = {
 "normal":{"name":"团团 · 普通猫","rate":1.0,"value":1,"art":"short"},
 "fast":{"name":"闪闪 · 快生长样本","rate":2.0,"value":1,"art":"static"},
 "special":{"name":"刺刺 · 手动样本","rate":1.0,"value":2,"art":"giant"}
}
const NODES = [
 {"key":"yield","name":"单根增产","costs":[10,30],"prereq":"","description":"新长出的每根毛 +1 价值；旧毛不变"},
 {"key":"grow","name":"生长提速","costs":[15,40],"prereq":"","description":"每级全猫生长频率 ×1.25"},
 {"key":"touch","name":"移动触碰","costs":[25],"prereq":"yield","description":"鼠标移动扫过普通毛头即可收取"},
 {"key":"chain","name":"一跳连锁","costs":[20],"prereq":"grow","description":"手动摘毛同时收取周围普通毛"},
 {"key":"king","name":"毛王发现","costs":[20],"prereq":"yield","description":"新毛 2% 为毛王；连点 6 次拔出"},
 {"key":"king_rate","name":"毛王概率","costs":[40],"prereq":"king","description":"毛王概率升至 4%"},
 {"key":"worker","name":"猫身小帮手","costs":[30],"prereq":"touch","description":"开放招募；每名另需 20 毛球"},
 {"key":"worker_rate","name":"小帮手效率","costs":[20,40],"prereq":"worker","description":"每级工作频率 ×1.25"},
 {"key":"buff","name":"船舱设施","costs":[20],"prereq":"grow","description":"开放生长灯与无属性装饰购买"}
]
const STAGES = [
 {"name":"S01 单猫随机长毛","intro":"点击毛头赚毛球。停手观察长毛；滚轮向下回船舱，悬停猫向上放大。","cats":["normal"],"counts":[20],"research":[],"wallet":0,"workers":0,"cabin":false},
 {"name":"S02 收割工具进化","intro":"先单点，再打开成长树购买触碰与连锁。45 毛球恰好购买两项。","cats":["normal"],"counts":[150],"research":["yield","grow"],"wallet":45,"workers":0,"cabin":false},
 {"name":"S03 毛王爆发收获","intro":"连点金色毛王 6 次；移动触碰与小帮手不能代替。再提升出现概率。","cats":["normal"],"counts":[60],"research":["king"],"wallet":40,"workers":0,"cabin":false},
 {"name":"S04 多猫产能与船舱buff","intro":"比较两猫，购买生长灯并指派目标；装饰不增加收益。","cats":["normal","fast"],"counts":[40,40],"research":["buff"],"wallet":25,"workers":0,"cabin":true},
 {"name":"S05 猫身自动化","intro":"招募、指派小帮手，再购买效率。切到另一只猫，原猫继续工作。","cats":["normal","fast"],"counts":[80,80],"research":["worker","chain"],"wallet":40,"workers":0,"cabin":false},
 {"name":"S06 毛发打结","intro":"毛结只锁局部。按住左键来回刷，至少两次反向；其他区域照常摘毛。","cats":["normal","fast"],"counts":[100,100],"research":["worker","chain"],"wallet":20,"workers":1,"cabin":false},
 {"name":"S07 偷毛贼来袭","intro":"跳蚤出现后本猫暂停所有收割。连点击败追回赃物；可重试观察逃跑。","cats":["normal","fast"],"counts":[200,80],"research":["worker","chain"],"wallet":20,"workers":1,"cabin":false},
 {"name":"S08 特殊猫与综合循环","intro":"给手动样本指派小帮手观察缩毛损失，再撤下手动摘毛；其他猫持续生产。","cats":["normal","fast","special"],"counts":[100,100,100],"research":["worker","chain","king","buff"],"wallet":40,"workers":2,"cabin":true}
]
