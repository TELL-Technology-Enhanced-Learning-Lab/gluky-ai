# res://scripts/Glucolife/ScriptAnimation/bed_green_2.gd
# COLLEGARE A: bed_green2 (nodo del letto dentro Forniture)
class_name BedAnimationController
extends Node3D

@export_group("Animation Timing")
@export var simultaneous_movement_duration: float = 3.0
@export var final_adjustment_duration: float = 2.0
@export var room_darken_duration: float = 2.5
@export var room_brighten_duration: float = 2.0
@export var return_duration: float = 2.0

@export_group("Player Positions - EXACT")
@export var player_start_position: Vector3 = Vector3(6.965, 1.19, 7.594)
@export var player_start_rotation: Vector3 = Vector3(0.0, 90.0, 0.0)
@export var player_final_position: Vector3 = Vector3(7.3, 1.19, 9.311)
@export var player_final_rotation: Vector3 = Vector3(-79.5, 90.0, 0.0)

@export_group("Camera Positions - EXACT")
@export var camera_initial_offset: Vector3 = Vector3(2.5, 2.0, 2.0)
@export var camera_final_position: Vector3 = Vector3(9.428, 2.951, 9.994)
@export var camera_final_rotation: Vector3 = Vector3(-18.1, 90.0, -0.3)
@export var camera_return_position: Vector3 = Vector3(12.367, 2.951, 9.301)
@export var camera_return_rotation: Vector3 = Vector3(-18.1, 90.0, -0.3)

@export_group("Visual Effects")
@export var night_darkness_amount: float = 0.85
@export var ambient_night_color: Color = Color(0.05, 0.05, 0.15, 1.0)

var player: Node3D
var camera: Camera3D
var original_camera_position: Vector3
var original_camera_rotation: Vector3
var player_animation_player: AnimationPlayer
var world_environment: WorldEnvironment
var original_ambient_color: Color
var original_ambient_energy: float

var click_detector: Area3D
var tween: Tween
var darkness_overlay: ColorRect
var overlay_canvas_layer: CanvasLayer

var is_animating: bool = false
var can_interact: bool = true
var is_sleeping: bool = false
var player_was_physics_enabled: bool = false

signal animation_started
signal sleep_started
signal sleep_ended
signal animation_completed

func _ready():
	print("=== BED ANIMATION SYSTEM INITIALIZED ===")
	await get_tree().process_frame
	_find_references()
	_setup_click_detector()
	
	if camera:
		original_camera_position = camera.global_position
		original_camera_rotation = camera.rotation_degrees

func _process(_delta):
	if is_sleeping and Input.is_anything_pressed():
		print("Player wakes up")
		is_sleeping = false

func _find_references():
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_error("CRITICAL: Player not found in group 'player'")
		return
	print("Player found: " + player.name)
	
	player_animation_player = _find_animation_player(player)
	if player_animation_player:
		print("AnimationPlayer found: " + player_animation_player.name)
	
	camera = get_viewport().get_camera_3d()
	if not camera:
		push_error("CRITICAL: Camera not found")
		return
	print("Camera found")
	
	world_environment = get_tree().get_first_node_in_group("world_environment")
	if not world_environment:
		world_environment = get_viewport().find_child("WorldEnvironment", true, false)
	
	if world_environment and world_environment.environment:
		original_ambient_energy = world_environment.environment.ambient_light_energy
		original_ambient_color = world_environment.environment.ambient_light_color
		print("WorldEnvironment found")
	else:
		print("WARNING: WorldEnvironment not found - lighting effects disabled")

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

func _setup_click_detector():
	click_detector = get_node_or_null("BedClickArea")
	if not click_detector:
		push_error("CRITICAL: BedClickArea not found as child of bed_green2")
		return
	
	print("BedClickArea found")
	if not click_detector.input_event.is_connected(_on_click_detector_input):
		click_detector.input_event.connect(_on_click_detector_input)
		print("Click system active - Ready to sleep")

func _on_click_detector_input(_cam: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _idx: int):
	if not can_interact or is_animating:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("\n=== BED CLICKED - STARTING CINEMATIC ===")
			start_sleep_animation()

func start_sleep_animation():
	if is_animating or not player or not camera:
		return
	
	print("CINEMATIC SEQUENCE START")
	is_animating = true
	can_interact = false
	animation_started.emit()
	
	_disable_player_control()
	await _cinematic_sequence()
	_enable_player_control()
	
	is_animating = false
	can_interact = true
	animation_completed.emit()
	print("=== SEQUENCE COMPLETED ===\n")

func _disable_player_control():
	if player is CharacterBody3D:
		player_was_physics_enabled = player.is_physics_processing()
		player.set_physics_process(false)
	
	if player_animation_player:
		player_animation_player.stop()
	
	for child in player.get_children():
		if child is AnimationPlayer:
			child.stop()
	
	print("Player controls disabled")

func _enable_player_control():
	if player is CharacterBody3D and player_was_physics_enabled:
		player.set_physics_process(true)
	
	print("Player controls enabled")

func _cinematic_sequence():
	print("PHASE 1: Cinematic movement")
	await _phase_1_cinematic_movement()
	
	print("PHASE 2: Final positioning")
	await _phase_2_final_positioning()
	
	print("PHASE 3: Night falls")
	await _phase_3_night_falls()
	
	print("PHASE 4: Sleeping - press any key to wake up")
	await _phase_4_sleep()
	
	print("PHASE 5: Morning")
	await _phase_5_morning()
	
	print("PHASE 6: Return to start position")
	await _phase_6_return()

