extends Node

var voice_id := ""
var queue: Array[String] = []
var speaking := false
const QUEUE_MAX := 3

func _ready():
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return
	voice_id = find_italian_voice()

func find_italian_voice() -> String:
	for v in DisplayServer.tts_get_voices():
		if v.get("language", "").begins_with("it"):
			return v["id"]
	return ""

func speak(text: String):
	text = text.strip_edges()
	if text == "":
		return
	if queue.size() >= QUEUE_MAX:
		queue.pop_front()
	queue.append(text)
	if not speaking:
		_play_next()

func _play_next():
	if queue.size() == 0:
		speaking = false
		return
	speaking = true
	var current_text = queue.pop_front()
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(current_text, voice_id)

func _process(_delta):
	if speaking:
		if not DisplayServer.tts_is_speaking():
			if queue.size() > 0:
				_play_next()
			else:
				speaking = false
