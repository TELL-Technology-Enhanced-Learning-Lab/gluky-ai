extends Node3D

@export var preferred_orientation := OrientationManager.OrientationMode.PORTRAIT

func _ready():
	GlucolifeDataManager.enter_glucolife()
	_update_ui()

func _update_ui():
	var stats = GlucolifeDataManager.get_stats()
	
	if has_node("UI/GlucoseBar"):
		$UI/GlucoseBar.value = stats.glucose
	if has_node("UI/EnergyBar"):
		$UI/EnergyBar.value = stats.energy
	if has_node("UI/HygieneBar"):
		$UI/HygieneBar.value = stats.hygiene
	if has_node("UI/HappinessBar"):
		$UI/HappinessBar.value = stats.happiness
