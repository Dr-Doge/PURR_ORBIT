extends RefCounted
# Explicit developer commands reuse normal creation, research and collection paths.
const D=preload("res://scripts/data.gd")
const MONEY=10000
const FOOD=100
const COMMANDS=[
 ["money","1","增加 10,000 毛球"],
 ["food","2","增加 100 份标准猫粮"],
 ["feeder","3","获得喂食器"],
 ["sun","4","获得日光浴"],
 ["arcade","5","获得娱乐设施"],
 ["static","L","获得静电猫"],
 ["worker","面板","获得小帮手"],
 ["short","7","获得短毛猫"],
 ["stage2","8","补齐首批12件收藏，进入第二阶段"]
]
static func unlock(model,key: String) -> bool:
 if not D.RESEARCH.has(key) or model.has(key):return true
 for pre in D.RESEARCH[key].pre:
  if not unlock(model,pre):return false
 model.wallet+=float(D.RESEARCH[key].price)
 return model.research(key)
static func execute(model,key: String) -> String:
 if key=="static":
  var at: Vector2=D.FLOOR.get_center()
  var c: Dictionary=model.add_cat(at)
  c.kind="static";c.reaction_kind="static"
  if not model.Space.is_clear(model,c,at):c.pos=model.Space.escape_spot(model,c);c.dest=c.pos
  return "已生成一只静电猫"
 if key=="money":model.wallet+=MONEY;return "+10,000 毛球"
 if key=="food":model.food[0]+=FOOD;return "+100 份标准猫粮（在喂食器中补入）"
 if key=="stage2":
  if model.round_no>=2:return "已经处于第二阶段，未重复发放收藏"
  model.first_token=true;model.accept_contact()
  while model.round_no==1:
   if model.tokens<1:model.tokens+=1;model.minted+=1
   if model.draw_capsule()=="":return model.error
  return "首批12件已补齐，第二阶段已开放；现有进度保留"
 if not D.PRICES.has(key):return "未知开发者指令"
 if model.round_no<D.gate(key):return "娱乐设施需要第二阶段；按8可补齐首批收藏并进入第二阶段"
 # Find a free placement before granting research or spending anything.
 var at:=Vector2.ZERO
 var found: bool=false
 for y in [410,560,700]:
  for x in [220,440,660,880,1100,1280]:
   var candidate:=Vector2(x,y)
   var available: bool=true
   for f in model.facilities:
    if f.pos.distance_to(candidate)<140:available=false;break
   if available:at=candidate;found=true;break
  if found:break
 if not found:return "场地没有足够空位，请移动设施后重试"
 var wallet: float=model.wallet
 var ok: bool=unlock(model,key)
 if ok:
  model.wallet+=model.price(key)
  ok=model.buy(key,at)
 model.wallet=wallet
 return "已免费获得"+D.title(key)+"；可按现有操作移动或使用" if ok else model.error
