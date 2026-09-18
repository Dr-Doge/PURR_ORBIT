extends RefCounted
## Space cats v0.26 demo parameters. Values are provisional, not final design.
const WORLD = Vector2(1440, 900)
const FLOOR = Rect2(88, 300, 1264, 438)
const MAX_ROUND = 3
const LAYER_CD = 6.0
const MAX_LAYERS = 8
const PET_DISTANCE = 110.0
const BUG_TIME = 38.0
const INTERFERENCE_TIME = 32.0
const NAMES = {"short":"短毛猫", "giant":"巨型猫", "static":"静电猫", "lucky":"招财猫", "alien":"外星猫", "worker":"毛球精灵", "feeder":"高能喂食器", "sun":"太空舷窗日光浴", "arcade":"猫用娱乐设施", "altar":"喵喵密语祭坛", "hats":"职责分配帽", "maint":"工人维护", "gacha":"未知文明的仪器"}
const RESEARCH = {
 "worker":{"round":1,"price":8,"pre":[],"pos":Vector2(1050,1900),"desc":"招募小帮手，接手收割与照料。"},
 "feeder":{"round":1,"price":18,"pre":["worker"],"pos":Vector2(260,1450),"desc":"范围喂食增产；需要补粮，可能转化巨型猫。"},
 "sun":{"round":1,"price":45,"pre":["feeder"],"pos":Vector2(260,750),"desc":"将CD中的猫拖进日光浴，快速长出新毛层。"},
 "hats":{"round":2,"price":60,"pre":["worker"],"pos":Vector2(1050,1100),"desc":"把固定工作交给固定工人。"},
 "arcade":{"round":2,"price":95,"pre":["feeder"],"pos":Vector2(1900,1200),"desc":"猫暂停长毛，按轮次赢取换金道具。"},
 "altar":{"round":3,"price":200,"pre":["arcade"],"pos":Vector2(1900,400),"desc":"指派猫提高全局生产速度，也会干扰娱乐设备。"},
 "maint":{"round":3,"price":95,"pre":["hats","altar"],"pos":Vector2(1050,180),"desc":"解锁工人维修黑屏设备的能力。"}}
const PRICES = {"short":12,"worker":20,"feeder":24,"sun":40,"arcade":65,"altar":110}
const BRANCHES = {
 "feeder":{"food":["高级猫粮",25,2],"transform":["巨型猫转化",30,4]},
 "sun":{"time":["日光浴速度",35,4],"capacity":["日光浴容量",40,4],"transform":["静电猫转化",40,4]},
 "arcade":{"win":["获奖概率",65,4],"time":["轮次速度",65,4],"value":["奖品价值",70,4],"transform":["招财猫转化",65,4]},
 "altar":{"capacity":["祭坛槽位",100,4],"speed":["单猫全局加成",100,4],"transform":["外星猫转化",95,4]}}
const FOOD_NAMES = ["标准猫条","高能冻干","星尘鱼罐头"]
const FOOD_PRICES = [6,12,18]
const ROLES = {"general":"自由照料","harvest":"抚摸收割","refill":"补充猫粮","sun":"日光浴搬运","clean":"清除蟑螂","arcade":"娱乐设施安排","altar":"祭坛指派","repair":"设备维护"}
const ITEMS = ["不存在的鱼骨","猫形黑洞门票","反重力纸箱","宇宙的逗猫棒","第九条尾巴"]
# Each round introduces NEW series. Every series has three unique artifacts.
const SERIES = [
 {"id":"r1_fur","round":1,"name":"柔软物质档案","effect":"yield","step":0.35,"label":"毛球产量","color":"e4bc76"},
 {"id":"r1_time","round":1,"name":"呼噜时间碎片","effect":"speed","step":0.12,"label":"毛层生长速度","color":"79d2cd"},
 {"id":"r2_hands","round":2,"name":"看不见的同伴","effect":"work","step":0.20,"label":"工人行动效率","color":"c2a2f0"},
 {"id":"r2_trade","round":2,"name":"星港交换记录","effect":"sale","step":0.20,"label":"道具出售价格","color":"ec9d84"},
 {"id":"r2_fur","round":2,"name":"猫绒星际物质","effect":"yield","step":0.30,"label":"毛球产量","color":"e4bc76"},
 {"id":"r3_time","round":3,"name":"猫眼里的光年","effect":"speed","step":0.15,"label":"毛层生长速度","color":"79d2cd"},
 {"id":"r3_hands","round":3,"name":"无声的帽子","effect":"work","step":0.20,"label":"工人行动效率","color":"c2a2f0"},
 {"id":"r3_trade","round":3,"name":"远方来信","effect":"sale","step":0.20,"label":"道具出售价格","color":"ec9d84"},
 {"id":"r3_fur","round":3,"name":"第一声喵","effect":"yield","step":0.35,"label":"毛球产量","color":"e4bc76"}]
static func title(key: String) -> String:
 return NAMES.get(key,key)
static func gate(key: String) -> int:
 return int(RESEARCH.get(key,{}).get("round",1))
static func collectible_name(key: String) -> String:
 for s in SERIES:
  for i in range(3):
   if key == s.id+":"+str(i): return s.name+" · "+["回声","印记","核心"][i]
 return key
