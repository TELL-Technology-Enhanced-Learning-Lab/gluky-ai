extends Node2D

class_name MenuTutorialSystem

@onready var tut_selection: Button = $TutSelection
@onready var back_button: Button = $BackButton
@onready var tut_glucorun: Button = get_node("TutGlucorun")
@onready var glucorun_button: Button = get_node("TutGlucolife")
@onready var main_selection: Node2D = get_node("../Main Selection")
@onready var selection_button: Button = get_node("../Main Selection/Selection")

var camera_node: Camera3D = null
var is_menu_active: bool = false
var current_camera_position: int = 1
var library_signal_used: bool = false

var book_menu_controller: BookMenuController = null

signal menu_shown(menu_type: String)
signal menu_closed(menu_type: String)
signal glucorun_selected()
signal camera_return_requested()

enum MenuState {
	CLOSED = -1,
	INITIAL = 0,
	TUTORIALS_MAIN = 1,
	GLUCORUN_SELECTION = 2
}
var current_menu_state: int = MenuState.CLOSED

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	if selection_button:
		selection_button.pressed.connect(_on_selection_button_pressed)
	if tut_selection:
		tut_selection.pressed.connect(_on_tut_selection_pressed)
	if glucorun_button:
		glucorun_button.pressed.connect(_on_glucorun_selected)
	
	_hide_all_tutorial_ui()
	_find_and_connect_camera()
	_find_book_controller()

func _find_book_controller():
	var controllers = get_tree().get_nodes_in_group("book_controller")
	if controllers.size() > 0:
		book_menu_controller = controllers[0] as BookMenuController
	if not book_menu_controller:
		book_menu_controller = get_node("../BookMenuController") as BookMenuController

func _find_and_connect_camera() -> void:
	await get_tree().process_frame
	var cameras = get_tree().get_nodes_in_group("main_camera")
	if cameras.size() > 0:
		var camera = cameras[0] as Camera3D
		if camera:
			set_camera_node(camera)

func _hide_all_tutorial_ui() -> void:
	if tut_selection:
		tut_selection.visible = false
		tut_selection.modulate = Color(1, 1, 1, 0)
		tut_selection.disabled = true
	if back_button:
		back_button.visible = false
		back_button.modulate = Color(1, 1, 1, 0)
		back_button.disabled = true
	if tut_glucorun:
		tut_glucorun.visible = false
		tut_glucorun.modulate = Color(1, 1, 1, 0)
		tut_glucorun.disabled = true
	if glucorun_button:
		glucorun_button.visible = false
		glucorun_button.modulate = Color(1, 1, 1, 0)
		glucorun_button.disabled = true

func _check_camera_position() -> void:
	if current_camera_position == 1:
		if selection_button:
			selection_button.visible = true
			selection_button.disabled = false
			if not is_menu_active:
				selection_button.text = "Library"
			if main_selection:
				main_selection.visible = true
	else:
		if selection_button:
			selection_button.visible = false
			selection_button.disabled = true
		if main_selection:
			main_selection.visible = false
		
		if is_menu_active:
			_close_menu()

func _show_menu_element(element: Node, duration: float = 0.3) -> void:
	if not element or not is_instance_valid(element):
		return
	element.visible = true
	if element is Control:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(element, "modulate", Color(1, 1, 1, 1), duration)

func _hide_menu_element(element: Node, duration: float = 0.3) -> void:
	if not element or not is_instance_valid(element):
		return
	if element == selection_button or element == main_selection:
		return
	if element is Control:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(element, "modulate", Color(1, 1, 1, 0), duration)
		await tween.finished
		element.visible = false
		element.disabled = true
	elif element is Node2D:
		element.visible = false

func _on_selection_button_pressed() -> void:
	if current_camera_position == 2:
		selection_button.visible = false
		selection_button.disabled = true
		if main_selection:
			main_selection.visible = false
		_close_menu()
		return
	
	if current_camera_position != 1:
		return
	
	if is_menu_active:
		_close_menu()
		return
	
	if not library_signal_used:
		return
	
	_open_menu()

func _open_menu():
	if not is_menu_active and current_camera_position == 1:
		is_menu_active = true
		current_menu_state = MenuState.INITIAL
		
		if selection_button:
			selection_button.text = "Back"
		
		_apply_menu_state()
		
		library_signal_used = false
		menu_shown.emit("library_menu")

func show_library_menu_from_zoom() -> void:
	if current_camera_position != 1:
		return
	
	is_menu_active = true
	current_menu_state = MenuState.INITIAL
	
	if selection_button:
		selection_button.text = "Back"
	
	_apply_menu_state()
	
	library_signal_used = false
	menu_shown.emit("library_menu")

