extends BaseStatusBar
class_name HappinessBar

func _ready():
	min_value = 0.0
	max_value = 100.0
	low_threshold = 30.0
	high_threshold = 70.0
	optimal_min = 40.0
	optimal_max = 60.0

	super._ready()
