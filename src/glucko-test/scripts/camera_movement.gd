extends Camera3D

@export var mouse_sensitivity: float = 0.003
@export var min_vertical_offset: float = 1.0
@export var max_vertical_offset: float = 3.0
@export var camera_distance: float = 5.0
@export var vertical_sensitivity: float = 0.01

var yaw: float = 0.0
var vertical_offset: float = 2.0
var player: CharacterBody3D

func _ready():
	player = get_parent().get_node("Player")
	if not player:
		player = get_tree().get_first_node_in_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	top_level = true

func _input(event):
	if event is InputEventMouseMotion and player:
		yaw -= event.relative.x * mouse_sensitivity
		
		if Input.is_key_pressed(KEY_SHIFT):
			vertical_offset = clamp(vertical_offset - event.relative.y * vertical_sensitivity, min_vertical_offset, max_vertical_offset)

func _process(_delta):
	if not player:
		return
	
	var player_pos = player.global_position
	
	var offset = Vector3(0, 0, camera_distance)
	offset = offset.rotated(Vector3.UP, yaw)
	
	global_position = player_pos + offset + Vector3(0, vertical_offset, 0)
	look_at(player_pos + Vector3(0, 1, 0), Vector3.UP)
