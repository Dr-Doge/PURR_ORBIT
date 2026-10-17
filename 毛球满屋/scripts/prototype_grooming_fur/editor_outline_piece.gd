@tool
extends Sprite2D
## Editor placement only. Never rebuild positions or start the grooming model.
## NodePath and texture.resource_path, not source_id, identify authored pieces.
@export var asset_key: String = ""
@export var service_region: String = "body"
@export var cat_frame: NodePath = NodePath("../../..")
@export var reference_body_rect: Rect2
@export var preview_coat: Texture2D
@export var preview_white: Texture2D
const CoatShader = preload("res://scripts/prototype_grooming_fur/coat_cleaning.gdshader")
var private_material: ShaderMaterial

func _ready() -> void:
 refresh_preview()

func _process(_delta: float) -> void:
 if Engine.is_editor_hint():refresh_preview()

func refresh_preview() -> void:
 var frame: Node2D = get_node_or_null(cat_frame) as Node2D
 if frame == null or texture == null or reference_body_rect.size.x <= 0:return
 # Palette templates show their original art. Duplicating one into a cat's
 # three-level Contours/Region hierarchy enables pigment matching automatically.
 if not frame.has_meta("cat_scale"):
  material = null
  return
 if private_material == null:
  private_material = ShaderMaterial.new()
  private_material.resource_local_to_scene = true
  private_material.shader = CoatShader
 if material != private_material:material = private_material
 var box: Rect2 = frame.get_meta("body_rect", reference_body_rect)
 var drawn: Vector2 = Vector2(texture.get_size()) * scale.abs()
 var center: Vector2 = frame.to_local(global_position)
 var angle: float = global_rotation - frame.global_rotation
 var uv: Vector2 = (center - drawn * .5 - box.position) / box.size
 var extent: Vector2 = drawn / box.size
 private_material.set_shader_parameter("remaining_mask", preview_white)
 private_material.set_shader_parameter("body_mask", preview_white)
 private_material.set_shader_parameter("coat_map", preview_coat)
 private_material.set_shader_parameter("body_dimensions", box.size)
 private_material.set_shader_parameter("region_in_body", Vector4(uv.x, uv.y, extent.x, extent.y))
 private_material.set_shader_parameter("patch_angle", angle)
 private_material.set_shader_parameter("patch_dimensions", drawn)
 private_material.set_shader_parameter("source_dimensions", Vector2(texture.get_size()))
 private_material.set_shader_parameter("match_coat", true)
 private_material.set_shader_parameter("preserve_outline", true)
 private_material.set_shader_parameter("complete_sprite", true)
 private_material.set_shader_parameter("loosen", 1.0)
