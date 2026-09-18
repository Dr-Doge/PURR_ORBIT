extends SceneTree
const Model = preload("res://scripts/fleet/model.gd")
var failures := 0
func check(ok: bool, text: String) -> void:
	if not ok: failures += 1; push_error(text)
func _initialize() -> void:
	var m = Model.new()
	var id: int = m.targets[0].id
	m.hit(id,999); m.hit(id,999)
	check(m.generated == 20 and m.wallet == 0 and m.kills == 1,"Overkill/drop settlement")
	m.tick(0.1); check(m.transit_value() == 20 and m.wallet == 0,"Transport delayed")
	for i in range(60): m.tick(0.1)
	check(m.wallet == 20 and m.generated == m.earned+m.ground_value()+m.transit_value(),"Conservation")
	m.hit(id,999); check(m.generated == 20,"Stale projectile cannot hit respawn")
	m.add_hotspot("armor"); var armored: Dictionary = m.targets.back()
	m.hit(armored.id,100); check(armored.armor == 90 and armored.hp == 100,"Armor reduction")
	m.hit(armored.id,999,true); check(armored.armor == 0 and armored.hp == 100,"No armor overflow")
	m.receive({"id":999,"source":"cache","value":120})
	check(m.unlocked and not m.sell(999),"First discovery lock and unlock")
	m.inventory[0].locked = false; check(m.sell(999) and m.unlocked and not m.sell(999),"One sale/permanent blueprint")
	check(m.save_to("user://fleet_test.save") == OK,"Save")
	var loaded = Model.new(); check(loaded.load_from("user://fleet_test.save") and loaded.snapshot() == m.snapshot(),"Roundtrip")
	DirAccess.remove_absolute("user://fleet_test.save")
	# Earn every purchase through normal gameplay; no injected wallet or rewards.
	m = Model.new()
	var order := ["auto","light","drone","heavy","piercing"]
	var step := 0
	for i in range(24000):
		if step < order.size() and m.buy(order[step]): step += 1
		if not m.auto_fire:
			for t in m.targets:
				if t.hp > 0: m.command(t.id); m.held = true; break
		else:
			for t in m.targets:
				if t.kind != "normal" and t.hp > 0: m.command(t.id); break
		m.tick(0.05); m.events.clear()
		if m.completed: break
	check(m.completed and step == 5,"Natural progression completes within 20 minutes")
	check(absf(m.generated-m.earned-m.ground_value()-m.transit_value()) < 0.001,"Full-run conservation")
	print("FLEET TEST: failures=%d completion_seconds=%.1f kills=%d" % [failures,m.elapsed,m.kills])
	quit(failures)
