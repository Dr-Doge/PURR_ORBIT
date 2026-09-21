extends SceneTree
## Old v0.26 outputs remain under reports/pacing_2h; current model uses a separate audit.
func _initialize() -> void:
 print("Historical v0.26 analysis is frozen. Run res://tests/pacing_v027.gd for the current continuous demo.")
 quit()
