extends Control

@onready var number_label = $Background/Number

func set_number(value):
	number_label.text = "- " + str(value) + " -"
