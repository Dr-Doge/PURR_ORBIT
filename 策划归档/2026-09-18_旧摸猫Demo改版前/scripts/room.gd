extends Control
signal notice(text: String)
signal placed()
var model
var interactive: bool = false
var placing: int = -1
var hover: int = -1
var previous: Vector2 = Vector2.ZERO
var pointer: Vector2 = Vector2.ZERO
var particles: Array = []
var numbers: Array = []
var rings: Array = []
var clock: float = 0
var reduced: bool = false
var font := SystemFont.new()
const INK = Color("564b45")
const TEAL = Color("528c82")
func _ready() -> void:
	font.font_names = PackedStringArray(["Microsoft YaHei","Segoe UI"]); clip_contents = true
	mouse_exited.connect(reset_pointer)
func reset_pointer() -> void:
	hover = -1; model.clear_pet(); queue_redraw()
func world(p: Vector2) -> Vector2: return p*Vector2(900,640)/size
func step(dt: float) -> void:
	clock += dt
	var selected: Dictionary = model.cat(hover)
	if not selected.is_empty() and (selected.moving > 0 or pointer.distance_to(selected.pos) > 48): reset_pointer()
	for e in model.events:
		if e.kind == "notice": notice.emit(e.text)
		elif e.kind == "money":
			numbers.append({"p":e.pos,"text":"+%.1f%s" % [e.value," ×2" if e.double else ""],"age":0.0})
			for i in range(2 if reduced else 5): particles.append({"p":e.pos,"v":Vector2(randf_range(-65,65),randf_range(-150,-90)),"age":0.0})
		elif e.kind == "ring": rings.append({"p":e.pos,"radius":e.radius,"age":0.0})
	model.events.clear()
	for p in particles.duplicate():
		p.age += dt
		if p.age < 0.45: p.v.y += dt*220; p.p += p.v*dt
		else: p.p = p.p.lerp(Vector2(850,25),minf(1,dt*5))
		if p.age > 1.1: particles.erase(p)
	while particles.size() > 200: particles.pop_front()
	for n in numbers.duplicate():
		n.age += dt
		if n.age > 1.2: numbers.erase(n)
	for r in rings.duplicate():
		r.age += dt
		if r.age > 0.7: rings.erase(r)
	queue_redraw()
func text(p: Vector2,value: String,sz: int = 15,col: Color = INK) -> void: draw_string(font,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,col)
func rounded(rect: Rect2,col: Color,radius: int = 16,border: Color = Color.TRANSPARENT) -> void:
	var box := StyleBoxFlat.new(); box.bg_color = col; box.set_corner_radius_all(radius)
	if border.a > 0: box.border_color = border; box.set_border_width_all(2)
	draw_style_box(box,rect)
func ellipse(p: Vector2,scale: Vector2,col: Color) -> void:
	var points := PackedVector2Array()
	for i in range(40): points.append(p+Vector2(cos(TAU*i/40),sin(TAU*i/40))*scale)
	draw_colored_polygon(points,col)
