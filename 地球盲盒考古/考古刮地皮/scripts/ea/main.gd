extends Control
const M=preload("res://scripts/ea/model.gd")
const C=preload("res://scripts/ea/config.gd")
const Board=preload("res://scripts/ea/board.gd")
const Workbench=preload("res://scripts/ea/workbench.gd")
const Reveal=preload("res://scripts/reveal_stage_3d.gd")
const Preview=preload("res://scripts/model_preview_3d.gd")
const INK=Color("e9f1e8")
const MUTED=Color("98aca6")
const ACCENT=Color("a3e3bd")
var model:=M.new()
var board: Control
var balance: Label
var status: Label
var notice: Label
var depth_clip: Control
var depth_rows: Control
var overlay: Control
var page_body: Control
var page_title: Label
var page_balance: Label
var pause_button: Button
var workbench: Control
var view:=""
var inventory_tab:="raw"
var series_filter:=-1
var inventory_page:=0
var fine_filter:=false
var work_id:=-1
var shop_buttons: Dictionary={}
var machine_buttons: Dictionary={}
var live_status: Array[Dictionary]=[]
var ui_clock:=0.0
var save_clock:=0.0
var notice_clock:=0.0
var depth_tween: Tween
var save_enabled:=true
var signature:=""
var reveal_busy:=false
var upgrade_scroll: ScrollContainer
var upgrade_stack: VBoxContainer
var settings_dialog: Control
var pause_menu: Control
var settings_draft := {}
var analyzer_button: Button
var upgrade_labels := {}
var machine_labels := {}
var start_menu: Control
var start_message: Label
var load_button: Button
var session_active := false
var save_path := "user://ea_save.dat"
var settings_path := "user://ea_settings.cfg"

func _ready()->void:
	var font:=SystemFont.new()
	font.font_names=PackedStringArray(["Microsoft YaHei","Segoe UI"])
	theme=Theme.new(); theme.default_font=font; theme.default_font_size=14
	save_enabled=not "--test" in OS.get_cmdline_user_args()
	_load_preferences()
	model.paused=true
	_build()
	_build_start_menu()
	model.layers_shifted.connect(_depth_shift)
	_refresh()
	get_tree().auto_accept_quit=false
	
func _notification(what:int)->void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		if save_enabled and session_active: model.save_to(save_path)
		get_tree().quit()
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(board): board.cancel_drag()

func _panel(parent:Node,rect:Rect2,color:Color=Color("15292e"))->Panel:
	var p:=Panel.new(); p.position=rect.position; p.size=rect.size
	var style:=StyleBoxFlat.new(); style.bg_color=color; style.border_color=Color("38534d")
	style.set_border_width_all(1); style.set_corner_radius_all(8)
	p.add_theme_stylebox_override("panel",style); p.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(p); return p
	
func _text(parent:Node,value:String,rect:Rect2,font_size:int=14,color:Color=INK)->Label:
	var label:=Label.new(); label.text=value; label.position=rect.position; label.size=rect.size
	label.add_theme_font_size_override("font_size",font_size); label.add_theme_color_override("font_color",color)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(label); return label

func _button(parent:Node,value:String,rect:Rect2,callback:Callable)->Button:
	var b:=Button.new(); b.text=value; b.position=rect.position; b.size=rect.size
	b.focus_mode=Control.FOCUS_NONE; b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	for state in ["normal","hover","pressed","disabled"]:
		var style:=StyleBoxFlat.new()
		style.bg_color=Color("2d554a") if state!="disabled" else Color("1e3032")
		if state=="hover": style.bg_color=Color("3e7562")
		style.set_corner_radius_all(5)
		b.add_theme_stylebox_override(state,style)
	b.add_theme_color_override("font_color",INK)
	b.pressed.connect(callback); parent.add_child(b); return b

