extends SceneTree

const MAIN := preload("res://scripts/ui/main.gd")
const STALL := preload("res://scripts/stall_demo/stall_demo.gd")

const EXPECTED_REGULAR := [9, 9, 12, 10, 12]
const EXPECTED_SMALL_SECRET := [1, 1, 1, 1, 1]
const EXPECTED_BIG_SECRET := [0, 0, 0, 1, 1]


func _init() -> void:
	var failed := false
	var stall := STALL.new()
	if not is_equal_approx(MAIN.FAT_PARTNER_REVIEW_YAW, deg_to_rad(-25.0)):
		push_error("肥嘟嘟伙伴没有采用正面朝向镜头后左转 25° 的展示角度。")
		failed = true
	if MAIN.SERIES.size() != 5:
		push_error("系列数量必须为5。")
		failed = true
	for series_index in MAIN.SERIES.size():
		var series: Dictionary = MAIN.SERIES[series_index]
		var items: Array = series["items"]
		var rarities: Array = series["rarities"]
		var weights: Array = series["weights"]
		var values: Array = series["values"]
		if items.size() != rarities.size() or items.size() != weights.size() or items.size() != values.size():
			push_error("%s 的items/rarities/weights/values长度不一致。" % series["name"])
			failed = true
			continue
		var model_paths: Array = MAIN.COLLECTIBLE_MODEL_PATHS[series_index]
		if model_paths.size() != items.size():
			push_error("%s 的内容物数量与新模型路径数量不一致。" % series["name"])
			failed = true
		else:
			for item_index in items.size():
				var model_path := String(model_paths[item_index])
				if not model_path.begins_with("res://assets/3D assets/") or model_path.contains("Bind_Box_Fever美术"):
					push_error("%s 仍在使用旧内容物路径：%s" % [series["name"], model_path])
					failed = true
				if not ResourceLoader.exists(model_path):
					push_error("找不到新内容物模型：%s" % model_path)
					failed = true
				else:
					var packed_model := load(model_path) as PackedScene
					if packed_model == null:
						push_error("新内容物模型无法作为场景加载：%s" % model_path)
						failed = true
					else:
						var model_instance := packed_model.instantiate()
						if model_instance == null:
							push_error("新内容物模型无法实例化：%s" % model_path)
							failed = true
						else:
							model_instance.free()
				var expected_name := _display_name_from_model_path(model_path)
				if String(items[item_index]) != expected_name:
					push_error("%s 的显示名应为“%s”，实际为“%s”。" % [model_path, expected_name, items[item_index]])
					failed = true
		var regular_weights: Array[int] = []
		var small_count := 0
		var big_count := 0
		var total_weight := 0
		for item_index in items.size():
			var rarity := int(rarities[item_index])
			var weight := int(weights[item_index])
			total_weight += weight
			if rarity == 0: regular_weights.append(weight)
			elif rarity == 4: small_count += 1
			elif rarity == 5: big_count += 1
			else:
				push_error("%s仍包含废止的稀有度索引%d。" % [series["name"], rarity])
				failed = true
		if regular_weights.size() != EXPECTED_REGULAR[series_index] or small_count != EXPECTED_SMALL_SECRET[series_index] or big_count != EXPECTED_BIG_SECRET[series_index]:
			push_error("%s的常规/小隐藏/大隐藏数量不符合策划。" % series["name"])
			failed = true
		for weight in regular_weights:
			if weight != regular_weights[0]:
				push_error("%s的常规款没有严格等概率。" % series["name"])
				failed = true
		var base_small_percent := float(weights[rarities.find(4)]) / float(total_weight) if small_count > 0 else 0.0
		var base_big_percent := float(weights[rarities.find(5)]) / float(total_weight) if big_count > 0 else 0.0
		if not is_equal_approx(base_small_percent, 0.05):
			push_error("%s的基础小隐藏概率不是5%%。" % series["name"])
			failed = true
		var expected_base_big := 0.01 if EXPECTED_BIG_SECRET[series_index] > 0 else 0.0
		if not is_equal_approx(base_big_percent, expected_base_big):
			push_error("%s的基础大隐藏概率不符合1%%规则。" % series["name"])
			failed = true
		var rarity_totals: Array = STALL.STALL_FIXED_RARITY_WEIGHTS[series_index]
		var stall_total := int(rarity_totals[0]) + int(rarity_totals[4]) + int(rarity_totals[5])
		var small_percent := float(rarity_totals[4]) / float(stall_total)
		var big_percent := float(rarity_totals[5]) / float(stall_total)
		if not is_equal_approx(small_percent, 0.05):
			push_error("%s的小隐藏概率不是5%%。" % series["name"])
			failed = true
		var expected_big_percent := 0.01 if EXPECTED_BIG_SECRET[series_index] > 0 else 0.0
		if not is_equal_approx(big_percent, expected_big_percent):
			push_error("%s的大隐藏概率不符合1%%规则。" % series["name"])
			failed = true
		var runtime_weights := stall.item_weights_for_series(series_index)
		var runtime_total := 0
		for weight in runtime_weights: runtime_total += weight
		var first_regular_weight := runtime_weights[0]
		for item_index in items.size():
			if int(rarities[item_index]) == 0 and runtime_weights[item_index] != first_regular_weight:
				push_error("%s运行时奖池没有严格平分常规款。" % series["name"])
				failed = true
		var runtime_small := float(runtime_weights[rarities.find(4)]) / float(runtime_total)
		if not is_equal_approx(runtime_small, 0.05):
			push_error("%s运行时小隐藏概率不是5%%。" % series["name"])
			failed = true
		if EXPECTED_BIG_SECRET[series_index] > 0:
			var runtime_big := float(runtime_weights[rarities.find(5)]) / float(runtime_total)
			if not is_equal_approx(runtime_big, 0.01):
				push_error("%s运行时大隐藏概率不是1%%。" % series["name"])
				failed = true
	stall.free()
	if failed:
		quit(1)
	else:
		print("SERIES_DATA_OK: 5 series, 59 named models, equal regular probabilities")
		quit(0)


func _display_name_from_model_path(model_path: String) -> String:
	var result := model_path.get_file().get_basename()
	var separator := result.find("-")
	if separator >= 0: result = result.substr(separator + 1)
	var style_markers := RegEx.new()
	style_markers.compile("\\s*[（(][^）)]*[）)]")
	return style_markers.sub(result, "", true).strip_edges()
