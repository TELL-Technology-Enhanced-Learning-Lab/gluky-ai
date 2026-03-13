extends Node

signal game_won
const WIN_SCORE := 1
var perfect_plates: int = 0
var game_over: bool = false

func register_perfect_plate() -> void:
	if game_over:
		return
	perfect_plates += 1
	if perfect_plates >= WIN_SCORE:
		game_over = true
		_remove_mobile_controls()
		game_won.emit()

func reset_game() -> void:
	perfect_plates = 0
	game_over = false

func _remove_mobile_controls() -> void:
	for child in get_tree().root.get_children():
		if child.scene_file_path == "res://scenes/MealPerfectgameScenes/mobile_controls_pm.tscn":
			child.queue_free()
			break

func _on_btn_exit_mpg_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/glucky/Minigame_Selection.tscn")
