extends Area3D

@export var glucose_amount: float = 15.0
@export var effect_duration: float = 30.0

func get_food_data() -> Dictionary:
	return {
		"glucose_amount": glucose_amount,
		"effect_duration": effect_duration,
	}
