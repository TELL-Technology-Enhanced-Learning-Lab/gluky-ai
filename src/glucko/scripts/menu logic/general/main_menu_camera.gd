extends Camera3D

@export var player_node: Node3D
@export var look_sensitivity: float = 0.002

enum CameraState { VIGNETTE_FADE, CHARACTER_RESET, RISE_WITH_CHARACTER, CAMERA_RISE_BACK, PLAYER_CONTROL }
var current_state: CameraState = CameraState.VIGNETTE_FADE
var animation_time: float = 0.0

var vignette_hold_duration: float = 1.0
var vignette_fade_out_duration: float = 0.5
var character_reset_duration: float = 0.5
var vignette_fade_in_duration: float = 0.5
var rise_with_character_duration: float = 3.5
var camera_rise_back_duration: float = 3.0

var vignette_rect: ColorRect
var max_vignette_opacity: float = 1.0

var camera_pivot: Node3D
var camera_detach_prepared: bool = false

var character_start_rotation: Vector3
var camera_start_position: Vector3
var camera_start_rotation: Vector3

var camera_move_start_position: Vector3
var camera_move_target_position: Vector3
var camera_look_target_position: Vector3
var camera_move_start_rotation: Basis

enum RiseSubState { X_AXIS_FIRST_PART, X_AXIS_PAUSE, X_AXIS_SECOND_PART }
var current_rise_state: RiseSubState = RiseSubState.X_AXIS_FIRST_PART
var sub_state_time: float = 0.0

var player_animation_player: AnimationPlayer
var reset_animation_played: bool = false
var sitting_animation_played: bool = false

signal animation_sequence_completed
signal player_camera_movement(direction: int)
signal camera_movement_finished(target_position: int)
signal library_focused
signal camera_ready_for_book
signal book_should_hide

var current_camera_position: int = 1
var is_animating: bool = false
var swipe_start_position: Vector2 = Vector2.ZERO
var min_swipe_distance: float = 50.0

var original_camera_y_angle: float = 0.0
var original_camera_x_angle: float = -5.0
var original_camera_position: Vector3 = Vector3.ZERO

var camera_position_left: Vector3 = Vector3.ZERO
var camera_position_right: Vector3 = Vector3.ZERO
var camera_rotation_left: Vector2 = Vector2.ZERO
var camera_rotation_right: Vector2 = Vector2.ZERO

var highlight_material: StandardMaterial3D
var highlighted_group: String = ""

var swipe_input_enabled: bool = true

var book_target: Node3D
var book_node: Node3D
var book_animation_player: AnimationPlayer

func _ready():
	if player_node:
		character_start_rotation = player_node.rotation_degrees
		_find_player_animation_player()
	
	camera_start_position = global_position
	camera_start_rotation = rotation_degrees
	
	_create_vignette_effect()
	_create_highlight_material()
	player_camera_movement.connect(_on_camera_movement)
	
	set_process_input(false)
	_prepare_book_target()

func _create_highlight_material():
	highlight_material = StandardMaterial3D.new()
	highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight_material.albedo_color = Color(1, 0.8, 0.2, 0.6)
	highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight_material.cull_mode = BaseMaterial3D.CULL_DISABLED

func _on_camera_movement(target_position: int):
	_clear_all_highlights()
	match target_position:
		0:
			_highlight_group("minigame")
		1:
			_highlight_group("library")
			library_focused.emit()
		2:
			_highlight_group("exit")

func _highlight_group(group_name: String):
	highlighted_group = group_name
	var nodes = get_tree().get_nodes_in_group(group_name)
	for node in nodes:
		if node is MeshInstance3D:
			node.material_overlay = highlight_material

func _clear_all_highlights():
	if highlighted_group.is_empty():
		return
	var nodes = get_tree().get_nodes_in_group(highlighted_group)
	for node in nodes:
		if node is MeshInstance3D:
			node.material_overlay = null
	highlighted_group = ""

func _prepare_book_target():
	var books = get_tree().get_nodes_in_group("book")
	if books.size() > 0:
		book_node = books[0]
		for child in book_node.get_children():
			if child is AnimationPlayer:
				book_animation_player = child
				break
	var library_targets = get_tree().get_nodes_in_group("library")
	for node in library_targets:
		if node.is_in_group("target") and node is Node3D:
			book_target = node
			break

func _position_book_for_camera():
	if not book_node or not camera_pivot:
		return
	
	var camera_pos = camera_pivot.global_position
	var camera_forward = -camera_pivot.global_transform.basis.z.normalized()
	var book_distance = 1.5
	var book_height_offset = -0.3
	var book_position = camera_pos + camera_forward * book_distance
	book_position.y += book_height_offset
	
	book_node.global_position = book_position
	book_node.look_at(camera_pos)
	book_node.rotate_object_local(Vector3(0, 1, 0), PI)

