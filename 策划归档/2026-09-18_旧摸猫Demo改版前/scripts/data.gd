extends RefCounted
## Implemented candidates from design 00 v0.9. Undefined token mechanics stay disabled.
const ORDER = ["start","spirit","long","wand","static","heater","spark","lucky"]
const NAMES = {"start":"徒手与短毛猫","hand":"徒手","short":"短毛猫","long":"长毛猫","static":"静电猫","lucky":"招财猫","spirit":"毛球精灵","spark":"静电精灵","wand":"固定逗猫棒","heater":"电暖炉","bed":"蓬松猫窝","post":"猫抓柱","bell":"幸运猫铃架"}
const RESEARCH = [0,0,20,5,60,10,40,150]
const CATS = {"short":{"need":100.0,"yield":1.0,"price":5,"branch":10,"colors":["三花","奶牛","橘色"]},"long":{"need":180.0,"yield":3.0,"price":25,"branch":24,"colors":["纯白","纯黑","银虎纹"]},"static":{"need":120.0,"yield":2.0,"price":80,"branch":32,"colors":["橘白","银灰虎斑","黑白"]},"lucky":{"need":240.0,"yield":0.0,"price":200,"branch":60,"colors":["白底三花","纯白","招财金"]}}
const TOOLS = {"spirit":12,"spark":80,"wand":15,"heater":25}
const BRANCHES = {"hand":["yield","double","drop","quality","sale"],"short":["yield","double","move","drop","quality","cap"],"long":["yield","double","move","token","quality","cap"],"static":["yield","double","move","range","cap"],"lucky":["yield","double","move","drop","quality","cap"],"spirit":["cd","speed","token","yield","move","drop","quality","cap"],"spark":["cd","range","token","yield","move","drop","quality","cap"],"wand":["range","yield","cap"],"heater":["range","yield","cap"]}
const LABELS = {"yield":"产毛量","double":"双倍概率","move":"移动速度","drop":"物品掉率","quality":"物品品质","cap":"持有上限","sale":"物品售价","cd":"工作间隔","speed":"抚摸速度","range":"作用范围","token":"代币概率"}
const COLLECTIBLES = ["薛定谔的欠条","猫猫辞职信","一根祖传网线","量子纸箱","地毯所有权证","液态猫样本"]
const ITEMS = ["羽毛狂欢券","金色毛球贴","幸运小铃铛"]
static func title(key: String) -> String: return NAMES.get(key,key)
static func branch(subject: String, key: String) -> Dictionary:
	var base: float = 8; var growth: float = 1.6; var cap: int = 5
	if key == "token" or (subject == "lucky" and key in ["yield","double","drop","quality"]): return {"base":0,"growth":1.0,"cap":0}
	if CATS.has(subject):
		base = CATS[subject].branch
		if key in ["yield","range"]: cap = 3
	elif subject == "hand": base = {"yield":4,"double":8,"drop":8,"quality":12,"sale":16}[key]
	elif subject == "spirit":
		if key == "cap": base = 10
		if key in ["speed","cd"]: growth = 1.5
	elif subject == "spark":
		base = 30
		if key == "range": base = 24; cap = 3; growth = 1.5
		if key == "cd": growth = 1.5
		if key == "cap": base = 40; cap = 3
	elif subject == "wand":
		growth = 1.5; cap = 3 if key != "yield" else 5
		if key == "cap": base = 15; growth = 1.6
	elif subject == "heater":
		base = 12 if key == "range" else 16; growth = 1.5; cap = 3
		if key == "cap": base = 25; growth = 1.6
	return {"base":base,"growth":growth,"cap":cap}
