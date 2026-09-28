extends RefCounted
const D=preload("res://scripts/data.gd")
const B=preload("res://scripts/balance.gd")
const FRAGMENTS={
 "S00": {
  "title": "基础收割",
  "price": 0,
  "desc": "首次真实收割后显示三路线；不发研究点或额外奖励。"
 },
 "A1T": {
  "title": "薄毛专精 I",
  "price": 80,
  "desc": "恰好1层真实收割的毛球加成增加3个百分点。只购买主题入口，不会自动获得本段两个细化节点。"
 },
 "A1P": {
  "title": "薄毛专精·细化一 I",
  "price": 120,
  "desc": "同一恰好1层真实收割的毛球加成再增加2个百分点；与其他同主题节点相加。"
 },
 "A1Q": {
  "title": "薄毛专精·细化二 I",
  "price": 180,
  "desc": "同一恰好1层真实收割的毛球加成再增加2个百分点；本段最后一片，不开放下一段的全部数值。"
 },
 "A1M": {
  "title": "连收计数 I",
  "price": 240,
  "desc": "开放连收计数：全场每完成12次真实1层收割，第12次额外给该次基础毛球的25%，清空计数。人工和工人均可计入。"
 },
 "A1U": {
  "title": "短循环 I",
  "price": 320,
  "desc": "连收次数需求再减1；只影响真实1层收割，衍生收益不计数。"
 },
 "A1V": {
  "title": "额外毛团 I",
  "price": 450,
  "desc": "连收额外奖励再增加5个百分点，以本次基础毛球为基数。"
 },
 "A2T": {
  "title": "薄毛专精 II",
  "price": 900,
  "desc": "恰好1层真实收割的毛球加成增加3个百分点。只购买主题入口，不会自动获得本段两个细化节点。"
 },
 "A2P": {
  "title": "薄毛专精·细化一 II",
  "price": 1400,
  "desc": "同一恰好1层真实收割的毛球加成再增加2个百分点；与其他同主题节点相加。"
 },
 "A2Q": {
  "title": "薄毛专精·细化二 II",
  "price": 2100,
  "desc": "同一恰好1层真实收割的毛球加成再增加2个百分点；本段最后一片，不开放下一段的全部数值。"
 },
 "A2M": {
  "title": "连收计数 II",
  "price": 3000,
  "desc": "在已解锁连收基础上，触发次数需求减1，奖励增加10个百分点；不重置并立刻结算旧进度。"
 },
 "A2U": {
  "title": "短循环 II",
  "price": 4200,
  "desc": "连收次数需求再减1；只影响真实1层收割，衍生收益不计数。"
 },
 "A2V": {
  "title": "额外毛团 II",
  "price": 6000,
  "desc": "连收额外奖励再增加5个百分点，以本次基础毛球为基数。"
 },
 "A3T": {
  "title": "薄毛专精 III",
  "price": 9000,
  "desc": "恰好1层真实收割的毛球加成增加5个百分点。只购买主题入口，不会自动获得本段两个细化节点。"
 },
 "A3P": {
  "title": "薄毛专精·细化一 III",
  "price": 14000,
  "desc": "同一恰好1层真实收割的毛球加成再增加3个百分点；与其他同主题节点相加。"
 },
 "A3Q": {
  "title": "薄毛专精·细化二 III",
  "price": 21000,
  "desc": "同一恰好1层真实收割的毛球加成再增加3个百分点；本段最后一片，不开放下一段的全部数值。"
 },
 "A3M": {
  "title": "连收计数 III",
  "price": 30000,
  "desc": "再次把连收次数需求减1，奖励增加15个百分点；不赠送未买的连收旁支。"
 },
 "A3U": {
  "title": "短循环 III",
  "price": 42000,
  "desc": "连收次数需求再减1；只影响真实1层收割，衍生收益不计数。"
 },
 "A3V": {
  "title": "额外毛团 III",
  "price": 60000,
  "desc": "连收额外奖励再增加5个百分点，以本次基础毛球为基数。"
 },
 "B1T": {
  "title": "厚毛专精 I",
  "price": 80,
  "desc": "4层及以上真实收割的毛球加成增加3个百分点。只购买主题入口，不会自动获得本段两个细化节点。"
 },
 "B1P": {
  "title": "厚毛专精·细化一 I",
  "price": 120,
  "desc": "同一4层及以上真实收割的毛球加成再增加2个百分点；与其他同主题节点相加。"
 },
 "B1Q": {
  "title": "厚毛专精·细化二 I",
  "price": 180,
  "desc": "同一4层及以上真实收割的毛球加成再增加2个百分点；本段最后一片，不开放下一段的全部数值。"
 },
 "B1M": {
  "title": "蓄养格 I",
  "price": 240,
  "desc": "开放蓄养格：猫在有食物buff时自然长出新层，存入1格，初始容量1；4层以上真实收割时，每格额外给本次基础毛球3%，随后清空。"
 },
 "B1U": {
  "title": "扩容一格 I",
  "price": 320,
  "desc": "蓄养容量再增加1格，不立即填充；原已有格数保留。"
 },
 "B1V": {
  "title": "浓缩蓄养 I",
  "price": 450,
  "desc": "每格结算比例增加1个百分点，全部格使用当前比例。"
 },
 "B2T": {
  "title": "厚毛专精 II",
  "price": 900,
  "desc": "4层及以上真实收割的毛球加成增加3个百分点。只购买主题入口，不会自动获得本段两个细化节点。"
 },
 "B2P": {
  "title": "厚毛专精·细化一 II",
  "price": 1400,
  "desc": "同一4层及以上真实收割的毛球加成再增加2个百分点；与其他同主题节点相加。"
 },
 "B2Q": {
  "title": "厚毛专精·细化二 II",
  "price": 2100,
  "desc": "同一4层及以上真实收割的毛球加成再增加2个百分点；本段最后一片，不开放下一段的全部数值。"
 },
 "B2M": {
  "title": "蓄养格 II",
  "price": 3000,
  "desc": "蓄养容量再增加1格；同时开放日光充能：有食物buff的猫在日光浴实际新增毛层时，每个新层也可充1格；同一层不重复充，单纯进出不充。"
 },
 "B2U": {
  "title": "扩容一格 II",
  "price": 4200,
  "desc": "蓄养容量再增加1格，不立即填充；原已有格数保留。"
 },
 "B2V": {
  "title": "浓缩蓄养 II",
  "price": 6000,
  "desc": "每格结算比例增加1个百分点，全部格使用当前比例。"
 },
 "B3T": {
  "title": "厚毛专精 III",
  "price": 9000,
  "desc": "4层及以上真实收割的毛球加成增加5个百分点。只购买主题入口，不会自动获得本段两个细化节点。"
 },
 "B3P": {
  "title": "厚毛专精·细化一 III",
  "price": 14000,
  "desc": "同一4层及以上真实收割的毛球加成再增加3个百分点；与其他同主题节点相加。"
 },
 "B3Q": {
  "title": "厚毛专精·细化二 III",
  "price": 21000,
  "desc": "同一4层及以上真实收割的毛球加成再增加3个百分点；本段最后一片，不开放下一段的全部数值。"
 },
 "B3M": {
  "title": "蓄养格 III",
  "price": 30000,
  "desc": "蓄养容量再增加1格；保持真实进食期间自然长层的充能规则。"
 },
 "B3U": {
  "title": "扩容一格 III",
  "price": 42000,
  "desc": "蓄养容量再增加1格，不立即填充；原已有格数保留。"
 },
 "B3V": {
  "title": "浓缩蓄养 III",
  "price": 60000,
  "desc": "每格结算比例增加1个百分点，全部格使用当前比例。"
 },
 "C1T": {
  "title": "道具估价 I",
  "price": 80,
  "desc": "普通道具正常出售价格加成增加3个百分点。只购买主题入口，不会自动获得本段两个细化节点。"
 },
 "C1P": {
  "title": "道具估价·细化一 I",
  "price": 120,
  "desc": "同一普通道具正常出售价格加成再增加2个百分点；与其他同主题节点相加。"
 },
 "C1Q": {
  "title": "道具估价·细化二 I",
  "price": 180,
  "desc": "同一普通道具正常出售价格加成再增加2个百分点；本段最后一片，不开放下一段的全部数值。"
 },
 "C1M": {
  "title": "订单交换 I",
  "price": 240,
  "desc": "开放同款订单：消耗2件同名普通道具，获得其正常售价总和的1.05倍；开放1条库存预留清单。"
 },
 "C1U": {
  "title": "预留清单 I",
  "price": 320,
  "desc": "库存预留清单数量增加1条；不同清单不能占用同一件实物。"
 },
 "C1V": {
  "title": "议价练习 I",
  "price": 450,
  "desc": "所有已解锁订单的交易系数增加0.02；只选一种订单出口，不将系数连乘。"
 },
 "C2T": {
  "title": "道具估价 II",
  "price": 900,
  "desc": "普通道具正常出售价格加成增加3个百分点。只购买主题入口，不会自动获得本段两个细化节点。"
 },
 "C2P": {
  "title": "道具估价·细化一 II",
  "price": 1400,
  "desc": "同一普通道具正常出售价格加成再增加2个百分点；与其他同主题节点相加。"
 },
 "C2Q": {
  "title": "道具估价·细化二 II",
  "price": 2100,
  "desc": "同一普通道具正常出售价格加成再增加2个百分点；本段最后一片，不开放下一段的全部数值。"
 },
 "C2M": {
  "title": "订单交换 II",
  "price": 3000,
  "desc": "开放三件套订单：消耗3件不同名普通道具，获得正常售价总和的1.08倍；原同款订单仍可用。"
 },
 "C2U": {
  "title": "预留清单 II",
  "price": 4200,
  "desc": "库存预留清单数量增加1条；不同清单不能占用同一件实物。"
 },
 "C2V": {
  "title": "议价练习 II",
  "price": 6000,
  "desc": "所有已解锁订单的交易系数增加0.02；只选一种订单出口，不将系数连乘。"
 },
 "C3T": {
  "title": "道具估价 III",
  "price": 9000,
  "desc": "普通道具正常出售价格加成增加5个百分点。只购买主题入口，不会自动获得本段两个细化节点。"
 },
 "C3P": {
  "title": "道具估价·细化一 III",
  "price": 14000,
  "desc": "同一普通道具正常出售价格加成再增加3个百分点；与其他同主题节点相加。"
 },
 "C3Q": {
  "title": "道具估价·细化二 III",
  "price": 21000,
  "desc": "同一普通道具正常出售价格加成再增加3个百分点；本段最后一片，不开放下一段的全部数值。"
 },
 "C3M": {
  "title": "订单交换 III",
  "price": 30000,
  "desc": "开放五件套订单：消耗5件不同名普通道具，获得正常售价总和的1.12倍；当前五种普通道具均可直接产出，不要求稀有转化。"
 },
 "C3U": {
  "title": "预留清单 III",
  "price": 42000,
  "desc": "库存预留清单数量增加1条；不同清单不能占用同一件实物。"
 },
 "C3V": {
  "title": "议价练习 III",
  "price": 60000,
  "desc": "所有已解锁订单的交易系数增加0.02；只选一种订单出口，不将系数连乘。"
 },
 "S10": {
  "title": "分组照料",
  "price": 1500,
  "desc": "开放2个猫群标签，工人按组工作；目标层在已付费解锁的层数范围内设置。任一路机制入口买到即可继续，不要求数值碎片满。"
 },
 "S20": {
  "title": "流程复盘",
  "price": 22000,
  "desc": "增加第3个猫群标签，并允许给各组记录目标层／娱乐轮次预设；同时开放第三研发段。手动操作和工人仍执行实际任务。"
 },
 "XAB": {
  "title": "快慢接力",
  "price": 8500,
  "desc": "真实单层收割累计8次生成1枚标记（最多1）；下次4层以上真实收割消耗标记，增加该次基础毛球5%。"
 },
 "XAC": {
  "title": "散货助销",
  "price": 8500,
  "desc": "真实单层收割累计20次生成1张券（最多1）；下次出售一件普通道具，额外获得该件正常售价5%。"
 },
 "XBC": {
  "title": "满载开场",
  "price": 8500,
  "desc": "4层以上猫进入娱乐可选消耗超过首层的毛层，换min(消耗层数,3)轮基础奖品价值+5%；离场清除剩余轮次，消耗毛层及蓄养格不另兑毛球。"
 }
}
const SUBJECTS={"worker":"N10","feeder":"N20","sun":"N30","hats":"N11","arcade":"N40","altar":"N50","maint":"N12"}
const THEMES={"worker:efficiency":"U11","worker:harvest_layers":"U12","worker:cooldown":"U13","feeder:food":"U21","feeder:transform":"U22","feeder:capacity":"U23","sun:time":"U31","sun:transform":"U33","arcade:win":"U41","arcade:time":"U42","arcade:value":"U43","arcade:transform":"U44","altar:speed":"H52","altar:transform":"H53"}
static func level_segment(subject: String,key: String,level: int) -> int:
 if subject=="worker":
  var first: int=3 if key=="harvest_layers" else 2
  return 1 if level<=first else (2 if level<=first+2 else 3)
 if key=="food":return level
 return 1 if level==1 else (2 if level==2 else 3)
