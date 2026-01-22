extends Marker3D

@export_category("Food Spawner")
@export var healthy_foods: Array[PackedScene] = []:
	set(value):
		healthy_foods = value
	get:
		if healthy_foods.is_empty():
			healthy_foods = _load_foods_from_folder("res://special items/healthy foods/")
		return healthy_foods

@export var sugary_foods: Array[PackedScene] = []:
	set(value):
		sugary_foods = value
	get:
		if sugary_foods.is_empty():
			sugary_foods = _load_foods_from_folder("res://special items/sugary foods/")
		return sugary_foods

var current_food_instance: Node3D = null
var respawn_timer: Timer = null
var current_food_category: String = ""

func _ready():
	respawn_timer = Timer.new()
	respawn_timer.wait_time = 30.0
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	add_child(respawn_timer)

	call_deferred("spawn_food")

func _load_foods_from_folder(folder_path: String) -> Array[PackedScene]:
	var foods: Array[PackedScene] = []
	var dir = DirAccess.open(folder_path)
	
	if dir == null:
		push_error("Cannot open folder: " + folder_path)
		return foods
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tscn"):
			var scene_path = folder_path.path_join(file_name)
			var packed_scene = load(scene_path)
			if packed_scene is PackedScene:
				foods.append(packed_scene)
			else:
				push_error("Failed to load scene: " + scene_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	if foods.is_empty():
		push_warning("No valid .tscn files found in folder: " + folder_path)
	
	return foods

func spawn_food():
	if current_food_instance != null:
		return
	
	var food_array: Array[PackedScene]
	
	if is_in_group("HealthyFood"):
		food_array = healthy_foods
		current_food_category = "HealthyFood"
	elif is_in_group("SugaryFood"):
		food_array = sugary_foods
		current_food_category = "SugaryFood"

	if food_array.is_empty():
		return

	var random_index = randi() % food_array.size()
	var food_scene = food_array[random_index]
	
	if food_scene == null:
		push_error("Invalid food scene in array at index " + str(random_index))
		return

	current_food_instance = food_scene.instantiate()
	current_food_instance.add_to_group(current_food_category)
	
	get_parent().add_child(current_food_instance)
	current_food_instance.global_position = self.global_position
	
	var area3d = _find_area3d(current_food_instance)
	if area3d:
		area3d.body_entered.connect(_on_food_collected)

func _find_area3d(node: Node) -> Area3D:
	if node is Area3D:
		return node
	
	for child in node.get_children():
		var result = _find_area3d(child)
		if result:
			return result
	
	return null

func _on_food_collected(body: Node):
	if body.is_in_group("Player"):
		var food_data = get_food_data(current_food_instance)
		if food_data.is_empty():
			food_data["food_category"] = current_food_category
		
		body.handle_collision(current_food_instance, food_data)
		start_respawn_timer()

func get_food_data(food_instance: Node3D) -> Dictionary:
	var data = {}
	
	if food_instance.has_method("get_food_data"):
		data = food_instance.get_food_data()
	else:
		for child in food_instance.get_children():
			if child.has_method("get_food_data"):
				data = child.get_food_data()
				break
	
	if not data.has("food_category"):
		data["food_category"] = current_food_category
	
	return data

func start_respawn_timer():
	if current_food_instance != null:
		current_food_instance.queue_free()
		current_food_instance = null

	respawn_timer.start()

func _on_respawn_timer_timeout():
	spawn_food()
