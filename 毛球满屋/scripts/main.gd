extends Control
const Dev = preload("res://scripts/developer_tools.gd")
var developer_drawer
const Model = preload("res://scripts/model.gd")
const Room = preload("res://scripts/room.gd")
const D = preload("res://scripts/data.gd")
const SAVE = "user://space_cats_v27.save"
var model = Model.new()
var room
var active: bool = false
var paused: bool = true
var testing: bool = false
var modal: String = ""
var hud
var overlay: PanelContainer
var body: VBoxContainer
var header_label: Label
var hint_label: Label
var notice_label: Label
var bindings: Array = []
var update_clock: float = 0.0
var save_clock: float = 0.0
var status_clock: float = 0.0
var card: PanelContainer
var signal_bar: ProgressBar
var nav_buttons: Dictionary = {}
var graph: GraphEdit
var detail: VBoxContainer
var capsule_busy: bool = false
var tree_selected: String = "worker"
func style(color: String,border: String = "3d586b",radius: int = 8) -> StyleBoxFlat:
 var palette: Dictionary={"152737":"182c38ee","1a2d3e":"f3f0e6","203b4a":"e4e9de","243b4c":"e4e9de","294856":"d9e5d5","3b646c":"c8ddc6","486f68":"b0d0b3","23313e":"e1e3dc","607c87":"bac8b9","526f7e":"b3c7b6","3d586b":"c6d1c1","14282f":"e8dfd2"}
 var s := StyleBoxFlat.new(); s.bg_color = Color(palette.get(color,color)); s.border_color = Color(palette.get(border,border))
 s.set_border_width_all(1); s.set_corner_radius_all(maxi(radius,12))
 s.content_margin_left = 15; s.content_margin_right = 15; s.content_margin_top = 10; s.content_margin_bottom = 10
 return s
func label(value: String,size_px: int = 17,color: String = "334b49") -> Label:
 var l := Label.new(); l.text = value; l.add_theme_font_size_override("font_size",size_px); l.add_theme_color_override("font_color",Color({"dfc794":"776046","a8e1ca":"496950","9ac5c2":"b8d3c4"}.get(color,color)))
 return l
func paragraph(value: String,parent: Node,size_px: int = 16) -> Label:
 var l := label(value,size_px); l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.size_flags_horizontal = SIZE_EXPAND_FILL; parent.add_child(l); return l
func button(value: String,action: Callable,parent: Node) -> Button:
 var b := Button.new(); b.text = value; b.custom_minimum_size.y = 44; b.mouse_default_cursor_shape = CURSOR_POINTING_HAND
 b.pressed.connect(action); parent.add_child(b); return b
func column(parent: Node) -> VBoxContainer:
 var c := VBoxContainer.new(); c.add_theme_constant_override("separation",12); c.size_flags_horizontal = SIZE_EXPAND_FILL; parent.add_child(c); return c
func row(parent: Node) -> HBoxContainer:
 var r := HBoxContainer.new(); r.add_theme_constant_override("separation",12); parent.add_child(r); return r
func clear(parent: Node) -> void:
 for child in parent.get_children(): parent.remove_child(child); child.queue_free()
func live(l: Label,callback: Callable) -> void:
 bindings.append({"node":l,"fn":callback}); l.text = callback.call()
func _ready() -> void:
 get_tree().auto_accept_quit = false
 room=$Room;room.model=model;room.apply_initial_layout(model)
 room.facility_selected.connect(show_facility);room.worker_selected.connect(show_worker);room.gacha_selected.connect(show_gacha)
 room.notice.connect(message);room.build_requested.connect(func(key: String,at: Vector2):transact(func():return model.buy(key,at)))
 hud=$HUD;hud.bind_game(self)
 overlay=$Overlay;card=$Overlay/Center/Card;body=$Overlay/Center/Card/Body
 developer_drawer=$DeveloperDrawer;developer_drawer.bind_game(self)
 room.step(0)
 resized.connect(resize_panel)
 resized.connect(layout_presentation)
 layout_presentation()
 refresh();show_start()
