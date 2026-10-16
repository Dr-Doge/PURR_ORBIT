extends Control
const RobotModel=preload("res://scripts/prototype_grooming_robot/model.gd")
const R=preload("res://scripts/prototype_grooming_robot/config.gd")
const C=preload("res://scripts/prototype_grooming/config.gd")
@export var service_polygon: PackedVector2Array=PackedVector2Array(R.SERVICE)
var model=RobotModel.new()
var dragging: bool=false
var previous:=Vector2.ZERO
var pending_paths: Array=[]
var paused: bool=false
var sound_enabled: bool=true
var last_particle: float=-1
@onready var view=$ServiceView
@onready var pause_panel=$HUD/PausePanel
func _ready() -> void:
 get_window().title="Purr Orbit / 毛球计划 · 机器猫随机污垢测试"
 model.generator.polygon=service_polygon
 if service_polygon!=PackedVector2Array(R.SERVICE):model.reproduce(model.order_seed)
 view.game=self;view.attach(model)
 $HUD/Top/New.pressed.connect(new_order)
 $HUD/Top/Retry.pressed.connect(retry_order)
 $HUD/Top/Reproduce.pressed.connect(reproduce_seed)
 $HUD/Top/Pause.pressed.connect(toggle_pause)
 $HUD/PausePanel/VBox/Continue.pressed.connect(toggle_pause)
 $HUD/Top/Seed.text=str(model.order_seed)
 update_ui()
func clear_input() -> void:
 dragging=false;pending_paths.clear();view.trail=PackedVector2Array()
func new_order() -> void:
 clear_input();paused=false;model.paused=false;pause_panel.hide()
 model.new_random_order();$HUD/Top/Seed.text=str(model.order_seed);view.sync();update_ui()
func retry_order() -> void:
 clear_input();paused=false;model.paused=false;pause_panel.hide()
 model.reproduce(model.order_seed);view.sync();update_ui()
func reproduce_seed() -> void:
 var value: String=$HUD/Top/Seed.text.strip_edges()
 if not value.is_valid_int() or int(value)<0 or value.length()>10:
  model.hint("开发seed请输入0—2147483647的整数");update_ui();return
 var seed_value: int=int(value)
 if seed_value>2147483647:model.hint("开发seed请输入0—2147483647的整数");update_ui();return
 clear_input();paused=false;model.paused=false;pause_panel.hide()
 model.reproduce(seed_value);view.sync();update_ui()
func toggle_pause() -> void:
 clear_input();paused=not paused;model.paused=paused;pause_panel.visible=paused
 view.sync();update_ui()
func surface_input(event: InputEvent) -> void:
 if event is InputEventMouseMotion:
  view.mouse=view.to_logical(event.position)
  if dragging and not (event.button_mask&MOUSE_BUTTON_MASK_LEFT):clear_input()
  if dragging and not paused and model.stage=="cleaning":
   var point: Vector2=view.model_point(event.position)
   pending_paths.append({"a":previous,"b":point});previous=point
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  if event.pressed:
   if paused or model.stage!="cleaning":return
   dragging=true;previous=view.model_point(event.position);view.mouse=view.to_logical(event.position)
   model.begin_gesture(previous)
  else:
   flush_paths();clear_input()
 view.sync();update_ui()
func flush_paths() -> void:
 if paused:pending_paths.clear();return
 for path in pending_paths:
  var result: Dictionary=model.stroke(path.a,path.b,1.0/60)
  if result.changed>0 and model.now-last_particle>.04:
   view.burst("oil_fleck",path.b,2);last_particle=model.now
 pending_paths.clear()
func _process(dt: float) -> void:
 var hover: Control=get_viewport().gui_get_hovered_control()
 if dragging and hover!=null and hover!=view:clear_input()
 if dragging:flush_paths()
 var serial_before: int=model.serial;var stage_before: String=model.stage
 model.tick(dt)
 if serial_before!=model.serial or stage_before!=model.stage:
  clear_input()
  if serial_before!=model.serial:$HUD/Top/Seed.text=str(model.order_seed)
 if not paused:view.animate(dt)
 else:view.sync()
 update_ui()
func _unhandled_key_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
  toggle_pause();get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
 if what in [NOTIFICATION_WM_WINDOW_FOCUS_OUT,NOTIFICATION_APPLICATION_FOCUS_OUT] and is_node_ready():clear_input()
func update_ui() -> void:
 $HUD/Top/Title.text="毛球计划 · 机器猫随机污垢"
 $HUD/Top/Money.text="金钱 %d  ｜ 已服务 %d"%[model.wallet,model.served]
 $HUD/Top/Details.text="本单seed %d  ·  普通%d／顽固%d  ·  评价%d"%[model.order_seed,model.generation.actual_normal,model.generation.actual_stubborn,model.score]
 var remaining: int=0
 for obj in model.objects:remaining+=int(not obj.done)
 $HUD/Bottom/Requirements.text="待清理 %d / %d  ｜ 擦净全部污垢自动结算"%[remaining,model.objects.size()]
 $HUD/Bottom/Progress.value=model.cleaning_progress()*100
 $HUD/Bottom/Hint.text=model.note if model.note_left>0 else "按住擦布自由来回擦 · 大块顽固污垢多擦几次 · 松手保留进度"
