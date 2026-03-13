extends CharacterBody3D

#piu inertia
@export var ACCELERATION := 8.0
@export var DECELERATION := 9.0
@export var AIR_CONTROL := 2.5
@export var enable_mobile_controls: bool = true

#camera cinematic
@export var SWAY_STRENGTH := 0.005
@export var SWAY_SMOOTH := 10.0
@export var CAMERA_LAG := 9.0
@export var CAMERA_TILT := 0.025

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D
@onready var ray_cast_3d: RayCast3D = $CameraPivot/Camera3D/RayCast3D
@onready var hand_marker: Node3D = $ObjectMarker3D
@onready var headmovement = get_node("simulateMovement")

signal interact_object

const SPEED: float = 3.5
const JUMP_VELOCITY: float = 4.0
const CAMERA_SENS: float = 0.003

var gravity = 9.8
var pickedObject: Node3D = null
var collider: Node = null
# Salva l'ultimo cibo visto dal raycast — rimane valido anche quando
# il dito tocca il pulsante e il raycast perde il bersaglio per un frame
var _last_valid_collider: Node = null

# variabili interne (stato della camera)
var sway_target := 0.0
var current_sway := 0.0
var camera_offset := Vector3.ZERO

# ------- MOBILE -------
var _is_mobile := false
var _mobile_look_input := Vector2.ZERO
var _pickup_requested := false

var mobile_controls_ui: Node = null
var move_joystick = null
var look_joystick = null
var pickup_button = null

func _ready() -> void:
	ray_cast_3d.enabled = true
	ray_cast_3d.target_position = Vector3(0, 0, -3.0)
	add_to_group("player")
	headmovement.play("walk")

	_is_mobile = OS.get_name() == "Android" or OS.get_name() == "iOS"
	
	if enable_mobile_controls and _is_mobile:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		call_deferred("setup_mobile_controls")
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func setup_mobile_controls() -> void:
	var mobile_scene = preload("res://scenes/MealPerfectgameScenes/mobile_controls_pm.tscn")
	mobile_controls_ui = mobile_scene.instantiate()
	get_tree().root.add_child(mobile_controls_ui)
	await get_tree().process_frame

	move_joystick = mobile_controls_ui.find_child("move_joystick")
	look_joystick = mobile_controls_ui.find_child("look_joystick")
	pickup_button = mobile_controls_ui.find_child("PickupAndDropButton")

	if move_joystick:
		move_joystick.movement_joystick_updated.connect(_on_move_joystick_updated)
	if look_joystick:
		look_joystick.look_joystick_updated.connect(_on_look_joystick_updated)
	if pickup_button:
		pickup_button.pressed.connect(_on_pickup_button_pressed)

func _on_move_joystick_updated(_value: Vector2) -> void:
	pass

func _on_look_joystick_updated(value: Vector2) -> void:
	_mobile_look_input = value

func _on_pickup_button_pressed() -> void:
	_pickup_requested = true

# -------  INPUT  -------
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		get_tree().quit()

	if not _is_mobile and event is InputEventMouseMotion:
		rotation.y -= event.relative.x * CAMERA_SENS
		rotation.x = clamp(rotation.x - event.relative.y * CAMERA_SENS, -0.7, 1)

	if event.is_action_pressed("interact"):
		_handle_interact(collider)

# ------- PHYSICS -------
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if _pickup_requested:
		_pickup_requested = false
		_handle_interact(_last_valid_collider)

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	apply_camera_sway(delta, input_dir)

	var target_velocity := Vector3.ZERO

	if direction:
		target_velocity = direction * SPEED
		if is_on_floor():
			head_move(2.0)
			velocity.x = move_toward(velocity.x, target_velocity.x, ACCELERATION * delta)
			velocity.z = move_toward(velocity.z, target_velocity.z, ACCELERATION * delta)
		else:
			head_move(0.0)
			velocity.x = move_toward(velocity.x, target_velocity.x, AIR_CONTROL * delta)
			velocity.z = move_toward(velocity.z, target_velocity.z, AIR_CONTROL * delta)
	else:
		head_move(0.0)
		var decel := DECELERATION if is_on_floor() else AIR_CONTROL
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)
		velocity.z = move_toward(velocity.z, 0.0, decel * delta)

	if _is_mobile and _mobile_look_input != Vector2.ZERO:
		var look_sens := CAMERA_SENS * 10.0 # da mobile quest'azione gestisce la durezza del movimento della cameraa
		rotation.y -= _mobile_look_input.x * look_sens
		rotation.x = clamp(
			rotation.x - _mobile_look_input.y * look_sens,
			-0.7, 1.0
		)

	apply_camera_lag(delta)

	velocity.x = clamp(velocity.x, -SPEED, SPEED)
	velocity.z = clamp(velocity.z, -SPEED, SPEED)
	move_and_slide()

