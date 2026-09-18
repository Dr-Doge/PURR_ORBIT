extends Control
signal sound_requested(heavy: bool)
signal message(text: String)
var model
var clock: float = 0
var reduced: bool = false
var particles: Array = []
var rings: Array = []
var numbers: Array = []
var stars: Array = []
var terrain: Array = []
var muzzle: Dictionary = {}
var arrivals: Dictionary = {}
var font := SystemFont.new()
const CYAN = Color("74ebdb")
const GOLD = Color("ffd17c")
const WHITE = Color("dcebf0")
const MUTED = Color("6a8b9e")
const SHIP_POS = [Vector2(245,170),Vector2(735,175),Vector2(405,270),Vector2(565,130)]

func _ready() -> void:
	font.font_names = PackedStringArray(["Microsoft YaHei", "Segoe UI"])
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	clip_contents = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 83122
	for i in range(150): stars.append(Vector3(rng.randf_range(25,975),rng.randf_range(55,660),rng.randf_range(0.5,1.8)))
	for i in range(75): terrain.append(Vector3(rng.randf_range(20,980),rng.randf_range(0,180),rng.randf_range(6,27)))

func surface(x: float) -> float:
	return 1240.0 - sqrt(maxf(0, 690.0*690.0-pow(x-500.0,2)))

func point(x: float) -> Vector2:
	return Vector2(x*1000.0, surface(x*1000.0))

func ship_pos(i: int) -> Vector2:
	var p: Vector2 = SHIP_POS[i % SHIP_POS.size()]
	var age: float = clock - float(arrivals.get(i,0.0))
	if age < 1.0: p.x -= 1100.0 * pow(1.0-maxf(age,0),3)
	return p + Vector2(0,sin(clock*0.8+i)*3)

func step(dt: float) -> void:
	clock += dt
	for i in range(model.ships.size()):
		if not arrivals.has(i): arrivals[i] = clock
	for event in model.events:
		var p: Vector2 = point(float(event.get("x",0.5))) - Vector2(0,25)
		match event.kind:
			"shot":
				muzzle[int(event.ship)] = clock
				sound_requested.emit(bool(event.heavy))
			"hit":
				rings.append({"p":p,"age":0.0,"big":event.big,"color":GOLD if event.armored else CYAN})
				numbers.append({"p":p+Vector2(randf_range(-18,18),-25),"age":0.0,"text":("护甲 " if event.armored else "")+str(snappedf(event.value,0.1)),"color":GOLD if event.armored else WHITE})
			"drop":
				for j in range(3 if reduced else 7):
					particles.append({"p":p,"v":Vector2(randf_range(-95,95),randf_range(-210,-100)),"age":0.0,"color":CYAN if j%3 else GOLD})
			"income": numbers.append({"p":Vector2(810,95),"age":0.0,"text":"+%d 金属" % int(event.value),"color":CYAN})
			"reveal": message.emit("已回收："+str(event.text)+("  · 首次发现！" if event.first else ""))
			"hotspot", "complete", "purchase": message.emit(str(event.text))
	model.events.clear()
	for part in particles.duplicate():
		part.age += dt
		part.v.y += 380*dt
		part.p += part.v*dt
		part.p.x = clampf(part.p.x,30,970)
		var floor_y: float = surface(part.p.x)+4
		if part.p.y > floor_y:
			part.p.y = floor_y; part.v.y = -absf(part.v.y)*0.35; part.v.x *= 0.7
		if part.age > 2.4: particles.erase(part)
	while particles.size() > 120: particles.pop_front()
	for r in rings.duplicate():
		r.age += dt
		if r.age > 0.65: rings.erase(r)
	for n in numbers.duplicate():
		n.age += dt
		if n.age > 1.2: numbers.erase(n)
	queue_redraw()

func label(p: Vector2, text: String, color: Color = WHITE, sz: int = 15) -> void:
	draw_string(font,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,color)

