extends Node

var voice_id: String = ""
var queue: Array[String] = []
var speaking: bool = false
const QUEUE_MAX := 3

signal speech_finished

func _ready():
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		print("[TTS] TTS non supportato su questo dispositivo")
		return
	print("[TTS] Voci disponibili:")
	for v in DisplayServer.tts_get_voices():
		print(" - ID:", str(v.get("id")), " | Lingua:", str(v.get("language")))
	voice_id = find_italian_voice()
	if voice_id == "":
		print("[TTS] Nessuna voce italiana trovata. Uso fallback.")
	else:
		print("[TTS] Voce italiana selezionata:", voice_id)

func find_italian_voice() -> String:
	var fallback: String = ""
	for v in DisplayServer.tts_get_voices():
		var lang: String = str(v.get("language", ""))
		if lang.begins_with("it"):
			return str(v["id"])
		if fallback == "":
			fallback = str(v["id"])
	return fallback

func _clean_text(text: String) -> String:
	var regex = RegEx.new()

	# Rimuovi asterischi e testo tra asterischi
	regex.compile("\\*+[^*]*\\*+")
	text = regex.sub(text, " ", true)

	# Rimuovi asterischi rimasti
	regex.compile("\\*+")
	text = regex.sub(text, " ", true)

	# Rimuovi spazi doppi
	regex.compile("\\s+")
	text = regex.sub(text, " ", true)

	return text.strip_edges()

func speak(text: String):
	text = text.strip_edges()
	if text == "":
		return
	text = _clean_text(text)
	if text == "":
		return
	if queue.size() >= QUEUE_MAX:
		queue.pop_front()
	queue.append(text)
	if not speaking:
		_play_next()

func _play_next():
	if queue.is_empty():
		speaking = false
		emit_signal("speech_finished")
		return
	speaking = true
	var current_text: String = queue.pop_front()
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(current_text, voice_id)

func _process(_delta: float) -> void:
	if speaking and not DisplayServer.tts_is_speaking():
		if queue.size() > 0:
			_play_next()
		else:
			speaking = false
			emit_signal("speech_finished")
