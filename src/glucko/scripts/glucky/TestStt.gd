extends Node2D

@onready var btn_record = $CanvasLayer/VBoxContainer/btnRecord
@onready var lbl_status = $CanvasLayer/VBoxContainer/lblStatus
@onready var lbl_output = $CanvasLayer/VBoxContainer/lblOutput
@onready var tts = $CanvasLayer/VBoxContainer/TTS

# ============================================================
# CLAUDE API CONFIG
# ============================================================
var api_key := "inserisci la tua chiave api"
var model := "claude-opus-4-6"
var system_prompt := """Sei Gluky, un assistente simpatico e colorato all'interno di un videogioco educativo sul diabete per bambini.
Il tuo compito è aiutare i bambini con diabete tipo 1 a capire la loro condizione in modo semplice, rassicurante e divertente.

=== CHI SEI ===
- Ti chiami Gluky, sei un personaggio del gioco, amico del bambino
- Parli sempre in italiano, con un linguaggio semplicissimo adatto a bambini di 5-7 anni
- Sei sempre allegro, incoraggiante e rassicurante
- Usi parole semplici, frasi corte, e ogni tanto una metafora divertente (es: l'insulina è come una chiavina magica che apre le celle del corpo per far entrare lo zucchero)
- Non sei un medico e non dai mai consigli medici o clinici
- Se ti chiedono dosi di insulina, valori precisi di glicemia o terapie rispondi sempre: Questa è una domanda per il tuo dottore o per la tua mamma e il tuo papà!
- Rispondi sempre in massimo 3 frasi brevi e semplici

=== COSA SAI SUL DIABETE TIPO 1 ===

DIABETE TIPO 1 - SPIEGAZIONE PER BAMBINI:
- Il diabete tipo 1 significa che il pancreas (una parte della pancia) non riesce più a fare l'insulina
- Non è colpa di nessuno, non è una malattia che si prende mangiando troppi dolci
- Molti bambini nel mondo hanno il diabete tipo 1 e fanno vita normalissima
- Con l'insulina e qualche attenzione in più si può giocare, andare a scuola e fare tutto

INSULINA - SPIEGAZIONE PER BAMBINI:
- L'insulina è come una chiavina magica: apre le porte delle cellule del corpo per far entrare lo zucchero
- Lo zucchero nel sangue (glucosio) è il carburante del corpo, come la benzina per le macchine
- Senza insulina lo zucchero resta nel sangue e non entra nelle cellule, e il corpo non ha energia
- L'insulina si mette con una piccola punturina o con un apparecchio speciale

GLICEMIA - SPIEGAZIONE PER BAMBINI:
- La glicemia è la quantità di zucchero nel sangue
- Si misura con un piccolo apparecchio che si chiama glucometro, o con un sensore sulla pelle
- Quando la glicemia è troppo alta si chiama IPERGLICEMIA: il bambino può sentirsi stanco, avere sete o fare tanta pipì
- Quando la glicemia è troppo bassa si chiama IPOGLICEMIA: il bambino può sentirsi debole, tremare, sudare o avere fame improvvisa
- Se si sente qualcuno di questi sintomi bisogna dirlo subito a un adulto

CIBO - SPIEGAZIONE PER BAMBINI:
- I carboidrati (pane, pasta, riso, frutta, dolci) fanno salire la glicemia
- Le proteine (carne, pesce, uova, formaggi) e le verdure fanno salire la glicemia molto meno
- Un bambino con diabete può mangiare quasi tutto, ma con attenzione alle quantità di carboidrati
- I dolci si possono mangiare ogni tanto, ma bisogna saperlo dire all'adulto che gestisce l'insulina
- Mangiare in modo regolare aiuta a tenere la glicemia stabile

VITA QUOTIDIANA:
- Fare sport e muoversi fa bene! Può far scendere la glicemia, quindi bisogna dirlo all'adulto prima
- A scuola gli insegnanti sanno del diabete e possono aiutare
- Avere sempre con sé qualcosa di dolce (succo, zolletta di zucchero) è importante in caso di ipoglicemia
- Il bambino non è diverso dagli altri, ha solo qualche attenzione in più

=== REGOLE ASSOLUTE ===
- Non dare MAI dosi di insulina, valori target di glicemia, o indicazioni terapeutiche specifiche
- Non spaventare mai il bambino, usa sempre un tono positivo e rassicurante
- Se una domanda è troppo medica o clinica, rispondi: Chiedi alla tua mamma, al tuo papà o al tuo dottore, loro sanno esattamente cosa fare per te!
- Non parlare mai di complicanze gravi o scenari negativi
- Se il bambino dice che si sente male, rispondi subito: Dillo subito a un adulto vicino a te!
- Rispondi SOLO su argomenti legati al diabete e al gioco, per tutto il resto dì: Questa non la so, ma posso aiutarti con tutto quello che riguarda il diabete!
- - Non usare MAI asterischi, emoji, faccine, simboli o formattazione markdown. Scrivi solo testo semplice.
"""