func _draw() -> void:
	if model == null or size.x <= 0: return
	draw_set_transform(Vector2.ZERO,0,Vector2(size.x/1000.0,size.y/750.0))
	draw_rect(Rect2(0,0,1000,750),Color("060f20"))
	for i in range(12):
		draw_circle(Vector2(760,360),200-i*11,Color(0.09,0.2,0.3,0.012))
	for s in stars:
		draw_circle(Vector2(s.x,s.y),s.z,Color(0.55,0.76,0.85,0.25+0.25*sin(clock*0.5+s.x)))
	draw_circle(Vector2(850,135),28,Color("1d374c"))
	draw_circle(Vector2(861,129),25,Color("091427"))
	for x in range(60,1000,100):
		draw_line(Vector2(x,330),Vector2(x,337),Color("203847"),1)
	draw_line(Vector2(30,333),Vector2(970,333),Color(0.25,0.5,0.58,0.1),1)
	# Curved horizon with an illuminated atmospheric rim.
	var planet := PackedVector2Array([Vector2(0,900)])
	for x in range(0,1001,10): planet.append(Vector2(x,surface(x)))
	planet.append(Vector2(1000,900))
	draw_colored_polygon(planet,Color("183b43"))
	var horizon := PackedVector2Array()
	for x in range(0,1001,10): horizon.append(Vector2(x,surface(x)))
	draw_polyline(horizon,Color(0.26,0.88,0.78,0.07),18,true)
	draw_polyline(horizon,Color(0.26,0.88,0.78,0.18),7,true)
	draw_polyline(horizon,CYAN.darkened(0.2),2,true)
	for data in terrain:
		var p := Vector2(data.x,surface(data.x)+data.y+20)
		draw_arc(p,data.z,0,TAU,16,Color("245159"),1,true)
		draw_line(p-Vector2(data.z,0),p+Vector2(data.z,0),Color("20444c"),1)
	for t in model.targets: draw_structure(t)
	for item in model.loot:
		var p: Vector2 = point(float(item.x))+Vector2(0,15)
		if item.kind == "treasure": draw_treasure(p, int(item.id)==model.priority)
		else:
			var count: int = mini(12,2+int(item.value/10))
			for j in range(count):
				var q: Vector2 = p+Vector2((j%5-2)*8,-(j/5)*6)
				draw_rect(Rect2(q,Vector2(6,5)),CYAN.darkened(float(j%3)*0.15))
			label(p+Vector2(-12,29),str(int(item.value)),CYAN,12)
	for p in particles: draw_rect(Rect2(p.p,Vector2(4,4)),p.color)
	for i in range(model.ships.size()): draw_ship(i)
	for p in model.projectiles:
		var a: Vector2 = ship_pos(int(p.ship))+Vector2(0,23)
		var b: Vector2 = point(float(p.x))-Vector2(0,24)
		var progress: float = 1-float(p.time)/float(p.duration)
		var head: Vector2 = a.lerp(b,progress)
		var tail: Vector2 = a.lerp(b,maxf(0,progress-0.12))
		var col: Color = GOLD if p.ap or p.damage>=30 else CYAN
		draw_line(tail,head,Color(col,0.16),9,true)
		draw_line(tail,head,col,3 if p.damage>=30 else 2,true)
		draw_circle(head,3,col)
	for i in range(model.drones.size()): draw_drone(i)
	for r in rings:
		var alpha: float = 1-r.age/0.65
		var radius: float = (70 if r.big else 40)*r.age/0.65+5
		draw_circle(r.p, radius*0.7, Color(r.color,alpha*0.12))
		draw_arc(r.p,radius,0,TAU,32,Color(r.color,alpha),2,true)
		if r.age<0.13: draw_circle(r.p,12,Color("fff8d0"))
	for n in numbers: label(n.p-Vector2(0,n.age*38),n.text,Color(n.color,1-n.age/1.2),17)
	# Bridge framing and the minimal diegetic status labels.
	draw_rect(Rect2(0,0,1000,42),Color("0c1b2a"))
	draw_rect(Rect2(0,0,14,750),Color("152939"))
	draw_rect(Rect2(986,0,14,750),Color("152939"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,710),Vector2(80,728),Vector2(410,735),Vector2(440,717),Vector2(560,717),Vector2(590,735),Vector2(920,728),Vector2(1000,710),Vector2(1000,750),Vector2(0,750)]),Color("0b1925"))
	draw_line(Vector2(35,43),Vector2(965,43),Color("304b5e"),1)
	label(Vector2(30,27),"ORBITAL COMMAND / 轨道舰桥",CYAN,14)
	label(Vector2(718,27),"KEPLER–09   /   构载体信号在线",MUTED,12)
	label(Vector2(32,81),"01  /  舰队阵列",MUTED,13)
	label(Vector2(32,365),"02  /  火力与回收航道",MUTED,12)
	label(Vector2(32,697),"03  /  外星构载体",CYAN,13)
	label(Vector2(680,697),"右键取消集火 · 点击宝藏优先回收",MUTED,12)
	if model.kills == 0 and not model.auto_fire:
		var p: Vector2 = point(0.37)-Vector2(0,110)
		label(p-Vector2(78,15),"按住这个结构，指挥第一轮炮击",WHITE,16)
		draw_line(p+Vector2(0,2),p+Vector2(0,37),CYAN,2)
		draw_circle(p+Vector2(0,42),4,CYAN)
	if model.completed: label(Vector2(385,743),"行动完成 · 舰队继续作业",GOLD,13)

