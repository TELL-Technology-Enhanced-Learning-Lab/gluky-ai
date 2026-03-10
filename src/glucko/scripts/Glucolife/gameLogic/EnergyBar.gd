extends BaseStatusBar
class_name EnergyBar

func _ready():
	min_value = 0.0
	max_value = 100.0
	low_threshold = 30.0
	high_threshold = 101.0
	optimal_min = 50.0
	optimal_max = 101.0

	super._ready()
