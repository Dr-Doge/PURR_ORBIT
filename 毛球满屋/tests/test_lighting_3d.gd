extends SceneTree
var game
var checks: int=0
var failures: int=0
func _initialize() -> void:
 root.size=Vector2i(1440,900);call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func capture(name: String) -> Image:
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 var img: Image=root.get_texture().get_image()
 img.save_png(ProjectSettings.globalize_path("res://reports/3d_scene/"+name+".png"))
 return img
func shadow_measure(lit: Image,clear: Image,exclude: Rect2) -> Vector2:
 var count: int=0
 var center: float=0
 for y in range(200,780,2):
  for x in range(40,1400,2):
   if exclude.has_point(Vector2(x,y)):continue
   var a: Color=lit.get_pixel(x,y)
   var b: Color=clear.get_pixel(x,y)
   if b.get_luminance()-a.get_luminance()>0.025:
    count+=1;center+=x
 return Vector2(count,center/maxi(1,count))
func run() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/3d_scene"))
 game=load("res://scenes/3D scene.tscn").instantiate();game.testing=true;root.add_child(game)
 await process_frame;game.start_game();game.set_process(false);game.hud.hide()
 var room=game.room
 var c: Dictionary=game.model.cats[0]
 game.model.cats=[c];c.pos=Vector2(720,560);c.dest=c.pos;c.layers=0;c.pop=0
 room.interactive=false;room.step(0)
 var lamp: OmniLight3D=room.shell.get_node("MainLamp")
 var sprite: Sprite3D=room.actor_lighting.sprites["Cat_%d"%c.id]
 check(sprite.shaded and sprite.cast_shadow!=0,"Cat is a lit shadow-casting 3D card")
 check(sprite.texture==room.cat_visuals.texture(c.id),"Animation texture synchronized")
 var factor: float=room.object_scale(c.pos)
 var rect: Rect2=room.cat_rect(c)
 var bounds: Rect2i=sprite.texture.get_image().get_used_rect()
 var texel_scale: float=rect.size.x*factor/sprite.texture.get_width()
 var exclude:=Rect2(room.screen_position(c.pos)+(rect.position-c.pos)*factor+Vector2(bounds.position)*texel_scale,Vector2(bounds.size)*texel_scale).grow(1)
 lamp.position=Vector3(-3,6,4);lamp.look_at(Vector3(0,0,-1))
 var left_on: Image=await capture("light_01_left")
 sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var left_off: Image=await capture("light_02_no_shadow")
 var left: Vector2=shadow_measure(left_on,left_off,exclude)
 check(left.x>30,"Rendered shadow visible outside cat silhouette")
 lamp.position=Vector3(3,6,4);lamp.look_at(Vector3(0,0,-1));sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
 var right_on: Image=await capture("light_03_right")
 sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var right_off: Image=await capture("light_04_right_no_shadow")
 var right: Vector2=shadow_measure(right_on,right_off,exclude)
 check(right.x>30 and left.y>right.y+20,"Moving the light reverses the projected shadow direction")
 print("SHADOW PIXELS / CENTROIDS: ",left," / ",right)
 lamp.position=Vector3(-3,6,4);lamp.look_at(Vector3(0,0,-1));sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
 c.pos.x+=12;room.step(0.16)
 check(sprite.texture==room.cat_visuals.texture(c.id) and sprite.flip_h==room.cat_visuals.flipped(c.id),"Walk frame and facing synchronized")
 game.model.wallet=1000000;game.model.round_no=2
 for key in ["worker","feeder","sun","arcade"]:game.model.researches[key]=true
 game.model.buy("feeder",Vector2(280,405));game.model.buy("sun",Vector2(680,395))
 game.model.buy("arcade",Vector2(1110,595));game.model.buy("worker",Vector2(440,640))
 c.pos=Vector2(300,620);c.dest=c.pos
 var positions: Array=[Vector2(520,535),Vector2(830,640),Vector2(970,505),Vector2(680,445)]
 var i: int=0
 for kind in ["giant","static","lucky","alien"]:
  var cat: Dictionary=game.model.add_cat(positions[i]);cat.kind=kind;cat.layers=1;i+=1
 room.step(0.0)
 check(room.actor_lighting.lamps.size()==1,"Sun equipment owns a local warm spotlight")
 check(room.actor_lighting.cards.size()==2,"Worker and arcade procedural art preserved as cards")
 game.model.first_token=true;game.model.gacha_ready=true;room.step(0)
 game.hud.show();game.refresh()
 await capture("light_05_full_room")
 var sun: SpotLight3D=room.actor_lighting.lamps.values()[0]
 sun.visible=false
 var sun_off: Image=await capture("light_06_sun_off")
 sun.visible=true
 var sun_on: Image=await capture("light_07_sun_on")
 var changed: int=0
 for y in range(210,730,3):
  for x in range(200,1100,3):
   if sun_on.get_pixel(x,y).get_luminance()-sun_off.get_pixel(x,y).get_luminance()>0.02:changed+=1
 check(changed>100,"Device lamp visibly illuminates the scene")
 game.model.cats.remove_at(4);room.step(0)
 check(room.actor_lighting.sprites.keys().filter(func(key):return key.begins_with("Cat_")).size()==4,"Removed cats release their shadow cards")
 for f in game.model.facilities:
  if f.kind=="sun":f.kind="feeder"
 room.step(0)
 check(room.actor_lighting.lamps.is_empty(),"Reused facility IDs do not retain old lamps after loading another game")
 print("3D LIGHTING: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
