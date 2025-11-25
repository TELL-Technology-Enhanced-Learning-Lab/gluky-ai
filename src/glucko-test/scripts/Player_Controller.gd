extends CharacterBody3D

@export var speed: float = 10.0
@export var gravity: float = 40.0
@export var jump_vel: float = 15.0
@export var rotation_speed := 12.0
@export var stopping_speed := 1.0
@export var push_strength: float = 0
@export var push_duration: float = 0.1
@export var sprint_multiplier: float = 1.2

var glucoseVal: int = 50
var timer: float = 0.0
var _last_input_direction := Vector3.BACK
var _was_on_floor_last_frame := true
var _is_being_pushed: bool = false
var _push_velocity: Vector3 = Vector3.ZERO
var _push_timer: float = 0.0
var _is_sprinting: bool = false

@onready var game_setup = get_parent()
@onready var collection_area: Area3D = $CollectionArea
@onready var _skin: CharacterSkin = $PlayerSkin

func _ready() -> void:
	add_to_group("player")
	game_setup.update_value(glucoseVal)
	collection_area.body_entered.connect(_on_collection_area_body_entered)
	_last_input_direction = -global_transform.basis.z

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_glucose(delta)
	handle_push_effect(delta)
	update_animation_state()
	create_sprint_dust()
	move_and_slide()

func handle_movement(delta: float) -> void:
	if _is_being_pushed:
		return
	
	_is_sprinting = Input.is_action_pressed("sprint")
		
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.z += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	
	var camera = get_viewport().get_camera_3d()
	if camera:
		var camera_basis = camera.global_transform.basis
		var direction = camera_basis.z * input_dir.z + camera_basis.x * input_dir.x
		direction.y = 0
		direction = direction.normalized()
		
		var current_speed = speed * (sprint_multiplier if _is_sprinting else 1.0)
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		if direction.length() > 0.2:
			_last_input_direction = direction.normalized()
		
		var target_angle := Vector3.BACK.signed_angle_to(_last_input_direction, Vector3.UP)
		_skin.global_rotation.y = lerp_angle(_skin.rotation.y, target_angle, rotation_speed * delta)
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_vel

func handle_push_effect(delta: float) -> void:
	if _is_being_pushed:
		velocity.x = _push_velocity.x
		velocity.z = _push_velocity.z
		
		if not is_on_floor():
			velocity.y -= gravity * delta
		
		_push_timer -= delta
		
		if _push_timer <= 0:
			_is_being_pushed = false
			_push_velocity = Vector3.ZERO

func apply_push_force(push_direction: Vector3, strength: float = -1) -> void:
	var actual_strength = strength if strength > 0 else push_strength
	_push_velocity = push_direction.normalized() * actual_strength
	_push_velocity.y = 0
	_is_being_pushed = true
	_push_timer = push_duration

func update_animation_state() -> void:
	if not _skin:
		return
	
	if _is_being_pushed:
		_skin.fall()
		return
	
	var ground_speed := Vector2(velocity.x, velocity.z).length()
	var is_just_jumping := Input.is_action_just_pressed("jump") and is_on_floor()
	
	if is_just_jumping:
		_skin.jump()
	elif not is_on_floor():
		if velocity.y < 0:
			_skin.fall()
		else:
			_skin.jump()
	elif is_on_floor():
		if ground_speed > stopping_speed:
			_skin.move()
			var move_tilt = _last_input_direction.x * ground_speed / speed
			_skin.run_tilt = clamp(move_tilt, -1.0, 1.0)
		else:
			_skin.idle()
			_skin.run_tilt = 0.0
	
	_was_on_floor_last_frame = is_on_floor()

func create_sprint_dust():
	if _is_sprinting and is_on_floor() and velocity.length() > stopping_speed:
		if randf() < 0.3:
			var dust = MeshInstance3D.new()
			dust.mesh = SphereMesh.new()
			dust.mesh.radius = 0.2
			dust.mesh.height = 0.4
			
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.6, 0.4, 0.2, 0.8)
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			dust.material_override = material
			
			var behind_pos = global_position - global_transform.basis.z * 0.5
			behind_pos.y = global_position.y + 0.1
			
			get_tree().root.add_child(dust)
			dust.global_position = behind_pos
			
			var tween = create_tween()
			var target_pos = dust.global_position + Vector3(0, 0.5, 0)
			tween.parallel().tween_property(dust, "global_position", target_pos, 0.8)
			tween.parallel().tween_property(dust, "scale", Vector3.ZERO, 0.8)
			tween.tween_callback(dust.queue_free)

func handle_glucose(delta: float) -> void:
	timer += delta
	if timer >= 1.3:
		glucoseVal = max(0, glucoseVal - 1)
		game_setup.update_value(glucoseVal)
		timer = 0.0

func _on_collection_area_body_entered(body: Node3D) -> void:
	handle_collision(body)

func handle_collision(body: Node3D) -> void:
	if body.is_in_group("obstacles"): 
		var push_direction = global_position - body.global_position
		push_strength = (velocity.length() + 6) * 1.4; 
		push_direction.y = 0
		push_direction = push_direction.normalized()
		apply_push_force(push_direction)
	elif body.is_in_group("healthy foods"):
		glucoseVal = max(0, glucoseVal - 3)
		game_setup.update_value(glucoseVal)
		collect_item(body)
	elif body.is_in_group("sugary foods"):
		glucoseVal = min(100, glucoseVal + 4)
		game_setup.update_value(glucoseVal)
		collect_item(body)
	elif body.is_in_group("power ups"):
		glucoseVal = 50
		game_setup.update_value(glucoseVal)
		collect_item(body)

func collect_item(item: Node3D):
	item.queue_free()
