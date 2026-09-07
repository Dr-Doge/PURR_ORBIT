extends Node3D

const SPRITESHEET_PLAYER := preload("res://scripts/vfx/spritesheet_vfx_3d.gd")

var opening_vfx
var standby_vfx


func configure(opening_texture: Texture2D, standby_texture: Texture2D, target_world_size: float) -> void:
	opening_vfx = SPRITESHEET_PLAYER.new()
	opening_vfx.name = "OpeningVFX"
	add_child(opening_vfx)
	# 64 帧在约 0.9 秒内播完，与剪影弹出、落定的总时长对齐。
	opening_vfx.configure(opening_texture, target_world_size, 72.0, false, false)
	opening_vfx.playback_finished.connect(_start_standby)

	standby_vfx = SPRITESHEET_PLAYER.new()
	standby_vfx.name = "StandbyVFX"
	standby_vfx.visible = false
	standby_vfx.scale = Vector3.ONE * 0.08
	add_child(standby_vfx)
	standby_vfx.configure(standby_texture, target_world_size, 30.0, true, false)


func _start_standby() -> void:
	if opening_vfx:
		opening_vfx.visible = false
		opening_vfx.queue_free()
		opening_vfx = null
	if not standby_vfx: return
	standby_vfx.visible = true
	var grow := create_tween()
	grow.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	grow.tween_property(standby_vfx, "scale", Vector3.ONE, 0.58)
