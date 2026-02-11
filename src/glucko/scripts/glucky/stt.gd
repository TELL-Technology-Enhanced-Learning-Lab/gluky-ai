extends Node

@export var whisper_binary_path := "res://bin/whisper"       
@export var whisper_model_path := "res://models/tiny-q8_0.bin" 
@export var max_record_time := 20.0                           

var capture: AudioEffectCapture
var recording := false
var recorded_data: PackedFloat32Array = []
var record_timer := 0.0

func _ready():
	var bus_index = AudioServer.get_bus_index("Record")
	capture = AudioServer.get_bus_effect(bus_index, 0)

func start_recording():
	recorded_data.clear()
	record_timer = 0.0
	recording = true
	print("Recording started")

func stop_recording():
	recording = false
	print("Recording stopped")
	save_wav()
	var text = run_whisper("user://voice.wav")
	print("STT Result: ", text)
	# Qui mettiamo la funzione risposta dell'API dell'AI più avanti
	# send_to_ai(text)

func _process(delta):
	if recording:
		record_timer += delta
		if record_timer >= max_record_time:
			stop_recording()
			return
		if capture.get_frames_available() > 0:
			var frames = capture.get_buffer(capture.get_frames_available())
			for f in frames:
				recorded_data.append(f)

func save_wav():
	var file = FileAccess.open("user://voice.wav", FileAccess.WRITE)
	if file == null:
		return

	var sample_rate = 16000
	var data = PackedByteArray()
	for f in recorded_data:
		var sample = int(clamp(f, -1.0, 1.0) * 32767.0)
		data.append(sample & 0xFF)
		data.append((sample >> 8) & 0xFF)

	write_wav_header(file, data.size(), sample_rate)
	file.store_buffer(data)
	file.close()

func write_wav_header(file: FileAccess, data_size: int, sample_rate: int):
	file.store_string("RIFF")
	file.store_32(36 + data_size)
	file.store_string("WAVE")
	file.store_string("fmt ")
	file.store_32(16)
	file.store_16(1)
	file.store_16(1)
	file.store_32(sample_rate)
	file.store_32(sample_rate * 2)
	file.store_16(2)
	file.store_16(16)
	file.store_string("data")
	file.store_32(data_size)

func run_whisper(audio_path: String) -> String:
	var args = [
		"-m", whisper_model_path,
		"-f", audio_path,
		"-l", "it"
	]
	var output = []
	var error_code = OS.execute(whisper_binary_path, args, output, true)
	if error_code != 0:
		print("Whisper execution failed")
		return ""
	return output.join("\n")
