extends Node2D

# ============================================================
# NODI
# ============================================================

@onready var tts = $TTS
@onready var microphone: AudioStreamPlayer2D = $Microphone
@onready var btn_record: Button = $CanvasLayer/BtnRecord

# ============================================================
# CONFIG CLAUDE
# ============================================================

var api_key := "inserisci la chiave api "
var model := "claude-haiku-4-5-20251001"

# ============================================================
# MEMORIA CONVERSAZIONE
# ============================================================

const MAX_HISTORY := 8
var conversation_history := []

# Nome del bambino — appreso dinamicamente
var child_name := ""

# Flag: stiamo aspettando la risposta col nome dopo la presentazione
var _waiting_for_name := false

# ============================================================
# SYSTEM PROMPT BASE
# ============================================================

var system_prompt_base := """
=== CHI SEI ===
Ti chiami Gluky. Sei il fedele assistente virtuale di un videogioco educativo sul diabete tipo 1 pensato per bambini di 5-7 anni.
Sei allegro, paziente, incoraggiante e rassicurante. Parli SEMPRE in italiano.
Sei l amico del bambino dentro il gioco, non un medico.

=== MEMORIA E NOME ===
- Ricordi tutto quello che il bambino ti ha detto in questa sessione.
- Se conosci il nome del bambino usalo spesso nelle risposte per renderle personali e calorose.
- Esempi: Bravo Marco!, Dai Sofia ce la fai!, Grande Luca!
- NON chiedere il nome ogni volta. Se lo conosci gia usalo e basta.
- Se non sai il nome va bene lo stesso, parla normalmente senza chiedere.

=== COME PARLI ===
- Usi frasi cortissime e parole semplicissime, come se parlassi con un bambino di 5 anni.
- Rispondi SEMPRE in massimo 3 frasi brevi.
- Non usi MAI simboli, emoji, asterischi, trattini o formattazione markdown.
- Scrivi solo testo semplice e pulito.
- Ogni tanto usi metafore divertenti per spiegare cose difficili.
  Esempio: l insulina e come una chiavina magica che apre le porte delle cellule per far entrare lo zucchero.

=== COME INIZI LE RISPOSTE — REGOLA IMPORTANTISSIMA ===
- NON iniziare MAI con Ciao sono Gluky tranne la primissima volta assoluta che parli col bambino.
- Dopo la presentazione iniziale vai SEMPRE dritto al punto come in una conversazione tra amici.
- Varia SEMPRE l inizio delle frasi. Non ripetere mai lo stesso inizio due volte di fila.
- Esempi di inizi diversi: Certo!, Ottima domanda!, Allora..., Sai cosa?, Hai ragione!, Guarda..., Mmm vediamo..., Dai!, Perfetto!, Wow!, Capito!, Ma certo!, Fantastico!

=== INTELLIGENZA CONVERSAZIONALE ===
- Ricordi quello che hai gia spiegato in questa sessione e non ti ripeti mai.
- Se il bambino fa una domanda simile a una gia fatta, rispondi in modo diverso con un esempio nuovo.
- Mostri entusiasmo genuino per le domande del bambino.
- Se il bambino sbaglia qualcosa lo correggi dolcemente senza farlo sentire stupido.

=== COSA SAI ===
- Conosci il diabete tipo 1 e sai spiegarlo in modo semplice e rassicurante.
- Sai come funzionano i giochi di Gluky e puoi guidare il bambino al loro interno.
- Per tutto il resto dici: Questa non la so, ma posso aiutarti con tutto quello che riguarda il gioco e il diabete!

=== REGOLE ASSOLUTE — NON VIOLARLE MAI ===
- Non dare MAI dosi di insulina, valori target di glicemia o indicazioni terapeutiche di nessun tipo.
- Non parlare MAI di complicanze gravi, scenari negativi o argomenti che possono spaventare il bambino.
- Se la domanda e medica o clinica rispondi esattamente: Questa e una domanda per il tuo dottore o per la tua mamma e il tuo papa!
- Se il bambino dice che si sente male rispondi immediatamente: Dillo subito a un adulto vicino a te!
- Usa SEMPRE un tono positivo, mai allarmante.
- Non usare MAI asterischi, trattini, emoji, faccine o qualsiasi simbolo. Solo testo semplice.
"""

