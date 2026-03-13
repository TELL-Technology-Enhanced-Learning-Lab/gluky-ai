extends Control

#dichiarazione delle variabili

var questions = [] #array di domande
var current_index = 0 #indice
var selected_answer := -1 #variabile di selezione risposta
var buttons := [] #array che conterrà le risposte (pulsanti)
var animation_players := [] #array di animazioni
var initial_positions := []  # Salva le posizioni iniziali

#salvo e carico la scena del popupSpiegazione, e popup pausescene e instanzio la scena punteggio.
const pause_scene = preload("res://scenes/GlukoQuizScenes/pause_control.tscn")
var pause_istance = null
var explanation_scene = preload("res://scenes/GlukoQuizScenes/PopupEducativo.tscn")

@onready var score_hud = $Score_HUD 
@onready var pauseButton = $PauseButton 

var timer_running = false
var time_left = 15.0


func _ready():
	pauseButton.pressed.connect(_on_pause_pressed)
	
	load_questions()
	
	buttons = [
		$Answer1,
		$Answer2,
		$Answer3,
		$Answer4
	]
	
	# Salva le posizioni iniziali di ogni bolla
	for btn in buttons:
		initial_positions.append(btn.position)
		animation_players.append(btn.get_node("AnimationPlayer"))
	
	show_questions()
	
func _on_pause_pressed():
	# Se non esiste già, crea l'istanza
	if pause_istance == null:
		#fai sparire gli altri oggetti per un campo visivo maggiore
		#bloccare il flusso del gioco anche.
		
		pause_istance = pause_scene.instantiate()
		add_child(pause_istance)
		
		# Connetti il segnale di chiusura
		if pause_istance.has_signal("chiuso"):
			pause_istance.chiuso.connect(_on_pause_chiuso)
	else:
		# Se esiste già, mostrala
		pause_istance.show()
	
	
func _on_pause_chiuso():
	# Opzionale: rimuovi l'istanza quando si chiude
	if pause_istance:
		#mostra gli altri oggetti della scena quando l'istanza viene chiusa
		#fai riprendere il flusso del gioco
		pause_istance.queue_free()
		pause_istance = null

func load_questions():
	#carica il file pranzo.json
	var file = FileAccess.open("res://Json_files/Cena.json", FileAccess.READ)
	if file == null:
		push_error("Impossibile aprire il file JSON")
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data == null:
		push_error("Errore nel parsing del JSON")
		return
	questions = data["questions"]
	
func show_questions():
	selected_answer = -1
	time_left = 15.0 # faccio partire il tempo da 15 secondi ogni volta che vengono mostrate le domande.
	timer_running = true #segnale che stabilisce la durata del tempo True quando vengono mostrate le domande.
	$TimerLabel.modulate = Color(1,1,1)#ogni volta che mostri la label del timer impost il colore sul bianco
	$TimerLabel.visible = true #timer torna visibile ogni volta che vengono caricate le domande
	$PauseButton.visible = true
	
	if current_index >= questions.size():
		return
	
	var q = questions[current_index]
	$QuestionLabel.text = q["text"]
	
	# Ripristino tutte le bolle con un leggero fade in
	for i in range(4):
		var btn = buttons[i]
		var anim = animation_players[i]
		var label = btn.get_node("Label")
		label.text = q["answers"][i]
		
		# Reset animazioni
		anim.stop()
		anim.seek(0, true)
		
		# ripristina la posizione iniziale
		btn.position = initial_positions[i]
		
		# Reset proprietà con fade in più veloce
		btn.visible = true
		btn.disabled = false
		btn.modulate = Color(1, 1, 1, 0)  # Parto da trasparente
		
		# Fade in rapido e scaglionato per ogni bolla (effetto più dinamico)
		var fade_in = create_tween()
		fade_in.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.3).set_delay(i * 0.1)

		# Riconnetti segnali
		if btn.pressed.is_connected(_on_answer_pressed):
			btn.pressed.disconnect(_on_answer_pressed)
			
		btn.pressed.connect(_on_answer_pressed.bind(i))
	
	$NextButton.visible = false
	$NextButton.disabled = false
	
	#avvia il timer
	start_timer()

