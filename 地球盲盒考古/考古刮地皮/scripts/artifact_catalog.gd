extends RefCounted

const RARITY_NAMES := ["常规款", "", "", "", "小隐藏", "大隐藏"]
const SERIES := [
	{"name":"肥嘟嘟伙伴", "folder":"肥嘟嘟袋鼠", "prefix":"袋鼠", "color":Color("59c7b5"), "box_price":40, "items":["冬日暖意","度假搭档","煎扒厨师","骑士","人生一串","送达","外卖侠","外卖小哥","最爱甜筒","国王（小隐藏）"], "display":["冬日暖意","度假搭档","煎扒厨师","骑士","人生一串","送达","外卖侠","外卖小哥","最爱甜筒","国王"], "rarities":[0,0,0,0,0,0,0,0,0,4], "weights":[95,95,95,95,95,95,95,95,95,45], "values":[60,60,60,60,60,60,60,60,60,300]},
	{"name":"高雅企鹅", "folder":"高雅企鹅", "prefix":"高雅企鹅", "color":Color("8d66c7"), "box_price":96, "items":["厨子","钓鱼","滑板","卖萌","迷人","商务","摄影","休憩","炫技","国王（小隐藏）"], "display":["厨子","钓鱼","滑板","卖萌","迷人","商务","摄影","休憩","炫技","国王"], "rarities":[0,0,0,0,0,0,0,0,0,4], "weights":[95,95,95,95,95,95,95,95,95,45], "values":[144,144,144,144,144,144,144,144,144,1200]},
	{"name":"奶蛙生肖", "folder":"奶蛙", "prefix":"奶蛙", "color":Color("526cb7"), "box_price":240, "items":["子鼠","丑牛","寅虎","卯兔","辰龙","巳蛇","午马","未羊","申猴","酉鸡","戌狗","亥猪","奶蛙"], "display":["子鼠","丑牛","寅虎","卯兔","辰龙","巳蛇","午马","未羊","申猴","酉鸡","戌狗","亥猪","奶蛙"], "rarities":[0,0,0,0,0,0,0,0,0,0,0,0,4], "weights":[19,19,19,19,19,19,19,19,19,19,19,19,12], "values":[360,360,360,360,360,360,360,360,360,360,360,360,2400]},
	{"name":"牛来", "folder":"牛来", "prefix":"牛来", "color":Color("dc759b"), "box_price":520, "items":["豹拉","大牛来","坏狼A","坏狼B","牛爸爸","牛来","牛妈妈","普通牛","小绳头","云雀","票房王（小隐藏）","奥德牛斯（大隐藏）"], "display":["豹拉","大牛来","坏狼A","坏狼B","牛爸爸","牛来","牛妈妈","普通牛","小绳头","云雀","票房王","奥德牛斯"], "rarities":[0,0,0,0,0,0,0,0,0,0,4,5], "weights":[94,94,94,94,94,94,94,94,94,94,50,10], "values":[780,780,780,780,780,780,780,780,780,780,4000,20000]},
	{"name":"胖企鹅", "folder":"胖企鹅", "prefix":"胖企鹅", "color":Color("dd7048"), "box_price":1040, "items":["Debug","花花","酷酷","困困","摸鱼","派对","取景","蛙蛙","西部","嫌弃","音乐","宇宙","破壳（小隐藏）","胖大王（大隐藏） (1)"], "display":["Debug","花花","酷酷","困困","摸鱼","派对","取景","蛙蛙","西部","嫌弃","音乐","宇宙","破壳","胖大王"], "rarities":[0,0,0,0,0,0,0,0,0,0,0,0,4,5], "weights":[47,47,47,47,47,47,47,47,47,47,47,47,30,6], "values":[1560,1560,1560,1560,1560,1560,1560,1560,1560,1560,1560,1560,8000,24000]}
]

static func item(series_index: int, item_index: int) -> Dictionary:
	var series: Dictionary = SERIES[series_index]
	var filename := "%s-%s" % [series.prefix, series.items[item_index]]
	return {"series":series_index, "item_index":item_index, "series_name":series.name, "name":series.display[item_index], "rarity":int(series.rarities[item_index]), "price":int(series.values[item_index]), "color":series.color, "model_path":"res://assets/3D assets/%s/%s.fbx" % [series.folder, filename]}

static func roll_for_depth(depth: int, rng: RandomNumberGenerator) -> Dictionary:
	var series_index := clampi(depth, 0, SERIES.size() - 1)
	var series: Dictionary = SERIES[series_index]
	var total := 0
	for weight in series.weights: total += int(weight)
	var roll := rng.randi_range(1, total)
	for item_index in range(series.items.size()):
		roll -= int(series.weights[item_index])
		if roll <= 0: return item(series_index, item_index)
	return item(series_index, 0)

static func rarity_name(rarity: int) -> String:
	return RARITY_NAMES[rarity] if rarity >= 0 and rarity < RARITY_NAMES.size() else "常规款"