func _find_player_animation_player():
	if player_node:
		for child in player_node.get_children():
			if child is AnimationPlayer:
				player_animation_player = child
				return
		player_animation_player = player_node.find_child("*AnimationPlayer*", true)

func _create_vignette_effect():
	vignette_rect = ColorRect.new()
	vignette_rect.name = "VignetteEffect"
	vignette_rect.color = Color(0, 0, 0, max_vignette_opacity)
	vignette_rect.anchor_left = 0.0
	vignette_rect.anchor_top = 0.0
	vignette_rect.anchor_right = 1.0
	vignette_rect.anchor_bottom = 1.0
	vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().root.call_deferred("add_child", vignette_rect)

func _process(delta):
	match current_state:
		CameraState.VIGNETTE_FADE:
			_animate_vignette_fade(delta)
		CameraState.CHARACTER_RESET:
			_animate_character_reset(delta)
		CameraState.RISE_WITH_CHARACTER:
			_animate_rise_with_character(delta)
		CameraState.CAMERA_RISE_BACK:
			_animate_camera_rise_back(delta)
		CameraState.PLAYER_CONTROL:
			_handle_player_control(delta)

func _animate_vignette_fade(delta):
	animation_time += delta
	if animation_time < vignette_hold_duration:
		if vignette_rect:
			vignette_rect.color.a = max_vignette_opacity
		return
	var fade_time = animation_time - vignette_hold_duration
	var progress = min(fade_time / vignette_fade_out_duration, 1.0)
	if vignette_rect:
		vignette_rect.color.a = lerp(max_vignette_opacity, 1.0, _smooth_in_out(progress))
	if progress >= 1.0:
		current_state = CameraState.CHARACTER_RESET
		animation_time = 0.0

func _animate_character_reset(delta):
	animation_time += delta
	var progress = min(animation_time / character_reset_duration, 1.0)
	if progress < 0.5:
		if vignette_rect:
			vignette_rect.color.a = 1.0
	else:
		if not reset_animation_played and player_animation_player:
			player_animation_player.play("RESET")
			reset_animation_played = true
		var reset_progress = (progress - 0.5) / 0.5
		reset_progress = _smooth_in_out(reset_progress)
		if player_node:
			player_node.rotation_degrees.x = lerp(-90.0, -90.0, reset_progress)
			player_node.rotation_degrees.y = -180.0
		rotation_degrees.x = lerp(-90.0, -90.0, reset_progress)
		rotation_degrees.y = -180.0
		if vignette_rect:
			vignette_rect.color.a = lerp(1.0, 0.0, reset_progress)
	if progress >= 1.0:
		current_state = CameraState.RISE_WITH_CHARACTER
		animation_time = 0.0
		current_rise_state = RiseSubState.X_AXIS_FIRST_PART
		sub_state_time = 0.0
		if vignette_rect:
			vignette_rect.color.a = 0.0

func _animate_rise_with_character(delta):
	animation_time += delta
	sub_state_time += delta
	match current_rise_state:
		RiseSubState.X_AXIS_FIRST_PART:
			var x_first_part_duration = 1.0
			var progress = min(sub_state_time / x_first_part_duration, 1.0)
			var eased = _smooth_in_out(progress)
			if player_node:
				player_node.rotation_degrees.x = lerp(-90.0, -60.0, eased)
				player_node.rotation_degrees.y = -180.0
			rotation_degrees.x = lerp(-90.0, -80.0, eased)
			rotation_degrees.y = -180.0
			if progress >= 1.0:
				current_rise_state = RiseSubState.X_AXIS_PAUSE
				sub_state_time = 0.0
		RiseSubState.X_AXIS_PAUSE:
			var pause_duration = 1.0
			if player_node:
				player_node.rotation_degrees.x = -60.0
				player_node.rotation_degrees.y = -180.0
			rotation_degrees.x = -80.0
			rotation_degrees.y = -180.0
			if sub_state_time >= pause_duration:
				current_rise_state = RiseSubState.X_AXIS_SECOND_PART
				sub_state_time = 0.0
		RiseSubState.X_AXIS_SECOND_PART:
			var x_second_part_duration = 1.5
			var progress = min(sub_state_time / x_second_part_duration, 1.0)
			var eased = _smooth_in_out(progress)
			if player_node:
				player_node.rotation_degrees.x = lerp(-60.0, 0.0, eased)
				player_node.rotation_degrees.y = -180.0
			rotation_degrees.x = lerp(-80.0, -10.0, eased)
			rotation_degrees.y = -180.0
			if progress >= 1.0:
				current_state = CameraState.CAMERA_RISE_BACK
				animation_time = 0.0
				_prepare_camera_detach()

