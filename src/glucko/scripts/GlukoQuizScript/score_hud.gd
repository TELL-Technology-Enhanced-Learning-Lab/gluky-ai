extends Control

@onready var score_label = $TextureRect/ScoreLabel

var current_score = 0 #var. punteggio
func _ready():
	update_score_display()

func add_points(points: int):
	current_score = current_score + points
	animate_score_change(points)
	update_score_display()
	
func remove_points(points: int):
	current_score = current_score - points
	if current_score < 0:
		current_score = 0 #il punteggio non può esserre negativoo
		
	animate_score_change(-points)
	update_score_display()
	
func update_score_display():
	score_label.text = "" + str(current_score)	


func animate_score_change(points: int):
	# Effetto visivo quando il punteggio cambia
	var original_scale = scale
	var color = Color(0.2, 1.0, 0.2) if points > 0 else Color(1.0, 0.2, 0.2)
	
	# Animazione scala e colore
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(score_label, "modulate", color, 0.2)
	
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", original_scale, 0.2)
	tween.tween_property(score_label, "modulate", Color(1, 1, 1), 0.2)	

func get_score() -> int:
	return current_score
	
func reset_score():
	current_score = 0
	update_score_display()
	
	
