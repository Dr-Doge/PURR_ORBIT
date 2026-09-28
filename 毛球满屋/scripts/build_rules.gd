extends RefCounted
const D=preload("res://scripts/data.gd")
static func spec(m,route: String) -> float:
 var value: float=0
 for i in range(1,4):
  for part in ["T","P","Q"]:
   if m.node_owned(route+str(i)+part):value+=(0.05 if part=="T" else 0.03) if i==3 else (0.03 if part=="T" else 0.02)
 return value
static func count(m,route: String,part: String) -> int:
 var n: int=0
 for i in range(1,4):
  if m.node_owned(route+str(i)+part):n+=1
 return n
static func combo_need(m) -> int:
 return 13-count(m,"A","M")-count(m,"A","U")
static func combo_reward(m) -> float:
 return 0.25+(0.1 if m.node_owned("A2M") else 0.0)+(0.15 if m.node_owned("A3M") else 0.0)+0.05*count(m,"A","V")
static func charge_capacity(m) -> int:return count(m,"B","M")+count(m,"B","U")
static func charge_layer(m,c: Dictionary,source: String) -> void:
 if not m.node_owned("B1M") or c.fed<=0:return
 if source=="sun" and not m.node_owned("B2M"):return
 if source not in ["natural","sun"]:return
 if not c.has("charges"):c.charges=[]
 if c.charges.size()<charge_capacity(m):c.charges.append(c.layers)
static func harvest_bonus(m,c: Dictionary,n: int) -> float:
 var bonus: float=spec(m,"A") if n==1 else (spec(m,"B") if n>=4 else 0.0)
 var state: Dictionary=m.build_state
 if n==1:
  if m.node_owned("A1M"):
   state.combo=int(state.get("combo",0))+1
   if state.combo>=combo_need(m):bonus+=combo_reward(m);state.combo=0
  for cross in ["XAB","XAC"]:
   if not m.node_owned(cross):continue
   var progress: String=cross+"_count";var ready: String=cross+"_ready"
   if not state.get(ready,false):
    state[progress]=int(state.get(progress,0))+1
    if state[progress]>=(8 if cross=="XAB" else 20):state[ready]=true;state[progress]=0
 elif n>=4 and state.get("XAB_ready",false):bonus+=0.05;state.XAB_ready=false
 var remaining: Array=[];var consumed: int=0
 for layer in c.get("charges",[]):
  if layer<=n:consumed+=1
  else:remaining.append(layer-n+1)
 if n>=4:bonus+=consumed*(0.03+0.01*count(m,"B","V"))
 c.charges=remaining
 return bonus
static func sale_value(m,item: Dictionary) -> float:
 return float(item.value)*m.effect("sale")*(1.0+spec(m,"C"))
static func order_size(kind: String) -> int:
 return {"pair":2,"trio":3,"set":5}.get(kind,0)
static func order_unlocked(m,kind: String) -> bool:
 return m.node_owned({"pair":"C1M","trio":"C2M","set":"C3M"}.get(kind,""))
static func order_factor(m,kind: String) -> float:
 return {"pair":1.05,"trio":1.08,"set":1.12}.get(kind,1.0)+0.02*count(m,"C","V")
static func refresh_orders(m) -> void:
 var assigned: Dictionary={}
 for order in m.orders:
  var kept: Array=[];var names: Array=[]
  for item in m.inventory:
   if order.ids.has(item.id) and not assigned.has(item.id):kept.append(item.id);names.append(item.name);assigned[item.id]=true
  order.ids=kept
  for item in m.inventory:
   if order.ids.size()>=order_size(order.kind):break
   if assigned.has(item.id):continue
   if not names.is_empty() and ((order.kind=="pair" and item.name!=names[0]) or (order.kind!="pair" and names.has(item.name))):continue
   order.ids.append(item.id);names.append(item.name);assigned[item.id]=true
static func reserved_ids(m) -> Array:
 var ids: Array=[]
 for order in m.orders:ids.append_array(order.ids)
 return ids
static func create_order(m,kind: String) -> bool:
 if not order_unlocked(m,kind):return m.fail("先在成长树解锁该订单")
 if m.orders.size()>=1+count(m,"C","U"):return m.fail("预留清单已满，可提交或取消已有清单")
 m.orders.append({"kind":kind,"ids":[]});refresh_orders(m);return true
static func sell(m,index: int=-1) -> float:
 refresh_orders(m)
 var selected: Array=[];var factor: float=1.0
 if index>=0:
  if index>=m.orders.size():return 0.0
  var order: Dictionary=m.orders[index]
  if order.ids.size()!=order_size(order.kind):m.fail("预留物品尚未齐全");return 0.0
  selected=order.ids.duplicate();factor=order_factor(m,order.kind)
 else:
  var reserved: Array=reserved_ids(m)
  for item in m.inventory:
   if not reserved.has(item.id):selected.append(item.id)
 var value: float=0
 for item in m.inventory.duplicate():
  if not selected.has(item.id):continue
  var base: float=sale_value(m,item);value+=base*factor
  if m.build_state.get("XAC_ready",false):value+=base*0.05;m.build_state.XAC_ready=false
  m.inventory.erase(item)
 if index>=0:m.orders.remove_at(index)
 m.wallet+=value;refresh_orders(m);return value
static func summary(m) -> String:
 var parts: PackedStringArray=[]
 if m.node_owned("A1T"):parts.append("薄毛 +%.0f%%" % (spec(m,"A")*100))
 if m.node_owned("A1M"):parts.append("连收 %d/%d" % [m.build_state.get("combo",0),combo_need(m)])
 if m.node_owned("B1T"):parts.append("厚毛 +%.0f%%" % (spec(m,"B")*100))
 if m.node_owned("B1M"):parts.append("蓄养上限 %d格" % charge_capacity(m))
 if m.node_owned("C1T"):parts.append("估价 +%.0f%%" % (spec(m,"C")*100))
 return " · ".join(parts)
