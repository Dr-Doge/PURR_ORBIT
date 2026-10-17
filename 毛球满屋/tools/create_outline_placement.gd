extends SceneTree
## One-time snapshot, not an editor auto-generator. Refuse to overwrite artists.
const Model = preload("res://scripts/prototype_grooming_fur/model.gd")
const Piece = preload("res://scripts/prototype_grooming_fur/editor_outline_piece.gd")
const ShaderSource = preload("res://scripts/prototype_grooming_fur/coat_cleaning.gdshader")
const DEST = "res://scenes/prototype_grooming/轮廓毛发摆放.tscn"
const RES_DIR = "res://Art/grooming_fur_v1/editor_placement/"
var author_root: Node2D
var coat: Texture2D
var white: Texture2D
var index: Dictionary
var summary: Dictionary = {}

func _initialize() -> void:
 if FileAccess.file_exists(DEST):
  push_error("Existing placement scene preserved. Edit it in Godot; do not regenerate.")
  quit(2);return
 call_deferred("generate")

func add(parent: Node, child: Node, title: String, locked: bool = false) -> Node:
 child.name = title;parent.add_child(child);child.owner = author_root
 if locked:child.set_meta("_edit_lock_", true)
 return child

func image_sprite(parent: Node, title: String, tex: Texture2D, rect: Rect2) -> Sprite2D:
 var s: Sprite2D = add(parent, Sprite2D.new(), title, true)
 s.texture = tex;s.position = rect.get_center();s.scale = rect.size / Vector2(tex.get_size())
 return s

func caption(parent: Node, title: String, text: String, at: Vector2, font_size: int = 28) -> void:
 var l: Label = add(parent, Label.new(), title, true)
 l.text = text;l.position = at;l.add_theme_font_size_override("font_size", font_size)
 l.mouse_filter = Control.MOUSE_FILTER_IGNORE

func material_for(obj: Dictionary, box: Rect2, texture: Texture2D) -> ShaderMaterial:
 var m = ShaderMaterial.new();m.shader = ShaderSource
 var uv: Vector2 = (obj.rect.position - box.position) / box.size
 var size: Vector2 = obj.rect.size / box.size
 for key in ["remaining_mask", "body_mask"]:m.set_shader_parameter(key, white)
 m.set_shader_parameter("coat_map", coat)
 m.set_shader_parameter("body_dimensions", box.size)
 m.set_shader_parameter("region_in_body", Vector4(uv.x, uv.y, size.x, size.y))
 m.set_shader_parameter("patch_angle", obj.draw_angle)
 m.set_shader_parameter("patch_dimensions", obj.rect.size)
 m.set_shader_parameter("source_dimensions", Vector2(texture.get_size()))
 m.set_shader_parameter("match_coat", true)
 m.set_shader_parameter("complete_sprite", true)
 m.set_shader_parameter("preserve_outline", obj.rule == "edge")
 return m

func generate() -> void:
 var model = Model.new()
 DirAccess.make_dir_recursive_absolute(RES_DIR)
 coat = model.assets.coat_reference()
 var raw = Image.create(2, 2, false, Image.FORMAT_RGBA8);raw.fill(Color.WHITE)
 white = ImageTexture.create_from_image(raw)
 if ResourceSaver.save(coat, RES_DIR + "coat_reference.res") != OK or ResourceSaver.save(white, RES_DIR + "white.res") != OK:
  push_error("Cannot persist preview textures");quit(3);return
 coat = load(RES_DIR + "coat_reference.res");white = load(RES_DIR + "white.res")
 index = model.assets.fur_index
 author_root = Node2D.new();author_root.name = "轮廓毛发手工摆放"
 author_root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
 author_root.set_meta("placement_schema", 1)
 author_root.set_meta("runtime_applied", false)
 author_root.set_meta("snapshot_task", "IMP-20261017-006")
 author_root.set_meta("authoring_note", "编辑后Ctrl+S；不要重新运行生成脚本。可玩Demo暂不读取此场景。")
 create_cat(model, "大猫摆放区", 1.0, Vector2.ZERO)
 create_cat(model, "小猫摆放区", .5, Vector2(2240, 0))
 var palette: Node2D = add(author_root, Node2D.new(), "轮廓素材区_仅供复制")
 palette.position = Vector2(0, 1260);palette.set_meta("placement_role", "palette")
 caption(palette, "素材说明", "复制毛条 → 放入目标猫的 可编辑轮廓 / 胸前、躯干或尾部 → 修改位置、旋转与缩放", Vector2(0, -75), 32)
 var n = 0
 for key in index.sprites:
  if not str(key).begins_with("edge_"):continue
  var p = Sprite2D.new();p.set_script(Piece)
  p.asset_key = key;p.preview_coat = coat;p.preview_white = white
  # Once reparented, ../../.. points at the target cat; preview uses its own
  # body_rect metadata. Duplicating a cat piece also retains an appropriate size.
  p.reference_body_rect = model.assets.body_rect("calico")
  p.texture = load("res://Art/grooming_fur_v1/" + index.sprites[key].resource)
  p.position = Vector2(200 + (n % 4) * 510, 160 + (n / 4) * 380)
  p.scale = Vector2.ONE * minf(300.0 / p.texture.get_width(), 200.0 / p.texture.get_height())
  p.set_meta("placement_role", "template")
  add(palette, p, str(key))
  caption(palette, "名称_%d" % n, str(key), p.position + Vector2(-180, 140), 25)
  n += 1
 var packed = PackedScene.new()
 if packed.pack(author_root) != OK or ResourceSaver.save(packed, DEST) != OK:
  push_error("Cannot save authoring scene");quit(4);return
 var file = FileAccess.open(RES_DIR + "snapshot.json", FileAccess.WRITE)
 file.store_string(JSON.stringify(summary, "  "))
 print("EDITOR_PLACEMENT_CREATED ", JSON.stringify(summary))
 author_root.free();quit()

