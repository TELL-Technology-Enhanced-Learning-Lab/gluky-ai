extends Camera3D

@export var player_node: Node3D
@export var look_sensitivity: float = 0.002
@export var behind_offset: Vector3 = Vector3(0, 1.5, 3)
@export var transition_height: float = 2.0

enum CameraState { EYE_OPENING, GETTING_UP, LOOK_AROUND, DETACH_AND_MOVE_BEHIND, PLAYER_CONTROL }
var current_state: CameraState = CameraState.EYE_OPENING
var animation_time: float = 0.0

var eye_opening_duration: float = 2.0
var getting_up_duration: float = 1.5
var look_around_duration: float = 2.0
var detach_duration: float = 1.0

var look_targets: Array = [
	Vector2(0.5, 0.3),   
	Vector2(-0.3, 0.2),  
	Vector2(0, 0)        
]

var original_parent: Node3D
var original_local_transform: Transform3D
var original_global_rotation: Vector3
var detach_start_pos: Vector3
var detach_end_pos: Vector3
var camera_pivot: Node3D

func _ready():
	original_parent = get_parent()
	original_local_transform = transform
	original_global_rotation = global_rotation_degrees
	
	fov = 10
	animation_time = 0.0
	
	set_process_input(false)

func _process(delta):
	match current_state:
		CameraState.EYE_OPENING:
			_animate_eye_opening(delta)
		CameraState.GETTING_UP:
			_animate_getting_up(delta)
		CameraState.LOOK_AROUND:
			_animate_look_around(delta)
		CameraState.DETACH_AND_MOVE_BEHIND:
			_animate_detach_and_move_behind(delta)
		CameraState.PLAYER_CONTROL:
			_handle_player_control(delta)

func _animate_eye_opening(delta):
	animation_time += delta
	var progress = animation_time / eye_opening_duration
	
	fov = lerp(10.0, 70.0, ease(progress, 0.5))
	
	var breath_offset = sin(animation_time * 2.0) * 0.01
	position.y += breath_offset
	
	if animation_time >= eye_opening_duration:
		current_state = CameraState.GETTING_UP
		animation_time = 0.0

func _animate_getting_up(delta):
	animation_time += delta
	var progress = animation_time / getting_up_duration
	var eased_progress = ease(progress, 0.3)
	
	var original_x_rot = original_global_rotation.x
	rotation_degrees.x = lerp(original_x_rot, 0.0, eased_progress)
	
	var wobble = sin(animation_time * 5.0) * 0.02 * (1.0 - eased_progress)
	rotation_degrees.z = wobble
	
	if animation_time >= getting_up_duration:
		current_state = CameraState.LOOK_AROUND
		animation_time = 0.0

func _animate_look_around(delta):
	animation_time += delta
	var progress = min(animation_time / look_around_duration, 1.0)
	
	var segment = progress * (look_targets.size() - 1)
	var segment_index = int(segment)
	var segment_progress = segment - segment_index
	
	if segment_index < look_targets.size() - 1:
		var start_look = look_targets[segment_index]
		var end_look = look_targets[segment_index + 1]
		
		var current_look = start_look.lerp(end_look, segment_progress)
		
		rotation_degrees.y = original_global_rotation.y + current_look.x * 30
		rotation_degrees.x = current_look.y * 20
	
	if animation_time >= look_around_duration:
		current_state = CameraState.DETACH_AND_MOVE_BEHIND
		animation_time = 0.0
		_prepare_detach()

func _prepare_detach():
	detach_start_pos = global_transform.origin
	
	if player_node:
		var player_pos = player_node.global_transform.origin
		var player_forward = -player_node.global_transform.basis.z
		detach_end_pos = player_pos + player_forward * behind_offset.z + Vector3(0, behind_offset.y, 0)

func _animate_detach_and_move_behind(delta):
	animation_time += delta
	var progress = min(animation_time / detach_duration, 1.0)
	var eased_progress = ease(progress, 0.5)
	
	if player_node and detach_end_pos:
		var current_pos = detach_start_pos.lerp(detach_end_pos, eased_progress)
		var arc_height = transition_height * sin(PI * eased_progress)
		current_pos.y += arc_height
		
		var scene_root = get_tree().root
		var old_parent = get_parent()
		
		if is_inside_tree() and camera_pivot == null:
			old_parent.remove_child(self)
			
			camera_pivot = Node3D.new()
			camera_pivot.name = "CameraPivot"
			scene_root.add_child(camera_pivot)
			camera_pivot.global_transform.origin = current_pos
			
			camera_pivot.add_child(self)
			transform = Transform3D()
			position = Vector3.ZERO
		
		if camera_pivot:
			camera_pivot.global_transform.origin = current_pos
			
			var look_target = player_node.global_transform.origin + Vector3(0, 1.0, 0)
			camera_pivot.look_at(look_target)
			camera_pivot.rotate_object_local(Vector3(1, 0, 0), deg_to_rad(-10))
	
	if animation_time >= detach_duration:
		current_state = CameraState.PLAYER_CONTROL
		set_process_input(true)

func _handle_player_control(_delta):
	pass

func _input(event):
	if current_state != CameraState.PLAYER_CONTROL:
		return
	
	if event is InputEventScreenDrag and camera_pivot:
		var look_rotation = Vector2(
			-event.relative.x * look_sensitivity,
			-event.relative.y * look_sensitivity
		)
		
		camera_pivot.rotate_y(look_rotation.x)
		
		var current_vertical = camera_pivot.rotation_degrees.x
		var new_vertical = current_vertical + look_rotation.y
		camera_pivot.rotation_degrees.x = clamp(new_vertical, -30, 30)
		
		if player_node:
			var look_direction = -camera_pivot.global_transform.basis.z
			look_direction.y = 0
			look_direction = look_direction.normalized()
			
			if look_direction.length() > 0.1:
				var target_rotation = atan2(look_direction.x, look_direction.z)
				player_node.rotation.y = lerp_angle(player_node.rotation.y, target_rotation, 0.1)

func reset_camera():
	if camera_pivot:
		camera_pivot.remove_child(self)
		camera_pivot.queue_free()
		camera_pivot = null
	
	if original_parent:
		var scene_root = get_tree().root
		if get_parent() != original_parent:
			if is_inside_tree():
				get_parent().remove_child(self)
			original_parent.add_child(self)
	
	transform = original_local_transform
	global_rotation_degrees = original_global_rotation
	fov = 10
	
	current_state = CameraState.EYE_OPENING
	animation_time = 0.0
	
	set_process_input(false)
