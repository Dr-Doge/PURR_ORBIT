extends Control
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
func create_room():
 return Room.new()
func create_hud():
 return preload("res://scripts/station_hud.gd").new()
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
 add_child(preload("res://scripts/game_cursor.gd").new())
 var font := SystemFont.new(); font.font_names = PackedStringArray(["Microsoft YaHei","Segoe UI"])
 var skin := Theme.new(); skin.default_font = font; skin.default_font_size = 16
 for state in ["normal","hover","pressed","disabled","focus"]:
  skin.set_stylebox(state,"Button",style({"normal":"294856","hover":"3b646c","pressed":"486f68","disabled":"23313e","focus":"294856"}[state],"526f7e"))
 skin.set_color("font_color","Label",Color("334b49"));skin.set_color("font_color","CheckButton",Color("334b49"))
 skin.set_color("font_color","Button",Color("304b43")); skin.set_color("font_disabled_color","Button",Color("8c988d")); theme = skin
 room = create_room(); room.model = model; room.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(room)
 room.facility_selected.connect(show_facility); room.worker_selected.connect(show_worker); room.gacha_selected.connect(show_gacha)
 room.notice.connect(message); room.build_requested.connect(func(key: String,at: Vector2): transact(func(): return model.buy(key,at)))
 hud=create_hud();hud.game=self;add_child(hud)
 overlay=PanelContainer.new();overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT);overlay.add_theme_stylebox_override("panel",style("0a1823bb","0a182300",0));add_child(overlay)
 var center:=CenterContainer.new();overlay.add_child(center)
 card=PanelContainer.new();card.custom_minimum_size=Vector2(820,580);card.add_theme_stylebox_override("panel",style("1a2d3e","607c87",22));center.add_child(card)
 body=column(card)
 resized.connect(resize_panel)
 resized.connect(layout_presentation)
 layout_presentation()
 refresh();show_start()
func layout_presentation() -> void:
 if hud == null:return
 hud.position=room.stage_origin();hud.size=Room.Backdrop.DESIGN_SIZE;hud.scale=Vector2.ONE*room.stage_scale()
 hud.show_title(modal=="start")
func screen(title: String,description: String,kind: String,freeze: bool = false) -> VBoxContainer:
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
 if not active: show_start();return
 if modal == "contact": model.accept_contact();save_game()
 modal="";paused=false;bindings.clear();overlay.hide();room.interactive=true;room.reset_pointer();refresh();layout_presentation()
func show_start() -> void:
 var content := screen("Purr Orbit / 毛球计划", "一群奇妙的室友，一台来自未知文明的仪器。", "start",true)
 clear(body);content=column(body)
 button("开始游戏",new_game_prompt,content)
 var load_button := button("继续游戏",func():
  if model.load_from(SAVE): room.model=model;active=true;close_modal()
  else: message("存档无法读取，原件没有覆盖");paragraph("无法读取当前存档；请尝试下方的备份恢复。",content),content)
 load_button.disabled = not FileAccess.file_exists(SAVE)
 if FileAccess.file_exists(SAVE+".bak"):
  button("从自动备份继续",func():
   if model.load_from(SAVE+".bak"):room.model=model;active=true;close_modal()
   else:paragraph("备份也无法读取；原文件已保留。",content),content)
 button("设置",show_settings,content)
func new_game_prompt() -> void:
 if FileAccess.file_exists(SAVE):
  var content := screen("开始新的驻留？","会开始一份新的驻留进度。当前进度留有自动备份，旧版本存档保留。","new_confirm",true)
  button("确认开始新游戏",start_game,content);button("取消",show_pause if active else show_start,content)
 else: start_game()
func start_game() -> void:
 model=Model.new();room.model=model;room.effects.clear();active=true;save_clock=0;close_modal();save_game()
func message(value: String) -> void:
 notice_label.text=value;status_clock=7.0
func transact(action: Callable) -> bool:
 var result: bool = bool(action.call())
 if not result: message(model.error)
 else: save_game()
 refresh();return result
