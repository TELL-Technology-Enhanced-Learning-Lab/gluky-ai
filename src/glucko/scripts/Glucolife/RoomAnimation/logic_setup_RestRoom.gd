extends Node3D

var player: Node3D
var camera: Camera3D
var camera_pivot: Node3D
var bathtub: Node3D
var bathtub_click_detector: Area3D

var tween: Tween
var is_animating: bool = false
var can_interact: bool = true
var waiting_for_exit_click: bool = false

var player_original_position: Vector3
var player_original_rotation: Vector3
var player_original_scale: Vector3

@export_group("Animation Timing")
@export var walk_duration: float = 2.5
@export var return_duration: float = 2.5

@export_group("Player Bath Transform")
@export var player_bath_position: Vector3 = Vector3(15.81, 1.5, 3.124)
@export var player_bath_rotation: Vector3 = Vector3(0.0, -90.0, 0.0)
@export var player_bath_scale: Vector3 = Vector3(2.0, 2.0, 2.0)

func _ready():
	await get_tree().process_frame
	_find_references()
	_setup_click_detector()

func _exit_tree():
	if tween and tween.is_valid():
		tween.kill()

func _find_references():
	player = get_tree().get_first_node_in_group("player")
	camera_pivot = get_tree().get_first_node_in_group("camera_pivot")
	if camera_pivot:
		camera = camera_pivot.get_node_or_null("Camera3D")
	if not camera:
		camera = get_viewport().get_camera_3d()
	bathtub = find_child("bath", true, false)
	if not bathtub:
		bathtub = find_child("Bathtub", true, false)
	if not bathtub:
		bathtub = find_child("Bath", true, false)

func _setup_click_detector():
	if bathtub:
		for child in bathtub.get_children():
			if child is Area3D:
				bathtub_click_detector = child
				break
	if not bathtub_click_detector:
		bathtub_click_detector = find_child("BathtubClickArea", true, false)
	if not bathtub_click_detector:
		bathtub_click_detector = find_child("BathClickArea", true, false)
	if not bathtub_click_detector:
		bathtub_click_detector = find_child("ClickArea", true, false)

	if bathtub_click_detector:
		if not bathtub_click_detector.input_event.is_connected(_on_bathtub_clicked):
			bathtub_click_detector.input_event.connect(_on_bathtub_clicked)
	else:
		push_error("BathtubClickArea non trovata!")

func _input(event: InputEvent):
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	if waiting_for_exit_click:
		waiting_for_exit_click = false
		return

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
	else:
		var cb = get_tree().root.find_child("CameraBounds", true, false)
		if cb:
			query.exclude = [cb.get_rid()]

	var result = space_state.intersect_ray(query)
	if result and bathtub_click_detector and result.collider == bathtub_click_detector:
		start_bath_animation()

func _on_bathtub_clicked(_cam, event, _pos, _normal, _idx):
	if not can_interact or is_animating:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		start_bath_animation()

func start_bath_animation():
	if is_animating or not player or not camera:
		return

	is_animating = true
	can_interact = false

	player_original_position = player.global_position
	player_original_rotation = player.rotation_degrees
	player_original_scale = player.scale

	_disable_player_control()
	await _bath_sequence()
	_enable_player_control()

	is_animating = false
	can_interact = true

func _disable_player_control():
	if player is CharacterBody3D:
		player.set_physics_process(false)
	for child in player.get_children():
		if child is AnimationPlayer:
			child.stop()

func _enable_player_control():
	if player is CharacterBody3D:
		player.set_physics_process(true)

func _make_tween() -> Tween:
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	return tween

func _bath_sequence():
	await _phase_1_walk_to_bath()
	await _phase_2_wait_for_click()
	await _phase_3_return()

func _phase_1_walk_to_bath():
	var t = _make_tween()
	t.tween_property(player, "global_position", player_bath_position, walk_duration)
	t.tween_property(player, "rotation_degrees", player_bath_rotation, walk_duration)
	t.tween_property(player, "scale", player_bath_scale, walk_duration)
	await tween.finished
	await get_tree().create_timer(0.3).timeout

func _phase_2_wait_for_click():
	_update_bath_stats()
	waiting_for_exit_click = true
	while waiting_for_exit_click:
		await get_tree().process_frame

func _phase_3_return():
	var t = _make_tween()
	t.tween_property(player, "global_position", player_original_position, return_duration)
	t.tween_property(player, "rotation_degrees", player_original_rotation, return_duration)
	t.tween_property(player, "scale", player_original_scale, return_duration)
	await tween.finished

func _update_bath_stats():
	var data_manager = get_node_or_null("/root/GlucolifeDataManager")
	if data_manager and data_manager.has_method("modify_stat"):
		data_manager.modify_stat("hygiene", 30)
		data_manager.modify_stat("happiness", 10)
