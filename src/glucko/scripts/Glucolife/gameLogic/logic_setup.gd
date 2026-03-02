extends Node3D

@export var preferred_orientation := OrientationManager.OrientationMode.PORTRAIT
@export var status_bars_scene: PackedScene = preload("res://scenes/user interface/Status_Bars_Glucolife.tscn")

var status_bars_instance


func _ready():
	status_bars_instance = status_bars_scene.instantiate()
	add_child(status_bars_instance)

	GlucolifeDataManager.stats_changed.connect(_on_stats_changed)
	GlucolifeDataManager.enter_glucolife()


func _on_stats_changed(stats: Dictionary):
	if not status_bars_instance:
		return

	var mapping = {
		"GlucoseBar": stats.glucose,
		"EnergyBar": stats.energy,
		"HygieneBar": stats.hygiene,
		"HappinessBar": stats.happiness
	}

	for bar_name in mapping.keys():
		var bar = status_bars_instance.find_child(bar_name, true, false)
		if bar and bar.has_method("set_value"):
			bar.set_value(mapping[bar_name])