func _build()->void:
	board=Board.new(); board.model=model; board.position=Vector2(4,14); board.size=C.WORLD; add_child(board)
	var side:=_panel(self,Rect2(1110,14,248,822),Color("102125"))
	_text(side,"地球盲盒考古 / v0.3",Rect2(14,12,222,26),16,ACCENT)
	_text(side,"废料",Rect2(14,45,100,20),12,MUTED)
	balance=_text(side,"",Rect2(14,66,220,40),29,Color("f1d28d"))
	_button(side,"古物库存",Rect2(12,112,108,34),open_page.bind("inventory"))
	_button(side,"天赋树",Rect2(128,112,108,34),open_page.bind("talents"))
	status=_text(side,"",Rect2(14,153,220,40),12,MUTED)
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	notice=_text(side,"",Rect2(14,195,220,50),12,ACCENT)
	notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	upgrade_scroll=ScrollContainer.new(); upgrade_scroll.position=Vector2(10,253); upgrade_scroll.size=Vector2(228,338)
	upgrade_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(upgrade_scroll)
	upgrade_stack=VBoxContainer.new(); upgrade_stack.custom_minimum_size.x=210; upgrade_stack.add_theme_constant_override("separation",7); upgrade_scroll.add_child(upgrade_stack)
	_build_upgrades()
	_text(side,"活动地层 · Esc 暂停菜单",Rect2(14,595,220,25),13,ACCENT)
	depth_clip=Control.new(); depth_clip.position=Vector2(12,628); depth_clip.size=Vector2(224,190); depth_clip.clip_contents=true
	depth_clip.mouse_filter=Control.MOUSE_FILTER_IGNORE; side.add_child(depth_clip)
	depth_rows=Control.new(); depth_rows.size=depth_clip.size; depth_clip.add_child(depth_rows)
	_depth_build()
	overlay=Control.new(); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); overlay.mouse_filter=Control.MOUSE_FILTER_STOP; add_child(overlay)
	var veil:=ColorRect.new(); veil.color=Color(0.015,0.025,0.03,0.9); veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); overlay.add_child(veil)
	var frame:=_panel(overlay,Rect2(103,48,1160,754),Color("102329"))
	page_title=_text(frame,"",Rect2(24,15,630,40),25)
	page_balance=_text(frame,"",Rect2(655,21,330,34),20,Color("f1d28d"))
	_button(frame,"返回挖掘",Rect2(994,17,142,38),close_page)
	page_body=Control.new(); page_body.position=Vector2(24,72); page_body.size=Vector2(1112,652); frame.add_child(page_body)
	overlay.hide()
	_build_pause_menu()

func _depth_build()->void:
	for child in depth_rows.get_children(): child.queue_free()
	for i in range(5):
		var layer:Dictionary=model.layers[i]
		var p:=_panel(depth_rows,Rect2(0,i*38,224,35),Color("1b3839") if i==0 else Color("122b30"))
		var image:=TextureRect.new(); image.position=Vector2(5,5); image.size=Vector2(26,26)
		image.texture=load(layer.texture); image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; image.mouse_filter=Control.MOUSE_FILTER_IGNORE; p.add_child(image)
		var label:=_text(p,"",Rect2(38,0,180,23),13); label.name="DepthText"
		var progress:=ProgressBar.new(); progress.name="LayerProgress"; progress.position=Vector2(38,25); progress.size=Vector2(180,5)
		progress.show_percentage=false; progress.add_theme_font_size_override("font_size",1); p.add_child(progress)

