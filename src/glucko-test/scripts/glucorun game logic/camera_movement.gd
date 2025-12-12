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
@export var low_symptom_intensity: float = 3.0
@export var high_symptom_intensity: float = 2.5

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

var world_environment: WorldEnvironment
var screen_tint: Color = Color.WHITE
var screen_shake_offset: Vector2 = Vector2.ZERO
var shake_timer: float = 0.0

var last_glucose_state: String = "normal"
var game_setup_connected: bool = false

func _ready():
	player = get_parent()
	base_smooth_speed = smooth_speed
	base_mouse_sensitivity = mouse_sensitivity
	original_fov = fov
	
	if OS.has_feature("mobile"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	call_deferred("setup_visual_effects")
	
	await get_tree().create_timer(0.1).timeout
	setup_game_setup_connection()

func setup_game_setup_connection():
	var game_setup = null
	
	for node in get_tree().root.get_children():
		if node is Node3D and node.get_script() != null:
			var script_path = node.get_script().resource_path
			if script_path != null and "game_setup" in script_path:
				game_setup = node
				break
	
	if not game_setup:
		game_setup = get_tree().root.get_node_or_null("GameSetup") or get_tree().root.find_child("GameSetup", true, false)
	
	if game_setup and not game_setup_connected:
		if game_setup.has_signal("glucose_updated"):
			game_setup.connect("glucose_updated", Callable(self, "_on_glucose_updated"))
			game_setup_connected = true

func _on_glucose_updated(value: float):
	glucose_value = value
	
	var new_state = "normal"
	if glucose_value < low_glucose_threshold:
		new_state = "LOW"
	elif glucose_value > high_glucose_threshold:
		new_state = "HIGH"
	
	last_glucose_state = new_state

func setup_visual_effects():
	cleanup_visual_effects()
	create_world_environment()

func cleanup_visual_effects():
	if is_instance_valid(world_environment) and world_environment.is_inside_tree():
		get_tree().root.remove_child.call_deferred(world_environment)
		world_environment.queue_free()
		world_environment = null

func create_world_environment():
	world_environment = WorldEnvironment.new()
	world_environment.name = "CameraWorldEnvironment"
	world_environment.environment = Environment.new()
	get_tree().root.add_child(world_environment)
	
	var env = world_environment.environment
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	
	env.glow_enabled = true
	env.glow_bloom = 0.3
	env.glow_intensity = 1.5
	env.glow_strength = 2.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	
	env.fog_enabled = false
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.0
	env.adjustment_saturation = 1.0

func set_glucose(value: float):
	glucose_value = value

func _input(event):
	var sensitivity_mod = 1.0
	if glucose_value < low_glucose_threshold:
		sensitivity_mod = lerp(0.4, 1.0, (glucose_value - 50.0) / 20.0)
	elif glucose_value > high_glucose_threshold:
		sensitivity_mod = lerp(1.0, 0.5, min((glucose_value - 180.0) / 70.0, 1.0))
	
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
	
	if not game_setup_connected:
		setup_game_setup_connection()
	
	update_symptoms(delta)
	update_screen_shake(delta)
	
	var player_pos = player.global_position
	var camera_target = player_pos + Vector3(0, vertical_offset, 0)
	
	if screen_shake_offset.length() > 0.001:
		camera_target.x += screen_shake_offset.x * 0.5
		camera_target.z += screen_shake_offset.y * 0.5
	
	var yaw_with_dizziness = yaw
	
	if glucose_value < low_glucose_threshold:
		var intensity = clamp((low_glucose_threshold - glucose_value) / 20.0, 0.0, 1.0) * low_symptom_intensity
		dizziness_offset = dizziness_offset.lerp(
			Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity,
			delta * 2.5
		)
		yaw_with_dizziness += dizziness_offset.x * 0.25
		camera_target.y += dizziness_offset.y * 0.35
	elif glucose_value > high_glucose_threshold:
		var intensity = clamp((glucose_value - high_glucose_threshold) / 70.0, 0.0, 1.0) * 1.2
		var t = Time.get_ticks_msec() / 1000.0
		dizziness_offset = dizziness_offset.lerp(
			Vector2(sin(t * 3.0) * intensity, cos(t * 2.5) * intensity),
			delta * 2.0
		)
		yaw_with_dizziness += dizziness_offset.x * 0.15
		camera_target.y += dizziness_offset.y * 0.2

	var desired_offset = Vector3(0, 0, camera_distance).rotated(Vector3.UP, yaw_with_dizziness)
	actual_camera_distance = check_camera_collision(camera_target, desired_offset)
	var final_position = camera_target + desired_offset.normalized() * actual_camera_distance
	final_position = ensure_minimum_height(final_position, player_pos)
	
	var current_smooth_speed = smooth_speed
	if glucose_value > high_glucose_threshold:
		current_smooth_speed = lerp(base_smooth_speed, base_smooth_speed * 0.3, min((glucose_value - 180.0) / 70.0, 1.0))
	
	global_position = global_position.lerp(final_position, current_smooth_speed * delta)
	look_at(player_pos + Vector3(0, 1, 0), Vector3.UP)
	
	apply_visual_effects()

func update_symptoms(delta):
	if glucose_value < low_glucose_threshold:
		low_symptom_timer += delta
		high_symptom_timer = 0.0
		if glucose_value < 50.0:
			shake_timer += delta * 3.0
	elif glucose_value > high_glucose_threshold:
		high_symptom_timer += delta
		low_symptom_timer = 0.0
		if glucose_value > 250.0:
			shake_timer += delta * 1.0
	else:
		low_symptom_timer = max(low_symptom_timer - delta * 2.0, 0.0)
		high_symptom_timer = max(high_symptom_timer - delta * 2.0, 0.0)
		shake_timer = max(shake_timer - delta * 4.0, 0.0)

func update_screen_shake(delta):
	if shake_timer > 0.0:
		var shake_intensity = 0.0
		if glucose_value < low_glucose_threshold:
			shake_intensity = clamp((low_glucose_threshold - glucose_value) / 20.0, 0.0, 1.0) * 4.0
		elif glucose_value > high_glucose_threshold:
			shake_intensity = clamp((glucose_value - high_glucose_threshold) / 70.0, 0.0, 1.0)
		
		var time = Time.get_ticks_msec() / 1000.0
		screen_shake_offset.x = sin(time * 20.0 + 0.0) * 1.0 * shake_intensity
		screen_shake_offset.y = cos(time * 18.0 + 1.0) * 1.0 * shake_intensity
	else:
		screen_shake_offset = screen_shake_offset.lerp(Vector2.ZERO, delta * 3.0)

func apply_visual_effects():
	if not world_environment or not world_environment.environment:
		return
	
	var env = world_environment.environment
	
	if glucose_value < low_glucose_threshold:
		var severity = clamp((low_glucose_threshold - glucose_value) / 20.0, 0.0, 1.0)
		
		var desat_color = Color.from_hsv(0.6, 0.3, 0.7)
		var dark_tint = Color(0.5, 0.6, 0.8, 1.0)
		screen_tint = screen_tint.lerp(desat_color.lerp(dark_tint, severity * 0.8), 0.05)
		fov = original_fov + sin(low_symptom_timer * 5.0) * 10.0 * severity
		
		env.adjustment_enabled = true
		env.adjustment_brightness = lerp(env.adjustment_brightness, 0.8 - severity * 0.3, 0.05)
		env.adjustment_contrast = lerp(env.adjustment_contrast, 1.2 + severity * 0.3, 0.05)
		env.adjustment_saturation = lerp(env.adjustment_saturation, 0.5 - severity * 0.3, 0.05)
		
	elif glucose_value > high_glucose_threshold:
		var severity = clamp((glucose_value - high_glucose_threshold) / 70.0, 0.0, 1.0)
		
		var warm_color = Color.from_hsv(0.05, 0.5, 1.0)
		var red_tint = Color(1.0, 0.7, 0.6, 1.0)
		screen_tint = screen_tint.lerp(warm_color.lerp(red_tint, severity * 0.7), 0.05)
		fov = lerp(fov, original_fov - severity * 8.0, 0.05)
		
		env.adjustment_enabled = true
		env.adjustment_brightness = lerp(env.adjustment_brightness, 1.2 + severity * 0.2, 0.05)
		env.adjustment_contrast = lerp(env.adjustment_contrast, 1.0 - severity * 0.2, 0.05)
		env.adjustment_saturation = lerp(env.adjustment_saturation, 1.5 + severity * 0.5, 0.05)
		
		if high_symptom_timer > 0.5:
			var pulse = sin(high_symptom_timer * 10.0) * severity * 0.25
			rotation.z += pulse
	
	else:
		fov = lerp(fov, original_fov, 0.05)
		rotation.z = lerp_angle(rotation.z, 0.0, 0.05)
		screen_tint = screen_tint.lerp(Color.WHITE, 0.05)
		
		env.adjustment_brightness = lerp(env.adjustment_brightness, 1.0, 0.05)
		env.adjustment_contrast = lerp(env.adjustment_contrast, 1.0, 0.05)
		env.adjustment_saturation = lerp(env.adjustment_saturation, 1.0, 0.05)
	
	if world_environment:
		env = world_environment.environment
		env.glow_enabled = glucose_value > high_glucose_threshold
		if env.glow_enabled:
			var severity = clamp((glucose_value - high_glucose_threshold) / 70.0, 0.0, 1.0)
			env.glow_bloom = 0.3 + severity * 0.6
			env.glow_intensity = 1.5 + severity * 1.5
			env.glow_strength = 2.0 + severity * 1.0

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

func reset_camera():
	yaw = 0.0
	vertical_offset = 4.0
	glucose_value = 90.0
	low_symptom_timer = 0.0
	high_symptom_timer = 0.0
	dizziness_offset = Vector2.ZERO
	screen_shake_offset = Vector2.ZERO
	shake_timer = 0.0
	screen_tint = Color.WHITE
	
	fov = original_fov
	rotation.z = 0.0
	
	game_setup_connected = false
	cleanup_visual_effects()
	call_deferred("setup_visual_effects")

func _exit_tree():
	cleanup_visual_effects()