func draw_structure(t: Dictionary) -> void:
	var p: Vector2 = point(float(t.x))
	if t.hp <= 0:
		draw_arc(p,27,PI,TAU,18,MUTED,2,true)
		return
	var hot: bool = t.kind != "normal"
	var color: Color = GOLD if hot else CYAN
	var w: float = 36 if hot else 25
	var height: float = 62 if hot else 35+int(t.id)%3*10
	var shape := PackedVector2Array([p+Vector2(-w,0),p+Vector2(-w,-height+12),p+Vector2(-w+12,-height),p+Vector2(w-7,-height),p+Vector2(w,-height+13),p+Vector2(w,0)])
	draw_colored_polygon(shape,Color("38493e") if hot else Color("254852"))
	draw_polyline(shape,color.darkened(0.55),2,true)
	for j in range(3):
		draw_line(p+Vector2(-w+8,-12-j*12),p+Vector2(w-8,-12-j*12),Color(color,0.3),2)
	if t.hp < t.max_hp:
		draw_polyline(PackedVector2Array([p+Vector2(-6,-height),p+Vector2(5,-height*0.6),p+Vector2(-8,-height*0.3),p]),GOLD,2,true)
	if hot:
		draw_arc(p-Vector2(0,height/2),w+15,0,TAU,36,Color(color,0.4+sin(clock*3)*0.2),1,true)
		label(p+Vector2(-36,-height-22),"重甲遗迹" if t.kind == "armor" else "暴露宝库",color,14)
	var ratio: float = float(t.armor)/100.0 if t.armor > 0 else float(t.hp)/float(t.max_hp)
	draw_rect(Rect2(p+Vector2(-w,-height-10),Vector2(w*2,4)),Color("101e28"))
	draw_rect(Rect2(p+Vector2(-w,-height-10),Vector2(w*2*ratio,4)),GOLD if t.armor > 0 else CYAN)
	if int(t.id) == model.focus or int(t.id) == model.manual_target:
		var center: Vector2 = p-Vector2(0,height/2)
		draw_arc(center,w+22,clock,clock+TAU*0.8,32,WHITE,2,true)
		label(p+Vector2(-30,49),"集火目标" if hot else "指定落点",WHITE,12)

