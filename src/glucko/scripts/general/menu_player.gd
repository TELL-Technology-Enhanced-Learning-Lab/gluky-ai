extends Node3D

class_name CameraController

@onready var camera_node = get_node("../Node3D/Camera3D")

var current_position: int = 1
var is_animating: bool = false
var animation_player: AnimationPlayer

func _ready():
	if camera_node:
		await get_tree().process_frame
		if camera_node.has_signal("player_camera_movement"):
			camera_node.player_camera_movement.connect(_on_player_camera_movement)
		
		if camera_node.has_method("_find_player_animation_player"):
			camera_node._find_player_animation_player()
			animation_player = camera_node.player_animation_player
	else:
		print("Camera node not assigned!")

func _on_player_camera_movement(direction: int):
	if is_animating:
		return
	
	var target_position = current_position + direction
	
	if target_position < 0 or target_position > 2:
		return
	
	_move_to_position(target_position, direction)

func _move_to_position(target_position: int, _direction: int):
	is_animating = true
	var previous_position = current_position
	current_position = target_position
	
	_play_neck_animation(previous_position, target_position)

func _play_neck_animation(from_position: int, to_position: int):
	if not animation_player:
		is_animating = false
		return
	
	if from_position == 1 and to_position == 0:
		animation_player.play("turn_neck_left")
	elif from_position == 0 and to_position == 1:
		animation_player.play_backwards("turn_neck_left")
	elif from_position == 1 and to_position == 2:
		animation_player.play("turn_neck_right")
	elif from_position == 2 and to_position == 1:
		animation_player.play_backwards("turn_neck_right")

	await get_tree().create_timer(0.5).timeout
	is_animating = false
