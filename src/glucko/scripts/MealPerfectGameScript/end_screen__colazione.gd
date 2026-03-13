extends Control

@onready var restart_button: Button = $Panel/VBoxContainer/Button_Restart

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.game_won.connect(show_end_screen)

func show_end_screen() -> void:
	await get_tree().create_timer(8.5).timeout
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true
	get_tree().paused = true

func _on_button_restart_pressed() -> void:
	get_tree().paused = false
	GameState.reset_game()
	get_tree().change_scene_to_file("res://scenes/MealPerfectgameScenes/MainScene_Levelcolazione.tscn")

func _on_button_quit_pressed() -> void:
	get_tree().paused = false
	GameState.reset_game()
	get_tree().change_scene_to_file("res://scenes/scenes_tutorial/MenuLivelli.tscn")

func _on_button_next_pressed() -> void:
	get_tree().paused = false
	GameState.reset_game()
	get_tree().change_scene_to_file("res://scenes/MealPerfectgameScenes/MainScene.tscn")
