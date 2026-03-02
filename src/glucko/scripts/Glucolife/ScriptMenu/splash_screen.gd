extends Control

@onready var splash_image: TextureRect = $Background

@export var auto_transition_delay: float = 3.0
@export var transition_duration: float = 1.0
@export_file("*.tscn") var next_scene: String = "res://scenes/menu_glucolife/Menu.tscn"

var transition_overlay: ColorRect

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	
	await get_tree().process_frame
	
	# Forza il nodo root a coprire tutto lo schermo
	self.anchor_left = 0
	self.anchor_top = 0
	self.anchor_right = 1
	self.anchor_bottom = 1
	self.offset_left = 0
	self.offset_top = 0
	self.offset_right = 0
	self.offset_bottom = 0
	
	# Forza immagine a coprire tutto
	splash_image.anchor_left = 0
	splash_image.anchor_top = 0
	splash_image.anchor_right = 1
	splash_image.anchor_bottom = 1
	splash_image.offset_left = 0
	splash_image.offset_top = 0
	splash_image.offset_right = 0
	splash_image.offset_bottom = 0
	splash_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	splash_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	splash_image.scale = Vector2(1.0, 1.0)
	splash_image.pivot_offset = Vector2.ZERO
	
	_create_transition_overlay()
	await get_tree().process_frame
	start_splash_animation()

func _create_transition_overlay() -> void:
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color.BLACK
	transition_overlay.modulate.a = 0.0
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.anchor_left = 0
	transition_overlay.anchor_top = 0
	transition_overlay.anchor_right = 1
	transition_overlay.anchor_bottom = 1
	transition_overlay.offset_left = 0
	transition_overlay.offset_top = 0
	transition_overlay.offset_right = 0
	transition_overlay.offset_bottom = 0
	add_child(transition_overlay)
	move_child(transition_overlay, get_child_count() - 1)

func start_splash_animation() -> void:
	splash_image.modulate.a = 0.0
	
	var anim := create_tween()
	anim.tween_property(splash_image, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await anim.finished
	
	start_idle_breathing()
	await get_tree().create_timer(auto_transition_delay).timeout
	transition_to_menu()

func start_idle_breathing() -> void:
	var idle := create_tween()
	idle.set_loops()
	idle.set_trans(Tween.TRANS_SINE)
	idle.set_ease(Tween.EASE_IN_OUT)
	idle.tween_property(splash_image, "modulate:a", 0.92, 2.0)
	idle.tween_property(splash_image, "modulate:a", 1.0, 2.0)

func transition_to_menu() -> void:
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var trans := create_tween()
	trans.set_parallel(true)
	trans.tween_property(splash_image, "modulate:a", 0.0, transition_duration * 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	trans.tween_property(transition_overlay, "modulate:a", 1.0, transition_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await trans.finished

	get_tree().change_scene_to_file(next_scene)

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed() and not event.is_echo():
			if splash_image.modulate.a > 0.5:
				transition_to_menu()
