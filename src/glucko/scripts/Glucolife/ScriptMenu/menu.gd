extends Control

@onready var video_intro: VideoStreamPlayer = $VideoIntro
@onready var video_loop: VideoStreamPlayer = $VideoLoop

@export var fade_duration: float = 0.5
@export var crossfade_enabled: bool = true

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	
	# Adatta entrambi i video a tutto lo schermo con taglio proporzionale
	var viewport_size = get_viewport().get_visible_rect().size
	
	video_intro.set_anchors_preset(Control.PRESET_FULL_RECT)
	video_intro.position = Vector2.ZERO
	video_intro.size = viewport_size
	video_intro.expand = true
	
	video_loop.set_anchors_preset(Control.PRESET_FULL_RECT)
	video_loop.position = Vector2.ZERO
	video_loop.size = viewport_size
	video_loop.expand = true

	video_intro.modulate.a = 0.0
	video_intro.loop = false

	video_loop.visible = false
	video_loop.modulate.a = 0.0
	video_loop.loop = true
	video_loop.stream_position = 0.0

	_fade_in(video_intro)
	video_intro.finished.connect(_on_intro_finished)
	video_intro.play()

func _on_intro_finished() -> void:
	if crossfade_enabled:
		_crossfade_to_loop()
	else:
		_fade_to_loop()

func _crossfade_to_loop() -> void:
	video_loop.visible = true
	video_loop.play()

	var tween_in := create_tween().set_parallel(true)
	tween_in.tween_property(video_loop, "modulate:a", 1.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_in.tween_property(video_intro, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween_in.finished
	video_intro.visible = false

func _fade_to_loop() -> void:
	await _fade_out(video_intro)
	video_intro.visible = false

	video_loop.visible = true
	video_loop.play()
	await _fade_in(video_loop)

func _fade_in(video: VideoStreamPlayer) -> void:
	var tween := create_tween()
	tween.tween_property(video, "modulate:a", 1.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

func _fade_out(video: VideoStreamPlayer) -> void:
	var tween := create_tween()
	tween.tween_property(video, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished

func exit_loop() -> void:
	await _fade_out(video_loop)
	video_loop.stop()

	video_intro.stream_position = 0.0
	video_intro.visible = true
	video_intro.volume_db = 0
	video_intro.play()
	await _fade_in(video_intro)

func set_fade_speed(speed: float) -> void:
	fade_duration = clamp(speed, 0.1, 3.0)

func pause_with_fade() -> void:
	var active_video := video_loop if video_loop.visible else video_intro
	await _fade_out(active_video)
	active_video.paused = true

func resume_with_fade() -> void:
	var active_video := video_loop if video_loop.visible else video_intro
	active_video.paused = false
	await _fade_in(active_video)
