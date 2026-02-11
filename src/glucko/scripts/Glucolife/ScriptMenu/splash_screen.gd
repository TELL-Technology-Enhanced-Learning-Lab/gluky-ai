extends Control

# Riferimento all'immagine
@onready var splash_image: TextureRect = $Background
@export var preferred_orientation := OrientationManager.OrientationMode.LANDSCAPE


# Configurazione
@export var auto_transition_delay: float = 3.0  # Tempo totale prima di cambiare scena
@export var transition_duration: float = 1.0
@export_file("*.tscn") var next_scene: String = "res://scenes/MenuGlucoLife/Menu.tscn"

# Overlay per transizione
var transition_overlay: ColorRect

func _ready() -> void:
	_create_transition_overlay()
	start_splash_animation()

# ======================
# Setup overlay nero
# ======================
func _create_transition_overlay() -> void:
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color.BLACK
	transition_overlay.modulate.a = 0.0
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(transition_overlay)
	move_child(transition_overlay, get_child_count() - 1)  # In cima a tutto

# ======================
# ✨ ANIMAZIONE SPLASH
# ======================
func start_splash_animation() -> void:
	# Setup iniziale
	splash_image.modulate.a = 0.0
	splash_image.scale = Vector2(0.8, 0.8)
	splash_image.pivot_offset = splash_image.size / 2  # Centra il pivot
	
	var anim := create_tween()
	anim.set_parallel(true)
	
	# FADE IN + ZOOM
	anim.tween_property(
		splash_image,
		"modulate:a",
		1.0,
		0.8
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	anim.tween_property(
		splash_image,
		"scale",
		Vector2(1.0, 1.0),
		1.0
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await anim.finished
	
	# IDLE ANIMATION (respiro + leggera rotazione)
	start_idle_breathing()
	
	# Attendi e poi passa al menu
	await get_tree().create_timer(auto_transition_delay).timeout
	transition_to_menu()

# ======================
# Animazione idle (respiro)
# ======================
func start_idle_breathing() -> void:
	var idle := create_tween()
	idle.set_loops()
	idle.set_trans(Tween.TRANS_SINE)
	idle.set_ease(Tween.EASE_IN_OUT)
	
	# Respiro lento
	idle.tween_property(
		splash_image,
		"scale",
		Vector2(1.03, 1.03),
		2.0
	)
	idle.tween_property(
		splash_image,
		"scale",
		Vector2(1.0, 1.0),
		2.0
	)

# ======================
# ✨ TRANSIZIONE AL MENU
# ======================
func transition_to_menu() -> void:
	# Blocca input
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var trans := create_tween()
	trans.set_parallel(true)
	
	# Zoom + fade out immagine
	trans.tween_property(
		splash_image,
		"scale",
		Vector2(1.2, 1.2),
		transition_duration * 0.7
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	trans.tween_property(
		splash_image,
		"modulate:a",
		0.0,
		transition_duration * 0.6
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Fade to black
	trans.tween_property(
		transition_overlay,
		"modulate:a",
		1.0,
		transition_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	await trans.finished
	
	# Cambia scena
	get_tree().change_scene_to_file(next_scene)

# ======================
# ✨ SKIP con qualsiasi input
# ======================
func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed() and not event.is_echo():
			# Skippa solo se l'immagine è ancora visibile
			if splash_image.modulate.a > 0.5:
				transition_to_menu()
