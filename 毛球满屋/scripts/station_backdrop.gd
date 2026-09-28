extends Control
const SCENE = preload("res://Art/Scene.jpg")
const MASK = preload("res://Art/mask.jpg")
const UNIVERSE = preload("res://Art/universe.jpg")
const SHADER = preload("res://Art/station_windows.gdshader")
# Fit the scene and its mask to the same 16:9 presentation canvas.
const DESIGN_SIZE = Vector2(1440,810)
const ORBIT_SECONDS = 300.0
var elapsed: float = 0.0
func _ready() -> void:
 mouse_filter = MOUSE_FILTER_IGNORE
 var composite := ShaderMaterial.new()
 composite.shader = SHADER
 composite.set_shader_parameter("window_mask",MASK)
 composite.set_shader_parameter("universe",UNIVERSE)
 material = composite
func step(dt: float) -> void:
 elapsed = fposmod(elapsed+dt,ORBIT_SECONDS)
 material.set_shader_parameter("orbit_angle",elapsed*TAU/ORBIT_SECONDS)
 queue_redraw()
func _draw() -> void:
 draw_texture_rect(SCENE,Rect2(Vector2.ZERO,size),false)
