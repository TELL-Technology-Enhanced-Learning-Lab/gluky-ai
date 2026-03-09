extends Button

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	var current_scene = get_tree().current_scene.scene_file_path
	var target_scene = "res://scenes/glucolife rooms/Bedroom.tscn"
	
	if current_scene == target_scene:
		return
	
	get_tree().change_scene_to_file(target_scene)
