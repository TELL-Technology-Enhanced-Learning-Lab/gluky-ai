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
@export var low_symptom_intensity: float = 5.0
@export var high_symptom_intensity: float = 4.0
@export var low_color_tint: Color = Color(0.4, 0.6, 1.0, 0.9)
@export var high_color_tint: Color = Color(1.0, 0.4, 0.4, 0.9)
@export var max_screen_wobble: float = 15.0
@export var max_fov_change: float = 25.0
@export var max_shake_intensity: float = 8.0

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
var screen_shake_offset: Vector2 = Vector2.ZERO
var shake_timer: float = 0.0
var color_rect: ColorRect
var screen_wobble_timer: float = 0.0
var last_glucose_state: String = "normal"
var game_setup_connected: bool = false
var effect_intensity: float = 0.0

func _ready():
	player = get_parent()
	base_smooth_speed = smooth_speed
	base_mouse_sensitivity = mouse_sensitivity
	original_fov = fov
	
	if OS.has_feature("mobile"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	create_visual_overlay()
	
	await get_tree().create_timer(0.1).timeout
	setup_game_setup_connection()

func create_visual_overlay():
	color_rect = ColorRect.new()
	color_rect.name = "GlucoseOverlay"
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.color = Color(1, 0, 0, 0)
	color_rect.show_behind_parent = true
	
	var viewport = get_viewport()
	if viewport:
		viewport.add_child.call_deferred(color_rect)
		color_rect.set_anchors_preset(Control.PRESET_FULL_RECT, true)

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

func set_glucose(value: float):
	glucose_value = value

func _input(event):
	var sensitivity_mod = 1.0
	if glucose_value < low_glucose_threshold:
		sensitivity_mod = lerp(0.3, 1.0, (glucose_value - 40.0) / 30.0)
	elif glucose_value > high_glucose_threshold:
		sensitivity_mod = lerp(1.0, 0.3, min((glucose_value - 180.0) / 100.0, 1.0))
	
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
	update_visual_effects(delta)
	
	var player_pos = player.global_position
	var camera_target = player_pos + Vector3(0, vertical_offset, 0)
	
	if screen_shake_offset.length() > 0.001:
		camera_target.x += screen_shake_offset.x * 0.8
		camera_target.z += screen_shake_offset.y * 0.8
	
	var yaw_with_dizziness = yaw
	
	if glucose_value < low_glucose_threshold:
		effect_intensity = clamp((low_glucose_threshold - glucose_value) / 30.0, 0.0, 1.0)
		var intensity = effect_intensity * low_symptom_intensity
		
		dizziness_offset = dizziness_offset.lerp(
			Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity,
			delta * 3.0
		)
		yaw_with_dizziness += dizziness_offset.x * 0.4
		camera_target.y += dizziness_offset.y * 0.5
		
		screen_wobble_timer += delta * 4.0
		var wobble = sin(screen_wobble_timer * 2.5) * intensity * max_screen_wobble
		var wobble2 = cos(screen_wobble_timer * 1.8) * intensity * max_screen_wobble * 0.7
		rotation.z = deg_to_rad(wobble)
		rotation.x = deg_to_rad(wobble2 * 0.3)
	
	elif glucose_value > high_glucose_threshold:
		effect_intensity = clamp((glucose_value - high_glucose_threshold) / 100.0, 0.0, 1.0)
		var intensity = effect_intensity * high_symptom_intensity
		var t = Time.get_ticks_msec() / 1000.0
		
		dizziness_offset = dizziness_offset.lerp(
			Vector2(sin(t * 4.0) * intensity, cos(t * 3.5) * intensity),
			delta * 2.5
		)
		yaw_with_dizziness += dizziness_offset.x * 0.25
		camera_target.y += dizziness_offset.y * 0.3
		
		screen_wobble_timer += delta * 3.0
		var pulse_wobble = sin(screen_wobble_timer * 4.0) * intensity * max_screen_wobble
		var pulse_wobble2 = cos(screen_wobble_timer * 3.2) * intensity * max_screen_wobble * 0.5
		rotation.z = deg_to_rad(pulse_wobble)
		rotation.x = deg_to_rad(pulse_wobble2 * 0.2)
	
	else:
		rotation.z = lerp_angle(rotation.z, 0.0, delta * 4.0)
		rotation.x = lerp_angle(rotation.x, 0.0, delta * 4.0)
		screen_wobble_timer = 0.0
		effect_intensity = lerp(effect_intensity, 0.0, delta * 3.0)

	var desired_offset = Vector3(0, 0, camera_distance).rotated(Vector3.UP, yaw_with_dizziness)
	actual_camera_distance = check_camera_collision(camera_target, desired_offset)
	var final_position = camera_target + desired_offset.normalized() * actual_camera_distance
	final_position = ensure_minimum_height(final_position, player_pos)
	
	var current_smooth_speed = smooth_speed
	if glucose_value > high_glucose_threshold:
		current_smooth_speed = lerp(base_smooth_speed, base_smooth_speed * 0.2, min((glucose_value - 180.0) / 100.0, 1.0))
	
	global_position = global_position.lerp(final_position, current_smooth_speed * delta)
	look_at(player_pos + Vector3(0, 1, 0), Vector3.UP)

func update_symptoms(delta):
	if glucose_value < low_glucose_threshold:
		low_symptom_timer += delta
		high_symptom_timer = 0.0
		if glucose_value < 50.0:
			shake_timer += delta * 4.0
	elif glucose_value > high_glucose_threshold:
		high_symptom_timer += delta
		low_symptom_timer = 0.0
		if glucose_value > 250.0:
			shake_timer += delta * 1.5
	else:
		low_symptom_timer = max(low_symptom_timer - delta * 2.0, 0.0)
		high_symptom_timer = max(high_symptom_timer - delta * 2.0, 0.0)
		shake_timer = max(shake_timer - delta * 5.0, 0.0)

func update_screen_shake(delta):
	if shake_timer > 0.0:
		var shake_intensity = 0.0
		if glucose_value < low_glucose_threshold:
			shake_intensity = clamp((low_glucose_threshold - glucose_value) / 30.0, 0.0, 1.0) * max_shake_intensity
		elif glucose_value > high_glucose_threshold:
			shake_intensity = clamp((glucose_value - high_glucose_threshold) / 100.0, 0.0, 1.0) * max_shake_intensity * 0.5
		
		var time = Time.get_ticks_msec() / 1000.0
		screen_shake_offset.x = sin(time * 25.0 + 0.0) * 1.5 * shake_intensity
		screen_shake_offset.y = cos(time * 22.0 + 1.0) * 1.5 * shake_intensity
	else:
		screen_shake_offset = screen_shake_offset.lerp(Vector2.ZERO, delta * 4.0)

func update_visual_effects(delta):
	if not color_rect:
		return
	
	if glucose_value < low_glucose_threshold:
		var severity = clamp((low_glucose_threshold - glucose_value) / 30.0, 0.0, 1.0)
		
		var pulse = sin(low_symptom_timer * 4.0) * 0.2 + 0.8
		var current_color = low_color_tint
		current_color.a = severity * 0.9 * pulse
		
		current_color.r = lerp(current_color.r, 0.5, severity * 0.5)
		current_color.g = lerp(current_color.g, 0.5, severity * 0.5)
		current_color.b = lerp(current_color.b, 0.5, severity * 0.5)
		
		color_rect.color = color_rect.color.lerp(current_color, delta * 6.0)
		
		var tunnel_vision = severity * max_fov_change * 1.5
		var fov_pulse = sin(low_symptom_timer * 5.0) * 15.0 * severity
		fov = original_fov + tunnel_vision + fov_pulse
		
	elif glucose_value > high_glucose_threshold:
		var severity = clamp((glucose_value - high_glucose_threshold) / 100.0, 0.0, 1.0)
		
		var throb = sin(high_symptom_timer * 5.0) * 0.3 + 0.7
		var current_color = high_color_tint
		current_color.a = severity * 0.85 * throb
		
		var sat_factor = 1.0 + severity * 0.8
		current_color.r = min(current_color.r * sat_factor, 1.0)
		current_color.g = current_color.g / sat_factor
		current_color.b = current_color.b / sat_factor
		
		color_rect.color = color_rect.color.lerp(current_color, delta * 6.0)
		
		var narrow_vision = severity * max_fov_change * 0.8
		fov = lerp(fov, original_fov - narrow_vision, delta * 6.0)
		
	else:
		color_rect.color = color_rect.color.lerp(Color(1, 0, 0, 0), delta * 5.0)
		fov = lerp(fov, original_fov, delta * 4.0)

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
	screen_wobble_timer = 0.0
	effect_intensity = 0.0
	
	fov = original_fov
	rotation.z = 0.0
	rotation.x = 0.0
	
	if color_rect:
		color_rect.color = Color(1, 0, 0, 0)
	
	game_setup_connected = false

func _exit_tree():
	if color_rect and color_rect.is_inside_tree():
		color_rect.queue_free()
