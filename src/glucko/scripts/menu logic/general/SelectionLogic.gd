extends Button

@onready var camera_node: Camera3D = get_node("../../player_model/Node3D/Camera3D")
@onready var book_menu_controller: BookMenuController = get_node("../../BookMenuController")
@onready var tutorial_system = get_node("../../Library Options")

var current_camera_position: int = 1
var target_object: Node3D
var is_zoomed: bool = false
var is_loading_scene: bool = false

func _ready() -> void:
	visible = false
	_setup_camera_connections()

func _setup_camera_connections():
	if camera_node:
		if not camera_node.player_camera_movement.is_connected(_on_camera_moved):
			camera_node.player_camera_movement.connect(_on_camera_moved)
		if not camera_node.animation_sequence_completed.is_connected(_on_animation_completed):
			camera_node.animation_sequence_completed.connect(_on_animation_completed)
		if not camera_node.camera_movement_finished.is_connected(_on_camera_movement_finished):
			camera_node.camera_movement_finished.connect(_on_camera_movement_finished)
		
		if camera_node.has_method("_enable_swipe_input"):
			camera_node._enable_swipe_input()

func _on_camera_moved(cposition: int):
	if not is_zoomed:
		current_camera_position = cposition
	_update_button_text()

func _on_camera_movement_finished(target_position: int):
	current_camera_position = target_position
	_update_button_text()
	if target_position == 1:
		await get_tree().create_timer(0.2).timeout
		visible = true
		_update_button_text()

func _on_animation_completed():
	visible = true
	_update_button_text()

func _find_target_object():
	var group_name = ""
	match current_camera_position:
		0:
			group_name = "minigame"
		1:
			group_name = "library"
		2:
			group_name = "exit"
	var nodes = get_tree().get_nodes_in_group(group_name)
	for node in nodes:
		if node.is_in_group("target") and node is Node3D:
			return node
	return null

func _find_book_node():
	var book_nodes = get_tree().get_nodes_in_group("book")
	for node in book_nodes:
		if node is Node3D:
			return node
	return null

func _zoom_to_target():
	target_object = _find_target_object()
	if not target_object:
		return
	if camera_node and camera_node.has_method("_prepare_camera_zoom"):
		var zoom_tween = camera_node._prepare_camera_zoom(target_object)
		if zoom_tween:
			is_zoomed = true
			text = "Back"
			await zoom_tween.finished

