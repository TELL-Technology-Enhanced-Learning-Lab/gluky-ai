extends CharacterBody3D

@export var speed: float = 10.0
@export var gravity: float = 40.0
@export var jump_vel: float = 15.0
@export var rotation_speed := 12.0
@export var stopping_speed := 1.0
@export var push_strength: float = 0
@export var push_duration: float = 0.1
@export var sprint_multiplier: float = 1.2

var timer: float = 0.0
var _last_input_direction := Vector3.BACK
var _was_on_floor_last_frame := true
var _is_being_pushed: bool = false
var _push_velocity: Vector3 = Vector3.ZERO
var _push_timer: float = 0.0
var _is_sprinting: bool = false
var _is_invincible: bool = false

@onready var collection_area: Area3D = $CollectionArea
@onready var _skin: CharacterSkin = $PlayerSkin
@onready var game_setup = get_parent()

var glucose_bar = null

func _ready() -> void:
	add_to_group("player")
	collection_area.body_entered.connect(_on_collection_area_body_entered)
	collection_area.area_entered.connect(_on_collection_area_area_entered)
	_last_input_direction = -global_transform.basis.z
	game_setup.glucose_bar_ready.connect(_on_glucose_bar_ready)

func _on_glucose_bar_ready():
	glucose_bar = get_parent().get_node("GlucoseUI")

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_push_effect(delta)
	update_animation_state()
	create_sprint_dust()
	move_and_slide()

func handle_movement(delta: float) -> void:
	if _is_being_pushed:
		if glucose_bar:
			glucose_bar.set_moving_state(false, false)
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
	
	if glucose_bar:
		var is_moving = input_dir.length() > 0.1 and is_on_floor()
		glucose_bar.set_moving_state(is_moving, _is_sprinting)
	
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
