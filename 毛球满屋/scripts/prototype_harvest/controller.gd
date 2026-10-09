extends Control
const M = preload("res://scripts/prototype_harvest/model.gd")
const C = preload("res://scripts/prototype_harvest/config.gd")
var model = M.new()
var testing: bool = false
var transition_left: float = 0.0
var transition_start: float = 1.0
var transition_end: float = 1.0
var wheel_lock: float = 0.0
var pending_selection: int = -1
var manual_pause: bool = false
var page: String = "tree"
var ui_clock: float = 0.0
var buttons: Dictionary = {}
var worker_rows: Array = []
var last_workers: int = -1
var last_cats: int = -1
var focus_lost: bool = false
@onready var view = $HarvestView
@onready var room = $Room
@onready var content: VBoxContainer = $Sidebar/Scroll/Content
@onready var drawer: PanelContainer = $MeetingMenu
@onready var menu_items: VBoxContainer = $MeetingMenu/Scroll/Items
@onready var status: Label = $Status
@onready var heading: Label = $Header
@onready var hint: Label = $Hint
func _ready() -> void:
 get_window().title="Purr Orbit / 毛球计划 · 猫身采集会议原型"
 var panel:=StyleBoxFlat.new();panel.bg_color=Color("f5f3e9");panel.corner_radius_top_left=14;panel.corner_radius_top_right=14;panel.corner_radius_bottom_left=14;panel.corner_radius_bottom_right=14
 $Sidebar.add_theme_stylebox_override("panel",panel)
 var menu_style: StyleBoxFlat=panel.duplicate();menu_style.content_margin_left=20;menu_style.content_margin_right=20;menu_style.content_margin_top=18;menu_style.content_margin_bottom=18
 drawer.add_theme_stylebox_override("panel",menu_style)
 view.game=self;view.model=model
 $MenuButton.pressed.connect(func():set_menu(not drawer.visible))
 $BackButton.pressed.connect(func():zoom(view.close_amount<0.5,view.selected))
 $Sidebar/TreeButton.pressed.connect(func():show_page("tree"))
 $Sidebar/TeamButton.pressed.connect(func():show_page("team"))
 resized.connect(layout);layout();build_menu();load_stage(0,false)
func layout() -> void:
 var sidebar: float=320
 view.position=Vector2.ZERO;view.size=Vector2(size.x-sidebar-20,size.y)
 $Sidebar.position=Vector2(size.x-sidebar-12,90);$Sidebar.size=Vector2(sidebar,size.y-150)
 $Header.position=Vector2(24,18);$Header.size=Vector2(size.x-360,56)
 $MenuButton.position=Vector2(12,size.y*0.42)
 $BackButton.position=Vector2(size.x-332,22);$BackButton.size=Vector2(320,44)
 $Hint.position=Vector2(28,size.y-34);$Hint.size=Vector2(size.x-380,28)
 $Status.position=Vector2(size.x-332,size.y-52);$Status.size=Vector2(320,44)
 drawer.position=Vector2(58,82);drawer.size=Vector2(minf(590,size.x-90),size.y-110)
func text(value: String, parent: Node, font_size: int=17) -> Label:
 var label:=Label.new();label.text=value;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size",font_size);label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(label);return label
func button(value: String,parent: Node, action: Callable, key: String="") -> Button:
 var b:=Button.new();b.text=value;b.custom_minimum_size=Vector2(0,40);b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 b.add_theme_font_size_override("font_size",17);parent.add_child(b);b.pressed.connect(action)
 if key!="":buttons[key]=b
 return b
func clear_children(node: Node) -> void:
 for child in node.get_children():node.remove_child(child);child.queue_free()
