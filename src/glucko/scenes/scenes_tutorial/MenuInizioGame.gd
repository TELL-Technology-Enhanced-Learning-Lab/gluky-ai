extends Control

func _ready():

	MusicManager.play_music()
	MusicManager.fade_in()
	$AnimationPlayer1.play("menu_intro") #fade in animazione
	Glukybot.update_scene("res://scenes/scenes_tutorial/Menu_inizio.tscn")
	
#quando si clicca su 'gioca' la musica si sfuma ma continua
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "menu_out":
		get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_play_pressed():
	$AnimationPlayer1.play("menu_out") #fade out animazione
	MusicManager.fade_out() # abbassa la musica quando si clicca su 'gioca' e inizia il livello pranzo
	get_tree().change_scene_to_file("res://scenes/MealPerfectgameScenes/MainScene.tscn") #al click del pulsante avvia il gioco
	
func _on_info_pressed():
	get_tree().change_scene_to_file("res://scenes/scenes_tutorial/tutorial_2.tscn") #al click del pulsante collegati al tutorial


func _on_levels_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/scenes_tutorial/MenuLivelli.tscn") # al click del pulsante collegamewnto alla pagina livelli
	

func _on_exit_pressed():
	get_tree().quit() #al click del pulsante chiudi il gioco
	

	
