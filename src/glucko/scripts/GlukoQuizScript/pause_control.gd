extends Control

signal stop 

@onready var ok_button = $Control/OkButton
@onready var back_button = $Control/BackButton

func _ready():
	
	# Connetti i pulsanti
	ok_button.pressed.connect(_on_ok_pressed)
	back_button.pressed.connect(_on_back_pressed)
	

func _on_back_pressed():
	stop.emit()
	hide()

func _on_ok_pressed():
	get_tree().change_scene_to_file("res://scenes/GlukoQuizScenes/Mainscene1.tscn")
	stop.emit()
	hide()