func layout_presentation() -> void:
 if hud == null:return
 hud.position=room.stage_origin();hud.size=Room.Backdrop.DESIGN_SIZE;hud.scale=Vector2.ONE*room.stage_scale()
 hud.show_title(modal=="start")
func screen(title: String,description: String,kind: String,freeze: bool = false) -> VBoxContainer:
 if is_instance_valid(developer_drawer):developer_drawer.hide_panel()
 room.reset_pointer();room.interactive=false;room.placing="";room.moving_id=-1
 modal=kind;paused=freeze;overlay.show();bindings.clear();clear(body);resize_panel();layout_presentation()
 var title_row := row(body);var h := label(title,28,"dfc794");h.size_flags_horizontal=SIZE_EXPAND_FILL;title_row.add_child(h)
 if active: button("返回舱室 ×",close_modal,title_row)
 paragraph(description,body,16)
 var scroll := ScrollContainer.new();scroll.size_flags_vertical=SIZE_EXPAND_FILL;scroll.size_flags_horizontal=SIZE_EXPAND_FILL;body.add_child(scroll)
 var content := column(scroll);content.size_flags_horizontal=SIZE_EXPAND_FILL
 return content
func resize_panel() -> void:
 if not is_instance_valid(card):return
 overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 if modal=="start":
  var factor: float=room.stage_scale()
  var origin: Vector2=room.stage_origin()
  overlay.offset_left=origin.x+510*factor;overlay.offset_right=origin.x+930*factor-size.x
  overlay.offset_top=origin.y+505*factor;overlay.offset_bottom=origin.y+790*factor-size.y
  card.custom_minimum_size=Vector2(330*factor,0)
  return
 var wide: bool=modal=="tree"
 card.custom_minimum_size=Vector2(minf(1300 if wide else 930,size.x-80),minf(675 if wide else 620,size.y-160))
func bind_button(b: Button, text_fn: Callable, disabled_fn: Callable) -> void:
 bindings.append({"node":b,"fn":text_fn,"disabled":disabled_fn});b.text=text_fn.call();b.disabled=disabled_fn.call()
func close_modal() -> void:
 if is_instance_valid(developer_drawer):developer_drawer.hide_panel()
 if not active: show_start();return
 if modal == "contact": model.accept_contact();save_game()
 modal="";paused=false;bindings.clear();overlay.hide();room.interactive=true;room.reset_pointer();refresh();layout_presentation()
func show_start() -> void:
 screen("Purr Orbit / 毛球计划","一群奇妙的室友，一台来自未知文明的仪器。","start",true)
 clear(body)
 var content=preload("res://scenes/ui/start_menu.tscn").instantiate();body.add_child(content)
 content.get_node("NewGame").pressed.connect(new_game_prompt)
 var load_button: Button=content.get_node("Continue")
 load_button.pressed.connect(func():
  if model.load_from(SAVE):room.model=model;active=true;close_modal()
  else:message("存档无法读取，原件没有覆盖");paragraph("无法读取当前存档；请尝试下方的备份恢复。",content))
 load_button.disabled=not FileAccess.file_exists(SAVE)
 var backup: Button=content.get_node("RestoreBackup")
 backup.visible=FileAccess.file_exists(SAVE+".bak")
 backup.pressed.connect(func():
  if model.load_from(SAVE+".bak"):room.model=model;active=true;close_modal()
  else:paragraph("备份也无法读取；原文件已保留。",content))
 content.get_node("Settings").pressed.connect(show_settings)
func new_game_prompt() -> void:
 if FileAccess.file_exists(SAVE):
  var content := screen("开始新的驻留？","会开始一份新的驻留进度。当前进度留有自动备份，旧版本存档保留。","new_confirm",true)
  button("确认开始新游戏",start_game,content);button("取消",show_pause if active else show_start,content)
 else: start_game()
