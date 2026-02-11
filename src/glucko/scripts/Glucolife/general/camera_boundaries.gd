extends Area3D

@export var camera_pivot: NodePath


func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if body.is_in_group("player"):
		var cam = get_node(camera_pivot)
		cam.set_bounds_from_area(self)
