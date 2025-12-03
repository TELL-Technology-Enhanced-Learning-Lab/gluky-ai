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
@export var low_glucose_threshold: float = 70.0
@export var high_glucose_threshold: float = 180.0
@export var low_symptom_intensity: float = 1.0
@export var high_symptom_intensity: float = 1.0

var yaw: float = 0.0
var vertical_offset: float = 4.0
var player: CharacterBody3D
var actual_camera_distance: float = camera_distance
var touch_delta: Vector2 = Vector2.ZERO
var glucose_value: float = 90.0
var low_symptom_timer: float = 0.0
var high_symptom_timer: float = 0.0
var base_smooth_speed: float
var base_mouse_sensitivity: float
var dizziness_offset: Vector2 = Vector2.ZERO
var original_fov: float

func _ready():
	player = get_parent()
	base_smooth_speed = smooth_speed
	base_mouse_sensitivity = mouse_sensitivity
	original_fov = fov
	
	if OS.has_feature("mobile"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func set_glucose(value: float):
	glucose_value = value

func _input(event):
	var sensitivity_mod = 1.0
	if glucose_value < low_glucose_threshold:
		sensitivity_mod = lerp(0.7, 1.0, (glucose_value - 50.0) / 20.0)
	elif glucose_value > high_glucose_threshold:
		sensitivity_mod = lerp(1.0, 0.8, min((glucose_value - 180.0) / 70.0, 1.0))
	
	if OS.has_feature("mobile"):
		if event is InputEventScreenDrag:
			if event.index == 0:
				yaw -= event.relative.x * touch_sensitivity * sensitivity_mod
			elif event.index == 1:
				var inverted_vertical = -event.relative.y * sensitivity_mod
				vertical_offset = clamp(vertical_offset + inverted_vertical * vertical_sensitivity, min_vertical_offset, max_vertical_offset)
	else:
		if event is InputEventMouseMotion:
			yaw -= event.relative.x * mouse_sensitivity * sensitivity_mod
			var inverted_vertical = -event.relative.y * sensitivity_mod
			vertical_offset = clamp(vertical_offset + inverted_vertical * vertical_sensitivity, min_vertical_offset, max_vertical_offset)

func _physics_process(delta):
	if not player:
		return
	
	update_symptoms(delta)
	
	var player_pos = player.global_position
	var camera_target = player_pos + Vector3(0, vertical_offset, 0)
	
	var yaw_with_dizziness = yaw
	if glucose_value < low_glucose_threshold:
		dizziness_offset = dizziness_offset.lerp(Vector2(randf_range(-1, 1), randf_range(-1, 1)) * low_symptom_intensity, delta * 2.0)
		yaw_with_dizziness += dizziness_offset.x * 0.1
		camera_target.y += dizziness_offset.y * 0.2
	
	var desired_offset = Vector3(0, 0, camera_distance).rotated(Vector3.UP, yaw_with_dizziness)

	actual_camera_distance = check_camera_collision(camera_target, desired_offset)
	var final_position = camera_target + desired_offset.normalized() * actual_camera_distance

	final_position = ensure_minimum_height(final_position, player_pos)
	
	var current_smooth_speed = smooth_speed
	if glucose_value > high_glucose_threshold:
		current_smooth_speed = lerp(base_smooth_speed, base_smooth_speed * 0.5, min((glucose_value - 180.0) / 70.0, 1.0))
	
	global_position = global_position.lerp(final_position, current_smooth_speed * delta)
	look_at(player_pos + Vector3(0, 1, 0), Vector3.UP)
	
	apply_visual_effects()

func update_symptoms(delta):
	if glucose_value < low_glucose_threshold:
		low_symptom_timer += delta
		high_symptom_timer = 0.0
	elif glucose_value > high_glucose_threshold:
		high_symptom_timer += delta
		low_symptom_timer = 0.0
	else:
		low_symptom_timer = max(low_symptom_timer - delta * 2.0, 0.0)
		high_symptom_timer = max(high_symptom_timer - delta * 2.0, 0.0)

func apply_visual_effects():
	var blur_amount = 0.0
	var distortion_amount = 0.0
	
	if glucose_value < low_glucose_threshold:
		var severity = clamp((low_glucose_threshold - glucose_value) / 20.0, 0.0, 1.0)
		blur_amount = severity * low_symptom_intensity
		distortion_amount = severity * low_symptom_intensity * 0.5
		fov = original_fov + sin(low_symptom_timer * 3.0) * 2.0 * severity
		
	elif glucose_value > high_glucose_threshold:
		var severity = clamp((glucose_value - high_glucose_threshold) / 70.0, 0.0, 1.0)
		blur_amount = severity * high_symptom_intensity * 0.7
		fov = original_fov - severity * 3.0
		
		if high_symptom_timer > 0.5:
			var pulse = sin(high_symptom_timer * 6.0) * severity * 0.1
			rotation.z += pulse
	else:
		fov = lerp(fov, original_fov, 0.1)
		rotation.z = lerp_angle(rotation.z, 0.0, 0.1)

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