func _prepare_camera_detach():
	if camera_detach_prepared:
		return
	var scene_tree = get_tree()
	if not scene_tree:
		return
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	var current_global_transform = global_transform
	if player_node:
		var char_forward = -player_node.global_transform.basis.z.normalized()
		camera_move_target_position = player_node.global_position + char_forward * 3.0 + Vector3(0, 2.0, 0)
		camera_look_target_position = player_node.global_position + Vector3(0, 1.5, 0)
	camera_move_start_position = global_position
	camera_move_start_rotation = global_transform.basis
	var parent = get_parent()
	if parent:
		parent.remove_child(self)
	camera_pivot.global_transform = current_global_transform
	camera_pivot.add_child(self)
	scene_tree.root.add_child(camera_pivot)
	transform = Transform3D.IDENTITY
	camera_detach_prepared = true
	original_camera_y_angle = camera_pivot.rotation_degrees.y
	original_camera_x_angle = camera_pivot.rotation_degrees.x
	original_camera_position = camera_move_target_position
	camera_position_left = original_camera_position + Vector3(1.5, 0, 0)
	camera_position_right = original_camera_position + Vector3(-1.5, 0, 0)
	camera_rotation_left = Vector2(original_camera_y_angle + 7.0, original_camera_x_angle + 5.0)
	camera_rotation_right = Vector2(original_camera_y_angle - 15.0, original_camera_x_angle + 5.0)

func _animate_camera_rise_back(delta):
	animation_time += delta
	var progress = min(animation_time / camera_rise_back_duration, 1.0)
	if not camera_pivot:
		return
	var eased_progress = _smooth_step(progress)
	var smooth_progress = _smooth_in_out(eased_progress)
	if smooth_progress < 0.4:
		var up_progress = smooth_progress / 0.4
		var up_eased = _smooth_in_out(up_progress)
		var up_position = camera_move_start_position + Vector3(0, 2.0, 0)
		camera_pivot.global_position = camera_move_start_position.lerp(up_position, up_eased)
		camera_pivot.global_transform.basis = camera_move_start_rotation
		var tilt_amount = _smooth_in_out(up_eased * 0.3)
		camera_pivot.rotation_degrees.x = lerp(-10.0, -5.0, tilt_amount)
	else:
		if not sitting_animation_played and player_animation_player:
			player_animation_player.play("sitting_on_bed")
			sitting_animation_played = true
		var back_progress = (smooth_progress - 0.4) / 0.6
		var back_eased = _smooth_in_out(back_progress)
		var up_position = camera_move_start_position + Vector3(0, 2.0, 0)
		var target_pos = camera_move_target_position
		camera_pivot.global_position = up_position.lerp(target_pos, back_eased)
		if back_eased < 0.6:
			camera_pivot.global_transform.basis = camera_move_start_rotation
			var tilt_amount = _smooth_in_out(back_eased * 0.6)
			camera_pivot.rotation_degrees.x = lerp(-5.0, -3.0, tilt_amount)
		else:
			var look_progress = (back_eased - 0.6) / 0.4
			look_progress = clamp(look_progress, 0.0, 1.0)
			var look_eased = _smooth_in_out(look_progress)
			var current_forward = -camera_pivot.global_transform.basis.z
			var target_look = (player_node.global_position + Vector3(0, 1.5, 0) - camera_pivot.global_position).normalized()
			var interpolated_forward = current_forward.slerp(target_look, look_eased)
			if interpolated_forward.length() > 0.001:
				camera_pivot.look_at(camera_pivot.global_position + interpolated_forward * 10.0)
				camera_pivot.rotation_degrees.x = -5.0
	if vignette_rect:
		if smooth_progress > 0.5:
			var fade_progress = (smooth_progress - 0.5) / 0.5
			fade_progress = _smooth_in_out(fade_progress)
			vignette_rect.color.a = lerp(0.1, 0.0, fade_progress)
			if fade_progress >= 1.0:
				vignette_rect.visible = false
	if progress >= 0.75:
		current_state = CameraState.PLAYER_CONTROL
		set_process_input(true)
		animation_sequence_completed.emit()
		camera_movement_finished.emit(current_camera_position)
		_on_camera_movement(1)

