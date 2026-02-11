# res://scripts/Glucolife/ScriptAnimation/table_food_system.gd
class_name TableFoodSystem
extends Node3D

@export_group("Camera Settings")
@export var camera_zoom_position: Vector3 = Vector3(0, 1.5, 2.0)
@export var camera_zoom_rotation: Vector3 = Vector3(-30, 0, 0)
@export var zoom_duration: float = 1.2

@export_group("Food Settings")
@export var healthy_foods_path: String = "res://special items/healthy foods/"
@export var sugary_foods_path: String = "res://special items/sugary foods/"
@export var foods_displayed: int = 3
@export var food_spacing: float = 0.8
@export var food_scale: float = 0.35

@export_group("UI Settings")
@export var arrow_size: float = 50.0
@export var arrow_margin: float = 20.0

var player: Node3D
var camera: Camera3D
var original_camera_transform: Transform3D
var click_area: Area3D
var food_spawn_point: Node3D

var food_scenes: Array = []
var current_food_indices: Array = []
var current_food_nodes: Array = []
var current_index_offset: int = 0

var ui_canvas: CanvasLayer
var left_arrow: Button
var right_arrow: Button
var exit_button: Button

var is_active := false
var is_animating := false
var tween: Tween

signal food_selected(scene_path: String)

func _ready():
	await get_tree().process_frame
	_find_references()
	_setup_click_area()
	_load_food_scenes()

func _find_references():
	player = get_tree().get_first_node_in_group("player")
	camera = get_viewport().get_camera_3d()
	food_spawn_point = get_node("FoodSpawnPoint")

func _setup_click_area():
	click_area = get_node("TableClickArea")
	click_area.input_event.connect(_on_table_clicked)

func _load_food_scenes():
	food_scenes.clear()

	var healthy_dir := DirAccess.open(healthy_foods_path)
	if healthy_dir:
		healthy_dir.list_dir_begin()
		var file = healthy_dir.get_next()
		while file != "":
			if file.ends_with(".tscn"):
				food_scenes.append(healthy_foods_path + file)
			file = healthy_dir.get_next()

	var sugary_dir := DirAccess.open(sugary_foods_path)
	if sugary_dir:
		sugary_dir.list_dir_begin()
		var file2 = sugary_dir.get_next()
		while file2 != "":
			if file2.ends_with(".tscn"):
				food_scenes.append(sugary_foods_path + file2)
			file2 = sugary_dir.get_next()

	print("Loaded food scenes:", food_scenes)

func _on_table_clicked(_cam, event, _pos, _normal, _idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_active:
			start_food_interaction()

func start_food_interaction():
	if is_animating or food_scenes.is_empty():
		return

	is_active = true
	is_animating = true

	original_camera_transform = camera.global_transform

	await _zoom_camera_to_table()
	await _spawn_random_foods()
	_create_ui()

	is_animating = false

func end_food_interaction():
	if is_animating:
		return

	is_animating = true

	_destroy_ui()
	await _despawn_foods()
	await _zoom_camera_out()

	is_active = false
	is_animating = false

func _zoom_camera_to_table():
	var target_pos = global_position + camera_zoom_position
	var target_rot = Vector3(
		deg_to_rad(camera_zoom_rotation.x),
		deg_to_rad(camera_zoom_rotation.y),
		deg_to_rad(camera_zoom_rotation.z)
	)

	tween = create_tween().set_parallel(true)
	tween.tween_property(camera, "global_position", target_pos, zoom_duration)
	tween.tween_property(camera, "rotation", target_rot, zoom_duration)
	await tween.finished

func _zoom_camera_out():
	tween = create_tween()
	tween.tween_property(camera, "global_transform", original_camera_transform, zoom_duration)
	await tween.finished

func _spawn_random_foods():
	current_food_indices.clear()

	var indices := range(food_scenes.size())
	indices.shuffle()

	for i in range(foods_displayed):
		current_food_indices.append(indices[i])

	await _display_foods()

func _display_foods():
	for f in current_food_nodes:
		if is_instance_valid(f):
			f.queue_free()
	current_food_nodes.clear()

	var start_x = -(foods_displayed - 1) * food_spacing * 0.5

	for i in range(current_food_indices.size()):
		var scene_path = food_scenes[current_food_indices[i]]
		var scene = load(scene_path)
		var food = scene.instantiate()

		food.position = Vector3(start_x + i * food_spacing, 0, 0)
		food.scale = Vector3.ONE * food_scale

		food_spawn_point.add_child(food)
		current_food_nodes.append(food)

		if food.has_signal("food_selected"):
			food.food_selected.connect(_on_food_selected.bind(scene_path))

func _despawn_foods():
	for f in current_food_nodes:
		if is_instance_valid(f):
			f.queue_free()
	current_food_nodes.clear()

func _scroll_foods(direction: int):
	if is_animating:
		return
	is_animating = true

	for i in range(foods_displayed):
		current_food_indices[i] = (current_food_indices[i] + direction) % food_scenes.size()

	await _display_foods()
	is_animating = false

func _create_ui():
	ui_canvas = CanvasLayer.new()
	ui_canvas.layer = 10
	get_tree().root.add_child(ui_canvas)

	left_arrow = Button.new()
	left_arrow.text = "<"
	left_arrow.custom_minimum_size = Vector2(arrow_size, arrow_size)
	left_arrow.position = Vector2(arrow_margin, get_viewport().size.y / 2)
	left_arrow.pressed.connect(func(): _scroll_foods(-1))
	ui_canvas.add_child(left_arrow)

	right_arrow = Button.new()
	right_arrow.text = ">"
	right_arrow.custom_minimum_size = Vector2(arrow_size, arrow_size)
	right_arrow.position = Vector2(get_viewport().size.x - arrow_size - arrow_margin, get_viewport().size.y / 2)
	right_arrow.pressed.connect(func(): _scroll_foods(1))
	ui_canvas.add_child(right_arrow)

	exit_button = Button.new()
	exit_button.text = "X"
	exit_button.custom_minimum_size = Vector2(80, 40)
	exit_button.position = Vector2(get_viewport().size.x / 2 - 40, arrow_margin)
	exit_button.pressed.connect(end_food_interaction)
	ui_canvas.add_child(exit_button)

func _destroy_ui():
	if ui_canvas:
		ui_canvas.queue_free()

func _on_food_selected(scene_path: String):
	print("Food selected:", scene_path)
	food_selected.emit(scene_path)
	end_food_interaction()
