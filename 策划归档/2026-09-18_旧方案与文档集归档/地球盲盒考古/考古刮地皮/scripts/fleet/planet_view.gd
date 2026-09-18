extends Control
signal message(text: String)
signal selected_ship(id: int)
var model
var interactive: bool = false
var clock: float = 0
var particles: Array = []
var rings: Array = []
var numbers: Array = []
var stars: Array = []
var flashes: Dictionary = {}
var pointer: Vector2 = Vector2(500,550)
var font := SystemFont.new()
const CYAN = Color("79e1cd")
const GOLD = Color("f6c673")
const RED = Color("ff7a79")
const INK = Color("09111f")
func _ready() -> void:
	font.font_names = PackedStringArray(["Microsoft YaHei","Segoe UI"]); clip_contents = true
	var rng := RandomNumberGenerator.new(); rng.seed = 83122
	for i in range(110): stars.append(Vector3(rng.randf_range(20,980),rng.randf_range(50,590),rng.randf_range(0.5,1.7)))
func surface(x: float) -> float:
	var radius: float = 700.0*[1.0,1.25,1.55][model.planet]
	return 535.0+radius-sqrt(maxf(1.0,radius*radius-pow(x-500,2)))
func point(x: float) -> Vector2: return Vector2(x*1000,surface(x*1000))
func lon_point(lon: float) -> Vector2: return point(model.screen_x(lon))
func ship_pos(i: int) -> Vector2: return Vector2(model.ship_x(i)*1000,140+float(i/8)*34)
func ship_point(id: int) -> Vector2:
	for i in range(model.ships.size()):
		if int(model.ships[i].id) == id: return ship_pos(i)
	return Vector2(500,140)
func threat_point(t: Dictionary) -> Vector2:
	if t.kind == "aircraft": return Vector2(t.x*1000+sin(clock*0.5+t.id)*25,365+float(int(t.id)%3)*19)
	return Vector2(t.x*1000,540).lerp(ship_point(t.target),1.0-t.time/t.duration)
func step(dt: float) -> void:
	clock += dt
	var income: float = 0
	for e in model.events:
		match e.kind:
			"shot": flashes[e.ship] = clock
			"notice": message.emit(e.text)
			"income": income += e.value
			"hit", "nuclear", "enemy_shot":
				if not model.visible(e.lon): continue
				rings.append({"lon":e.lon,"age":0.0,"nuke":e.kind == "nuclear","enemy":e.kind == "enemy_shot","ship":e.get("ship",-1)})
				if e.kind != "enemy_shot":
					for i in range(2 if model.settings.reduced else 5):
						particles.append({"lon":e.lon,"p":Vector2.ZERO,"v":Vector2(randf_range(-50,50),randf_range(-150,-60)),"age":0.0})
	if income > 0:
		if model.settings.merge and not numbers.is_empty() and numbers.back().age < 0.15: numbers.back().value += income
		else: numbers.append({"value":income,"age":0.0})
	model.events.clear()
	for p in particles.duplicate():
		p.age += dt; p.v.y += dt*380; p.p += p.v*dt
		if p.p.y > 4: p.p.y = 4; p.v.y = -absf(p.v.y)*0.3; p.v.x *= 0.7
		if p.age > 1.6: particles.erase(p)
	while particles.size() > 240: particles.pop_front()
	for r in rings.duplicate():
		r.age += dt
		if r.age > (1.0 if r.nuke else 0.3): rings.erase(r)
	for n in numbers.duplicate():
		n.age += dt
		if n.age > 1.2: numbers.erase(n)
	queue_redraw()
func text_at(p: Vector2, text: String, color: Color = CYAN, sz: int = 14) -> void:
	draw_string(font,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,color)
