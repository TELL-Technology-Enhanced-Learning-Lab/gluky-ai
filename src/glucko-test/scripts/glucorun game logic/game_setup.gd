extends Node3D

signal glucose_bar_ready
signal ui_ready
signal game_over_triggered
signal glucose_updated(value: float)
signal glucose_bar_available(bar_node)

var game_ui = null
var glucose_bar = null
var game_over_active := false
var game_over_zone: Area3D = null

func _ready():
	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.size = get_viewport().get_visible_rect().size
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.modulate.a = 1.0
	
	get_tree().root.add_child.call_deferred(fade_rect)
	
	await get_tree().process_frame
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0)
	tween.finished.connect(fade_rect.queue_free)
	
	var ui_scene = load("res://art/user interface/GameUI.tscn")
	game_ui = ui_scene.instantiate() 
	get_tree().root.add_child(game_ui)
	
	game_over_zone = find_game_over_zone()
	
	glucose_bar = get_glucose_bar()
	if glucose_bar:
		if glucose_bar.has_signal("glucose_game_over"):
			glucose_bar.glucose_game_over.connect(_on_glucose_game_over)
		if glucose_bar.has_signal("glucose_updated"):
			glucose_bar.glucose_updated.connect(_on_glucose_bar_updated)
		emit_signal("glucose_bar_available", glucose_bar)
	
	emit_signal("glucose_bar_ready")
	emit_signal("ui_ready")

func _on_glucose_bar_updated(value: float):
	emit_signal("glucose_updated", value)

func find_game_over_zone() -> Area3D:
	var zones = get_tree().get_nodes_in_group("GameOverZone")
	if zones.size() > 0:
		return zones[0]
	return null

func _on_glucose_game_over():
	if game_over_active:
		return
	
	game_over_active = true
	emit_signal("game_over_triggered")
	fade_and_reload()

func fade_and_reload():
	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.size = get_viewport().get_visible_rect().size
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.modulate.a = 0
	
	get_tree().root.add_child(fade_rect)
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	if game_ui and game_ui.is_inside_tree():
		game_ui.queue_free()
		game_ui = null
	
	await get_tree().create_timer(0.3).timeout
	
	fade_rect.queue_free()
	get_tree().call_deferred("reload_current_scene")

func get_glucose_bar():
	if game_ui and game_ui.has_method("get_glucose_bar"):
		return game_ui.get_glucose_bar()
	return null

func get_insulin_counter():
	if game_ui and game_ui.has_method("get_insulin_counter"):
		return game_ui.get_insulin_counter()
	return null

func is_game_over_active() -> bool:
	return game_over_active

func trigger_game_over():
	if not game_over_active:
		_on_glucose_game_over()