func start_game() -> void:
 model=Model.new();room.apply_initial_layout(model);room.model=model;room.effects.clear();active=true;save_clock=0;close_modal();save_game()
func message(value: String) -> void:
 notice_label.text=value;status_clock=7.0
func transact(action: Callable) -> bool:
 var result: bool = bool(action.call())
 if not result: message(model.error)
 else: save_game()
 refresh();return result
func refresh() -> void:
 header_label.text="%s 毛球    ◇ %d\n收藏批次 %d · 猫 %d · 帮手 %d" % [format_money(model.wallet),model.tokens,model.round_no,model.cats.size(),model.workers.size()]
 hint_label.text="代币已集齐 · 等待回应" if model.minted==36 and model.owned.size()<36 else ("信号已全部收到" if model.owned.size()==36 else "下一枚代币  %d%%" % roundi(model.signal_progress()*100))
 signal_bar.value=model.signal_progress()*100
 nav_buttons.workers.visible=not model.workers.is_empty()
 nav_buttons.inventory.visible=model.has("arcade") or not model.inventory.is_empty()
 nav_buttons.inventory.text="仓库 · %d" % model.inventory.size() if not model.inventory.is_empty() else "仓库"
 nav_buttons.gacha.visible=model.first_token
 nav_buttons.gacha.text="仪器 · %d" % model.tokens if model.gacha_ready else "未知信号"
 for entry in bindings:
  if is_instance_valid(entry.node):
   entry.node.text=entry.fn.call()
   if entry.has("disabled"):entry.node.disabled=entry.disabled.call()
func format_money(amount: float) -> String:
 return "%.1fk" % (amount/1000.0) if amount>=10000 else "%.0f" % amount
func _process(dt: float) -> void:
 room.refresh_hover()
 if active and not paused:
  model.tick(minf(dt,0.1))
  for e in model.events:
   if e.kind == "notice": message(e.text)
   else: room.consume_event(e)
  model.events.clear()
  save_clock+=dt
  if save_clock>=10: save_clock=0;save_game()
  if model.first_token and not model.gacha_ready and modal not in ["contact","pause","settings","developer"]: show_contact()
 room.step(dt)
 update_clock+=dt;status_clock-=dt
 if update_clock>=0.25:
  update_clock=0;refresh()
  if status_clock<=0 and active: notice_label.text=guidance()
func guidance() -> String:
 if room.placing!="":return "点击地板摆放"+D.title(room.placing)+"；右键取消，落地时才扣款。"
 if room.moving_id>=0:return "选择设备的新位置；右键取消。"
 if model.owned.size()==36:return "所有回声都已收到。留在这里，继续陪伴你的猫咪吧。"
 if model.harvests<2:return "悬停让猫停下，来回摸猫完成收割；收获动作结束后可再摸。按住可以搬猫。"
 if not model.has("worker"):return "成长树已出现毛球精灵。先研究，再去商店招募，让它接手收割。"
 if model.workers.is_empty():return "精灵研究完成了。到商店招募一个真正的小帮手。"
 if not model.has("feeder"):return "喂食器能增加产毛量。成长树开放能力，商店购买实体。"
 for f in model.facilities:
  if f.bugs>0:return "喂食器里出现了蟑螂，产量正在下降！点击设施打开内部清理。"
  if f.broken:return "娱乐设施黑屏停产。点击捶打恢复，或解锁工人维护再分配维修岗位。"
 if not model.has("sun"):return "继续研发日光浴；将猫拖进去，它会更快长出一层毛，再自行离开。"
 if not model.has("hats"):return "新的照料工作出现了。到成长面板解锁职责帽，给小帮手分工。"
 if not model.has("arcade"):return "娱乐设施已开放：让一只猫去赢取小物件，生产也会推动信号进度。"
 for f in model.facilities:
  if f.kind=="feeder" and f.grain==0:return "喂食器空了。点击设备补粮；库存不足时可直接购买。"
 return "攒毛、喂食和娱乐中奖，都能让下一个信号更快抵达。"
