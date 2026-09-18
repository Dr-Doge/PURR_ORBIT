extends Control
const Model = preload("res://scripts/model.gd")
const Room = preload("res://scripts/room.gd")
const D = preload("res://scripts/data.gd")
const SAVE = "user://space_cats_v26.save"
var model = Model.new()
var room
var active: bool = false
var paused: bool = true
var testing: bool = false
var modal: String = ""
var overlay: PanelContainer
var body: VBoxContainer
var header_label: Label
var hint_label: Label
var notice_label: Label
var bindings: Array = []
var update_clock: float = 0.0
var save_clock: float = 0.0
var status_clock: float = 0.0
var graph: GraphEdit
var detail: VBoxContainer
var capsule_busy: bool = false
var tree_selected: String = "worker"
func style(color: String,border: String = "3d586b",radius: int = 8) -> StyleBoxFlat:
 var s := StyleBoxFlat.new(); s.bg_color = Color(color); s.border_color = Color(border)
 s.set_border_width_all(1); s.set_corner_radius_all(radius)
 s.content_margin_left = 15; s.content_margin_right = 15; s.content_margin_top = 10; s.content_margin_bottom = 10
 return s
func label(value: String,size_px: int = 17,color: String = "d5e6e8") -> Label:
 var l := Label.new(); l.text = value; l.add_theme_font_size_override("font_size",size_px); l.add_theme_color_override("font_color",Color(color))
 return l
func paragraph(value: String,parent: Node,size_px: int = 16) -> Label:
 var l := label(value,size_px); l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.size_flags_horizontal = SIZE_EXPAND_FILL; parent.add_child(l); return l
func button(value: String,action: Callable,parent: Node) -> Button:
 var b := Button.new(); b.text = value; b.custom_minimum_size.y = 42; b.mouse_default_cursor_shape = CURSOR_POINTING_HAND
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
 var font := SystemFont.new(); font.font_names = PackedStringArray(["Microsoft YaHei","Segoe UI"])
 var skin := Theme.new(); skin.default_font = font; skin.default_font_size = 16
 for state in ["normal","hover","pressed","disabled","focus"]:
  skin.set_stylebox(state,"Button",style({"normal":"294856","hover":"3b646c","pressed":"486f68","disabled":"23313e","focus":"294856"}[state],"526f7e"))
 skin.set_color("font_color","Button",Color("e0eeee")); skin.set_color("font_disabled_color","Button",Color("718896")); theme = skin
 room = Room.new(); room.model = model; room.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(room)
 room.facility_selected.connect(show_facility); room.worker_selected.connect(show_worker); room.gacha_selected.connect(show_gacha)
 room.notice.connect(message); room.build_requested.connect(func(key: String,at: Vector2): transact(func(): return model.buy(key,at)))
 var top := PanelContainer.new(); top.set_anchors_and_offsets_preset(PRESET_TOP_WIDE); top.offset_left=24;top.offset_right=-24;top.offset_top=16;top.offset_bottom=88;top.add_theme_stylebox_override("panel",style("152737"));add_child(top)
 var top_row := row(top); var title := label("PURR / ORBIT",23,"a9e4d0"); top_row.add_child(title)
 header_label=label("",19);header_label.size_flags_horizontal=SIZE_EXPAND_FILL;header_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;top_row.add_child(header_label)
 button("帮助",show_help,top_row);button("暂停 · Esc",show_pause,top_row)
 var bottom := PanelContainer.new();bottom.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE);bottom.offset_left=24;bottom.offset_right=-24;bottom.offset_top=-112;bottom.offset_bottom=-16;bottom.add_theme_stylebox_override("panel",style("152737"));add_child(bottom)
 var bottom_col := column(bottom);var actions := row(bottom_col)
 button("＋ 猫咪与设施",show_shop,actions);button("成长树 ↑",func():show_tree(),actions);button("工人分工",show_workers,actions);button("库存 / 换金",show_inventory,actions);button("神秘收藏",show_gacha,actions)
 hint_label=label("",15,"9ac5c2");hint_label.size_flags_horizontal=SIZE_EXPAND_FILL;actions.add_child(hint_label)
 notice_label=label("在猫身上来回移动鼠标收割；按住拖动可以搬猫。",15,"b4c7d1");bottom_col.add_child(notice_label)
 overlay=PanelContainer.new();overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT);overlay.add_theme_stylebox_override("panel",style("101d2cee","101d2c",0));add_child(overlay)
 var margin := MarginContainer.new();margin.add_theme_constant_override("margin_left",64);margin.add_theme_constant_override("margin_right",64);margin.add_theme_constant_override("margin_top",110);margin.add_theme_constant_override("margin_bottom",125);overlay.add_child(margin)
 var card := PanelContainer.new();card.add_theme_stylebox_override("panel",style("1a2d3e","607c87",14));margin.add_child(card)
 body=column(card)
 refresh();show_start()
