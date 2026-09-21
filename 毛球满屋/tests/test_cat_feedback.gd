extends SceneTree
const M=preload("res://scripts/model.gd")
const R=preload("res://scripts/room.gd")
const D=preload("res://scripts/data.gd")
var failures: int=0
var checks: int=0
var room
func _initialize() -> void:
 root.size=Vector2i(1440,900);call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func motion(at: Vector2) -> void:
 var event:=InputEventMouseMotion.new();event.position=at;root.push_input(event)
func capture(name: String) -> Rect2i:
 room.queue_redraw()
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 var picture: Image=root.get_texture().get_image()
 check(picture.save_png(ProjectSettings.globalize_path("res://reports/cat_feedback/"+name+".png"))==OK,"Screenshot "+name)
 # Measure the actual rendered cream cat, not a copy of the animation formula.
 var left: int=1000;var right: int=0;var top: int=1000;var bottom: int=0
 for y in range(420,560):
  for x in range(520,680):
   var color: Color=picture.get_pixel(x,y)
   if absf(color.r-color.g)<0.02 and color.r>0.85 and color.r-color.b>0.04 and color.r-color.b<0.09:
    left=mini(left,x);right=maxi(right,x);top=mini(top,y);bottom=maxi(bottom,y)
 check(right>left and bottom>top,"Cat pixels found: "+name)
 return Rect2i(left,top,right-left+1,bottom-top+1)
func run() -> void:
 var m=M.new();m.rng.seed=173
 var c: Dictionary=m.cats[0];c.pos=Vector2(600,500);c.dest=Vector2(900,500);c.layers=1;c.pop=0.0;c.wander=9999.0
 m.tick(0.1)
 check(c.pos.x>600 and c.growth>0,"Growth and walking run together despite legacy walk timer")
 room=R.new();room.model=m;room.size=D.WORLD;room.interactive=true;root.add_child(room);await process_frame
 var target: Vector2=c.dest;var origin: Vector2=c.pos
 for i in range(6):
  motion(c.pos+Vector2(-18 if i%2 else 18,0));m.tick(0.1);await process_frame
 check(m.harvests==1 and m.wallet==3,"Real hover movement harvests a walking cat")
 check(c.pos.x>origin.x and c.dest==target,"Pet and harvest neither stop nor redirect walking")
 c.pos=c.dest;m.tick(0.1)
 check(c.pos!=target and c.dest!=target,"Next walk starts immediately at arrival")
 c.layers=0;c.growth=D.LAYER_CD-0.05;origin=c.pos;m.tick(0.1)
 check(c.layers==1 and c.pop>0 and c.pos!=origin,"New layer feedback triggers during walking")
 check(m.harvest(c.id),"New layer can be harvested immediately during walking and feedback")
 var saved: Dictionary=m.snapshot();saved.cats[0].wander=10000.0
 var restored=M.new();check(restored.restore(saved),"Existing v27 save remains readable")
 var loaded: Dictionary=restored.cats[0];origin=loaded.pos;restored.tick(0.1)
 check(loaded.pos!=origin,"Legacy saved wander timer does not restore a movement cooldown")
 m.cats=[c];c.pos=Vector2(600,500);c.dest=c.pos;c.kind="short";c.color=1;c.layers=2;c.pop=0.0;c.pet=0.0
 room.hover=-1;room.interactive=false
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/cat_feedback"))
 var before: Rect2i=await capture("01_before_growth")
 m.layer(c);c.pop=D.CAT_PULSE_DURATION/2.0
 var expanded: Rect2i=await capture("02_expansion_peak")
 c.pop=0.0
 var settled: Rect2i=await capture("03_settled_new_layer")
 check(expanded.size.x>settled.size.x and expanded.size.y>settled.size.y,"Layer feedback expands actual rendered body")
 check(absi(expanded.end.y-settled.end.y)<=1,"Expansion keeps feet planted instead of jumping")
 check(settled.size.x>before.size.x,"New fur layer keeps its persistent size gain after pulse")
 print("CAT FEEDBACK: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
