extends StaticBody3D
class_name store_food
@onready var objectsPlaced: Node3D = $OggettiPosati
# mapping tra marker e cibo assegnato
var marker_to_food: Dictionary = {}
var itemsPlaced: Array = []
func _ready() -> void:
	itemsPlaced.resize(objectsPlaced.get_child_count())
	# inizializza marker e figli
	for slot in objectsPlaced.get_children():
		if slot.get_child_count() > 0:
			var cibo = slot.get_child(0)
			itemsPlaced[objectsPlaced.get_children().find(slot)] = cibo
			marker_to_food[slot.name] = cibo
			if cibo.has_method("snap_to_marker"):
				cibo.last_marker = slot
		else:
			itemsPlaced[objectsPlaced.get_children().find(slot)] = null
	add_to_group("table")
	for slot in objectsPlaced.get_children():
		slot.connect("tree_exiting", Callable(self, "_on_marker_child_exiting_tree"))
func add_object(object: Node3D, marker: Node3D = null) -> bool:
	var slot: Node3D = null
	# prova a piazzare l'oggetto sul marker assegnato dal nome
	for s in objectsPlaced.get_children():
		if marker_to_food.has(s.name) and marker_to_food[s.name] == object and s.get_child_count() == 0:
			slot = s
			break
	# fallback: usa marker passato se libero
	if slot == null and marker != null and marker.get_child_count() == 0 and marker.get_parent() == self:
		slot = marker
	# fallback: primo slot libero
	if slot == null:
		var free_index := itemsPlaced.find(null)
		if free_index != -1:
			slot = objectsPlaced.get_child(free_index)
		else:
			return false
	if object.get_parent():
		object.get_parent().remove_child(object)
	slot.add_child(object, false)
	object.transform = Transform3D()
	object.global_transform = slot.global_transform
	var orig_scale = object.get("original_scale")
	if orig_scale:
		object.scale = orig_scale
	var col := object.get_node_or_null("CollisionShape3D")
	if col:
		col.disabled = true
	var idx = objectsPlaced.get_children().find(slot)
	if idx != -1:
		itemsPlaced[idx] = object
	return true
func _on_marker_child_exiting_tree(node: Node) -> void: #per livello pranzo
	var idx := itemsPlaced.find(node)
	if idx != -1:
		itemsPlaced[idx] = null
