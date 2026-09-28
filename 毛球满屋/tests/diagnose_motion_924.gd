extends SceneTree
const M=preload("res://scripts/model.gd")
const A=preload("res://scripts/cat_animation_data.gd")
func _initialize() -> void:
 for kind in ["short","giant","static","lucky"]:
  var frames=A.frames_for(kind)
  for anim in ["idle","walk","produce"]:
   var bottoms=[]
   for i in range(frames.get_frame_count(anim)):
    var tex=frames.get_frame_texture(anim,i)
    bottoms.append(tex.get_image().get_used_rect().end.y)
   print(kind," ",anim," ",bottoms)
 var m=M.new();m.cats.resize(2)
 var c=m.cats[0];var other=m.cats[1]
 c.pos=Vector2(500,450);other.pos=Vector2(675,450);c.dest=Vector2(800,450)
 var last=Vector2.ZERO;var turns=0
 for i in range(600):
  var next=m.Space.walk(m,c,c.pos.move_toward(c.dest,16.0/60.0))
  var delta=next-c.pos
  if delta.length()>0.001 and last.length()>0.001 and delta.dot(last)<0:turns+=1
  if delta.length()>0.001:last=delta
  c.pos=next
 print("600 steps turns=",turns," final=",c.pos)
 quit()
