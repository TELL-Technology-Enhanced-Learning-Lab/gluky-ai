class_name VirtualJoystick
extends Control

signal movement_joystick_updated(value: Vector2)

@export var deadzone_size: float = 0.15
@export var max_distance: float = 100.0
@export var joystick_texture: Texture2D
@export var handle_texture: Texture2D
@export var sensitivity: float = 1.0
@export var pressed_color := Color.GRAY
enum Joystick_mode { FIXED, DYNAMIC }
@export var joystick_mode := Joystick_mode.FIXED
enum Visibility_mode { ALWAYS, TOUCHSCREEN_ONLY }
@export var visibility_mode := Visibility_mode.ALWAYS
@export var use_input_actions := true
@export var action_left := "move_left"
@export var action_right := "move_right"
@export var action_up := "move_forward"
@export var action_down := "move_backward"

var joystick_active := false
var output := Vector2.ZERO
var _is_dragging: bool = false
var _touch_index: int = -1
var _center_position: Vector2 = Vector2.ZERO
var _current_position: Vector2 = Vector2.ZERO
var _handle_sprite: Sprite2D
var _joystick_sprite: Sprite2D
var _default_color: Color

func _ready():
	_setup_visuals()
	_center_position = position + size / 2
	
	if not DisplayServer.is_touchscreen_available() and visibility_mode == Visibility_mode.TOUCHSCREEN_ONLY:
		hide()

func _setup_visuals():
	if joystick_texture:
		_joystick_sprite = Sprite2D.new()
		_joystick_sprite.texture = joystick_texture
		_joystick_sprite.position = size / 2
		_joystick_sprite.centered = true
		add_child(_joystick_sprite)
	
	if handle_texture:
		_handle_sprite = Sprite2D.new()
		_handle_sprite.texture = handle_texture
		_handle_sprite.position = size / 2
		_handle_sprite.centered = true
		add_child(_handle_sprite)
		_default_color = _handle_sprite.modulate

func _process(_delta):
	if _is_dragging and _current_position.length() > deadzone_size:
		output = _current_position * sensitivity
		movement_joystick_updated.emit(output)
		
		if use_input_actions:
			if output.x < 0:
				_update_input_action(action_left, -output.x)
			else:
				_update_input_action(action_right, output.x)
			
			if output.y < 0:
				_update_input_action(action_up, -output.y)
			else:
				_update_input_action(action_down, output.y)

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed and not _is_dragging:
			if joystick_mode == Joystick_mode.DYNAMIC or (joystick_mode == Joystick_mode.FIXED and _is_point_inside_base(event.position)):
				if joystick_mode == Joystick_mode.DYNAMIC:
					_move_base(event.position)
				_is_dragging = true
				_touch_index = event.index
				_center_position = position + size / 2
				update_joystick(event.position)
				if _handle_sprite:
					_handle_sprite.modulate = pressed_color
				joystick_active = true
		elif not event.pressed and event.index == _touch_index:
			_reset()
			movement_joystick_updated.emit(Vector2.ZERO)
	
	elif event is InputEventScreenDrag and _is_dragging and event.index == _touch_index:
		update_joystick(event.position)

func _move_base(new_position: Vector2):
	position = new_position - size / 2

func _is_point_inside_base(point: Vector2) -> bool:
	var x: bool = point.x >= global_position.x and point.x <= global_position.x + (size.x * get_global_transform_with_canvas().get_scale().x)
	var y: bool = point.y >= global_position.y and point.y <= global_position.y + (size.y * get_global_transform_with_canvas().get_scale().y)
	return x and y

func update_joystick(touch_position: Vector2):
	var direction = touch_position - _center_position
	var distance = direction.length()
	
	if distance > max_distance:
		direction = direction.normalized() * max_distance
	
	_current_position = direction / max_distance
	
	if _current_position.length() < deadzone_size:
		_current_position = Vector2.ZERO
		joystick_active = false
	else:
		joystick_active = true
	
	output = _current_position * sensitivity
	
	update_handle_position()
	
	if joystick_active:
		movement_joystick_updated.emit(output)
		
		if use_input_actions:
			if output.x < 0:
				_update_input_action(action_left, -output.x)
			else:
				_update_input_action(action_right, output.x)
			
			if output.y < 0:
				_update_input_action(action_up, -output.y)
			else:
				_update_input_action(action_down, output.y)

func update_handle_position():
	if _handle_sprite:
		var handle_position = _current_position * max_distance
		_handle_sprite.position = size / 2 + handle_position

func _update_input_action(action:String, value:float):
	if value > InputMap.action_get_deadzone(action):
		Input.action_press(action, value)
	elif Input.is_action_pressed(action):
		Input.action_release(action)

func _reset():
	joystick_active = false
	output = Vector2.ZERO
	_is_dragging = false
	_touch_index = -1
	_current_position = Vector2.ZERO
	
	if _handle_sprite:
		_handle_sprite.modulate = _default_color
		update_handle_position()
	
	if use_input_actions:
		for action in [action_left, action_right, action_up, action_down]:
			if Input.is_action_pressed(action) or Input.is_action_just_pressed(action):
				Input.action_release(action)

func get_value() -> Vector2:
	return output
