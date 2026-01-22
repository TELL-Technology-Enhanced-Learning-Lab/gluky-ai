extends Node

signal orientation_changed(new_orientation)

enum OrientationMode {
	LANDSCAPE,
	PORTRAIT
}

var current_orientation: OrientationMode = OrientationMode.LANDSCAPE
var portrait_scenes: Array[String] = []
var portrait_folder_path: String = "res://scenes/glucolife rooms"
var is_mobile: bool = false
var initialized: bool = false

func _ready():
	is_mobile = OS.get_name() in ["Android", "iOS"]
	_update_portrait_scenes_from_folder()
	get_tree().connect("node_added", _on_node_added)
	get_tree().connect("tree_changed", _on_tree_changed)
	await get_tree().create_timer(0.5).timeout
	_check_current_scene_orientation()
	initialized = true

func set_portrait_folder(folder_path: String):
	portrait_folder_path = folder_path
	_update_portrait_scenes_from_folder()

func _update_portrait_scenes_from_folder():
	if portrait_folder_path.is_empty():
		return
	
	portrait_scenes.clear()
	
	var dir = DirAccess.open(portrait_folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tscn"):
				var scene_path = portrait_folder_path.path_join(file_name)
				portrait_scenes.append(scene_path)
			file_name = dir.get_next()

func _check_current_scene_orientation():
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.scene_file_path:
		var scene_path = current_scene.scene_file_path
		
		# 修复：重命名变量以避免遮蔽函数
		var should_be_portrait = false
		for portrait_scene in portrait_scenes:
			if scene_path == portrait_scene:
				should_be_portrait = true
				break
		
		if should_be_portrait:
			set_orientation(OrientationMode.PORTRAIT)
		else:
			set_orientation(OrientationMode.LANDSCAPE)
	else:
		set_orientation(OrientationMode.LANDSCAPE)

func set_orientation(mode: OrientationMode):
	if current_orientation == mode and initialized:
		return
	
	current_orientation = mode
	
	if is_mobile:
		match mode:
			OrientationMode.LANDSCAPE:
				DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
			OrientationMode.PORTRAIT:
				DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	else:
		var current_size = DisplayServer.window_get_size()
		
		if mode == OrientationMode.PORTRAIT:
			if current_size.x > current_size.y:
				var portrait_size = Vector2i(min(current_size.y, 1080), min(current_size.x, 1920))
				DisplayServer.window_set_size(portrait_size)
		else:
			if current_size.y > current_size.x:
				var landscape_size = Vector2i(min(current_size.x, 1920), min(current_size.y, 1080))
				DisplayServer.window_set_size(landscape_size)
	
	orientation_changed.emit(mode)
	
	await get_tree().process_frame
	
	if is_mobile:
		get_tree().root.content_scale_size = DisplayServer.screen_get_size()
	else:
		get_tree().root.content_scale_size = DisplayServer.window_get_size()

func is_portrait() -> bool:
	return current_orientation == OrientationMode.PORTRAIT

func is_landscape() -> bool:
	return current_orientation == OrientationMode.LANDSCAPE

func _on_node_added(node: Node):
	if node.get_parent() == get_tree().root or node.get_parent() == null:
		call_deferred("_check_current_scene_orientation")

func _on_tree_changed():
	call_deferred("_check_current_scene_orientation")

func force_orientation_check():
	_check_current_scene_orientation()
