extends CharacterBody3D

@export var speed: float = 10.0
@export var gravity: float = 40.0
@export var jump_vel: float = 20.0

var glucoseVal: int = 50
var timer: float = 0.0

@onready var game_setup = get_parent()
@onready var collection_area: Area3D = $CollectionArea

func _ready() -> void:
	add_to_group("player")
	game_setup.update_value(glucoseVal)
	collection_area.body_entered.connect(_on_collection_area_body_entered)

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_glucose(delta)
	move_and_slide()

func handle_movement(delta: float) -> void:
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.z += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	input_dir = input_dir.normalized()
	
	var camera = get_viewport().get_camera_3d()
	if camera:
		var camera_basis = camera.global_transform.basis
		var direction = camera_basis.z * input_dir.z + camera_basis.x * input_dir.x
		direction.y = 0
		direction = direction.normalized()
		
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		if direction.length() > 0.1:
			look_at(global_position - direction, Vector3.UP)
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_vel

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
		get_tree().reload_current_scene()
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
