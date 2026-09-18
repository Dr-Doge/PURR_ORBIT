"""Rebuild the scene's exact button graph; never modifies the game archive."""
import json, hashlib, collections, html
from pathlib import Path

HERE = Path(__file__).resolve().parent
BASE = HERE.parent
DOCS = BASE.parent.parent
source = json.loads((BASE / 'sheets.source.json').read_text(encoding='utf-8'))['NODES']
scene = json.loads(next(HERE.glob('*.nodes.json')).read_text(encoding='utf-8'))
subjects = dict(SPOON='勺子', SHOVEL='铲子', PICKAXE='镐子', TRIDENT='三叉戟',
 MUSHROOM_GUY='蘑菇帮手', FROG_GUY='青蛙帮手', PASSIVE='全局被动', CURSOR='光标',
 INVENTORY='背包', SPELL_ZAPS='闪电法术', SPELL_GOLDRUSH='淘金法术', SPELL_RAIN='降雨法术',
 SLEDGEHAMMER='大锤', MOLE_GUY='鼹鼠帮手', GOLEM_GUY='魔像帮手', DRUID_STAFF='德鲁伊法杖',
 DRUID_GUY='德鲁伊帮手', GHOST_GUY='幽灵帮手', JACKHAMMER='风镐', DESCENT='深入系统',
 BUFF_DIRT_MULTIPLY='产量增益', BUFF_SPEED='速度增益')
stats = dict(DIRT_GAIN='产量', ANIMATION_SCALE='动作倍率', DIRT_GAIN_CRIT_CHANCE='暴击率',
 COUNT_ADD='数量扩容', SHOP_UNLOCK='解锁', IDLE_TIME='等待时间', STOMP_RAD='作用范围',
 LUCK_ITEM_DROP='物品掉率', LUCK_ITEM_RARITY='物品品质', RADIUS='光标范围',
 SELL_ITEMS_DIRT='物品售价', ZAP_CHANCE='放电率', ZAP_CRIT_CHANCE='放电暴击率',
 SPELL_STACKS='法术储备', SPELL_DIGS='法术挖掘量', SPELL_DURATION='法术持续时间',
 DIG_COUNT='挖掘次数', BUFF_TIME='增益持续时间', BUFF_VALUE='增益强度', DIRT_MULTIPLY='产量倍率')
nodes = []
for n in scene:
    p = n['properties']
    if 'key_node' not in p:
        continue
    subject, stat, index = p['key_node'], p['key_stat'], p.get('stat_id', 0)
    r = source[subject][stat][index]
    key = f'{subject}.{stat}.{index}'
    parent = f"{r.get('LOCK_BY_KEY_NODE')}.{r.get('LOCK_BY_KEY_STAT')}.{r.get('LOCK_BY_STAT_ID')}"
    if r.get('LOCK_BY_KEY_NODE', 'NULL') == 'NULL':
        parent = None
    nodes.append(dict(id=f'D{len(nodes)+1:03}', key=key, subject=subject, stat=stat,
        array_index=index, embedded_stat_id=r.get('STAT_ID'), scene_index=n['index'],
        scene_name=n['name'], label=f'{subjects[subject]}·{stats[stat]}[{index}]',
        x=p['offset_left']+32, y=p['offset_top']+32, width=64, height=64,
        parent_key=parent, required_level_raw=r.get('LOCK_BY_LEVEL'),
        levels=r.get('LEVELS'), level_start=r.get('LEVEL_START', 0),
        value_init=r.get('VALUE_INIT'), value_inc=r.get('VALUE_INC'),
        cost_base=r.get('DIRT_BASE'), cost_growth=r.get('DIRT_GROWTH'),
        demo_lock=bool(r.get('DEMO_LOCK', 0)), raw_config=r))
bykey={n['key']:n for n in nodes}
assert len(nodes)==131 and len(bykey)==131
for n in nodes:
    p=bykey.get(n['parent_key'])
    assert n['parent_key'] is None or p is not None, n
    n['parent']=p['id'] if p else None
    n['required_level']= (p['levels'] if n['required_level_raw']==0 else n['required_level_raw']) if p else None
    n['children']=[c['id'] for c in nodes if c['parent_key']==n['key']]
    path=[]; cur=n
    while cur:
        assert cur['id'] not in path, 'cycle'
        path.append(cur['id']); cur=bykey.get(cur['parent_key'])
    n['ancestor_path']=path[::-1]
    n['demo_blockers']=[v['id'] for v in nodes if v['demo_lock'] and v['id'] in path]
    n['status']='Demo直接锁' if n['demo_lock'] else ('受前置Demo锁阻挡' if n['demo_blockers'] else '无Demo锁阻挡')
