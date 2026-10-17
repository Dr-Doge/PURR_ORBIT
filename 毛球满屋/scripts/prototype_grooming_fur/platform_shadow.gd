extends Node2D
var view: Control
func _draw() -> void:
 if view==null or view.model==null:return
 draw_set_transform(Vector2.ZERO,0.0,view.size/Vector2(1920,1080))
 var box: Rect2=view.model.body_rect
 var rect:=Rect2(box.position.x+box.size.x*.12,box.end.y-38,box.size.x*.77,58)
 var points:=PackedVector2Array()
 for i in range(48):points.append(rect.get_center()+Vector2(cos(TAU*i/48.0),sin(TAU*i/48.0))*rect.size*.5)
 draw_colored_polygon(points,Color(.08,.04,.025,.20))
