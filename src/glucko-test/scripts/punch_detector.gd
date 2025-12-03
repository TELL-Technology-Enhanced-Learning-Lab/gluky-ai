extends Area3D

@onready var animation_player = get_node("../AnimationPlayer")

var can_punch: bool = true

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not can_punch:
		return

	if body.is_in_group("player") and animation_player and animation_player.has_animation("punching_gummy"):
		can_punch = false
		animation_player.play("punching_gummy")
		await animation_player.animation_finished
		animation_player.play_backwards("punching_gummy")
		await animation_player.animation_finished
		await get_tree().create_timer(2.0).timeout
		can_punch = true
