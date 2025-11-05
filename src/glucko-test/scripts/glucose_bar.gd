extends CanvasLayer

@onready var glucose_bar = $ProgressBar  
var max_value = 100
var current_value = 50

func _ready():
	glucose_bar.max_value = max_value
	glucose_bar.value = current_value
	glucose_bar.size = Vector2(300, 30) 
	glucose_bar.position = Vector2(20, 20)

func update_bar(new_value):
	current_value = clamp(new_value, 0, max_value)
	glucose_bar.value = current_value
