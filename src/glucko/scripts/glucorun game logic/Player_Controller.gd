extends CharacterBody3D

@export var speed: float = 10.0
@export var gravity: float = 40.0
@export var jump_vel: float = 15.0
@export var rotation_speed := 12.0
@export var stopping_speed := 1.0
@export var push_strength: float = 0
@export var push_duration: float = 0.1
@export var sprint_multiplier: float = 1.2
@export var enable_mobile_controls: bool = true
@export var mobile_joystick_deadzone: float = 0.2
@export var mobile_camera_sensitivity: float = 0.005

var _last_input_direction := Vector3.BACK
var _is_being_pushed: bool = false
var _push_velocity: Vector3 = Vector3.ZERO
var _push_timer: float = 0.0
var _is_sprinting: bool = false
var _is_invincible: bool = false
var _is_mobile: bool = false
var _mobile_move_input: Vector2 = Vector2.ZERO
var _mobile_look_input: Vector2 = Vector2.ZERO
var _jump_requested: bool = false

@onready var collection_area: Area3D = $CollectionArea
@onready var _skin: CharacterSkin = $PlayerSkin
@onready var game_setup = get_parent()

var mobile_controls_ui: Node = null
var move_joystick = null
var look_joystick = null
var sprint_button = null
var jump_button = null
var glucose_bar = null
var insulin_ui = null

const INSULIN_EFFECT_MGDL := 80.0
const INSULIN_DURATION := 30.0

func _ready() -> void:
	add_to_group("player")
	collection_area.body_entered.connect(_on_collection_area_body_entered)
	collection_area.area_entered.connect(_on_collection_area_area_entered)
	_last_input_direction = -global_transform.basis.z
	game_setup.glucose_bar_ready.connect(_on_glucose_bar_ready)
	game_setup.ui_ready.connect(_on_ui_ready)
	
	_is_mobile = OS.get_name() == "Android" or OS.get_name() == "iOS"
	
	if enable_mobile_controls:
		call_deferred("setup_mobile_controls")

func setup_mobile_controls():
	var mobile_scene = preload("res://art/user interface/mobile_controls.tscn")
	if not mobile_scene:
		get_tree().quit()
		return
	
	mobile_controls_ui = mobile_scene.instantiate()
	get_tree().root.add_child.call_deferred(mobile_controls_ui)
	await get_tree().process_frame
	
	move_joystick = mobile_controls_ui.find_child("MoveJoystick")
	look_joystick = mobile_controls_ui.find_child("LookJoystick")
	sprint_button = mobile_controls_ui.find_child("SprintButton")
	jump_button = mobile_controls_ui.find_child("JumpButton")
	
	if move_joystick:
		if move_joystick.has_signal("movement_joystick_updated"):
			move_joystick.movement_joystick_updated.connect(_on_move_joystick_updated)
		else:
			get_tree().quit()
			return
	
	if look_joystick:
		if look_joystick.has_signal("look_joystick_updated"):
			look_joystick.look_joystick_updated.connect(_on_look_joystick_updated)
		else:
			get_tree().quit()
			return
	
	if sprint_button:
		if sprint_button is TextureButton:
			sprint_button.toggle_mode = true
			sprint_button.button_pressed = false
			sprint_button.pressed.connect(_on_sprint_button_pressed)
	
	if jump_button:
		jump_button.pressed.connect(_on_jump_button_pressed)

func _on_move_joystick_updated(value: Vector2):
	_mobile_move_input = Vector2(value.x, -value.y)

func _on_look_joystick_updated(value: Vector2):
	_mobile_look_input = value

func _on_sprint_button_pressed():
	_is_sprinting = sprint_button.button_pressed

func _on_jump_button_pressed():
	_jump_requested = true

func _on_glucose_bar_ready():
	glucose_bar = game_setup.get_glucose_bar()

func _on_ui_ready():
	insulin_ui = game_setup.get_insulin_counter()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	handle_movement(delta)
	handle_push_effect(delta)
	update_animation_state()
	create_sprint_dust()
	move_and_slide()
	handle_insulin_input()
	
	if _is_mobile and enable_mobile_controls:
		handle_mobile_camera(delta)

func handle_mobile_camera(_delta: float):
	var camera = get_viewport().get_camera_3d()
	if camera and camera is Camera3D:
		if _mobile_look_input.length() > mobile_joystick_deadzone:
			camera.rotate_y(-_mobile_look_input.x * mobile_camera_sensitivity)
			var current_rotation = camera.rotation.x
			var new_pitch = current_rotation - _mobile_look_input.y * mobile_camera_sensitivity
			camera.rotation.x = clamp(new_pitch, -PI/3, PI/3)