func show_shop() -> void:
 var content := screen("舱室补给", "添一位室友，或给它们一个新的好去处。", "shop")
 var grid := GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",14);grid.add_theme_constant_override("v_separation",14);content.add_child(grid)
 for key in ["short","worker","feeder","sun","arcade","altar"]:
  var tile := PanelContainer.new();tile.custom_minimum_size.x=410;tile.size_flags_horizontal=SIZE_EXPAND_FILL;tile.add_theme_stylebox_override("panel",style("203b4a"));grid.add_child(tile)
  var c := column(tile);c.add_child(label(D.title(key),20,"496950"))
  paragraph({"short":"新的软绵绵室友，会在设施中发现另一种自己。","worker":"替你收毛球、补粮和搬猫。","feeder":"猫会自行过来吃粮，吃饱后暂时增产。需要备好猫粮。","sun":"把猫拖进光里，长出一层毛后自行离开。","arcade":"暂停长毛，赢取小物件；在仓库出售。","altar":"一只猫留守产生全局加速，并可能转化外星猫；会干扰娱乐设备。"}[key],c,15)
  var buy_button:=button("",func():
   if model.round_no<D.gate(key):return
   if key!="short" and not model.has(key):show_tree(key)
   elif key in ["short","worker"]:
    transact(func():return model.buy(key,Vector2(model.rng.randf_range(420,850),model.rng.randf_range(420,610))));show_shop()
   else:close_modal();room.placing=key;message("点击舱室空地摆放"+D.title(key)),c)
  bind_button(buy_button,func():
   if model.round_no<D.gate(key):return "首批回声收齐后开放"
   if key!="short" and not model.has(key):return "去研究解锁 →"
   return "购买 · %d 毛球" % model.price(key),func():return model.round_no<D.gate(key) or (model.buy_reason(key)=="" and model.wallet<model.price(key)))
 if model.has("feeder"):
  content.add_child(label("猫粮补给",20))
  var foods:=column(content)
  for i in range(model.lv("feeder","food")+1):
   var food_line:=row(foods)
   var b:=button("",func():transact(func():return model.buy_food(i)),food_line)
   var bulk:=button("一次备好100份 · %d毛球" % (D.FOOD_PRICES[i]*10),func():transact(func():return model.buy_food(i,10)),food_line)
   bind_button(bulk,func():return "一次备好100份 · %d毛球" % (D.FOOD_PRICES[i]*10),func():return model.wallet<D.FOOD_PRICES[i]*10)
   bind_button(b,func():return "%s ×10 · %d毛球  /  库存%d" % [D.FOOD_NAMES[i],D.FOOD_PRICES[i],model.food[i]],func():return model.wallet<D.FOOD_PRICES[i])
func show_tree(subject: String = "worker") -> void:
 preload("res://scripts/tree_ui.gd").show_tree(self,subject)
func show_tree_detail(key: String) -> void:
 preload("res://scripts/tree_ui.gd").detail(self,key)
func focus_tree(key: String) -> void:
 preload("res://scripts/tree_ui.gd").focus(self,Model.T.SUBJECTS.get(key,key))
