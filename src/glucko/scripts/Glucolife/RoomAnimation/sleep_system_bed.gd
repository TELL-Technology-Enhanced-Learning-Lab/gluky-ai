extends Node3D

@export_group("Animation Timing")
@export var walk_duration: float = 2.5
@export var zoom_duration: float = 2.0
@export var room_darken_duration: float = 3.0
@export var room_brighten_duration: float = 2.5
@export var return_duration: float = 2.5

@export_group("Player Positions")
@export var player_start_position: Vector3 = Vector3(6.965, 1.19, 7.594)
@export var player_start_rotation: Vector3 = Vector3(0.0, 90.0, 0.0)
@export var player_final_position: Vector3 = Vector3(7.403, 1.117, 9.333)
@export var player_final_rotation: Vector3 = Vector3(-75.5, 90.0, 0.0)

@export_group("Visual Effects")
@export var night_darkness_amount: float = 0.85
@export var ambient_night_color: Color = Color(0.05, 0.05, 0.15, 1.0)

@export_group("Camera Cinematic")
@export var pivot_z_offset: float = 2.0
@export var cinematic_y_lift: float = 0.8
@export var cinematic_push_in: float = 1.2

var pivot_position_at_click: Vector3
var pivot_position_final: Vector3

var player: Node3D
var camera: Camera3D
var camera_pivot: Node3D
var original_pivot_transform: Transform3D
var original_camera_local_transform: Transform3D
var player_animation_player: AnimationPlayer
var world_environment: WorldEnvironment
var original_ambient_color: Color
var original_ambient_energy: float

var click_detector: Area3D
var tween: Tween
var darkness_overlay: ColorRect
var overlay_canvas_layer: CanvasLayer
var vignette_overlay: ColorRect

var is_animating: bool = false
var can_interact: bool = true
var is_sleeping: bool = false
var player_was_physics_enabled: bool = false

signal animation_started
signal sleep_started
signal sleep_ended
signal animation_completed

func _ready():
	await get_tree().process_frame
	_find_references()
	_setup_click_detector()

func _exit_tree():
	if tween and tween.is_valid():
		tween.kill()
	_cleanup_overlay()

func _process(_delta):
	if is_sleeping and Input.is_anything_pressed():
		is_sleeping = false

# ---------------------------------------------------------
# RICERCA NODI
# ---------------------------------------------------------

func _find_references():
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_error("Player non trovato nel gruppo 'player'")
		return
	player_animation_player = _find_animation_player(player)
	camera_pivot = get_tree().get_first_node_in_group("camera_pivot")
	if camera_pivot:
		camera = camera_pivot.get_node_or_null("Camera3D")
	if not camera:
		camera = get_viewport().get_camera_3d()
	world_environment = get_tree().get_first_node_in_group("world_environment")
	if not world_environment:
		world_environment = get_viewport().find_child("WorldEnvironment", true, false)
	if world_environment and world_environment.environment:
		original_ambient_energy = world_environment.environment.ambient_light_energy
		original_ambient_color = world_environment.environment.ambient_light_color

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		if child is AnimationPlayer:
			return child
		var result = _find_animation_player(child)
		if result:
			return result
	return null

# ---------------------------------------------------------
# CLICK DETECTOR
# ---------------------------------------------------------

func _setup_click_detector():
	click_detector = get_node_or_null("BedClickArea")
	if not click_detector:
		push_error("BedClickArea non trovata!")
		return
	if not click_detector.input_event.is_connected(_on_click_detector_input):
		click_detector.input_event.connect(_on_click_detector_input)

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not can_interact or is_animating:
			return
		if not camera:
			return
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 100.0
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		var camera_bounds = get_tree().get_first_node_in_group("camera_bounds")
		if camera_bounds:
			query.exclude = [camera_bounds.get_rid()]
		var result = space_state.intersect_ray(query)
		if result and result.collider == click_detector:
			start_sleep_animation()

func _on_click_detector_input(_cam: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _idx: int):
	if not can_interact or is_animating:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		start_sleep_animation()

# ---------------------------------------------------------
# ANIMAZIONE PRINCIPALE
# ---------------------------------------------------------

