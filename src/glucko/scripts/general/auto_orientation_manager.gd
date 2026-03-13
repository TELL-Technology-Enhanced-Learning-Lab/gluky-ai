extends Node

signal orientation_changed(new_orientation)

enum OrientationMode {
	LANDSCAPE,
	PORTRAIT
}

var current_orientation := OrientationMode.LANDSCAPE
var is_mobile := false
var _pending_orientation: OrientationMode = OrientationMode.LANDSCAPE
var _changing_orientation := false


func _ready():
	is_mobile = OS.get_name() in ["Android", "iOS"]
	
	get_tree().scene_changed.connect(_on_scene_changed)
	
	# Connect to display metrics changed instead
	if is_mobile:
		# This is the correct signal for screen orientation changes
		get_tree().root.size_changed.connect(_on_display_size_changed)
	
	await get_tree().process_frame
	_check_scene_orientation()


func _on_scene_changed():
	# Wait a bit for the scene to fully load
	await get_tree().process_frame
	await get_tree().process_frame
	_check_scene_orientation()


func _on_display_size_changed():
	# When Android actually changes orientation, update our tracking
	if is_mobile and not _changing_orientation:
		var size = DisplayServer.screen_get_size()
		var new_orientation = OrientationMode.LANDSCAPE if size.x > size.y else OrientationMode.PORTRAIT
		if new_orientation != current_orientation:
			print("Display size changed - new orientation: ", new_orientation)
			current_orientation = new_orientation
			orientation_changed.emit(new_orientation)


func _check_scene_orientation():
	var scene = get_tree().current_scene
	if scene == null:
		return

	var preferred = OrientationMode.LANDSCAPE  # default
	if "preferred_orientation" in scene:
		preferred = scene.preferred_orientation
	
	_set_orientation(preferred)


func _set_orientation(mode: OrientationMode):
	if current_orientation == mode or _changing_orientation:
		return
	
	print("Changing orientation from ", current_orientation, " to ", mode)
	_changing_orientation = true
	_pending_orientation = mode

	if is_mobile:
		# Force the orientation change more aggressively
		match mode:
			OrientationMode.LANDSCAPE:
				# For landscape, try both landscape options to ensure it switches
				DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
				await get_tree().create_timer(0.1).timeout
				DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
				
			OrientationMode.PORTRAIT:
				DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
		
		# Wait longer for Android to process the orientation change
		await get_tree().create_timer(0.3).timeout
		
		# Verify the orientation actually changed
		var retry_count = 0
		while retry_count < 5:
			var current_size = DisplayServer.screen_get_size()
			var actual_orientation = OrientationMode.LANDSCAPE if current_size.x > current_size.y else OrientationMode.PORTRAIT
			
			if actual_orientation == mode:
				print("Orientation successfully changed to ", mode)
				break
			
			# If not changed yet, wait and retry
			print("Orientation not changed yet (current: ", actual_orientation, "), retrying...")
			await get_tree().create_timer(0.1).timeout
			retry_count += 1
			
			# Try setting again if it's stuck
			if retry_count == 3:
				print("Retrying orientation change...")
				if mode == OrientationMode.LANDSCAPE:
					DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
				else:
					DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
		
		# Update content scale with the actual screen size
		await get_tree().process_frame
		get_tree().root.content_scale_size = DisplayServer.screen_get_size()
		
	else:
		# Desktop version
		var new_size := Vector2i(1920, 1080) if mode == OrientationMode.LANDSCAPE else Vector2i(1080, 1920)
		DisplayServer.window_set_size(new_size)
		await get_tree().process_frame
		await get_tree().process_frame
		get_tree().root.content_scale_size = DisplayServer.window_get_size()
	
	# Update current orientation
	current_orientation = mode
	_changing_orientation = false
	orientation_changed.emit(mode)
