extends SceneTree
const M=preload("res://scripts/model.gd")
const D=preload("res://scripts/data.gd")
const B=preload("res://scripts/balance.gd")
func _initialize() -> void:
 var branches: Dictionary={}
 for subject in D.BRANCHES:
  for key in D.BRANCHES[subject]:
   var spec: Array=D.BRANCHES[subject][key]
   var costs: Array=[];var effects: Array=[]
   for level in range(int(spec[2])):costs.append(ceili(spec[1]*pow(B.BRANCH_GROWTH,level)))
   for level in range(int(spec[2])+1):effects.append(D.branch_effect(subject,key,level))
   branches[subject+":"+key]={"name":spec[0],"costs":costs,"effects":effects}
 var research: Dictionary={}
 for key in D.RESEARCH:
  if D.gate(key)<=D.MAX_STAGE:research[key]={"price":D.RESEARCH[key].price,"stage":D.gate(key),"requires":D.RESEARCH[key].pre}
 var repeat: Dictionary={}
 for key in D.PRICES:
  var costs: Array=[]
  for i in range(5):costs.append(ceili(D.PRICES[key]*pow(B.PRICE_GROWTH[key],i)))
  repeat[key]={"base":D.PRICES[key],"growth":B.PRICE_GROWTH[key],"first_five":costs}
 var curve: Array=[]
 var model=M.new()
 for n in range(1,D.MAX_LAYERS+1):curve.append({"layers":n,"multiplier":model.harvest_scale(n),"manual_pixels":model.harvest_distance(n),"worker_seconds_before_efficiency":model.harvest_time(n)})
 var reactions: Dictionary={}
 for kind in ["short","giant","static","lucky"]:reactions[kind]=M.A.reaction_duration(kind)
 var parameters: Dictionary=B.new().get_script().get_script_constant_map()
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/hover_008"))
 var f:=FileAccess.open("res://reports/hover_008/balance.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"version":"v0.27-N2 IMP-20260921-008 trial","harvest_curve":curve,"cat_reaction_seconds":reactions,"research":research,"repeat":repeat,"branches":branches,"series":D.SERIES,"parameters":parameters,"layer_cd":D.LAYER_CD,"max_layers":D.MAX_LAYERS,"min_layers":D.MIN_LAYERS,"bug_seconds":D.BUG_TIME,"default_harvest_target":M.new().worker_target()},"  "));f.close()
 print("BALANCE EXPORTED");quit()

