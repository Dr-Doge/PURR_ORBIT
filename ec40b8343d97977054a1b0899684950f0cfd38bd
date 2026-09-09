extends RefCounted
## Nonnegative exact base-ten decimal. No floating-point wallet or exponent cap.
## digits * 10^-places; all economy operations use integer digit arithmetic.
var digits := "0"
var places := 0

func _init(value: String = "0", fractional_places: int = 0) -> void:
	digits = value
	places = fractional_places
	_normalize()

func _normalize() -> void:
	while digits.length() > 1 and digits.begins_with("0"): digits = digits.substr(1)
	while places > 0 and digits.ends_with("0"):
		digits = digits.left(-1)
		places -= 1
	if digits.is_empty() or digits == "0":
		digits = "0"
		places = 0

func clone() -> RefCounted: return get_script().new(digits, places)

func compare(other: RefCounted) -> int:
	var scale := maxi(places, other.places)
	var a := digits + "0".repeat(scale-places)
	var b: String = other.digits + "0".repeat(scale-other.places)
	a = a.lstrip("0"); b = b.lstrip("0")
	if a.length() != b.length(): return 1 if a.length() > b.length() else -1
	if a == b: return 0
	return 1 if a > b else -1

func plus(other: RefCounted) -> RefCounted:
	var scale := maxi(places, other.places)
	var a := digits + "0".repeat(scale-places)
	var b: String = other.digits + "0".repeat(scale-other.places)
	var i := a.length()-1
	var j := b.length()-1
	var carry := 0
	var reversed := ""
	while i >= 0 or j >= 0 or carry > 0:
		var total := carry
		if i >= 0: total += a.unicode_at(i)-48
		if j >= 0: total += b.unicode_at(j)-48
		reversed += str(total % 10)
		carry = total / 10
		i -= 1; j -= 1
	return get_script().new(reversed.reverse(),scale)

func minus(other: RefCounted) -> RefCounted:
	assert(compare(other) >= 0, "Negative currency is not permitted")
	var scale := maxi(places, other.places)
	var a := digits + "0".repeat(scale-places)
	var b: String = other.digits + "0".repeat(scale-other.places)
	var j := b.length()-1
	var borrow := 0
	var reversed := ""
	for i in range(a.length()-1,-1,-1):
		var value := a.unicode_at(i)-48-borrow
		if j >= 0: value -= b.unicode_at(j)-48
		borrow = 1 if value < 0 else 0
		if value < 0: value += 10
		reversed += str(value)
		j -= 1
	return get_script().new(reversed.reverse(),scale)

func times(value: int, extra_places: int = 0) -> RefCounted:
	var carry := 0
	var reversed := ""
	for i in range(digits.length()-1,-1,-1):
		var n := (digits.unicode_at(i)-48)*value+carry
		reversed += str(n % 10)
		carry = n / 10
	while carry > 0:
		reversed += str(carry % 10)
		carry /= 10
	return get_script().new(reversed.reverse(),places+extra_places)

func floor_value() -> RefCounted:
	if places == 0: return clone()
	var whole := digits.left(maxi(0,digits.length()-places))
	return get_script().new(whole if not whole.is_empty() else "0")

func ceil_value() -> RefCounted:
	var whole := floor_value()
	return whole.plus(get_script().new("1")) if compare(whole)>0 else whole

func display() -> String:
	var whole: String = floor_value().digits
	if whole.length() <= 6: return whole
	var padded := whole + "00"
	return "%s.%se+%d" % [padded[0],padded.substr(1,2),whole.length()-1]

func exact() -> String:
	if places == 0: return digits
	var padded := "0".repeat(maxi(0,places+1-digits.length()))+digits
	return padded.left(padded.length()-places)+"."+padded.right(places)

func data() -> Dictionary: return {"digits":digits,"places":places}
