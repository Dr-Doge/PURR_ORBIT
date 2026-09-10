extends SceneTree
const M=preload("res://scripts/shovel/model.gd")
func _initialize():
	var values=[]
	for y in [100,250,400,550,700]:
		for x in [100,300,500,700,900]:
			var m=M.new()
			m.dispatch(Vector2(x,y)); m.tick(5); m.tick(20)
			values.append(float(m.wallet.exact()))
	var total=0.0
	for v in values: total+=v
	print("SHOVEL INCOME samples=%d average=%.2f min=%.0f max=%.0f"%[values.size(),total/values.size(),values.min(),values.max()])
	quit()
