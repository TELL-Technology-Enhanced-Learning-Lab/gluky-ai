extends TextureButton

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	# Trova il player e rimuovi i suoi controlli mobile
	var player = get_tree().get_first_node_in_group("player")
	if player and player.mobile_controls_ui:
		player.mobile_controls_ui.queue_free()
		player.mobile_controls_ui = null
	
	get_tree().change_scene_to_file("res://scenes/menus/glucky/Minigame_Selection.tscn")
