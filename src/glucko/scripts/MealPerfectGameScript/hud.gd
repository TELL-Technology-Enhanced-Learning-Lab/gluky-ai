extends CanvasLayer

@onready var score_label = $ScoreLabel

func update_score(value: int):
	#aggiorno il testo quando cambia il punteggio
	score_label.text = "PIATTI COMPLETATI : " + str (value)
