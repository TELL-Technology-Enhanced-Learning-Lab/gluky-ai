extends MeshInstance3D

@export var water_node: MeshInstance3D
@export var exit_button: Button
@export var hygiene_increase_per_second: float = 10.0
@export var sponge_texture: Texture2D

@export_group("Animation Timing")
@export var walk_duration: float = 2.5
@export var return_duration: float = 2.5

@export_group("Player Bath Transform")
@export var player_bath_position: Vector3 = Vector3(15.81, 1.5, 3.124)
@export var player_bath_rotation: Vector3 = Vector3(0.0, -90.0, 0.0)
@export var player_bath_scale: Vector3 = Vector3(2.0, 2.0, 2.0)

var player: Node3D
var camera: Camera3D
var camera_pivot: Node3D
var bathtub_click_detector: Area3D
var data_manager: Node
var main_tween: Tween
var is_animating: bool = false
var can_interact: bool = true
var player_in_bath: bool = false
var is_cleaning: bool = false
var last_clean_time: float = 0.0
var clean_cooldown: float = 0.05
var custom_cursor: Control
var player_original_position: Vector3
var player_original_rotation: Vector3
var player_original_scale: Vector3
var cleaning_progress: float = 0.0
var max_hygiene: float = 100.0

func _ready():
	await get_tree().process_frame
	_find_references()
	_setup_click_detector()
	_create_sponge_cursor()
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)
		exit_button.hide()

func _find_references():
	player = get_tree().get_first_node_in_group("Player")
	camera_pivot = get_tree().get_first_node_in_group("camera_pivot")
	if camera_pivot:
		camera = camera_pivot.get_node_or_null("Camera3D")
	if not camera:
		camera = get_viewport().get_camera_3d()
	data_manager = get_node("/root/GlucolifeDataManager")

func _setup_click_detector():
	for child in get_children():
		if child is Area3D:
			bathtub_click_detector = child
			break
	if bathtub_click_detector:
		bathtub_click_detector.collision_layer = 2
		if not bathtub_click_detector.input_event.is_connected(_on_bathtub_clicked):
			bathtub_click_detector.input_event.connect(_on_bathtub_clicked)

func _create_sponge_cursor():
	if not sponge_texture:
		return
	custom_cursor = Control.new()
	custom_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sponge_rect = TextureRect.new()
	sponge_rect.texture = sponge_texture
	sponge_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	sponge_rect.size = Vector2(64, 64)
	sponge_rect.position = -sponge_rect.size / 2
	custom_cursor.add_child(sponge_rect)
	get_viewport().add_child(custom_cursor)
	custom_cursor.hide()

func _input(event: InputEvent):
	if custom_cursor and custom_cursor.visible and event is InputEventMouseMotion:
		custom_cursor.position = event.position

	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
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
	query.collision_mask = 2

	var result = space_state.intersect_ray(query)
	if result and bathtub_click_detector and result.collider == bathtub_click_detector:
		if not player_in_bath:
			start_bath_animation()
		else:
			_handle_cleaning(result.position)

func _on_bathtub_clicked(_cam, event, pos, _normal, _idx):
	if not can_interact or is_animating:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not player_in_bath:
			start_bath_animation()
		else:
			_handle_cleaning(pos)

func start_bath_animation():
	if is_animating or not player:
		return

	is_animating = true
	can_interact = false
	cleaning_progress = 0.0

	player_original_position = player.global_position
	player_original_rotation = player.rotation_degrees
	player_original_scale = player.scale

	_disable_player_control()

	var t = _make_tween()
	t.tween_property(player, "global_position", player_bath_position, walk_duration)
	t.tween_property(player, "rotation_degrees", player_bath_rotation, walk_duration)
	t.tween_property(player, "scale", player_bath_scale, walk_duration)

	await t.finished

	_enable_player_control()

	is_animating = false
	can_interact = true
	player_in_bath = true

	if water_node and water_node.has_method("cinematic_splash"):
		water_node.cinematic_splash()

	if exit_button:
		exit_button.show()

func _disable_player_control():
	if player is CharacterBody3D:
		player.set_physics_process(false)
	if camera_pivot:
		camera_pivot.set_process(false)
		camera_pivot.set_physics_process(false)

func _enable_player_control():
	if player is CharacterBody3D:
		player.set_physics_process(true)
	if camera_pivot:
		camera_pivot.set_process(true)
		camera_pivot.set_physics_process(true)

func _make_tween() -> Tween:
	if main_tween and main_tween.is_valid():
		main_tween.kill()
	main_tween = create_tween()
	main_tween.set_parallel(true)
	main_tween.set_ease(Tween.EASE_IN_OUT)
	main_tween.set_trans(Tween.TRANS_CUBIC)
	return main_tween

func _on_exit_pressed():
	if is_animating or not player or not player_in_bath:
		return
	_exit_bath()

func _exit_bath():
	if is_animating:
		return

	player_in_bath = false
	_stop_cleaning()

	if exit_button:
		exit_button.hide()

	is_animating = true
	can_interact = false

	var t = _make_tween()
	t.tween_property(player, "global_position", player_original_position, return_duration)
	t.tween_property(player, "rotation_degrees", player_original_rotation, return_duration)
	t.tween_property(player, "scale", player_original_scale, return_duration)

	await t.finished

	is_animating = false
	can_interact = true

func _handle_cleaning(click_pos: Vector3):
	if not player_in_bath or is_animating:
		return

	if not is_cleaning:
		_start_cleaning()

	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_clean_time > clean_cooldown:
		_apply_cleaning()
		last_clean_time = current_time

	_show_feedback(click_pos)

	var stats = data_manager.get_stats()
	if stats.hygiene >= max_hygiene:
		_exit_bath()

func _start_cleaning():
	if is_cleaning:
		return
	is_cleaning = true
	if custom_cursor:
		custom_cursor.show()

func _stop_cleaning():
	if not is_cleaning:
		return
	is_cleaning = false
	if custom_cursor:
		custom_cursor.hide()

func _apply_cleaning():
	if not data_manager or not data_manager.is_glucolife_active:
		return
	var increase = hygiene_increase_per_second * clean_cooldown
	data_manager.update_hygiene(increase)

func _show_feedback(pos: Vector3):
	var bubble = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.8, 1.0, 0.6)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere.material = material
	bubble.mesh = sphere
	add_child(bubble)
	bubble.global_position = pos
	var bubble_tween = create_tween()
	bubble_tween.set_parallel(true)
	bubble_tween.tween_property(bubble, "scale", Vector3(2, 2, 2), 0.3)
	bubble_tween.tween_property(bubble, "position:y", bubble.position.y + 0.1, 0.3)
	bubble_tween.tween_method(_set_bubble_alpha.bind(bubble), 1.0, 0.0, 0.3)
	await bubble_tween.finished
	bubble.queue_free()

func _set_bubble_alpha(alpha: float, bubble: MeshInstance3D):
	if bubble and is_instance_valid(bubble):
		var surface_material = bubble.mesh.surface_get_material(0)
		if surface_material:
			surface_material.albedo_color.a = alpha

func _exit_tree():
	if custom_cursor:
		custom_cursor.queue_free()
