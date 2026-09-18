extends RefCounted
## State-derived facts survive save/load; dismissing a card never verifies an action.
static func card(id: String, text: String, action: String, urgent: bool = false) -> Dictionary:
	return {"id":id,"text":text,"action":action,"urgent":urgent}
static func choose(m) -> Dictionary:
	var f: Dictionary = m.facts
	f["guide_version"] = 1
	var verified: Dictionary = f.get("guide_verified",{})
	for pair in [["G00","income"],["G02","navigated"],["G03","bought_fired"],["G04","refit_fired"],["G05","upgrade_kinetic:attack"],["G08","arrival_1"],["G11","intercept"],["G12","research_ap"],["G13","fixed_kill"],["G15","retreated"]]:
		if f.get(pair[1],false): verified[pair[0]] = true
	if m.has_installed("aa"): verified["G10"] = true
	if f.get("focused",false) and f.get("focus_damage",false): verified["G07"] = true
	f["guide_verified"] = verified
	if not m.tutorial_enabled or m.elapsed < m.tutorial_later: return {}
	if m.phase == "finished": return card("end","远征已完成，可查看舰队、研究与收藏。","help")
	if m.retreat > 0: return card("repair","撤离维修中，星球资源与在途货物保留。","",true)
	var attacks: int = 0; var carriers: int = 0; var disabled: int = 0
	for s in m.ships:
		if s.hp <= 0: disabled += 1; continue
		if s.kind == "carrier": carriers += 1
		for id in s.slots:
			if id >= 0 and m.module(id).kind in ["kinetic","ap","laser","neutron"]: attacks += 1
	if disabled > 0 or attacks == 0 or carriers == 0: return card("G15","舰队失能或无法作业，免费撤离恢复火力。","retreat",true)
	if not f.get("income",false):
		return card("G01" if m.ground_value()+m.transit_value() > 0 else "G00","可汗，舰队已开火。金属要运回才到账。","")
	if m.phase == "ready": return card("G08","物资已全部回收。驶向下一颗星球。","depart",true)
	if m.phase == "vault": return card("G07","转动星球寻找金色宝库，点击持续集火。","vault",true)
	if m.phase == "recovery": return card("recover","清除剩余威胁，等待全部运输返回。","logistics")
	var below_empty: bool = true
	for i in range(m.ships.size()):
		var s: Dictionary = m.ships[i]
		if s.kind != "carrier" and s.hp > 0 and m.regions[m.region_at(m.longitude(m.ship_x(i)))].stock > 0: below_empty = false
	if below_empty and m.unextracted() > 0: return card("G02","炮口下已枯竭。按住 A / D 转向新地表。","navigate",true)
	var throughput: float = m.drones.size()*40.0*pow(1.8,m.level("cargo"))/(6.0/pow(1.2,m.level("speed")))
	if m.ground_value() > throughput*10 and m.wallet >= m.upgrade_price("cargo") and m.level("cargo") < 8: return card("G06","地表货物积压，提升货舱或掠袭舰数量。","logistics",true)
	if m.planet > 0:
		if not m.has_installed("aa"): return card("G10","防空许可已开放。研发后给母舰安装防空炮。","aa")
		for t in m.targets:
			if t.hp <= 0 or not m.visible(t.lon) or t.kind == "vault": continue
			if t.armor > 0 and not m.has_installed("ap"): return card("G14","目标有装甲。研发穿甲后给现役舰安装。","ap",true)
			if m.focus != t.id: return card("G13","点击红色固定防御持续集火，防空独立拦截。","focus",true)
		if not f.get("intercept",false): return card("G11","防空已部署。等待真实敌袭，观察自动拦截。","help")
		if not m.researched.has("ap"): return card("G12","研发防空后可研发穿甲，无需升满前项。","ap")
	if not f.get("bought_fired",false) and m.wallet >= 100:
		if m.command_used() >= m.command_max(): return card("G06cmd","指挥点已满，升级指挥容量再扩军。","command")
		return card("G03","购买单炮护卫舰，留下一个槽位学习改装。","frigate")
	if not f.get("refit_fired",false) and f.get("bought_fired",false) and m.wallet >= 20:
		for s in m.ships:
			if s.slots.has(-1) and s.kind != "carrier": return card("G04","选择现役舰，在空槽补装第二门动能炮。","refit")
		f["guide_refit_optional"] = true
	if m.level("kinetic:attack") == 0 and m.wallet >= 100: return card("G05","升级动能威力，全舰队同型号炮同步增强。","kinetic")
	if m.planet == 2 and m.researched.has("destroyer"):
		if m.level("special") == 0: return card("N01","歼星舰已研发，解锁专用中子特殊槽。","special")
		if not m.researched.has("neutron"): return card("N02","先研发激光，再研发歼星级中子炮。","neutron")
		if not m.has_installed("neutron"): return card("N03","在歼星舰特殊槽安装中子炮。","refit")
		if not f.get("manual_neutron",false): return card("N04","点击中子瞄准按钮，再点击地表手动发射。","nuclear")
		if m.level("nuclear_auto") == 0: return card("N05","已完成手动发射，可研究中子自动火控。","nuclear_auto")
	return card("idle","自动轰炸 · A / D 航行 · 点击固定防御集火","help")