# Prompt caricati dai file txt — uno per gioco
var prompts := {
	"glucorun"   : "",
	"glucolife"  : "",
	"mealperfect": "",
	"glukoquiz"  : "",
	
}

var active_prompt := ""

# ============================================================
# MAPPA SCENE → GIOCO + CONTESTO + TUTORIAL
# ============================================================

var scene_map := {

	"res://scenes/menus/glucky/Intro_3d.tscn": {
		"game"        : "base",
		"context"     : "Menu principale di Gluky (Intro_3d). Stanza 3D stile cartoon accogliente: pareti pastello, pavimento in legno, tappeto rosa, luci a festoni, scaffali colorati, scrivania con monitor gialli, divano grigio, poster di Gluky. Il personaggio Gluky (bambino con casco blu e tuta bianco-blu) e al centro della stanza. Il bambino striscia il dito per ruotare la visuale: sinistra trovi Play a Minigame, ancora destra trovi la Libreria video, destra trovi la porta Quit. In basso al centro c e il bottone Parla per parlare con Gluky.",
		"tutorial_key": "intro_3d",
		"tutorial_msg": "PRESENTAZIONE_CON_NOME"
	},

	"res://scenes/menus/glucky/Minigame_Selection.tscn": {
		"game"        : "base",
		"context"     : "Schermata selezione giochi. Il bambino puo scegliere tra GlukoRun, GlukoLife, MealPerfect e GlukoQuiz.",
		"tutorial_key": "minigame_selection",
		"tutorial_msg": "Presenta i quattro giochi in modo breve e divertente per un bambino di 5-7 anni. GlukoRun e un gioco dove si corre si salta e si impara come funziona la glicemia raccogliendo cibi. GlukoLife e un gioco dove ti prendi cura di un personaggio speciale facendolo mangiare dormire lavare e giocare. MealPerfect e un gioco dove si imparano a comporre piatti perfetti bilanciando gli alimenti. GlukoQuiz e un gioco a domande per scoprire quanto hai imparato sul diabete. Chiedi al bambino con quale vuole iniziare. Sii breve entusiasta. Niente markdown o simboli."
	},

	"res://scenes/glucorun levels/livello1.tscn": {
		"game"        : "glucorun",
		"context"     : "Livello 1 di GlukoRun. Il bambino corre raccoglie cibi e impara a gestire la glicemia del personaggio.",
		"tutorial_key": "glucorun_livello1",
		"tutorial_msg": "Fai un tutorial breve per il Livello 1 di GlukoRun. Il personaggio corre automaticamente e il bambino deve saltare per raccogliere i cibi giusti e tenere la barra della glicemia nella zona verde. I cibi sani mantengono la glicemia in equilibrio. I dolci la fanno salire troppo. Sii breve e divertente. Niente markdown o simboli."
	},

	"res://scenes/glucorun levels/livello2.tscn": {
		"game"        : "glucorun",
		"context"     : "Livello 2 di GlukoRun. Piu veloce e difficile del livello 1. Ostacoli nuovi e piu cibi da gestire.",
		"tutorial_key": "",
		"tutorial_msg": ""
	},

	"res://scenes/glucorun levels/livello3.tscn": {
		"game"        : "glucorun",
		"context"     : "Livello 3 di GlukoRun. Il livello piu difficile con ostacoli complessi e gestione avanzata della glicemia.",
		"tutorial_key": "",
		"tutorial_msg": ""
	},

	"res://scenes/GlukoQuizScenes/Mainscene1.tscn": {
		"game"        : "glukoquiz",
		"context"     : "Menu iniziale di GlukoQuiz. Il bambino sceglie tra i livelli Colazione Pranzo e Cena per rispondere a 10 domande sul diabete.",
		"tutorial_key": "glukoquiz_menu",
		"tutorial_msg": "Fai il tutorial di benvenuto di GlukoQuiz. Ci sono tre livelli Colazione Pranzo e Cena. In ogni livello 10 domande a risposta multipla con 15 secondi di tempo. Risposta giusta vale 2 punti risposta sbagliata toglie 1 punto. Sii breve entusiasta. Niente markdown o simboli."
	},

	"res://scenes/scenes_tutorial/Menu_inizio.tscn": {
		"game"        : "mealperfect",
		"context"     : "Menu iniziale di MealPerfect. Il bambino sta per entrare nel gioco dei piatti perfetti ambientato in una cucina giapponese.",
		"tutorial_key": "mealperfect_menu",
		"tutorial_msg": "Dai il benvenuto a MealPerfect. Spiega che si sceglie un livello tra colazione pranzo o cena. Nel gioco si crea un piatto perfetto scegliendo al massimo 3 alimenti e mantenendo il valore glicemico virtuale tra 15 e 30. Si trascina il cibo nel piatto con il dito. Sii breve ed entusiasta. Niente markdown o simboli."
	},

	"res://scenes/glucolife rooms/Kitchen.tscn": {
		"game"        : "glucolife",
		"context"     : "Cucina virtuale di GlukoLife. Il bambino da da mangiare al personaggio dai capelli blu scegliendo i cibi giusti.",
		"tutorial_key": "glucolife_cucina",
		"tutorial_msg": "Fai il tutorial di GlukoLife poi spiega la cucina. Il bambino tocca i cibi per far mangiare il personaggio dai capelli blu. I cibi sani ricaricano la barra della fame in modo equilibrato. I dolci alzano troppo la glicemia simulata. Nella vita reale la dieta la gestiscono i genitori e il medico. Sii breve e affettuoso. Niente markdown o simboli."
	},

	"res://scenes/glucolife rooms/Living room.tscn": {
		"game"        : "glucolife",
		"context"     : "Cameretta virtuale di GlukoLife. Il bambino fa dormire il personaggio dai capelli blu per ricaricare la barra del sonno.",
		"tutorial_key": "glucolife_cameretta",
		"tutorial_msg": "Benvenuto nella cameretta. Tocca il letto per far addormentare il personaggio dai capelli blu. Dormire ricarica la sua energia e lo aiuta a giocare meglio. Sii breve e dolce. Niente markdown o simboli."
	},

	"res://scenes/glucolife rooms/Restroom.tscn": {
		"game"        : "glucolife",
		"context"     : "Bagno virtuale di GlukoLife. Il bambino fa lavare il personaggio dai capelli blu per ricaricare la barra dell igiene.",
		"tutorial_key": "glucolife_bagno",
		"tutorial_msg": "Benvenuto nel bagno. Tocca la doccia o il lavandino per far lavare il personaggio dai capelli blu. Lavarsi ricarica la barra dell igiene e lo fa sentire fresco e felice. Sii breve e allegro. Niente markdown o simboli."
	},

	"res://scenes/glucolife rooms/PlayGround.tscn": {
		"game"        : "glucolife",
		"context"     : "Parco giochi virtuale di GlukoLife. Il bambino fa giocare il personaggio dai capelli blu per ricaricare la barra dell energia.",
		"tutorial_key": "glucolife_parco",
		"tutorial_msg": "Benvenuto al parco giochi! Tocca le giostre o i giochi per far correre e saltare il personaggio dai capelli blu. Cosi ricarica la barra dell energia e diventa piu contento. Giocare lo aiuta a stare in forma. Sii breve ed entusiasta. Niente markdown o simboli."
	},
}