func _draw() -> void:
	if model == null or size.x == 0: return
	draw_set_transform(Vector2.ZERO,0,size/Vector2(900,640))
	rounded(Rect2(0,0,900,640),Color("eee4d4"),22)
	# Wall, window, shelf and wood floor remain distinct from the interactive carpet.
	rounded(Rect2(20,16,860,104),Color("f7f1e7"),15)
	rounded(Rect2(51,28,154,76),Color("abcac0"),12,Color("d1b395"))
	draw_circle(Vector2(165,50),17,Color("f8dea1")); draw_line(Vector2(126,30),Vector2(126,103),Color("f9f5ed"),6); draw_line(Vector2(52,66),Vector2(205,66),Color("f9f5ed"),6)
	text(Vector2(330,64),"今天也要，好好摸猫。",25)
	text(Vector2(339,89),"F U R B A L L   C O T T A G E",12,TEAL)
	for y in range(124,640,38):
		draw_line(Vector2(20,y),Vector2(880,y),Color("dfcfb7"),1)
		for x in range(20+(y%3)*95,880,220): draw_line(Vector2(x,y),Vector2(x,y+38),Color("dfcfb7"),1)
	rounded(Rect2(54,137,792,446),Color("a7b5a0"),32)
	rounded(Rect2(65,148,770,422),Color("c9d1b9"),27,Color("e4e6cf"))
	rounded(Rect2(78,161,744,396),Color("d7ddc6"),22)
	for y in range(180,545,30):
		for x in range(92,812,30): draw_line(Vector2(x,y),Vector2(x+6,y),Color(0.58,0.64,0.51,0.12),1)
	# Low-key room furniture; purchased upgrades appear in the reserved edge positions.
	rounded(Rect2(739,72,97,11),Color("b08b68"),3)
	for i in range(4): rounded(Rect2(746+i*19,39-i%2*8,13,33+i%2*8),Color(["cb937e","8ea697","d2b66d","b4a5bb"][i]),2)
	draw_line(Vector2(30,106),Vector2(30,58),TEAL,4)
	for side in [-1,1]: ellipse(Vector2(30+side*10,72),Vector2(15,7),TEAL)
	rounded(Rect2(14,94,31,25),Color("bd8c75"),5)
	for i in range(3):
		var key: String = ["bed","post","bell"][i]
		if model.decor[key] <= 0: continue
		var p := Vector2(135+i*225,605)
		if key == "bed": ellipse(p,Vector2(51,17),Color("cda397")); ellipse(p-Vector2(0,5),Vector2(39,10),Color("f6dfc8"))
		elif key == "post": rounded(Rect2(p-Vector2(10,42),Vector2(20,43)),Color("bc9b76"),6); ellipse(p+Vector2(0,2),Vector2(30,7),Color("b78c68"))
		else: draw_line(p-Vector2(25,0),p-Vector2(25,32),INK,3); draw_line(p-Vector2(25,32),p+Vector2(25,-32),INK,3); draw_circle(p-Vector2(0,15),10,Color("e1b954"))
		text(p+Vector2(40,1),"Lv."+str(model.decor[key]),12)
	if model.auto_unlocked:
		rounded(Rect2(726,590,76,33),Color("cba679"),5)
		draw_line(Vector2(764,590),Vector2(764,621),Color("a98358"),2)
		text(Vector2(710,636),"纸箱游乐台",12)
	for t in model.tools:
		if not t.placed or t.kind not in ["heater","wand"]: continue
		var col: Color = Color("dba568") if t.kind == "heater" else Color("a584b0")
		draw_circle(t.pos,model.radius(t),Color(col,0.10)); draw_arc(t.pos,model.radius(t),0,TAU,64,Color(col,0.4),1,true)
		if t.kind == "heater":
			rounded(Rect2(t.pos-Vector2(22,26),Vector2(44,44)),Color("b68563"),10)
			for i in range(4): draw_line(t.pos+Vector2(-13+i*8,-15),t.pos+Vector2(-13+i*8,9),Color("ffd092"),4)
		else:
			draw_line(t.pos,t.pos+Vector2(9,-45),Color("94765f"),4); draw_line(t.pos+Vector2(9,-45),t.pos+Vector2(28,-29),INK,1)
			ellipse(t.pos+Vector2(30,-24),Vector2(7,14),Color("c18d9e"))
	var sorted: Array = model.cats.duplicate(); sorted.sort_custom(func(a: Dictionary,b: Dictionary): return a.pos.y < b.pos.y)
	for c in sorted: draw_cat(c)
	for t in model.tools:
		if t.kind not in ["spirit","spark"]: continue
		var p: Vector2 = t.pos-Vector2(0,24); var electric: bool = t.kind == "spark"
		var color: Color = Color("92aba1") if electric else Color("d4bf9e")
		ellipse(t.pos+Vector2(0,11),Vector2(15,5),Color(0.3,0.3,0.2,0.13))
		draw_circle(p,12,color); draw_circle(p+Vector2(0,19),10,color)
		draw_line(p+Vector2(-8,15),p+Vector2(-17,2+sin(clock*8)*7),color,5,true)
		draw_line(p+Vector2(8,15),p+Vector2(17,2-sin(clock*8)*7),color,5,true)
		draw_circle(p-Vector2(4,0),2,INK); draw_circle(p+Vector2(4,0),2,INK)
		if electric: draw_arc(p,22,clock,clock+4.5,18,TEAL,2,true)
	for r in rings: draw_arc(r.p,r.radius*minf(1,r.age*3),0,TAU,64,Color(TEAL,1-r.age/0.7),3,true)
	for p in particles:
		draw_circle(p.p,6,Color("eee0c2")); draw_arc(p.p,4,0,5,12,Color("ad967b"),1,true)
	for n in numbers: text(n.p-Vector2(22,53+n.age*28),n.text,21,Color(0.24,0.44,0.35,1-n.age/1.2))
	if placing >= 0:
		for t in model.tools:
			if t.id == placing: draw_circle(pointer,model.radius(t),Color(TEAL,0.17)); draw_arc(pointer,model.radius(t),0,TAU,48,TEAL,2,true)
		text(Vector2(220,625),"点击空地摆放 · 右键取消（摆放期间暂停）",16)
	elif hover >= 0 and interactive:
		# A simple hand cursor, without implying a click requirement.
		var p: Vector2 = pointer+Vector2(12,14)
		rounded(Rect2(p,Vector2(19,18)),Color("f4c9a4"),7,Color("b88467"))
		for i in range(3): draw_line(p+Vector2(3+i*6,6),p+Vector2(2+i*6,-5-i%2*4),Color("f4c9a4"),5,true)
		text(Vector2(257,624),"不用按键，轻轻来回摸。停下来也不会丢进度。",15)
	else: text(Vector2(246,624),"把鼠标放在猫身上，来回移动就能摸猫。",16)
