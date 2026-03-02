extends Control
class_name BaseStatusBar

@export var min_value := 0.0
@export var max_value := 100.0
@export var low_threshold := 30.0
@export var high_threshold := 70.0
@export var optimal_min := 40.0
@export var optimal_max := 60.0

var current_value := 0.0

var progress_bar: ProgressBar
var label_value: Label


func _ready():
	_find_nodes()
	resized.connect(_refresh)
	_refresh()


func _find_nodes():
	# Find the first ProgressBar child automatically
	for child in get_children():
		if child is ProgressBar:
			progress_bar = child
		elif child is Label:
			label_value = child


func set_value(value: float):
	current_value = clamp(value, min_value, max_value)
	_refresh()


func _refresh():
	if not progress_bar:
		return

	progress_bar.value = current_value

	_update_color()
	_update_label()


func _update_color():
	if not progress_bar:
		return

	if current_value <= low_threshold:
		progress_bar.add_theme_color_override("fill_color", Color(0.1, 0.4, 1.0)) # low → blue
	elif current_value >= high_threshold:
		progress_bar.add_theme_color_override("fill_color", Color(1.0, 0.2, 0.2)) # high → red
	elif current_value >= optimal_min and current_value <= optimal_max:
		progress_bar.add_theme_color_override("fill_color", Color(0.2, 1.0, 0.3)) # optimal → green
	else:
		progress_bar.add_theme_color_override("fill_color", Color(1.0, 0.8, 0.0)) # warning → yellow


func _update_label():
	if label_value:
		label_value.text = str(round(current_value))