byid={n['id']:n for n in nodes}
edges=[dict(source=n['parent'],target=n['id'],required_level=n['required_level'],raw=n['required_level_raw']) for n in nodes if n['parent']]
assert len(edges)==130
omitted=[]
for subject, body in source.items():
    for stat, arr in body.items():
        if not isinstance(arr,list): continue
        for i,r in enumerate(arr):
            key=f'{subject}.{stat}.{i}'
            if key not in bykey: omitted.append(dict(key=key,raw_config=r))
assert len(omitted)==37
counts=collections.Counter(n['status'] for n in nodes)
report=dict(scene_objects=len(scene),buttons=len(nodes),edges=len(edges),roots=[n['id'] for n in nodes if not n['parent']],
    statuses=dict(counts),max_level_edges=sum(e['raw']==0 for e in edges),
    config_records=168,not_instanced_records=len(omitted),all_parents_resolved=True,acyclic=True,
    pck_sha256=hashlib.sha256((DOCS/'Dirt Clicker Demo'/'Dirt Clicker Demo.pck').read_bytes()).hexdigest())
(HERE/'逐节点拓扑.json').write_text(json.dumps(dict(summary=report,nodes=nodes,edges=edges,not_instanced=omitted),ensure_ascii=False,indent=2),encoding='utf-8')
(HERE/'拓扑校验.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')

def ref(i): return f'[{i}](#{i.lower()})'
def req(n):
    if not n['parent']: return '起点，无树内前置'
    level=f"Lv.{n['required_level']}"
    if n['required_level_raw']==0: level+='（满级；原字段0）'
    return ref(n['parent'])+' '+level
def shortreq(n):
    return f"{n['required_level']}级" + ('/满级' if n['required_level_raw']==0 else '')

