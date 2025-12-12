extends CheckButton

func _ready():
	button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func _on_toggled(toggled_on):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	await get_tree().create_timer(0.1).timeout
	
	if has_node("/root/ResolutionManager"):
		var res_manager = get_node("/root/ResolutionManager")
		res_manager.update_resolution()