func show_facility(id: int) -> void:
 var f: Dictionary=model.facility(id)
 if f.is_empty():return
 var content := screen(D.title(f.kind), "点击设备操作；回到场地后，也可以直接把猫拖进对应区域。", "facility")
 var info := label("");content.add_child(info)
 live(info,func():return "料仓 %d / %d   ·   蟑螂 %d" % [f.grain,model.feed_capacity(),f.bugs] if f.kind=="feeder" else "占用 %d / %d   %s" % [model.occupants(id).size(),model.capacity(f),"黑屏 · 停止产出" if f.broken else "正常运行"])
 if f.kind=="feeder":
  paragraph("猫会自行前来进食；吃饱后离开也能保持加成。你和小帮手负责补粮。",content,15)
  var options := row(content)
  for i in range(D.FOOD_NAMES.size()):
   var b := button("补入%s（库存%d）" % [D.FOOD_NAMES[i],model.food[i]],func():transact(func():return model.refill(id,i));show_facility(id),options)
   b.disabled=i>model.lv("feeder","food")
  button("备好当前猫粮 ×100 · %d 毛球" % (D.FOOD_PRICES[int(f.food_kind)]*10),func():transact(func():return model.buy_food(int(f.food_kind),10));show_facility(id),content)
  var bug_box := PanelContainer.new();bug_box.add_theme_stylebox_override("panel",style("14282f","b17875"));bug_box.custom_minimum_size.y=130;content.add_child(bug_box)
  var inside := column(bug_box);inside.add_child(label("喂食器内部  /  太空偷渡客",21,"805947"))
  if f.bugs>0:
   paragraph("虫害会取消增产并降低产量。连续点击清除，每只需要两下。",inside)
   button("捶它！  × %d 只蟑螂   [%d/2]" % [f.bugs,f.hits],func():model.clean(id);save_game();show_facility(id),inside)
  else: paragraph("内部干净。"+(" 建好日光浴后需定期打理，工人也可以接手。"),inside)
 elif f.kind=="arcade" and f.broken:
  var repair_label := label("");content.add_child(repair_label);live(repair_label,func():return "黑屏维修：%d / 6" % f.hits if f.broken else "画面恢复，设备已重新产出")
  button("捶打设备",func():model.repair(id);save_game();refresh(),content)
 else:
  for c in model.occupants(id):button("让%s回到场地" % D.title(c.kind),func():model.move_cat(c.id,f.pos+Vector2(0,110));save_game();show_facility(id),content)
  var free := row(content)
  for c in model.cats:
   if c.station==-1:
    button("送入 %s #%d" % [D.title(c.kind),c.id],func():transact(func():return model.assign(c.id,id));show_facility(id),free)
    if free.get_child_count()>=5:break
 var actions := row(content)
 button("移动设备",func():close_modal();room.moving_id=id,actions)
 button("查看分支升级",func():show_tree(f.kind),actions)
func show_workers() -> void:
 var content := screen("毛球精灵 · 职责台", "设施带来新能力，工人接手劳动。没有掉落物拾取岗位；补粮工人使用已购买的猫粮。", "workers")
 var strategy:=label("");content.add_child(strategy)
 live(strategy,func():return "收割门槛 %d 层 · 产出后CD %.2f秒" % [model.worker_target(),model.worker_cooldown()])
 button("升级收割策略与CD",func():show_tree("worker"),content)
 paragraph("层数升级每级增加1层门槛；可自行决定是否购买。蓝条为各自收割CD，期间仍能补粮、清虫和搬猫。",content,15)
 if not model.has("hats"):paragraph("固定分工在成长树解锁职责帽后开放；当前工人会自主照料。",content)
 if model.workers.is_empty():button("去招募一个小帮手",show_shop,content)
 for w in model.workers:
  var line := row(content);var text_label := label("");text_label.custom_minimum_size.x=460;line.add_child(text_label)
  live(text_label,func():return "精灵 #%d · %s · %s\n收割CD %.1f秒" % [w.id,D.ROLES[w.role],w.status,w.get("cooldown",0.0)])
  var select := OptionButton.new();select.custom_minimum_size=Vector2(220,42);line.add_child(select)
  var keys: Array=D.ROLES.keys()
  for i in range(keys.size()):
   select.add_item(D.ROLES[keys[i]],i)
   if keys[i]==w.role:select.select(i)
   select.set_item_disabled(i,(keys[i]!="general" and not model.has("hats")) or (keys[i]=="repair" and not model.has("maint")) or (keys[i]=="arcade" and not model.has("arcade")) or (keys[i]=="altar" and not model.has("altar")))
  select.item_selected.connect(func(index:int):transact(func():return model.set_role(w.id,keys[index])))
  if model.node_owned("S10"):
   var group_pick:=OptionButton.new();line.add_child(group_pick)
   for i in range(model.group_count()):group_pick.add_item("猫群 "+str(i+1),i)
   group_pick.select(w.get("group",0));group_pick.item_selected.connect(func(index:int):transact(func():return model.set_group("worker",w.id,index)))
 if model.node_owned("S10"):show_groups(content)