func _smooth_step(t: float) -> float:
	t = clamp(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _smooth_in_out(t: float) -> float:
	t = clamp(t, 0.0, 1.0)
	if t < 0.5:
		return 4.0 * t * t * t
	else:
		t = 2.0 * t - 2.0
		return 0.5 * t * t * t + 1.0

func _handle_player_control(_delta):
	pass

func _input(event):
	if current_state != CameraState.PLAYER_CONTROL:
		return
	if not swipe_input_enabled:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start_position = event.position
		else:
			var swipe_end = event.position
			_handle_swipe(swipe_start_position, swipe_end)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				swipe_start_position = event.position
			else:
				var swipe_end = event.position
				_handle_swipe(swipe_start_position, swipe_end)

func _handle_swipe(start_pos: Vector2, end_pos: Vector2):
	if is_animating:
		return
	if not swipe_input_enabled:
		return
	var swipe_distance = (end_pos - start_pos).length()
	if swipe_distance < min_swipe_distance:
		return
	var swipe_direction = end_pos.x - start_pos.x
	var direction = 1 if swipe_direction > 0 else -1
	var target_position = current_camera_position + direction
	if target_position >= 0 and target_position <= 2 and target_position != current_camera_position:
		_move_camera_to_position(target_position)

func _move_camera_to_position(target_position: int):
	is_animating = true
	player_camera_movement.emit(target_position)
	var old_position = current_camera_position
	if old_position == 1 and target_position != 1:
		emit_signal("book_should_hide")
	current_camera_position = target_position
	if target_position == 1 and book_animation_player and book_animation_player.has_animation("takeBookOut"):
		book_animation_player.play("takeBookOut")
	if old_position == 1 and target_position == 0:
		_play_neck_animation("turn_neck_left", false)
		_adjust_camera_angle_position(0, 0.4)
	elif old_position == 0 and target_position == 1:
		_play_neck_animation("turn_neck_left", true)
		_reset_camera_angle_position(0.5)
	elif old_position == 1 and target_position == 2:
		_play_neck_animation("turn_neck_right", false)
		_adjust_camera_angle_position(2, 0.5)
	elif old_position == 2 and target_position == 1:
		_play_neck_animation("turn_neck_right", true)
		_reset_camera_angle_position(0.5)

func _play_neck_animation(animation_name: String, reverse: bool):
	if player_animation_player and player_animation_player.has_animation(animation_name):
		if reverse:
			player_animation_player.play_backwards(animation_name)
		else:
			player_animation_player.play(animation_name)
	await get_tree().create_timer(0.5).timeout
	is_animating = false
	camera_movement_finished.emit(current_camera_position)
	if current_camera_position == 1:
		emit_signal("camera_ready_for_book")

func _adjust_camera_angle_position(position_type: int, duration: float = 0.5):
	if not camera_pivot:
		return
	var tween = create_tween()
	match position_type:
		0:
			tween.tween_property(camera_pivot, "global_position", camera_position_left, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tween.parallel().tween_property(camera_pivot, "rotation_degrees:y", camera_rotation_left.x, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tween.parallel().tween_property(camera_pivot, "rotation_degrees:x", camera_rotation_left.y, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		2:
			tween.tween_property(camera_pivot, "global_position", camera_position_right, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tween.parallel().tween_property(camera_pivot, "rotation_degrees:y", camera_rotation_right.x, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tween.parallel().tween_property(camera_pivot, "rotation_degrees:x", camera_rotation_right.y, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_on_tween_finished)

func _reset_camera_angle_position(duration: float = 0.5):
	if not camera_pivot:
		return
	var tween = create_tween()
	tween.tween_property(camera_pivot, "global_position", original_camera_position, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(camera_pivot, "rotation_degrees:y", original_camera_y_angle, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(camera_pivot, "rotation_degrees:x", original_camera_x_angle, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_on_tween_finished)

func _on_tween_finished():
	camera_movement_finished.emit(current_camera_position)
	if current_camera_position == 1:
		emit_signal("camera_ready_for_book")

func _disable_swipe_input():
	swipe_input_enabled = false

func _enable_swipe_input():
	swipe_input_enabled = true

func _prepare_camera_zoom(target_object: Node3D):
	if not camera_pivot:
		return
	
	if not has_meta("original_position_before_zoom"):
		set_meta("original_position_before_zoom", camera_pivot.global_position)
		set_meta("original_rotation_before_zoom", camera_pivot.rotation_degrees)
	
	var target_position = target_object.global_position
	var current_position = camera_pivot.global_position
	var direction = (target_position - current_position).normalized()
	var target_distance = 1.0
	var zoom_position = target_position - direction * target_distance
	
	_disable_swipe_input()
	
	var tween = create_tween()
	tween.tween_property(camera_pivot, "global_position", zoom_position, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	camera_pivot.look_at(target_position)
	
	return tween

func _exit_tree():
	if vignette_rect and is_instance_valid(vignette_rect):
		vignette_rect.queue_free()
