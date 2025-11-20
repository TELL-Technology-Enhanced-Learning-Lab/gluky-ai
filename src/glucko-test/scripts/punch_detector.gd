extends Area3D

@onready var animation_player = get_node("../AnimationPlayer")

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		if animation_player and animation_player.has_animation("punching_gummy"):
			animation_player.play("punching_gummy")
			await get_tree().create_timer(1.0).timeout
			animation_player.play_backwards("punching_gummy")