intro='''# dc升级树｜逐节点结构复刻

2026-09-15｜以用户提供的 **Dirt Clicker Demo 本地包**为准。这里复刻的是原版场景布局与连接，不是把猫咪内容强行串成一条线；不声称覆盖其他版本。中文名按内部键释义，方括号是从0开始的运行时分段索引，不是升级等级。

**阅读入口：**[原坐标总图（可缩放、点节点查看）](参考研究/DirtClicker/节点研究/dc-tree.html) · [完整原坐标SVG](参考研究/DirtClicker/节点研究/dc-tree.svg) · [机器可读节点与边](参考研究/DirtClicker/节点研究/逐节点拓扑.json)。下文D编号与总图一一对应，编号按场景按钮顺序稳定分配；实际推进方向从下往上，不按编号顺序购买。

## 1. 本次精确到什么程度

'''
intro+=f'''| 项目 | 核实结果 |
| --- | --- |
| 场景对象 / 真正升级按钮 | {len(scene)} / **131**；其余为容器、背景和辅助UI |
| 节点连线 | **130条**，唯一根节点D001；无环、无缺失前置，每个非根按钮有一个直接前置 |
| 原始属性记录 | 168条；其中37条没有实例化为这棵树的按钮，不能凑成168个技能 |
| Demo状态 | 直接锁{counts['Demo直接锁']}个；受祖先锁阻挡{counts['受前置Demo锁阻挡']}个；无此类锁阻挡{counts['无Demo锁阻挡']}个。后者仍需满足等级、费用等购买条件 |
| 满级连接 | {report['max_level_edges']}条前置字段为0，脚本将其解析成前置满级，并非“零级即可” |
| 坐标与连线 | 直接读取场景偏移坐标；连接由按钮脚本按配置前置生成，未靠截图猜线 |
| 核验边界 | 已静态解析场景和脚本令牌；未运行dc，也未验证正式版内容或所有效果的最终收益算法 |

**对上一版的纠正：**M00→M07单线方案撤销。“2—3条主干”是对这张图的空间阅读方式，并非引擎里有三个独立树对象。实际是一棵有共同起点、随后多次分叉的树；支路还能继续分叉，并非所有小节点都只是终点。

## 2. 如何从下往上读

共同起步是 **勺子产量[0] → 蘑菇帮手解锁 → 背包解锁**。背包先分出铲子方向、光标方向和勺子掉落支路；光标方向再分出左侧勺子扩容／青蛙方向、中央被动方向和蘑菇强化方向。因此视觉上形成左右两条长路线，中间附带被动成长路线。

| 阅读区域 | 实际延伸内容 | 结构特点 |
| --- | --- | --- |
| 左侧长路线 | 光标[0] → 勺子扩容[0] → 青蛙 → 镐子；青蛙另分德鲁伊帮手／降雨，镐子另分德鲁伊法杖／淘金 | 新对象解锁与旧对象后段强化交错，既有长线也有侧线 |
| 中央路线 | 光标[0] → 被动产量[0] → 产量／品质／售价簇；售价[0] → 深入系统 | 由性能节点继续引出系统节点，不是全程“购买新品” |
| 右侧长路线 | 背包 → 铲子 → 三叉戟 → 闪电法术 → 幽灵 → 风镐；另分大锤、鼹鼠／魔像及工具后段强化 | 同一解锁节点可同时开放多个方向；Demo锁不等于没有这个节点 |

下面仅压缩显示分叉骨架，完整旁支见第3、4节。实线均为实际直接连接；为简洁省略边上的等级，等级以逐节点表为准。

```mermaid
flowchart BT
'''
spinekeys=['SPOON.DIRT_GAIN.0','MUSHROOM_GUY.SHOP_UNLOCK.0','INVENTORY.SHOP_UNLOCK.0','CURSOR.RADIUS.0','SPOON.COUNT_ADD.0','FROG_GUY.SHOP_UNLOCK.0','PICKAXE.SHOP_UNLOCK.0','FROG_GUY.COUNT_ADD.0','PICKAXE.COUNT_ADD.0','DRUID_GUY.SHOP_UNLOCK.0','DRUID_STAFF.SHOP_UNLOCK.0','SPELL_RAIN.SHOP_UNLOCK.0','SPELL_GOLDRUSH.SHOP_UNLOCK.0','PASSIVE.DIRT_GAIN.0','PASSIVE.SELL_ITEMS_DIRT.0','DESCENT.SHOP_UNLOCK.0','SHOVEL.SHOP_UNLOCK.0','TRIDENT.SHOP_UNLOCK.0','SPELL_ZAPS.SHOP_UNLOCK.0','GHOST_GUY.SHOP_UNLOCK.0','JACKHAMMER.SHOP_UNLOCK.0','SLEDGEHAMMER.SHOP_UNLOCK.0','MOLE_GUY.SHOP_UNLOCK.0','GOLEM_GUY.SHOP_UNLOCK.0','MUSHROOM_GUY.COUNT_ADD.0','MUSHROOM_GUY.COUNT_ADD.1','SHOVEL.COUNT_ADD.0','TRIDENT.COUNT_ADD.0']
for k in spinekeys:
    n=bykey[k]; intro+=f'  {n["id"]}["{n["id"]} {n["label"]}"]\n'
for k in spinekeys:
    n=bykey[k]
    if n['parent_key'] in spinekeys: intro+=f'  {n["parent"]} --> {n["id"]}\n'
intro+='''```

## 3. 全树连接清单（131个节点，无省略）

缩进代表直接父子关系；括号是该连接要求的**父节点等级**，不是本节点价格或等级。按画布左右位置排列同父节点的孩子；阅读这份清单向右深入，对应画布沿连接推进。

```text
'''
def walk(n,prefix='',last=True,root=False):
    line=prefix+('' if root else ('└─ ' if last else '├─ '))+n['id']+' '+n['label']
    if not root: line+=' ←前置'+shortreq(n)
    if n['demo_lock']: line+=' 【Demo锁】'
    elif n['demo_blockers']: line+=' 【受Demo前置锁阻挡】'
    out=[line]
    children=sorted((byid[c] for c in n['children']),key=lambda v:(v['x'],-v['y']))
    for i,c in enumerate(children): out+=walk(c,prefix+('' if root else ('   ' if last else '│  ')),i==len(children)-1)
    return out
