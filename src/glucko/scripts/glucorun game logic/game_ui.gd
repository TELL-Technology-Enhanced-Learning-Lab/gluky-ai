extends CanvasLayer

@onready var glucose_bar = $GlucoseUI
@onready var insulin_counter = $InsulinCounter

func _ready():
	glucose_bar.visible = true
	insulin_counter.visible = true


func get_glucose_bar():
	return glucose_bar

func get_insulin_counter():
	return insulin_counter
