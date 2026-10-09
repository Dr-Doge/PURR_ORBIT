extends SceneTree
const Scene=preload("res://scenes/archive/测试场景_004.tscn")
const Lab=preload("res://scripts/lab_model.gd")
const Base=preload("res://scripts/model.gd")
var game
var checks=0
var failures=0
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(why)
func frames() -> void:
 for i in range(4):await process_frame
func motion(at: Vector2) -> void:
 var e=InputEventMouseMotion.new();e.position=at;root.push_input(e,true)
func click(at: Vector2,down: bool=true) -> void:
 var e=InputEventMouseButton.new();e.position=at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e,true)
func press(text: String) -> bool:
 await frames()
 for b in game.find_children("*","Button",true,false):
  if b.text.begins_with(text) and b.is_visible_in_tree() and not b.disabled:
   var parent=b.get_parent()
   while parent!=null:
    if parent is ScrollContainer:parent.ensure_control_visible(b)
    parent=parent.get_parent()
   await frames()
   var at: Vector2=b.get_global_rect().get_center();motion(at);click(at);click(at,false);await frames();return true
 check(false,"Reachable button: "+text);return false
func advance(seconds: float) -> void:
 for i in range(roundi(seconds/0.05)):game._process(0.05)
func capture(name: String) -> void:
 await frames();await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png("res://reports/lab_004/"+name+".png")==OK,"Capture "+name)
func open_facility(f: Dictionary) -> void:
 if game.modal!="":game.close_modal()
 var at: Vector2=game.room.screen_position(f.pos)+Vector2(0,-80)*game.room.object_scale(f.pos)
 motion(at);click(at);click(at,false);await frames()
 check(game.modal=="facility","Facility opens through visible upper artwork")
func _initialize() -> void:
 root.size=Vector2i(1440,810);call_deferred("run")
