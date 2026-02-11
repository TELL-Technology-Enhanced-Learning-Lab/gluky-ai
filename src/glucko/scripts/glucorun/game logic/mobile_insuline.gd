extends VBoxContainer

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

func _on_gui_input(event):
	if event is InputEventScreenTouch and event.pressed:
		Input.action_press("inject_insulin")
		Input.action_release("inject_insulin")
		_animate_press()
		accept_event()

func _animate_press():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
