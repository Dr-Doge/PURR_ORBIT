extends Sprite3D

signal playback_finished

const SHEET_COLUMNS := 8
const SHEET_ROWS := 8
const DEFAULT_FRAME_COUNT := SHEET_COLUMNS * SHEET_ROWS

var playback_fps := 36.0
var frame_count := DEFAULT_FRAME_COUNT
var looping := false
var auto_free := false
var elapsed := 0.0


func configure(sheet: Texture2D, target_world_size: float, fps := 36.0, should_loop := false, should_auto_free := false, frames := DEFAULT_FRAME_COUNT) -> void:
	texture = sheet
	hframes = SHEET_COLUMNS
	vframes = SHEET_ROWS
	frame_count = clampi(frames, 1, DEFAULT_FRAME_COUNT)
	playback_fps = maxf(fps, 1.0)
	looping = should_loop
	auto_free = should_auto_free
	elapsed = 0.0
	frame = 0
	centered = true
	shaded = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if texture:
		var frame_width := float(texture.get_width()) / float(SHEET_COLUMNS)
		pixel_size = target_world_size / maxf(frame_width, 1.0)
	set_process(texture != null)


func _process(delta: float) -> void:
	elapsed += delta
	var next_frame := int(floor(elapsed * playback_fps))
	if looping:
		frame = posmod(next_frame, frame_count)
		return
	if next_frame < frame_count:
		frame = next_frame
		return
	frame = frame_count - 1
	set_process(false)
	playback_finished.emit()
	if auto_free: queue_free()
