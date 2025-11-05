extends Node3D

var glucose_bar
var glucose_value = 50

func _ready():
	var ui_scene = load("res://art/user interface/Glucose_Bar.tscn")
	var ui_instance = ui_scene.instantiate()
	add_child(ui_instance)
	glucose_bar = ui_instance.get_node("CanvasLayer")

func update_value(new_value) -> void:
	glucose_value = new_value
	if glucose_bar and glucose_bar.has_method("update_bar"):
		glucose_bar.update_bar(glucose_value)