func start_timer():
	while timer_running and time_left > 0:
		await get_tree().create_timer(0.1).timeout
		time_left -= 0.1 #sottrae -1 al tempo qwuando la condizione è vera(15,14,13,ecc.) fino a quando il timer è 0 ed esce dal ciclo
		
		# Aggiorna la UI del timer
		if has_node("TimerLabel"):
			$TimerLabel.text = "Tempo: " + str(int(time_left)) + "s"
		
		# Cambia colore quando mancano 5 secondi 
		if time_left <= 5.0 and has_node("TimerLabel"):
			$TimerLabel.modulate = Color(1, 0.3, 0.3)

	#quando esce dal ciclo
	#se la risposta viene selezionata ma non viene premuto il pulsante nextbutton e il tempo scade, passa ugualmente alla domanda successiva
	if timer_running and time_left <= 0:
		timer_running = false
		
		# Effetto lampeggiante quando scade il tempo
		var blink = create_tween()
		blink.set_loops(3)
		blink.tween_property($TimerLabel, "modulate:a", 0.3, 0.2)
		blink.tween_property($TimerLabel, "modulate:a", 1.0, 0.2)
		
		# Mostra la risposta corretta dopo che è scaduto il tempo (sostituire o aggiungere popup di spiegazione della risposta esatta)
		var correct = questions[current_index]["correct"]
		buttons[correct].modulate = Color(0.2, 1.0, 0.2, 1.0)
		var highlight = create_tween()
		highlight.tween_property(buttons[correct], "scale", Vector2(1.2, 1.2), 0.3)
		
		score_hud.remove_points(1) #togli un punto se la risposta non viene scelta.
		await get_tree().create_timer(1.5).timeout #aspetta 1.5 sec e via con la succ. domanda
		$TimerLabel.modulate = Color(1, 1, 1)#il timer torna bianco 
		_go_next_question()

func _on_answer_pressed(i: int):
	
	selected_answer = i #passaggio parametri, assegno la var i alla variabile che contiene la selezione della risposta
	
	# Reset colore di tutte le bolle
	for j in range(4):
		buttons[j].modulate = Color(1, 1, 1, 1)
		buttons[j].scale = Vector2(1, 1)  #Reset scala
		
	# La bolla selezionata diventa blu celeste e rimbalza
	buttons[i].modulate = Color(0.398, 0.627, 1.0, 1.0)
	var bounce = create_tween()
	bounce.tween_property(buttons[i], "scale", Vector2(1.15, 1.15), 0.3)
	bounce.tween_property(buttons[i], "scale", Vector2(1, 1), 0.3)
	
	# Mostro il pulsante Next con un piccolo effetto
	$NextButton.modulate.a = 0
	$NextButton.visible = true
	
	var next_fade = create_tween()
	next_fade.tween_property($NextButton, "modulate:a", 1.0, 0.2)

func _on_next_button_pressed():
	if selected_answer == -1:
		return
	
	timer_running = false #fermo il timer solo quando premo nextbutton
	$TimerLabel.visible = false #nascondi timer
	$PauseButton.visible = false
	
	# Disabilito tutti i controlli
	$NextButton.disabled = true
	$NextButton.visible = false
	
	for btn in buttons:
		btn.disabled = true
		
		if btn.pressed.is_connected(_on_answer_pressed):
			btn.pressed.disconnect(_on_answer_pressed)
	
	var correct = questions[current_index]["correct"]
	var selected_btn = buttons[selected_answer]
	var selected_anim = animation_players[selected_answer]
	
	# Fai SPARIRE le altre bolle IMMEDIATO
	for i in range(4):
		if i != selected_answer:
			buttons[i].visible = false
	
	# PICCOLA PAUSA DOPO CHE SPARISCONO LE BOLLE
	await get_tree().create_timer(0.3).timeout
	
	# Muovi la bolla al centro con TWEEN in 2.5 secondi
	var target_pos = $AnswerTarget.position  # Posizione locale del centro
	var move_tween = create_tween()
	move_tween.tween_property(selected_btn, "position", target_pos, 2.5)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN_OUT)
	await move_tween.finished #aspetto che finisce l'animazionw
	
	# Controlla se è corretta o sbagliata
	
	if selected_answer == correct:
		# Risposta CORRETTA: diventa verde e svanisce
		score_hud.add_points(2) #richiamo la funzione addpoints della scena score_hud e assegno il punteggio di 2.
		flash_background(Color(0.2, 1.0, 0.2, 0.2)) #richiamo la funzione e imposto il colore verde chiaro
		
		selected_anim.play("correct_answer")
		await selected_anim.animation_finished
	else:
		# Risposta SBAGLIATA: diventa rossa, trema lo schermo e svanisce
		score_hud.remove_points(1) #richiamo la funzione addpoints della scena score_hud e rimuovo 1 punto.
		flash_background(Color(1.0, 0.2, 0.2, 0.2)) #richiamo la funzione e imposto il colore rosso chiaro.
		
		selected_anim.play("wrong_answer")
		screen_shake(0.8, 20.0, 0.04)
		await selected_anim.animation_finished
		
		#Mostra la risposta corretta, da gestire l'apparizione in maniera migliore
		buttons[correct].visible = true
		buttons[correct].modulate = Color(0.2, 1.0, 0.2, 0)
		var show_correct = create_tween()
		show_correct.tween_property(buttons[correct], "modulate:a", 1.0, 0.3)
		await get_tree().create_timer(1.5).timeout
	
	#Mostro la spiegazione richiamando la funzione
	await show_explanation_screen()
	
	# FASE 3: Passa alla domanda successiva
	_go_next_question()
	
	
