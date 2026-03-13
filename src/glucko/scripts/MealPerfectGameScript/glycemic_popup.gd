extends Panel

@onready var title_label: Label = $Label_Title
@onready var message_label: Label = $Label_Message
@onready var ratio_label: Label = $Label_Ratio   

func _ready():
	visible = false
	modulate.a = 0.0

func show_popup(
	message: String,
	ratio: float,
	title: String = "Bilanciamento del piatto"
) -> void:
	
	title_label.text = title
	message_label.text = message
	ratio_label.text = "Rapporto glicemico: %.2f" % ratio

	#feedback visivo
	if ratio < 15:
		ratio_label.modulate = Color(0.111, 0.312, 1.0, 1.0) #blu(piatto troppo leggero)
	elif ratio >= 15.0 and ratio <= 30 :
		ratio_label.modulate = Color(0.2, 0.8, 0.2) # verde(piatto perfetto)
	else:
		ratio_label.modulate = Color(0.9, 0.2, 0.2) # rosso(piatto critico)

	visible = true
	modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

	# attesa NON bloccante
	#attesa dura 8 secondi, rendere di meno se si vuole
	await get_tree().create_timer(10).timeout #timer popup, variabile

	var tween2 = create_tween()
	tween2.tween_property(self, "modulate:a", 0.0, 0.3)

	await tween2.finished
	visible = false
