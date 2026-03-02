extends Node

@export var max_record_time := 20.0
@export var whisper_model_path := "res://models/model.bin"

var capture: AudioEffectCapture
var recording := false
var record_timer := 0.0
var recorded_data = PackedFloat32Array()

signal transcription_complete(text)

var recognizer = null
var is_android := false
var model_ready := false

func _ready():
	print("===== STT LOADED =====")
	is_android = OS.get_name() == "Android"
	print("[STT] Platform:", OS.get_name())

	var bus_index = AudioServer.get_bus_index("Record")
	if bus_index == -1:
		push_error("[STT] Record bus NOT found!")
		return

	capture = AudioServer.get_bus_effect(bus_index, 0)
	if capture == null:
		push_error("[STT] AudioEffectCapture NOT found!")
		return

	AudioServer.set_bus_volume_db(bus_index, -80.0)
	print("[STT] Record bus OK - mix rate:", AudioServer.get_mix_rate())

	if not is_android:
		print("[STT] PC mode - nessuna trascrizione disponibile")
		return

	if not ClassDB.class_exists("SpeechRecognizer"):
		push_error("[STT] SpeechRecognizer plugin NOT found!")
		return

	var user_model_path = "user://model.bin"
	if not FileAccess.file_exists(user_model_path):
		print("[STT] Copying model to user://...")
		var src = FileAccess.open(whisper_model_path, FileAccess.READ)
		if src == null:
			push_error("[STT] Cannot open model from res://!")
			return
		var data = src.get_buffer(src.get_length())
		src.close()
		var dst = FileAccess.open(user_model_path, FileAccess.WRITE)
		if dst == null:
			push_error("[STT] Cannot write to user://!")
			return
		dst.store_buffer(data)
		dst.close()
		print("[STT] Model copied OK")
	else:
		print("[STT] Model already present in user://")

	await get_tree().process_frame
	await get_tree().process_frame

	recognizer = ClassDB.instantiate("SpeechRecognizer")
	if recognizer == null:
		push_error("[STT] Failed to instantiate SpeechRecognizer!")
		return

	var real_path = ProjectSettings.globalize_path(user_model_path)
	print("[STT] Loading model:", real_path)

	model_ready = recognizer.load_model(real_path)
	print("[STT] Model loaded:", model_ready)

	if model_ready:
		recognizer.transcription_complete.connect(_on_transcription_complete)
		print("[STT] STT READY!")
	else:
		push_error("[STT] Model FAILED to load!")

func start_recording():
	print(">>> start_recording() CALLED")
	if is_android and not model_ready:
		print("[STT] Model not ready!")
		return
	if recording:
		print("[STT] Already recording!")
		return
	capture.clear_buffer()
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), true)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), true)
	recorded_data = PackedFloat32Array()
	record_timer = 0.0
	recording = true
	print("[STT] Recording STARTED")

func stop_recording():
	print(">>> stop_recording() CALLED")
	if not recording:
		return
	recording = false
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), false)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), false)
	print("[STT] Samples:", recorded_data.size())
	print("[STT] Duration:", float(recorded_data.size()) / float(AudioServer.get_mix_rate()), "sec")

	var max_amp := 0.0
	for s in recorded_data:
		max_amp = max(max_amp, abs(s))
	print("[STT] Max amplitude:", max_amp)

	if max_amp < 0.001:
		print("[STT] Silenzio totale!")
		emit_signal("transcription_complete", "")
		return

	if recorded_data.size() < 8000:
		print("[STT] Audio troppo corto!")
		emit_signal("transcription_complete", "")
		return

	if not is_android:
		print("[STT] PC mode - skip trascrizione")
		emit_signal("transcription_complete", "")
		return

	if recognizer != null and model_ready:
		var resampled = resample_to_16k(recorded_data)
		print("[STT] Sending", resampled.size(), "samples to Whisper...")
		recognizer.transcribe_audio(resampled)
	else:
		push_error("[STT] Recognizer not ready!")
		emit_signal("transcription_complete", "")

func resample_to_16k(data: PackedFloat32Array) -> PackedFloat32Array:
	var input_rate = float(AudioServer.get_mix_rate())
	var output_rate = 16000.0
	var ratio = input_rate / output_rate
	var new_size = int(data.size() / ratio)
	var resampled = PackedFloat32Array()
	resampled.resize(new_size)
	for i in new_size:
		var src_pos = float(i) * ratio
		var idx = int(src_pos)
		var frac = src_pos - idx
		var s0 = data[clamp(idx, 0, data.size() - 1)]
		var s1 = data[clamp(idx + 1, 0, data.size() - 1)]
		resampled[i] = s0 + frac * (s1 - s0)
	print("[STT] Resample:", data.size(), "->", resampled.size(), "@16kHz")
	return resampled

func _process(delta):
	if not recording:
		return
	record_timer += delta
	if record_timer >= max_record_time:
		print("[STT] Max time reached")
		stop_recording()
		return
	var frames_available = capture.get_frames_available()
	if frames_available > 0:
		var frames = capture.get_buffer(frames_available)
		var old_size = recorded_data.size()
		recorded_data.resize(old_size + frames.size())
		for i in frames.size():
			recorded_data[old_size + i] = clamp(frames[i].x, -1.0, 1.0)

func _on_transcription_complete(text: String):
	print("===== WHISPER RESULT =====")
	print("[STT] Text:", text)
	print("==========================")
	emit_signal("transcription_complete", text)
