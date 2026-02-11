extends Area3D

@onready var candy1 = get_node("../Candy1")
@onready var candy2 = get_node("../Candy2")
@onready var candy3 = get_node("../Candy3")
var triggered = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	if body.is_in_group("player") and not triggered:
		triggered = true
		
		apply_force_to_candy(candy1, Vector3(0, 10, 10))
		await get_tree().create_timer(0.2).timeout
		apply_force_to_candy(candy2, Vector3(0, 10, 10))
		await get_tree().create_timer(0.2).timeout
		apply_force_to_candy(candy3, Vector3(0, 10, 10))

func apply_force_to_candy(candy, force):
	if candy is RigidBody3D:
		candy.freeze = false 
		candy.apply_central_impulse(force)
