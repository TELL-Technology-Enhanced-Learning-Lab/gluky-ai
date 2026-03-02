extends Control

# Carica la scena impostazioni
const IMPOSTAZIONI_SCENE = preload("res://scenes/GlukoQuizScenes/Impostazioni.tscn")

@onready var impostazioni_button = $Button_gui/ButtonOption  #il percorso corretto al tuo bottone
var impostazioni_instance = null

func _ready():
	# Connetti il segnale del bottone
	impostazioni_button.pressed.connect(_on_impostazioni_pressed)

func _on_impostazioni_pressed():
	
	# Se non esiste già, crea l'istanza
	if impostazioni_instance == null:
		#fai sparire gli altri oggetti per un campo visivo maggiore
		$GlukoButton.visible = false
		$Button_gui.visible = false
		
		impostazioni_instance = IMPOSTAZIONI_SCENE.instantiate()
		add_child(impostazioni_instance)
		
		# Connetti il segnale di chiusura 
		if impostazioni_instance.has_signal("chiuso"):
			impostazioni_instance.chiuso.connect(_on_impostazioni_chiuso)
	else:
		# Se esiste già, mostrala
		impostazioni_instance.show()

func _on_impostazioni_chiuso():
	# Opzionale: rimuovi l'istanza quando si chiude
	if impostazioni_instance:
		#mostra gli altri oggetti della scena quando l'istanza viene chiusa
		$GlukoButton.visible = true
		$Button_gui.visible = true
		
		impostazioni_instance.queue_free()
		impostazioni_instance = null