func run() -> void:
 var authored=Scene.instantiate()
 check(authored.name=="测试场景","Requested scene name")
 check(authored.get_node("TestSetup/Cats").get_child_count()==12,"Editable preset markers")
 check(authored.get_node("Room/WhiteboxViewport/World3D/WhiteboxRoom/ActorLighting").get_child_count()==22,"All 22 visible actor cards exist before ready")
 authored.set_script(null);authored.get_node("Room").set_script(null)
 var cursor=authored.get_node("Cursor");authored.remove_child(cursor);cursor.free()
 root.add_child(authored);await frames();await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://reports/lab_004/00_authored.png")
 authored.queue_free();await frames()
 game=Scene.instantiate();game.testing=true;root.add_child(game);game.set_process(false);await frames()
 check(game.active and game.modal=="","Directly playable, no developer-key setup")
 var m=game.model
 check(m.cats.size()==12 and m.workers.size()==2 and m.facilities.size()==7,"Real preset model counts")
 check(m.wallet==121 and m.food[0]==40 and m.tokens==2 and m.minted==2,"Finite budget and consistent token accounting")
 check(m.facilities[0].grain==6 and m.facilities[1].grain==6,"Finite feeder stock")
 check(m.cats.filter(func(c):return c.station==-1).size()==9,"Nine cats free, three facility occupants")
 check(m.levels.is_empty() and m.owned.is_empty(),"Growth and collection room remains")
 check(ProjectSettings.get_setting("application/run/main_scene")=="res://scenes/3D scene.tscn","Formal startup unchanged")
 var official=load("res://scenes/room_3d.tscn").instantiate()
 var official_floor=official.get_node("WhiteboxViewport/World3D/WhiteboxRoom/Floor")
 check(official_floor.mesh!=game.room.shell.get_node("Floor").mesh and official_floor.material_override!=game.room.shell.get_node("Floor").material_override,"Mutable test meshes/materials isolated")
 official.free()
 var names={}
 for c in m.cats:
  check(not names.has(c.identity.name) and Lab.Personas.valid_saved(c.identity,c.id),"Persistent unique valid identity")
  names[c.identity.name]=true
  check(c.identity.source.contains("AI预生成") and Lab.Personas.valid_tags(Lab.Personas.library(),c.identity.tags,c.kind),"Actual category draw resolves compatible offline AI cache")
 var baseline=m.snapshot()
 check(m.tree.size()==126 and not m.tree.has("N11") and not m.tree.has("N12"),"No job-hat or maintenance nodes")
 for id in m.tree:
  for pre in m.tree[id].all+m.tree[id].any:
   if not m.tree.has(pre):check(false,"Dangling tree edge "+id+" / "+pre)
 check(m.tree.S10.all==["N10"] and m.tree.S20.all==["N10"],"Group and later upgrades have reachable replacement prerequisites")
 var tree_probe=Lab.new();tree_probe.wallet=10000000.0
 for iteration in range(20):
  for id in tree_probe.tree:
   if not tree_probe.node_owned(id) and tree_probe.node_reason(id)=="":tree_probe.buy_node(id)
 check(tree_probe.tree.keys().all(func(id):return tree_probe.node_owned(id)),"All retained tree nodes can be purchased without deleted jobs")
 check(m.upgrade_price("worker","efficiency")==Base.new().upgrade_price("worker","efficiency"),"Existing worker price retained")
 var probe=Lab.new();probe.configure(game.get_node("TestSetup"))
 for c in probe.cats:c.fed=999;c.idle_left=999
 probe.facilities[0].grain=0;probe.facilities[0].bugs=2;probe.facilities[4].broken=true
 probe.workers[0].role="general";probe.workers[0].job={"kind":"refill","target":probe.facilities[0].id,"cat":-1};probe.workers[0].cooldown=5.0
 var stock=probe.food.duplicate();var occupied=probe.cats.map(func(c):return c.station)
 for i in range(200):probe.tick(0.05)
 check(probe.facilities[0].grain==0 and probe.food==stock and probe.facilities[0].bugs==2 and probe.facilities[4].broken,"Workers cannot refill, clean or repair while player is absent")
 check(probe.workers.all(func(w):return w.role=="harvest" and w.job.get("kind","harvest")=="harvest"),"Stale general/refill jobs are blocked in model")
 check(not probe.set_role(probe.workers[0].id,"repair") and not probe.repair(probe.facilities[4].id,true),"Direct role and worker-repair API rejected")
 check(not probe.research("hats") and not probe.research("maint"),"Obsolete research cannot be bought outside the UI")
 # Exercise all four natural transformation paths with unchanged probabilities.
 for kind in ["feeder","sun","arcade","altar"]:
  var t=Lab.new();t.cats.clear();t.workers.clear();t.facilities.clear();t.next_id=1;t.rng.seed=928
  t.researches[kind]=true;t.wallet=100000;t.buy(kind,Vector2(500,450))
  var cat=t.add_cat(Vector2(500,485));var original=cat.identity.duplicate(true);var f=t.facilities[0]
  for attempt in range(1000):
   if cat.kind!="short":break
   if kind=="feeder":
    cat.fed=0;cat.pos=t.feeding_spot(f);cat.feed_target=f.id;cat.eat_time=t.B.FEED_EAT_TIME-0.05;f.grain=1
   else:
    cat.layers=1
    t.assign(cat.id,f.id)
    cat.timer=100.0
   t.tick(0.1)
  var expected={"feeder":"giant","sun":"static","arcade":"lucky","altar":"alien"}
  check(cat.kind==expected[kind] and cat.identity==original,"Natural "+kind+" conversion retains identity")
 var collection=Lab.new();collection.configure(game.get_node("TestSetup"));collection.tokens=37;collection.minted=36
 var positions=collection.cats.map(func(cat):return cat.pos)
 for i in range(12):collection.draw_capsule()
 check(collection.round_no==2 and collection.pool().size()==24 and collection.tokens==25 and collection.cats.map(func(cat):return cat.pos)==positions,"12th draw restocks 24 without extra debit or scene reset")
 for i in range(24):collection.draw_capsule()
 check(collection.owned.size()==36 and collection.draw_capsule()=="" and collection.tokens==1,"Empty pool preserves remaining coin")
 var saved=Lab.new();check(saved.restore(baseline),"Test snapshot roundtrip")
 check(saved.cats.map(func(c):return c.identity)==m.cats.map(func(c):return c.identity),"Identities retained exactly on restore")
 check(not saved.restore(Base.new().snapshot()),"Formal save schema rejected by test model")
 check(saved.save_to("user://space_cats_v27.save")==ERR_INVALID_PARAMETER and not saved.load_from("user://space_cats_v27.save"),"Formal file access rejected before I/O")
 check(m.save_to("res://reports/lab_004/isolated.save")==OK and saved.load_from("res://reports/lab_004/isolated.save"),"Isolated test file can be saved and loaded")
 var bad=baseline.duplicate(true);bad.cats[1].identity.name=bad.cats[0].identity.name
 check(not saved.restore(bad),"Duplicate identity rejected without replacing state")
 var legacy=baseline.duplicate(true);legacy.cats[0].erase("identity")
 check(saved.restore(legacy) and saved.cats[0].has("identity"),"Missing test identity assigned once")
 var identity=saved.cats[0].identity.duplicate(true);saved.restore(saved.snapshot())
 check(saved.cats[0].identity==identity,"Identity backfill is stable")
 var book=Lab.Personas.library();book.profiles=[]
 var fallback=Lab.Personas.generate(99,"short",5,[],book)
 check(fallback.source.contains("模板回退") and fallback.tags.size()==6,"Cache failure samples categories and marks fallback")
 var invalid=baseline.cats[0].identity.tags.duplicate();invalid.origin="unknown"
 check(not Lab.Personas.valid_tags(Lab.Personas.library(),invalid,"short"),"Unknown or conflicting prompt keywords rejected")
 var incompatible=baseline.cats[0].identity.tags.duplicate()
 incompatible.origin="origin_1" if incompatible.origin!="origin_1" else "origin_2"
 check(not Lab.Personas.valid_tags(Lab.Personas.library(),incompatible,"short"),"Background and past constraints reject contradictory keyword combinations")
 var malformed=Lab.Personas.library();malformed.profiles=[null,{"name":"x","bio":1},[]]
 check(Lab.Personas.generate(100,"short",7,[],malformed).source.contains("模板回退"),"Malformed cache entries fall back safely")
 var a=Lab.Personas.generate(99,"short",7);var b=Lab.Personas.generate(99,"short",7)
 check(a==b,"Fixed seed reproduces selection")
 for i in range(2):game.start_game()
 m=game.model
 check(var_to_bytes(m.snapshot())==var_to_bytes(baseline),"Reset restores exactly one preset, no repeated grant")
 await capture("01_runtime")
 # Mouse harvesting and reaction exclusion on the real projected cat.
 var c=m.cats[0];var before=m.harvests
 for i in range(16):motion(game.room.screen_position(c.pos)+Vector2(-18 if i%2 else 18,0))
 check(m.harvests==before+1 and c.reaction_left>0,"Actual rubbing harvests and starts reaction")
 for i in range(16):motion(game.room.screen_position(c.pos)+Vector2(-18 if i%2 else 18,0))
 check(m.harvests==before+1 and c.pet==0,"Cannot collect again during produce")
 motion(Vector2(20,160));advance(1.2)
 # Manual drag into the second empty sun.
 c=m.cats[1];var sun=m.facilities[3]
 motion(game.room.screen_position(c.pos));click(game.room.screen_position(c.pos))
 motion(game.room.screen_position(sun.pos));click(game.room.screen_position(sun.pos),false)
 check(c.station==sun.id,"Actual drag assigns cat to an empty facility")
 check(not m.assign(m.cats[2].id,sun.id),"Single-cat facility prevents second occupant")
 motion(Vector2(20,160));advance(3.0)
 check(c.station==-1,"Sun releases cat when ready")
 # Genuine UI purchase, refill and bug clearing.
 await open_facility(m.facilities[0])
 var grain=m.facilities[0].grain;var food=m.food[0]
 await press("补入标准")
 check(m.facilities[0].grain>grain and m.food[0]<food,"Manual refill transfers existing stock")
 var wallet=m.wallet
 await press("备好当前猫粮")
 check(m.wallet==wallet-60 and m.food[0]>=100,"Food purchase uses finite money")
 game.close_modal();await press("测试台");await press("演示虫害")
 await press("捶它！");await press("捶它！")
 check(m.facilities[0].bugs==0,"Manual two-click bug removal")
 game.close_modal();await press("测试台");await press("演示干扰")
 advance(0.05)
 check(m.facilities[4].broken,"Interference runs through existing event clock")
 await open_facility(m.facilities[4])
 for i in range(6):await press("捶打设备")
 check(not m.facilities[4].broken,"Six real repair clicks restore entertainment")
 game.close_modal();motion(Vector2(20,160));before=m.harvests;advance(20)
 check(m.harvests>before,"Workers perform real harvest cycles")
 check(not m.inventory.is_empty(),"Entertainment actually generates sellable items")
 game.show_inventory();await frames();wallet=m.wallet
 await press("出售未预留物品")
 check(m.wallet>wallet and m.inventory.is_empty(),"Actual inventory sale increases wallet")
 game.close_modal();game.show_tree("worker");game.show_tree_detail("U11-L1");await frames();wallet=m.wallet
 await press("购买 · 40 毛球")
 check(m.lv("worker","efficiency")==1 and m.wallet==wallet-40,"Actual unified-tree purchase invests earned money")
 game.close_modal();game.show_gacha();await frames();var tokens=m.tokens
 await press("投入 1 枚代币")
 check(m.owned.size()==1 and m.tokens==tokens-1,"One real gacha action draws one collectible")
 await capture("02_collection")
 game.close_modal();await press("猫咪档案")
 await press(m.cats[0].identity.name)
 var stable=m.cats[0].identity.duplicate(true)
 await capture("03_identity")
 game.close_modal();await press("猫咪档案");await press(m.cats[0].identity.name)
 check(m.cats[0].identity==stable,"Opening identity panel never rerolls")
 game.close_modal();await press("猫咪档案");await press("新增访客")
 check(m.cats.size()==13 and m.cats.back().identity.tags.size()==6,"New live cat uses category generation pipeline")
 game.close_modal();game.show_workers();await capture("04_workers")
 check(game.body.find_children("*","OptionButton",true,false).is_empty(),"No job role picker in initial worker UI")
 game.close_modal();root.size=Vector2i(1280,720);await frames();await press("测试台");await capture("05_small_panel")
 check(game.card.get_global_rect().end.x<=game.size.x+1 and game.card.get_global_rect().end.y<=game.size.y+1,"Test panel stays inside small viewport")
 game.close_modal();await press("重置预置")
 check(game.model.cats.size()==12 and game.model.wallet==121 and game.model.tokens==2 and game.model.owned.is_empty(),"Real reset restores finite clean state")
 print("LAB004: ",checks," checks, ",failures," failures")
 var report=FileAccess.open("res://reports/lab_004/result.json",FileAccess.WRITE);report.store_string(JSON.stringify({"checks":checks,"failures":failures,"budget":game.model.initial_budget,"tree_nodes":game.model.tree.size(),"source":"404099a5"},"  "));report.close()
 game.queue_free();await frames();quit(0 if failures==0 else 1)
