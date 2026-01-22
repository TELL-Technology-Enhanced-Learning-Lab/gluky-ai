extends Node

var current_resolution: Vector2
var is_fullscreen: bool = false
var needs_update: bool = false

func _ready():
	update_resolution()
	get_tree().root.connect("size_changed", Callable(self, "_on_window_size_changed"))

func update_resolution():
	current_resolution = get_viewport().get_visible_rect().size
	is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	needs_update = true

func _on_window_size_changed():
	update_resolution()

func get_needs_update() -> bool:
	return needs_update

func clear_update_flag():
	needs_update = false
