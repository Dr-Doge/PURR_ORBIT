extends RefCounted
# Explicit developer commands reuse normal creation, research and collection paths.
const D=preload("res://scripts/data.gd")
const MONEY=10000
const FOOD=100
const CAT_KINDS=["short","giant","static","lucky","alien"]
const COMMANDS=[
 ["money","资源","增加 10,000 毛球"],
 ["food","资源","增加 100 份标准猫粮"],
 ["feeder","设施与工人","获得喂食器"],
 ["sun","设施与工人","获得日光浴"],
 ["arcade","设施与工人","获得娱乐设施"],
 ["altar","设施与工人","获得祭坛"],
 ["worker","设施与工人","获得小帮手"],
 ["short","生成猫咪","生成短毛猫"],
 ["giant","生成猫咪","生成巨型猫"],
 ["static","生成猫咪","生成静电猫"],
 ["lucky","生成猫咪","生成招财猫"],
 ["alien","生成猫咪","生成外星猫"],
 ["stage2","流程测试","补齐首批12件收藏"],
 ["bugs","流程测试","演示喂食器虫害"],
 ["interference","流程测试","触发娱乐设施干扰"]
]
static func cat_position(model) -> Vector2:
 for y in [480,610,370,700]:
  for x in [220,400,580,760,940,1120,1260]:
   var at:=Vector2(x,y)
   if model.cats.any(func(c):return c.pos.distance_to(at)<80):continue
   if model.facilities.any(func(f):return f.pos.distance_to(at)<120):continue
   return model.clamp_position(at)
 # Dense rooms still allow short soft overlaps; do not add a cat-count limit.
 return model.clamp_position(Vector2(720,540))
static func unlock(model,key: String) -> bool:
 if not D.RESEARCH.has(key) or model.has(key):return true
 for pre in D.RESEARCH[key].pre:
  if not unlock(model,pre):return false
 model.wallet+=float(D.RESEARCH[key].price)
 return model.research(key)
static func execute(model,key: String) -> String:
 if key in CAT_KINDS:
  var cat: Dictionary=model.add_cat(cat_position(model))
  cat.kind=key;cat.reaction_kind=key
  return "已生成"+D.title(key)+" #"+str(cat.id)+"（开发测试）"
 if key=="bugs":
  for f in model.facilities:
   if f.kind=="feeder":
    f.bugs=maxi(f.bugs,1);f.hits=0
    return "已在喂食器注入虫害；关闭菜单后点击设备清理"
  return "请先生成一台喂食器"
 if key=="interference":
  for f in model.facilities:
   if f.kind=="arcade" and not f.broken:
    f.broken=true;f.hits=0
    return "已触发一台娱乐设施黑屏；关闭菜单后手动修复"
  return "需要一台尚未黑屏的娱乐设施"
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
 if model.round_no<D.gate(key):return "请先使用菜单中的补齐首批收藏"
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
