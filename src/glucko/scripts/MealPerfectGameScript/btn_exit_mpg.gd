extends TextureButton

#porta al menu selezione livelli di meal perfect game
func _on_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/scenes_tutorial/MenuLivelli.tscn")
