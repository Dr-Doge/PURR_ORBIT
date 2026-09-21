extends SceneTree
const Main = preload("res://scenes/main.tscn")
var game
var failures: int = 0
var output: String
func check(ok: bool,message: String) -> void:
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:
 root.size=Vector2i(1440,900)
 output=OS.get_environment("TEMP").path_join("purr-station-art")
 DirAccess.make_dir_recursive_absolute(output)
 call_deferred("run")
func capture(name: String) -> Image:
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 var image: Image=root.get_texture().get_image()
 image.save_png(output.path_join(name+".png"))
 return image
func run() -> void:
 game=Main.instantiate();game.testing=true;root.add_child(game);game.set_process(false)
 await capture("01_title")
 check(game.hud.title_art.visible,"Title image displayed at start")
 game.start_game();game.room.step(0)
 check(not game.hud.title_art.visible,"Title hidden in room")
 var cat: Dictionary=game.model.cats[0]
 var mapped: Vector2=game.room.screen_position(cat.pos)
 check(game.room._get_cursor_shape(mapped)==Control.CURSOR_CROSS,"Hovering a pettable cat selects glove")
 check(game.room._get_cursor_shape(game.room.screen_position(Vector2(180,680)))==Control.CURSOR_ARROW,"Empty floor selects mouse")
 check(game.room.world(mapped).distance_to(cat.pos)<0.001,"Input mapping inverts presentation coordinates")
 for i in range(8):
  var motion:=InputEventMouseMotion.new()
  motion.position=game.room.screen_position(cat.pos+Vector2(-18 if i%2 else 18,0))
  root.push_input(motion);await process_frame
 check(game.model.harvests>0,"Real mouse petting works on remapped cats")
 game.room.step(0)
 game.room.backdrop.elapsed=0;game.room.backdrop.step(0)
 var first: Image=await capture("02_room_000")
 game.room.backdrop.step(75)
 var quarter: Image=await capture("03_room_075")
 game.room.backdrop.step(225)
 var cycle: Image=await capture("04_room_300")
 var mask: Image=game.room.Backdrop.MASK.get_image()
 var changed_inside: int=0
 var changed_outside: int=0
 var wrong_cycle: int=0
 var leak_bounds := Rect2i()
 var origin: Vector2=game.room.stage_origin()
 var extent: Vector2=game.room.Backdrop.DESIGN_SIZE*game.room.stage_scale()
 for y in range(int(origin.y)+2,int(origin.y+extent.y)-2,4):
  for x in range(int(origin.x)+2,int(origin.x+extent.x)-2,4):
   var uv: Vector2=(Vector2(x+0.5,y+0.5)-origin)/extent
   var m: float=mask.get_pixel(int(uv.x*mask.get_width()),int(uv.y*mask.get_height())).r
   # Exclude the linear-filter footprint at mask edges from the solid-black check.
   var edge_max: float=m
   for offset in [Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,2)]:
    var sample_at: Vector2i=Vector2i(uv*Vector2(mask.get_size()))+offset
    sample_at=sample_at.clamp(Vector2i.ZERO,mask.get_size()-Vector2i.ONE)
    edge_max=maxf(edge_max,mask.get_pixelv(sample_at).r)
   if first.get_pixel(x,y)!=quarter.get_pixel(x,y):
    if m>0.9:changed_inside+=1
    elif edge_max<0.05:
     changed_outside+=1
     leak_bounds=leak_bounds.expand(Vector2i(x,y)) if changed_outside>1 else Rect2i(x,y,1,1)
   if first.get_pixel(x,y)!=cycle.get_pixel(x,y):wrong_cycle+=1
 check(changed_inside>100,"Universe visibly rotates through white windows")
 print("MASK: inside=",changed_inside," outside=",changed_outside," bounds=",leak_bounds," origin=",origin," extent=",extent," room=",game.room.size," image=",first.get_size())
 check(changed_outside==0,"Rotation never leaks outside mask")
 check(wrong_cycle==0,"300 seconds returns to identical orientation")
 var press:=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true;press.position=game.room.screen_position(cat.pos)
 root.push_input(press);await process_frame
 check(game.room._get_cursor_shape(game.room.screen_position(cat.pos))==Control.CURSOR_ARROW,"Carrying a cat leaves petting cursor")
 var destination: Vector2=cat.pos+Vector2(100,40)
 var drag:=InputEventMouseMotion.new();drag.position=game.room.screen_position(destination);root.push_input(drag);await process_frame
 press=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.pressed=false;press.position=game.room.screen_position(destination)
 root.push_input(press);await process_frame
 check(cat.pos.distance_to(destination)<0.01 and not cat.dragging,"Drag and release stay aligned with new floor")
 game.show_shop();await capture("05_shop")
 check(game.room._get_cursor_shape(game.room.screen_position(cat.pos))==Control.CURSOR_ARROW,"Modal screens restore mouse")
 game.show_tree();await capture("06_tree")
 game.close_modal()
 root.size=Vector2i(1280,720)
 await capture("07_room_1280")
 mapped=game.room.screen_position(cat.pos)
 check(game.room.world(mapped).distance_to(cat.pos)<0.001,"Resized input mapping stays aligned")
 game.show_start();await capture("08_title_1280")
 game.queue_free();await process_frame
 print("STATION ART CHECKS: ",failures," failures; images: ",output)
 quit(0 if failures==0 else 1)
