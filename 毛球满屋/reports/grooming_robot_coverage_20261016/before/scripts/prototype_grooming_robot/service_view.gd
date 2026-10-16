extends "res://scripts/prototype_grooming/service_view.gd"
const DirtShader=preload("res://scripts/prototype_grooming_robot/dirt.gdshader")
func _ready() -> void:
 super()
 foreground.z_index=30
func sync() -> void:
 super()
 if model==null:return
 for obj in model.objects:
  var entry: Dictionary=object_sprites[obj.id]
  if entry.sprite.material.shader!=DirtShader:
   var material:=ShaderMaterial.new();material.shader=DirtShader
   material.set_shader_parameter("remaining_mask",entry.texture)
   material.set_shader_parameter("opacity",obj.opacity)
   entry.sprite.material=material
 tool.position=mouse*size/C.CANVAS
 tool.modulate.a=1.0 if game!=null and game.dragging else .65
func _draw() -> void:
 if model==null:return
 draw_set_transform(Vector2.ZERO,0,size/C.CANVAS)
 draw_texture_rect(model.assets.texture("room_background"),Rect2(Vector2.ZERO,C.CANVAS),false)
 draw_texture_rect(model.assets.texture("grooming_table"),Rect2(-100,550,2120,1193),false)
 if model.stage in ["reward","departure"]:
  draw_texture_rect(model.assets.texture("coin"),Rect2(780,145,62,62),false)
  draw_string(ThemeDB.fallback_font,Vector2(855,196),"+%d"%model.last_payment,HORIZONTAL_ALIGNMENT_LEFT,-1,64,Color(1,.85,.3))
func draw_foreground(canvas: Node2D) -> void:
 if model==null:return
 canvas.draw_set_transform(Vector2.ZERO,0,size/C.CANVAS)
 if model.stage!="cleaning":return
 for obj in model.objects:
  if obj.done or not obj.stubborn:continue
  var at: Vector2=obj.rect.position+Vector2(0,-12)
  var text: String="顽固污垢 %d%%"%roundi((1-obj.sum/obj.initial)*100)
  canvas.draw_style_box(label_style(),Rect2(at-Vector2(7,23),Vector2(154,34)))
  canvas.draw_string(ThemeDB.fallback_font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color(.28,.17,.08))
 if game!=null and game.dragging:canvas.draw_arc(mouse,C.BRUSH_RADIUS,0,TAU,32,Color(.7,1,1,.8),2,true)
