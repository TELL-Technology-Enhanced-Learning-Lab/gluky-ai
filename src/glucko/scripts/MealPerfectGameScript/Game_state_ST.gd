extends Node
#classe autoload che gestisce lo stato del gioco durante la partita,
#emettendo un segnale quando il livello è completato
signal game_won

const WIN_SCORE := 1#numero di 'piatti perfetti' per far vincere il player

var perfect_plates: int = 0
var game_over: bool = false

func register_perfect_plate() -> void:
	if game_over:
		return

	perfect_plates += 1

	if perfect_plates >= WIN_SCORE:
		game_over = true
		game_won.emit()


func reset_game() -> void:
	perfect_plates = 0
	game_over = false


func _on_btn_exit_mpg_pressed() -> void:
		get_tree().change_scene_to_file("res://scenes/menus/glucky/Minigame_Selection.tscn")
