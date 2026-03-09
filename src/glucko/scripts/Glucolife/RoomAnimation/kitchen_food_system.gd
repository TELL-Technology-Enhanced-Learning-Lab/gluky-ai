extends Node3D

@export_group("Camera Settings")
@export var zoom_duration: float = 1.2

@export_group("Food Settings")
@export var foods_displayed: int = 3
@export var food_spacing: float = 0.8
@export var food_scale: float = 0.35

@export_group("UI Settings")
@export var arrow_size: float = 50.0
@export var arrow_margin: float = 20.0

var player: Node3D
var camera: Camera3D
var camera_pivot: Node3D
var original_pivot_transform: Transform3D
var original_camera_transform: Transform3D
var click_area: Area3D
var food_spawn_point: Node3D

var healthy_food_scenes: Array = []
var sugary_food_scenes: Array = []
var all_food_scenes: Array = []

var current_food_indices: Array = []
var current_food_nodes: Array = []

var ui_canvas: CanvasLayer
var left_arrow: Button
var right_arrow: Button
var exit_button: Button

var is_active := false
var is_animating := false
var tween: Tween
var can_interact_with_table := true

var meal_label: Label3D

signal food_selected(scene_path: String)
signal food_selected_packed(scene: PackedScene)

func _ready():
	await get_tree().process_frame
	_find_references()
	_setup_click_area()
	_load_foods_from_database()
	_find_meal_label()
	_update_table_interaction_status()
	_update_meal_label_text()

func _exit_tree():
	if tween and tween.is_valid():
		tween.kill()
	if ui_canvas and is_instance_valid(ui_canvas):
		ui_canvas.queue_free()
	for food_node in current_food_nodes:
		if is_instance_valid(food_node):
			food_node.queue_free()
	current_food_nodes.clear()

func _find_references():
	player = get_tree().get_first_node_in_group("player")
	camera_pivot = get_tree().get_first_node_in_group("camera_pivot")
	if camera_pivot:
		camera = camera_pivot.get_node_or_null("Camera3D")
	if not camera:
		camera = get_viewport().get_camera_3d()
	food_spawn_point = get_node_or_null("FoodSpawnPoint")

func _setup_click_area():
	click_area = get_node_or_null("TableClickArea")
	if click_area:
		click_area.input_event.connect(_on_table_clicked)

func _find_meal_label():
	meal_label = get_node_or_null("mealLabel")
	if meal_label:
		meal_label.text = ""

func _load_foods_from_database():
	if not FoodDatabase or not FoodDatabase.food_database:
		return
	var food_resource = FoodDatabase.food_database
	if "healthy_foods" in food_resource:
		healthy_food_scenes = food_resource.healthy_foods
	if "sugary_foods" in food_resource:
		sugary_food_scenes = food_resource.sugary_foods
	all_food_scenes = healthy_food_scenes + sugary_food_scenes

func _update_table_interaction_status():
	var current_meal_type = _get_current_meal_type()
	can_interact_with_table = GlucolifeDataManager.can_eat_meal(current_meal_type)
	
	if click_area and click_area.has_method("set_interaction_message"):
		if can_interact_with_table:
			click_area.set_interaction_message("Scegli il tuo pasto")
		else:
			var messages = {
				GlucolifeDataManager.MealType.BREAKFAST: "Hai già fatto colazione oggi",
				GlucolifeDataManager.MealType.SNACK1: "Hai già fatto merenda oggi",
				GlucolifeDataManager.MealType.LUNCH: "Hai già pranzato oggi",
				GlucolifeDataManager.MealType.SNACK2: "Hai già fatto merenda oggi",
				GlucolifeDataManager.MealType.DINNER: "Hai già cenato oggi"
			}
			click_area.set_interaction_message(messages.get(current_meal_type, "Non puoi mangiare ora"))