func _phase_1_cinematic_movement():
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(player, "global_position", player_final_position, simultaneous_movement_duration)
	tween.tween_property(player, "rotation_degrees", player_final_rotation, simultaneous_movement_duration)
	tween.tween_property(camera, "global_position", camera_final_position, simultaneous_movement_duration)
	
	var cam_rot_rad = Vector3(
		deg_to_rad(camera_final_rotation.x),
		deg_to_rad(camera_final_rotation.y),
		deg_to_rad(camera_final_rotation.z)
	)
	tween.tween_property(camera, "rotation", cam_rot_rad, simultaneous_movement_duration)
	
	await tween.finished
	
	if player_animation_player:
		player_animation_player.stop()
	await get_tree().create_timer(0.3).timeout

func _phase_2_final_positioning():
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	tween.tween_property(player, "global_position", player_final_position, final_adjustment_duration)
	tween.tween_property(player, "rotation_degrees", player_final_rotation, final_adjustment_duration)
	tween.tween_property(camera, "global_position", camera_final_position, final_adjustment_duration)
	
	var cam_rot_rad = Vector3(
		deg_to_rad(camera_final_rotation.x),
		deg_to_rad(camera_final_rotation.y),
		deg_to_rad(camera_final_rotation.z)
	)
	tween.tween_property(camera, "rotation", cam_rot_rad, final_adjustment_duration)
	
	await tween.finished
	await get_tree().create_timer(0.5).timeout

func _phase_3_night_falls():
	_create_darkness_overlay()
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	if darkness_overlay:
		tween.tween_property(darkness_overlay, "modulate:a", night_darkness_amount, room_darken_duration)
	
	if world_environment and world_environment.environment:
		tween.tween_property(world_environment.environment, "ambient_light_energy", 0.1, room_darken_duration)
		tween.tween_property(world_environment.environment, "ambient_light_color", ambient_night_color, room_darken_duration)
	
	await tween.finished

func _phase_4_sleep():
	sleep_started.emit()
	is_sleeping = true
	
	print("Sleeping... press any key to wake up")
	
	while is_sleeping:
		await get_tree().create_timer(0.1).timeout
	
	sleep_ended.emit()
	_update_sleep_stats()

func _phase_5_morning():
	print("Good morning")
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	if darkness_overlay:
		tween.tween_property(darkness_overlay, "modulate:a", 0.0, room_brighten_duration)
	
	if world_environment and world_environment.environment:
		tween.tween_property(world_environment.environment, "ambient_light_energy", original_ambient_energy, room_brighten_duration)
		tween.tween_property(world_environment.environment, "ambient_light_color", original_ambient_color, room_brighten_duration)
	
	await tween.finished
	_cleanup_overlay()
	await get_tree().create_timer(0.5).timeout

func _phase_6_return():
	# Ritorna alla posizione ESATTA di partenza
	print("Returning to start position: " + str(player_start_position))
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	
	# Player torna a (6.965, 1.19, 7.594) con rotazione (0.0, 90.0, 0.0)
	tween.tween_property(player, "global_position", player_start_position, return_duration)
	tween.tween_property(player, "rotation_degrees", player_start_rotation, return_duration)
	
	# Camera torna alla posizione di ritorno
	tween.tween_property(camera, "global_position", camera_return_position, return_duration)
	
	var cam_return_rot_rad = Vector3(
		deg_to_rad(camera_return_rotation.x),
		deg_to_rad(camera_return_rotation.y),
		deg_to_rad(camera_return_rotation.z)
	)
	tween.tween_property(camera, "rotation", cam_return_rot_rad, return_duration)
	
	await tween.finished
	
	print("EXACT Player position: " + str(player.global_position))
	print("EXACT Player rotation: " + str(player.rotation_degrees))
	print("EXACT Camera position: " + str(camera.global_position))

func _create_darkness_overlay():
	overlay_canvas_layer = CanvasLayer.new()
	overlay_canvas_layer.layer = 50
	overlay_canvas_layer.name = "SleepCanvasLayer"
	get_tree().root.add_child(overlay_canvas_layer)
	
	darkness_overlay = ColorRect.new()
	darkness_overlay.name = "DarknessOverlay"
	darkness_overlay.color = Color(0.02, 0.02, 0.1, 1.0)
	darkness_overlay.modulate.a = 0.0
	darkness_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	darkness_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	darkness_overlay.z_index = 50
	
	overlay_canvas_layer.add_child(darkness_overlay)

func _cleanup_overlay():
	if is_instance_valid(darkness_overlay):
		darkness_overlay.queue_free()
		darkness_overlay = null
	
	if is_instance_valid(overlay_canvas_layer):
		overlay_canvas_layer.queue_free()
		overlay_canvas_layer = null

func _update_sleep_stats():
	var data_manager = get_node_or_null("/root/GlucolifeDataManager")
	if data_manager and data_manager.has_method("modify_stat"):
		data_manager.modify_stat("energy", 100)
		data_manager.modify_stat("happiness", 20)
		data_manager.modify_stat("hygiene", -10)
		print("Stats updated: Energy +100, Happiness +20, Hygiene -10")
	else:
		print("Stats system not available")
