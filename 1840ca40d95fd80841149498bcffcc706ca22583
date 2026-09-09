extends Control
signal completed

const LINES := [
	["旁白", "第一天的摆摊生意结束了。"],
	["我", "我chovy，这一天才赚这么一点钱，我是不是被诓了啊？谁说盲盒赚钱的啊？"],
	["？？？", "小伙子。"],
	["我", "谁啊？今天收摊了。"],
	["老王", "小子，我是你王叔啊，你之前还来我电脑店里问过装机的事情呢。"],
	["我", "嗷？王叔？你咋来了？"],
	["老王", "小子，我看你摆摊摆了一天了，这一天能赚多少啊，这么缺钱？"],
	["我", "嗐，你以为我想来摆摊啊？要不是为了配台新电脑，我用得着这么费劲儿吗？"],
	["老王", "哦？你就为了赚钱配电脑啊，你早说啊。"],
	["我", "怎么说？"],
	["老王", "有个生意，能让你不用花钱就能配好电脑，你做不做？"],
	["我", "有这种好事？"],
	["老王", "嘿嘿，只要你把你盲盒里开出来的高罕款隐藏款什么乱七八糟的值钱货都给我，我就免费送你电脑配件，怎么样？"],
	["我", "王叔，没想到你也对这些东西感兴趣啊？"],
	["老王", "不不不，不是我，是我儿子对这样东西感兴趣。"],
	["老王", "我儿子这段时间突然沉迷上开这些个玩意儿，但是他脸实在是太黑了，怎么都开不出好货，只能一直不停地买，给我钱包都快掏空了！"],
	["我", "哦我明白了，你是想要我花钱帮你儿子开啊？"],
	["老王", "对咯，只要你给我整来我儿子要的款式，我直接拿配件跟你换！怎么样？"],
	["我", "那必须可以啊！"],
	["老王", "O了！等你好消息咯。"],
]
var index := 0

func start() -> void:
	index = 0
	show()
	_show_line()

func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		advance()

func advance() -> void:
	index += 1
	if index >= LINES.size():
		hide()
		completed.emit()
		return
	_show_line()

func _show_line() -> void:
	$Caption/Content/Speaker.text = LINES[index][0]
	$Caption/Content/Text.text = LINES[index][1]
	$PortraitArea.visible = index >= 2
	$PortraitArea.modulate = Color.WHITE if LINES[index][0] in ["老王", "？？？"] else Color(0.6, 0.6, 0.6)
	$PortraitArea/Placeholder.visible = $PortraitArea/Portrait.texture == null
