extends Control
## Isolated copy of the current 3D shell. No old Room/Model, workers or save hooks.
@onready var presentation: SubViewportContainer = $WhiteboxViewport
@onready var shell: Node3D = $WhiteboxViewport/World3D/WhiteboxRoom
@onready var camera: Camera3D = $WhiteboxViewport/World3D/WhiteboxRoom/Camera
var zoom_amount: float = 0.0
func _ready() -> void:
 mouse_filter=MOUSE_FILTER_IGNORE
 for mesh_name in ["Floor","BackWall","LeftWall","RightWall"]:
  var node: MeshInstance3D=shell.get_node(mesh_name)
  node.mesh=node.mesh.duplicate(true)
  if node.material_override:node.material_override=node.material_override.duplicate(true)
 resized.connect(resize_world);resize_world()
func resize_world() -> void:
 if not is_node_ready():return
 presentation.size=size
 camera.rotation=Vector3.ZERO
 camera.set_frustum(lerpf(0.06,0.054,zoom_amount),Vector2(0,-0.4056),1.0,200.0)
 var half_width: float=(camera.position.z-3.090909)*0.06*(size.x/maxf(1,size.y))*0.5
 shell.get_node("Floor").mesh.size=Vector2(half_width*2,10.008339)
 shell.get_node("Floor").material_override.set_shader_parameter("half_width",half_width)
 shell.get_node("BackWall").mesh.size=Vector2(half_width*2,6)
 shell.get_node("BackWall").material_override.set_shader_parameter("canvas_size",size)
 shell.get_node("LeftWall").position.x=-half_width
 shell.get_node("RightWall").position.x=half_width
 for part in ["Left","LeftFront"]:shell.get_node("Frames/"+part).position.x=-half_width
 for part in ["Right","RightFront"]:shell.get_node("Frames/"+part).position.x=half_width
func set_zoom(value: float) -> void:
 zoom_amount=value;resize_world()
