extends TextureButton


#torna al menu d'inizio
func _on_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menuiniziale.tscn")
