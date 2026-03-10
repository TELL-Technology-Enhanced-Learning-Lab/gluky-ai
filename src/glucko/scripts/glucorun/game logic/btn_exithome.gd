extends TextureButton
#esci dal livello 1 e vai al menu principale di glucorun
func _on_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/glucorun/glucorun_menu.tscn")
