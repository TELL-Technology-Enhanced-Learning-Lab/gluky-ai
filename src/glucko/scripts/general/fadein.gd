extends Node2D

@export var fade_duration: float = 1.0

func _ready() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
