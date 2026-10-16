extends Control
const Model=preload("res://scripts/prototype_grooming_fur/model.gd")
const C=preload("res://scripts/prototype_grooming/config.gd")
const Tool=preload("res://scripts/prototype_grooming_fur/tool_geometry.gd")
var model=Model.new()
@onready var view: Control=$ServiceView
@onready var title_label: Label=$HUD/Top/Title
@onready var resource_label: Label=$HUD/Top/Money
@onready var quality_label: Label=$HUD/Top/Quality
@onready var requirements: Label=$HUD/Bottom/Requirements
@onready var hint_label: Label=$HUD/Bottom/Hint
@onready var progress: ProgressBar=$HUD/Bottom/Progress
@onready var pause_panel: PanelContainer=$HUD/PausePanel
var dragging: bool=false
var previous: Vector2=Vector2.ZERO
var previous_tick: int=0
var paused: bool=false
var previous_version: int=-1
var previous_stage: String=""
var last_particle: float=-10.0
var last_paid_serial: int=-1
var nail_points:=PackedVector2Array()
var sound_enabled: bool=true
var sound_player: AudioStreamPlayer
var sounds: Dictionary={}
var pending_paths: Array=[]
var speed_history: Array=[]
var grooming_speed: float=0.0
var previous_screen: Vector2=Vector2.ZERO
var frame_stamp: int=0
var frame_delta: float=1.0/60.0

func _ready() -> void:
 view.game=self;view.attach(model)
 $HUD/Top/Calico.pressed.connect(jump_order.bind(0,false))
 $HUD/Top/Robot.pressed.connect(jump_order.bind(1,false))
 $HUD/Top/Full.pressed.connect(jump_order.bind(2,false))
 $HUD/Top/Nails.pressed.connect(jump_order.bind(0,true))
 $HUD/Top/Retry.pressed.connect(retry_order)
 $HUD/Top/Pause.pressed.connect(toggle_pause)
 $HUD/Top/Sound.toggled.connect(set_sound)
 $HUD/Top/Size.pressed.connect(toggle_cat_size)
 $HUD/PausePanel/VBox/Continue.pressed.connect(toggle_pause)
 sound_player=AudioStreamPlayer.new();sound_player.volume_db=-18;add_child(sound_player)
 for name in ["brush","cut","pain","reward"]:sounds[name]=make_sound(name)
 update_ui()

func make_sound(name: String) -> AudioStreamWAV:
 var rate: int=22050
 var duration: float=0.07 if name=="brush" else 0.14
 var count: int=int(rate*duration)
 var bytes:=PackedByteArray();bytes.resize(count*2)
 var frequency: float={"brush":220.0,"cut":900.0,"pain":150.0,"reward":660.0}[name]
 for i in range(count):
  var t: float=float(i)/rate
  var envelope: float=sin(PI*float(i)/count)*(1.0-float(i)/count)
  var value: float=sin(TAU*frequency*t+(12.0*t*t if name=="reward" else 0.0))*envelope*0.35
  if name=="brush":value=(randf()*2-1)*envelope*0.10
  bytes.encode_s16(i*2,int(value*32767))
 var sound:=AudioStreamWAV.new();sound.format=AudioStreamWAV.FORMAT_16_BITS;sound.mix_rate=rate;sound.data=bytes
 return sound

func play_sound(name: String) -> void:
 if sound_enabled:sound_player.stream=sounds[name];sound_player.play()

func set_sound(value: bool) -> void:sound_enabled=value;clear_input()

func clear_input() -> void:
 dragging=false;previous_tick=0;nail_points=PackedVector2Array()
 pending_paths.clear();speed_history.clear();grooming_speed=0.0
 if is_instance_valid(view):view.trail=PackedVector2Array()

func jump_order(index: int,nail_practice: bool=false) -> void:
 clear_input();paused=false;model.paused=false;pause_panel.hide();model.start_order(index,nail_practice);view.sync();update_ui()

func retry_order() -> void:jump_order(model.order_index,model.title.contains("练习"))