func _depth_shift(_count:int)->void:
	if is_instance_valid(depth_tween): depth_tween.kill()
	_depth_build()
	depth_rows.position.y=0 if model.reduce_fx else 48
	if not model.reduce_fx:
		depth_tween=create_tween()
		depth_tween.tween_property(depth_rows,"position:y",0.0,0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	notify("地层完成 · 已推进至第%d层"%model.base_depth)

func _process(delta:float)->void:
	if not session_active: return
	var dt:=minf(delta,0.10)
	board.step(dt)
	model.tick(dt)
	board.consume_find_events()
	if not model.notices.is_empty():
		notify(model.notices.back()+("（另有%d条）"%(model.notices.size()-1) if model.notices.size()>1 else ""))
		model.notices.clear()
	ui_clock+=delta; save_clock+=delta
	if ui_clock>=0.25:
		ui_clock=0
		_refresh()
	if save_enabled and save_clock>=30:
		save_clock=0
		var err:=model.save_to(save_path)
		if err!=OK: notify("自动保存失败，请手动重试")
	if notice_clock>0:
		notice_clock-=delta

func _refresh()->void:
	balance.text=model.wallet.display()
	balance.tooltip_text=model.wallet.exact()
	if is_instance_valid(page_balance):
		page_balance.text="废料 "+model.wallet.display()
		page_balance.tooltip_text=model.wallet.exact()
	var raw:=0; var known:=0
	for r in model.records:
		if r.status in ["raw","cleaning"]: raw+=1
		elif r.status=="identified": known+=1
	status.text="未知 %d · 藏品 %d · 机器人 %d\n知识点 %d · 推进预留 %s"%[raw,known,model.levels.auto,model.knowledge,model.reserve().display()]
	if notice_clock<=0:
		notice.text="已暂停全部作业" if model.paused else ("已到活动层底部\n请清除上方残余地皮" if board.active_depth==5 else ("强度不足：升级铲子至适配层" if board.active_depth<5 and model.efficiency(board.active_depth)<1 else "按住拖动刮地 · 出土后到库存清理"))
	var rows:=depth_rows.get_children().filter(func(n): return not n.is_queued_for_deletion())
	for i in range(mini(5,rows.size())):
		rows[i].get_node("DepthText").text="第%d层  %s"%[model.layers[i].depth,model.progress_text(i)]
		rows[i].get_node("LayerProgress").value=model.progress(i)*100
	if is_instance_valid(analyzer_button):
		var ar:=model.analyzer_reason()
		analyzer_button.text=ar if not ar.is_empty() else "购买 · 500废料"
		analyzer_button.disabled=model.paused or not ar.is_empty()
	for kind in shop_buttons:
		var b:Button=shop_buttons[kind]
		if not is_instance_valid(b): continue
		var reason:=model.purchase_reason(kind)
		b.disabled=not reason.is_empty() or model.paused
		b.text=reason if not reason.is_empty() else "升级 · "+C.price(kind,model.levels[kind]).display()
		b.tooltip_text=C.price(kind,model.levels[kind]).exact()+" 废料"
		if upgrade_labels.has(kind): upgrade_labels[kind].text=C.NAMES[kind]+" Lv.%d\n"%model.levels[kind]+_upgrade_detail(kind)
	for index in machine_buttons:
		var b:Button=machine_buttons[index]
		if not is_instance_valid(b): continue
		if model.machines[index].owned:
			b.text="暂停工位" if model.machines[index].enabled else "恢复工位"
			b.disabled=model.paused
			var task:Dictionary=model.record(int(model.machines[index].task))
			var line:="等待匹配库存" if task.is_empty() else "匿名任务 · 第%d步 %d%%"%[int(task.step)+1,int(float(task.progress[mini(1,int(task.step))])*100)]
			machine_labels[index].text=("S%02d 鉴宝机"%(index+1) if index<5 else "通用鉴宝机")+"\n"+line+"\n不含可选抛光"
			continue
		var reason:=model.machine_reason(index)
		b.disabled=not reason.is_empty() or model.paused
		b.text=reason if not reason.is_empty() else "购买 · %d废料"%C.MACHINE_PRICES[index]
	for item in live_status:
		if is_instance_valid(item.label):
			var r:=model.record(item.id)
			if not r.is_empty(): item.label.text=_record_status(r)
	if view=="inventory":
		var next_signature:="%d/%d/%d"%[raw,known,model.discovered.size()]
		if signature!=next_signature:
			signature=next_signature
			_render_page()

func notify(message:String)->void:
	if is_instance_valid(notice): notice.text=message
	notice_clock=5

func toggle_pause()->void:
	model.paused=not model.paused
	board.cancel_drag()
	_refresh()

func _clear_body()->void:
	live_status.clear()
	for child in page_body.get_children():
		page_body.remove_child(child); child.queue_free()
	workbench=null

func open_page(page:String)->void:
	if reveal_busy: return
	if page=="settings": _open_pause(); _open_settings(); return
	if page=="shop": return
	if work_id>=0: model.release_manual(work_id); work_id=-1
	board.cancel_drag()
	view=page
	overlay.show()
	_render_page()
	
func close_page()->void:
	if reveal_busy: return
	if work_id>=0: model.release_manual(work_id); work_id=-1
	view=""
	_clear_body()
	overlay.hide()
	board.cancel_drag()

func _render_page()->void:
	_clear_body()
	match view:
		"inventory": _inventory()
		"talents": _talents()
		"settings": _settings()
		"developer": _developer()
	_refresh_page_balance()
	
func _refresh_page_balance()->void:
	page_balance.text="废料 "+model.wallet.display()

func _scroll(rect:Rect2)->VBoxContainer:
	var scroll:=ScrollContainer.new(); scroll.position=rect.position; scroll.size=rect.size; page_body.add_child(scroll)
	var stack:=VBoxContainer.new(); stack.custom_minimum_size.x=rect.size.x-18; stack.add_theme_constant_override("separation",8); scroll.add_child(stack)
	return stack
	
func _upgrade_detail(kind: String) -> String:
	var level: int=model.levels[kind]
	match kind:
		"power","auto_power": return "适配第%d → %d层\n强度 10^%d → 10^%d"%[level+1,level+2,level,level+1]
		"radius": return "半径 %.1f → %.1f"%[C.radius(level),C.radius(mini(4,level+1))]
		"auto_radius": return "半径 %.1f → %.1f"%[C.radius(level,true),C.radius(mini(4,level+1),true)]
		"auto": return "并行 %d → %d台"%[level,mini(3,level+1)]
		"auto_move": return "移动 %.0f → %.0f px/s"%[C.move_speed(level),C.move_speed(mini(5,level+1))]
		"opening": return "处理 %.2f → %.2f倍"%[pow(1.2,level),pow(1.2,mini(8,level+1))]
	return ""

func _build_upgrades() -> void:
	for kind in C.NAMES:
		var heading := ""
		if kind=="power": heading="手动工具"
		if kind=="auto": heading="机器人 · 独立属性"
		if kind=="opening": heading="开盒自动化"
		if heading!="":
			var label:=Label.new(); label.text=heading; upgrade_stack.add_child(label)
		var card:=_panel(upgrade_stack,Rect2(0,0,210,124)); card.custom_minimum_size=Vector2(210,124)
		upgrade_labels[kind]=_text(card,"",Rect2(8,5,194,76),13)
		shop_buttons[kind]=_button(card,"",Rect2(7,86,195,31),_buy_upgrade.bind(kind))
		shop_buttons[kind].add_theme_font_size_override("font_size",12)
	var scan:=_panel(upgrade_stack,Rect2(0,0,210,116)); scan.custom_minimum_size=Vector2(210,116)
	_text(scan,"分析仪 · 只识别潜在系列\n不揭晓款式，不完成清理",Rect2(8,8,195,60),12)
	analyzer_button=_button(scan,"",Rect2(7,77,195,31),func(): model.buy_analyzer(); _refresh())
	analyzer_button.add_theme_font_size_override("font_size",12)
	for i in range(6):
		var card:=_panel(upgrade_stack,Rect2(0,0,210,134)); card.custom_minimum_size=Vector2(210,134)
		var label:=_text(card,("S%02d 系列鉴宝机"%(i+1) if i<5 else "通用鉴宝机")+"\n剥土 → 甩沙 · 不含抛光\n基础 %.2f秒/件"%(C.MACHINE_SECONDS[i]*C.FINISH),Rect2(8,6,194,87),12)
		machine_labels[i]=label
		machine_buttons[i]=_button(card,"",Rect2(7,96,195,31),_machine_action.bind(i))
		machine_buttons[i].add_theme_font_size_override("font_size",12)

func _buy_upgrade(kind:String)->void:
	model.buy(kind); _refresh()
func _buy_machine(index:int)->void:
	model.buy_machine(index); _refresh()
func _toggle_machine(index:int)->void:
	if model.paused: return
	model.machines[index].enabled=not model.machines[index].enabled
	model.touch(); _refresh()
func _machine_action(index: int) -> void:
	if model.machines[index].owned: _toggle_machine(index)
	else: _buy_machine(index)

func _inventory()->void:
	page_title.text="古物库存 · 清理 / 收藏 / 出售"
	for i in range(3):
		var tab: String=["raw","identified","catalog"][i]
		_button(page_body,["未清理 / 处理中","已鉴定","图鉴"][i],Rect2(i*176,0,168,34),_inventory_tab.bind(tab))
	_button(page_body,"自动卖重复普通件："+("开" if model.auto_sell else "关"),Rect2(548,0,310,34),_toggle_sell)
	_button(page_body,"刷新",Rect2(874,0,108,34),_render_page)
	var select:=OptionButton.new(); select.position=Vector2(0,46); select.size=Vector2(290,32)
	select.visible=inventory_tab!="raw" or model.analyzer
	if inventory_tab=="raw" and not model.analyzer: series_filter=-1
	select.add_item("全部系列")
	for s in range(5): select.add_item(C.series_name(s))
	select.selected=series_filter+1
	select.item_selected.connect(func(index): series_filter=index-1; inventory_page=0; _render_page())
	page_body.add_child(select)
	if model.talents.has("T22"):
		_button(page_body,"仅可精修："+("是" if fine_filter else "否"),Rect2(310,46,206,32),func(): fine_filter=not fine_filter; inventory_page=0; _render_page())
	if model.talents.has("T31"):
		var priority:=OptionButton.new(); priority.position=Vector2(538,46); priority.size=Vector2(320,32)
		priority.add_item("队列：按入库顺序")
		priority.add_item("优先已有清理进度")
		priority.add_item("优先尚未开始")
		if model.analyzer:
			for s in range(5): priority.add_item("优先 "+C.series_name(s))
		priority.selected=model.priority_series+3 if model.analyzer and model.priority_series>=0 else model.queue_priority
		priority.item_selected.connect(func(index): model.queue_priority=index if index<3 else 0; model.priority_series=index-3 if index>=3 else -1; model.touch())
		page_body.add_child(priority)
	if inventory_tab=="catalog":
		_catalog()
		return
	var items:Array[Dictionary]=[]
	for r in model.records:
		if series_filter>=0 and r.series!=series_filter: continue
		if inventory_tab=="raw" and r.status in ["raw","cleaning"]: items.append(r)
		if inventory_tab=="identified" and r.status=="identified" and (not fine_filter or not r.quality): items.append(r)
	var pages:=maxi(1,int(ceil(items.size()/8.0)))
	inventory_page=clampi(inventory_page,0,pages-1)
	_text(page_body,"共%d件 · 第%d/%d页 · 首见与锁定件不会自动出售"%[items.size(),inventory_page+1,pages],Rect2(0,91,820,25),13,MUTED)
	_button(page_body,"上一页",Rect2(874,88,108,28),_paginate.bind(-1))
	_button(page_body,"下一页",Rect2(994,88,108,28),_paginate.bind(1))
	for n in range(inventory_page*8,mini(items.size(),inventory_page*8+8)):
		var r:Dictionary=items[n]
		var i:=n-inventory_page*8
		var card:=_panel(page_body,Rect2((i%2)*552,128+(i/2)*126,540,118))
		var title_value:=model.unknown_title(r)
		if r.status=="identified": title_value=C.model_item(int(r.series),int(r.variant)).name+(" · 精品" if r.quality else "")
		_text(card,title_value,Rect2(14,7,500,26),16)
		var detail:=_text(card,_record_status(r),Rect2(14,38,500,24),12,MUTED)
		live_status.append({"id":r.id,"label":detail})
		if r.status=="identified":
			var value:String=model.sale_price(r).display()
			var sell_button:=_button(card,"出售 "+value,Rect2(14,76,162,30),_sell.bind(int(r.id)))
			sell_button.disabled=r.locked
			_button(card,"解锁" if r.locked else "锁定",Rect2(184,76,78,30),_lock.bind(int(r.id)))
			_button(card,"精修" if not r.quality else "已精品",Rect2(270,76,90,30),_start_work.bind(int(r.id),true)).disabled=r.quality
			_button(card,"3D查看",Rect2(368,76,154,30),_show_reveal.bind(int(r.id),false))
		else:
			_button(card,"接管并清理" if r.owner.begins_with("machine") else "手动清理",Rect2(14,76,200,30),_start_work.bind(int(r.id),false))
			_text(card,"内容未知 · 可中断暂存",Rect2(232,78,290,26),13,ACCENT)

func _record_status(r:Dictionary)->String:
	if r.status=="identified":
		var extra: String="  精修加价 "+model.amount(r.estimate).times(125,2).floor_value().minus(model.amount(r.estimate).floor_value()).display() if model.talents.has("T22") and not r.quality else ""
		return "来源第%d层 · 售价%s废料%s"%[r.depth,model.sale_price(r).display(),extra]
	if r.status=="sold": return "已出售，发现记录已保留"
	var step:=mini(2,int(r.step))
	return "第%d层 · 基础工序%d/2 %s %d%% · %s"%[r.depth,step+1,C.STAGES[int(r.series)][step],int(float(r.progress[step])*100),"机器处理" if r.owner.begins_with("machine") else "待手动 / 空闲工位"]

func _catalog()->void:
	var visible_series:Array[int]=[]
	if series_filter>=0: visible_series.append(series_filter)
	else:
		for i in range(5): visible_series.append(i)
	var stack:=_scroll(Rect2(0,90,1112,555))
	for series in visible_series:
		var count:=0
		for v in range(5):
			if model.discovered.has("%d_%d"%[series,v]): count+=1
		var header:=Label.new()
		header.text=C.series_name(series)
		if model.talents.has("T00"): header.text+=" · 已发现 %d/5"%count
		if model.talents.has("T12"): header.text+=" · 保底连续重复 %d/2（已生成封存体计入预留）"%model.duplicate_streak[series]
		stack.add_child(header)
		var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",10); stack.add_child(row)
		for v in range(5):
			var known:=model.discovered.has("%d_%d"%[series,v])
			var card:=_panel(row,Rect2(0,0,208,196)); card.custom_minimum_size=Vector2(208,196)
			var item:=C.model_item(series,v)
			if known:
				var preview:=Preview.new(); preview.position=Vector2(14,8); preview.size=Vector2(180,147); preview.build(item.model_path,Vector2i(180,147)); card.add_child(preview)
			_text(card,item.name if known else "？？？",Rect2(14,158,185,25),15,INK if known else MUTED)

func _inventory_tab(tab:String)->void:
	inventory_tab=tab; inventory_page=0; _render_page()
func _paginate(direction:int)->void:
	inventory_page+=direction; _render_page()
func _toggle_sell()->void:
	model.auto_sell=not model.auto_sell; model.touch(); _render_page()
func _sell(id:int)->void:
	if model.sell(id): _render_page()
func _lock(id:int)->void:
	var r:=model.record(id); r.locked=not r.locked; model.touch(); _render_page()

func _start_work(id:int,polish:bool)->void:
	var r:=model.record(id)
	if r.is_empty(): return
	overlay.show(); board.cancel_drag()
	if not polish and not model.claim_manual(id): return
	view="work"; work_id=id; _clear_body()
	page_title.text="清理工作台 · 连点剥土 / 甩沙 / 可选抛光"
	_button(page_body,"暂存并返回库存",Rect2(855,0,244,35),open_page.bind("inventory"))
	workbench=Workbench.new(); workbench.model=model; workbench.item_id=id; workbench.polishing=polish
	workbench.position=Vector2(0,40); workbench.size=Vector2(1000,600)
	workbench.completed.connect(_work_complete.bind(polish))
	page_body.add_child(workbench)
	
func _work_complete(id:int,polishing:bool)->void:
	if polishing:
		notify("精修完成，售价提高25%")
		open_page.call_deferred("inventory")
	else:
		_show_reveal.call_deferred(id,true)

func _show_reveal(id:int,animate:bool)->void:
	var r:=model.record(id)
	if r.is_empty(): return
	view="review"; work_id=-1; _clear_body()
	var item:=C.model_item(int(r.series),int(r.variant))
	page_title.text=("首次发现 · " if r.new else "古物 · ")+item.name
	var stage:=Reveal.new(); stage.position=Vector2(80,0); stage.size=Vector2(920,575); page_body.add_child(stage)
	stage.configure(item)
	reveal_busy=true
	if animate and not (model.skip_repeat and not r.new):
		await stage.play_reveal()
	else:
		stage.box_root.hide()
		stage._spawn_collectible()
		stage.review_item.position=stage._review_layer_position(stage.REVIEW_ITEM_CAMERA_DISTANCE)
		stage.review_item.basis=stage._front_facing_basis(stage.review_item.position)
		stage.review_item.scale=Vector3.ONE*(0.84*stage.REVIEW_MODEL_SCALE_MULTIPLIER)
		for mesh in stage.imported_meshes: mesh.material_override=null
		stage._create_reveal_burst()
		stage.rotation_enabled=true
	reveal_busy=false
	_text(page_body,"拖动旋转 · 当前 "+model.sale_price(r).display()+" · 抛光后 "+model.amount(r.estimate).times(125,2).floor_value().display()+" 废料",Rect2(190,580,780,26),16,ACCENT)
	_button(page_body,"返回库存",Rect2(230,613,210,35),open_page.bind("inventory"))
	_button(page_body,"出售 "+model.sale_price(r).display(),Rect2(452,613,210,35),func(): model.sell(id); open_page("inventory")).disabled=r.locked or r.status!="identified"
	if not r.quality and r.status=="identified": _button(page_body,"追加精修 +25%",Rect2(674,613,210,35),_start_work.bind(id,true))

func _talents()->void:
	page_title.text="天赋树 · 知识点 %d"%model.knowledge
	_text(page_body,"首次发现 +1 · 普通系列集齐 +2 · 出售不撤销发现 · 免费重置",Rect2(0,0,950,28),14,MUTED)
	_button(page_body,"重置并退点",Rect2(920,0,180,34),func(): model.reset_talents(); _render_page())
	var order := [0,1,3,5,2,4,6]
	for i in range(order.size()):
		var t:Dictionary=C.TALENTS[order[i]]
		var x:=370*((i-1)%3) if i>0 else 370
		var y:=200+205*((i-1)/3) if i>0 else 48
		var p:=_panel(page_body,Rect2(x,y,350,147),Color("234c3c") if model.talents.has(t.id) else Color("183036"))
		_text(p,t.id+" · "+t.name,Rect2(14,10,324,25),18,ACCENT)
		_text(p,t.effect,Rect2(14,42,324,24),13)
		_text(p,"前置 "+("首次鉴定" if t.pre=="" else t.pre),Rect2(14,69,320,20),12,MUTED)
		var button:=_button(p,"已获得" if model.talents.has(t.id) else "学习 · %d知识点"%t.cost,Rect2(14,100,322,33),_learn.bind(String(t.id)))
		button.disabled=model.talents.has(t.id) or model.knowledge<int(t.cost) or (t.pre!="" and not model.talents.has(t.pre)) or model.discovered.is_empty()
	
func _learn(id:String)->void:
	if model.buy_talent(id): _render_page()

func _settings()->void:
	page_title.text="设置与保存"
	_text(page_body,"界面打开时机器人和鉴宝机继续运行；只有显式暂停会停止全部模拟。",Rect2(0,0,1100,30),16,MUTED)
	_button(page_body,"继续全部作业" if model.paused else "暂停全部作业",Rect2(0,55,330,48),func(): toggle_pause(); _render_page())
	_button(page_body,"立即保存",Rect2(355,55,330,48),_save)
	_button(page_body,"读取存档",Rect2(710,55,330,48),_load)
	_button(page_body,"减少动态效果："+("开" if model.reduce_fx else "关"),Rect2(0,135,500,44),func(): model.reduce_fx=not model.reduce_fx; _render_page())
	_button(page_body,"跳过重复开盒演出："+("开" if model.skip_repeat else "关"),Rect2(540,135,500,44),func(): model.skip_repeat=not model.skip_repeat; _render_page())
	_text(page_body,"每30秒自动保存，退出时保存。保存当前五层、库存工序、工位、升级和天赋。",Rect2(0,200,1090,30),15,MUTED)
	for slot in range(2):
		var b:=_button(page_body,"保存托管预设 %d"%(slot+1),Rect2(0,265+slot*65,500,46),func(): model.save_preset(slot); _render_page())
		b.disabled=not model.talents.has("T32")
		var apply:=_button(page_body,"应用预设 %d"%(slot+1),Rect2(540,265+slot*65,500,46),func(): model.load_preset(slot); _render_page())
		apply.disabled=not model.talents.has("T32") or model.presets[slot].is_empty()
	_text(page_body,"托管预设需要天赋T32；记录工位开关、自动出售和系列优先级。",Rect2(0,410,1080,30),14,MUTED)
	_button(page_body,"新游戏（进入确认页）",Rect2(0,510,450,44),_new_game_confirmation)

func _save()->void:
	notify("保存成功" if model.save_to(save_path)==OK else "保存失败")
func _load()->void:
	if model.load_from(save_path):
		board._rebuild(0); _depth_build(); notify("已恢复存档"); close_page()
	else: notify("没有可读取的新版存档")
func _new_game_confirmation()->void:
	_clear_body()
	_text(page_body,"新游戏会覆盖当前新版Demo存档。",Rect2(100,170,900,50),25)
	_button(page_body,"确认新游戏",Rect2(190,260,300,50),func():
		if save_enabled and FileAccess.file_exists("user://ea_save.dat"): DirAccess.remove_absolute("user://ea_save.dat")
		get_tree().reload_current_scene())
	_button(page_body,"取消",Rect2(560,260,300,50),_render_page)

func _developer()->void:
	page_title.text="开发者工具 · 新版Demo"
	_button(page_body,"增加当前层870倍废料",Rect2(0,0,480,48),func():
		model.wallet=model.wallet.plus(model.amount(model.layers[0].scale).times(870)); _render_page())
	_button(page_body,"真实清空顶部地层并结算",Rect2(510,0,580,48),_dev_clear)
	_button(page_body,"生成五系列测试封存体",Rect2(0,70,480,48),_dev_artifacts)
	_button(page_body,"机器人 +1（最多3台）",Rect2(510,70,580,48),func():
		model.levels.auto=mini(3,model.levels.auto+1); model.started=true; _render_page())
	var index:=0
	for kind in C.NAMES:
		var y:=150+index*56
		var title:String=C.NAMES[kind]
		_text(page_body,"%s · Lv.%d"%[title,model.levels[kind]],Rect2(0,y,390,40),18)
		_button(page_body,"−1",Rect2(410,y,130,38),_dev_level.bind(kind,-1))
		_button(page_body,"+1",Rect2(555,y,130,38),_dev_level.bind(kind,1))
		_button(page_body,"匹配当前深度 / 满级",Rect2(700,y,390,38),_dev_max.bind(kind))
		index+=1

func _dev_level(kind:String,change:int)->void:
	var maximum:=int(C.LIMITS[kind])
	model.levels[kind]=maxi(0,model.levels[kind]+change)
	if maximum>=0: model.levels[kind]=mini(maximum,model.levels[kind])
	model.touch(); _render_page()
func _dev_max(kind:String)->void:
	model.levels[kind]=model.base_depth-1 if C.LIMITS[kind]<0 else C.LIMITS[kind]
	model.touch(); _render_page()
func _dev_clear()->void:
	model.layers[0].mask.fill(0); model.layers[0].wear.fill(1.0); model.layers[0].cleared=M.PIXELS
	model.scan_exposed_finds(); model.advance_layers(); _render_page()
func _dev_artifacts()->void:
	for s in range(5):
		model.records.append({"id":model.next_id,"series":s,"variant":0,"depth":model.base_depth,"estimate":model.amount(model.layers[0].scale).times(C.BASE_PRICES[s]).times(8,1).data(),
			"status":"raw","step":0,"progress":[0.0,0.0,0.0],"marks":[[],[],[]],"owner":"","locked":false,"quality":false,"polish":0.0,"new":false})
		model.next_id+=1
		model.series_seen[s]=true
	model.touch(); notify("已加入五系列测试封存体")

func _unhandled_key_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
		if settings_dialog.visible: _close_settings(false)
		elif not session_active: pass
		elif pause_menu.visible: _resume_game()
		else: _open_pause()
		get_viewport().set_input_as_handled()

func _build_pause_menu() -> void:
	pause_menu=Control.new(); pause_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); pause_menu.mouse_filter=Control.MOUSE_FILTER_STOP; add_child(pause_menu)
	var shade:=ColorRect.new(); shade.color=Color(0.02,0.04,0.04,0.9); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); pause_menu.add_child(shade)
	var frame:=_panel(pause_menu,Rect2(473,190,420,460))
	_text(frame,"已暂停",Rect2(35,20,350,50),26)
	_button(frame,"返回游戏",Rect2(35,90,350,48),_resume_game)
	_button(frame,"设置",Rect2(35,155,350,48),_open_settings)
	_button(frame,"开发者工具",Rect2(35,220,350,48),func(): _resume_game(); open_page("developer"))
	_button(frame,"保存并退出",Rect2(35,285,350,48),func():
		if model.save_to(save_path)==OK: get_tree().quit()
		else: notify("保存失败，未退出"))
	pause_menu.hide()
	settings_dialog=Control.new(); settings_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); settings_dialog.mouse_filter=Control.MOUSE_FILTER_STOP; add_child(settings_dialog); settings_dialog.hide()

