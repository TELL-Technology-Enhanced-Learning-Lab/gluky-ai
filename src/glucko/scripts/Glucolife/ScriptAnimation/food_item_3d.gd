extends Node3D

signal food_selected

var is_hovered := false

func _ready():
	var area = Area3D.new()
	add_child(area)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.6, 0.6, 0.6)
	col.shape = shape
	area.add_child(col)

	area.input_ray_pickable = true
	area.input_event.connect(_on_input_event)
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)

func _on_input_event(_cam, event, _pos, _normal, _idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		food_selected.emit()

func _on_mouse_entered():
	create_tween().tween_property(self, "scale", scale * 1.2, 0.15)

func _on_mouse_exited():
	create_tween().tween_property(self, "scale", scale / 1.2, 0.15)
