extends Control
const Model=preload("res://scripts/prototype_grooming_fur/model.gd")
const Brush=preload("res://scripts/prototype_grooming_fur/brush_config.gd")
const C=preload("res://scripts/prototype_grooming/config.gd")
@export var presentation: Resource=preload("res://Art/grooming_environment_v1/grooming_presentation.tres")
var model=Model.new()
@onready var view: Control=$ServiceView
@onready var title_label: Label=$HUD/Top/Title
@onready var resource_label: Label=$HUD/Top/Money
@onready var requirements: Label=$HUD/Bottom/Requirements
@onready var hint_label: Label=$HUD/Bottom/Hint
@onready var progress: ProgressBar=$HUD/Bottom/Progress
@onready var pause_panel: PanelContainer=$HUD/PausePanel
var dragging: bool=false
var previous:=Vector2.ZERO
var paused: bool=false
var previous_version: int=-1
var previous_stage: String=""
var last_particle: float=-10.0
var last_paid_serial: int=-1
var sound_enabled: bool=true
var sound_player: AudioStreamPlayer
var sounds: Dictionary={}
var pending_paths: Array=[]
var frame_delta: float=1.0/60.0

func _ready() -> void:
 if not model.configure_presentation(presentation):push_error("Invalid grooming presentation profile; using default art.")
 view.game=self;view.attach(model)
 $HUD/Top/Pause.pressed.connect(toggle_pause)
 $HUD/Top/Sound.toggled.connect(set_sound)
 $HUD/Top/Size.pressed.connect(toggle_cat_size)
 $HUD/PausePanel/VBox/Continue.pressed.connect(toggle_pause)
 sound_player=AudioStreamPlayer.new();sound_player.volume_db=-18;add_child(sound_player)
 for name in ["brush","reward"]:sounds[name]=make_sound(name)
 previous_version=model.version;previous_stage=model.stage;update_ui()

func make_sound(name: String) -> AudioStreamWAV:
 var rate: int=22050;var duration: float=.14 if name=="reward" else .10
 var count: int=int(rate*duration);var bytes:=PackedByteArray();bytes.resize(count*2)
 for i in range(count):
  var t: float=float(i)/rate;var envelope: float=sin(PI*float(i)/count)*(1.0-float(i)/count)
  var value: float=sin(TAU*660*t)*envelope*.30 if name=="reward" else (randf()*2-1)*envelope*.10
  bytes.encode_s16(i*2,int(value*32767))
 var sound:=AudioStreamWAV.new();sound.format=AudioStreamWAV.FORMAT_16_BITS;sound.mix_rate=rate;sound.data=bytes
 return sound

func play_sound(name: String) -> void:
 if sound_enabled:sound_player.stream=sounds[name];sound_player.play()
func set_sound(value: bool) -> void:sound_enabled=value;clear_input()
func clear_input() -> void:
 if dragging:model.end_brush()
 dragging=false;pending_paths.clear()
func toggle_cat_size() -> void:
 var selected: float=model.next_cat_scale if model.next_cat_scale>0 else model.cat_scale
 model.queue_customer(null,.5 if selected==1 else 1.0)
 clear_input();update_ui()
func toggle_pause() -> void:
 clear_input();paused=not paused;model.paused=paused;pause_panel.visible=paused;update_ui()
func _unhandled_key_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
  toggle_pause();get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
 if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:clear_input()

func surface_input(event: InputEvent) -> void:
 if event is InputEventMouseMotion:
  view.mouse=view.to_logical(event.position)
  if dragging and not (event.button_mask&MOUSE_BUTTON_MASK_LEFT):clear_input();return
  if dragging and not paused and model.stage=="cleaning":
   var point: Vector2=view.model_point(event.position)
   pending_paths.append({"a":previous,"b":point,"distance":previous.distance_to(point)});previous=point
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  if paused:return
  if event.pressed:
   if model.stage!="cleaning":return
   dragging=true;previous=view.model_point(event.position);model.begin_gesture(previous)
   view.mouse=view.to_logical(event.position);pending_paths.clear()
  else:
   if dragging:flush_grooming(frame_delta)
   clear_input()
 view.sync();update_ui()

func flush_grooming(dt: float) -> void:
 var length: float=0
 for path in pending_paths:length+=path.distance
 for path in pending_paths:
  var result: Dictionary=model.stroke(path.a,path.b,maxf(.001,dt*path.distance/maxf(length,.001)))
  if result.changed>0 and model.now-last_particle>=Brush.PARTICLE_INTERVAL:
   view.burst(result.particle,result.point,1);last_particle=model.now;play_sound("brush")
 pending_paths.clear()

func _process(dt: float) -> void:
 if not is_instance_valid(view):return
 var hover: Control=get_viewport().gui_get_hovered_control()
 if dragging and hover!=null and hover!=view:clear_input()
 if dragging and not paused and model.stage=="cleaning":flush_grooming(dt)
 frame_delta=maxf(dt,.001);model.tick(dt)
 if model.version!=previous_version or model.stage!=previous_stage:
  clear_input();previous_version=model.version;previous_stage=model.stage
 if model.settled and last_paid_serial!=model.serial:
  last_paid_serial=model.serial;play_sound("reward")
 if not paused:view.animate(dt)
 else:view.sync()
 update_ui()

func update_ui() -> void:
 var selected: float=model.next_cat_scale if model.next_cat_scale>0 else model.cat_scale
 $HUD/Top/Size.text="下只：大猫" if selected==1 else "下只：小猫"
 title_label.text="毛球计划  ·  "+model.title
 resource_label.text="完成 %d 次"%model.served
 requirements.text="✓ 梳理完成" if model.settled else "每片梳两遍 · 拉松 → 回弹 → 脱落"
 progress.value=model.cleaning_progress()*100.0
 var text: String="按住左键向右梳；第二遍回弹结束后脱落。松手保留进度。"
 if model.stage=="arrival":text="平台载猫上升 · 停稳后开始梳理"
 elif model.stage=="departure":text="平台下降 · 下一只猫即将到来"
 elif model.settled:text="梳理完成 · 马上自动换下一只猫"
 hint_label.text=model.note if model.note_left>0 and model.stage=="cleaning" else text