func _open_pause() -> void:
	if not session_active: return
	model.paused=true; board.cancel_drag()
	if is_instance_valid(workbench): workbench.cancel_input()
	pause_menu.show()

func _resume_game() -> void:
	if not session_active: return
	settings_dialog.hide(); pause_menu.hide(); model.paused=false
	board.cancel_drag()
	if is_instance_valid(workbench): workbench.cancel_input()

func _open_settings() -> void:
	settings_draft={"reduce_fx":model.reduce_fx,"skip_repeat":model.skip_repeat}
	settings_dialog.show(); _render_settings()

func _render_settings() -> void:
	for child in settings_dialog.get_children(): settings_dialog.remove_child(child); child.queue_free()
	var shade:=ColorRect.new(); shade.color=Color(0.01,0.02,0.03,0.9); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); settings_dialog.add_child(shade)
	var frame:=_panel(settings_dialog,Rect2(343,145,680,555))
	_text(frame,"设置 · 游戏保持暂停" if session_active else "设置",Rect2(30,20,610,45),24)
	_text(frame,"应用保存修改；取消 / Esc 返回"+("暂停菜单。" if session_active else "开始菜单。"),Rect2(30,75,610,32),15,MUTED)
	_button(frame,"减少动态效果："+("开" if settings_draft.reduce_fx else "关"),Rect2(30,125,620,45),func(): settings_draft.reduce_fx=not settings_draft.reduce_fx; _render_settings())
	_button(frame,"跳过重复开盒："+("开" if settings_draft.skip_repeat else "关"),Rect2(30,185,620,45),func(): settings_draft.skip_repeat=not settings_draft.skip_repeat; _render_settings())
	_button(frame,"立即保存进度",Rect2(30,255,295,44),_save).disabled=not session_active
	_button(frame,"读取进度（保持暂停）",Rect2(355,255,295,44),_load_paused).disabled=not session_active
	for slot in range(2):
		_button(frame,"存托管预设%d"%(slot+1),Rect2(30,320+slot*45,295,38),func(): model.save_preset(slot)).disabled=not model.talents.has("T32")
		_button(frame,"用托管预设%d"%(slot+1),Rect2(355,320+slot*45,295,38),func(): model.load_preset(slot)).disabled=not model.talents.has("T32") or model.presets[slot].is_empty()
	_button(frame,"应用",Rect2(30,460,295,45),_close_settings.bind(true))
	_button(frame,"取消",Rect2(355,460,295,45),_close_settings.bind(false))

