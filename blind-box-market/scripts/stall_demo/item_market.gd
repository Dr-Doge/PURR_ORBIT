extends RefCounted
## Deterministic synthetic market, not real stock data. Each item has its own
## persistent stochastic trajectory; asking prices never determine market value.
var histories: Dictionary = {}

func price(series: int, item: int, day: int, base: float, box_cost: int, hidden: bool, event_strength: Callable) -> int:
	var key := "%d:%d" % [series, item]
	if not histories.has(key): histories[key] = [base]
	var history: Array = histories[key]
	while history.size() < maxi(1, day):
		var date := history.size() + 1
		var random := RandomNumberGenerator.new()
		random.seed = 81173 + series * 193939 + item * 7919 + date * 104729
		var previous := float(history.back())
		var trend := random.randfn(0.0, 0.20 if not hidden else 0.14)
		var regime := RandomNumberGenerator.new()
		regime.seed = series * 71237 + item * 419 + int(date / 7) * 8911
		trend += regime.randf_range(-0.10, 0.07)
		trend += log(maxf(0.1, float(event_strength.call(date)))) * 0.25
		trend += log(base / previous) * 0.035
		if random.randf() < 0.08: trend += random.randf_range(-0.48, 0.40)
		var floor_price := box_cost * (1.05 if hidden else 0.15)
		history.append(clampf(previous * exp(trend), floor_price, base * 4.0))
	return maxi(1, int(round(history[maxi(0, day - 1)])))