func _reset_camera():
	if not camera_node or not target_object:
		return
	
	if current_camera_position == 1:
		await _play_book_animation_reverse()
	
	var camera_pivot = camera_node.get_parent()
	if not camera_pivot:
		return
	
	var original_position = Vector3.ZERO
	var original_rotation_y = 0.0
	var original_rotation_x = 0.0
	
	match current_camera_position:
		0:
			original_position = camera_node.camera_position_left
			original_rotation_y = camera_node.camera_rotation_left.x
			original_rotation_x = camera_node.camera_rotation_left.y
		1:
			if camera_node.has_meta("original_position_before_zoom"):
				original_position = camera_node.get_meta("original_position_before_zoom")
				var original_rotation = camera_node.get_meta("original_rotation_before_zoom")
				original_rotation_y = original_rotation.y
				original_rotation_x = original_rotation.x
			else:
				original_position = camera_node.original_camera_position
				original_rotation_y = camera_node.original_camera_y_angle
				original_rotation_x = camera_node.original_camera_x_angle
			
			if camera_node.book_node:
				camera_node.book_node.visible = false
		2:
			original_position = camera_node.camera_position_right
			original_rotation_y = camera_node.camera_rotation_right.x
			original_rotation_x = camera_node.camera_rotation_right.y
	
	var reset_tween = create_tween()
	reset_tween.tween_property(camera_pivot, "global_position", original_position, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	reset_tween.parallel().tween_property(camera_pivot, "rotation_degrees:y", original_rotation_y, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	reset_tween.parallel().tween_property(camera_pivot, "rotation_degrees:x", original_rotation_x, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	if camera_node.has_method("_enable_swipe_input"):
		camera_node._enable_swipe_input()
	
	is_zoomed = false
	_update_button_text()
	
	await reset_tween.finished
	
	if camera_node.has_meta("original_position_before_zoom"):
		camera_node.remove_meta("original_position_before_zoom")
	if camera_node.has_meta("original_rotation_before_zoom"):
		camera_node.remove_meta("original_rotation_before_zoom")

func _update_button_text():
	if is_loading_scene:
		text = "Loading..."
	elif is_zoomed:
		text = "Back"
	else:
		match current_camera_position:
			0:
				text = "Play a minigame"
			1:
				text = "Library"
			2:
				text = "Quit game"

func _pressed():
	if is_loading_scene:
		return
	
	if not camera_node:
		return
	
	if current_camera_position == 1 and not is_zoomed:
		target_object = _find_target_object()
		if not target_object:
			return
		
		if camera_node.has_method("_prepare_camera_zoom"):
			var zoom_tween = camera_node._prepare_camera_zoom(target_object)
			if zoom_tween:
				is_zoomed = true
				text = "Back"
				await zoom_tween.finished
				
				await _play_book_animation()
				
				_teleport_book_to_target()
				
				if tutorial_system:
					tutorial_system.show_library_menu_from_zoom()
		return
	
	if is_zoomed:
		await _reset_camera()
		if current_camera_position == 1 and book_menu_controller:
			book_menu_controller.go_back()
		return
	
	target_object = _find_target_object()
	if not target_object:
		match current_camera_position:
			0:
				_load_minigame_scene()
			1:
				pass
			2:
				get_tree().quit()
		return
	
	var camera_pivot = camera_node.get_parent()
	if not camera_pivot:
		return
	
	var target_position = target_object.global_position
	var current_position = camera_pivot.global_position
	var direction = (target_position - current_position).normalized()
	var target_distance = 1.0
	var zoom_position = target_position - direction * target_distance
	
	if camera_node.has_method("_disable_swipe_input"):
		camera_node._disable_swipe_input()
	
	var action_tween = create_tween()
	action_tween.tween_property(camera_pivot, "global_position", zoom_position, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	camera_pivot.look_at(target_position)
	
	is_zoomed = true
	text = "Back"
	
	await action_tween.finished
	if not is_zoomed:
		return
	
	match current_camera_position:
		0:
			_load_minigame_scene()
		1:
			pass
		2:
			get_tree().quit()

func _play_book_animation():
	if target_object:
		var animation_player = target_object.get_node_or_null("AnimationPlayer")
		if animation_player and animation_player.has_animation("takeBookOut"):
			animation_player.play("takeBookOut")
			await animation_player.animation_finished

func _play_book_animation_reverse():
	if target_object:
		var animation_player = target_object.get_node_or_null("AnimationPlayer")
		if animation_player and animation_player.has_animation("takeBookOut"):
			animation_player.play_backwards("takeBookOut")
			await animation_player.animation_finished

func _teleport_book_to_target():
	var book_node = _find_book_node()
	if book_node and target_object:
		var original_parent = book_node.get_parent()
		
		book_node.get_parent().remove_child(book_node)
		target_object.add_child(book_node)
		book_node.global_transform = target_object.global_transform
		
		target_object.remove_child(book_node)
		original_parent.add_child(book_node)
		book_node.global_transform = target_object.global_transform
		book_node.global_position += Vector3(0, -0.2, 0.3)
		book_node.scale = Vector3(0.4, 0.4, 0.4)
		
		book_node.visible = true
		target_object.visible = false
		
		var book_animation_player = book_node.get_node_or_null("AnimationPlayer")
		if book_animation_player and book_animation_player.has_animation("bookPrep"):
			book_animation_player.play("bookPrep")

func _restore_target_object():
	if target_object:
		target_object.visible = true
	
	var book_node = _find_book_node()
	if book_node:
		book_node.visible = false

func _load_minigame_scene() -> void:
	if is_loading_scene:
		return
	
	is_loading_scene = true
	_update_button_text()
	
	var kitchen_scene_path = "res://scenes/menus/glucky/Minigame_Selection.tscn"
	
	if not ResourceLoader.exists(kitchen_scene_path):
		push_error("Scene not found: " + kitchen_scene_path)
		is_loading_scene = false
		return
	
	get_tree().change_scene_to_file(kitchen_scene_path)

func _on_back_button_pressed():
	if is_loading_scene:
		return
	
	if book_menu_controller:
		book_menu_controller.go_back()
	
	if is_zoomed:
		await _reset_camera()
