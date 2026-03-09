extends Node3D

var player: Node3D
var camera: Camera3D
var bathtub: Node3D
var bathtub_click_area: Area3D
var bathtub_node: MeshInstance3D

var tween: Tween
var is_animating: bool = false
var can_interact: bool = true
var player_in_bath: bool = false

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
	_connect_signals()

func _find_references():
	player = get_tree().get_first_node_in_group("player")
	camera = get_viewport().get_camera_3d()
	bathtub = get_tree().root.find_child("Bathtub", true, false)
	
	if bathtub:
		for child in bathtub.get_children():
			if child is Area3D:
				bathtub_click_area = child
			if child is MeshInstance3D and child.name == "bath_water":
				bathtub_node = bathtub

func _connect_signals():
	if bathtub_click_area:
		if not bathtub_click_area.input_event.is_connected(_on_bathtub_clicked):
			bathtub_click_area.input_event.connect(_on_bathtub_clicked)
	
	if bathtub_node:
		if bathtub_node.has_signal("entered_bathtub"):
			if not bathtub_node.entered_bathtub.is_connected(_on_entered_bathtub):
				bathtub_node.entered_bathtub.connect(_on_entered_bathtub)
			
		if bathtub_node.has_signal("exited_bathtub"):
			if not bathtub_node.exited_bathtub.is_connected(_on_exit_from_bathtub):
				bathtub_node.exited_bathtub.connect(_on_exit_from_bathtub)

func _on_bathtub_clicked(_cam, event, _pos, _normal, _idx):
	if not can_interact or is_animating:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not player_in_bath:
			start_enter_animation()

func _on_entered_bathtub():
	# Aggiorna lo stato nella click area
	if bathtub_click_area and bathtub_click_area.has_method("set_player_in_bath"):
		bathtub_click_area.set_player_in_bath(true)

func _on_exit_from_bathtub():
	if player_in_bath:
		start_exit_animation()

func start_enter_animation():
	if is_animating or not player:
		return

	is_animating = true
	can_interact = false

	player_original_position = player.global_position
	player_original_rotation = player.rotation_degrees
	player_original_scale = player.scale

	_disable_player_control()
	await _enter_bath_sequence()
	_enable_player_control()

	is_animating = false
	can_interact = true
	player_in_bath = true
	
	if bathtub_node and bathtub_node.has_signal("entered_bathtub"):
		bathtub_node.entered_bathtub.emit()

func start_exit_animation():
	if is_animating or not player:
		return

	is_animating = true
	can_interact = false
	player_in_bath = false

	# Aggiorna lo stato nella click area
	if bathtub_click_area and bathtub_click_area.has_method("set_player_in_bath"):
		bathtub_click_area.set_player_in_bath(false)

	_disable_player_control()
	await _exit_bath_sequence()
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

func _enter_bath_sequence():
	var t = _make_tween()
	t.tween_property(player, "global_position", player_bath_position, walk_duration)
	t.tween_property(player, "rotation_degrees", player_bath_rotation, walk_duration)
	t.tween_property(player, "scale", player_bath_scale, walk_duration)
	await tween.finished

func _exit_bath_sequence():
	var t = _make_tween()
	t.tween_property(player, "global_position", player_original_position, return_duration)
	t.tween_property(player, "rotation_degrees", player_original_rotation, return_duration)
	t.tween_property(player, "scale", player_original_scale, return_duration)
	await tween.finished