func refresh() -> void:
 header_label.text="%s 毛球    ◇ %d\n阶段 %d · 猫 %d · 帮手 %d" % [format_money(model.wallet),model.tokens,model.round_no,model.cats.size(),model.workers.size()]
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
  if model.first_token and not model.gacha_ready and modal not in ["contact","pause","settings"]: show_contact()
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
 if model.round_no==2 and not model.has("hats"):return "新的照料工作出现了。到成长面板解锁职责帽，给小帮手分工。"
 if model.round_no==2 and not model.has("arcade"):return "娱乐设施已开放：让一只猫去赢取小物件，生产也会推动信号进度。"
 for f in model.facilities:
  if f.kind=="feeder" and f.grain==0:return "喂食器空了。点击设备补粮；库存不足时可直接购买。"
 return "攒毛、喂食和娱乐中奖，都能让下一个信号更快抵达。"
func show_shop() -> void:
 var content := screen("舱室补给", "添一位室友，或给它们一个新的好去处。", "shop")
 var grid := GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",14);grid.add_theme_constant_override("v_separation",14);content.add_child(grid)
 for key in ["short","worker","feeder","sun","arcade"]:
  var tile := PanelContainer.new();tile.custom_minimum_size.x=410;tile.size_flags_horizontal=SIZE_EXPAND_FILL;tile.add_theme_stylebox_override("panel",style("203b4a"));grid.add_child(tile)
  var c := column(tile);c.add_child(label(D.title(key),20,"496950"))
  paragraph({"short":"新的软绵绵室友，会在设施中发现另一种自己。","worker":"替你收毛球、补粮和搬猫。","feeder":"猫会自行过来吃粮，吃饱后暂时增产。需要备好猫粮。","sun":"把猫拖进光里，长出一层毛后自行离开。","arcade":"暂停长毛，赢取小物件；在仓库出售。"}[key],c,15)
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
 tree_selected=subject
 var content := screen("成长树  /  向上探索", "先选一个方向，再看看它带来的变化。旁支不必升满，研究后在补给中购买实体。", "tree")
 var jumps := row(content)
 for target in D.RESEARCH:
  if D.gate(target)>D.MAX_STAGE:continue
  button(D.title(target),func():show_tree_detail(target);focus_tree(target),jumps)
 var layout := row(content);layout.custom_minimum_size.y=415
 graph=GraphEdit.new();graph.custom_minimum_size=Vector2(790,400);graph.size_flags_horizontal=SIZE_EXPAND_FILL;graph.minimap_enabled=false;graph.show_arrange_button=false;graph.show_grid_buttons=false;graph.show_minimap_button=false;graph.show_grid=false;graph.add_theme_stylebox_override("panel",style("e5e9df"));layout.add_child(graph)
 detail=column(layout);detail.custom_minimum_size.x=320
 for key in D.RESEARCH:
  if D.gate(key)>D.MAX_STAGE:continue
  var spec: Dictionary=D.RESEARCH[key]
  var node := GraphNode.new();node.name=key;node.title=D.title(key);node.position_offset=spec.pos;node.custom_minimum_size.x=215;graph.add_child(node)
  var state: String = "已解锁" if model.has(key) else ("首批回声收齐后" if model.round_no<spec.round else "研究 %d 毛球" % spec.price)
  node.add_theme_stylebox_override("panel",style("f5f2e8"));node.add_theme_stylebox_override("titlebar",style("c8d7c1","c8d7c1"));node.add_theme_color_override("title_color",Color("334b49"))
  button(state,func():show_tree_detail(key),node)
  node.set_slot(0,true,0,Color("95c9bd"),true,0,Color("95c9bd"))
  if D.BRANCHES.has(key):
   var desc := label("＋ "+" / ".join(D.BRANCHES[key].keys()),12,"8faeae")
   desc.text="＋ %d 项独立分支" % D.BRANCHES[key].size();node.add_child(desc)
 for key in D.RESEARCH:
  if D.gate(key)>D.MAX_STAGE:continue
  for pre in D.RESEARCH[key].pre: graph.connect_node(pre,0,key,0)
 for key in D.BRANCHES:
  var index: int = 0
  for branch in D.BRANCHES[key]:
   var spec: Array = D.BRANCHES[key][branch]
   var node := GraphNode.new();node.name=key+"_"+branch;node.title=spec[0]
   node.position_offset=D.RESEARCH[key].pos+Vector2(-230+(index%3)*235,-180-(index/3)*150)
   node.custom_minimum_size.x=185;graph.add_child(node)
   node.add_theme_stylebox_override("panel",style("edf0e6"));node.add_theme_stylebox_override("titlebar",style("c8d7c1","c8d7c1"));node.add_theme_color_override("title_color",Color("334b49"))
   button("%d / %d · 查看强化" % [model.lv(key,branch),spec[2]],func():show_tree_detail(key),node)
   node.set_slot(0,true,0,Color("dec18d"),false,0,Color("dec18d"))
   graph.connect_node(key,0,node.name,0);index+=1
 show_tree_detail(subject)
 focus_tree(subject)
