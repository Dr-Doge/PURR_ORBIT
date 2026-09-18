extends RefCounted
## v0.3.2 EA candidates, sourced from planning document 06. Not final balance.
const PLANETS = [
	{"name":"灰砾卫星", "regions":8, "stock":200.0, "factor":0.5, "vault":800.0, "hp":100.0, "armor":0.0, "treasure":"部族航路碑", "sale":200, "aa":0, "silo":0, "color":"477276"},
	{"name":"铸铁殖民星", "regions":16, "stock":1500.0, "factor":2.0, "vault":12000.0, "hp":600.0, "armor":200.0, "treasure":"熔铸王冠", "sale":2000, "aa":2, "silo":1, "color":"8b6750"},
	{"name":"堡垒巨星", "regions":24, "stock":9000.0, "factor":5.0, "vault":84000.0, "hp":3000.0, "armor":1000.0, "treasure":"星核圣匣", "sale":20000, "aa":4, "silo":2, "color":"716487"}]
const HULLS = {
	"frigate":{"name":"轻型护卫舰", "price":80, "cmd":1, "slots":2, "hp":120.0, "armor":30.0, "branch":80, "research":0},
	"cruiser":{"name":"中型巡洋舰", "price":400, "cmd":2, "slots":4, "hp":450.0, "armor":120.0, "branch":300, "research":200},
	"battleship":{"name":"重型战列舰", "price":1600, "cmd":3, "slots":6, "hp":1400.0, "armor":500.0, "branch":1000, "research":1000},
	"destroyer":{"name":"歼星舰", "price":12000, "cmd":5, "slots":8, "hp":4000.0, "armor":0.0, "branch":4000, "research":4000},
	"carrier":{"name":"空天母舰", "price":300, "cmd":1, "slots":2, "hp":300.0, "armor":80.0, "branch":200, "research":0}}
const WEAPONS = {
	"kinetic":{"name":"轻型动能火炮", "price":20, "armor":2.0, "hp":10.0, "extract":10.0, "reload":1.0, "branch":100, "research":0},
	"aa":{"name":"防空炮台", "price":50, "armor":0.0, "hp":12.0, "extract":0.0, "reload":0.6, "branch":150, "research":100},
	"ap":{"name":"穿甲贫铀炮台", "price":80, "armor":30.0, "hp":5.0, "extract":5.0, "reload":1.5, "branch":240, "research":100},
	"laser":{"name":"固定激光炮台", "price":220, "armor":0.0, "hp":120.0, "extract":120.0, "reload":4.0, "branch":600, "research":400},
	"neutron":{"name":"歼星级中子炮", "price":8000, "armor":800.0, "hp":1200.0, "extract":1200.0, "reload":18.0, "branch":4000, "research":4000}}
const GEAR = {
	"plate":{"name":"装甲衬板", "price":40, "branch":120, "research":0},
	"repair":{"name":"损管舱", "price":40, "branch":120, "research":0},
	"energy":{"name":"装填供能器", "price":100, "branch":400, "research":200}}
const COMMAND = [6,12,24,48]
const COMMAND_COST = [600,5000,30000]
const CHAIN = ["kinetic","aa","ap","laser","neutron"]
static func title(key: String) -> String:
	for table in [HULLS, WEAPONS, GEAR]:
		if table.has(key): return table[key].name
	return {"command":"舰队指挥", "hangar":"母舰机库", "cargo":"掠袭舰货舱", "speed":"掠袭舰航速", "special":"中子特殊槽", "nuclear_auto":"中子自动火控", "raider":"掠袭舰"}.get(key,key)
static func module_price(key: String) -> int:
	return int(WEAPONS.get(key,GEAR.get(key,{"price":0})).price)
