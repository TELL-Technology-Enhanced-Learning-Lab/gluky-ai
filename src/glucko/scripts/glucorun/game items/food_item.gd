extends Area3D

@export_group("Glucorun Stats")
@export var glucose_amount: float = 15.0
@export var effect_duration: float = 30.0

@export_group("Glucolife Stats")
@export var glucolife_glucose: float = 0.0
@export var glucolife_energy: float = 0.0
@export var glucolife_happiness: float = 0.0
@export var glucolife_digestion: float = 0.0

func get_food_data() -> Dictionary:
	return {
		"glucose_amount": glucose_amount,
		"effect_duration": effect_duration,
	}

func get_glucolife_data() -> Dictionary:
	return {
		"glucose": glucolife_glucose,
		"energy": glucolife_energy,
		"happiness": glucolife_happiness,
		"digestion_duration": glucolife_digestion
	}
