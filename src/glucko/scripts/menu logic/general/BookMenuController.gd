class_name BookMenuController
extends Node

@onready var book_node: Node3D
@onready var page_ui_container: Control = null
@onready var current_menu_depth: int = 0
@onready var camera_node: Camera3D = null

func _ready():
	var books = get_tree().get_nodes_in_group("book")
	if books.size() > 0:
		book_node = books[0]
		book_node.visible = false
	
	camera_node = get_tree().get_first_node_in_group("main_camera")
	if camera_node:
		camera_node.player_camera_movement.connect(_on_camera_moved)
		camera_node.camera_ready_for_book.connect(_on_camera_ready_for_book)
		camera_node.book_should_hide.connect(_on_book_should_hide)
		camera_node.camera_movement_finished.connect(_on_camera_movement_finished)

func _on_camera_ready_for_book():
	if book_node:
		book_node.visible = true
		_position_book_for_camera()
		reset_to_main_menu()

func _on_book_should_hide():
	if book_node:
		book_node.visible = false
	if page_ui_container:
		page_ui_container.hide()

func _position_book_for_camera():
	if not book_node or not camera_node:
		return
	var camera_pos = camera_node.global_position
	var camera_forward = -camera_node.global_transform.basis.z.normalized()
	var book_distance = 1.5
	var book_height_offset = -0.3
	var book_position = camera_pos + camera_forward * book_distance
	book_position.y += book_height_offset
	book_node.global_position = book_position
	book_node.look_at(camera_pos)
	book_node.rotate_object_local(Vector3(0, 1, 0), PI)

func _on_camera_moved(target_position: int):
	if target_position != 1:
		if page_ui_container:
			page_ui_container.hide()
		if book_node:
			book_node.visible = false

func _on_camera_movement_finished(target_position: int):
	if target_position == 1:
		if book_node:
			book_node.visible = true
			await get_tree().create_timer(0.1).timeout
			_position_book_for_camera()
		reset_to_main_menu()

func reset_to_main_menu():
	current_menu_depth = 0
	if page_ui_container:
		page_ui_container.show()
		_update_page_display()
	if book_node and book_node.has_method("_reset_to_first_page"):
		book_node._reset_to_first_page()

func go_deeper():
	current_menu_depth += 1
	if book_node and book_node.has_method("turn_right"):
		book_node.turn_right()
	_update_page_display()
	if book_node and book_node.has_method("play_page_turn_sound"):
		book_node.play_page_turn_sound()

func go_back():
	if current_menu_depth > 0:
		current_menu_depth -= 1
		if book_node and book_node.has_method("turn_left"):
			book_node.turn_left()
		_update_page_display()
		if book_node and book_node.has_method("play_page_turn_sound"):
			book_node.play_page_turn_sound()

func _update_page_display():
	if not page_ui_container:
		return
	match current_menu_depth:
		0:
			_show_main_menu_pages()
		1:
			_show_book_selection_pages()
		2:
			_show_chapter_selection_pages()
		_:
			_show_main_menu_pages()

func _show_main_menu_pages():
	for child in page_ui_container.get_children():
		child.queue_free()
	var page_scene = load("res://Page.tscn") if ResourceLoader.exists("res://Page.tscn") else null
	if page_scene:
		var page1 = page_scene.instantiate()
		if page1.has_method("set_number"):
			page1.set_number("Library")
		page_ui_container.add_child(page1)
		var page2 = page_scene.instantiate()
		if page2.has_method("set_number"):
			page2.set_number("Select a Book")
		page_ui_container.add_child(page2)

func _show_book_selection_pages():
	for child in page_ui_container.get_children():
		child.queue_free()
	var page_scene = load("res://Page.tscn") if ResourceLoader.exists("res://Page.tscn") else null
	if page_scene:
		var books = ["Book 1", "Book 2", "Book 3", "Book 4"]
		for i in range(min(books.size(), 4)):
			var page = page_scene.instantiate()
			if page.has_method("set_number"):
				page.set_number(books[i])
			page_ui_container.add_child(page)

func _show_chapter_selection_pages():
	for child in page_ui_container.get_children():
		child.queue_free()
	var page_scene = load("res://Page.tscn") if ResourceLoader.exists("res://Page.tscn") else null
	if page_scene:
		for i in range(1, 5):
			var page = page_scene.instantiate()
			if page.has_method("set_number"):
				page.set_number("Chapter " + str(i))
			page_ui_container.add_child(page)