func show_groups(content: VBoxContainer) -> void:
 paragraph("猫群与照料预设：工人只接手自己组的猫；目标层不超过已付费上限。",content)
 for group in range(model.group_count()):
  var line:=row(content);line.add_child(label("猫群 "+str(group+1)))
  var target:=OptionButton.new();line.add_child(target)
  for n in range(1,model.worker_target()+1):target.add_item("收割目标 %d层" % n,n)
  target.select(mini(model.group_settings[group].target,model.worker_target())-1)
  target.item_selected.connect(func(index:int):transact(func():return model.set_group_target(group,index+1)))
  if model.node_owned("S20"):
   var rounds:=SpinBox.new();rounds.min_value=0;rounds.max_value=20;rounds.step=1;rounds.prefix="娱乐轮次";rounds.suffix="（0不限）";rounds.value=model.group_settings[group].rounds;line.add_child(rounds)
   rounds.value_changed.connect(func(v:float):transact(func():return model.set_group_target(group,model.group_settings[group].target,int(v))))
 for c in model.cats:
  var line:=row(content);line.add_child(label("%s #%d" % [D.title(c.kind),c.id]))
  var pick:=OptionButton.new();line.add_child(pick)
  for i in range(model.group_count()):pick.add_item("猫群 "+str(i+1),i)
  pick.select(c.get("group",0));pick.item_selected.connect(func(index:int):transact(func():return model.set_group("cat",c.id,index)))
  if model.node_owned("XBC"):
   var boost:=CheckButton.new();boost.text="满载入场：消耗多余毛层";boost.button_pressed=c.get("use_boost",false);line.add_child(boost)
   boost.toggled.connect(func(v:bool):c.use_boost=v;save_game())
func show_worker(_id: int) -> void:
 show_workers()
func show_inventory() -> void:
 var content := screen("猫咪的小仓库", "赢来的小物件会自动送来。卖出后才会变成毛球。", "inventory")
 var info := label("");content.add_child(info)
 live(info,func():return "%d 件小物件   ·   合计 %s 毛球" % [model.inventory.size(),format_money(inventory_value())])
 var sell:=button("",func():message("出售获得 %.1f 毛球" % model.sell_all());save_game();show_inventory(),content)
 bind_button(sell,func():return "出售未预留物品（库存%d件） · %s 毛球" % [model.inventory.size(),format_money(inventory_value())],func():return model.inventory.is_empty())
 var groups: Dictionary={}
 for item in model.inventory:
  if not groups.has(item.name):groups[item.name]={"count":0,"value":0.0}
  groups[item.name].count+=1;groups[item.name].value+=model.Build.sale_value(model,item)
 for name in groups:
  content.add_child(label("%s    ×%d       %s 毛球" % [name,groups[name].count,format_money(groups[name].value)],19))
 if groups.is_empty():paragraph("还空着呢。去看看猫咪在娱乐设施里发现了什么。",content,19)
 if model.node_owned("C1M"):
  paragraph("订单预留：自动收集所需实物，齐全后手动提交。普通出售保留已预留物品。",content)
  var choices:=row(content)
  for kind in ["pair","trio","set"]:
   var create:=button({"pair":"预留2件同款","trio":"预留3件不同","set":"预留5件不同"}[kind],func():transact(func():return model.Build.create_order(model,kind));show_inventory(),choices)
   create.disabled=not model.Build.order_unlocked(model,kind)
  for i in range(model.orders.size()):
   var order: Dictionary=model.orders[i];var line:=row(content)
   line.add_child(label("清单%d · %d/%d件 · ×%.2f" % [i+1,order.ids.size(),model.Build.order_size(order.kind),model.Build.order_factor(model,order.kind)]))
   button("提交",func():message("订单获得 %.1f 毛球" % model.Build.sell(model,i));save_game();show_inventory(),line)
   button("取消预留",func():model.orders.remove_at(i);model.Build.refresh_orders(model);save_game();show_inventory(),line)