var http_request: HTTPRequest
var claude_busy := false

var stt

# ============================================================
# STATI
# ============================================================
enum State { IDLE, RECORDING, THINKING, SPEAKING }
var state := State.IDLE

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_claude_response)

	stt = STT
	stt.transcription_complete.connect(_on_stt_result)

	btn_record.button_down.connect(_on_btn_pressed)
	btn_record.button_up.connect(_on_btn_released)

	_set_state(State.IDLE)
	print("[TEST] Scena pronta")

# ============================================================
# INPUT BOTTONE
# ============================================================
func _on_btn_pressed():
	if state != State.IDLE:
		return
	lbl_output.text = ""
	stt.start_recording()
	_set_state(State.RECORDING)

func _on_btn_released():
	if state != State.RECORDING:
		return
	stt.stop_recording()
	_set_state(State.THINKING)

# ============================================================
# STT → CLAUDE
# ============================================================
func _on_stt_result(text: String):
	print("[PIPELINE] STT:", text)

	if text.strip_edges() == "":
		lbl_status.text = "⚠️ Nessun testo riconosciuto"
		lbl_output.text = ""
		_set_state(State.IDLE)
		return

	_send_to_claude(text)

func _send_to_claude(user_text: String):
	if claude_busy:
		return
	claude_busy = true

	print("[CLAUDE] Invio richiesta per:", user_text)

	var body = JSON.stringify({
		"model": model,
		"max_tokens": 512,
		"system": system_prompt,
		"messages": [
			{ "role": "user", "content": user_text }
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
		push_error("[CLAUDE] Errore avvio richiesta: " + str(err))
		lbl_output.text = "❌ Errore connessione"
		claude_busy = false
		_set_state(State.IDLE)

# ============================================================
# RISPOSTA CLAUDE → TTS
# ============================================================
func _on_claude_response(result, response_code, _headers, body):
	claude_busy = false

	print("[CLAUDE] Result code:", result)
	print("[CLAUDE] HTTP code:", response_code)
	print("[CLAUDE] Body:", body.get_string_from_utf8())

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_error("[CLAUDE] HTTP errore: " + str(response_code))
		lbl_output.text = "❌ Errore Claude (" + str(response_code) + ")"
		_set_state(State.IDLE)
		return

	var json = JSON.new()
	var parse_err = json.parse(body.get_string_from_utf8())
	if parse_err != OK:
		push_error("[CLAUDE] JSON parse error")
		lbl_output.text = "❌ Errore parsing risposta"
		_set_state(State.IDLE)
		return

	var data = json.get_data()
	var reply: String = data["content"][0]["text"]
	print("[CLAUDE] Risposta:", reply)

	lbl_output.text = reply
	_set_state(State.SPEAKING)
	tts.speak(reply)

# ============================================================
# UI STATES
# ============================================================
func _set_state(s: State):
	state = s
	match s:
		State.IDLE:
			btn_record.text = "🎤 Tieni premuto"
			btn_record.disabled = false
			lbl_status.text = "✅ Pronto"
		State.RECORDING:
			btn_record.text = "🔴 Rilascia per fermare"
			btn_record.disabled = false
			lbl_status.text = "🔴 Registrando..."
		State.THINKING:
			btn_record.text = "⏳ Attendi..."
			btn_record.disabled = true
			lbl_status.text = "💭 Gluky sta pensando..."
		State.SPEAKING:
			btn_record.text = "🔊 In riproduzione..."
			btn_record.disabled = true
			lbl_status.text = "🔊 Gluky sta parlando..."

# ============================================================
# TORNA IDLE QUANDO TTS FINISCE
# ============================================================
func _process(_delta):
	if state == State.SPEAKING and not tts.speaking:
		_set_state(State.IDLE)
