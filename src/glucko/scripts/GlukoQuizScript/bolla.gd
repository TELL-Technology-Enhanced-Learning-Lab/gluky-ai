extends TextureButton

@export var wave_amplitude := 10.0
@export var wave_speed := 1.0
@export var sparkle_strength := 0.2
@export var start_delay := 0.0

func _ready():
	await get_tree().create_timer(start_delay).timeout
	_start_animation()
	jelly()

func _start_animation():
	var tween = create_tween()
	tween.set_loops()

	var original_pos = position

	# Oscillazione verticale con position
	tween.tween_property(self, "position",
		original_pos + Vector2(0, -wave_amplitude),
		wave_speed)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(self, "position",
		original_pos + Vector2(0, wave_amplitude),
		wave_speed)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	# Luccichio con modulate
	tween.parallel().tween_property(self, "modulate",
		Color(1, 1, 1, 1.0 - sparkle_strength),
		wave_speed / 2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	tween.parallel().tween_property(self, "modulate",
		Color(1, 1, 1, 1.0),
		wave_speed / 2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
#effetto rimbalzante ("jelly") dato dalla bolla, utilizzando la scale		
func jelly():
	var tween = create_tween()
	tween.set_loops()

	tween.tween_property(self, "scale", Vector2(1.02, 0.98), 0.35)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "scale", Vector2(0.98, 1.02), 0.35)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.35)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

#carica il livello 1 al click.
func level1_on_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/GlukoQuizScenes/level1_Colazione.tscn")
	
#carica il livello 2 al click.
func _on_level_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/GlukoQuizScenes/level2_Pranzo.tscn")

#carica il livello 3 al click
func _on_level_3_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/GlukoQuizScenes/level_3_cena.tscn")

func _on_back_button_pressed() -> void:
	pass # Replace with function body.
