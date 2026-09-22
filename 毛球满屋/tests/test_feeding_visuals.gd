extends SceneTree
const Main=preload("res://scenes/main.tscn")
var failures: int=0
var game
func check(ok: bool,msg: String) -> void:
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:
 root.size=Vector2i(1440,900);call_deferred("run")
func capture(name: String) -> Image:
 for i in range(3):await process_frame
 await RenderingServer.frame_post_draw
 var img: Image=root.get_texture().get_image()
 img.save_png(ProjectSettings.globalize_path("res://reports/idle_009/"+name+".png"))
 return img
func run() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/idle_009"))
 game=Main.instantiate();game.testing=true;root.add_child(game);game.set_process(false);game.start_game()
 var m=game.model;var room=game.room
 m.cats.resize(1);m.gacha_ready=true;m.first_token=true
 var c: Dictionary=m.cats[0];c.layers=1;c.pop=0;c.pos=room.GACHA_POS;c.dest=c.pos
 room.interactive=false;room.step(0)
 var machine: Sprite2D=room.harvest_art.machine
 check(machine.z_index<room.z_index and machine.z_index>room.backdrop.z_index,"Gacha renders below cats and above backdrop")
 var corner: Vector2=room.project(room.GACHA_POS)
 check(corner.x>1020 and corner.y<=155,"Gacha moved to top-right by sidebar")
 var together: Image=await capture("14_gacha_cat_overlap")
 machine.hide()
 var alone: Image=await capture("15_cat_layer_reference")
 # Compare opaque interior sprite pixels in the actual viewport, not just z-index.
 var tex: Image=room.cat_visuals.texture(c.id).get_image()
 var rect: Rect2=room.cat_rect(c)
 var factor: float=room.stage_scale()*0.9
 var top_left: Vector2=room.screen_position(c.pos)+(rect.position-c.pos)*factor
 var extent: Vector2=rect.size*factor
 var samples: int=0;var changed: int=0
 for y in range(2,int(extent.y)-2):
  for x in range(2,int(extent.x)-2):
   var screen: Vector2i=Vector2i(top_left+Vector2(x,y))
   var uv: Vector2=(Vector2(screen)+Vector2(0.5,0.5)-top_left)/extent
   if room.cat_visuals.flipped(c.id):uv.x=1.0-uv.x
   var pixel: Vector2i=Vector2i(uv*Vector2(tex.get_size()))
   var solid: bool=true
   for offset in [Vector2i.ZERO,Vector2i(-16,0),Vector2i(16,0),Vector2i(0,-16),Vector2i(0,16),Vector2i(-16,-16),Vector2i(16,-16),Vector2i(-16,16),Vector2i(16,16)]:
    var point: Vector2i=(pixel+offset).clamp(Vector2i.ZERO,tex.get_size()-Vector2i.ONE)
    if tex.get_pixelv(point).a<0.99:solid=false
   if not solid:continue
   samples+=1
   if together.get_pixelv(screen)!=alone.get_pixelv(screen):changed+=1
 print("OCCLUSION: ",samples," opaque samples, ",changed," changed")
 check(samples>300 and changed==0,"Cat opaque pixels stay in front of machine")
 machine.show();room.interactive=true
 m.move_cat(c.id,Vector2(400,550));room.step(0)
 var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.position=room.screen_position(room.GACHA_POS)
 root.push_input(event);await process_frame
 check(game.modal=="gacha","New gacha location remains clickable")
 game.close_modal();m.wallet=20000
 m.research("worker");m.research("feeder");m.buy("feeder",Vector2(650,500));m.refill(m.facilities[0].id)
 m.move_cat(c.id,Vector2(480,535));m.tick(0.1);room.step(0.1)
 await capture("16_seeking_food")
 m.move_cat(c.id,m.feeding_spot(m.facilities[0]));m.tick(0.5);room.step(0.5)
 await capture("17_eating")
 m.tick(0.5);m.tick(1);room.step(0.1)
 check(c.fed>0,"Feeding fixture gets buff")
 await capture("18_fed_roaming")
 game.queue_free();await process_frame
 print("FEEDING VISUALS: ",failures," failures")
 quit(0 if failures==0 else 1)