func create_cat(model: RefCounted, title: String, size: float, offset: Vector2) -> void:
 model.next_cat_scale = size;model.start_order(0)
 var area: Node2D = add(author_root, Node2D.new(), title)
 area.position = offset;area.set_meta("cat_scale", size)
 area.set_meta("body_rect", model.body_rect)
 area.set_meta("placement_role", "cat_layout")
 caption(area, "编辑说明", title + "：底层锁定；轮廓逐片编辑。坐标为1920×1080逻辑画布。", Vector2(0, -65), 32)
 var reference: Node2D = add(area, Node2D.new(), "参考底层_请勿移动", true)
 reference.set_meta("placement_role", "reference")
 image_sprite(reference, "房间", model.assets.presentation.room_texture, Rect2(0, 0, 1920, 1080))
 image_sprite(reference, "操作台", model.assets.presentation.table_texture, model.assets.presentation.table_rect)
 image_sprite(reference, "整洁猫底图", model.assets.presentation.cat_texture, model.body_rect)
 var body: Node2D = add(reference, Node2D.new(), "当前身躯毛片_锁定", true)
 var editable: Node2D = add(area, Node2D.new(), "可编辑轮廓")
 editable.set_meta("placement_role", "editable_outline")
 var groups = {}
 for r in ["chest", "body", "tail"]:
  groups[r] = add(editable, Node2D.new(), {"chest":"胸前", "body":"躯干", "tail":"尾部"}[r])
  groups[r].set_meta("service_region", r)
 var bodies = 0;var edges = 0
 for obj in model.objects:
  var s = Sprite2D.new()
  s.texture = load("res://Art/grooming_fur_v1/" + index.sprites[obj.type].resource)
  s.position = obj.rect.get_center();s.rotation = obj.draw_angle
  s.scale = obj.rect.size / Vector2(s.texture.get_size())
  s.set_meta("asset_key", obj.type);s.set_meta("source_id", obj.id)
  s.set_meta("service_region", obj.region)
  if obj.rule == "edge":
   s.set_script(Piece);s.asset_key = obj.type;s.service_region = obj.region
   s.reference_body_rect = model.body_rect;s.preview_coat = coat;s.preview_white = white
   s.set_meta("placement_role", "outline")
   add(groups[obj.region], s, "毛条_%03d_%s" % [obj.id, obj.type])
   # Persist a valid initial preview even before the editor's first frame.
   s.material = material_for(obj, model.body_rect, s.texture)
   edges += 1
  else:
   s.material = material_for(obj, model.body_rect, s.texture)
   add(body, s, "毛片_%03d" % obj.id, true);bodies += 1
 var guides: Node2D = add(area, Node2D.new(), "服务区与脚爪参考_按需显示", true)
 guides.visible = false;guides.z_index = 20
 var regions = {"胸前":model.service_chest, "躯干":model.service_body, "尾部":model.service_tail}
 var i = 0
 for name in regions:
  var line: Line2D = add(guides, Line2D.new(), name, true)
  for uv in regions[name]:line.add_point(model.body_rect.position + uv * model.body_rect.size)
  line.closed = true;line.width = 3
  line.default_color = [Color(.2,.6,1,.8), Color(1,.3,.2,.8), Color(.2,1,.4,.8)][i];i += 1
 for j in range(model.paw_exclusions.size()):
  var line: Line2D = add(guides, Line2D.new(), "脚爪禁区_%d" % j, true)
  for uv in model.paw_exclusions[j]:line.add_point(model.body_rect.position + uv * model.body_rect.size)
  line.closed = true;line.width = 3;line.default_color = Color(1,.1,.1,.8)
 summary[title] = {"body_count":bodies, "edge_count":edges, "cat_scale":size, "offset":[offset.x,offset.y], "body_rect":[model.body_rect.position.x,model.body_rect.position.y,model.body_rect.size.x,model.body_rect.size.y]}
