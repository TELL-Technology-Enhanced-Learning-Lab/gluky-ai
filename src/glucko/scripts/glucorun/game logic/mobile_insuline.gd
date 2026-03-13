extends Button
@export var action_name: String = "inject_insulin"
@export var animation_scale: float = 0.95
@export var animation_duration: float = 0.08
var _tween: Tween
var _touch_pressed: bool = false

func _ready() -> void:
	modulate = Color(1, 1, 1, 0)  
	mouse_filter = Control.MOUSE_FILTER_STOP
	expand_icon = true
	
	pressed.connect(_on_pressed)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	
	gui_input.connect(_on_gui_input)

func _on_pressed() -> void:
	_trigger_action()
	_play_feedback_animation()

func _on_button_down() -> void:
	_touch_pressed = true

func _on_button_up() -> void:
	if _touch_pressed:
		_touch_pressed = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_button_down()
		else:
			_on_button_up()

func _trigger_action() -> void:
	Input.action_press(action_name)
	await get_tree().process_frame
	Input.action_release(action_name)

func _play_feedback_animation() -> void:
	var target = get_parent()  
	if not target:
		return
	
	if _tween and _tween.is_valid():
		_tween.kill()
	
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_OUT)
	
	_tween.tween_property(
		target,
		"scale",
		Vector2.ONE * animation_scale,
		animation_duration 
	)
	_tween.tween_property(
		target,
		"scale",
		Vector2.ONE,
		animation_duration
	)