# ============================================================
# STATO INTERNO
# ============================================================

var http_request: HTTPRequest
var claude_busy := false
var stt
var current_context  := ""
var current_scene_path := ""
var _tutorials_shown := {}
var _first_interaction := true

enum State { IDLE, RECORDING, THINKING, SPEAKING }
var state := State.IDLE

# ============================================================
# READY
# ============================================================

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_all_prompts()

	http_request = HTTPRequest.new()
	http_request.use_threads = true
	http_request.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(http_request)
	http_request.request_completed.connect(_on_claude_response)

	stt = STT
	stt.transcription_complete.connect(_on_stt_result)

	microphone.process_mode = Node.PROCESS_MODE_ALWAYS
	microphone.play()
	tts.process_mode = Node.PROCESS_MODE_ALWAYS

	btn_record.process_mode = Node.PROCESS_MODE_ALWAYS
	btn_record.pressed.connect(_on_btn_pressed)

	_set_state(State.IDLE)
	print("[GLUKY] Pronto")

# ============================================================
# CARICAMENTO SYSTEM PROMPT DA FILE
# ============================================================

func _load_all_prompts():
	var files := {
		"glucorun"   : "res://system_prompts/GlucoRun_Promt.txt",
		"glucolife"  : "res://system_prompts/GlukoLife_Promt.txt",
		"mealperfect": "res://system_prompts/MealPerfectPrompt.txt",
		"glukoquiz"  : "res://system_prompts/GlukoQuizPrompt.txt",
	}
	for key in files:
		var path = files[key]
		if FileAccess.file_exists(path):
			var f = FileAccess.open(path, FileAccess.READ)
			prompts[key] = f.get_as_text()
			f.close()
			print("[GLUKY] Prompt caricato:", key)
		else:
			print("[GLUKY] ATTENZIONE — file non trovato:", path)