func screen(title: String,description: String,kind: String,freeze: bool = false) -> VBoxContainer:
 room.reset_pointer();room.interactive=false;room.placing="";room.moving_id=-1
 modal=kind;paused=freeze;overlay.show();bindings.clear();clear(body)
 var title_row := row(body);var h := label(title,28,"dfc794");h.size_flags_horizontal=SIZE_EXPAND_FILL;title_row.add_child(h)
 if active: button("返回舱室 ×",close_modal,title_row)
 paragraph(description,body,16)
 var scroll := ScrollContainer.new();scroll.size_flags_vertical=SIZE_EXPAND_FILL;scroll.size_flags_horizontal=SIZE_EXPAND_FILL;body.add_child(scroll)
 var content := column(scroll);content.size_flags_horizontal=SIZE_EXPAND_FILL
 return content
func close_modal() -> void:
 if not active: show_start();return
 if modal == "contact": model.accept_contact();save_game()
 modal="";paused=false;bindings.clear();overlay.hide();room.interactive=true;room.reset_pointer();refresh()
func show_start() -> void:
 var content := screen("喵星驻留站", "一群奇妙的室友，一台来自未知文明的仪器。", "start",true)
 paragraph("在猫身上来回移动鼠标，收下柔软的毛球。
给它们一点时间，多攒几层会收获更多。
然后把重复的工作交给毛球精灵，去追踪那个陌生的信号。",content,24)
 button("开始第一次停留",new_game_prompt,content)
 var load_button := button("继续上一次的驻留",func():
  if model.load_from(SAVE): room.model=model;active=true;close_modal()
  else: message("存档无法读取，原件没有覆盖");paragraph("无法读取当前存档；请尝试下方的备份恢复。",content),content)
 load_button.disabled = not FileAccess.file_exists(SAVE)
 if FileAccess.file_exists(SAVE+".bak"):
  button("从自动备份继续",func():
   if model.load_from(SAVE+".bak"):room.model=model;active=true;close_modal()
   else:paragraph("备份也无法读取；原文件已保留。",content),content)
 paragraph("Godot 4.7.1 · 三周目可玩原型
鼠标移动抚摸 / 按住拖动搬猫 / 点击设施操作 / Esc 暂停
第一频段：基础经营与日光浴；第二频段：虫害与娱乐；第三频段：祭坛与干扰。",content,16)
func new_game_prompt() -> void:
 if FileAccess.file_exists(SAVE):
  var content := screen("开始新的驻留？","会重置本Demo的当前进度与永久收藏。旧版摸猫存档不受影响。","new_confirm",true)
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
 header_label.text="第 %d 周目    %s 毛球    ◇ %d 代币    猫 %d · 工人 %d" % [model.round_no,format_money(model.wallet),model.tokens,model.cats.size(),model.workers.size()]
 hint_label.text="产毛 ×%.2f   生长 ×%.2f" % [model.effect("yield"),model.effect("speed")]
 for entry in bindings:
  if is_instance_valid(entry.node): entry.node.text=entry.fn.call()
func format_money(amount: float) -> String:
 return "%.1fk" % (amount/1000.0) if amount>=10000 else "%.0f" % amount
func _process(dt: float) -> void:
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
 if model.pool().is_empty():return "仪器正在发出新的信号。打开神秘收藏，回应它。"
 if model.harvests<2:return "在猫身上来回移动鼠标收割；数字是毛层，等待多层更赚。按住可以搬猫。"
 if not model.has("worker"):return "成长树已出现毛球精灵。先研究，再去商店招募，让它接手收割。"
 if model.workers.is_empty():return "精灵研究完成了。到商店招募一个真正的小帮手。"
 if not model.has("feeder"):return "喂食器能增加产毛量。成长树开放能力，商店购买实体。"
 for f in model.facilities:
  if f.bugs>0:return "喂食器里出现了蟑螂，产量正在下降！点击设施打开内部清理。"
  if f.broken:return "娱乐设施黑屏停产。点击捶打恢复，或解锁工人维护再分配维修岗位。"
 if not model.has("sun"):return "继续研发日光浴；将猫拖进去，它会更快长出一层毛，再自行离开。"
 return "多攒几层毛，再让工人收割；代币来自收割的自然毛层，收得快不会凭空多产代币。"
func show_shop() -> void:
 var content := screen("舱室补给", "购买猫、招募工人，或把新的设施放进舱室。生产设施开放资格随周目增加。", "shop")
 var cash := label("");content.add_child(cash);live(cash,func():return "可用毛球："+format_money(model.wallet))
 var grid := GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);content.add_child(grid)
 for key in ["short","worker","feeder","sun","arcade","altar"]:
  var card := PanelContainer.new();card.custom_minimum_size=Vector2(370,155);card.add_theme_stylebox_override("panel",style("203b4a"));grid.add_child(card)
  var c := column(card);c.add_child(label(D.title(key),21,"a8e1ca"))
  paragraph({"short":"只购买普通猫，特殊猫通过设施转化。","worker":"真实行走与操作，自动处理重复工作。","feeder":"范围喂食增产，记得添加库存猫粮。","sun":"拖入CD中的猫；首周目不会引发虫害。","arcade":"第二周目：暂停产毛，赢取换金道具。","altar":"第三周目：指派猫，全局加速与干扰。"}[key],c,14)
  var reason: String=model.buy_reason(key)
  var b := button(("购买 · %d 毛球" % model.price(key)) if reason=="" else reason,func():
   if key != "short" and not model.has(key):show_tree(key)
   elif key in ["short","worker"]:
    transact(func():return model.buy(key,Vector2(model.rng.randf_range(420,850),model.rng.randf_range(420,610))));show_shop()
   elif not model.has(key):show_tree(key)
   else:close_modal();room.placing=key;message("点击舱室空地摆放"+D.title(key)),c)
  b.disabled = model.round_no<D.gate(key)
 var foods := row(content)
 for i in range(3):
  var b := button("%s ×10 · %d毛球（库存%d）" % [D.FOOD_NAMES[i],D.FOOD_PRICES[i],model.food[i]],func():transact(func():return model.buy_food(i));show_shop(),foods)
  b.disabled=not model.has("feeder") or i>model.lv("feeder","food")
 button("前往升级树",func():show_tree(),content)
func show_tree(subject: String = "worker") -> void:
 tree_selected=subject
 var content := screen("成长树  /  向上探索", "三条路线：产毛设施、工人分工、娱乐与密语。周目锁不能用资金越过，性能旁支无需满级。", "tree")
 var jumps := row(content)
 for target in D.RESEARCH:
  button(D.title(target),func():show_tree_detail(target);focus_tree(target),jumps)
 var layout := row(content);layout.custom_minimum_size.y=415
 graph=GraphEdit.new();graph.custom_minimum_size=Vector2(860,415);graph.size_flags_horizontal=SIZE_EXPAND_FILL;graph.minimap_enabled=false;graph.show_arrange_button=false;layout.add_child(graph)
 detail=column(layout);detail.custom_minimum_size.x=295
 for key in D.RESEARCH:
  var spec: Dictionary=D.RESEARCH[key]
  var node := GraphNode.new();node.name=key;node.title=D.title(key);node.position_offset=spec.pos;node.custom_minimum_size.x=215;graph.add_child(node)
  var state: String = "已解锁" if model.has(key) else ("第%d周目开放" % spec.round if model.round_no<spec.round else "研究 %d 毛球" % spec.price)
  button(state,func():show_tree_detail(key),node)
  node.set_slot(0,true,0,Color("95c9bd"),true,0,Color("95c9bd"))
  if D.BRANCHES.has(key):
   var desc := label("＋ "+" / ".join(D.BRANCHES[key].keys()),12,"8faeae")
   desc.text="＋ %d 项独立分支" % D.BRANCHES[key].size();node.add_child(desc)
 for key in D.RESEARCH:
  for pre in D.RESEARCH[key].pre: graph.connect_node(pre,0,key,0)
 for key in D.BRANCHES:
  var index: int = 0
  for branch in D.BRANCHES[key]:
   var spec: Array = D.BRANCHES[key][branch]
   var node := GraphNode.new();node.name=key+"_"+branch;node.title=spec[0]
   node.position_offset=D.RESEARCH[key].pos+Vector2(-230+(index%3)*235,-230-(index/3)*150)
   node.custom_minimum_size.x=185;graph.add_child(node)
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
 target_graph.scroll_offset=D.RESEARCH[subject].pos-Vector2(300,310)
func show_tree_detail(key: String) -> void:
 clear(detail);tree_selected=key
 detail.add_child(label(D.title(key),23,"dfc794"));paragraph(D.RESEARCH[key].desc,detail)
 var cash := label("");detail.add_child(cash);live(cash,func():return "毛球："+format_money(model.wallet))
 var why: String = model.research_reason(key)
 paragraph("已解锁 · 实体在商店购买" if model.has(key) else (why if why!="" else "研究费用：%d 毛球" % D.RESEARCH[key].price),detail)
 var b := button("研发主体",func():transact(func():return model.research(key));show_tree(key),detail);b.disabled=why!=""
 for branch in D.BRANCHES.get(key,{}):
  var spec: Array=D.BRANCHES[key][branch];var cost: int=model.upgrade_price(key,branch)
  var bt := button("%s %d/%d · %s" % [spec[0],model.lv(key,branch),spec[2],str(cost)+"毛球" if cost>=0 else "已满"],func():transact(func():return model.upgrade(key,branch));show_tree_detail(key),detail)
  bt.disabled=not model.has(key) or cost<0
func show_facility(id: int) -> void:
 var f: Dictionary=model.facility(id)
 if f.is_empty():return
 var content := screen(D.title(f.kind), "点击设备操作；回到场地后，也可以直接把猫拖进对应区域。", "facility")
 var info := label("");content.add_child(info)
 live(info,func():return "料仓 %d / 40   蟑螂 %d" % [f.grain,f.bugs] if f.kind=="feeder" else "占用 %d / %d   %s" % [model.occupants(id).size(),model.capacity(f),"黑屏 · 停止产出" if f.broken else "正常运行"])
 if f.kind=="feeder":
  var options := row(content)
  for i in range(3):
   var b := button("补入%s（库存%d）" % [D.FOOD_NAMES[i],model.food[i]],func():transact(func():return model.refill(id,i));show_facility(id),options)
   b.disabled=i>model.lv("feeder","food")
  button("去商店购买猫粮",show_shop,content)
  var bug_box := PanelContainer.new();bug_box.add_theme_stylebox_override("panel",style("14282f","b17875"));bug_box.custom_minimum_size.y=130;content.add_child(bug_box)
  var inside := column(bug_box);inside.add_child(label("喂食器内部  /  太空偷渡客",21,"e6b3a0"))
  if f.bugs>0:
   paragraph("虫害会取消增产并降低产量。连续点击清除，每只需要两下。",inside)
   button("捶它！  × %d 只蟑螂   [%d/2]" % [f.bugs,f.hits],func():model.clean(id);save_game();show_facility(id),inside)
  else: paragraph("内部干净。"+(" 第一周目不会发生虫害。" if model.round_no==1 else "工人也可以接手打理。"),inside)
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
 var target_row := row(content);target_row.add_child(label("收割策略：等到几层再收？",18,"dfc794"))
 var spin := SpinBox.new();spin.min_value=1;spin.max_value=8;spin.value=model.harvest_target;spin.value_changed.connect(func(v:float):model.harvest_target=int(v));target_row.add_child(spin)
 if not model.has("hats"):paragraph("固定分工在第二周目解锁职责帽后开放；当前工人会自主照料。",content)
 if model.workers.is_empty():button("去招募一个小帮手",show_shop,content)
 for w in model.workers:
  var line := row(content);var text_label := label("");text_label.custom_minimum_size.x=390;line.add_child(text_label)
  live(text_label,func():return "精灵 #%d   ·   %s   ·   %s" % [w.id,D.ROLES[w.role],w.status])
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
 var content := screen("库存 · 来自猫咪的小物件", "换金道具由娱乐设施与招财猫产生。收藏加成放在神秘仪器中，不混入出售。", "inventory")
 var info := label("");content.add_child(info);live(info,func():return "道具 %d 件   出售倍率 ×%.2f" % [model.inventory.size(),model.effect("sale")])
 button("出售当前全部换金道具",func():message("出售获得 %.1f 毛球" % model.sell_all());save_game();show_inventory(),content)
 for item in model.inventory:content.add_child(label("%s   ·   %.1f 毛球" % [item.name,item.value*model.effect("sale")]))
 if model.inventory.is_empty():paragraph("这里还空着。娱乐设施将在第二周目开放。",content)
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
 var info := label("");content.add_child(info);live(info,func():return "神秘代币 %d    本频段未回应 %d    永久收藏 %d" % [model.tokens,model.pool().size(),model.owned.size()])
 button("投入 1 枚代币 · 转动旋钮",pull_capsule,content).disabled=model.pool().is_empty()
 var grid := GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);content.add_child(grid)
 for s in D.SERIES:
  if int(s.round)>model.round_no:continue
  var card := PanelContainer.new();card.custom_minimum_size=Vector2(360,130);card.add_theme_stylebox_override("panel",style("243b4c",s.color));grid.add_child(card)
  var col := column(card);var count_owned: int=0
  for i in range(3):
   if model.owned.has(s.id+":"+str(i)):count_owned+=1
  col.add_child(label(s.name,18,s.color));paragraph("%d / 3    %s +%.0f%%" % [count_owned,s.label,count_owned*float(s.step)*100],col,15)
  var marks: PackedStringArray=[]
  for i in range(3):marks.append("◆" if model.owned.has(s.id+":"+str(i)) else "◇")
  col.add_child(label("  ".join(marks),23,s.color))
 if model.pool().is_empty():
  if model.round_no<3:button("仪器收到一个新的信号……",show_restart,content)
  else:paragraph("这段旅程的回声已经全部收到。
第三频段Demo内容已完成，你仍可留在舱室继续经营。",content,22)
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
  if key.begins_with(s.id+":"):paragraph("永久加成已增强：%s +%.0f%%
新的力量会陪你进入下一次驻留。" % [s.label,float(s.step)*100],content,22)
 button("带着新的回声返回仪器",func():capsule_busy=false;show_gacha(),content)
 capsule_busy=false
func show_restart() -> void:
 var content := screen("下一次驻留", "当期仪器已经没有新回声。更远的信号，似乎正等着你。", "restart",true)
 var next: String="第二周目：喂食器虫害、职责分配、娱乐设施" if model.round_no==1 else "第三周目：密语祭坛、信号干扰、工人维护"
 paragraph("下一频段将开放："+next,content,24)
 paragraph("永久保留：所有扭蛋收藏及系列buff，开局即生效。
Demo重置：猫、工人、设施、研究等级、毛球、猫粮、换金道具、剩余代币。
新开局：2只短毛猫与20份基础猫粮。旧版摸猫存档不会被读取或覆盖。",content,19)
 button("开启下一周目",func():
  if transact(func():return model.advance_round()):room.effects.clear();close_modal(),content)
 button("暂时留在这里",show_gacha,content)
func show_pause() -> void:
 if not active:return
 var content := screen("驻留暂停", "猫咪、设备、工人和故障计时都已暂停。", "pause",true)
 button("继续驻留",close_modal,content);button("保存进度",func():message("已保存" if save_game() else "保存失败，请查看权限"),content)
 button("设置",show_settings,content);button("重新开始…",new_game_prompt,content)
 button("退出游戏",func():save_game();get_tree().quit(),content)
func show_settings() -> void:
 var content := screen("设置", "视觉设置。", "settings",true)
 var reduced := CheckButton.new();reduced.text="减少收益粒子";reduced.button_pressed=room.reduced;reduced.toggled.connect(func(v:bool):room.reduced=v);content.add_child(reduced)
 var fullscreen := CheckButton.new();fullscreen.text="全屏显示";fullscreen.button_pressed=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN;fullscreen.toggled.connect(func(v:bool):DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if v else DisplayServer.WINDOW_MODE_WINDOWED));content.add_child(fullscreen)
 button("返回",show_pause,content)
func show_help() -> void:
 var content := screen("驻留手册", "让旧工作逐渐交给小帮手，把注意力留给新的发现。", "help",true)
 paragraph("① 不按键，在猫身上来回移动：收割。等多层再收，产量更高。
② 按住猫拖动：搬猫；松在设施上可指派，松在空地则回到场地。
③ 成长树研发能力 → 商店购买实体 → 点击地板摆放。右键取消摆放。
④ 点击喂食器补粮或打开内部清虫；点击黑屏娱乐设施反复捶打。
⑤ 工人分工中可设置目标收割层数；第二周目职责帽安排固定岗位。
⑥ 代币投入神秘仪器获得不重复收藏。回应下一段信号，保留加成重新发展。",content,22)
 paragraph("前三周目内容逐步开放。Demo数值与重置方案为试玩暂定，完整说明见工程README。",content,15)
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
