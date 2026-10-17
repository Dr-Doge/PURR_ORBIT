extends SceneTree
## Deterministic recut requested by the user. Preserve each crop's canvas and
## primary silhouette; remove neighbouring sprites and disconnected noise.
const ROOT = "res://Art/grooming_fur_v1/"
const OUT = ROOT + "isolated_patches/"
const REPORT = "res://reports/fur_asset_cleanup_20261017/"
const CORE_ALPHA = 32.0 / 255.0
var sheets: Dictionary = {}

func _initialize() -> void:call_deferred("run")

static func isolate(raw: Image) -> Dictionary:
 var width: int = raw.get_width();var height: int = raw.get_height()
 var active = PackedByteArray();active.resize(width * height)
 for y in range(height):
  for x in range(width):active[y * width + x] = int(raw.get_pixel(x,y).a > CORE_ALPHA)
 var largest = PackedInt32Array()
 var sizes: Array = []
 for i in range(active.size()):
  if active[i] == 0:continue
  var component = PackedInt32Array([i]);active[i] = 0
  var cursor = 0
  while cursor < component.size():
   var at: int = component[cursor];cursor += 1
   var x: int = at % width;var y: int = at / width
   for dy in range(-1,2):
    for dx in range(-1,2):
     if dx == 0 and dy == 0:continue
     var nx: int = x + dx;var ny: int = y + dy
     if nx < 0 or nx >= width or ny < 0 or ny >= height:continue
     var next: int = ny * width + nx
     if active[next]:active[next] = 0;component.append(next)
  sizes.append(component.size())
  if component.size() > largest.size():largest = component
 var keep = PackedByteArray();keep.resize(width * height)
 for i in largest:keep[i] = 1
 # Retain the existing one-pixel low-alpha antialiased fringe; do not dilate
 # opaque alpha or accidentally admit another independently opaque fragment.
 for i in largest:
  var x: int = i % width;var y: int = i / width
  for dy in range(-1,2):
   for dx in range(-1,2):
    var nx: int = x + dx;var ny: int = y + dy
    if nx < 0 or nx >= width or ny < 0 or ny >= height:continue
    var alpha: float = raw.get_pixel(nx,ny).a
    if alpha > 0 and alpha <= CORE_ALPHA:keep[ny * width + nx] = 1
 var cleaned: Image = raw.duplicate()
 var removed_visible = 0;var removed_any = 0
 for i in range(keep.size()):
  if keep[i]:continue
  var x: int = i % width;var y: int = i / width
  var alpha: float = raw.get_pixel(x,y).a
  removed_visible += int(alpha > CORE_ALPHA);removed_any += int(alpha > 0)
  cleaned.set_pixel(x,y,Color(0,0,0,0))
 sizes.sort();sizes.reverse()
 return {"image":cleaned,"core_pixels":largest.size(),"removed_visible":removed_visible,"removed_any":removed_any,"original_components":sizes}

func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 DirAccess.make_dir_recursive_absolute(REPORT)
 var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "atlas_index.json"))
 var entries: Dictionary = {}
 for key in index.sprites:
  var e: Dictionary = index.sprites[key]
  if e.role not in ["body_patch","contour_overlay"]:continue
  if not sheets.has(e.file):
   var original: Image = load(ROOT + e.file).get_image()
   if original.is_compressed():original.decompress()
   sheets[e.file] = original
  var r: Array = e.region
  var raw: Image = sheets[e.file].get_region(Rect2i(r[0],r[1],r[2],r[3]))
  var cut: Dictionary = isolate(raw)
  if cut.core_pixels < 1000:push_error("No primary fur silhouette: " + key);quit(1);return
  var texture: ImageTexture = ImageTexture.create_from_image(cut.image)
  var path: String = OUT + key + ".res"
  if ResourceSaver.save(texture,path) != OK:push_error("Cannot save " + path);quit(1);return
  var resource_text: String = '[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n[ext_resource type="Texture2D" path="'+path+'" id="1"]\n\n[resource]\natlas = ExtResource("1")\nregion = Rect2(0, 0, '+str(r[2])+', '+str(r[3])+')\nfilter_clip = true\n'
  FileAccess.open(ROOT + e.resource,FileAccess.WRITE).store_string(resource_text)
  entries[key] = {"original_file":e.file,"original_region":r,"canvas":[raw.get_width(),raw.get_height()],"resource":e.resource,"isolated_texture":path,"core_pixels":cut.core_pixels,"removed_visible":cut.removed_visible,"removed_any":cut.removed_any,"original_components":cut.original_components}
 var hashes = {}
 for file in sheets:hashes[file] = FileAccess.get_sha256(ROOT + file)
 var result = {"method":"largest 8-connected alpha core plus one-pixel existing soft fringe","core_alpha":32,"canvas_preserved":true,"source_sha256":hashes,"sprites":entries}
 FileAccess.open(ROOT + "isolated_patches.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
 FileAccess.open(REPORT + "asset_manifest.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
 var count = 0
 for key in entries:count += entries[key].removed_visible
 print("CLEAN_FUR_ASSETS ",entries.size()," same-size assets; removed stray opaque pixels ",count)
 quit()