func draw_ship(i: int) -> void:
	var s: Dictionary = model.ships[i]
	var p: Vector2 = ship_pos(i)
	var heavy: bool = s.kind == "heavy"
	var w: float = 89 if heavy else 64
	var color: Color = GOLD if heavy else CYAN
	var hull := PackedVector2Array([p+Vector2(-w,-12),p+Vector2(-w+18,-28),p+Vector2(w-28,-28),p+Vector2(w+15,-4),p+Vector2(w-8,17),p+Vector2(-w+15,17)])
	draw_colored_polygon(hull,Color("375068") if heavy else Color("284757"))
	draw_polyline(hull,Color("8ba1ae"),1.5,true)
	draw_rect(Rect2(p+Vector2(-28,-42),Vector2(39,17)),Color("3c5b70"))
	draw_rect(Rect2(p+Vector2(-20,-37),Vector2(22,5)),color)
	draw_line(p+Vector2(-w+18,-5),p+Vector2(w-24,-5),color.darkened(0.5),3)
	for j in range(4): draw_rect(Rect2(p+Vector2(-w+20+j*15,3),Vector2(7,3)),Color("91a9b0"))
	draw_circle(p+Vector2(-w-1,0),10+sin(clock*20+i)*2,Color(color,0.12))
	draw_line(p+Vector2(-w,0),p+Vector2(-w-17,0),color,5)
	var aim: Vector2 = point(0.5)-p
	var t: Dictionary = model.target(model.focus if i==model.ships.size()-1 and model.focus>=0 else model.manual_target)
	if not t.is_empty(): aim = point(t.x)-p
	var gun: Vector2 = p+Vector2(0,14)
	var end: Vector2 = gun+aim.normalized()*29
	draw_circle(gun,9,Color("101c28"))
	draw_line(gun,end,Color("b7cbd4"),7 if heavy else 5,true)
	if clock-float(muzzle.get(i,-10))<0.12: draw_circle(end,13,color)
	label(p+Vector2(-w,44),("R–01  重炮舰" if heavy else "L–0%d  轻型炮艇" % (i+1)),MUTED,12)
	var ready: float = 1-float(s.cool)/model.interval(s.kind)
	draw_line(p+Vector2(-w,53),p+Vector2(-w+60,53),Color("203544"),2)
	draw_line(p+Vector2(-w,53),p+Vector2(-w+60*ready,53),color,2)

func draw_treasure(p: Vector2, selected: bool = false) -> void:
	draw_circle(p,25,Color(1,0.72,0.32,0.08))
	draw_colored_polygon(PackedVector2Array([p+Vector2(0,-16),p+Vector2(13,0),p+Vector2(0,13),p+Vector2(-13,0)]),GOLD)
	draw_line(p+Vector2(0,-12),p+Vector2(0,8),Color("fff6d4"),2)
	if selected: draw_arc(p,22,0,TAU,24,WHITE,2,true)
	label(p+Vector2(-27,36),"回收宝藏",GOLD,12)

func draw_drone(i: int) -> void:
	var d: Dictionary = model.drones[i]
	var home := Vector2(100+i*65,395)
	var p: Vector2 = home
	if d.time > 0:
		var t: float = 1-float(d.time)/5.0
		var dest: Vector2 = point(d.x)-Vector2(0,10)
		var blend: float = t*2 if t<0.5 else (1-t)*2
		p = home.lerp(dest,smoothstep(0,1,blend))
		draw_line(home,dest,Color(0.4,0.7,0.8,0.1),1,true)
		if t>=0.5:
			draw_rect(Rect2(p+Vector2(-7,8),Vector2(14,9)),GOLD if not d.treasure.is_empty() else CYAN)
		elif not d.treasure.is_empty(): draw_treasure(dest+Vector2(0,20))
		else: draw_rect(Rect2(dest+Vector2(-8,12),Vector2(16,7)),CYAN)
	draw_rect(Rect2(p+Vector2(-12,-4),Vector2(24,8)),Color("69889a"))
	draw_circle(p+Vector2(-13,0),3,CYAN)
	draw_circle(p+Vector2(13,0),3,CYAN)
	draw_rect(Rect2(p+Vector2(-4,-7),Vector2(8,9)),Color("d4e6ea"))

func _gui_input(event: InputEvent) -> void:
	if model == null: return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			model.focus = -1; model.manual_target = -1; model.held=false; accept_event(); return
		if event.button_index != MOUSE_BUTTON_LEFT: return
		model.held = false
		if not event.pressed: return
		var p: Vector2 = event.position * Vector2(1000.0/size.x,750.0/size.y)
		for item in model.loot:
			if item.kind == "treasure" and p.distance_to(point(item.x)+Vector2(0,15))<30:
				model.priority=item.id; message.emit("宝藏已加入优先回收"); accept_event(); return
		for t in model.targets:
			if t.hp>0 and p.distance_to(point(t.x)-Vector2(0,28))<55:
				model.command(t.id); model.held=true; accept_event(); return
		for item in model.loot:
			if p.distance_to(point(item.x)+Vector2(0,15))<38:
				model.priority=item.id; message.emit("已优先回收这堆资源"); accept_event(); return
