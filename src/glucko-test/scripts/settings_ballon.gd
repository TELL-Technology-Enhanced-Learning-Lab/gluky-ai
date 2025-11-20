extends Node3D

@onready var area = $Area3D
var angular_speed = deg_to_rad(15)  

func _process(delta):
	rotation.y += angular_speed * delta

func _on_Area3D_body_entered(body):
	if body.is_in_group("player"):
		body.add_to_group("on_platform")
		body.platform_ref = self  

func _on_Area3D_body_exited(body):
	if body.is_in_group("player"):
		body.remove_from_group("on_platform")
		body.platform_ref = null
