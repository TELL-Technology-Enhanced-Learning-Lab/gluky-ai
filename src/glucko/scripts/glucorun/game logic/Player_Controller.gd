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

var _last_input_direction := Vector3.BACK
var _is_being_pushed := false
var _push_velocity := Vector3.ZERO
var _push_timer := 0.0
var _is_sprinting := false
var _wants_to_sprint := false
var _is_invincible := false
var _is_mobile := false
var _mobile_move_input := Vector2.ZERO
var _jump_requested := false

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

func _ready():
	add_to_group("player")
	collection_area.body_entered.connect(_on_collection_area_body_entered)
	collection_area.area_entered.connect(_on_collection_area_area_entered)
	_last_input_direction = -global_transform.basis.z
	game_setup.glucose_bar_ready.connect(_on_glucose_bar_ready)
	game_setup.ui_ready.connect(_on_ui_ready)
	_is_mobile = OS.get_name() == "Android" or OS.get_name() == "iOS"
	if enable_mobile_controls and _is_mobile:
		call_deferred("setup_mobile_controls")

func setup_mobile_controls():
	var mobile_scene = preload("res://scenes/user interface/Mobile_Controls_Glucorun.tscn")
	mobile_controls_ui = mobile_scene.instantiate()
	get_tree().root.add_child(mobile_controls_ui)
	await get_tree().process_frame
	move_joystick = mobile_controls_ui.find_child("MoveJoystick")
	look_joystick = mobile_controls_ui.find_child("LookJoystick")
	sprint_button = mobile_controls_ui.find_child("SprintButton")
	jump_button = mobile_controls_ui.find_child("JumpButton")
	if move_joystick:
		move_joystick.movement_joystick_updated.connect(_on_move_joystick_updated)
	if sprint_button:
		sprint_button.pressed.connect(_on_sprint_button_pressed)
	if jump_button:
		jump_button.pressed.connect(_on_jump_button_pressed)

func _on_move_joystick_updated(value: Vector2):
	_mobile_move_input = Vector2(value.x, -value.y)

func _on_sprint_button_pressed():
	_wants_to_sprint = not _wants_to_sprint
	if glucose_bar:
		glucose_bar.set_moving_state(false, _wants_to_sprint)

func _on_jump_button_pressed():
	_jump_requested = true

func _on_glucose_bar_ready():
	glucose_bar = game_setup.get_glucose_bar()

func _on_ui_ready():
	insulin_ui = game_setup.get_insulin_counter()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	handle_movement(delta)
	handle_push_effect(delta)
	update_animation_state()
	create_sprint_dust()
	move_and_slide()
	handle_insulin_input()

func handle_movement(delta):
	if _is_being_pushed:
		if glucose_bar:
			glucose_bar.set_moving_state(false, _is_sprinting)
		return
	var move_input := Vector2.ZERO
	if _is_mobile and enable_mobile_controls and mobile_controls_ui:
		move_input = _mobile_move_input if _mobile_move_input.length() > mobile_joystick_deadzone else Vector2.ZERO
	else:
		move_input = Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
		)
	if is_on_floor() and (_jump_requested or Input.is_action_just_pressed("jump")):
		velocity.y = jump_vel
		_jump_requested = false
	if move_input.length() == 0:
		_is_sprinting = false
		velocity.x = move_toward(velocity.x, 0, stopping_speed)
		velocity.z = move_toward(velocity.z, 0, stopping_speed)
		if glucose_bar:
			glucose_bar.set_moving_state(false, _wants_to_sprint)
		return
	move_input = move_input.normalized()
	_is_sprinting = _wants_to_sprint
	if not _is_mobile:
		if Input.is_action_pressed("sprint"):
			_is_sprinting = true
		else:
			_is_sprinting = false
	var camera = get_viewport().get_camera_3d()
	if camera:
		var forward = -camera.global_transform.basis.z
		var right = camera.global_transform.basis.x
		var move_direction = (forward * move_input.y + right * move_input.x)
		move_direction.y = 0
		move_direction = move_direction.normalized()
		var current_speed = speed * (sprint_multiplier if _is_sprinting else 1.0)
		velocity.x = move_direction.x * current_speed
		velocity.z = move_direction.z * current_speed
		_last_input_direction = move_direction
		var target_angle = Vector3.BACK.signed_angle_to(_last_input_direction, Vector3.UP)
		_skin.global_rotation.y = lerp_angle(
			_skin.rotation.y,
			target_angle,
			rotation_speed * delta
		)
	if glucose_bar:
		glucose_bar.set_moving_state(true, _is_sprinting)