func start_sleep_animation():
	if is_animating or not player or not camera:
		return

	is_animating = true
	can_interact = false

	original_pivot_transform = camera_pivot.global_transform
	original_camera_local_transform = camera.transform
	pivot_position_at_click = camera_pivot.global_position

	pivot_position_final = Vector3(
		pivot_position_at_click.x,
		pivot_position_at_click.y + cinematic_y_lift,
		pivot_position_at_click.z + pivot_z_offset
	)

	animation_started.emit()

	if camera_pivot and camera_pivot.has_method("set_cinematic_mode"):
		camera_pivot.set_cinematic_mode(true)

	_disable_player_control()
	await _cinematic_sequence()
	_enable_player_control()

	is_animating = false
	can_interact = true
	animation_completed.emit()

func _disable_player_control():
	if player is CharacterBody3D:
		player_was_physics_enabled = player.is_physics_processing()
		player.set_physics_process(false)
	if player_animation_player:
		player_animation_player.stop()
	for child in player.get_children():
		if child is AnimationPlayer:
			child.stop()

func _enable_player_control():
	if player is CharacterBody3D and player_was_physics_enabled:
		player.set_physics_process(true)

# ---------------------------------------------------------
# SEQUENZA CINEMATICA
# ---------------------------------------------------------

func _cinematic_sequence():
	await _phase_0_cinematic_intro()
	await _phase_1_walk_to_bed()
	await _phase_2_lay_down()
	await _phase_3_night_falls()
	await _phase_4_sleep()
	await _phase_5_morning()
	await _phase_6_return()

func _make_tween() -> Tween:
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	return tween

# ---------------------------------------------------------
# FASI
# ---------------------------------------------------------

# INTRO — zoom morbido
func _phase_0_cinematic_intro():
	var intro_pos = Vector3(
		pivot_position_at_click.x,
		pivot_position_at_click.y + 0.3,
		pivot_position_at_click.z + 0.5
	)
	var t = _make_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.tween_property(camera_pivot, "global_position", intro_pos, 1.2)
	await tween.finished
	await get_tree().create_timer(0.3).timeout

# WALK — aggiunta oscillazione handheld
func _apply_subtle_camera_motion():
	var cam_tween = create_tween()
	cam_tween.set_parallel(true)
	cam_tween.set_trans(Tween.TRANS_SINE)
	cam_tween.set_ease(Tween.EASE_IN_OUT)
	cam_tween.tween_property(camera, "rotation_degrees:z", randf_range(-0.4, 0.4), 1.8)
	cam_tween.tween_property(camera, "rotation_degrees:x", randf_range(-0.3, 0.3), 1.8)

func _phase_1_walk_to_bed():
	_apply_subtle_camera_motion()
	var t = _make_tween()
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(camera_pivot, "global_position", pivot_position_final, walk_duration)
	t.tween_property(player, "global_position", player_final_position, walk_duration)
	t.tween_property(player, "rotation_degrees", Vector3(0, 90, 0), walk_duration * 0.3)
	await tween.finished
	await get_tree().create_timer(0.3).timeout

# LAY DOWN — dolly-in + tilt
func _phase_2_lay_down():
	var push_pos = Vector3(
		pivot_position_final.x,
		pivot_position_final.y - 0.3,
		pivot_position_final.z + cinematic_push_in
	)
	var t = _make_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(camera_pivot, "global_position", push_pos, zoom_duration * 1.2)
	t.tween_property(player, "rotation_degrees", player_final_rotation, zoom_duration)
	await tween.finished
	await get_tree().create_timer(0.5).timeout

# NIGHT — vignette + pulse + grading
func _animate_vignette_pulse():
	var pulse = create_tween()
	pulse.set_loops()
	pulse.tween_property(vignette_overlay, "modulate:a", 0.45, 1.2)
	pulse.tween_property(vignette_overlay, "modulate:a", 0.35, 1.2)

func _phase_3_night_falls():
	_create_canvas_layer()
	_create_vignette()
	_create_darkness_overlay()

	var t_vignette = create_tween()
	t_vignette.tween_property(vignette_overlay, "modulate:a", 0.4, 0.8)
	await t_vignette.finished

	_animate_vignette_pulse()

	var night_pos = Vector3(
		pivot_position_final.x,
		pivot_position_final.y + 0.2,
		pivot_position_final.z + cinematic_push_in - 0.3
	)
	var t = _make_tween()
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(camera_pivot, "global_position", night_pos, room_darken_duration)
	if darkness_overlay:
		t.tween_property(darkness_overlay, "modulate:a", night_darkness_amount, room_darken_duration)
	if world_environment and world_environment.environment:
		t.tween_property(world_environment.environment, "ambient_light_energy", 0.1, room_darken_duration)
		t.tween_property(world_environment.environment, "ambient_light_color", ambient_night_color, room_darken_duration)
	await tween.finished

