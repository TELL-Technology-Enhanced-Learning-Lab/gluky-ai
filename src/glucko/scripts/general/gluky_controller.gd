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

var api_key := "inserisci la chiave api"
var model := "claude-haiku-4-5-20251001"

var system_prompt := """
Sei Gluky, un assistente simpatico e colorato all'interno di un videogioco educativo sul diabete per bambini.
Il tuo compito è aiutare i bambini con diabete tipo 1 a capire la loro condizione in modo semplice, rassicurante e divertente.

CHI SEI:
Ti chiami Gluky.
Sei un personaggio del gioco, amico del bambino.
Parli sempre in italiano.
Usi un linguaggio semplicissimo adatto a bambini di 5-7 anni.
Sei sempre allegro, incoraggiante e rassicurante.
Usi frasi corte.
Non sei un medico e non dai mai consigli medici o clinici.
Rispondi sempre in massimo 3 frasi brevi.

REGOLE IMPORTANTI:
Non dare MAI dosi di insulina o indicazioni terapeutiche.
Se chiedono dosi o valori precisi rispondi:
"Questa è una domanda per il tuo dottore o per la tua mamma e il tuo papà!"
Se il bambino dice che si sente male rispondi:
"Dillo subito a un adulto vicino a te!"
Non spaventare mai il bambino.
Rispondi solo su argomenti legati al diabete e al gioco.
Non usare simboli, emoji o markdown.
"""

var http_request: HTTPRequest
var claude_busy := false
var stt

# ============================================================
# STATI
# ============================================================

enum State { IDLE, RECORDING, THINKING, SPEAKING }
var state := State.IDLE

# ============================================================
# READY
# ============================================================

func _ready():

	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_claude_response)

	stt = STT
	stt.transcription_complete.connect(_on_stt_result)

	microphone.play()

	btn_record.pressed.connect(_on_btn_pressed)

	_set_state(State.IDLE)
	print("GLUKY pronto")

# ============================================================
# CONTROLLO FINE TTS
# ============================================================

func _process(_delta):
	if state == State.SPEAKING and not tts.speaking:
		print("TTS finito → torno IDLE")
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
	print("START RECORDING")
	stt.start_recording()
	_set_state(State.RECORDING)

func _stop_recording():
	print("STOP RECORDING")
	stt.stop_recording()
	_set_state(State.THINKING)

# ============================================================
# STT → CLAUDE
# ============================================================

func _on_stt_result(text: String):

	print("STT:", text)

	if text.strip_edges() == "":
		print("Testo vuoto")
		_set_state(State.IDLE)
		return

	_send_to_claude(text)

func _send_to_claude(user_text: String):

	if claude_busy:
		return

	claude_busy = true

	var body = JSON.stringify({
		"model": model,
		"max_tokens": 300,
		"system": system_prompt,
		"messages": [
			{
				"role": "user",
				"content": [
					{ "type": "text", "text": user_text }
				]
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
		print("Errore HTTP:", err)
		claude_busy = false
		_set_state(State.IDLE)

# ============================================================
# RISPOSTA CLAUDE → TTS
# ============================================================

func _on_claude_response(result, response_code, _headers, body):

	claude_busy = false

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("Errore Claude:", response_code)
		_set_state(State.IDLE)
		return

	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		print("Errore parsing JSON")
		_set_state(State.IDLE)
		return

	var data = json.get_data()

	if not data.has("content"):
		_set_state(State.IDLE)
		return

	var reply: String = data["content"][0]["text"]

	print("Claude:", reply)

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
# GESTIONE STATI
# ============================================================

func _set_state(s: State):

	state = s

	match s:

		State.IDLE:
			btn_record.text = "Parla"
			btn_record.disabled = false

		State.RECORDING:
			btn_record.text = "Invia"
			btn_record.disabled = false

		State.THINKING:
			btn_record.text = "Penso..."
			btn_record.disabled = true

		State.SPEAKING:
			btn_record.text = "Stop"
			btn_record.disabled = false