func inventory_value() -> float:
 var value: float=0.0
 for item in model.inventory:
  if not model.Build.reserved_ids(model).has(item.id):value+=model.Build.sale_value(model,item)
 return value
func show_contact() -> void:
 var content := screen("……你听见了吗？", "舱窗外，一个猫咪形状的轮廓正在望着你。", "contact",true)
 var portrait := label("◀   ●   ●   ▶",56,"acd6c7");portrait.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(portrait)
 paragraph("“它认得你手里的东西。”" if not model.contact_seen else "熟悉的图腾再次亮起。这一次，旋钮后面多了几个陌生的回声。",content,24)
 paragraph("一台刻满猫咪图腾的仪器出现在舱室里。正面有一道投币口，和一只安静的旋钮。",content,21)
 button("接过仪器，试着转动旋钮",func():model.accept_contact();save_game();show_gacha(),content)
func show_gacha() -> void:
 if not active:return
 if not model.gacha_ready:
  if model.first_token:show_contact();return
  var c := screen("尚未回应的信号", "猫咪偶尔会留下某种陌生的东西。先继续照料它们。", "gacha")
  paragraph("在场地里收割猫咪积蓄的毛层，也许很快就会知道。",c,24);return
 var content := screen("猫咪图腾 · 未知仪器", "投币，转动旋钮。每一次回应都是你尚未拥有的收藏。", "gacha")
 var info := label("");content.add_child(info);live(info,func():return "代币 %d    ·    本批 %d / %d    ·    全部 %d / 36" % [model.tokens,(12 if model.round_no==1 else 24)-model.pool().size(),12 if model.round_no==1 else 24,model.owned.size()])
 var draw:=button("",pull_capsule,content)
 bind_button(draw,func():return "投入 1 枚代币 · 转动旋钮" if not model.pool().is_empty() else "回声已收齐",func():return model.pool().is_empty() or model.tokens<1)
 var grid := GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);content.add_child(grid)
 for s in D.SERIES:
  if int(s.round)>model.round_no:continue
  var card := PanelContainer.new();card.custom_minimum_size=Vector2(410,120);card.add_theme_stylebox_override("panel",style("243b4c",s.color));grid.add_child(card)
  var col := column(card);var count_owned: int=0
  for i in range(D.SERIES_SIZE):
   if model.owned.has(s.id+":"+str(i)):count_owned+=1
  col.add_child(label(s.name,18,"496950"));paragraph("%d / 6    %s +%.1f%%" % [count_owned,s.label,count_owned*float(s.full)/D.SERIES_SIZE*100],col,15)
  var marks: PackedStringArray=[]
  for i in range(D.SERIES_SIZE):marks.append("◆" if model.owned.has(s.id+":"+str(i)) else "◇")
  col.add_child(label("  ".join(marks),23,"776046"))
 if model.pool().is_empty():paragraph("这段旅程的36个回声都已收到。谢谢你的陪伴，还可以继续照料猫咪。",content,22)
