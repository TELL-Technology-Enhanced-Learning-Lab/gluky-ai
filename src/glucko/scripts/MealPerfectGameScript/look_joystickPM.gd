class_name VirtualLookJoystickPM
extends Control

signal look_joystick_updated(value: Vector2)

@export var deadzone_size: float = 0.1
@export var max_distance: float = 100.0
@export var joystick_texture: Texture2D
@export var handle_texture: Texture2D
@export var sensitivity: float = 1.0
@export var pressed_color: Color = Color.GRAY

enum JoystickMode { FIXED, DYNAMIC }
@export var joystick_mode := JoystickMode.FIXED

enum VisibilityMode { ALWAYS, TOUCHSCREEN_ONLY }
@export var visibility_mode := VisibilityMode.ALWAYS

var joystick_active := false
var output := Vector2.ZERO

var _is_dragging := false
var _touch_index := -1
var _center_position := Vector2.ZERO
var _current_position := Vector2.ZERO
var _handle_sprite: Sprite2D
var _joystick_sprite: Sprite2D
var _default_color: Color

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("look_joystick")
	_setup_visuals()
	_update_center_position()
	if not DisplayServer.is_touchscreen_available() and visibility_mode == VisibilityMode.TOUCHSCREEN_ONLY:
		hide()

func _setup_visuals():
	if joystick_texture:
		_joystick_sprite = Sprite2D.new()
		_joystick_sprite.texture = joystick_texture
		_joystick_sprite.centered = true
		_joystick_sprite.position = size / 2
		add_child(_joystick_sprite)

	if handle_texture:
		_handle_sprite = Sprite2D.new()
		_handle_sprite.texture = handle_texture
		_handle_sprite.centered = true
		_handle_sprite.position = size / 2
		add_child(_handle_sprite)
		_default_color = _handle_sprite.modulate

func _update_center_position():
	_center_position = global_position + size / 2

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed and not _is_dragging:
			if joystick_mode == JoystickMode.DYNAMIC or (joystick_mode == JoystickMode.FIXED and _is_point_inside_base(event.position)):
				if joystick_mode == JoystickMode.DYNAMIC:
					_move_base(event.position)
				_update_center_position()
				_is_dragging = true
				_touch_index = event.index
				if _handle_sprite:
					_handle_sprite.modulate = pressed_color
				update_joystick(event.position)
		elif not event.pressed and event.index == _touch_index:
			_reset()
	elif event is InputEventScreenDrag and _is_dragging and event.index == _touch_index:
		update_joystick(event.position)

func _move_base(new_position: Vector2):
	position = new_position - size / 2
	_update_center_position()

func _is_point_inside_base(point: Vector2) -> bool:
	var rect := Rect2(global_position, size)
	return rect.has_point(point)

func update_joystick(touch_position: Vector2):
	var direction := touch_position - _center_position
	var distance := direction.length()
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
		look_joystick_updated.emit(output)

func update_handle_position():
	if not _handle_sprite:
		return
	var handle_offset := _current_position * max_distance
	_handle_sprite.position = size / 2 + handle_offset

func _reset():
	joystick_active = false
	output = Vector2.ZERO
	_is_dragging = false
	_touch_index = -1
	_current_position = Vector2.ZERO
	if _handle_sprite:
		_handle_sprite.modulate = _default_color
		update_handle_position()
	look_joystick_updated.emit(Vector2.ZERO)

func get_value() -> Vector2:
	return output
