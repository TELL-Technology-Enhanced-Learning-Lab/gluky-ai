extends Marker3D

var current_food_instance: Node3D = null
var respawn_timer: Timer = null
var current_food_category: String = ""

func _ready():
	# Setup respawn timer
	respawn_timer = Timer.new()
	respawn_timer.wait_time = 30.0
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	add_child(respawn_timer)

	await get_tree().process_frame
	spawn_food()

func spawn_food():
	if current_food_instance != null:
		return

	var food_array: Array[PackedScene] = []

	if is_in_group("HealthyFood"):
		food_array = FoodDatabase.food_database.healthy_foods
		current_food_category = "HealthyFood"
	elif is_in_group("SugaryFood"):
		food_array = FoodDatabase.food_database.sugary_foods
		current_food_category = "SugaryFood"

	if food_array.is_empty():
		push_warning("No food assigned in singleton for category: " + current_food_category)
		return

	var random_index = randi() % food_array.size()
	var food_scene = food_array[random_index]

	if food_scene == null:
		push_error("Invalid food scene in singleton at index " + str(random_index))
		return

	current_food_instance = food_scene.instantiate()
	current_food_instance.add_to_group(current_food_category)

	if not is_inside_tree():
		await tree_entered

	if not get_parent():
		push_error("Food spawner has no parent!")
		return

	get_parent().call_deferred("add_child", current_food_instance)
	await get_tree().process_frame

	if current_food_instance:
		current_food_instance.global_position = self.global_position

		var area3d = _find_area3d(current_food_instance)
		if area3d:
			area3d.body_entered.connect(_on_food_collected)
		else:
			push_warning("No Area3D found in food instance")

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
