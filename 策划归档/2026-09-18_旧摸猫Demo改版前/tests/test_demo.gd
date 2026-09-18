extends SceneTree
const M = preload("res://scripts/model.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool,why: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(why)
func advance(m,seconds: float) -> void:
	for i in range(ceili(seconds/0.05)): m.tick(0.05); m.events.clear()
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m = M.new(); m.rng.seed = 41
	advance(m,10); check(m.cats[0].progress == 0 and m.wallet == 0,"stationary hover gives nothing")
	var id: int = m.cats[0].id
	m.pet(id,100000); m.tick(0.05); check(is_equal_approx(m.cats[0].progress,2),"manual per second cap")
	var progress: float = m.cats[0].progress; m.clear_pet(); advance(m,1); check(m.cats[0].progress == progress,"progress retained after leaving")
	for i in range(49): m.pet(id,10); m.tick(0.05)
	check(m.satisfied == 1 and m.wallet == 1 and m.cats[0].moving > 0,"one completion one reward and movement")
	m.pet(id,999); m.tick(0.05); check(m.wallet == 1,"moving cat cannot be petted")
	advance(m,1); check(m.cats[0].pos != m.cats[0].from,"cat changes position")
	var gated = M.new(); gated.wallet = 1000
	for i in range(1,8): check(gated.research(i),"main chain advances without branches or entities")
	check(gated.levels.is_empty() and gated.cats.size() == 1 and gated.tools.is_empty(),"research does not grant entities or side upgrades")
	var balance: float = gated.wallet; check(not gated.buy("lucky") and gated.wallet == balance,"undefined coin odds do not charge")
	gated.buy("short"); gated.buy("short"); balance = gated.wallet
	check(not gated.buy("short") and gated.wallet == balance,"per species cap atomic")
	check(gated.buy("long"),"other species independent of short cap")
	check(gated.upgrade("short","cap") and gated.buy("short"),"cap upgrade then buy")
	var electric = M.new(); electric.cats.clear(); electric.add_cat("static",0); electric.add_cat("static",0); electric.add_cat("long",0)
	for c in electric.cats: c.pos = Vector2(450,330); c.dest = c.pos; c.progress = 30.0
	electric.cats[1].moving = 0.5; electric.care(electric.cats[0],90,"hand")
	check(electric.wallet == 7 and electric.eligible == 3,"static rewards all neighbors once without recursion")
	check(electric.cats[1].progress == 30 and electric.cats[1].moving == 0.5,"extra production preserves progress and moving state")
	var collectibles = M.new(); collectibles.rng.seed = 1
	for i in range(12): collectibles.reward(collectibles.cats[0],"hand")
	check(not collectibles.inventory.is_empty(),"first collectible pity")
	var item: Dictionary = collectibles.inventory[0]; check(not collectibles.sell(item.id),"first item locked")
	item.locked = false; var discovered: Array = collectibles.discovered.duplicate(); check(collectibles.sell(item.id) and collectibles.discovered == discovered,"sale keeps codex")
	check(not collectibles.sell(item.id),"sale cannot repeat")
	var auto = M.new(); auto.wallet = 100; auto.research(1); auto.buy("spirit"); advance(auto,20)
	check(auto.auto_earned > 0 and auto.auto_unlocked and auto.tickets > 0,"real helper care unlocks minigame")
	check(auto.start_minigame(),"reward game consumes ticket")
	var ticket: int = auto.tickets; var game_id: int = auto.minigame.id
	check(auto.start_minigame() and auto.tickets == ticket and auto.minigame.id == game_id,"resume no duplicate ticket charge")
	var old_auto: float = auto.auto_earned; advance(auto,8); check(auto.auto_earned > old_auto,"automatic income while game active")
	var saved: Dictionary = auto.snapshot(); var copy = M.new(); check(copy.restore(saved) and copy.snapshot() == saved,"save state and RNG roundtrip")
	var old_wallet: float = copy.wallet
	for value in range(3):
		for i in range(6):
			if copy.minigame.deck[i] == value: copy.flip(i)
	check(copy.minigame.claimed and copy.wallet == old_wallet+2,"minigame awards exactly 2, no double automatic income")
	copy.flip(0); check(copy.wallet == old_wallet+2,"minigame cannot reward twice")
	var consumable: int = copy.minigame.reward; check(copy.use_item(consumable) and not copy.use_item(consumable),"item consumed once and no same-effect stacking")
	var remaining: float = copy.buffs[consumable]; advance(copy,1); check(copy.buffs[consumable] < remaining,"buff uses simulation time")
	var path: String = "user://cat_test_only.save"
	check(copy.save_to(path) == OK and copy.save_to(path) == OK,"atomic save overwrite")
	var load = M.new(); check(load.load_from(path) and load.snapshot() == copy.snapshot(),"load file matches")
	DirAccess.remove_absolute(path)
	check(not load.restore({"version":999}),"foreign version rejected")
	var range_tool = M.new(); range_tool.stage = 6; range_tool.wallet = 100; range_tool.buy("spark")
	range_tool.tools[0].pos = range_tool.cats[0].pos; range_tool.cats[0].progress = 20.0
	advance(range_tool,7.9); check(range_tool.wallet == 20,"spark waits first real cooldown after arrival")
	advance(range_tool,0.3); check(range_tool.wallet == 21 and range_tool.cats[0].progress == 20,"spark extra output keeps satisfaction")
	var fixed = M.new(); fixed.stage = 5; fixed.wallet = 100; fixed.buy("wand"); fixed.place(fixed.tools[0].id,Vector2(250,300))
	var w: Dictionary = fixed.tools[0]; var fixed_cat: Dictionary = fixed.cats[0]
	fixed_cat.pos = Vector2(260,300); fixed.sync_passes(w); var initial: float = fixed.wallet; advance(fixed,3)
	check(fixed.wallet == initial,"wand placement and standing do not pay")
	fixed.buy("heater"); fixed.tools[1].placed = true; fixed.tools[1].pos = fixed_cat.pos
	fixed.tools.append(fixed.tools[1].duplicate(true)); fixed.tools.back().id = fixed.uid()
	check(is_equal_approx(fixed.room_multiplier(fixed_cat.pos),1.2),"overlapping heaters do not multiply")
	check(not fixed.upgrade("long","token"),"unconfigured token branches cannot be bought")
	var loop = M.new(); loop.rng.seed = 421
	var first_auto: float = -1
	for i in range(5000):
		if loop.stage == 0: loop.research(1)
		if loop.lv("hand","yield") == 0 and loop.wallet >= 4: loop.upgrade("hand","yield")
		if loop.count("short") < 2 and loop.wallet >= loop.price("short"): loop.buy("short")
		if loop.count("spirit") == 0 and loop.wallet >= 12: loop.buy("spirit"); first_auto = loop.elapsed
		if loop.count("spirit") == 0:
			for c in loop.cats:
				if c.moving <= 0: loop.pet(c.id,5); break
		loop.tick(0.05); loop.events.clear()
		if loop.completed: break
	check(loop.completed,"zero-money manual-upgrade-multicat-automation loop")
	print("First helper bought at %.1fs; completed loop at %.1fs, wallet %.1f" % [first_auto,loop.elapsed,loop.wallet])
	print("CAT DEMO: %d checks / %d failures" % [checks,failures]); quit(1 if failures else 0)