intro+='\n'.join(walk(bykey['SPOON.DIRT_GAIN.0'],root=True))+'\n```\n\n## 4. 每个节点的前置、等级和分支\n\n坐标是按钮中心的原场景偏移坐标，Y越小越靠上。每行的“后续”列列出全部直接子节点，不等于都必须购买。属性[0]、[1]等段数按运行时数组索引列出；没有按钮的记录不列入此表。\n\n'
groups=collections.defaultdict(list)
for n in nodes: groups[n['subject']].append(n)
for subject,items in groups.items():
    intro+=f'### {subjects[subject]}（{subject}，{len(items)}个节点）\n\n| 编号／节点 | 精确前置 | 初始→最高等级 | 直接后续节点 | 中心坐标X,Y | Demo状态 |\n| --- | --- | --- | --- | --- | --- |\n'
    for n in items:
        intro+=f'| <a id="{n["id"].lower()}"></a>**{n["id"]}** {stats[n["stat"]]}[{n["array_index"]}] | {req(n)} | {n["level_start"]}→{n["levels"]} | {", ".join(ref(c) for c in n["children"]) or "—"} | {n["x"]:g},{n["y"]:g} | {n["status"]} |\n'
    intro+='\n'
intro+='''## 5. 连接规则：原版事实与摸猫版要求分开

| 问题 | dc本包的实际规则 | 对摸猫版的处理 |
| --- | --- | --- |
| 每个小节点都是可选终点吗 | 不是。扩容、范围、掉率、售价等节点也可能继续解锁别的节点，详见后续列 | 用户确认的猫种／设施性能旁支不作为下一主体的硬门槛，不能偷偷继承这些锁 |
| 要先把上一物品全部升满吗 | 不需要全部升满；逐条连接只检查指定父属性及要求等级。一些局部连接要求指定属性满级 | 不把“指定父属性满级”误写成“整组满级”，也不把“并非整组满级”误写成“所有连接都是1级” |
| 多条主干怎么推进 | 同父节点可分出多路，各路继续发展，无需沿一根中央直线买完整棵树 | 取消旧M00→M07强制单线；猫版要保留多路可选推进的空间结构 |
| 重复属性能否合并 | 原树确实保留同属性多个分段按钮，各有自己的前置与费用 | 按此前要求，猫版可把后段等级归入原分支，腾出的节点簇布置逗猫棒、暖炉；这一步是有标记的改编，不再称为逐节点原样复刻 |
| 131个节点都照搬成猫内容吗 | 这里131个是原版证据数量，不是猫版内容量 | 猫版仍有50项规划分支；招财猫暂停分支、代币参数和手部形态仍按00的状态，不能为了填格子发明收费节点 |

下一步进行猫咪名称替换时，应保留本表D编号作为来源锚点，逐项标记“原位替换／后段合并／设施占位／暂留空”，同时另列猫版实际前置。原版图保持原样，才能检验改编究竟改变了哪些连接。当前猫版具体逐节点映射尚未定稿；本次没有修改Demo代码。

## 6. 证据、纠错与复核方式

- 场景：[147个场景对象的解析结果](参考研究/DirtClicker/节点研究/export-c7064a4a683f551e0fbc7c708e54eb07-ui_skill_tree.nodes.json)。按钮名称可能复用，身份按`key_node + key_stat + stat_id`绑定确定，不能按场景对象名字猜测。
- 连接／绘线：[按钮脚本令牌重建](参考研究/DirtClicker/节点研究/ui_btn_skill_tree.tokens.gd.txt)，查`_sheet_setup_lock`和`_line_pos_update`。这不是原作者源文件，原注释与排版未保留，不保证可直接编译。
- 前置等级／索引／价格：[数据控制器令牌重建](参考研究/DirtClicker/节点研究/data_controller.tokens.gd.txt)。`LOCK_BY_LEVEL=0`转换为前置`get_level_last()`；运行时ID取数组下标，而非记录内部的`STAT_ID`。因此三叉戟两条记录的重复内嵌ID，不能直接定性为重复按钮或运行时错误。
- 属性合并：[NodeData令牌重建](参考研究/DirtClicker/节点研究/NodeData.tokens.gd.txt)的`stat_value`对同类属性各段求和。负增量和后段初值0应放进总值解释；最终效果怎么使用该总值，仍需对应工作脚本才能下结论。
- 价格生成代码为`roundi(DIRT_BASE × DIRT_GROWTH^L)`，L是购买前当前等级。这里只核实基础费用序列；不把配置`ALL_COST`当真实累计投入，不直接复制到猫版经济。
- [未实例化的37条记录、逐节点原字段和校验结果](参考研究/DirtClicker/节点研究/逐节点拓扑.json)一并保留。无Demo锁阻挡不代表开局可购买，Demo锁后方节点也不是本Demo可玩的保证。
- 解析格式依据Godot官方的[二进制资源读取实现](https://github.com/godotengine/godot/blob/4.6/core/io/resource_format_binary.cpp)、[PackedScene实现](https://github.com/godotengine/godot/blob/4.6/scene/resources/packed_scene.cpp)与[GDScript令牌缓冲实现](https://github.com/godotengine/godot/blob/4.6/modules/gdscript/gdscript_tokenizer_buffer.cpp)。未修改或分发原游戏程序；文集内保存静态研究结果供核对。
'''
(DOCS/'08_dc升级树逐节点复刻.md').write_text(intro,encoding='utf-8')

