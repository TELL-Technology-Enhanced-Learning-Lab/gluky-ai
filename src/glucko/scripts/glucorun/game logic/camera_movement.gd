extends Camera3D

@export var mouse_sensitivity: float = 0.003
@export var touch_sensitivity: float = 0.004
@export var min_vertical_offset: float = 2.0
@export var max_vertical_offset: float = 6.0
@export var camera_distance: float = 5.0
@export var vertical_sensitivity: float = 0.02
@export var smooth_speed: float = 8.0
@export var collision_margin: float = 0.3
@export var min_camera_height: float = 0.5
@export var low_glucose_threshold: float = 70.0
@export var high_glucose_threshold: float = 180.0
@export var low_symptom_intensity: float = 5.0
@export var high_symptom_intensity: float = 4.0
@export var low_color_tint: Color = Color(0.4, 0.6, 1.0, 0.9)
@export var high_color_tint: Color = Color(1.0, 0.4, 0.4, 0.9)
@export var max_fov_change: float = 25.0

var yaw := 0.0
var vertical_offset := 4.0
var player: CharacterBody3D
var actual_camera_distance := 0.0
var glucose_value := 90.0
var base_smooth_speed := 0.0
var base_mouse_sensitivity := 0.0
var dizziness_offset := Vector2.ZERO
var original_fov := 0.0
var screen_shake_offset := Vector2.ZERO
var shake_timer := 0.0
var color_rect: ColorRect
var effect_intensity := 0.0
var _is_mobile := false
var look_joystick: Node
var look_joystick_connected := false
var game_setup_node: Node

func _ready():
	_is_mobile = OS.get_name() == "Android" or OS.get_name() == "iOS" or DisplayServer.is_touchscreen_available()
	player = get_parent()
	base_smooth_speed = smooth_speed
	base_mouse_sensitivity = mouse_sensitivity
	original_fov = fov

	if _is_mobile:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	create_visual_overlay()
	await get_tree().process_frame
	find_game_setup_node()

func create_visual_overlay():
	color_rect = ColorRect.new()
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.color = Color.TRANSPARENT
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)

	var canvas = CanvasLayer.new()
	canvas.layer = 100

	get_tree().current_scene.add_child.call_deferred(canvas)
	canvas.add_child.call_deferred(color_rect)

func find_game_setup_node():
	for node in get_tree().root.find_children("*", "", true, false):
		if node.has_signal("glucose_updated"):
			game_setup_node = node
			node.connect("glucose_updated", _on_glucose_updated)
			return

func _on_glucose_updated(value: float):
	glucose_value = value
	if glucose_value >= low_glucose_threshold and glucose_value <= high_glucose_threshold:
		reset_visual_effects()

func reset_visual_effects():
	effect_intensity = 0.0
	dizziness_offset = Vector2.ZERO
	screen_shake_offset = Vector2.ZERO
	shake_timer = 0.0
	if color_rect:
		color_rect.color = Color.TRANSPARENT
	fov = original_fov

func _input(event):
	if _is_mobile:
		return

	if event is InputEventMouseMotion:
		var sensitivity_mod := get_sensitivity_modifier()
		yaw -= event.relative.x * mouse_sensitivity * sensitivity_mod
		vertical_offset = clamp(
			vertical_offset - event.relative.y * vertical_sensitivity * sensitivity_mod,
			min_vertical_offset,
			max_vertical_offset
		)

func _physics_process(delta):
	if not player:
		return

	update_visual_effects(delta)

	var player_pos = player.global_position
	var camera_target = player_pos + Vector3(0, vertical_offset, 0)

	var yaw_mod = yaw
	if glucose_value < low_glucose_threshold:
		effect_intensity = clamp((low_glucose_threshold - glucose_value) / 30.0, 0.0, 1.0)
		dizziness_offset = dizziness_offset.lerp(
			Vector2(randf_range(-1,1), randf_range(-1,1)) * effect_intensity * low_symptom_intensity,
			delta * 3.0
		)
		yaw_mod += dizziness_offset.x * 0.4
		camera_target.y += dizziness_offset.y * 0.5
	elif glucose_value > high_glucose_threshold:
		effect_intensity = clamp((glucose_value - high_glucose_threshold) / 100.0, 0.0, 1.0)
		var t = Time.get_ticks_msec() / 1000.0
		dizziness_offset = dizziness_offset.lerp(
			Vector2(sin(t * 4.0), cos(t * 3.5)) * effect_intensity * high_symptom_intensity,
			delta * 2.5
		)
		yaw_mod += dizziness_offset.x * 0.25
		camera_target.y += dizziness_offset.y * 0.3

	var desired_offset = Vector3(0,0,camera_distance).rotated(Vector3.UP, yaw_mod)
	actual_camera_distance = check_camera_collision(camera_target, desired_offset)
	var final_position = camera_target + desired_offset.normalized() * actual_camera_distance
	final_position = ensure_minimum_height(final_position, player_pos)

	global_position = global_position.lerp(final_position, smooth_speed * delta)
	look_at(player_pos + Vector3(0,1,0), Vector3.UP)

func update_visual_effects(delta):
	if not color_rect:
		return

	if glucose_value < low_glucose_threshold:
		var severity = clamp((low_glucose_threshold - glucose_value) / 30.0, 0.0, 1.0)
		var c = low_color_tint
		c.a = severity * 0.8
		color_rect.color = color_rect.color.lerp(c, delta * 6.0)
		fov = lerp(fov, original_fov + max_fov_change * severity, delta * 4.0)

	elif glucose_value > high_glucose_threshold:
		var severity = clamp((glucose_value - high_glucose_threshold) / 100.0, 0.0, 1.0)
		var c = high_color_tint
		c.a = severity * 0.8
		color_rect.color = color_rect.color.lerp(c, delta * 6.0)
		fov = lerp(fov, original_fov - max_fov_change * severity * 0.5, delta * 4.0)

	else:
		color_rect.color = color_rect.color.lerp(Color.TRANSPARENT, delta * 5.0)
		fov = lerp(fov, original_fov, delta * 4.0)

func get_sensitivity_modifier() -> float:
	if glucose_value < low_glucose_threshold:
		return lerp(0.3, 1.0, (glucose_value - 40.0) / 30.0)
	elif glucose_value > high_glucose_threshold:
		return lerp(1.0, 0.3, min((glucose_value - 180.0) / 100.0, 1.0))
	return 1.0

func check_camera_collision(camera_target: Vector3, desired_offset: Vector3) -> float:
	var space_state = get_world_3d().direct_space_state
	var max_distance = desired_offset.length()
	var direction = desired_offset.normalized()
	var query = PhysicsRayQueryParameters3D.create(
		camera_target,
		camera_target + direction * max_distance
	)
	query.exclude = [player]
	var collision = space_state.intersect_ray(query)
	if collision:
		return camera_target.distance_to(collision.position)
	return max_distance

func ensure_minimum_height(camera_position: Vector3, player_pos: Vector3) -> Vector3:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		Vector3(camera_position.x, player_pos.y + 5.0, camera_position.z),
		Vector3(camera_position.x, player_pos.y - 10.0, camera_position.z)
	)
	var hit = space_state.intersect_ray(query)
	if hit:
		var desired = hit.position.y + min_camera_height
		if camera_position.y < desired:
			camera_position.y = desired
	return camera_position
