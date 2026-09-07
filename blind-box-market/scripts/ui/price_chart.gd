extends Control

var prices: Array[float] = []
var dates: Array[int] = []
var line_color := Color("#62a8ff")
var compact := false

func setup(new_prices: Array[float], new_dates: Array[int], color: Color) -> void:
	prices = new_prices
	dates = new_dates
	line_color = color
	queue_redraw()

func _draw() -> void:
	if compact:
		_draw_compact_chart()
		return
	var font: Font = ThemeDB.fallback_font
	var rect := Rect2(Vector2(72, 18), size - Vector2(94, 72))
	draw_rect(rect, Color("#111820"), true)
	draw_line(rect.position, Vector2(rect.position.x, rect.end.y), Color("#82909c"), 2.0)
	draw_line(Vector2(rect.position.x, rect.end.y), rect.end, Color("#82909c"), 2.0)
	if prices.is_empty():
		draw_string(font, rect.get_center(), "暂无价格记录", HORIZONTAL_ALIGNMENT_CENTER, 180, 16, Color("#9ba8b3"))
		return
	var minimum: float = prices.min()
	var maximum: float = prices.max()
	if is_equal_approx(minimum, maximum):
		minimum = max(0.0, minimum * 0.8)
		maximum = max(1.0, maximum * 1.2)
	for i in 5:
		var ratio: float = i / 4.0
		var y: float = lerp(rect.end.y, rect.position.y, ratio)
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(0.3,0.36,0.42,0.35), 1.0)
		var price: float = lerp(minimum, maximum, ratio)
		draw_string(font, Vector2(4, y + 5), compact_number(price), HORIZONTAL_ALIGNMENT_RIGHT, 60, 12, Color("#aeb9c5"))
	var points := PackedVector2Array()
	for i in prices.size():
		var x_ratio: float = 0.5 if prices.size() == 1 else float(i) / float(prices.size() - 1)
		var y_ratio: float = (prices[i] - minimum) / (maximum - minimum)
		points.append(Vector2(lerp(rect.position.x, rect.end.x, x_ratio), lerp(rect.end.y, rect.position.y, y_ratio)))
	if points.size() == 1:
		draw_circle(points[0], 5.0, line_color)
	else:
		draw_polyline(points, line_color, 4.0, true)
		for point in points: draw_circle(point, 3.5, line_color.lightened(0.2))
	var label_step: int = max(1, int(ceil(dates.size() / 7.0)))
	for i in dates.size():
		if i % label_step != 0 and i != dates.size() - 1: continue
		var x_ratio: float = 0.5 if dates.size() == 1 else float(i) / float(dates.size() - 1)
		var x: float = lerp(rect.position.x, rect.end.x, x_ratio)
		draw_string(font, Vector2(x - 22, rect.end.y + 24), "第%d天" % dates[i], HORIZONTAL_ALIGNMENT_CENTER, 44, 11, Color("#aeb9c5"))
	draw_string(font, Vector2(8, 14), "市价", HORIZONTAL_ALIGNMENT_LEFT, 50, 13, Color("#e2c98f"))
	draw_string(font, Vector2(rect.end.x - 30, rect.end.y + 45), "日期", HORIZONTAL_ALIGNMENT_LEFT, 50, 13, Color("#e2c98f"))

func _draw_compact_chart() -> void:
	var rect := Rect2(Vector2(7, 7), size - Vector2(14, 14))
	draw_rect(rect, Color("#111820"), true)
	for row in 3:
		var y: float = lerpf(rect.position.y, rect.end.y, float(row) / 2.0)
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(0.45, 0.52, 0.58, 0.22), 1.0)
	if prices.is_empty(): return
	var minimum: float = prices.min()
	var maximum: float = prices.max()
	if is_equal_approx(minimum, maximum):
		minimum -= 1.0
		maximum += 1.0
	var points := PackedVector2Array()
	for index in prices.size():
		var x_ratio := 0.5 if prices.size() == 1 else float(index) / float(prices.size() - 1)
		var y_ratio := (prices[index] - minimum) / (maximum - minimum)
		points.append(Vector2(lerp(rect.position.x, rect.end.x, x_ratio), lerp(rect.end.y, rect.position.y, y_ratio)))
	if points.size() == 1:
		draw_circle(points[0], 4.0, line_color)
	else:
		draw_polyline(points, line_color, 3.0, true)
		for point in points: draw_circle(point, 2.5, line_color.lightened(0.18))

func compact_number(value: float) -> String:
	var magnitude := absf(value)
	if magnitude >= 100000000.0: return compact_unit(value, 100000000.0, "亿")
	if magnitude >= 1000000.0: return compact_unit(value, 1000000.0, "百万")
	if magnitude >= 10000.0: return compact_unit(value, 10000.0, "万")
	return comma_integer(int(round(value)))

func compact_unit(value: float, divisor: float, suffix: String) -> String:
	var number := "%.2f" % (value / divisor)
	while number.ends_with("0"): number = number.left(-1)
	if number.ends_with("."): number = number.left(-1)
	return "%s%s" % [number, suffix]

func comma_integer(value: int) -> String:
	var raw := str(absi(value))
	var result := ""
	for index in raw.length():
		if index > 0 and (raw.length() - index) % 3 == 0: result += ","
		result += raw[index]
	return "-" + result if value < 0 else result
