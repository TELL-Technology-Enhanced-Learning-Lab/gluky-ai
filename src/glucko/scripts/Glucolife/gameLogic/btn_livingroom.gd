extends TextureButton

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	var current_scene = get_tree().current_scene.scene_file_path
	var target_scene = "res://scenes/glucolife rooms/Living room.tscn"
	
	if current_scene == target_scene:
		return
	
	GlucolifeDataManager._save_data()
	
	if has_node("/root/SceneTransition"):
		get_node("/root/SceneTransition").change_scene(target_scene)
	else:
		get_tree().change_scene_to_file(target_scene)
