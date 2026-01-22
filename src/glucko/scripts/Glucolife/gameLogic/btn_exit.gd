extends TextureButton

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	GlucolifeDataManager.exit_glucolife()
	
	if has_node("/root/SceneTransition"):
		get_node("/root/SceneTransition").change_scene("res://scenes/menus/Intro_3d.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/menus/Intro_3d.tscn")
