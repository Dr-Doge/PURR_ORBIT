extends SceneTree
const M=preload("res://scripts/ea/model.gd")
const C=preload("res://scripts/ea/config.gd")
const D=preload("res://scripts/ea/decimal.gd")
var failures:=0
func check(ok:bool,label:String)->void:
	if not ok: failures+=1; printerr("FAIL: "+label)
func _initialize()->void: call_deferred("run")
func clear_layer(m:RefCounted,index:int)->void:
	m.layers[index].wear.fill(1.0); m.layers[index].mask.fill(0); m.layers[index].cleared=M.PIXELS
func expose(m:RefCounted,layer:int,find:Dictionary)->void:
	var p:Vector2=find.position; var h:Vector2=find.size*0.5
	var lo:=((p-h)*M.WIDTH/M.WORLD_WIDTH).floor()
	var hi:=((p+h)*M.WIDTH/M.WORLD_WIDTH).ceil()
	for y in range(maxi(0,int(lo.y)),mini(M.HEIGHT,int(hi.y)+1)):
		for x in range(maxi(0,int(lo.x)),mini(M.WIDTH,int(hi.x)+1)):
			m.layers[layer].mask[y*M.WIDTH+x]=0
			m.layers[layer].wear[y*M.WIDTH+x]=1
func run()->void:
	check(D.new("12345",2).plus(D.new("555",2)).exact()=="129.00".trim_suffix(".00"),"decimal add normalize")
	check(D.new("100",2).minus(D.new("1",2)).exact()=="0.99","decimal borrow")
	check(D.new("118",2).times(10).exact()=="11.8","exact multiplication")
	var enormous:RefCounted=C.growth(1000)
	var plus_one:RefCounted=enormous.plus(D.new("1"))
	check(plus_one.minus(enormous).exact()=="1","tiny income survives large wallet")
	check(enormous.digits.length()>1000,"deep decimal retained beyond scientific display")
	for depth in [1,5,10,25,50,100,1000,5000]:
		check(is_equal_approx(C.efficiency(depth-1,depth),1.0),"strength ratio at depth %d"%depth)
		check(C.efficiency(0,depth)>0.0,"weak tools retain positive wear rate at depth %d"%depth)
	var m:=M.new()
	check(m.layers.size()==5 and m.layers[4].depth==5,"five active layers")
	for i in range(5):
		check(m.layers[i].finds.size()==608,"bounded finds per layer")
		if i>0: check(m.layers[i].texture!=m.layers[i-1].texture,"no adjacent repeated terrain")
	var p:=Vector2(400,300)
	m.scratch(p,p,0.1)
	check(m.layers[0].cleared==0 and m.layers[0].wear[int(300.0/M.WORLD_HEIGHT*M.HEIGHT)*M.WIDTH+int(400.0/M.WORLD_WIDTH*M.WIDTH)]>0,"partial wear not counted as cleared")
	check(m.layers[1].cleared==0,"no through-layer damage")
	m.layers[0].cleared=M.PIXELS-1
	check(m.progress_text(0)=="97.9%","display stays below finish threshold until settlement")
	m.layers[0].cleared=0
	var first_artifact:Dictionary=m.layers[0].finds[600]
	expose(m,0,first_artifact)
	m.scan_exposed_finds()
	check(m.records.size()==1 and m.records[0].status=="raw","find queues raw item without modal")
	check(not m.records[0].has("name"),"sealed item exposes no UI name")
	var first_id:int=m.records[0].id
	m.claim_manual(first_id)
	m.add_cleaning(first_id,0.25)
	m.release_manual(first_id)
	m.machines[0].owned=true
	m.tick(1.0)
	check(m.records[0].owner=="machine0" and m.records[0].progress[0]>0.25,"machine inherits partial manual progress")
	m.claim_manual(first_id)
	check(m.machines[0].task==-1 and m.records[0].owner=="manual","manual takeover releases workstation")
	for i in range(3): m.add_cleaning(first_id,1.0)
	check(m.discovered.size()==1 and m.knowledge==1,"identify grants once")
	var estimate:RefCounted=m.sale_price(m.records[0])
	m.polish(first_id,8)
	check(m.sale_price(m.records[0]).compare(estimate)>0,"polish raises fixed source price")
	check(m.buy_talent("T00") and m.knowledge==0,"knowledge independent from money")
	m.reset_talents(); check(m.knowledge==1,"talent reset exact refund")
	check(m.sell(first_id) and m.discovered.size()==1,"sale retains discovery")
	check(not m.sell(first_id),"no repeated sale")
	var baseline:RefCounted=m.wallet.clone()
	clear_layer(m,0); m.scan_exposed_finds()
	check(m.wallet.minus(baseline).exact()=="870","first layer exact income")
	var saved_mask:PackedByteArray=m.layers[1].mask.duplicate()
	m.advance_layers()
	check(m.base_depth==2 and m.layers.size()==5 and m.layers[4].depth==6,"sixth layer generated")
	check(m.layers[0].mask==saved_mask,"existing masks survive scrolling")
	var income:RefCounted=m.wallet.clone()
	clear_layer(m,0); m.scan_exposed_finds(); m.advance_layers()
	check(m.wallet.minus(income).exact()=="1026.6","second layer decimal income conserved")
	check(m.wallet.floor_value().exact()!="0","floor only for display")
	# Multiple top layers complete in a single simulation frame.
	for i in range(3): clear_layer(m,i)
	m.scan_exposed_finds(); m.advance_layers()
	check(m.base_depth==6 and m.layers.size()==5,"batch rotation correct")
	# Save/load preserves generated IDs, masks, fractional money, and ownership.
	var path:="user://ea_validation.dat"
	m.wallet=m.wallet.plus(D.new("13",2))
	m.claim_manual(int(m.records.back().id))
	check(m.save_to(path)==OK,"first save")
	check(m.save_to(path)==OK,"atomic overwrite")
	var restored:=M.new(777)
	check(restored.load_from(path),"load valid save")
	check(restored.wallet.exact()==m.wallet.exact() and restored.layers[0].texture==m.layers[0].texture,"restore wallet fraction and texture")
	check(restored.layers[0].mask==m.layers[0].mask and restored.layers[0].finds==m.layers[0].finds,"restore masks and fixed loot")
	check(restored.records.back().owner=="","manual task safely released on load")
	var money_before:RefCounted=restored.wallet.clone()
	restored.scan_exposed_finds()
	check(restored.wallet.compare(money_before)==0,"no duplicate collection after load")
	DirAccess.remove_absolute(path)
	# Full queues, six concurrent machines, universal compatibility and no duplicate claims.
	var q:=M.new()
	for i in range(5): clear_layer(q,i)
	q.scan_exposed_finds()
	for machine in q.machines: machine.owned=true
	q.tick(0.1)
	var machine_path := "user://ea_machine_validation.dat"
	check(q.save_to(machine_path)==OK,"save running machines")
	var resumed := M.new()
	check(resumed.load_from(machine_path),"load running machines")
	check(resumed.machines==q.machines and resumed.records==q.records,"machine ownership and partial progress survive load")
	DirAccess.remove_absolute(machine_path)
	var claimed:Dictionary={}
	for machine in q.machines:
		check(not claimed.has(machine.task),"one item per machine")
		claimed[machine.task]=true
	q.paused=true
	var remaining_before:float=q.records[0].progress[0]
	q.tick(10.0)
	check(q.records[0].progress[0]==remaining_before,"explicit pause stops workers")
	q.paused=false
	for i in range(400): q.tick(0.1)
	check(q.identified_series==[true,true,true,true,true],"all series processed by workers")
	var frozen:Dictionary=q.records[0].estimate.duplicate()
	q.base_depth=100
	check(q.records[0].estimate==frozen,"inventory does not reprice at current depth")
	var sales := M.new()
	clear_layer(sales,0); sales.scan_exposed_finds(); sales.auto_sell=true
	var first:Dictionary=sales.records[0]
	sales.identify(first)
	check(first.status=="identified","automatic sale preserves first discovery")
	var duplicate:Dictionary=sales.records[1]
	duplicate.variant=first.variant
	sales.identify(duplicate)
	check(duplicate.status=="sold" and sales.knowledge==1,"automatic duplicate sale does not award repeat knowledge")
	var locked:Dictionary=sales.records[2]
	locked.variant=first.variant; locked.locked=true
	sales.identify(locked)
	check(locked.status=="identified" and not sales.sell(int(locked.id)),"locked duplicates protected from automatic and manual sale")
	# First three reserved variants unique; at most ninth draw completes a set.
	var pity:=M.new()
	for series in range(5):
		check(pity.draws[series].size()>=3,"first three draws distinct")
		pity._draw_variant(series)
		check(pity.draws[series].size()==5,"ninth generated item completes ordinary set")
	# Robot upgrades independent from hand tool, fixed frequency and scoped top layer.
	var bot:=M.new()
	bot.levels.power=100
	bot.levels.auto=1
	bot._robot_step(0,0.1)
	check(bot.layers[0].cleared==0,"manual strength does not boost robot")
	bot.levels.auto_power=5
	bot._robot_step(0,0.1)
	check(bot.layers[0].cleared>0 and bot.layers[1].cleared==0,"robot sample only clears uppermost layer")
	print("EA_MODEL_CHECKS: %d failure(s)"%failures)
	quit(1 if failures else 0)
