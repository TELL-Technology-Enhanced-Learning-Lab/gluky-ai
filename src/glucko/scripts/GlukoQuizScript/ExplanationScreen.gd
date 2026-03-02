extends Control

signal explanation_finished

@onready var answer_label = $VBoxContainer/AnswerLabel
@onready var explanation_label = $VBoxContainer/ExplanationLabel
@onready var continue_button = $VBoxContainer/ContinueButton
@onready var panel = $Panel

func _ready():
	# Parte invisibile
	modulate.a = 0
	continue_button.pressed.connect(_on_continue_pressed)

func show_explanation(answer_text: String, explanation_text: String, is_correct: bool):
	# Imposta i testi
	answer_label.text = "Hai scelto: " + answer_text
	explanation_label.text = explanation_text
	
	# Cambia colore in base a corretta/sbagliata
	if is_correct:
		panel.modulate = Color(0.2, 1.0, 0.2, 0.3)  # Verde
		answer_label.modulate = Color(0.2, 1.0, 0.2)
	else:
		panel.modulate = Color(1.0, 0.2, 0.2, 0.3)  # Rosso
		answer_label.modulate = Color(1.0, 0.2, 0.2)
	
	# Animazione di apparizione
	var fade_in = create_tween()
	fade_in.tween_property(self, "modulate:a", 1.0, 0.4)

func _on_continue_pressed():
	# Animazione di scomparsa
	var fade_out = create_tween()
	fade_out.tween_property(self, "modulate:a", 0.0, 0.3)
	await fade_out.finished
	
	# Segnala che ha finito
	explanation_finished.emit()
	queue_free()