# ============================================================
# AGGIORNAMENTO SCENA — chiamato da ogni scena nel _ready()
# ============================================================

func update_scene(scene_path: String):
	current_scene_path = scene_path
	print("[GLUKY] Scena aggiornata:", scene_path)

	if not scene_map.has(scene_path):
		print("[GLUKY] Scena non mappata, uso prompt base")
		active_prompt = system_prompt_base
		current_context = ""
		return

	var info = scene_map[scene_path]
	current_context = info["context"]

	var game = info["game"]
	if game != "base" and prompts.has(game) and prompts[game] != "":
		active_prompt = prompts[game]
	else:
		active_prompt = system_prompt_base

	print("[GLUKY] Gioco attivo:", game, " | Contesto:", current_context)

	var tkey = info["tutorial_key"]
	var tmsg = info["tutorial_msg"]
	if tkey != "" and tmsg != "" and not _tutorials_shown.get(tkey, false):
		_tutorials_shown[tkey] = true
		_start_auto_tutorial(tmsg)

# ============================================================
# TUTORIAL AUTOMATICO
# ============================================================

func _start_auto_tutorial(msg: String):
	await get_tree().create_timer(2.0).timeout
	if state != State.IDLE:
		return

	if msg == "PRESENTAZIONE_CON_NOME":
		# Gluky si presenta, spiega il bottone, chiede il nome.
		# Il microfono NON parte da solo — il bambino preme quando vuole.
		_waiting_for_name = true
		print("[GLUKY] Presentazione iniziale con richiesta nome")
		_send_to_claude(
			"Sei Gluky e stai incontrando il bambino per la primissima volta in assoluto. " +
			"Fai una presentazione in 3 frasi brevi e allegre cosi strutturata: " +
			"Prima frase: presentati come Gluky il suo amico speciale in questo gioco e digli di guardarti al centro dello schermo. " +
			"Seconda frase: spiega come usare il bottone in basso: premilo una volta per iniziare a parlare e ripremilo quando hai finito di parlare per mandarmi la tua voce. " +
			"Terza frase: chiedigli come si chiama con entusiasmo. " +
			"Tono caloroso e da bambino. Niente markdown o simboli."
		)
	else:
		print("[GLUKY] Avvio tutorial automatico")
		_send_to_claude(msg)

# ============================================================
# PROCESS — controlla fine TTS
# ============================================================

func _process(_delta):
	if state == State.SPEAKING and not tts.speaking:
		_set_state(State.IDLE)

# ============================================================
# BOTTONE — comportamento identico a prima, nessuna modifica
# ============================================================

func _on_btn_pressed():
	match state:
		State.IDLE:
			_start_recording()
		State.RECORDING:
			_stop_recording()
		State.SPEAKING:
			_stop_tts()
		State.THINKING:
			pass

# ============================================================
# REGISTRAZIONE
# ============================================================

func _start_recording():
	print("[GLUKY] START RECORDING")
	stt.start_recording()
	_set_state(State.RECORDING)

func _stop_recording():
	print("[GLUKY] STOP RECORDING — pausa gioco durante Whisper")
	_set_state(State.THINKING)
	get_tree().paused = true
	stt.stop_recording()

# ============================================================
# STT → LOGICA NOME O CONVERSAZIONE NORMALE
# ============================================================

func _on_stt_result(text: String):
	get_tree().paused = false
	print("[STT]:", text)

	if text.strip_edges() == "":
		print("[GLUKY] Testo vuoto")
		# Se aspettavamo il nome e il bambino non ha detto nulla, via col tutorial
		if _waiting_for_name:
			_waiting_for_name = false
			_send_to_claude(_build_intro_tutorial_msg())
		else:
			_set_state(State.IDLE)
		return

	# Prova sempre a estrarre il nome
	_try_extract_name(text)

	# Se stavamo aspettando il nome: rispondi con entusiasmo + fai subito il tutorial
	if _waiting_for_name:
		_waiting_for_name = false
		_send_to_claude(_build_intro_tutorial_msg())
		return

	# Conversazione normale
	_send_to_claude(text)

