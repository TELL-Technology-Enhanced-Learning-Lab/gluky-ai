extends Control

@onready var main_buttons: VBoxContainer = $MainButtons
@onready var options: Panel = $Options
@onready var fullscreen_button: Button = $Options/VBoxContainer/HBoxContainer2/FullscreenControl  
@onready var fullscreen_label: Label = $Options/VBoxContainer/HBoxContainer2/Label

@export var preferred_orientation := OrientationManager.OrientationMode.LANDSCAPE
	


func _ready():
	main_buttons.visible = true
	options.visible = false
	_check_and_hide_fullscreen_on_mobile()


func _check_and_hide_fullscreen_on_mobile() -> void:
	if OS.has_feature("mobile") or OS.has_feature("Android") or OS.has_feature("iOS"):
		if fullscreen_button:
			fullscreen_button.visible = false
		if fullscreen_label:
			fullscreen_label.visible = false
	else:
		if fullscreen_button:
			fullscreen_button.visible = true
		if fullscreen_label:
			fullscreen_label.visible = true


func _process(_delta):
	pass


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/glucorun levels/livello1.tscn")


func _on_settings_pressed() -> void:
	main_buttons.visible = false
	options.visible = true


func _on_back_pressed() -> void:
	main_buttons.visible = true
	get_tree().change_scene_to_file("res://scenes/menus/glucky/Minigame_Selection.tscn")
	


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_back_options_pressed() -> void:
	_ready()
