extends "res://scripts/scene_3d.gd"
const LabModel=preload("res://scripts/lab_model.gd")
const LAB_SAVE="user://space_cats_lab_004.save"
func _ready() -> void:
 model=LabModel.new()
 super._ready()
 $LabBar/Tools.pressed.connect(show_lab)
 $LabBar/Cats.pressed.connect(show_cat_list)
 $LabBar/Reset.pressed.connect(start_game)
 start_game()
 get_window().title="毛球计划 · 测试场景"
func show_start() -> void:
 # Base _ready invokes this virtually. Never inspect the formal save or show its load buttons.
 pass
func new_game_prompt() -> void:start_game()
func start_game() -> void:
 model=LabModel.new();model.configure($TestSetup)
 room.model=model;room.effects.clear();room.placing="";room.dragging=-1
 active=true;save_clock=0;close_modal();room.step(0)
 message("测试预置已重置：12只猫、2名收割工人。上方测试台可手动保存与演示异常。")
func save_game() -> bool:
 # All inherited autosave calls stay in memory. Only explicit test-save actions write.
 return true
func save_test() -> void:
 if testing:message("自动验证使用内存／隔离报告存档");return
 var result: Error=model.save_to(LAB_SAVE)
 message("测试存档已保存" if result==OK else "测试存档保存失败，当前进度保留")
func load_test() -> void:
 if testing:return
 var restored=LabModel.new()
 if not restored.load_from(LAB_SAVE):message("测试存档缺失或不兼容，当前场景保留");return
 model=restored;room.model=model;room.effects.clear();close_modal();room.step(0)
 message("已读取独立测试存档")
func guidance() -> String:
 for f in model.facilities:
  if f.bugs>0:return "喂食器有虫：点击设备连点清理，收割工人不会代劳。"
  if f.broken:return "娱乐黑屏：点击设备捶打6次，人工恢复。"
  if f.kind=="feeder" and f.grain==0:return "喂食器空了：采购猫粮后手动补入，猫会自动前来吃。"
 return "摸自由猫 → 投资成长树；拖猫进空设备。测试台可演示异常，档案可看词条来源。"
func show_pause() -> void:
 var content=screen("测试场景 · 暂停","暂停猫、设施与工人。正式存档不在此场景读取或写入。","pause",true)
 button("继续测试",close_modal,content);button("保存测试进度",save_test,content)
 button("读取测试进度",load_test,content);button("重置测试预置",start_game,content)
 button("设置",show_settings,content);button("测试说明",show_lab,content)
 button("退出测试",func():get_tree().quit(),content)
