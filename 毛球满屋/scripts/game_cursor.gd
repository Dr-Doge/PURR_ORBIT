extends Node
const MOUSE = preload("res://Art/Mouse.png")
const GLOVE = preload("res://Art/Glove.png")
const NORMAL_SHAPES = [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_IBEAM,Input.CURSOR_DRAG,Input.CURSOR_CAN_DROP,Input.CURSOR_FORBIDDEN]
var mouse_texture: ImageTexture
var glove_texture: ImageTexture
func cursor_texture(source: Texture2D,height: int) -> ImageTexture:
 var image: Image=source.get_image()
 # Remove transparent padding only in the runtime cursor, leaving source art intact.
 image=image.get_region(image.get_used_rect())
 var width: int=maxi(1,roundi(float(image.get_width())*height/image.get_height()))
 image.resize(width,height,Image.INTERPOLATE_NEAREST)
 return ImageTexture.create_from_image(image)
func _ready() -> void:
 mouse_texture=cursor_texture(MOUSE,40)
 glove_texture=cursor_texture(GLOVE,56)
 for shape in NORMAL_SHAPES:Input.set_custom_mouse_cursor(mouse_texture,shape,Vector2(2,1))
 Input.set_custom_mouse_cursor(glove_texture,Input.CURSOR_CROSS,Vector2(15,11))
func _exit_tree() -> void:
 for shape in NORMAL_SHAPES:Input.set_custom_mouse_cursor(null,shape)
 Input.set_custom_mouse_cursor(null,Input.CURSOR_CROSS)
