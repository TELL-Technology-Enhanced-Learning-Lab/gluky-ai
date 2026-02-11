extends Node

signal orientation_changed(new_orientation)

enum OrientationMode {
	LANDSCAPE,
	PORTRAIT
}

var current_orientation := OrientationMode.LANDSCAPE
var is_mobile := false


func _ready():
	is_mobile = OS.get_name() in ["Android", "iOS"]

	get_tree().tree_changed.connect(_on_scene_changed)

	await get_tree().process_frame
	_check_scene_orientation()


func _on_scene_changed():
	call_deferred("_check_scene_orientation")


func _check_scene_orientation():
	var scene = get_tree().current_scene
	if scene == null:
		return

	if not "preferred_orientation" in scene:
		_set_orientation(OrientationMode.LANDSCAPE)
		return

	_set_orientation(scene.preferred_orientation)


func _set_orientation(mode: OrientationMode):

	if current_orientation == mode:
		return

	current_orientation = mode


	if is_mobile:

		match mode:
			OrientationMode.LANDSCAPE:
				DisplayServer.screen_set_orientation(
					DisplayServer.SCREEN_LANDSCAPE
				)

			OrientationMode.PORTRAIT:
				DisplayServer.screen_set_orientation(
					DisplayServer.SCREEN_PORTRAIT
				)

	else:

		if mode == OrientationMode.PORTRAIT:
			DisplayServer.window_set_size(Vector2i(720, 1280))

		else:
			DisplayServer.window_set_size(Vector2i(1280, 720))


	orientation_changed.emit(mode)

	await get_tree().process_frame
	get_tree().root.content_scale_size = DisplayServer.screen_get_size()
