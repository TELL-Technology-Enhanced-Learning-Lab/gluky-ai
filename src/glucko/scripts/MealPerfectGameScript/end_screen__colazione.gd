extends Control

@onready var restart_button: Button = $Panel/VBoxContainer/Button_Restart

func _ready():
	visible = false

	# IMPORTANTISSIMO: UI attiva anche in pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.process_mode = Node.PROCESS_MODE_ALWAYS

	GameState.game_won.connect(show_end_screen) #quando riceve il segnale gamewon fa apparire il panel
	restart_button.pressed.connect(_on_button_restart_pressed)


func show_end_screen() -> void:
	await get_tree().create_timer(8.5).timeout #timer che si avvia dopo le info dell'ultimo popup
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE #mouse visiile
	visible = true
	get_tree().paused = true


func _on_button_restart_pressed() -> void:
	# togli la pausa
	get_tree().paused = false
	# resetta il game manager
	GameState.reset_game()
	# ricarico scena mainscene
	get_tree().change_scene_to_file("res://Scenes/MainScene_Levelcolazione.tscn")

#esci dal livello in questione(colazione) porta al menu dei livelli
func _on_button_quit_pressed() -> void:
	get_tree().paused = false
	GameState.reset_game()
	get_tree().change_scene_to_file("res://scenes_tutorial/MenuLivelli.tscn")

#collegati al livello successivo, pranzo
func _on_button_next_pressed() -> void:
	get_tree().paused = false #tolgo la pausa per il caricamento del nuovo livello
	GameState.reset_game() #reset del game state, cosi il livello parte senza bloccarsi
	get_tree().change_scene_to_file("res://Scenes/MainScene.tscn") #carico la scena del livello pranzo
