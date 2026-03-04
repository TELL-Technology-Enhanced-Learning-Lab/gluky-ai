extends Node3D

@export var preferred_orientation := OrientationManager.OrientationMode.LANDSCAPE

func _ready():
	Glukybot.update_scene("res://scenes/menus/glucky/Intro_3d.tscn")