# SLEEP — breathing effect
func _sleep_breathing_effect():
	var breath = create_tween()
	breath.set_loops()
	breath.tween_property(camera_pivot, "global_position:y", camera_pivot.global_position.y + 0.05, 2.5)
	breath.tween_property(camera_pivot, "global_position:y", camera_pivot.global_position.y - 0.05, 2.5)

func _phase_4_sleep():
	sleep_started.emit()
	is_sleeping = true
	_sleep_breathing_effect()
	while is_sleeping:
		await get_tree().create_timer(0.1).timeout
	sleep_ended.emit()
	_update_sleep_stats()

# MORNING — glow + warm grading
func _morning_glow():
	if world_environment and world_environment.environment:
		var t = create_tween()
		t.tween_property(world_environment.environment, "glow_intensity", 0.15, 1.5)
		await t.finished
		var t2 = create_tween()
		t2.tween_property(world_environment.environment, "glow_intensity", 0.0, 1.0)

func _phase_5_morning():
	var morning_pos = Vector3(
		pivot_position_final.x,
		pivot_position_final.y,
		pivot_position_final.z + cinematic_push_in * 0.5
	)
	var t = _make_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.tween_property(camera_pivot, "global_position", morning_pos, room_brighten_duration)
	if darkness_overlay:
		t.tween_property(darkness_overlay, "modulate:a", 0.0, room_brighten_duration)
	if vignette_overlay:
		t.tween_property(vignette_overlay, "modulate:a", 0.0, room_brighten_duration)
	if world_environment and world_environment.environment:
		t.tween_property(world_environment.environment, "ambient_light_energy", original_ambient_energy, room_brighten_duration)
		t.tween_property(world_environment.environment, "ambient_light_color", original_ambient_color, room_brighten_duration)
	await tween.finished
	_cleanup_overlay()
	_morning_glow()
	await get_tree().create_timer(0.5).timeout

# RETURN — camera pulita e stabile
func _phase_6_return():
	var t = _make_tween()
	t.set_trans(Tween.TRANS_QUAD)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(player, "global_position", player_start_position, return_duration)
	t.tween_property(player, "rotation_degrees", player_start_rotation, return_duration)
	t.tween_property(camera_pivot, "global_position", pivot_position_at_click, return_duration)
	await tween.finished

	await get_tree().process_frame
	camera_pivot.global_transform = original_pivot_transform
	camera.transform = original_camera_local_transform

	if camera_pivot and camera_pivot.has_method("set_cinematic_mode"):
		camera_pivot.set_cinematic_mode(false)

# ---------------------------------------------------------
# OVERLAY
# ---------------------------------------------------------

func _create_canvas_layer():
	if overlay_canvas_layer:
		return
	overlay_canvas_layer = CanvasLayer.new()
	overlay_canvas_layer.layer = 50
	overlay_canvas_layer.name = "SleepCanvasLayer"
	get_tree().root.add_child(overlay_canvas_layer)

func _create_vignette():
	vignette_overlay = ColorRect.new()
	vignette_overlay.name = "VignetteOverlay"
	vignette_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
	vignette_overlay.modulate.a = 0.0
	vignette_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_canvas_layer.add_child(vignette_overlay)

func _create_darkness_overlay():
	darkness_overlay = ColorRect.new()
	darkness_overlay.name = "DarknessOverlay"
	darkness_overlay.color = Color(0.02, 0.02, 0.1, 1.0)
	darkness_overlay.modulate.a = 0.0
	darkness_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	darkness_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_canvas_layer.add_child(darkness_overlay)

func _cleanup_overlay():
	if darkness_overlay:
		darkness_overlay.queue_free()
		darkness_overlay = null
	if vignette_overlay:
		vignette_overlay.queue_free()
		vignette_overlay = null
	if overlay_canvas_layer:
		overlay_canvas_layer.queue_free()
		overlay_canvas_layer = null

# ---------------------------------------------------------
# STATS
# ---------------------------------------------------------

func _update_sleep_stats():
	var data_manager = get_node_or_null("/root/GlucolifeDataManager")
	if data_manager and data_manager.has_method("modify_stat"):
		data_manager.modify_stat("energy", 100)
		data_manager.modify_stat("happiness", 20)
		data_manager.modify_stat("hygiene", -10)
