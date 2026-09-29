extends SceneTree
func _initialize() -> void:call_deferred("run")
func press(game,key: int,echo: bool=false) -> void:
 var event:=InputEventKey.new();event.keycode=key;event.pressed=true;event.echo=echo
 game._input(event)
func run() -> void:
 var game=preload("res://scenes/3D scene.tscn").instantiate();game.testing=true;root.add_child(game)
 game.start_game();game.set_process(false)
 var initial: int=game.model.cats.size()
 press(game,KEY_6)
 assert(game.model.cats.size()==initial,"6 no longer spawns cats")
 press(game,KEY_L)
 assert(game.model.cats.size()==initial+1,"L spawns one cat")
 var c: Dictionary=game.model.cats.back()
 assert(c.kind=="static" and c.station==-1 and not c.get("debug_cat",false))
 press(game,KEY_L,true)
 assert(game.model.cats.size()==initial+1,"Key repeat ignored")
 press(game,KEY_L)
 assert(game.model.cats.size()==initial+2,"Each deliberate L adds one cat")
 assert(game.model.snapshot().cats.size()==initial+2,"Spawned cats persist")
 game.model.pet(c.id,1)
 assert(c.pet>0,"Spawned cat supports normal petting")
 print("STATIC HOTKEY: 7 checks passed")
 game.queue_free();await process_frame;quit()