func _input(event):
	if not _is_mobile:
		if event.is_action_pressed("sprint"):
			_wants_to_sprint = true
			if glucose_bar:
				glucose_bar.set_moving_state(true, true)
		elif event.is_action_released("sprint"):
			_wants_to_sprint = false
			if glucose_bar:
				glucose_bar.set_moving_state(true, false)

func handle_push_effect(delta):
	if _is_being_pushed:
		velocity.x = _push_velocity.x
		velocity.z = _push_velocity.z
		if not is_on_floor():
			velocity.y -= gravity * delta
		_push_timer -= delta
		if _push_timer <= 0:
			_is_being_pushed = false
			_push_velocity = Vector3.ZERO

func apply_push_force(push_direction: Vector3, strength := -1):
	var actual_strength: float = push_strength
	if strength > 0:
		actual_strength = strength
	_push_velocity = push_direction.normalized() * actual_strength
	_push_velocity.y = 0
	_is_being_pushed = true
	_push_timer = push_duration

func start_invincibility(duration):
	_is_invincible = true
	await get_tree().create_timer(duration).timeout
	_is_invincible = false

func update_animation_state():
	if _is_being_pushed:
		_skin.fall()
		return
	var ground_speed = Vector2(velocity.x, velocity.z).length()
	if not is_on_floor():
		if velocity.y > 0:
			_skin.jump()
		else:
			_skin.fall()
	elif ground_speed > stopping_speed:
		_skin.move()
		_skin.run_tilt = clamp(
			_last_input_direction.x * ground_speed / speed,
			-1.0,
			1.0
		)
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
			behind_pos.y += 0.1
			get_tree().root.add_child(dust)
			dust.global_position = behind_pos
			var tween = create_tween()
			tween.parallel().tween_property(
				dust,
				"global_position",
				behind_pos + Vector3.UP * 0.5,
				0.8
			)
			tween.parallel().tween_property(
				dust,
				"scale",
				Vector3.ZERO,
				0.8
			)
			tween.tween_callback(dust.queue_free)

func handle_insulin_input():
	if Input.is_action_just_pressed("inject_insulin") and insulin_ui and insulin_ui.get_insulin_available() > 0:
		if glucose_bar:
			glucose_bar.inject_insulin(INSULIN_EFFECT_MGDL, INSULIN_DURATION)
			insulin_ui.use_insulin()

func _on_collection_area_body_entered(body):
	handle_collision(body)

func _on_collection_area_area_entered(area):
	handle_collision(area)

func handle_collision(collider, food_data := {}):
	if collider.is_in_group("Obstacle"):
		if _is_invincible:
			return
		var push_direction = global_position - collider.global_position
		push_strength = (
			velocity.length()
			+ (25 if collider.is_in_group("Moving") else 6)
		) * 1.4
		push_direction.y = 0
		apply_push_force(push_direction)
		start_invincibility(1.0)
	elif collider.is_in_group("HealthyFood") or collider.is_in_group("SugaryFood"):
		if glucose_bar:
			var glucose_amount = food_data.get(
				"glucose_amount",
				15.0 if collider.is_in_group("HealthyFood") else 60.0
			)
			var duration = food_data.get(
				"effect_duration",
				30.0 if collider.is_in_group("HealthyFood") else 45.0
			)
			var effect_id = str(randi())
			glucose_bar.add_food_effect(effect_id, glucose_amount, duration)

func collect_item(item):
	item.queue_free()
