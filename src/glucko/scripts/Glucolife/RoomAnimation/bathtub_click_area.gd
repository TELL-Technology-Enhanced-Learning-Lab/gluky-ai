extends Area3D

@export var hygiene_increase_per_second: float = 5.0
@export var sponge_texture: Texture2D
@export var bathtub_node: MeshInstance3D

var data_manager: Node
var is_cleaning: bool = false
var last_clean_time: float = 0.0
var clean_cooldown: float = 0.05
var custom_cursor: Control
var player_in_bath: bool = false  # Da aggiornare esternamente

func _ready():
	input_ray_pickable = true
	monitoring = true
	monitorable = true
	collision_layer = 2
	collision_mask = 0
	
	data_manager = get_node("/root/GlucolifeDataManager")
	
	set_process_input(true)
	
	if sponge_texture:
		_create_sponge_cursor()

func _create_sponge_cursor():
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

func _input(event):
	if not data_manager or not data_manager.is_glucolife_active:
		return
	
	if event is InputEventMouseMotion and custom_cursor and custom_cursor.visible:
		custom_cursor.position = event.position
	
	# NON gestiamo più i touch qui - li gestiamo solo nell'input_event
	# per evitare conflitti con CameraDirector

func _on_input_event(_camera: Node, event: InputEvent, click_pos: Vector3, _normal: Vector3, _idx: int):
	if not data_manager or not data_manager.is_glucolife_active:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Se il giocatore è nella vasca, pulisci
			if player_in_bath:
				_handle_cleaning(click_pos)
			# Se NON è nella vasca, lasciamo che CameraDirector gestisca l'entrata
			# NON facciamo nulla qui, così l'evento continua a propagarsi

func _handle_cleaning(click_pos: Vector3):
	if not is_cleaning:
		_start_cleaning()
	
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_clean_time > clean_cooldown:
		_apply_cleaning()
		last_clean_time = current_time
	
	_show_feedback(click_pos)

func set_player_in_bath(value: bool):
	player_in_bath = value
	if not player_in_bath:
		_stop_cleaning()

func _start_cleaning():
	if is_cleaning:
		return
	
	is_cleaning = true
	
	if bathtub_node and bathtub_node.has_method("_start_cleaning"):
		bathtub_node._start_cleaning()
	
	if custom_cursor:
		custom_cursor.show()

func _stop_cleaning():
	if not is_cleaning:
		return
	
	is_cleaning = false
	
	if bathtub_node and bathtub_node.has_method("_stop_cleaning"):
		bathtub_node._stop_cleaning()
	
	if custom_cursor:
		custom_cursor.hide()

func _apply_cleaning():
	if not data_manager or not data_manager.is_glucolife_active:
		return
	
	var increase = hygiene_increase_per_second * clean_cooldown
	data_manager.update_hygiene(increase)
	
	if bathtub_node and bathtub_node.has_method("increase_hygiene"):
		bathtub_node.increase_hygiene(increase)

func _show_feedback(feedback_position: Vector3):
	var bubble = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.8, 1.0, 0.6)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere.material = material
	bubble.mesh = sphere
	
	get_parent().add_child(bubble)
	bubble.global_position = feedback_position
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(bubble, "scale", Vector3(2, 2, 2), 0.3)
	tween.tween_property(bubble, "position:y", bubble.position.y + 0.1, 0.3)
	tween.tween_property(bubble, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	bubble.queue_free()

func _exit_tree():
	if custom_cursor:
		custom_cursor.queue_free()
