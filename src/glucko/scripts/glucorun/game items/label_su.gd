extends HBoxContainer

#movimento morbido grazie a TRANS SINE.
#set loops lo fa ripetere all'infinito all'avvio della scena.
#vector2(0, -12) e (0,12) sarebbe quanto si muove l'effetto e 0.8 e la velocità dell'oscillazione


func _ready():
	_animate_title()

func _animate_title():
	var tween = create_tween()
	tween.set_loops()  # ripete all'infinito

	var start_pos = position

	# Oscillazione verticale
	tween.tween_property(self, "position", start_pos + Vector2(0, -12), 0.8)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(self, "position", start_pos + Vector2(0, 12), 0.8)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		

#collegati alla scena livelli al click del pulsante play
func _on_button_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Mainscene1.tscn")
