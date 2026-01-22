extends Control

@onready var video_intro: VideoStreamPlayer = $VideoIntro
@onready var video_loop: VideoStreamPlayer = $VideoLoop

# Durata delle transizioni in secondi
@export var fade_duration: float = 0.5
@export var crossfade_enabled: bool = true

func _ready() -> void:
	# Configura video intro
	video_intro.modulate.a = 0.0  # Inizia trasparente
	video_intro.loop = false
	
	# Configura video loop
	video_loop.visible = false
	video_loop.modulate.a = 0.0
	video_loop.loop = true
	
	# Precarica il video loop per evitare lag
	video_loop.stream_position = 0.0
	
	# Fade in dell'intro
	_fade_in(video_intro)
	
	# Avvia intro
	video_intro.finished.connect(_on_intro_finished)
	video_intro.play()

func _on_intro_finished() -> void:
	if crossfade_enabled:
		_crossfade_to_loop()
	else:
		_fade_to_loop()

# Transizione con crossfade (sovrappone i video)
func _crossfade_to_loop() -> void:
	video_loop.visible = true
	video_loop.play()
	
	# Fade in del loop
	var tween_in := create_tween().set_parallel(true)
	tween_in.tween_property(video_loop, "modulate:a", 1.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Fade out dell'intro
	tween_in.tween_property(video_intro, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Dopo il fade, nascondi l'intro
	await tween_in.finished
	video_intro.visible = false

# Transizione semplice con fade
func _fade_to_loop() -> void:
	# Fade out intro
	await _fade_out(video_intro)
	video_intro.visible = false
	
	# Mostra e fade in loop
	video_loop.visible = true
	video_loop.play()
	await _fade_in(video_loop)

# Funzione helper per fade in
func _fade_in(video: VideoStreamPlayer) -> void:
	var tween := create_tween()
	tween.tween_property(video, "modulate:a", 1.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

# Funzione helper per fade out
func _fade_out(video: VideoStreamPlayer) -> void:
	var tween := create_tween()
	tween.tween_property(video, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished

# Esci dal loop con animazione
func exit_loop() -> void:
	# Fade out del loop
	await _fade_out(video_loop)
	video_loop.stop()
	
	# Ripristina intro
	video_intro.stream_position = 0.0
	video_intro.visible = true
	video_intro.volume_db = 0
	
	# Fade in intro
	video_intro.play()
	await _fade_in(video_intro)

# Bonus: Funzione per cambiare velocità del fade
func set_fade_speed(speed: float) -> void:
	fade_duration = clamp(speed, 0.1, 3.0)

# Bonus: Pausa con animazione
func pause_with_fade() -> void:
	var active_video := video_loop if video_loop.visible else video_intro
	await _fade_out(active_video)
	active_video.paused = true

# Bonus: Riprendi con animazione
func resume_with_fade() -> void:
	var active_video := video_loop if video_loop.visible else video_intro
	active_video.paused = false
	await _fade_in(active_video)