func build_menu() -> void:
 clear_children(menu_items)
 text("会议演示 · S01—S08",menu_items,25)
 text("载入演示预置将重置当前测试进度。滚轮切换视角则保留进度。",menu_items,17)
 for i in C.STAGES.size():
  var index: int=i
  button(C.STAGES[i].name,menu_items,func():load_stage(index),"stage_"+str(i))
  text(C.STAGES[i].intro,menu_items,15)
 button("重试当前阶段",menu_items,func():load_stage(model.stage),"retry")
 button("从头游玩（随机新会话）",menu_items,func():load_stage(0,false),"restart")
 button("触发本阶段事件",menu_items,trigger_stage_event,"event")
 button("暂停 / 继续模拟",menu_items,func():manual_pause=not manual_pause;set_menu(false),"pause")
 button("返回继续",menu_items,func():manual_pause=false;set_menu(false),"resume")
func show_page(value: String) -> void:
 page=value;buttons.erase("buff_assign");clear_children(content);worker_rows.clear()
 if page=="tree":
  text("成长树 · 全部使用毛球",content,22)
  text("同一钱包 · 后续等级不补买前段",content,15)
  for n in C.NODES:
   var key: String=n.key
   text(("前置："+model.spec(n.prereq).name+" 1级\n" if n.prereq!="" else "起点\n")+n.description,content,15)
   button(n.name,content,func():model.buy(key);refresh_ui(),key)
 else:
  text("猫咪与船舱配置",content,22)
  for c in model.cats:
   var id: int=c.id
   button(c.name,content,func():select_cat(id),"cat_"+str(id))
  text("猫身小帮手 · 只摘普通毛",content,20)
  button("招募小帮手 · 20 毛球",content,func():model.purchase("worker");show_page("team"),"recruit")
  for w in model.workers:
   var id: int=w.id
   var state_label: Label=text("小帮手 %d"%id,content,17)
   var line:=HBoxContainer.new();content.add_child(line)
   for c in model.cats:
    var cat_id: int=c.id
    var assign_button: Button=button(c.name.split(" · ")[0],line,func():model.assign(id,cat_id);refresh_ui(),"assign_%d_%d"%[id,cat_id])
    assign_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
   var remove_button: Button=button("撤下",line,func():model.assign(id,-1);refresh_ui(),"unassign_"+str(id))
   remove_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
   worker_rows.append({"label":state_label,"worker":w,"line":line})
  text("设施提供加成，猫不进工作台",content,18)
  button("购买生长灯 · 20 毛球",content,func():model.purchase("buff");show_page("team"),"buy_buff")
  button("生长灯 → 当前猫",content,func():model.set_buff(view.selected);refresh_ui(),"buff_assign")
  button("关闭生长灯加成",content,func():model.set_buff(-1);refresh_ui(),"buff_off")
  button("购买盆栽 · 5 毛球（无属性）",content,func():model.purchase("decor");refresh_ui(),"buy_decor")
  text("刺刺为特殊手动样本：小帮手工作会缩回一根待摘毛，不扣已入库毛球。",content,15)
 last_workers=model.workers.size();last_cats=model.cats.size();refresh_ui()
func refresh_ui() -> void:
 if not is_node_ready():return
 heading.text="毛球计划  /  猫身采集原型     %d 毛球\n%s · 累计真实采集 %d"%[model.wallet,C.STAGES[model.stage].name,model.lifetime]
 status.text=("已暂停 · Esc继续" if model.paused else "实际自动收入 %.2f 毛球/s"%total_auto())
 hint.text=model.message
 $BackButton.text="返回船舱 ↓" if view.close_amount>0.5 else "放大当前猫 ↑"
 if page=="tree":
  for n in C.NODES:
   var b: Button=buttons[n.key]
   var lv: int=model.level(n.key);var why: String=model.reason(n.key)
   b.text="%s  %d/%d%s"%[n.name,lv,n.costs.size()," · %d"%n.costs[lv] if lv<n.costs.size() else ""]
   b.disabled=why!="" or model.paused
   b.tooltip_text=n.description+("\n"+why if why!="" else "")
 else:
  buttons.recruit.disabled=model.paused or model.level("worker")==0 or model.wallet<C.WORKER_COST
  buttons.buy_buff.disabled=model.paused or model.level("buff")==0 or model.buff_owned or model.wallet<C.BUFF_COST
  buttons.buff_assign.disabled=model.paused or not model.buff_owned
  buttons.buff_off.disabled=model.paused or model.buff_target<0
  buttons.buy_decor.disabled=model.paused or model.level("buff")==0 or model.decor or model.wallet<C.DECOR_COST
  buttons.buff_assign.text="生长灯 → "+model.cat(view.selected).name
  for row in worker_rows:
   row.label.text="小帮手 %d → %s"%[row.worker.id,"待分配" if row.worker.cat<0 else model.cat(row.worker.cat).name.split(" · ")[0]]
   for b in row.line.get_children():b.disabled=model.paused
