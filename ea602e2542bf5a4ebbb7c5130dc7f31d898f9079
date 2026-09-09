extends RefCounted
## EA v0.3 numeric draft; source of truth: planning document 06.
const Decimal = preload("res://scripts/ea/decimal.gd")
const Catalog = preload("res://scripts/artifact_catalog.gd")
const WIDTH := 512
const HEIGHT := 384
const WORLD := Vector2(1096,822)
const SCRAP_COUNT := 600
const ARTIFACT_COUNT := 8
const WEAR := 3.4
const FINISH := 0.98
const BASE_PRICES := [30,36,42,48,60]
const PHASE_SECONDS := [[8.0,12.0],[10.0,14.0],[12.0,16.0],[14.0,18.0],[16.0,20.0],[10.0,14.0]]
const NAMES := {"power":"铲子强度","radius":"铲子范围","auto":"机器人数量","auto_power":"机器人强度","auto_radius":"机器人范围","auto_move":"机器人移动","opening":"统一开盒速度"}
const LIMITS := {"power":-1,"radius":4,"auto":3,"auto_power":-1,"auto_radius":4,"auto_move":5,"opening":8}
const MACHINE_PRICES := [350,800,1600,3200,5000,8000]
const MACHINE_SECONDS := [20.0,24.0,28.0,32.0,36.0,24.0]
const MANUAL_SECONDS := [[8.0,3.0,5.0],[8.0,5.0,7.0],[10.0,6.0,8.0],[12.0,7.0,9.0],[14.0,8.0,10.0]]
const STAGES := [["连点剥土","来回甩沙","可选抛光"],["连点剥土","来回甩沙","可选抛光"],["连点剥土","来回甩沙","可选抛光"],["连点剥土","来回甩沙","可选抛光"],["连点剥土","来回甩沙","可选抛光"]]
const TALENTS := [
	{"id":"T00","name":"遗物档案","cost":1,"pre":"","effect":"显示各系列发现进度"},
	{"id":"T11","name":"异物轮廓","cost":2,"pre":"T00","effect":"强化异物轮廓，不识别系列"},
	{"id":"T12","name":"缺件追踪","cost":3,"pre":"T11","effect":"显示补齐保底进度"},
	{"id":"T21","name":"工序衔接","cost":2,"pre":"T00","effect":"剥土后自动切换甩沙工具"},
	{"id":"T22","name":"精品筛选","cost":3,"pre":"T21","effect":"筛选可精修藏品并显示加价"},
	{"id":"T31","name":"队列管理","cost":2,"pre":"T00","effect":"设置处理顺序，分析后可选系列"},
	{"id":"T32","name":"托管预设","cost":3,"pre":"T31","effect":"保存两套机器与自动出售设置"}]

static func growth(level: int, base: int = 1, multiplier: int = 118, places: int = 2) -> RefCounted:
	var result := Decimal.new(str(base))
	for i in range(level): result = result.times(multiplier,places)
	return result

static var latest_prices: Dictionary = {}

static func price(kind: String, level: int) -> RefCounted:
	if latest_prices.has(kind) and latest_prices[kind].level==level: return latest_prices[kind].value
	var value:=_uncached_price(kind,level)
	latest_prices[kind]={"level":level,"value":value}
	return value

static func _uncached_price(kind: String, level: int) -> RefCounted:
	match kind:
		"power": return growth(level,120).ceil_value()
		"auto_power": return growth(level,180).ceil_value()
		"radius": return growth(level,80,2,0).ceil_value()
		"auto": return growth(level,220,25,1).ceil_value()
		"auto_radius": return growth(level,160,2,0).ceil_value()
		"auto_move": return growth(level,140,2,0).ceil_value()
		"opening": return growth(level,300,18,1).ceil_value()
	return Decimal.new("0")

static func radius(level: int, robot: bool = false) -> float:
	return minf(22.0*pow(1.25,level),52.0) if robot else minf(18.0*pow(1.26,level),44.0)

static func move_speed(level: int) -> float: return minf(75.0*pow(1.31,level),280.0)
static func efficiency(level: int, depth: int) -> float:
	# Work on the difference; never divide two overflowing strength values.
	var difference := level-depth+1
	if difference>=1: return 4.0
	if difference==0: return 1.0
	# Clamp only at the floating-point representable tail, never a playable minimum.
	return pow(10.0,maxf(-300.0,3.0*difference))

static func model_item(series: int, variant: int) -> Dictionary:
	return Catalog.item(series,variant) # First five existing regular models per series.

static func series_name(series: int) -> String:
	return "S%02d · %s" % [series+1,Catalog.SERIES[series].name]