func draw_cat(c: Dictionary) -> void:
	var active: bool = c.id == hover and interactive and c.moving <= 0
	var progress: float = c.progress/float(model.D.CATS[c.kind].need)
	var p: Vector2 = c.pos; var longhair: bool = c.kind == "long"; var electric: bool = c.kind == "static"
	ellipse(p+Vector2(0,18),Vector2(40,11),Color(0.29,0.33,0.25,0.13))
	var sway: float = sin(clock*(9 if active else 2)+c.id)*(0.035+progress*0.13) if c.moving <= 0 else sin(clock*15)*0.05
	var scale := Vector2(1.0+(progress*0.22 if longhair else 0.03*sin(clock*8)*progress),1.0)
	if electric: scale = Vector2(1+sin(clock*7)*0.13*progress,1-sin(clock*7)*0.1*progress)
	var base_scale: Vector2 = size/Vector2(900,640)
	draw_set_transform((p-Vector2(0,c.pop*12))*base_scale,sway,scale*base_scale)
	var colors: Array = [Color("ecd6bc"),Color("f5efe1"),Color("d89d61")]
	if longhair: colors = [Color("f9f4e9"),Color("626269"),Color("aab0ac")]
	if electric: colors = [Color("ddb17a"),Color("a9b4b4"),Color("dedbd4")]
	var color: Color = colors[int(c.color)]; var face: Color = Color("efe5cb") if longhair and c.color == 1 else INK
	if electric or longhair:
		var shape := PackedVector2Array()
		for i in range(48): shape.append(Vector2.from_angle(TAU*i/48)*(43 if electric else 40)*(1.0 if i%2 == 0 else 0.84)*Vector2(1,0.9))
		draw_colored_polygon(shape,color)
	else: ellipse(Vector2(0,2),Vector2(39,27),color)
	draw_arc(Vector2(33,3),20,-1.1,2.0,16,color,12,true)
	draw_colored_polygon(PackedVector2Array([Vector2(-27,-18),Vector2(-25,-46),Vector2(-7,-28)]),color)
	draw_colored_polygon(PackedVector2Array([Vector2(9,-28),Vector2(28,-44),Vector2(30,-14)]),color)
	draw_colored_polygon(PackedVector2Array([Vector2(-22,-22),Vector2(-22,-37),Vector2(-13,-26)]),Color("dca69d"))
	draw_colored_polygon(PackedVector2Array([Vector2(15,-26),Vector2(25,-36),Vector2(26,-20)]),Color("dca69d"))
	ellipse(Vector2(0,-10),Vector2(33,26),color)
	if c.kind == "short" and c.color < 2:
		ellipse(Vector2(-19,-17),Vector2(12,16),Color("a07153") if c.color == 0 else Color("666362"))
		if c.color == 0: ellipse(Vector2(23,9),Vector2(9,14),Color("666362"))
	if c.color == 2 or (electric and c.color == 1):
		for x in [-10,0,10]: draw_line(Vector2(x,-32),Vector2(x+2,-22),color.darkened(0.25),3,true)
	for x in [-12,12]:
		if active or c.pop > 0: draw_arc(Vector2(x,-8),5,PI,TAU,8,face,2,true)
		else: draw_circle(Vector2(x,-10),3,face)
	draw_colored_polygon(PackedVector2Array([Vector2(-3,-3),Vector2(3,-3),Vector2(0,0)]),Color("b98079"))
	draw_arc(Vector2(-4,0),4,0,PI,8,face,1.4,true); draw_arc(Vector2(4,0),4,0,PI,8,face,1.4,true)
	for side in [-1,1]:
		for j in range(2): draw_line(Vector2(side*19,-1+j*5),Vector2(side*37,-4+j*9),Color(face,0.6),1,true)
		ellipse(Vector2(side*20,24),Vector2(12,7),color.lightened(0.08))
	if active: draw_arc(Vector2(0,2),48,0.3,2.85,30,TEAL,2,true)
	draw_set_transform(Vector2.ZERO,0,base_scale)
	text(p+Vector2(-29,47),"换个位置…" if c.moving > 0 else model.D.title(c.kind),11,Color("758574"))
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pointer = world(event.position)
		if placing >= 0: queue_redraw()
		if not interactive: return
		var id: int = -1; var nearest: float = 48
		for c in model.cats:
			var distance: float = pointer.distance_to(c.pos)
			if c.moving <= 0 and distance < nearest: nearest = distance; id = c.id
		if id == hover and id >= 0: model.pet(id,pointer.distance_to(previous))
		else: model.clear_pet()
		hover = id; previous = pointer; queue_redraw()
	if event is InputEventMouseButton and event.pressed and placing >= 0:
		if event.button_index == MOUSE_BUTTON_RIGHT: placing = -1; placed.emit()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if model.place(placing,world(event.position)): placing = -1; placed.emit()
			else: notice.emit(model.error)
		accept_event()
