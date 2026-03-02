extends MeshInstance3D


@export var amplitude_deg: float = 20.0   # ampiezza oscillazione
@export var speed: float = 1.2            # velocità (naturale)

var time := 0.0

func _process(delta):
	time += delta * speed
	rotation.x = deg_to_rad(sin(time) * amplitude_deg)
