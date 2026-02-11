extends Node3D

@export var amplitude_deg: float = 20.0
@export var speed: float = 1.2
@export var phase_offset: float = 0.0   

var time := 0.0

func _process(delta):
	time += delta * speed
	rotation.x = deg_to_rad(
		sin(time + phase_offset) * amplitude_deg
	)