# Gestisce pickup e drop sia da tastiera (desktop) che da pulsante (mobile).
# - target: il cibo da raccogliere (_last_valid_collider su mobile, collider su desktop)
# - per il drop usa sempre collider aggiornato in tempo reale
func _handle_interact(target: Node) -> void:
	if pickedObject:
		# Oggetto in mano: prova a depositarlo su piatto o tavolo
		if collider == pickedObject:
			return
		if collider is store_object:
			if collider.add_object(pickedObject):
				pickedObject = null
			return
		var t := collider
		while t and not t.is_in_group("table"):
			t = t.get_parent()
		if t and t.is_in_group("table"):
			drop_to_table(t)
			return
	else:
		# Mani vuote: prova a raccogliere il cibo puntato
		if target and target.is_in_group("food") and pickedObject == null:
			if target.has_method("on_dropped"):
				pick_up_object(target)

# ------- CAMERA -------
func apply_camera_sway(delta: float, input_dir: Vector2) -> void:
	sway_target = -input_dir.x * SWAY_STRENGTH
	current_sway = lerp(current_sway, sway_target, SWAY_SMOOTH * delta)
	camera_3d.rotation.z = current_sway

func apply_camera_lag(delta: float) -> void:
	var target_offset := Vector3.ZERO
	if is_on_floor() and velocity.length() > 0.1:
		target_offset.z = -velocity.length() * CAMERA_TILT
	camera_offset = camera_offset.lerp(target_offset, CAMERA_LAG * delta)
	camera_pivot.position = camera_offset
	if velocity.length() < 0.05:
		camera_offset = camera_offset.lerp(Vector3.ZERO, 6.0 * delta)

# ------- PROCESS -------
func _process(_delta: float) -> void:
	ray_cast_3d.force_raycast_update()
	if ray_cast_3d.is_colliding():
		collider = ray_cast_3d.get_collider()
		interact_object.emit(collider)
		# Salva solo il cibo — tavolo e piatto vengono gestiti tramite collider diretto
		if collider and collider.is_in_group("food"):
			_last_valid_collider = collider
	else:
		collider = null
		interact_object.emit(null)
		# Azzera solo se il nodo non esiste più in scena (es. già raccolto)
		if _last_valid_collider != null and not is_instance_valid(_last_valid_collider):
			_last_valid_collider = null

# ------- UTILITY -------
func head_move(value: float) -> void:
	if headmovement.speed_scale != value:
		headmovement.speed_scale = value

func pick_up_object(object: Node3D) -> void:
	pickedObject = object
	var col := object.get_node_or_null("CollisionShape3D")
	if col:
		col.disabled = true
	if object is StaticBody3D:
		object.set_physics_process(false)
	if object.get_parent():
		object.get_parent().remove_child(object)
	hand_marker.add_child(object)
	object.transform = Transform3D()
	var orig_scale = object.get("original_scale")
	if orig_scale:
		object.scale = orig_scale

func drop_to_table(table: Node) -> void:
	if not pickedObject:
		return
	var obj := pickedObject
	var marker_to_use: Node3D = obj.last_marker
	if marker_to_use != null and marker_to_use.get_parent() == table and marker_to_use.get_child_count() == 0:
		table.add_object(obj, marker_to_use)
	else:
		table.add_object(obj)
	pickedObject = null


func _on_btn_exit_mpg_2_pressed() -> void:
		get_tree().change_scene_to_file("res://scenes/menus/glucky/Minigame_Selection.tscn")


func _on_btn_exit_mpg_3_pressed() -> void:
		get_tree().change_scene_to_file("res://scenes/menus/glucky/Minigame_Selection.tscn")