func _close_settings(apply: bool) -> void:
	if apply:
		model.reduce_fx=settings_draft.reduce_fx; model.skip_repeat=settings_draft.skip_repeat
		_save_preferences()
		if save_enabled and session_active: model.save_to(save_path)
	settings_dialog.hide()

func _load_paused() -> void:
	if model.load_from(save_path):
		model.paused=true; work_id=-1; reveal_busy=false; view=""; _clear_body(); overlay.hide()
		board._rebuild(0); _depth_build(); _refresh()
		settings_draft={"reduce_fx":model.reduce_fx,"skip_repeat":model.skip_repeat}
		_render_settings(); notify("已恢复进度，返回游戏后继续")
	else: notify("没有可读取的存档")
func _build_start_menu() -> void:
	start_menu=Control.new(); start_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start_menu.mouse_filter=Control.MOUSE_FILTER_STOP; add_child(start_menu)
	move_child(settings_dialog,get_child_count()-1)
	var backdrop:=ColorRect.new(); backdrop.color=Color("0c1c20")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); start_menu.add_child(backdrop)
	var frame:=_panel(start_menu,Rect2(433,140,500,570),Color("152d32"))
	_text(frame,"地球盲盒考古",Rect2(40,38,420,58),36,ACCENT)
	_text(frame,"刮开废土，寻找遗落的文明",Rect2(40,104,420,32),17,MUTED)
	_button(frame,"开始游戏",Rect2(40,178,420,56),_start_new_game)
	load_button=_button(frame,"读取存档",Rect2(40,256,420,56),_load_start_game)
	load_button.disabled=not FileAccess.file_exists(save_path)
	_button(frame,"设置",Rect2(40,334,420,56),_open_settings)
	start_message=_text(frame,"开始游戏将从零开始。\n进入游戏后，自动保存会替换现有进度。" if not load_button.disabled else "尚无存档。选择开始游戏，踏上地球。",Rect2(40,422,420,90),15,MUTED)
	start_message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	start_message.size=Vector2(420,90)

func _start_new_game() -> void:
	if session_active: return
	_enter_game()

func _load_start_game() -> void:
	if session_active: return
	if not model.load_from(save_path):
		model.paused=true
		start_message.text="无法读取存档，请检查存档是否完整，或选择开始游戏。"
		return
	_load_preferences()
	board._rebuild(0); _depth_build()
	_enter_game()

func _enter_game() -> void:
	session_active=true; model.paused=false; save_clock=0
	start_menu.hide(); pause_menu.hide(); settings_dialog.hide()
	board.cancel_drag(); _refresh()

func _load_preferences() -> void:
	if not save_enabled: return
	var preferences:=ConfigFile.new()
	if preferences.load(settings_path)==OK:
		model.reduce_fx=preferences.get_value("display","reduce_fx",false)
		model.skip_repeat=preferences.get_value("display","skip_repeat",false)

func _save_preferences() -> void:
	if not save_enabled: return
	var preferences:=ConfigFile.new()
	preferences.set_value("display","reduce_fx",model.reduce_fx)
	preferences.set_value("display","skip_repeat",model.skip_repeat)
	if preferences.save(settings_path)!=OK: notify("设置保存失败")