# Preserve each node center and every edge; labels are research labels, not copied game UI.
x0=min(n['x'] for n in nodes)-100; y0=min(n['y'] for n in nodes)-100
w=max(n['x'] for n in nodes)-x0+100; h=max(n['y'] for n in nodes)-y0+100
svg=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{x0} {y0} {w} {h}" width="{w}" height="{h}" role="img" aria-label="dc升级树131节点原坐标复刻">',
 '<style>text{font-family:Microsoft YaHei,Arial,sans-serif;fill:#f4f2e9;text-anchor:middle} .node{cursor:pointer} .edge{stroke:#728999;stroke-width:4;fill:none}.node:focus rect,.node:hover rect{stroke:#fff;stroke-width:5}.selected rect{stroke:#fff;stroke-width:6}.hot{stroke:#ffcf68;stroke-width:8}</style>',
 f'<rect x="{x0}" y="{y0}" width="{w}" height="{h}" fill="#152633"/>']
for e in edges:
    a,b=byid[e['source']],byid[e['target']]
    svg.append(f'<path class="edge" data-from="{a["id"]}" data-to="{b["id"]}" d="M {a["x"]} {a["y"]} L {b["x"]} {b["y"]}"/>')
for n in nodes:
    color='#785047' if n['demo_lock'] else ('#334652' if n['demo_blockers'] else '#755c2c')
    title=f'{n["id"]} {n["label"]} | {n["key"]} | 前置 {n["parent"] or "无"} {n["required_level"] or ""}级 | {n["status"]}'
    svg.append(f'<g class="node" data-id="{n["id"]}" tabindex="0" role="button" aria-label="{html.escape(title)}"><title>{html.escape(title)}</title><rect x="{n["x"]-32}" y="{n["y"]-32}" width="64" height="64" rx="5" fill="{color}" stroke="#d4b970" stroke-width="2"/>')
    for offset,text,size in [(-17,n['id'],13),(0,subjects[n['subject']],9),(17,stats[n['stat']]+str(n['array_index']),9)]:
        svg.append(f'<text x="{n["x"]}" y="{n["y"]+offset}" font-size="{size}">{html.escape(text)}</text>')
    svg.append('</g>')
