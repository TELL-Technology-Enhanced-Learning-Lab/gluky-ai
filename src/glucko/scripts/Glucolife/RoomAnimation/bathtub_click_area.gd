extends Area3D

signal bathtub_clicked

func _ready():
	input_ray_pickable = true
	monitoring = true
	monitorable = true
	
	collision_layer = 2
	collision_mask = 0
	
	input_event.connect(_on_input_event)
	
	print("✓ Bathtub click detector ready on: %s" % get_parent().name)

func _on_input_event(
	_camera: Node,
	event: InputEvent,
	event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("🛁 Bathtub clicked!")
			emit_signal("bathtub_clicked")
			
			show_click_feedback(event_position)

func show_click_feedback(click_position: Vector3):
	var click_marker = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.1
	click_marker.mesh = sphere
	
	get_parent().add_child(click_marker)
	click_marker.global_position = click_position
	
	var tween = create_tween()
	tween.tween_property(click_marker, "scale", Vector3(2, 2, 2), 0.3)
	tween.parallel().tween_property(click_marker, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	click_marker.queue_free()
