extends Node3D

var glucose_bar
var glucose_value = 50

func _ready():
	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.size = get_viewport().get_visible_rect().size
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.modulate.a = 1.0
	
	get_tree().root.add_child(fade_rect)
	
	await get_tree().process_frame
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0)
	tween.finished.connect(fade_rect.queue_free)
	
	var ui_scene = load("res://art/user interface/Glucose_Bar.tscn")
	var ui_instance = ui_scene.instantiate()
	add_child(ui_instance)
	glucose_bar = ui_instance.get_node("CanvasLayer")

func update_value(new_value) -> void:
	glucose_value = new_value
	if glucose_bar and glucose_bar.has_method("update_bar"):
		glucose_bar.update_bar(glucose_value)
