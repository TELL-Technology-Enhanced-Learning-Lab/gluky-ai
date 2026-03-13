extends CanvasLayer

@onready var glucose_bar = $GlucoseUI
@onready var insulin_counter = $InsulinCounter

func _ready():
	glucose_bar.visible = true
	insulin_counter.visible = true

func get_glucose_bar():
	return glucose_bar

func get_insulin_counter():
	return insulin_counter

func _on_btn_exit_pressed() -> void:
	var nodes_to_remove = []
	
	var collect_nodes = func(collection_root):
		var stack = [collection_root]
		while stack.size() > 0:
			var current = stack.pop_back()
			if current.name.to_lower().find("mobile") != -1 or \
			   current.name.to_lower().find("controls") != -1 or \
			   (current is Control and current.visible and current.has_method("_on_joystick_pressed")):
				nodes_to_remove.append(current)
			
			for child in current.get_children():
				stack.append(child)
	
	collect_nodes.call(get_tree().root)
	
	for node in nodes_to_remove:
		if is_instance_valid(node) and node != self:
			node.queue_free()
	
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/menus/glucky/Minigame_Selection.tscn")
