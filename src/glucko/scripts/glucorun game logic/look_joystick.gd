extends TextureButton

signal look_joystick_updated(value: Vector2)

@export var deadzone: float = 0.15  
@export var max_distance: float = 100.0
@export var joystick_texture: Texture2D
@export var handle_texture: Texture2D
@export var sensitivity: float = 1.0  

var _is_dragging: bool = false
var _touch_index: int = -1
var _center_position: Vector2 = Vector2.ZERO
var _current_position: Vector2 = Vector2.ZERO
var _handle_sprite: Sprite2D

func _ready():
	if joystick_texture:
		texture_normal = joystick_texture
	
	_handle_sprite = Sprite2D.new()
	if handle_texture:
		_handle_sprite.texture = handle_texture
	add_child(_handle_sprite)
	
	_handle_sprite.position = size / 2
	
	_update_center_position()

func _process(_delta):
	if _is_dragging and _current_position.length() > deadzone:
		look_joystick_updated.emit(_current_position * sensitivity)

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed and not _is_dragging:
			var local_pos = make_input_local(event).position
			if Rect2(Vector2.ZERO, size).has_point(local_pos):
				_is_dragging = true
				_touch_index = event.index
				_update_center_position()
				update_joystick(event.position)
		elif not event.pressed and event.index == _touch_index:
			_is_dragging = false
			_touch_index = -1
			_current_position = Vector2.ZERO
			update_handle_position()
			look_joystick_updated.emit(Vector2.ZERO)
	
	elif event is InputEventScreenDrag and _is_dragging and event.index == _touch_index:
		update_joystick(event.position)
		if _current_position.length() > deadzone:
			look_joystick_updated.emit(_current_position * sensitivity)

func _update_center_position():
	var global_rect = get_global_rect()
	_center_position = global_rect.position + global_rect.size / 2

func update_joystick(touch_position: Vector2):
	var direction = touch_position - _center_position
	var distance = direction.length()
	
	if distance > max_distance:
		direction = direction.normalized() * max_distance
	
	_current_position = direction / max_distance
	
	if _current_position.length() < deadzone:
		_current_position = Vector2.ZERO
	
	update_handle_position()

func update_handle_position():
	var local_offset = _current_position * max_distance
	_handle_sprite.position = size / 2 + local_offset

func get_value() -> Vector2:
	return _current_position

func _notification(what):
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_TRANSFORM_CHANGED:
		_update_center_position()
