extends SceneTree
const Config = preload("res://scripts/prototype_harvest/config.gd")
func _initialize() -> void:
 var source: Script=load("res://scripts/prototype_harvest/config.gd")
 var values: Dictionary=source.get_script_constant_map()
 values.BODY_RADIUS={"x":Config.BODY_RADIUS.x,"y":Config.BODY_RADIUS.y}
 values["stage_seeds"]=[104901,104902,104903,104904,104905,104906,104907,104908]
 values["status"]="Independent prototype playtest values; not final balance"
 var file=FileAccess.open("res://reports/prototype_20261009/config.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(values,"  "));file.close()
 print("Prototype config exported");quit()
