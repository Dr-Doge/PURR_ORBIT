extends Camera3D
## Only X is modified. The editor-authored Y/Z and rotation remain fixed.
@export var edge_fraction: float = 0.085
@export var pan_speed: float = 2.5
@export var min_x: float = -3.2
@export var max_x: float = 3.2
@export var enabled: bool = true
@export_node_path("Camera3D") var closeup_camera_path: NodePath
var _closeup_active := false
var _transition_busy := false
var _transition_home: Transform3D
var _transition_has_home := false
var _fade_rect: ColorRect

func _ready() -> void:
    if closeup_camera_path.is_empty():
        return
    var overlay := CanvasLayer.new()
    overlay.name = "ChamberTransitionFade"
    overlay.layer = 100
    add_child(overlay)
    _fade_rect = ColorRect.new()
    _fade_rect.color = Color(0, 0, 0, 0)
    _fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay.add_child(_fade_rect)
    _fade_rect.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    _resize_fade()
    get_viewport().size_changed.connect(_resize_fade)

func _resize_fade() -> void:
    _fade_rect.position = Vector2.ZERO
    _fade_rect.size = get_viewport().get_visible_rect().size

func transition_chamber() -> void:
    if _transition_busy:
        return
    var door = get_node_or_null("../21_ArtAirlock")
    if door == null or door.busy or _fade_rect == null:
        return
    _transition_busy = true
    var returning := _closeup_active
    if returning:
        var fade_out := create_tween()
        fade_out.tween_property(_fade_rect, "color:a", 1.0, 0.2)
        await fade_out.finished
    else:
        if free_view:
            toggle_free_view()
        _transition_home = global_transform
        _transition_has_home = true
        if not door.opened:
            door.toggle_door(0.2, 0.6)
        # Opening: 0–0.8 s. Camera push: 0.5–1.0 s.
        await get_tree().create_timer(0.5).timeout
        var focus: Vector3 = door.to_global(Vector3(0, 2.05, 0))
        var push_start := global_transform
        var focus_screen_start := unproject_position(focus)
        var zoom := create_tween().set_parallel(true)
        zoom.tween_method(_update_door_push.bind(push_start, focus, focus_screen_start), 0.0, 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        zoom.tween_property(_fade_rect, "color:a", 1.0, 0.2).set_delay(0.3)
        await zoom.finished
    # Switch only under an opaque, viewport-sized overlay, then hold black.
    _fade_rect.color.a = 1.0
    if returning:
        if _transition_has_home:
            global_transform = _transition_home
        set_closeup_active(false)
    else:
        set_closeup_active(true)
        global_transform = _transition_home
    await get_tree().create_timer(0.2).timeout
    var fade_in := create_tween()
    fade_in.tween_property(_fade_rect, "color:a", 0.0, 0.2)
    await fade_in.finished
    if returning:
        await get_tree().create_timer(0.4).timeout
        if door.opened:
            await door.toggle_door(0.2, 0.6)
    _transition_busy = false


func _update_door_push(progress: float, start: Transform3D, focus: Vector3, screen_start: Vector2) -> void:
    # Move toward the door itself, then correct its screen position using the
    # actual asymmetric projection (including frustum_offset).
    global_transform = start
    global_position = start.origin.lerp(focus, progress * 0.6)
    var desired := screen_start.lerp(get_viewport().get_visible_rect().size * 0.5, progress)
    var origin := global_position
    var projected := unproject_position(focus)
    var right := global_basis.x.normalized()
    var up := global_basis.y.normalized()
    global_position = origin + right
    var dx := unproject_position(focus) - projected
    global_position = origin + up
    var dy := unproject_position(focus) - projected
    var error := desired - projected
    var determinant := dx.x * dy.y - dx.y * dy.x
    global_position = origin
    if absf(determinant) > 0.00001:
        global_position += right * ((error.x * dy.y - error.y * dy.x) / determinant)
        global_position += up * ((dx.x * error.y - dx.y * error.x) / determinant)


func set_closeup_active(held: bool) -> void:
    var camera := get_node_or_null(closeup_camera_path) as Camera3D
    if held == _closeup_active or (held and camera == null):
        return
    if held:
        if free_view:
            toggle_free_view()
        camera.make_current()
    else:
        make_current()
    _closeup_active = held

func _input(event: InputEvent) -> void:
    if closeup_camera_path.is_empty():
        return
    if event is InputEventKey and (event.physical_keycode == KEY_O or event.keycode == KEY_O):
        if event.pressed and not event.echo:
            transition_chamber()
        get_viewport().set_input_as_handled()
        return

func edge_axis(mouse: Vector2, viewport_size: Vector2) -> float:
    if viewport_size.x <= 0.0 or not Rect2(Vector2.ZERO, viewport_size).has_point(mouse):
        return 0.0
    var band := viewport_size.x * edge_fraction
    if mouse.x < band:
        return -clampf((band - mouse.x) / band, 0.0, 1.0)
    if mouse.x > viewport_size.x - band:
        return clampf((mouse.x - (viewport_size.x - band)) / band, 0.0, 1.0)
    return 0.0

func pan_from_pointer(mouse: Vector2, viewport_size: Vector2, delta: float) -> void:
    var direction := edge_axis(mouse, viewport_size)
    if is_zero_approx(direction):
        return
    # Never snap an editor-authored start position while the pointer is idle.
    if direction < 0.0:
        if position.x > min_x:
            position.x = maxf(position.x + direction * pan_speed * delta, min_x)
    elif position.x < max_x:
        position.x = minf(position.x + direction * pan_speed * delta, max_x)

func _process(delta: float) -> void:
    if not get_window().has_focus():
        _release_free_mouse()
        return
    if _transition_busy or _closeup_active or not is_current():
        return
    if free_view:
        _move_free_camera(delta)
        return
    if not enabled:
        return
    var view := get_viewport()
    pan_from_pointer(view.get_mouse_position(), view.get_visible_rect().size, delta)

@export var free_move_speed: float = 7.0
@export var free_mouse_sensitivity: float = 0.003
var free_view := false
var _free_looking := false
var _saved_transform: Transform3D
var _saved_projection: int
var _saved_fov: float
var _saved_near: float
var _saved_mouse_mode: int
var _look_mouse_mode: int

func toggle_free_view() -> void:
    if free_view:
        _release_free_mouse()
        transform = _saved_transform
        projection = _saved_projection
        fov = _saved_fov
        near = _saved_near
        Input.mouse_mode = _saved_mouse_mode
        free_view = false
    else:
        _saved_transform = transform
        _saved_projection = projection
        _saved_fov = fov
        _saved_near = near
        _saved_mouse_mode = Input.mouse_mode
        free_view = true
        projection = Camera3D.PROJECTION_PERSPECTIVE
        fov = 55.0
        near = 0.1
        look_at(Vector3(global_position.x, 1.2, -3.5), Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if free_view and event.keycode == KEY_ESCAPE:
            _release_free_mouse()
    if not free_view:
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
        if event.pressed:
            _look_mouse_mode = Input.mouse_mode
            _free_looking = true
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        else:
            _release_free_mouse()
        get_viewport().set_input_as_handled()
    elif event is InputEventMouseMotion and _free_looking:
        var angles := rotation
        angles.y -= event.relative.x * free_mouse_sensitivity
        angles.x = clampf(angles.x - event.relative.y * free_mouse_sensitivity, -1.5, 1.5)
        angles.z = 0.0
        rotation = angles
        get_viewport().set_input_as_handled()

func _move_free_camera(delta: float) -> void:
    var local_move := Vector3(
        float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
        0.0,
        float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
    var direction := global_basis * local_move
    direction += Vector3.UP * (float(Input.is_physical_key_pressed(KEY_E)) - float(Input.is_physical_key_pressed(KEY_Q)))
    var speed := free_move_speed * (3.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 1.0)
    global_position += direction.normalized() * speed * delta

func _release_free_mouse() -> void:
    if _free_looking:
        Input.mouse_mode = _look_mouse_mode
        _free_looking = false

func _exit_tree() -> void:
    _release_free_mouse()
    if free_view:
        Input.mouse_mode = _saved_mouse_mode
