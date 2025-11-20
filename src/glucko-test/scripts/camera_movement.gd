extends Camera3D

@export var mouse_sensitivity: float = 0.003
@export var touch_sensitivity: float = 0.002
@export var min_vertical_offset: float = 2.0
@export var max_vertical_offset: float = 6.0
@export var camera_distance: float = 5.0
@export var vertical_sensitivity: float = 0.01
@export var smooth_speed: float = 8.0
@export var collision_margin: float = 0.3
@export var min_camera_height: float = 0.5

var yaw: float = 0.0
var vertical_offset: float = 4.0
var player: CharacterBody3D
var actual_camera_distance: float = camera_distance
var touch_delta: Vector2 = Vector2.ZERO

func _ready():
	player = get_parent()
	if OS.has_feature("mobile"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if OS.has_feature("mobile"):
		if event is InputEventScreenDrag:
			if event.index == 0:
				yaw -= event.relative.x * touch_sensitivity
			elif event.index == 1:
				vertical_offset = clamp(vertical_offset - event.relative.y * vertical_sensitivity, min_vertical_offset, max_vertical_offset)
	else:
		if event is InputEventMouseMotion:
			yaw -= event.relative.x * mouse_sensitivity
			vertical_offset = clamp(vertical_offset - event.relative.y * vertical_sensitivity, min_vertical_offset, max_vertical_offset)

func _physics_process(delta):
	if not player:
		return
	
	var player_pos = player.global_position
	var camera_target = player_pos + Vector3(0, vertical_offset, 0)
	var desired_offset = Vector3(0, 0, camera_distance).rotated(Vector3.UP, yaw)

	actual_camera_distance = check_camera_collision(camera_target, desired_offset)
	var final_position = camera_target + desired_offset.normalized() * actual_camera_distance

	final_position = ensure_minimum_height(final_position, player_pos)
	
	global_position = global_position.lerp(final_position, smooth_speed * delta)
	look_at(player_pos + Vector3(0, 1, 0), Vector3.UP)

func check_camera_collision(camera_target: Vector3, desired_offset: Vector3) -> float:
	var space_state = get_world_3d().direct_space_state
	var max_distance = desired_offset.length()
	var direction = desired_offset.normalized()
	
	var query = PhysicsRayQueryParameters3D.create(
		camera_target,
		camera_target + direction * (max_distance + collision_margin)
	)
	query.exclude = [player]
	
	var collision = space_state.intersect_ray(query)
	
	if collision:
		var collision_distance = camera_target.distance_to(collision.position) - collision_margin
		return max(collision_distance, collision_margin * 2)
	
	return max_distance

func ensure_minimum_height(camera_position: Vector3, player_pos: Vector3) -> Vector3:
	var space_state = get_world_3d().direct_space_state
	
	var ground_query = PhysicsRayQueryParameters3D.create(
		Vector3(camera_position.x, player_pos.y + 5.0, camera_position.z),
		Vector3(camera_position.x, player_pos.y - 10.0, camera_position.z)
	)
	
	var ground_collision = space_state.intersect_ray(ground_query)
	
	if ground_collision:
		var ground_height = ground_collision.position.y
		var desired_height = ground_height + min_camera_height
		
		if camera_position.y < desired_height:
			camera_position.y = desired_height
	
	return camera_position