func _update_meal_label_text():
	if not meal_label:
		return
		
	var hour = Time.get_time_dict_from_system().hour
	var meal_type = _get_current_meal_type()
	
	match meal_type:
		GlucolifeDataManager.MealType.BREAKFAST:
			if GlucolifeDataManager.can_eat_meal(meal_type):
				meal_label.text = "Colazione (6:00 - 10:00)"
			else:
				meal_label.text = "Hai già fatto colazione oggi"
				
		GlucolifeDataManager.MealType.SNACK1:
			if GlucolifeDataManager.can_eat_meal(meal_type):
				meal_label.text = "Merenda Mattutina (10:00 - 12:00)"
			else:
				meal_label.text = "Hai già fatto merenda oggi"
				
		GlucolifeDataManager.MealType.LUNCH:
			if GlucolifeDataManager.can_eat_meal(meal_type):
				meal_label.text = "Pranzo (12:00 - 15:00)"
			else:
				meal_label.text = "Hai già pranzato oggi"
				
		GlucolifeDataManager.MealType.SNACK2:
			if GlucolifeDataManager.can_eat_meal(meal_type):
				meal_label.text = "Merenda Pomeridiana (15:00 - 18:00)"
			else:
				meal_label.text = "Hai già fatto merenda oggi"
				
		GlucolifeDataManager.MealType.DINNER:
			if GlucolifeDataManager.can_eat_meal(meal_type):
				meal_label.text = "Cena (18:00 - 22:00)"
			else:
				meal_label.text = "Hai già cenato oggi"
				
		_:
			if hour < 6:
				meal_label.text = "È troppo tardi! Torna domani per la colazione! (6:00)"
			elif hour > 22:
				meal_label.text = "È troppo tardi! Torna domani per la colazione! (6:00)"
			else:
				meal_label.text = "Non è ora di mangiare"

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_active:
			_check_table_click()
		elif is_active and not is_animating:
			_check_food_click()

func _check_table_click():
	if not can_interact_with_table:
		return
		
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 100.0

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 0xFFFFFFFF

	var camera_bounds = get_tree().get_first_node_in_group("camera_bounds")
	if camera_bounds:
		query.exclude = [camera_bounds.get_rid()]

	var result = space_state.intersect_ray(query)
	
	if not result.is_empty() and result.collider == click_area:
		start_food_interaction()

func _check_food_click():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 100.0

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = 0xFFFFFFFF

	var camera_bounds = get_tree().get_first_node_in_group("camera_bounds")
	if camera_bounds:
		query.exclude = [camera_bounds.get_rid()]

	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		return
		
	var collider = result.collider
	
	for food_node_instance in current_food_nodes:
		if not is_instance_valid(food_node_instance):
			continue
			
		if collider == food_node_instance or food_node_instance.is_ancestor_of(collider):
			_on_food_selected(food_node_instance)
			return

func _on_table_clicked(_cam, event, _pos, _normal, _idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_active and not is_animating and can_interact_with_table:
			start_food_interaction()

func start_food_interaction():
	if is_animating or all_food_scenes.is_empty() or not can_interact_with_table:
		return

	is_active = true
	is_animating = true

	if camera_pivot:
		original_pivot_transform = camera_pivot.global_transform
	if camera:
		original_camera_transform = camera.transform

	if camera_pivot and camera_pivot.has_method("set_food_view_mode"):
		camera_pivot.set_food_view_mode(true)

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

	if camera_pivot and camera_pivot.has_method("set_food_view_mode"):
		camera_pivot.set_food_view_mode(false)

	is_active = false
	is_animating = false
	
	_update_table_interaction_status()
	_update_meal_label_text()

func _zoom_camera_to_table():
	if not camera_pivot or not camera:
		return
		
	var table_pos = global_position
	var target_pivot_pos = table_pos
	var target_cam_pos = Vector3(0, 1.0, 2.5)
	var target_cam_rot = Vector3(deg_to_rad(10), 0.0, 0.0)

	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)

	tween.tween_property(camera_pivot, "global_position", target_pivot_pos, zoom_duration)
	tween.tween_property(camera_pivot, "rotation", Vector3.ZERO, zoom_duration)
	tween.tween_property(camera, "position", target_cam_pos, zoom_duration)
	tween.tween_property(camera, "rotation", target_cam_rot, zoom_duration)

	await tween.finished

func _zoom_camera_out():
	if not camera_pivot or not camera:
		return
	
	if original_pivot_transform == Transform3D() or original_camera_transform == Transform3D():
		return
	if abs(original_pivot_transform.basis.determinant()) < 0.001 or abs(original_camera_transform.basis.determinant()) < 0.001:
		return
		
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)

	tween.tween_property(camera_pivot, "global_transform", original_pivot_transform, zoom_duration)
	tween.tween_property(camera, "transform", original_camera_transform, zoom_duration)

	await tween.finished