func toggle_cat_size() -> void:
 model.next_cat_scale=.5 if model.cat_scale==1 else 1.0
 jump_order(model.order_index,model.title.contains("练习"))

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
  if not dragging or paused:return
  var point: Vector2=view.model_point(event.position)
  if model.stage=="nails":
   if nail_points.is_empty() or nail_points[-1].distance_to(point)>1.0:nail_points.append(point)
   view.trail=nail_points;view.queue_redraw();return
  if model.stage!="cleaning":clear_input();return
  if model.kind=="calico":
   var logical: Vector2=view.to_logical(event.position)
   pending_paths.append({"a":previous,"b":point,"distance":previous_screen.distance_to(logical)})
   previous=point;previous_screen=logical
   return
  var stamp: int=Time.get_ticks_usec()
  var dt: float=float(stamp-previous_tick)/1000000.0
  if dt>0.3 or dt<=0.0001:
   previous=point;previous_tick=stamp;return
  var result: Dictionary=model.stroke(previous,point,dt)
  previous=point;previous_tick=stamp
  if result.pain:play_sound("pain")
  elif result.changed>0 and model.now-last_particle>0.04:
   view.burst(result.particle,view.mouse,2);last_particle=model.now;play_sound("brush")
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  if paused:return
  if event.pressed:
   if model.stage not in ["cleaning","nails"]:return
   dragging=true;previous=view.model_point(event.position);model.begin_gesture(previous);previous_tick=Time.get_ticks_usec()
   view.mouse=view.to_logical(event.position)
   pending_paths.clear();speed_history.clear();grooming_speed=0.0;previous_screen=view.mouse
   if model.stage=="nails":nail_points=PackedVector2Array([previous]);view.trail=nail_points
   elif model.kind=="calico":
    var click: Dictionary=model.click_at(previous)
    if click.changed>0:play_sound("cut");view.burst(click.particle,view.mouse,2)
  else:
   if dragging and model.kind=="calico" and model.stage=="cleaning":
    flush_grooming(maxf(frame_delta,float(Time.get_ticks_usec()-frame_stamp)/1000000.0))
   if dragging and model.stage=="nails":
    nail_points.append(view.model_point(event.position))
    var result: Dictionary=model.cut_gesture(nail_points)
    if result.result!="miss":view.burst("nail_tip",result.point,2);play_sound("pain" if result.pain else "cut")
   clear_input()
 view.sync();update_ui()

func _process(dt: float) -> void:
 if not is_instance_valid(view):return
 var hover: Control=get_viewport().gui_get_hovered_control()
 if dragging and hover!=null and hover!=view:clear_input()
 if dragging and not paused and model.kind=="calico" and model.stage=="cleaning":flush_grooming(dt)
 frame_stamp=Time.get_ticks_usec()
 frame_delta=maxf(dt,.001)
 model.tick(dt)
 if model.version!=previous_version or model.stage!=previous_stage:
  clear_input();previous_version=model.version;previous_stage=model.stage
 if model.settled and last_paid_serial!=model.serial:
  last_paid_serial=model.serial;play_sound("reward");view.burst("sparkle",Vector2(1070,235),4)
 if not paused:view.animate(dt)
 else:view.sync()
 update_ui()

func measure_speed(distance: float,dt: float) -> float:
 var elapsed: float=maxf(dt,.001)
 speed_history.append({"time":elapsed,"distance":distance})
 var time: float=0.0;var length: float=0.0
 for sample in speed_history:time+=sample.time;length+=sample.distance
 while time>Tool.SPEED_WINDOW and speed_history.size()>1:
  var first: Dictionary=speed_history[0];var excess: float=time-Tool.SPEED_WINDOW
  if first.time<=excess:
   time-=first.time;length-=first.distance;speed_history.pop_front()
  else:
   var ratio: float=excess/first.time
   length-=first.distance*ratio;first.distance*=1.0-ratio;first.time-=excess;time-=excess
 grooming_speed=length/maxf(time,.001)
 return grooming_speed

func flush_grooming(dt: float) -> void:
 var length: float=0.0
 for path in pending_paths:length+=path.distance
 var speed: float=measure_speed(length,dt)
 for path in pending_paths:
  var result: Dictionary=model.stroke(path.a,path.b,maxf(.0001,dt*path.distance/maxf(length,.0001)),speed)
  if result.pain:play_sound("pain")
  elif result.changed>0 and model.now-last_particle>.04:
   view.burst(result.particle,view.mouse,2);last_particle=model.now;play_sound("brush")
 pending_paths.clear()

func update_ui() -> void:
 $HUD/Top/Size.text="尺寸：大猫" if model.cat_scale==1 else "尺寸：小猫"
 title_label.text="毛球计划  ·  "+model.title
 resource_label.text="金钱  %d   ｜已服务 %d"%[model.wallet,model.served]
 quality_label.text="评价 %d / 100"%model.score
 quality_label.modulate=Color(1,0.58,0.42) if model.score<80 else Color(0.70,1,0.76)
 var cleaning_done: bool=model.cleaning_progress()>=0.999
 var cut: int=0
 for nail in model.nails:
  if nail.done:cut+=1
 requirements.text=("✓" if cleaning_done else "○")+(" 梳理" if model.kind=="calico" else " 擦拭")
 if model.needs_nails:requirements.text+="    %s 修甲 %d/4"%["✓" if cut==4 else "○",cut]
 progress.value=float(cut)/4.0*100.0 if model.stage=="nails" else model.cleaning_progress()*100.0
 var default_hint: String="按住左键激活，身体／尾巴／轮廓均向右一梳脱落 →；毛结慢梳，灰尘上下扫，跳蚤点三下" if model.kind=="calico" else "可快速反复擦；积灰上下擦 ↕，油块左右擦 ↔"
 if model.stage=="nails":default_hint="按住左键，从指甲一侧横向划到另一侧；绿色区间最合适"
 if model.stage=="arrival":default_hint="下一位顾客正在入座"
 if model.stage=="to_nails":default_hint="全身护理完成，切换到猫爪"
 if model.stage in ["reward","departure"]:default_hint="服务完成 · 自动入账，即将迎接下一位"
 hint_label.text=model.note if model.note_left>0.0 else default_hint