func pull_capsule() -> void:
 if capsule_busy:return
 var key: String=model.draw_capsule()
 if key=="":message(model.error);return
 capsule_busy=true;save_game()
 var content := screen("一枚陌生的回声", "旋钮转过一圈，图腾依次亮起。", "capsule",true)
 var orb := label("◈",100,"dfc794");orb.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(orb)
 var tween := create_tween();orb.modulate.a=0.2;tween.tween_property(orb,"modulate:a",1.0,0.4)
 paragraph(D.collectible_name(key),content,27)
 for s in D.SERIES:
  if key.begins_with(s.id+":"):paragraph("收藏加成：%s +%.1f%%
回到舱室，就能感受到它的变化。" % [s.label,float(s.full)/D.SERIES_SIZE*100],content,22)
 if model.owned.size()==12:paragraph("新的信号抵达了：24个新回声，以及新的舱室补给。你的猫咪和全部进度都留在这里。",content,19)
 button("带着新的回声返回仪器",func():capsule_busy=false;show_gacha(),content)
 capsule_busy=false
func show_pause() -> void:
 if not active:return
 var content := screen("驻留暂停", "猫咪、设备、工人和故障计时都已暂停。", "pause",true)
 button("继续驻留",close_modal,content);button("保存进度",func():message("已保存" if save_game() else "保存失败，请查看权限"),content)
 button("设置",show_settings,content);button("操作帮助",show_help,content);button("重新开始…",new_game_prompt,content)
 button("开发者工具",show_developer,content)
 button("退出游戏",func():save_game();get_tree().quit(),content)
func show_settings() -> void:
 var content := screen("设置", "视觉设置。", "settings",true)
 var reduced := CheckButton.new();reduced.text="减少收益粒子";reduced.button_pressed=room.reduced;reduced.toggled.connect(func(v:bool):room.reduced=v);content.add_child(reduced)
 var fullscreen := CheckButton.new();fullscreen.text="全屏显示";fullscreen.button_pressed=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN;fullscreen.toggled.connect(func(v:bool):DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if v else DisplayServer.WINDOW_MODE_WINDOWED));content.add_child(fullscreen)
 button("返回",show_pause if active else show_start,content)
func show_help() -> void:
 var content := screen("驻留手册", "让旧工作逐渐交给小帮手，把注意力留给新的发现。", "help",true)
 paragraph("① 不按键，在猫身上来回移动：收割。停手后3秒内可接续；脚下短条显示进度。等多层再收，产量更高。收获动作结束后可再次摸这只猫。
② 按住猫拖动：搬猫；松在设施上可指派，松在空地则回到场地。
③ 成长树研发能力 → 商店购买实体 → 点击地板摆放。右键取消摆放。
④ 点击喂食器补粮；出现虫害时打开内部连续点击清除。
⑤ 成长树可付费提高工人收割层数、缩短CD；职责帽安排固定岗位，分组照料可设各组目标。
⑥ 收割和娱乐中奖推进代币进度。12个回声收齐后补入24个，全部经营进度保留。",content,22)
 paragraph("不必急着收第一层毛。多攒几层，可以获得更多毛球与信号进度。",content,16)
 paragraph("开发测试：开始游戏后，悬停屏幕最左侧“开发工具”查看提示，点击展开菜单。数字快捷键已取消；菜单可生成五种猫并保留资源、设施和流程测试。",content,16)
 if not active:button("返回开始界面",show_start,content)
func save_game() -> bool:
 if testing or not active:return true
 var result: Error=model.save_to(SAVE)
 if result!=OK:message("存档写入失败，请检查磁盘空间；当前游戏仍在运行。")
 return result==OK
func _unhandled_key_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
  if modal=="":show_pause()
  elif active:close_modal()
  get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
 if what==NOTIFICATION_WM_CLOSE_REQUEST:save_game();get_tree().quit()

func show_developer() -> void:
 if not active:return
 close_modal()
 if hud.has_method("set_open"):hud.set_open(false)
 room.reset_pointer();room.interactive=false;room.placing="";room.moving_id=-1
 modal="developer";paused=true
 developer_drawer.open_panel()
func developer_command(key: String) -> void:
 if not active:return
 var result: String=Dev.execute(model,key)
 room.step(0);refresh()
 if is_instance_valid(developer_drawer):developer_drawer.feedback.text=result
 if save_game():message("[开发] "+result)

func _input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo or not active:return
 if event.keycode!=KEY_L or event.alt_pressed or event.meta_pressed or event.shift_pressed or event.ctrl_pressed:return
 var focused: Control=get_viewport().gui_get_focus_owner()
 if focused is LineEdit or focused is TextEdit:return
 developer_command("static")
 get_viewport().set_input_as_handled()
