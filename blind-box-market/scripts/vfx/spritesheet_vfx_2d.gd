extends Sprite2D

signal playback_finished

const SHEET_COLUMNS := 8
const SHEET_ROWS := 8
const DEFAULT_FRAME_COUNT := SHEET_COLUMNS * SHEET_ROWS

var playback_fps := 36.0
var frame_count := DEFAULT_FRAME_COUNT
var elapsed := 0.0
var auto_free := true


func configure(sheet: Texture2D, fps := 36.0, should_auto_free := true, frames := DEFAULT_FRAME_COUNT) -> void:
	texture = sheet
	hframes = SHEET_COLUMNS
	vframes = SHEET_ROWS
	frame_count = clampi(frames, 1, DEFAULT_FRAME_COUNT)
	playback_fps = maxf(fps, 1.0)
	auto_free = should_auto_free
	elapsed = 0.0
	frame = 0
	centered = true
	set_process(texture != null)


func _process(delta: float) -> void:
	elapsed += delta
	var next_frame := int(floor(elapsed * playback_fps))
	if next_frame < frame_count:
		frame = next_frame
		return
	frame = frame_count - 1
	set_process(false)
	playback_finished.emit()
	if auto_free: queue_free()