func _close_menu():
	await _hide_all_menu_elements()
	current_menu_state = MenuState.CLOSED
	is_menu_active = false
	
	if selection_button:
		selection_button.text = "Library"
		selection_button.visible = true
		selection_button.disabled = false
	
	if main_selection:
		main_selection.visible = true
	
	if camera_node and camera_node.has_method("_enable_swipe_input"):
		camera_node._enable_swipe_input()
	
	camera_return_requested.emit()
	
	if book_menu_controller:
		book_menu_controller.reset_to_main_menu()
	
	menu_closed.emit("all")

func _hide_all_menu_elements() -> void:
	if tut_selection:
		await _hide_menu_element(tut_selection)
		tut_selection.disabled = true
	if back_button:
		await _hide_menu_element(back_button)
		back_button.disabled = true
	if tut_glucorun:
		await _hide_menu_element(tut_glucorun)
		tut_glucorun.disabled = true
	if glucorun_button:
		await _hide_menu_element(glucorun_button)
		glucorun_button.disabled = true

func _apply_menu_state():
	if current_menu_state == MenuState.CLOSED:
		return
	
	match current_menu_state:
		MenuState.INITIAL:
			if tut_selection:
				_show_menu_element(tut_selection)
				tut_selection.disabled = false
			
			if tut_glucorun:
				tut_glucorun.visible = false
				tut_glucorun.modulate = Color(1, 1, 1, 0)
				tut_glucorun.disabled = true
			if glucorun_button:
				glucorun_button.visible = false
				glucorun_button.modulate = Color(1, 1, 1, 0)
				glucorun_button.disabled = true
			if back_button:
				back_button.visible = false
				back_button.modulate = Color(1, 1, 1, 0)
				back_button.disabled = true
		
		MenuState.TUTORIALS_MAIN:
			if tut_selection:
				tut_selection.modulate = Color(1, 1, 1, 0)
				tut_selection.disabled = true
			
			if back_button:
				_show_menu_element(back_button)
				back_button.disabled = false
			if tut_glucorun:
				_show_menu_element(tut_glucorun)
				tut_glucorun.disabled = false
			if glucorun_button:
				_show_menu_element(glucorun_button)
				glucorun_button.disabled = false
		
		MenuState.GLUCORUN_SELECTION:
			if tut_selection:
				tut_selection.modulate = Color(1, 1, 1, 0)
				tut_selection.disabled = true
			
			if back_button:
				_show_menu_element(back_button)
				back_button.disabled = false
			if tut_glucorun:
				_show_menu_element(tut_glucorun)
				tut_glucorun.disabled = false
			if glucorun_button:
				_show_menu_element(glucorun_button)
				glucorun_button.disabled = false

func _on_back_button_pressed() -> void:
	if current_menu_state > MenuState.INITIAL:
		current_menu_state -= 1
		_apply_menu_state()
	else:
		_close_menu()

func _on_tut_selection_pressed() -> void:
	current_menu_state = MenuState.TUTORIALS_MAIN
	_apply_menu_state()
	menu_shown.emit("glucorun_menu")

func _on_glucorun_selected() -> void:
	current_menu_state = MenuState.CLOSED
	is_menu_active = false
	
	if selection_button:
		selection_button.text = "Library"
	
	await _hide_all_menu_elements()
	
	if camera_node and camera_node.has_method("_enable_swipe_input"):
		camera_node._enable_swipe_input()
	
	_check_camera_position()
	
	glucorun_selected.emit()
	menu_closed.emit("all")

func set_camera_node(camera: Camera3D) -> void:
	camera_node = camera
	if camera_node:
		if camera_node.has_signal("library_focused"):
			if not camera_node.library_focused.is_connected(_on_library_focused):
				camera_node.library_focused.connect(_on_library_focused)
		if camera_node.has_signal("camera_movement_finished"):
			if not camera_node.camera_movement_finished.is_connected(_on_camera_movement_finished):
				camera_node.camera_movement_finished.connect(_on_camera_movement_finished)

func _on_library_focused():
	library_signal_used = true

func _on_camera_movement_finished(target_position: int):
	current_camera_position = target_position
	if target_position == 1:
		_check_camera_position()
		if library_signal_used and not is_menu_active:
			await get_tree().create_timer(0.3).timeout
			_open_menu()
		else:
			is_menu_active = false
			current_menu_state = MenuState.CLOSED
			if selection_button:
				selection_button.text = "Library"
			if main_selection:
				main_selection.visible = true
	else:
		_close_menu()

func hide_all_menus() -> void:
	await _hide_all_menu_elements()
	current_menu_state = MenuState.CLOSED
	is_menu_active = false
	library_signal_used = false
	if selection_button:
		selection_button.text = "Library"

func _exit_tree() -> void:
	if camera_node:
		if camera_node.has_signal("library_focused"):
			if camera_node.library_focused.is_connected(_on_library_focused):
				camera_node.library_focused.disconnect(_on_library_focused)
		if camera_node.has_signal("camera_movement_finished"):
			if camera_node.camera_movement_finished.is_connected(_on_camera_movement_finished):
				camera_node.camera_movement_finished.disconnect(_on_camera_movement_finished)
