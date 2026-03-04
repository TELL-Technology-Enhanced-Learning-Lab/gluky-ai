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

var api_key := "inserisci la tua chiave api"
var model := "claude-haiku-4-5-20251001"

# ============================================================
# SYSTEM PROMPT BASE — caricato da file, fallback inline
# ============================================================
var system_prompt_base := """
=== CHI SEI ===
Ti chiami Gluky. Sei il fedele assistente virtuale di un videogioco educativo sul diabete tipo 1 pensato per bambini di 5-7 anni.
Sei allegro, paziente, incoraggiante e rassicurante. Parli SEMPRE in italiano.
Sei l'amico del bambino dentro il gioco, non un medico.

=== COME PARLI ===
- Usi frasi cortissime e parole semplicissime, come se parlassi con un bambino di 5 anni.
- Rispondi SEMPRE in massimo 3 frasi brevi.
- Non usi MAI simboli, emoji, asterischi, trattini o formattazione markdown.
- Scrivi solo testo semplice e pulito.
- Ogni tanto usi metafore divertenti per spiegare cose difficili.
  Esempio: l'insulina e come una chiavina magica che apre le porte delle cellule per far entrare lo zucchero.

=== COME INIZI LE RISPOSTE ===
- Non iniziare MAI ogni risposta con "Ciao sono Gluky" o presentandoti ogni volta.
- Presentati SOLO la prima volta che parli con il bambino o quando lui ti chiede chi sei.
- Nelle risposte successive vai subito al punto, come in una conversazione naturale tra amici.
- Varia sempre il modo in cui inizi le frasi per sembrare spontaneo e non ripetitivo.
- Esempi di inizi diversi: Certo!, Ottima domanda!, Allora..., Sai cosa?, Hai ragione!, Guarda..., Mmm vediamo...
- Una conversazione naturale non inizia sempre nello stesso modo, quindi cambia sempre.

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

# Prompt attivo in questo momento
var active_prompt := ""

# ============================================================
# MAPPA SCENE → GIOCO + CONTESTO + TUTORIAL
# ============================================================

# Struttura: "percorso_scena" : { game, context, tutorial_key, tutorial_msg }
var scene_map := {

"res://scenes/menus/glucky/Intro_3d.tscn": {
	"game"        : "base",
	"context"     : "Menu principale di Gluky (Intro_3d). La scena si svolge in una stanza 3D in stile cartoon dal sapore accogliente e domestico: pareti in tonalità pastello (grigio-azzurro, rosa, lilla), pavimento in legno marrone, tappeto rosa, luci decorative a festoni sul soffitto, scaffali con libri colorati, una scrivania con due monitor gialli, un divano grigio e poster del personaggio Gluky appesi alla parete. Il personaggio principale (Gluky, bambino con casco blu e tuta bianco-blu) è posizionato al centro della stanza. Il bambino controlla la visuale strisciando il dito sullo schermo: strisciando a sinistra la camera ruota verso sinistra e appare l'hotspot 'Play a Minigame' per accedere alla selezione dei minigiochi. Strisciando ancora a sinistra appare la 'Libreria' con i video tutorial. Strisciando a destra dalla posizione iniziale appare la porta con l'hotspot 'Quit' per uscire. In alto a destra è sempre visibile la mascotte pipistrello viola con il pulsante 'Parla' per interagire con l'assistente AI.",
	"tutorial_key": "intro_3d",
	"tutorial_msg": "Dai un benvenuto caloroso al bambino. Spiegagli che si trova nella stanza di Gluky e che puo guardare intorno strisciando il dito sullo schermo. Digli: striscia il dito verso sinistra e trovi Play a Minigame dove puoi scegliere un gioco e divertirti. Striscia ancora a sinistra e trovi la Libreria con i video per imparare i giochi. Striscia verso destra e trovi la porta Quit per uscire. Ricordagli che il pipistrello in alto a destra e sempre li per aiutarlo. Sii brevissimo, entusiasta e usa parole semplici da bambino di 5-7 anni. Niente markdown o simboli."
},

	"res://scenes/menus/glucky/Minigame_Selection.tscn": {
		"game"        : "base",
		"context"     : "Schermata selezione giochi. Il bambino puo scegliere tra GlukoRun, GlukoLife, MealPerfect e GlukoQuiz.",
		"tutorial_key": "minigame_selection",
		"tutorial_msg": "Presenta i quattro giochi in modo breve e divertente per un bambino di 5-7 anni. GlukoRun è un gioco dove si corre si salta e si impara come funziona la glicemia raccogliendo cibi. GlukoLife e un gioco dove ti prendi cura di un personaggio speciale facendolo mangiare dormire lavare e giocare. MealPerfect e un gioco dove si imparano a comporre piatti perfetti bilanciando gli alimenti. GlukoQuiz e un gioco a domande per scoprire quanto hai imparato sul diabete. Chiedi al bambino con quale vuole iniziare. Sii breve entusiasta e usa un linguaggio semplice. Niente markdown o simboli."
	},

	"res://scenes/glucorun levels/livello1.tscn": {
		"game"        : "glucorun",
		"context"     : "Livello 1 di GlukoRun. Il bambino corre raccoglie cibi e impara a gestire la glicemia del personaggio.",
		"tutorial_key": "glucorun_livello1",
		"tutorial_msg": "Fai un tutorial di benvenuto breve per il Livello 1 di GlukoRun. Spiega che il personaggio corre automaticamente e il bambino deve saltare per raccogliere i cibi giusti e tenere la barra della glicemia nella zona verde. I cibi sani mantengono la glicemia in equilibrio. I dolci la fanno salire troppo. Se la glicemia scende troppo il personaggio si stanca. Sii breve divertente e usa il system prompt di GlukoRun per i dettagli. Niente markdown o simboli."
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
		"tutorial_msg": "Fai il tutorial di benvenuto di GlukoQuiz preso dal tuo system prompt. Spiega che ci sono tre livelli Colazione Pranzo e Cena. In ogni livello ci sono 10 domande a risposta multipla con 15 secondi di tempo per rispondere. Risposta giusta vale 2 punti risposta sbagliata toglie 1 punto. Sii breve entusiasta e usa un linguaggio da bambino. Niente markdown o simboli."
	},

	"res://scenes/scenes_tutorial/Menu_inizio.tscn": {
"game"        : "mealperfect",
"context"     : "Menu iniziale di MealPerfect. Il bambino sta per entrare nel gioco dei piatti perfetti ambientato in una cucina giapponese.",
"tutorial_key": "mealperfect_menu",
"tutorial_msg": "Benvenuto in MealPerfect! Nel menu iniziale puoi scegliere un livello tra colazione, pranzo o cena. Se premi direttamente Play partirai dal pranzo. Puoi anche toccare Info per leggere piccoli tutorial utili. Quando il gioco inizia ti troverai in una cucina giapponese virtuale: il tuo compito è creare piatti perfetti scegliendo al massimo 3 alimenti e mantenendo il valore glicemico virtuale tra 15 e 30. Per giocare trascina gli alimenti nel piatto con il sistema drag and drop. Divertiti a creare combinazioni perfette!"
},

	"res://scenes/glucolife rooms/Kitchen.tscn": {
		"game"        : "glucolife",
		"context"     : "Cucina virtuale di GlukoLife. Il bambino sta dando da mangiare al personaggio dai capelli blu scegliendo i cibi giusti per tenere la glicemia simulata in equilibrio.",
		"tutorial_key": "glucolife_cucina",
		"tutorial_msg": "Fai il tutorial  di GlukoLife preso dal tuo system prompt poi fai il tutorial della cucina. Spiega che qui il bambino tocca i cibi sullo schermo per far mangiare il personaggio virtuale dai capelli blu. I cibi sani ricaricano la barra della fame in modo equilibrato. I dolci la ricaricano velocemente ma alzano troppo la glicemia simulata del personaggio nel gioco. Ricorda sempre che nella vita reale la dieta la gestiscono i genitori e il medico. Sii breve affettuoso e usa un linguaggio da bambino. Niente markdown o simboli."
	},

"res://scenes/glucolife rooms/Living room.tscn": {
"game"        : "glucolife",
"context"     : "Cameretta virtuale di GlukoLife. Il bambino fa dormire il personaggio dai capelli blu per ricaricare la barra del sonno.",
"tutorial_key": "glucolife_cameretta",
"tutorial_msg": "Questa è la cameretta del personaggio dai capelli blu. Qui può fare la nanna per ricaricare la sua energia del sonno. Tocca il letto per farlo addormentare e guardalo riposare tranquillo. Dormire lo aiuta a stare bene e a giocare meglio dopo."
},

"res://scenes/glucolife rooms/Restroom.tscn": {
"game"        : "glucolife",
"context"     : "Bagno virtuale di GlukoLife. Il bambino fa lavare il personaggio dai capelli blu per ricaricare la barra dell igiene.",
"tutorial_key": "glucolife_bagno",
"tutorial_msg": "Nel bagno puoi far lavare il personaggio dai capelli blu. Tocca la doccia o il lavandino per farlo pulire bene. Lavarsi ricarica la barra dell igiene e lo fa sentire fresco e felice. È un momento importante per prendersi cura di lui."
},

	"res://scenes/glucolife rooms/PlayGround.tscn": {
"game"        : "glucolife",
"context"     : "Parco giochi virtuale di GlukoLife. Il bambino fa giocare il personaggio dai capelli blu per ricaricare la barra dell energia.",
"tutorial_key": "glucolife_parco",
"tutorial_msg": "Prima dici che si Trova nel Parco gioco dandoli il bennvenuto e poi spiega che Al parco giochi il personaggio dai capelli blu può muoversi e divertirsi. Tocca le giostre o i giochi per farlo correre e saltare. Così ricarica la barra dell energia e diventa più attivo e contento. Giocare lo aiuta a stare in forma e a sorridere."
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

enum State { IDLE, RECORDING, THINKING, SPEAKING }
var state := State.IDLE

# ============================================================
# READY
# ============================================================

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Carica tutti i system prompt dai file txt
	_load_all_prompts()

	# HTTP asincrono
	http_request = HTTPRequest.new()
	http_request.use_threads = true
	http_request.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(http_request)
	http_request.request_completed.connect(_on_claude_response)

	# STT
	stt = STT
	stt.transcription_complete.connect(_on_stt_result)

	# Microfono e TTS sempre attivi
	microphone.process_mode = Node.PROCESS_MODE_ALWAYS
	microphone.play()
	tts.process_mode = Node.PROCESS_MODE_ALWAYS

	# Bottone sempre attivo
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

	# Seleziona il prompt giusto per il gioco
	var game = info["game"]
	if game != "base" and prompts.has(game) and prompts[game] != "":
		active_prompt = prompts[game]
	else:
		active_prompt = system_prompt_base

	print("[GLUKY] Gioco attivo:", game)
	print("[GLUKY] Contesto:", current_context)

	# Avvia tutorial automatico se previsto e non ancora mostrato
	var tkey = info["tutorial_key"]
	var tmsg = info["tutorial_msg"]
	if tkey != "" and tmsg != "" and not _tutorials_shown.get(tkey, false):
		_tutorials_shown[tkey] = true
		_start_auto_tutorial(tmsg)

func _start_auto_tutorial(msg: String):
	await get_tree().create_timer(2.0).timeout
	if state == State.IDLE:
		print("[GLUKY] Avvio tutorial automatico")
		_send_to_claude(msg)

# ============================================================
# PROCESS — controlla fine TTS
# ============================================================

func _process(_delta):
	if state == State.SPEAKING and not tts.speaking:
		_set_state(State.IDLE)

# ============================================================
# BOTTONE
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
# STT → CLAUDE
# ============================================================

func _on_stt_result(text: String):
	get_tree().paused = false
	print("[STT]:", text)

	if text.strip_edges() == "":
		print("[GLUKY] Testo vuoto")
		_set_state(State.IDLE)
		return

	_send_to_claude(text)

func _send_to_claude(user_text: String):
	if claude_busy:
		return

	claude_busy = true

	# Costruisce il messaggio con contesto scena iniettato
	var full_text = user_text
	if current_context != "":
		full_text = "[SCENA ATTUALE: " + current_context + "]\n\n" + user_text

	# Combina tutti i prompt disponibili per risposta trasversale
	var combined_prompt = _build_combined_prompt()

	var body = JSON.stringify({
		"model": model,
		"max_tokens": 350,
		"system": combined_prompt,
		"messages": [
			{
				"role": "user",
				"content": [{ "type": "text", "text": full_text }]
			}
		]
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

# Costruisce un prompt che include TUTTI i giochi disponibili
# cosi Gluky puo rispondere a qualsiasi domanda trasversale
func _build_combined_prompt() -> String:
	var base = active_prompt if active_prompt != "" else system_prompt_base

	# Aggiunge sezioni degli altri giochi come contesto secondario
	var extras := ""
	for key in prompts:
		if prompts[key] != "" and not active_prompt.begins_with(prompts[key].left(50)):
			extras += "\n\n=== CONOSCI ANCHE QUESTO GIOCO ===\n" + prompts[key].left(800)

	if extras != "":
		return base + "\n\n--- CONTESTO AGGIUNTIVO SUI GIOCHI ---" + extras

	return base

# ============================================================
# RISPOSTA CLAUDE → TTS
# ============================================================

func _on_claude_response(result, response_code, _headers, body):
	claude_busy = false

	if response_code == 529 or response_code == 503:
		print("[GLUKY] Claude sovraccarico, riprovo tra 2 secondi")
		await get_tree().create_timer(2.0).timeout
		claude_busy = false
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

	_set_state(State.SPEAKING)
	tts.speak(reply)

# ============================================================
# STOP TTS
# ============================================================

func _stop_tts():
	DisplayServer.tts_stop()
	tts.speaking = false
	_set_state(State.IDLE)

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