func focus_tree(subject: String) -> void:
 var target_graph: GraphEdit = graph
 await get_tree().process_frame
 await get_tree().process_frame
 if not is_instance_valid(target_graph) or target_graph!=graph:return
 target_graph.scroll_offset=D.RESEARCH[subject].pos-Vector2(300,260)
func show_tree_detail(key: String) -> void:
 clear(detail);tree_selected=key
 detail.add_child(label(D.title(key),23,"dfc794"));paragraph(D.RESEARCH[key].desc,detail)
 var cash := label("");detail.add_child(cash);live(cash,func():return "毛球："+format_money(model.wallet))
 var why: String = model.research_reason(key)
 paragraph(("已解锁 · 立即生效" if key=="hats" else "已解锁 · 实体在补给中购买") if model.has(key) else (why if why!="" else "研究费用：%d 毛球" % D.RESEARCH[key].price),detail)
 var b := button("研发主体",func():transact(func():return model.research(key));show_tree(key),detail);bind_button(b,func():return "已解锁" if model.has(key) else "研究 · %d 毛球" % D.RESEARCH[key].price,func():return why!="" or model.wallet<D.RESEARCH[key].price)
 for branch in D.BRANCHES.get(key,{}):
  var spec: Array=D.BRANCHES[key][branch];var cost: int=model.upgrade_price(key,branch)
  paragraph(D.branch_effect(key,branch,model.lv(key,branch))+" → "+D.branch_effect(key,branch,mini(model.lv(key,branch)+1,int(spec[2]))),detail,14)
  var bt := button("%s %d/%d · %s" % [spec[0],model.lv(key,branch),spec[2],str(cost)+"毛球" if cost>=0 else "已满"],func():transact(func():return model.upgrade(key,branch));show_tree_detail(key),detail)
  bind_button(bt,func():return "%s %d/%d · %s" % [spec[0],model.lv(key,branch),spec[2],str(cost)+"毛球" if cost>=0 else "已满"],func():return not model.has(key) or cost<0 or model.wallet<cost)
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
  else: paragraph("内部干净。"+(" 第一阶段不会发生虫害。" if model.round_no==1 else "工人也可以接手打理。"),inside)
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
 if not model.has("hats"):paragraph("固定分工在第二阶段解锁职责帽后开放；当前工人会自主照料。",content)
 if model.workers.is_empty():button("去招募一个小帮手",show_shop,content)
 for w in model.workers:
  var line := row(content);var text_label := label("");text_label.custom_minimum_size.x=460;line.add_child(text_label)
  live(text_label,func():return "精灵 #%d · %s · %s\n收割CD %.1f秒" % [w.id,D.ROLES[w.role],w.status,w.get("cooldown",0.0)])
  var select := OptionButton.new();select.custom_minimum_size=Vector2(220,42);line.add_child(select)
  var keys: Array=D.ROLES.keys()
  for i in range(keys.size()):
   select.add_item(D.ROLES[keys[i]],i)
   if keys[i]==w.role:select.select(i)
   select.set_item_disabled(i,(keys[i]!="general" and not model.has("hats")) or (keys[i]=="repair" and not model.has("maint")) or (keys[i]=="arcade" and not model.has("arcade")) or (keys[i]=="altar" and not model.has("altar")) or (keys[i]=="clean" and model.round_no<2))
  select.item_selected.connect(func(index:int):transact(func():return model.set_role(w.id,keys[index])))