func total_auto() -> float:
 var total: float=0.0
 for c in model.cats:total+=model.auto_rate(c)
 return total
func blocked() -> bool:return drawer.visible or manual_pause or transition_left>0
func sync_pause() -> void:model.paused=blocked()
func set_menu(opened: bool) -> void:
 drawer.visible=opened;view.clear_input();sync_pause();refresh_ui()
func load_stage(index: int,fixed_seed: bool=true) -> void:
 model.reset(index,fixed_seed);view.model=model;view.selected=1;view.effects.clear();view.samples.clear();view.sample_revision=-1;view.clear_input()
 transition_left=0;wheel_lock=0;manual_pause=false;pending_selection=-1
 view.close_amount=0.0 if C.STAGES[index].cabin else 1.0;room.set_zoom(view.close_amount)
 drawer.hide();sync_pause();show_page("team" if index in [3,4,7] else "tree")
func select_cat(id: int) -> void:
 if blocked() or model.cat(id).is_empty():return
 if view.close_amount>0.01 and id!=view.selected:
  zoom(false,view.selected);pending_selection=id;return
 view.selected=id;view.clear_input();refresh_ui()
func zoom(inside: bool,id: int) -> void:
 if blocked() or wheel_lock>0 or model.cat(id).is_empty():return
 var target: float=1.0 if inside else 0.0
 if is_equal_approx(target,view.close_amount):return
 view.selected=id;transition_start=view.close_amount;transition_end=target;transition_left=C.TRANSITION
 wheel_lock=C.TRANSITION+0.25;view.clear_input();sync_pause()
func trigger_stage_event() -> void:
 var index: int=model.stage
 if index==2:
  var c: Dictionary=model.cat(view.selected);var has_king: bool=false
  for h in c.hairs.values():
   if h.kind=="king":has_king=true;break
  if not has_king:model.spawn(c,"king",Vector2.ZERO)
 elif index==5:model.trigger_knot(view.selected)
 elif index==6:model.trigger_flea(view.selected)
 elif index==7:
  if not model.trigger_knot(view.selected):model.trigger_flea(view.selected)
 else:model.message="本阶段无强制事件，请体验采集或购买升级"
 set_menu(false)
func _process(dt: float) -> void:
 wheel_lock=maxf(0,wheel_lock-dt)
 if transition_left>0 and not drawer.visible and not manual_pause:
  transition_left=maxf(0,transition_left-dt)
  var t: float=1.0-transition_left/C.TRANSITION
  view.close_amount=lerpf(transition_start,transition_end,smoothstep(0,1,t));room.set_zoom(view.close_amount)
  if transition_left==0 and pending_selection>=0:view.selected=pending_selection;pending_selection=-1
  sync_pause() # Do not advance simulation on the frame completing a transition.
 else:
  sync_pause();model.tick(dt)
 view.step(0.0 if model.paused else dt)
 ui_clock+=dt
 if ui_clock>0.15:
  ui_clock=0
  if page=="team" and (last_workers!=model.workers.size() or last_cats!=model.cats.size()):show_page("team")
  refresh_ui()
func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
  if drawer.visible:set_menu(false)
  else:manual_pause=not manual_pause;view.clear_input();sync_pause();refresh_ui()
  get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  if is_instance_valid(view):view.clear_input()