static func nodes() -> Dictionary:
 var result: Dictionary={}
 for key in FRAGMENTS:
  var n: Dictionary=FRAGMENTS[key].duplicate(true)
  n.price=ceili(n.price*B.ECONOMY_COST_SCALE-0.000001);n.all=[];n.any=[];n.kind="build"
  n.pos=Vector2(1950,3200)
  if key.begins_with("A") or key.begins_with("B") or key.begins_with("C"):
   var route: String=key.substr(0,1);var segment: int=int(key.substr(1,1));var part: String=key.substr(2,1)
   var stem: String=route+str(segment)
   if part=="T":
    n.all=["S00" if route=="A" else ("N20" if route=="B" else "N40")]
    if segment>1:n.all.append("S10" if segment==2 else "S20");n.all.append(route+str(segment-1)+"M")
    if route=="B" and segment==2:n.all.append("N30")
   else:n.all=[stem+({"P":"T","Q":"P","M":"T","U":"M","V":"M"}[part])]
   var base: float=1800+["A","B","C"].find(route)*860
   n.pos=Vector2(base+{"T":0,"P":280,"Q":560,"M":0,"U":280,"V":560}[part],2800-(segment-1)*800-{"T":0,"P":160,"Q":320,"M":320,"U":480,"V":640}[part])
  elif key=="S00":n.kind="root";n.pos=Vector2(1500,3150)
  elif key in ["S10","S20"]:
   n.all=["N11"];n.any=["A1M","B1M","C1M"] if key=="S10" else ["A2M","B2M","C2M"]
   n.pos=Vector2(1500,2100 if key=="S10" else 1300)
  else:
   var routes: String=key.substr(1);n.all=[routes[0]+"2M",routes[1]+"2M"]
   n.pos=Vector2(1800+["XAB","XAC","XBC"].find(key)*860,100)
  result[key]=n
 var index: int=0
 for subject in SUBJECTS:
  var id: String=SUBJECTS[subject];var pre: Array=[]
  for p in D.RESEARCH[subject].pre:pre.append(SUBJECTS[p])
  if pre.is_empty():pre=["S00"]
  result[id]={"title":D.title(subject),"price":ceili(D.RESEARCH[subject].price*B.ECONOMY_COST_SCALE-0.000001),"desc":D.RESEARCH[subject].desc,"kind":"research","subject":subject,"all":pre,"any":[],"pos":Vector2(0,2950-index*420)}
  index+=1
 var theme_index: int=0
 for theme in THEMES:
  var bits: PackedStringArray=theme.split(":");var subject: String=bits[0];var branch: String=bits[1];var spec: Array=D.BRANCHES[subject][branch]
  for level in range(1,int(spec[2])+1):
   var id: String=THEMES[theme]+"-L"+str(level);var pre: Array=[SUBJECTS[subject]] if level==1 else [THEMES[theme]+"-L"+str(level-1)]
   var segment: int=level_segment(subject,branch,level)
   if segment>1:pre.append("S10" if segment==2 else "S20")
   result[id]={"title":spec[0]+" · "+str(level),"price":ceili(ceili(spec[1]*pow(B.BRANCH_GROWTH,level-1))*B.ECONOMY_COST_SCALE-0.000001),"desc":D.branch_effect(subject,branch,level-1)+" → "+D.branch_effect(subject,branch,level),"kind":"upgrade","subject":subject,"branch":branch,"level":level,"all":pre,"any":[],"pos":Vector2(280+(theme_index%5)*280,2950-(theme_index/5)*1250-(level-1)*155)}
  theme_index+=1
 return result
