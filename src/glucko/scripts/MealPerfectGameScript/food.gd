extends StaticBody3D
class_name food

var original_scale: Vector3 = Vector3.ONE

@export var food_category: String = "food generic"
@export var indice_glicemico: float = 50
@export var carbs: float = 10
@export var prot: float = 10
@export var fat: float = 10
@export_multiline var nutrizione_info: String = ""

var food_mesh_parent: Node3D = null
var main_mesh: MeshInstance3D = null
var outlineMesh: MeshInstance3D = null
var collision_shape: CollisionShape3D = null

var selected: bool = false
var outlineWidth: float = 0.05
var player: Node = null

var original_marker: Node3D = null
var last_marker: Node3D = null

func _ready() -> void:
	# Aggiunge il gruppo food per il rilevamento da parte del player (mobile e desktop)
	add_to_group("food")
	original_scale = scale
	original_marker = get_parent()
	last_marker = original_marker

	player = get_tree().get_first_node_in_group("player")
	if player and player.has_signal("interact_object"):
		player.interact_object.connect(_set_selected)

	food_mesh_parent = get_node_or_null("FoodMesh")
	if food_mesh_parent == null:
		food_mesh_parent = get_first_child_node3d()

	var meshes := find_all_meshes(self)
	if meshes.size() >= 1:
		main_mesh = meshes[0]
	if meshes.size() >= 2:
		outlineMesh = meshes[1]
		outlineMesh.visible = false

	collision_shape = find_collision_shape(self)

func find_all_meshes(node: Node) -> Array:
	var result: Array = []
	if node is MeshInstance3D:
		result.append(node)
	for c in node.get_children():
		result += find_all_meshes(c)
	return result

func find_collision_shape(node: Node) -> CollisionShape3D:
	if node is CollisionShape3D:
		return node
	for child in node.get_children():
		var found := find_collision_shape(child)
		if found:
			return found
	return null

func get_first_child_node3d() -> Node3D:
	for c in get_children():
		if c is Node3D:
			return c
	return self as Node3D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and selected and player:
		if player.has_method("pick_up_object"):
			player.pick_up_object(self)

func _process(_delta: float) -> void:
	if collision_shape:
		collision_shape.disabled = (get_parent() and get_parent().name == "ObjectMarker3D")

	if outlineMesh:
		outlineMesh.visible = selected and not (get_parent() and get_parent().name == "ObjectMarker3D")

	if food_mesh_parent:
		food_mesh_parent.position.y = outlineWidth if selected else 0.0

func _set_selected(obj: Node) -> void:
	selected = (obj == self)

func on_dropped() -> void:
	if collision_shape:
		collision_shape.disabled = false

func snap_to_marker(marker: Node3D):
	if get_parent():
		get_parent().remove_child(self)
	marker.add_child(self, false)
	transform = Transform3D()
	global_transform = marker.global_transform
	scale = original_scale
	if collision_shape:
		collision_shape.disabled = false
	last_marker = marker
