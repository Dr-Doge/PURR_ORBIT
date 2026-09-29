extends SceneTree
func _initialize() -> void:call_deferred("run")
func capture() -> Image:
 for i in range(4):await process_frame
 await RenderingServer.frame_post_draw
 return root.get_texture().get_image()
func run() -> void:
 root.size=Vector2i(1440,810)
 var game=load("res://scenes/3D scene.tscn").instantiate();game.testing=true;root.add_child(game)
 game.start_game();game.set_process(false);game.room.set_process(false);game.model.cats.clear()
 var c=game.model.add_cat(Vector2(690,500));c.kind="static"
 var front=game.model.add_cat(Vector2(715,540));front.kind="giant"
 game.room.step(0);game.refresh()
 var outline=game.room.actor_lighting.sprites["Outline_%d"%c.id]
 var cat=game.room.actor_lighting.sprites["Cat_%d"%c.id]
 assert(is_equal_approx(outline.position.z,cat.position.z))
 assert(not game.room.static_outlines.visible)
 outline.material_override.set_shader_parameter("thin_width",0.0)
 outline.material_override.set_shader_parameter("pulse",1.0)
 var shown: Image=await capture()
 DirAccess.make_dir_recursive_absolute("res://reports/cat2new")
 shown.save_png("res://reports/cat2new/overlap.png")
 outline.material_override.set_shader_parameter("pulse",0.0)
 var transparent: Image=await capture()
 outline.visible=false;var hidden: Image=await capture()
 assert(transparent.get_data()==hidden.get_data(),"Zero pulse must be fully transparent, not black")
 outline.visible=true;outline.material_override.set_shader_parameter("pulse",0.5)
 var middle: Image=await capture()
 var visible_pixels=0
 for y in range(shown.get_height()):
  for x in range(shown.get_width()):
   if absf(shown.get_pixel(x,y).r-hidden.get_pixel(x,y).r)+absf(shown.get_pixel(x,y).g-hidden.get_pixel(x,y).g)+absf(shown.get_pixel(x,y).b-hidden.get_pixel(x,y).b)>0.01:visible_pixels+=1
 assert(visible_pixels>20,"Bright outline remains visible")
 assert(middle.get_data()!=hidden.get_data() and middle.get_data()!=shown.get_data(),"Half pulse is an intermediate fade")
 outline.material_override.set_shader_parameter("pulse",1.0)
 outline.material_override.set_shader_parameter("thin_width",2.0)
 # An opaque card in front must fully occlude the rear outline in its screen rectangle.
 var blocker:=Sprite3D.new();var im=Image.create(320,320,false,Image.FORMAT_RGBA8);im.fill(Color.RED)
 blocker.texture=ImageTexture.create_from_image(im);blocker.position=cat.position+Vector3(0,0,0.1)
 blocker.pixel_size=cat.pixel_size*1.2;blocker.shaded=false
 game.room.actor_lighting.add_child(blocker)
 var on: Image=await capture();outline.visible=false;var off: Image=await capture()
 var changes=0
 for y in range(on.get_height()):
  for x in range(on.get_width()):
   if on.get_pixel(x,y)!=off.get_pixel(x,y):changes+=1
 assert(changes==0,"Foreground card must hide entire outline")
 blocker.queue_free()
 c.pos=Vector2(640,540);front.pos=Vector2(850,540);front.kind="short"
 game.room.step(0);outline.visible=true
 outline.material_override.set_shader_parameter("pulse",0.0)
 var plain: Image=await capture()
 plain.save_png("res://reports/cat2new/fine_outlines_grounded.png")
 assert(game.room.actor_lighting.sprites.has("Outline_%d"%front.id),"Short cat has a fine outline too")
 print("CAT2 OUTLINE: transparent / half / bright fade verified; foreground completely occludes outline")
 game.queue_free();await process_frame;quit()