func _draw() -> void:
	if model == null or size.x <= 0: return
	draw_set_transform(Vector2.ZERO,0,Vector2(size.x/1000,size.y/750))
	draw_rect(Rect2(0,0,1000,750),INK)
	for s in stars: draw_circle(Vector2(s.x,s.y),s.z,Color(0.58,0.75,0.88,0.38))
	draw_circle(Vector2(850,100),28,Color("203c50")); draw_circle(Vector2(860,95),26,INK)
	var base: Color = Color(model.config().color)
	for x in range(0,1000,5):
		var r: Dictionary = model.regions[model.region_at(model.longitude(float(x+2)/1000))]
		var col: Color = base.lerp(Color("151e26"),1.0-r.stock/r.max)
		var y: float = surface(x)
		draw_colored_polygon(PackedVector2Array([Vector2(x,y),Vector2(x+5,surface(x+5)),Vector2(x+5,750),Vector2(x,750)]),col.darkened(0.15))
	var rim := PackedVector2Array()
	for x in range(0,1001,8): rim.append(Vector2(x,surface(x)))
	draw_polyline(rim,Color(CYAN,0.10),12,true); draw_polyline(rim,Color(CYAN,0.7),2,true)
	# Surface decoration is deterministic in world longitude, including burnt ruins.
	for i in range(model.regions.size()):
		var r: Dictionary = model.regions[i]
		for j in range(3+model.planet):
			var lon: float = r.lon+(float(j)/float(3+model.planet)-0.5)*360.0/model.regions.size()
			if not model.visible(lon): continue
			var p: Vector2 = lon_point(lon); var h: float = 17+posmod(i*17+j*13,24)
			var burnt: bool = r.stock <= 0
			draw_rect(Rect2(p-Vector2(12,h if not burnt else 8),Vector2(24,h if not burnt else 8)),Color("1a2930") if burnt else base.lightened(0.08))
			if not burnt:
				draw_line(p-Vector2(9,h-5),p+Vector2(9,-h+5),Color(CYAN,0.4),2)
			else:
				for k in range(3): draw_circle(p-Vector2(-sin(clock+i+j+k)*5,15+k*12),6+k*2,Color(0.1,0.12,0.14,0.2))
	for t in model.targets:
		if not model.visible(t.lon): continue
		var p: Vector2 = lon_point(t.lon); var col: Color = GOLD if t.kind == "vault" else RED
		if t.hp <= 0: draw_line(p-Vector2(18,3),p+Vector2(18,-5),col.darkened(0.6),5); continue
		draw_rect(Rect2(p-Vector2(21,56),Vector2(42,56)),col.darkened(0.7))
		draw_rect(Rect2(p-Vector2(21,56),Vector2(42,56)),col,false,2)
		draw_line(p-Vector2(14,40),p+Vector2(14,-18),col,3)
		text_at(p+Vector2(-30,-70),{"vault":"最终宝库","silo":"导弹井","battery":"防空阵地"}[t.kind],col,13)
		draw_rect(Rect2(p-Vector2(24,64),Vector2(48,4)),Color("15202d"))
		draw_rect(Rect2(p-Vector2(24,64),Vector2(48*(t.armor/t.max_armor if t.armor > 0 else t.hp/t.max_hp),4)),GOLD if t.armor > 0 else RED)
		if t.id == model.focus: draw_arc(p-Vector2(0,27),37,clock,clock+5.0,24,GOLD,2,true)
	for item in model.loot:
		if not model.visible(item.lon): continue
		var p: Vector2 = lon_point(item.lon)+Vector2(0,15)
		var col: Color = GOLD if item.kind == "treasure" else CYAN
		if item.kind == "treasure": draw_colored_polygon(PackedVector2Array([p-Vector2(0,13),p+Vector2(12,0),p+Vector2(0,13),p-Vector2(12,0)]),col)
		else:
			for j in range(mini(12,1+int(item.value/20))): draw_rect(Rect2(p+Vector2((j%5)*5-12,-float(j/5)*5),Vector2(4,4)),col)
		text_at(p+Vector2(-18,32),"藏品" if item.kind == "treasure" else str(int(item.value)),col,12)
	for p in particles:
		if model.visible(p.lon): draw_rect(Rect2(lon_point(p.lon)+p.p,Vector2(3,3)),Color(CYAN,1-p.age/1.6))
	for i in range(model.ships.size()):
		var s: Dictionary = model.ships[i]; var p: Vector2 = ship_pos(i); var col: Color = GOLD if s.kind == "destroyer" else CYAN
		if s.hp <= 0: col = RED.darkened(0.5)
		var w: float = 22 if s.kind in ["battleship","destroyer"] else 16
		draw_colored_polygon(PackedVector2Array([p+Vector2(-w,-3),p+Vector2(-w+5,-7),p+Vector2(w-6,-7),p+Vector2(w+4,0),p+Vector2(w-3,5),p+Vector2(-w+4,5)]),col.darkened(0.35))
		draw_line(p-Vector2(w,0),p-Vector2(w+7,0),col,2)
		draw_line(p+Vector2(-w,10),p+Vector2(-w+2*w*s.hp/model.max_hp(s),10),col,2)
		text_at(p+Vector2(-w,-13),str(i+1)+(" M" if s.kind == "carrier" else ""),col,10)
		if clock-float(flashes.get(s.id,-10)) < 0.1: draw_circle(p+Vector2(0,9),5,GOLD)
		for id in s.slots:
			if id < 0: continue
			var m: Dictionary = model.module(id)
			if m.beam <= 0: continue
			var dest: Vector2 = point(model.ship_x(i))
			var t: Dictionary = model.target(m.beam_target)
			if not t.is_empty() and model.visible(t.lon): dest = lon_point(t.lon)-Vector2(0,25)
			draw_line(p,dest,Color(CYAN,0.12),9,true); draw_line(p,dest,CYAN,2,true)
	for p in model.projectiles:
		var a: Vector2 = ship_point(p.ship); var b: Vector2 = point(p.x)
		if p.kind == "aa":
			var t: Dictionary = model.find_id(model.threats,p.target)
			if not t.is_empty(): b = threat_point(t)
		elif p.target >= 0:
			var t: Dictionary = model.target(p.target)
			if not t.is_empty(): b = lon_point(t.lon)-Vector2(0,25)
		var ratio: float = 1-p.time/p.duration
		draw_line(a.lerp(b,maxf(0,ratio-0.14)),a.lerp(b,ratio),GOLD if p.kind == "ap" else CYAN,2,true)
	for t in model.threats:
		var p: Vector2 = threat_point(t)
		draw_colored_polygon(PackedVector2Array([p-Vector2(9,0),p+Vector2(0,-6),p+Vector2(9,0),p+Vector2(0,5)]),RED)
		text_at(p+Vector2(12,4),str(ceili(t.hp)),RED,10)
	for i in range(mini(model.drones.size(),96)):
		var d: Dictionary = model.drones[i]; var home: Vector2 = ship_point(d.carrier)+Vector2(0,20); var p: Vector2 = home
		if d.time > 0:
			var progress: float = 1-d.time/d.duration; var dest: Vector2 = point(clampf(model.screen_x(d.lon),0.03,0.97))+Vector2(0,15)
			p = home.lerp(dest,smoothstep(0,1,progress*2 if progress < 0.5 else (1-progress)*2))
			draw_line(home,dest,Color(CYAN,0.04),1)
			draw_rect(Rect2(p+Vector2(-3,3),Vector2(6,4)),GOLD if not d.treasure.is_empty() else CYAN)
		draw_line(p-Vector2(4,0),p+Vector2(4,0),Color("b5c9d3"),2)
	for r in rings:
		if not model.visible(r.lon): continue
		var p: Vector2 = lon_point(r.lon)
		if r.enemy: draw_line(p,ship_point(r.ship),Color(RED,1-r.age/0.3),1)
		else: draw_arc(p,5+r.age*(180 if r.nuke else 65),0,TAU,24,Color(GOLD if r.nuke else CYAN,1-r.age/(1.0 if r.nuke else 0.3)),2,true)
	for n in numbers: text_at(Vector2(735,82-n.age*30),"+%d 金属" % n.value,Color(CYAN,1-n.age/1.2),20)
	if model.nuclear_armed:
		draw_arc(pointer,85,0,TAU,48,GOLD,2,true); text_at(pointer+Vector2(-80,-95),"中子瞄准 · 右键取消",GOLD,14)
	draw_rect(Rect2(0,0,1000,40),Color("142330")); draw_rect(Rect2(0,0,12,750),Color("142330")); draw_rect(Rect2(988,0,12,750),Color("142330"))
	text_at(Vector2(28,26),"KHAN / 游牧舰队     ·     "+model.config().name,CYAN,15)
	text_at(Vector2(28,83),"舰队阵列   %d 艘 / 掠袭舰 %d" % [model.ships.size(),model.drones.size()],Color("8da6b8"),12)
	text_at(Vector2(28,350),"轨道火力 / 回收航道",Color("527586"),12)
	draw_rect(Rect2(12,694,976,56),Color("101d2a"))
	for i in range(model.regions.size()):
		var r: Dictionary = model.regions[i]; var w: float = 820.0/model.regions.size()
		draw_rect(Rect2(90+i*w,716,w-2,8),base if r.stock > 0 else Color("253440"))
	for t in model.targets:
		if t.hp > 0: draw_circle(Vector2(90+t.lon/360.0*820,710),4,GOLD if t.kind == "vault" else RED)
	var cursor: float = 90+model.angle/360.0*820
	draw_line(Vector2(cursor,709),Vector2(cursor,733),CYAN,2)
	text_at(Vector2(25,732),"0°",CYAN,12); text_at(Vector2(923,732),"360°",CYAN,12)
	text_at(Vector2(380,686),"A ◀  按住航行  ▶ D    /    %.0f°" % model.angle,CYAN,14)
	if model.retreat > 0: text_at(Vector2(310,440),"安全轨道维修  %.1f 秒" % model.retreat,GOLD,28)
func _gui_input(event: InputEvent) -> void:
	if not interactive: return
	if event is InputEventMouseMotion: pointer = event.position*Vector2(1000,750)/size
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT: model.focus = -1; model.nuclear_armed = false; accept_event(); return
		if event.button_index != MOUSE_BUTTON_LEFT: return
		var p: Vector2 = event.position*Vector2(1000,750)/size
		var hit: int = -1
		for t in model.targets:
			if t.hp > 0 and model.visible(t.lon) and p.distance_to(lon_point(t.lon)-Vector2(0,28)) < 38: hit = t.id; break
		if model.nuclear_armed:
			if p.y > 440 and p.y < 685:
				if not model.fire_neutron(clampf(p.x/1000,0,1),hit): message.emit("中子炮尚未就绪，或落点已枯竭")
			accept_event(); return
		if hit >= 0: model.command(hit); accept_event(); return
		for i in range(model.ships.size()):
			if p.distance_to(ship_pos(i)) < 23: selected_ship.emit(model.ships[i].id); accept_event(); return
		for item in model.loot:
			if model.visible(item.lon) and p.distance_to(lon_point(item.lon)+Vector2(0,15)) < 28: model.priority = item.id; message.emit("已标记优先回收"); accept_event(); return
