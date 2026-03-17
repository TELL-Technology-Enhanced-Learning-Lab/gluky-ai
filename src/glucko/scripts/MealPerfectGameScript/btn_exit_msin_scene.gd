extends TextureButton

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	GameState.reset_game() #reset del gioco se si esce da un qualsiasi livello per poi ricominciaree
	for child in get_tree().root.get_children():
		if child.scene_file_path == "res://scenes/MealPerfectgameScenes/mobile_controls_pm.tscn":
			child.queue_free()
			break
	get_tree().change_scene_to_file("res://scenes/menus/glucky/Minigame_Selection.tscn")