func show_worker(_id: int) -> void:
 show_workers()
func show_inventory() -> void:
 var content := screen("猫咪的小仓库", "赢来的小物件会自动送来。卖出后才会变成毛球。", "inventory")
 var info := label("");content.add_child(info)
 live(info,func():return "%d 件小物件   ·   合计 %s 毛球" % [model.inventory.size(),format_money(inventory_value())])
 var sell:=button("",func():message("出售获得 %.1f 毛球" % model.sell_all());save_game();show_inventory(),content)
 bind_button(sell,func():return "出售全部 %d 件 · %s 毛球" % [model.inventory.size(),format_money(inventory_value())],func():return model.inventory.is_empty())
 var groups: Dictionary={}
 for item in model.inventory:
  if not groups.has(item.name):groups[item.name]={"count":0,"value":0.0}
  groups[item.name].count+=1;groups[item.name].value+=float(item.value)*model.effect("sale")
 for name in groups:
  content.add_child(label("%s    ×%d       %s 毛球" % [name,groups[name].count,format_money(groups[name].value)],19))
 if groups.is_empty():paragraph("还空着呢。去看看猫咪在娱乐设施里发现了什么。",content,19)
func inventory_value() -> float:
 var value: float=0.0
 for item in model.inventory:value+=float(item.value)*model.effect("sale")
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
 button("退出游戏",func():save_game();get_tree().quit(),content)
func show_settings() -> void:
 var content := screen("设置", "视觉设置。", "settings",true)
 var reduced := CheckButton.new();reduced.text="减少收益粒子";reduced.button_pressed=room.reduced;reduced.toggled.connect(func(v:bool):room.reduced=v);content.add_child(reduced)
 var fullscreen := CheckButton.new();fullscreen.text="全屏显示";fullscreen.button_pressed=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN;fullscreen.toggled.connect(func(v:bool):DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if v else DisplayServer.WINDOW_MODE_WINDOWED));content.add_child(fullscreen)
 button("返回",show_pause if active else show_start,content)
func show_help() -> void:
 var content := screen("驻留手册", "让旧工作逐渐交给小帮手，把注意力留给新的发现。", "help",true)
 paragraph("① 不按键，在猫身上来回移动：收割。等多层再收，产量更高。收获动作结束后可再次摸这只猫。
② 按住猫拖动：搬猫；松在设施上可指派，松在空地则回到场地。
③ 成长树研发能力 → 商店购买实体 → 点击地板摆放。右键取消摆放。
④ 点击喂食器补粮；出现虫害时打开内部连续点击清除。
⑤ 成长树可付费提高工人收割层数或缩短产出后CD；第二阶段职责帽安排固定岗位。
⑥ 收割和娱乐中奖推进代币进度。12个回声收齐后补入24个，全部经营进度保留。",content,22)
 paragraph("不必急着收第一层毛。多攒几层，可以获得更多毛球与信号进度。",content,16)
 if not active:button("返回开始界面",show_start,content)
func save_game() -> bool:
 if testing or not active:return true
 var result: Error=model.save_to(SAVE)
 if result!=OK:message("存档写入失败，请检查磁盘空间；当前游戏仍在运行。")
 return result==OK
func _unhandled_key_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and active and not paused and modal=="" and (testing or "--art-preview" in OS.get_cmdline_user_args()):
  if not event.ctrl_pressed and not event.alt_pressed and not event.meta_pressed and not event.shift_pressed:
   var index: int = [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5].find(event.keycode)
   if index >= 0:
    var at := Vector2(model.rng.randf_range(D.FLOOR.position.x+60,D.FLOOR.end.x-60),model.rng.randf_range(D.FLOOR.position.y+60,D.FLOOR.end.y-60))
    var cat: Dictionary = model.add_cat(model.clamp_position(at))
    cat.kind = ["short","giant","static","lucky","alien"][index]
    message("已添加一只"+D.title(cat.kind))
    room.step(0.0)
    save_game()
    get_viewport().set_input_as_handled()
    return
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
  if modal=="":show_pause()
  elif active:close_modal()
  get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
 if what==NOTIFICATION_WM_CLOSE_REQUEST:save_game();get_tree().quit()
