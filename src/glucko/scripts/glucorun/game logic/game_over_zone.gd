extends Area3D

var game_setup = null

func _ready():
	body_entered.connect(_on_body_entered)
	
	game_setup = get_tree().current_scene
	if not game_setup or not game_setup.has_method("trigger_game_over"):
		game_setup = get_tree().get_first_node_in_group("GameSetup")

func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		if game_setup and game_setup.has_method("trigger_game_over"):
			game_setup.trigger_game_over()
		else:
			get_tree().reload_current_scene()
