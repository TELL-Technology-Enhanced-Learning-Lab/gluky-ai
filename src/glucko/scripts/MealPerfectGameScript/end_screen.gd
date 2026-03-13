extends Control

@onready var panel: Panel = $Panel

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.game_won.connect(show_end_screen)

func show_end_screen() -> void:
	await get_tree().create_timer(10.5).timeout
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true
	get_tree().paused = true
	# aspetta 4 secondi col messaggio visibile
	await get_tree().create_timer(4.0).timeout
	get_tree().paused = false
	GameState.reset_game()
	get_tree().change_scene_to_file("res://scenes/MealPerfectgameScenes/MainSceneLevel2.tscn")
