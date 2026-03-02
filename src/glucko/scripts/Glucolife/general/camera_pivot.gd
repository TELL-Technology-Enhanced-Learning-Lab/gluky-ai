extends Node3D

@export var player_path: NodePath

@export var height: float = 1.6
@export var distance: float = 4.0
@export var side_offset: float = 0.0

@export var follow_speed: float = 6.0
@export var look_speed: float = 8.0

enum CameraState {
	NORMAL,
	CINEMATIC,
	FOOD_VIEW,
	BATHTUB_VIEW,
	FROZEN
}

var current_bounds: AABB
var camera_state: CameraState = CameraState.NORMAL

@onready var player: Node3D = get_node_or_null(player_path)
@onready var camera: Camera3D = $Camera3D

func _enter_tree():
	add_to_group("camera_pivot")

func _ready():
	if camera:
		camera.current = true

func set_bounds_from_area(area: Area3D):
	if not is_instance_valid(area):
		return
	var shape_node = area.get_node_or_null("CollisionShape3D")
	if not shape_node:
		return
	var shape = shape_node.shape
	if shape is BoxShape3D:
		var extents = shape.size * 0.5
		var center = area.global_position
		current_bounds = AABB(center - extents, shape.size)

func set_cinematic_mode(active: bool):
	if active and camera_state != CameraState.NORMAL:
		print("Warning: Trying to set cinematic mode while in ", camera_state)
		return
	if active:
		camera_state = CameraState.CINEMATIC
	else:
		camera_state = CameraState.NORMAL
		_reset_to_normal_position()

func set_food_view_mode(active: bool):
	if active and camera_state != CameraState.NORMAL:
		print("Warning: Trying to set food view mode while in ", camera_state)
		return
	if active:
		camera_state = CameraState.FOOD_VIEW
	else:
		camera_state = CameraState.NORMAL

func set_bathtub_mode(active: bool):
	if active and camera_state != CameraState.NORMAL:
		print("Warning: Trying to set bathtub view mode while in ", camera_state)
		return
	if active:
		camera_state = CameraState.BATHTUB_VIEW
	else:
		camera_state = CameraState.NORMAL

func freeze_camera(active: bool):
	if active:
		camera_state = CameraState.FROZEN
	else:
		camera_state = CameraState.NORMAL

func _reset_to_normal_position():
	if is_instance_valid(player):
		var target_pos = player.global_position
		target_pos.y += height
		target_pos.x += side_offset
		global_position = target_pos

func _process(delta):
	if not is_instance_valid(player) or not is_instance_valid(camera):
		return
	match camera_state:
		CameraState.NORMAL:
			_normal_camera_update(delta)
		CameraState.CINEMATIC, CameraState.FOOD_VIEW, CameraState.BATHTUB_VIEW, CameraState.FROZEN:
			pass

func _normal_camera_update(delta):
	var target_pos = _calculate_target_position()
	if current_bounds.size != Vector3.ZERO:
		target_pos.x = clamp(target_pos.x, current_bounds.position.x, current_bounds.position.x + current_bounds.size.x)
		target_pos.y = clamp(target_pos.y, current_bounds.position.y, current_bounds.position.y + current_bounds.size.y)
		target_pos.z = clamp(target_pos.z, current_bounds.position.z, current_bounds.position.z + current_bounds.size.z)
	global_position = global_position.lerp(target_pos, follow_speed * delta)
	var cam_target = Vector3(0, 0, distance)
	camera.position = camera.position.lerp(cam_target, follow_speed * delta)
	_update_camera_look(delta)

func _update_camera_look(delta):
	if not is_instance_valid(player) or not is_instance_valid(camera):
		return
	var look_target = player.global_position
	look_target.y += height * 0.8
	var target_transform = camera.global_transform.looking_at(look_target, Vector3.UP)
	camera.global_transform = camera.global_transform.interpolate_with(target_transform, look_speed * delta)

func _calculate_target_position() -> Vector3:
	if not is_instance_valid(player):
		return global_position
	var target_pos = player.global_position
	target_pos.y += height
	target_pos.x += side_offset
	return target_pos

func is_in_normal_mode() -> bool:
	return camera_state == CameraState.NORMAL

func get_current_state() -> CameraState:
	return camera_state
