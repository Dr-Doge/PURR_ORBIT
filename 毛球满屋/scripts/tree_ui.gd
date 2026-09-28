extends RefCounted
static func show_tree(g,subject: String) -> void:
 var selected: String=g.Model.T.SUBJECTS.get(subject,subject)
 if not g.model.tree.has(selected):selected="S00"
 g.tree_selected=selected
 var content=g.screen("成长树 · 毛球研发","拖动平移、滚轮缩放。性能卡显示下一等级，逐段开放；所有设施与流派同图、只花毛球。","tree")
 var jumps:=HFlowContainer.new();content.add_child(jumps)
 for id in ["N10","N20","N30","N40","N50","A1T","B1T","C1T","S10"]:
  g.button(g.model.tree[id].title,func():detail(g,id);focus(g,id),jumps)
 var layout=g.row(content);layout.custom_minimum_size.y=350
 g.graph=GraphEdit.new();g.graph.custom_minimum_size=Vector2(700,350);g.graph.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 g.graph.minimap_enabled=false;g.graph.show_arrange_button=false;g.graph.show_grid_buttons=false;g.graph.show_minimap_button=false;g.graph.show_grid=false
 g.graph.add_theme_stylebox_override("panel",g.style("e5e9df"));layout.add_child(g.graph)
 var scroll:=ScrollContainer.new();scroll.custom_minimum_size.x=300;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;layout.add_child(scroll)
 g.detail=g.column(scroll);g.detail.custom_minimum_size.x=285
 var visible: Dictionary={}
 for id in g.model.tree:
  var spec: Dictionary=g.model.tree[id]
  if spec.kind=="upgrade":
   var maximum: int=g.D.BRANCHES[spec.subject][spec.branch][2]
   if spec.level!=mini(g.model.lv(spec.subject,spec.branch)+1,maximum):continue
  visible[id]=true
 for id in visible:
  var spec: Dictionary=g.model.tree[id];var node:=GraphNode.new();node.name=id;node.title=id+" · "+spec.title;node.position_offset=spec.pos;node.custom_minimum_size.x=245
  if spec.kind=="upgrade":
   var index: int=g.D.BRANCHES[spec.subject].keys().find(spec.branch)
   node.position_offset=g.model.tree[g.Model.T.SUBJECTS[spec.subject]].pos+Vector2(290+(index%3)*270,-170-(index/3)*155)
  node.add_theme_stylebox_override("panel",g.style("f5f2e8"));node.add_theme_stylebox_override("titlebar",g.style("c8d7c1"));node.add_theme_color_override("title_color",Color("334b49"))
  g.graph.add_child(node)
  var owned: bool=g.model.node_owned(id);var ready: bool=g.model.node_reason(id)==""
  g.button("已获得" if owned else ("%d 毛球" % spec.price if ready else "查看前置"),func():detail(g,id),node)
  node.set_slot(0,true,0,Color("95c9bd"),true,0,Color("95c9bd"))
 for id in visible:
  var spec: Dictionary=g.model.tree[id]
  if spec.kind=="upgrade":g.graph.connect_node(g.Model.T.SUBJECTS[spec.subject],0,id,0)
  else:
   for pre in spec.all+spec.any:
    if visible.has(pre):g.graph.connect_node(pre,0,id,0)
 detail(g,selected);focus(g,selected)
static func focus(g,id: String) -> void:
 var graph: GraphEdit=g.graph
 await g.get_tree().process_frame
 if is_instance_valid(graph) and graph==g.graph:
  var node: Node=graph.get_node_or_null(NodePath(id))
  if node==null and g.model.tree[id].kind=="upgrade":
   for child in graph.get_children():
    if child is GraphNode and str(child.name).begins_with(id.split("-L")[0]+"-L"):node=child;break
  if node!=null:graph.scroll_offset=node.position_offset-Vector2(100,160)
static func detail(g,id: String) -> void:
 id=g.Model.T.SUBJECTS.get(id,id)
 if not g.model.tree.has(id):return
 g.clear(g.detail);g.tree_selected=id
 var spec: Dictionary=g.model.tree[id]
 g.paragraph(spec.title,g.detail,21)
 g.paragraph(spec.desc,g.detail,15)
 var cash=g.label("");g.detail.add_child(cash);g.live(cash,func():return "毛球："+g.format_money(g.model.wallet))
 var rule: PackedStringArray=[]
 for pre in spec.all:rule.append(g.model.tree[pre].title)
 if not rule.is_empty():g.paragraph("全部需要："+"、".join(rule),g.detail,14)
 rule=[]
 for pre in spec.any:rule.append(g.model.tree[pre].title)
 if not rule.is_empty():g.paragraph("任一即可："+" / ".join(rule),g.detail,14)
 var b=g.button("",func():g.transact(func():return g.model.buy_node(id));show_tree(g,id),g.detail)
 g.bind_button(b,func():return "已获得" if g.model.node_owned(id) else "购买 · %d 毛球" % spec.price,func():return g.model.node_reason(id)!="" or g.model.wallet<spec.price)
 g.paragraph(g.model.Build.summary(g.model),g.detail,14)