func _spawn_random_foods():
	current_food_indices.clear()
	if all_food_scenes.is_empty():
		return
	var indices := range(all_food_scenes.size())
	indices.shuffle()
	for i in range(min(foods_displayed, all_food_scenes.size())):
		current_food_indices.append(indices[i])
	await _display_foods()

func _display_foods():
	for food_node in current_food_nodes:
		if is_instance_valid(food_node):
			food_node.queue_free()
	current_food_nodes.clear()

	if food_spawn_point == null:
		return

	var start_x = -(foods_displayed - 1) * food_spacing * 0.5

	for i in range(current_food_indices.size()):
		var scene_index = current_food_indices[i]
		if scene_index >= all_food_scenes.size():
			continue
			
		var food_scene = all_food_scenes[scene_index]
		if food_scene == null or not (food_scene is PackedScene):
			continue

		var food_node_instance = food_scene.instantiate()
		
		var food_pos = Vector3(start_x + i * food_spacing, 0.3, 0)
		food_node_instance.position = food_pos
		food_node_instance.scale = Vector3.ONE * food_scale
		
		food_spawn_point.add_child(food_node_instance)
		current_food_nodes.append(food_node_instance)

func _despawn_foods():
	for food_node in current_food_nodes:
		if is_instance_valid(food_node):
			food_node.queue_free()
	current_food_nodes.clear()
	await get_tree().process_frame

func _scroll_foods(direction: int):
	if is_animating or all_food_scenes.is_empty():
		return
	is_animating = true
	for i in range(current_food_indices.size()):
		current_food_indices[i] = (current_food_indices[i] + direction) % all_food_scenes.size()
	await _display_foods()
	is_animating = false

func _create_ui():
	ui_canvas = CanvasLayer.new()
	ui_canvas.layer = 10
	get_tree().root.add_child(ui_canvas)

	if all_food_scenes.size() > foods_displayed:
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
	if ui_canvas and is_instance_valid(ui_canvas):
		ui_canvas.queue_free()
		ui_canvas = null

func _on_food_selected(food_node_instance):
	food_selected.emit(food_node_instance.scene_file_path)
	food_selected_packed.emit(load(food_node_instance.scene_file_path))

	if food_node_instance.has_method("get_glucolife_data"):
		var data = food_node_instance.get_glucolife_data()
		var meal_type = _get_current_meal_type()
		
		var meal_added = GlucolifeDataManager.add_meal(
			meal_type,
			data["glucose"],
			data["energy"],
			data["happiness"],
			data.get("digestion_time", 1.0)
		)
		
		if meal_added:
			GlucolifeDataManager.update_glucose(data["glucose"])
			GlucolifeDataManager.update_energy(data["energy"])
			GlucolifeDataManager.update_happiness(data["happiness"])
			GlucolifeDataManager.update_hygiene(data["hygiene"])
	
	await _play_food_eaten_animation(food_node_instance)
	
	end_food_interaction()

func _get_current_meal_type() -> int:
	var hour = Time.get_time_dict_from_system().hour
	
	match hour:
		6,7,8,9,10:
			return GlucolifeDataManager.MealType.BREAKFAST
		11,12:
			return GlucolifeDataManager.MealType.SNACK1
		13,14,15:
			return GlucolifeDataManager.MealType.LUNCH
		16,17,18:
			return GlucolifeDataManager.MealType.SNACK2
		19,20,21,22:
			return GlucolifeDataManager.MealType.DINNER
		_:
			return -1
			
func _play_food_eaten_animation(food_node_instance):
	if not is_instance_valid(food_node_instance):
		return

	current_food_nodes.erase(food_node_instance)

	if camera and is_instance_valid(camera):
		var target_pos = camera.global_position + Vector3(0, 0, -0.5)

		var tweening = create_tween()
		tweening.set_parallel(true)
		tweening.set_ease(Tween.EASE_OUT)
		tweening.set_trans(Tween.TRANS_BACK)

		tweening.tween_property(food_node_instance, "global_position", target_pos, 0.35)
		tweening.tween_property(food_node_instance, "scale", Vector3(0.001, 0.001, 0.001), 0.35)

		await tweening.finished
	else:
		await get_tree().process_frame

	if is_instance_valid(food_node_instance):
		food_node_instance.queue_free()
