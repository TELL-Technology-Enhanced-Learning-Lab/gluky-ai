extends CanvasLayer

@onready var icons := [
	$VBoxContainer/BoxContainer/Icon,
	$VBoxContainer/BoxContainer/Icon2,
	$VBoxContainer/BoxContainer/Icon3
]

@onready var counter_label: Label = $VBoxContainer/CounterLabel

var max_insulin := 3
var current_insulin := 3

var normal_modulate := Color(1, 1, 1, 1)
var depleted_modulate := Color(0.4, 0.4, 0.4, 0.6)

func _ready():
	update_display()

func set_insulin_count(count: int):
	current_insulin = clamp(count, 0, max_insulin)
	update_display()

func use_insulin():
	if current_insulin > 0:
		current_insulin -= 1
		update_display()

func add_insulin(amount: int = 1):
	current_insulin = min(current_insulin + amount, max_insulin)
	update_display()

func reset_insulin():
	current_insulin = max_insulin
	update_display()

func update_display():
	counter_label.text = "%d/%d" % [current_insulin, max_insulin]

	for i in range(max_insulin):
		if i < current_insulin:
			icons[i].modulate = normal_modulate
		else:
			icons[i].modulate = depleted_modulate

func get_insulin_available() -> int:
	return current_insulin
