extends Control
class_name BaseStatusBar

@export var min_value := 0.0
@export var max_value := 100.0
@export var low_threshold := 30.0
@export var high_threshold := 70.0
@export var optimal_min := 40.0
@export var optimal_max := 60.0

var current_value := 0.0
var _is_connected := false

var progress_bar: ProgressBar
var label_value: Label

func _ready():
	_find_nodes()
	resized.connect(_refresh)
	_connect_to_glucolife()
	call_deferred("_force_update_from_glucolife")

func _enter_tree():
	_connect_to_glucolife()
	call_deferred("_force_update_from_glucolife")

func _exit_tree():
	if GlucolifeDataManager and GlucolifeDataManager.has_signal("stats_changed"):
		if GlucolifeDataManager.is_connected("stats_changed", _on_stats_changed):
			GlucolifeDataManager.stats_changed.disconnect(_on_stats_changed)

func _connect_to_glucolife():
	if _is_connected:
		return
		
	if not GlucolifeDataManager:
		await get_tree().process_frame
		_connect_to_glucolife()
		return
	
	if GlucolifeDataManager.has_signal("stats_changed"):
		if not GlucolifeDataManager.is_connected("stats_changed", _on_stats_changed):
			GlucolifeDataManager.stats_changed.connect(_on_stats_changed)
			_is_connected = true

func _force_update_from_glucolife():
	if not GlucolifeDataManager or not GlucolifeDataManager.has_method("get_stats"):
		await get_tree().process_frame
		_force_update_from_glucolife()
		return
	
	var stats = GlucolifeDataManager.get_stats()
	_on_stats_changed(stats)

func _get_stat_name_from_class() -> String:
	var class_name_string = name
	
	match class_name_string:
		"GlucoseBar":
			return "glucose"
		"EnergyBar":
			return "energy"
		"HygieneBar":
			return "hygiene"
		"HappinessBar":
			return "happiness"
	
	var script_path = get_script().resource_path.get_file()
	
	if "Glucose" in script_path:
		return "glucose"
	elif "Energy" in script_path:
		return "energy"
	elif "Hygiene" in script_path:
		return "hygiene"
	elif "Happiness" in script_path:
		return "happiness"
	
	return ""

func _on_stats_changed(stats: Dictionary):
	if not is_inside_tree():
		call_deferred("_on_stats_changed", stats)
		return
		
	var stat_name = _get_stat_name_from_class()
	if stat_name and stat_name in stats:
		set_value(stats[stat_name])

func _find_nodes():
	for child in get_children():
		if child is ProgressBar:
			progress_bar = child
		elif child is Label:
			label_value = child
	
	if not progress_bar:
		await get_tree().process_frame
		_find_nodes()

func set_value(value: float):
	current_value = clamp(value, min_value, max_value)
	_refresh()

func _refresh():
	if not progress_bar or not is_inside_tree():
		await get_tree().process_frame
		_refresh()
		return
	
	progress_bar.value = current_value
	_update_color()
	_update_label()

func _update_color():
	if not progress_bar:
		return
	
	var style = StyleBoxFlat.new()
	var color: Color
	
	if current_value <= low_threshold:
		color = Color(0.1, 0.4, 1.0)
	elif current_value >= high_threshold:
		color = Color(1.0, 0.2, 0.2)
	elif current_value >= optimal_min and current_value <= optimal_max:
		color = Color(0.2, 1.0, 0.3)
	else:
		color = Color(1.0, 0.8, 0.0)
	
	style.bg_color = color
	progress_bar.add_theme_stylebox_override("fill", style)

func _update_label():
	if label_value and is_instance_valid(label_value):
		label_value.text = str(round(current_value))