svg.append('</svg>'); svg='\n'.join(svg)
(HERE/'dc-tree.svg').write_text(svg,encoding='utf-8')
data=json.dumps(nodes,ensure_ascii=False).replace('</',r'<\/')
page='''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>dc｜131节点原坐标升级树</title>
<style>*{box-sizing:border-box}body{margin:0;font:15px/1.6 "Microsoft YaHei",sans-serif;color:#f4f2e9;background:#152633}header{padding:14px 22px;background:#203746;display:flex;align-items:center;gap:20px;flex-wrap:wrap}h1{font-size:20px;margin:0}main{display:grid;grid-template-columns:1fr 340px;height:calc(100vh - 80px)}#viewport{overflow:auto;position:relative}#viewport svg{display:block;max-width:none}aside{padding:22px;background:#203746;overflow:auto}select,input,button{font:inherit}button,select{background:#152633;color:#f4f2e9;border:1px solid #728999;padding:6px;border-radius:4px}label{white-space:nowrap}#details{overflow-wrap:anywhere}a{color:#ffcf68}small{color:#c1d0d9}#details button{margin:3px} @media(max-width:850px){main{grid-template-columns:1fr;height:auto}#viewport{height:65vh}aside{min-height:240px}}</style>
<header><h1>dc · 131个节点 / 130条连接</h1><label>缩放 <input id="zoom" type="range" min="10" max="200" value="125"><span id="zoomValue">125%</span></label><button id="start">回到起点</button><select id="jump" aria-label="定位节点"><option value="">定位节点…</option></select></header>
<main><div id="viewport">SVG_HERE</div><aside><h2>原场景位置复刻</h2><p>从下往上读；点击节点查看前置、全部后续与原始属性。</p><p><small>金色：无Demo锁阻挡<br>棕红：本节点Demo锁<br>灰蓝：受祖先Demo锁阻挡<br>颜色不代表已购买状态。</small></p><div id="details" aria-live="polite"></div><p><a href="../../../08_dc升级树逐节点复刻.md">完整逐节点文档</a> · <a href="逐节点拓扑.json">原始映射</a></p></aside></main>
<script>const nodes=DATA_HERE;const byId=Object.fromEntries(nodes.map(n=>[n.id,n]));const viewport=document.getElementById('viewport'),svg=viewport.querySelector('svg'),zoom=document.getElementById('zoom'),details=document.getElementById('details'),jump=document.getElementById('jump');let current='D001';
nodes.forEach(n=>{let o=document.createElement('option');o.value=n.id;o.textContent=n.id+' '+n.label;jump.append(o)});
function scale(){let z=Number(zoom.value)/100;svg.style.width=(WIDTH*z)+'px';svg.style.height=(HEIGHT*z)+'px';document.getElementById('zoomValue').textContent=zoom.value+'%'}
function center(id){const n=byId[id],z=Number(zoom.value)/100;viewport.scrollTo({left:(n.x-XMIN)*z-viewport.clientWidth/2,top:(n.y-YMIN)*z-viewport.clientHeight/2})}
function show(id,move=false){current=id;const n=byId[id];document.querySelectorAll('.node').forEach(e=>e.classList.toggle('selected',e.dataset.id===id));document.querySelectorAll('.edge').forEach(e=>e.classList.toggle('hot',e.dataset.from===id||e.dataset.to===id));details.replaceChildren();let h=document.createElement('h2');h.textContent=n.id+' '+n.label;details.append(h);for(let t of [n.key,'等级：'+n.level_start+' → '+n.levels,'状态：'+n.status,'前置：'+(n.parent? n.parent+' '+byId[n.parent].label+' 达到'+n.required_level+'级'+(n.required_level_raw===0?'（满级）':''):'无，树的起点'),'坐标：'+n.x+', '+n.y,'基础值：'+n.value_init+'；每级变化：'+n.value_inc,'基础价格：'+n.cost_base+'；增长系数：'+n.cost_growth]){let p=document.createElement('p');p.textContent=t;details.append(p)}if(n.parent){let b=document.createElement('button');b.textContent='定位前置 '+n.parent;b.onclick=()=>show(n.parent,true);details.append(b)}let p=document.createElement('p');p.textContent='直接后续（'+n.children.length+'）';details.append(p);n.children.forEach(id=>{let b=document.createElement('button');b.textContent=id+' '+byId[id].label;b.onclick=()=>show(id,true);details.append(b)});jump.value=id;if(move)center(id)}
svg.querySelectorAll('.node').forEach(e=>{e.addEventListener('click',()=>show(e.dataset.id));e.addEventListener('keydown',ev=>{if(ev.key==='Enter'||ev.key===' '){ev.preventDefault();show(e.dataset.id)}})});zoom.oninput=()=>{scale();center(current)};jump.onchange=()=>{if(jump.value)show(jump.value,true)};document.getElementById('start').onclick=()=>show('D001',true);scale();show('D001');requestAnimationFrame(()=>center('D001'));
</script></html>'''
page=page.replace('SVG_HERE',svg).replace('DATA_HERE',data).replace('WIDTH',str(w)).replace('HEIGHT',str(h)).replace('XMIN',str(x0)).replace('YMIN',str(y0))
(HERE/'dc-tree.html').write_text(page,encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))