# ============================================================
# MESSAGGIO DI RISPOSTA AL NOME + TUTORIAL STANZA
# ============================================================

func _build_intro_tutorial_msg() -> String:
	if child_name != "":
		return (
			"Il bambino si chiama " + child_name + ". " +
			"Rispondi con grandissimo entusiasmo usando subito il suo nome, poi in 2 frasi spiega la stanza di Gluky: " +
			"striscia il dito a sinistra per trovare Play a Minigame dove si scelgono i giochi, " +
			"striscia ancora a sinistra per la Libreria con i video, " +
			"striscia a destra per trovare la porta Quit per uscire. " +
			"Massimo 3 frasi totali. Niente markdown o simboli."
		)
	else:
		return (
			"Il bambino non ha detto il nome ma va benissimo. " +
			"Rispondi in modo allegro e spiega in 2 frasi la stanza di Gluky: " +
			"striscia il dito a sinistra per trovare Play a Minigame dove si scelgono i giochi, " +
			"striscia ancora a sinistra per la Libreria con i video, " +
			"striscia a destra per trovare la porta Quit per uscire. " +
			"Massimo 3 frasi totali. Niente markdown o simboli."
		)

# ============================================================
# ESTRAZIONE NOME DAL TESTO STT
# ============================================================

func _try_extract_name(text: String):
	if child_name != "":
		return

	var t = text.to_lower().strip_edges()

	# Pattern espliciti tipo "mi chiamo Marco", "sono Luca"
	var patterns = ["mi chiamo ", "sono ", "il mio nome è ", "il mio nome e ", "chiamami "]
	for p in patterns:
		var idx = t.find(p)
		if idx != -1:
			var after = text.substr(idx + p.length()).strip_edges()
			var parts = after.split(" ")
			if parts.size() > 0:
				var candidate = parts[0].rstrip("!,.")
				if candidate.length() >= 2 and candidate.length() <= 20:
					child_name = candidate.capitalize()
					print("[GLUKY] Nome appreso:", child_name)
					return

	# Fallback: se stavamo aspettando il nome e il bambino ha detto solo 1-2 parole
	# e quasi certamente il nome
	if _waiting_for_name:
		var words = text.strip_edges().split(" ")
		if words.size() <= 2:
			var candidate = words[0].rstrip("!,.")
			if candidate.length() >= 2 and candidate.length() <= 20:
				child_name = candidate.capitalize()
				print("[GLUKY] Nome appreso (risposta diretta):", child_name)

# ============================================================
# INVIO A CLAUDE CON CRONOLOGIA COMPLETA
# ============================================================

func _send_to_claude(user_text: String):
	if claude_busy:
		return

	claude_busy = true

	# Inietta contesto scena
	var full_text = user_text
	if current_context != "" and not user_text.begins_with("[SCENA"):
		full_text = "[SCENA ATTUALE: " + current_context + "]\n\n" + user_text

	# Aggiunge alla cronologia
	conversation_history.append({
		"role": "user",
		"content": [{ "type": "text", "text": full_text }]
	})

	while conversation_history.size() > MAX_HISTORY:
		conversation_history.pop_front()

	var body = JSON.stringify({
		"model": model,
		"max_tokens": 350,
		"system": _build_combined_prompt(),
		"messages": conversation_history
	})

	var headers = [
		"Content-Type: application/json",
		"x-api-key: " + api_key,
		"anthropic-version: 2023-06-01"
	]

	var err = http_request.request(
		"https://api.anthropic.com/v1/messages",
		headers,
		HTTPClient.METHOD_POST,
		body
	)

	if err != OK:
		print("[GLUKY] Errore HTTP:", err)
		claude_busy = false
		_set_state(State.IDLE)

# ============================================================
# COSTRUZIONE SYSTEM PROMPT DINAMICO
# ============================================================

