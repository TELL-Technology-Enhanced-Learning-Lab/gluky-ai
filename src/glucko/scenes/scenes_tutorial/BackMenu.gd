extends Control
#classe che gestisce i segnali del gioco (menugioco).

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/scenes_tutorial/Menu_inizio.tscn")# porta al menu d'inizio


func _on_level_2_pressed() -> void:
	MusicManager.fade_out() #abbassa la musica tramite music manager(autoload)
	get_tree().change_scene_to_file("res://scenes/MealPerfectgameScenes/MainScene.tscn")# avvia livello pranzo


func _on_avanti_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/scenes_tutorial/tutorial_2.tscn") #porta alla scena tutorial2




func _on_avanti_1_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/scenes_tutorial/tutorial_3.tscn")#porta alla sscena tutorial tavolino


func _on_back_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/scenes_tutorial/tutorial_2.tscn")#porta alla scena tutorial2


func _on_avanti_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/scenes_tutorial/tutorial_4.tscn")#porta alla scena tutorial4


func _on_back_3_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/scenes_tutorial/tutorial_3.tscn")#riporta alla scena tutorial3 del tavolino


func _on_esc_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/scenes_tutorial/Menu_inizio.tscn")# porta al menu d'inizio

	
func _on_level_3_pressed() -> void: 
	MusicManager.fade_out()
	get_tree().change_scene_to_file("res://scenes/MealPerfectgameScenes/MainSceneLevel2.tscn")#collegati al livello cena ovvero la scena cena.


func _on_level_1_pressed() -> void: #Collegamento livello colazione
	MusicManager.fade_out()
	get_tree().change_scene_to_file("res://scenes/MealPerfectgameScenes/MainScene_Levelcolazione.tscn")


func _on_back_1_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/scenes_tutorial/Menu_inizio.tscn")