func handle_movement(delta: float) -> void:
	if _is_being_pushed:
		if glucose_bar:
			glucose_bar.set_moving_state(false, false)
		return
	
	var move_input = _mobile_move_input if (_is_mobile and enable_mobile_controls and _mobile_move_input.length() > mobile_joystick_deadzone) else Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	)
	
	if move_input.length() == 0:
		velocity.x = move_toward(velocity.x, 0, stopping_speed)
		velocity.z = move_toward(velocity.z, 0, stopping_speed)
		if glucose_bar:
			glucose_bar.set_moving_state(false, false)
		return
	
	if move_input.length() > 1.0:
		move_input = move_input.normalized()
	
	var camera = get_viewport().get_camera_3d()
	if camera:
		var camera_transform = camera.global_transform
		var forward = -camera_transform.basis.z
		var right = camera_transform.basis.x
		var move_direction = Vector3.ZERO
		move_direction += forward * move_input.y
		move_direction += right * move_input.x
		move_direction.y = 0
		
		if move_direction.length() > 0.1:
			move_direction = move_direction.normalized()
			var current_speed = speed * (sprint_multiplier if _is_sprinting else 1.0)
			velocity.x = move_direction.x * current_speed
			velocity.z = move_direction.z * current_speed
			_last_input_direction = move_direction
			var target_angle := Vector3.BACK.signed_angle_to(_last_input_direction, Vector3.UP)
			_skin.global_rotation.y = lerp_angle(_skin.rotation.y, target_angle, rotation_speed * delta)
	
	if glucose_bar:
		var is_moving = move_input.length() > 0.1 and is_on_floor()
		glucose_bar.set_moving_state(is_moving, _is_sprinting)
	
	if is_on_floor():
		if _jump_requested:
			velocity.y = jump_vel
			_jump_requested = false
		elif not _is_mobile or not enable_mobile_controls:
			if Input.is_action_just_pressed("jump"):
				velocity.y = jump_vel
	else:
		_jump_requested = false

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
			if glucose_bar:
				glucose_bar.set_moving_state(false, false)

func apply_push_force(push_direction: Vector3, strength: float = -1) -> void:
	var actual_strength = strength if strength > 0 else push_strength
	_push_velocity = push_direction.normalized() * actual_strength
	_push_velocity.y = 0
	_is_being_pushed = true
	_push_timer = push_duration

func start_invincibility(duration: float) -> void:
	_is_invincible = true
	await get_tree().create_timer(duration).timeout
	_is_invincible = false

func update_animation_state() -> void:
	if not _skin:
		return
	
	if _is_being_pushed:
		_skin.fall()
		return
	
	var ground_speed := Vector2(velocity.x, velocity.z).length()
	
	if not is_on_floor():
		if velocity.y > 0:
			_skin.jump()
		else:
			_skin.fall()
	elif is_on_floor():
		if ground_speed > stopping_speed:
			_skin.move()
			var move_tilt = _last_input_direction.x * ground_speed / speed
			_skin.run_tilt = clamp(move_tilt, -1.0, 1.0)
		else:
			_skin.idle()
			_skin.run_tilt = 0.0

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

func handle_insulin_input():
	if Input.is_action_just_pressed("inject_insulin"):
		if insulin_ui and insulin_ui.get_insulin_available() > 0:
			if glucose_bar:
				glucose_bar.inject_insulin(INSULIN_EFFECT_MGDL, INSULIN_DURATION)
				insulin_ui.use_insulin()

func _on_collection_area_body_entered(body: Node) -> void:
	handle_collision(body)

func _on_collection_area_area_entered(area: Area3D) -> void:
	handle_collision(area)

func handle_collision(collider: Node3D, food_data: Dictionary = {}):
	if collider.is_in_group("Obstacle"):
		if _is_invincible:
			return
		var push_direction = global_position - collider.global_position
		if collider.is_in_group("Moving"):
			push_strength = (velocity.length() + 25) * 1.4
		else:
			push_strength = (velocity.length() + 6) * 1.4
		push_direction.y = 0
		push_direction = push_direction.normalized()
		apply_push_force(push_direction)
		start_invincibility(1.0)
	elif collider.is_in_group("HealthyFood") or collider.is_in_group("SugaryFood"):
		var glucose_amount = food_data.get("glucose_amount", 15.0 if collider.is_in_group("HealthyFood") else 60.0)
		var duration = food_data.get("effect_duration", 30.0 if collider.is_in_group("HealthyFood") else 45.0)
		
		if glucose_bar and glucose_bar.has_method("add_food_effect"):
			var food_type = "HealthyFood" if collider.is_in_group("HealthyFood") else "SugaryFood"
			var effect_id = food_type + "_" + str(randi())
			glucose_bar.add_food_effect(effect_id, glucose_amount, duration)

func collect_item(item: Node3D):
	item.queue_free()
