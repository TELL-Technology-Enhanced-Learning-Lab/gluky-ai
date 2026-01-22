extends VideoStreamPlayer

@export var loop_start_second: float = 6.0
var is_looping: bool = false
var exit_loop_flag: bool = false

func _ready() -> void:
	autoplay = true
	loop = false  # Assicurati che il loop nativo sia OFF
	finished.connect(_on_video_finished)

func _on_video_finished() -> void:
	if not exit_loop_flag:
		is_looping = true
		volume_db = -80  # Muta audio
		
		# Usa paused per transizione più fluida
		paused = false
		stream_position = loop_start_second
		play()

func exit_loop() -> void:
	exit_loop_flag = true
	is_looping = false
	volume_db = 0
	stream_position = 0.0
	play()