func _build_combined_prompt() -> String:
	var base = active_prompt if active_prompt != "" else system_prompt_base

	# Sezione nome
	var name_section := ""
	if child_name != "":
		name_section = (
			"\n\n=== NOME DEL BAMBINO ===" +
			"\nIl bambino si chiama " + child_name + "." +
			"\nUsalo spesso nelle risposte: Bravo " + child_name + "!, Dai " + child_name + " ce la fai!, Grande " + child_name + "!"
		)
	else:
		name_section = "\n\n=== NOME DEL BAMBINO ===\nNon conosci ancora il nome. NON chiederlo ora."

	# Sezione prima interazione vs in corso
	var interaction_section := ""
	if _first_interaction:
		interaction_section = (
			"\n\n=== PRIMA INTERAZIONE ===" +
			"\nE la PRIMA volta assoluta che parli con questo bambino." +
			"\nPuoi presentarti come Gluky in modo brevissimo ed entusiasta." +
			"\nDopo questa prima volta NON ripresentarti mai piu."
		)
	else:
		interaction_section = (
			"\n\n=== CONVERSAZIONE IN CORSO ===" +
			"\nHai GIA parlato con questo bambino." +
			"\nNON dire chi sei. NON dire Ciao sono Gluky." +
			"\nVai subito al punto con inizio vario e naturale." +
			"\nRicorda tutto quello che vi siete detti e non ripeterti mai."
		)

	# Contesto altri giochi come riferimento secondario
	var extras := ""
	for key in prompts:
		if prompts[key] != "" and not active_prompt.begins_with(prompts[key].left(50)):
			extras += "\n\n=== CONOSCI ANCHE QUESTO GIOCO ===\n" + prompts[key].left(800)

	var extra_section := ""
	if extras != "":
		extra_section = "\n\n--- CONTESTO AGGIUNTIVO SUI GIOCHI ---" + extras

	return base + name_section + interaction_section + extra_section

# ============================================================
# RISPOSTA CLAUDE → CRONOLOGIA + TTS
# ============================================================

func _on_claude_response(result, response_code, _headers, body):
	claude_busy = false

	if response_code == 529 or response_code == 503:
		print("[GLUKY] Claude sovraccarico, riprovo tra 2 secondi")
		await get_tree().create_timer(2.0).timeout
		_set_state(State.IDLE)
		return

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("[GLUKY] Errore Claude:", response_code)
		_set_state(State.IDLE)
		return

	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		print("[GLUKY] Errore parsing JSON")
		_set_state(State.IDLE)
		return

	var data = json.get_data()
	if not data.has("content"):
		_set_state(State.IDLE)
		return

	var reply: String = data["content"][0]["text"]
	print("[CLAUDE]:", reply)

	_first_interaction = false

	# Salva risposta in cronologia
	conversation_history.append({
		"role": "assistant",
		"content": [{ "type": "text", "text": reply }]
	})

	while conversation_history.size() > MAX_HISTORY:
		conversation_history.pop_front()

	_set_state(State.SPEAKING)
	tts.speak(reply)

# ============================================================
# STOP TTS
# ============================================================

func _stop_tts():
	DisplayServer.tts_stop()
	tts.speaking = false
	_waiting_for_name = false
	_set_state(State.IDLE)

# ============================================================
# RESET SESSIONE — chiama quando cambia bambino
# Esempio: get_node("/root/Gluky").reset_session()
# ============================================================

func reset_session():
	conversation_history.clear()
	child_name = ""
	_first_interaction = true
	_waiting_for_name = false
	_tutorials_shown.clear()
	active_prompt = ""
	current_context = ""
	current_scene_path = ""
	print("[GLUKY] Sessione resettata — pronto per nuovo bambino")

# ============================================================
# STATI + COLORI BOTTONE
# ============================================================

func _set_state(s: State):
	state = s
	match s:
		State.IDLE:
			btn_record.text = "Parla"
			btn_record.disabled = false
			btn_record.modulate = Color(1, 1, 1, 1)
		State.RECORDING:
			btn_record.text = "Invia"
			btn_record.disabled = false
			btn_record.modulate = Color(1, 0.4, 0.4, 1)
		State.THINKING:
			btn_record.text = "Sto pensando..."
			btn_record.disabled = true
			btn_record.modulate = Color(1, 0.8, 0.0, 1)
		State.SPEAKING:
			btn_record.text = "Stop"
			btn_record.disabled = false
			btn_record.modulate = Color(0.4, 1, 0.4, 1)
