extends RefCounted
## Purr Orbit / 毛球计划 v0.27 demo parameters. Values are provisional, not final design.
const WORLD = Vector2(1440, 900)
const FLOOR = Rect2(88, 300, 1264, 438)
const MAX_STAGE = 2
const SERIES_SIZE = 6
const B = preload("res://scripts/balance.gd")
const LAYER_CD = 10.0
const MAX_LAYERS = 8
const MIN_LAYERS = 1
const CAT_MOVE_SPEED = 16.0
const CAT_PULSE_DURATION = 0.35
const CAT_PULSE_AMOUNT = 0.16
const CAT_LAYER_SIZE_STEP = 0.026
const BUG_TIME = 90.0
const INTERFERENCE_TIME = 32.0
const NAMES = {"short":"短毛猫", "giant":"巨型猫", "static":"静电猫", "lucky":"招财猫", "alien":"外星猫", "worker":"毛球精灵", "feeder":"高能喂食器", "sun":"太空舷窗日光浴", "arcade":"猫用娱乐设施", "altar":"喵喵密语祭坛", "hats":"职责分配帽", "maint":"工人维护", "gacha":"未知文明的仪器"}
const RESEARCH = {
 "worker":{"round":1,"price":35,"pre":[],"pos":Vector2(1050,1900),"desc":"招募小帮手，接手收割与照料。"},
 "feeder":{"round":1,"price":350,"pre":["worker"],"pos":Vector2(260,1450),"desc":"猫自主前来进食，获得持续增产；需要补粮，可能转化巨型猫。"},
 "sun":{"round":1,"price":6000,"pre":["feeder"],"pos":Vector2(260,750),"desc":"将CD中的猫拖进日光浴，快速长出新毛层。"},
 "hats":{"round":2,"price":900,"pre":["worker"],"pos":Vector2(1050,1100),"desc":"把固定工作交给固定工人。"},
 "arcade":{"round":2,"price":16000,"pre":["feeder"],"pos":Vector2(1900,1200),"desc":"猫暂停长毛，按轮次赢取换金道具。"},
 "altar":{"round":3,"price":200,"pre":["arcade"],"pos":Vector2(1900,400),"desc":"指派猫提高全局生产速度，也会干扰娱乐设备。"},
 "maint":{"round":3,"price":95,"pre":["hats","altar"],"pos":Vector2(1050,180),"desc":"解锁工人维修黑屏设备的能力。"}}
const PRICES = {"short":30,"worker":45,"feeder":300,"sun":3000,"arcade":12000}
const BRANCHES = {
 "worker":{"efficiency":["轻快步伐",160,6],"harvest_layers":["积攒层数收割",120,7],"cooldown":["收割CD缩减",180,6]},
 "feeder":{"food":["高级猫粮",500,2],"transform":["巨型猫转化",650,4],"capacity":["扩充料仓",450,4]},
 "sun":{"time":["日光浴速度",1600,4],"capacity":["日光浴容量",1200,4],"transform":["静电猫转化",1800,4]},
 "arcade":{"win":["获奖概率",3500,4],"time":["轮次速度",4000,4],"value":["奖品价值",4500,4],"transform":["招财猫转化",3000,4]}}
const FOOD_NAMES = ["标准猫条","高能冻干","星尘鱼罐头"]
const FOOD_PRICES = [6,12,18]
const ROLES = {"general":"自由照料","harvest":"抚摸收割","refill":"补充猫粮","sun":"日光浴搬运","clean":"清除蟑螂","arcade":"娱乐设施安排"}
const ITEMS = ["不存在的鱼骨","猫形黑洞门票","反重力纸箱","宇宙的逗猫棒","第九条尾巴"]
# Six collections; full-set strength is split across six pieces, never copied per piece.
const SERIES = [
 {"id":"s1_fur","round":1,"name":"柔软物质档案","effect":"yield","full":0.60,"label":"毛球产量","color":"e4bc76"},
 {"id":"s1_time","round":1,"name":"呼噜时间碎片","effect":"speed","full":0.24,"label":"毛层生长速度","color":"79d2cd"},
 {"id":"s2_hands","round":2,"name":"看不见的同伴","effect":"work","full":0.45,"label":"工人行动效率","color":"c2a2f0"},
 {"id":"s2_trade","round":2,"name":"星港交换记录","effect":"sale","full":0.60,"label":"道具出售价格","color":"ec9d84"},
 {"id":"s2_fur","round":2,"name":"猫绒星际物质","effect":"yield","full":0.60,"label":"毛球产量","color":"e4bc76"},
 {"id":"s2_time","round":2,"name":"猫眼里的光年","effect":"speed","full":0.24,"label":"毛层生长速度","color":"79d2cd"}]
static func title(key: String) -> String:
 return NAMES.get(key,key)
static func gate(key: String) -> int:
 return int(RESEARCH.get(key,{}).get("round",1))
static func collectible_name(key: String) -> String:
 for s in SERIES:
  for i in range(SERIES_SIZE):
   if key == s.id+":"+str(i): return s.name+" · "+["回声","印记","微光","涟漪","梦境","核心"][i]
 return key

static func branch_effect(subject: String,key: String,level: int) -> String:
 match subject+":"+key:
  "worker:efficiency": return "行动效率 +%d%%" % (level*15)
  "worker:harvest_layers": return "至少 %d 层接单" % mini(MAX_LAYERS,1+level)
  "worker:cooldown": return "产出后CD %.2f 秒" % maxf(B.WORK_CD_MIN,B.WORK_POST_CD*pow(B.WORK_CD_RATIO,level))
  "feeder:capacity": return "料仓 %d 份" % (B.FEED_CAPACITY+level*B.FEED_CAPACITY_STEP)
  "feeder:food": return FOOD_NAMES[level]
  "sun:time": return "处理速度 +%d%%" % (level*30)
  "sun:capacity": return "%d 个位置" % (2+level)
  "arcade:win": return "中奖率 %d%%" % (55+level*8)
  "arcade:time": return "每轮 %.1f 秒" % (B.ENT_TIME/(1+level*B.ENT_SPEED_STEP))
  "arcade:value": return "奖品基础价值 %d" % (B.ENT_VALUE*(1+level*B.ENT_VALUE_STEP))
 if key=="transform": return "转化概率 %.1f%%" % ((B.TRANSFORM_BASE+level*B.TRANSFORM_STEP)*100)
 return ""
