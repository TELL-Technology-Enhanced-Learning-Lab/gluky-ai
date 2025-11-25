extends Area3D

@export var target_scene: PackedScene

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		load_target_scene()

func load_target_scene():
	if target_scene == null:
		return
	
	var loading_screen = create_loading_screen()
	get_tree().get_root().add_child(loading_screen)
	
	await get_tree().create_timer(0.5).timeout
	
	get_tree().change_scene_to_packed(target_scene)
	loading_screen.queue_free()

func create_loading_screen():
	var canvas_layer = CanvasLayer.new()
	
	var panel = ColorRect.new()
	panel.color = Color.BLACK
	panel.size = get_viewport().get_visible_rect().size
	
	var center_container = CenterContainer.new()
	center_container.size = panel.size
	
	var vbox = VBoxContainer.new()
	
	var label = Label.new()
	label.text = "LOADING..."
	label.add_theme_font_size_override("font_size", 32)
	
	var progress_bar = ProgressBar.new()
	progress_bar.size.x = 200
	progress_bar.show_percentage = false
	
	vbox.add_child(label)
	vbox.add_child(progress_bar)
	center_container.add_child(vbox)
	panel.add_child(center_container)
	canvas_layer.add_child(panel)
	
	return canvas_layer
