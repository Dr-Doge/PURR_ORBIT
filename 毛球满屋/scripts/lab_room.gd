extends "res://scripts/room_3d.gd"
func draw_cat_feedback(c: Dictionary) -> void:
 # The facility caption already reports occupancy at this same point.
 if c.station<0:super.draw_cat_feedback(c)