func show_explanation_screen():
	var q = questions[current_index]
	var answer_text = q["answers"][selected_answer]
	var explanation_text = q["explanations"][selected_answer]
	var is_correct = (selected_answer == q["correct"])
	
	# Istanzia la scena
	var explanation_instance = explanation_scene.instantiate()
	add_child(explanation_instance)
	
	# Mostra la spiegazione
	explanation_instance.show_explanation(answer_text, explanation_text, is_correct)
	
	# Aspetta che l'utente prema "Continua"
	await explanation_instance.explanation_finished

func flash_background(color: Color):
	var original_color = $TextureRect.modulate  # asseggno il texturerect alla variabile di sfondo dichiarata come origcolor
	var flash = create_tween()
	flash.tween_property($TextureRect, "modulate", color, 0.2)
	flash.tween_property($TextureRect, "modulate", original_color, 0.5)

# Funzione per far tremare lo schermo
func screen_shake(duration: float, intensity: float, shake_speed: float):
	var original_position = position
	var shake_time = 0.0
	
	while shake_time < duration:
		# Shake che diminuisce gradualmente per un effetto più naturale
		var progress = shake_time / duration
		var current_intensity = intensity * (1.0 - progress)
		
		var shake_offset = Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)
		position = original_position + shake_offset
		
		await get_tree().create_timer(shake_speed).timeout
		shake_time += shake_speed
	
	# Ripristino posizione originale
	position = original_position

func _go_next_question():
	timer_running = false #ferma il timer
	current_index += 1
	
	if current_index >= questions.size():
		
		# MOSTRA IL PUNTEGGIO FINALE, creo una schermata finale con il punteggio.
		var final_score = score_hud.get_score()
		show_final_score(final_score)
		
		#dopo x secondi in questo caso 5 passa al livello successivo.
		await get_tree().create_timer(5.0).timeout
		get_tree().change_scene_to_file("res://scenes/GlukoQuizScenes/Mainscene1.tscn") #portare al livello due
		return
	
	show_questions()
	
#mostra il punteggio finale con questa funzione.
func show_final_score(score: int):
	#Crea una label temporanea per mostrare il punteggio finale
	var final_label = Label.new()
	final_label.text = "Quiz completato!\nPunteggio finale: " + str(score) + "/" + str(questions.size() * 2)
	final_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	final_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	final_label.add_theme_font_size_override("font_size", 48)
	final_label.modulate = Color(0.0, 0.994, 0.355, 1.0)  # Giallo
	final_label.size = get_viewport_rect().size
	add_child(final_label)
	
	# Animazione
	final_label.modulate.a = 0
	var fade = create_tween()
	fade.tween_property(final_label, "modulate:a", 1.0, 0.5)
	
#funzione premio fine quiz
func get_stars_from_score(score: int, max_score: int) -> int:
	var percentuale = (float(score) / float(max_score)) * 100
	
	if percentuale >= 90:
		return 3  # gestire animazione 3 stelle
	elif percentuale >= 70:
		return 2  # gestire animazione 2 stelle
	elif percentuale >= 50:
		return 1  #gestire animazione 1 stella
	else:
		return 0  # se tutte le risposte date sono errate gestire l'animazione repeat livello
			