func show_help() -> void:show_lab()
func show_lab() -> void:
 var content=screen("测试场景 · 操作台","源版本404099a5；独立试玩配置，预置资源不代表正式开局。","lab",true)
 paragraph("① 不按键来回摸自由猫；按住拖入空日光浴／娱乐／祭坛。
② 用毛球采购猫粮、手动补给并投资统一树；工人只接手收割。
③ 猫自动进食；娱乐获奖自动入库，卖出才变毛球。
④ 两枚预置代币可在仪器抽取，12＋24补货保持。",content,18)
 paragraph("开局毛球 %d＝工效 %d＋目标层 %d＋CD %d＋一包猫粮 %d。40份库存、两料仓各6份。全部设施已解锁，性能未满级。" % [model.initial_budget.values().reduce(func(total,value):return total+value,0),model.initial_budget.efficiency,model.initial_budget.layers,model.initial_budget.cooldown,model.initial_budget.food_packet],content,15)
 var line=row(content)
 button("演示虫害（测试注入）",func():model.facilities[0].bugs=1;model.facilities[0].hits=0;close_modal();show_facility(model.facilities[0].id),line)
 button("演示干扰（推进事件计时）",func():model.interference=D.INTERFERENCE_TIME-0.01;close_modal(),line)
 var saves=row(content)
 button("保存测试进度",save_test,saves);button("读取测试进度",load_test,saves);button("重置测试预置",start_game,saves)
 paragraph("人设来自本轮AI编写的离线缓存；按六类关键词约束抽样，界面显示版本、种子和来源。缓存不可用时明确标为模板回退。在线AI服务尚未配置，不会发起付费请求。",content,15)
 paragraph("测试树去除N11职责帽／N12工人维护；S10/S20改接N10及原ABC入口，保留分组收割与升级。正式旧档迁移、退款和在线AI接入尚未实施。",content,15)
func show_workers() -> void:
 var content=screen("收割工人","工人仅寻找、接近并收割猫；CD期间不补粮、搬猫、清虫或维修。","workers")
 button("升级工效、目标层与CD",func():show_tree("worker"),content)
 for w in model.workers:
  var line=row(content);var info=label("");line.add_child(info)
  live(info,func():return "精灵 #%d · %s · 目标%d层 · CD %.1f秒" % [w.id,w.status,model.worker_target(w),w.cooldown])
  if model.node_owned("S10"):
   var pick=OptionButton.new();line.add_child(pick)
   for i in range(model.group_count()):pick.add_item("猫群 "+str(i+1),i)
   pick.select(w.get("group",0));pick.item_selected.connect(func(index:int):transact(func():return model.set_group("worker",w.id,index)))
 if model.node_owned("S10"):show_groups(content)
func show_cat_list() -> void:
 var content=screen("猫咪档案","姓名和简介绑定个体，重开面板或读档不会重新抽取。人设不改变技能和产量。","cats")
 button("新增访客（测试免费短毛猫）",func():developer_command("short");room.step(0);show_cat_list(),content)
 for c in model.cats:
  button("%s · %s #%d · %d层" % [c.identity.name,D.title(c.kind),c.id,c.layers],func():show_cat_profile(c.id),content)
func show_cat_profile(id: int) -> void:
 var c: Dictionary=model.cat(id)
 if c.is_empty():return
 var identity: Dictionary=c.identity
 var content=screen(identity.name+" · "+D.title(c.kind),"档案编号 "+str(c.id),"cat_profile")
 paragraph(identity.bio,content,22)
 paragraph("来源：%s
词库：%s · 生成种子：%d
缓存记录：%s" % [identity.source,identity.version,identity.seed,identity.cache_key],content,14)
 var book: Dictionary=LabModel.Personas.library()
 var labels={"origin":"来处","past":"经历","trait":"性格","habit":"习惯","contrast":"反差","naming":"命名"}
 for category in LabModel.Personas.CATEGORIES:
  var key: String=identity.tags.get(category,"")
  for word in book.get("words",{}).get(category,[]):
   if word.id==key:paragraph(labels[category]+"："+word.text+"  ["+key+"]",content,15)
 button("返回全部猫咪",show_cat_list,content)
func show_facility(id: int) -> void:

 var f: Dictionary=model.facility(id)
 if f.is_empty():return
 var content := screen(D.title(f.kind), "点击设备操作；回到场地后，也可以直接把猫拖进对应区域。", "facility")
 var info := label("");content.add_child(info)
 live(info,func():return "料仓 %d / %d   ·   蟑螂 %d" % [f.grain,model.feed_capacity(),f.bugs] if f.kind=="feeder" else "占用 %d / %d   %s" % [model.occupants(id).size(),model.capacity(f),"黑屏 · 停止产出" if f.broken else "正常运行"])
 if f.kind=="feeder":
  paragraph("猫会自行前来进食；吃饱后离开也能保持加成。补粮、清虫由你负责；工人只收割。",content,15)
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
  else: paragraph("内部干净。"+(" 建好日光浴后请定期手动打理。"),inside)
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

func show_shop() -> void:
 super.show_shop()
 for node in body.find_children("*","Label",true,false):
  if node.text=="替你收毛球、补粮和搬猫。":node.text="只接手收割；补给、安排和维护由你负责。"
