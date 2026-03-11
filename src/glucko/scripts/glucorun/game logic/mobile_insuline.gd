extends Button
@export var action_name: String = "inject_insulin"
@export var animation_scale: float = 0.95
@export var animation_duration: float = 0.08
var _tween: Tween
func _ready() -> void:
	# Bottone completamente trasparente ma ancora cliccabile
	modulate = Color.WHITE
	pressed.connect(_on_pressed)
	# Importantissimo per mobile
	mouse_filter = Control.MOUSE_FILTER_STOP
	expand_icon = true
func _on_pressed() -> void:
	_trigger_action()
	_play_feedback_animation()
func _trigger_action() -> void:
	# Non usiamo action_press/release manuale
	# Meglio emettere direttamente l'azione
	Input.action_press(action_name)
	Input.action_release(action_name)
func _play_feedback_animation() -> void:
	var target = get_parent()
	if not target:
		return
	# Se esiste un tween vecchio → kill
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
