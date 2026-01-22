extends Node

var is_glucolife_active = false
var last_update_time = 0

var glucose_level = 100.0
var energy_level = 100.0
var hygiene_level = 100.0
var happiness_level = 100.0

const GLUCOSE_DECAY_PER_HOUR = 15.0
const ENERGY_DECAY_PER_HOUR = 12.0
const HYGIENE_DECAY_PER_HOUR = 8.0
const HAPPINESS_DECAY_PER_HOUR = 5.0

func enter_glucolife():
	if not is_glucolife_active:
		is_glucolife_active = true
		_load_data()
		_calculate_offline_changes()
		_start_update_timer()

func exit_glucolife():
	if is_glucolife_active:
		is_glucolife_active = false
		_stop_update_timer()
		_save_data()

func update_glucose(amount):
	if is_glucolife_active:
		glucose_level = clamp(glucose_level + amount, 0, 100)
		_save_data()

func update_energy(amount):
	if is_glucolife_active:
		energy_level = clamp(energy_level + amount, 0, 100)
		_save_data()

func update_hygiene(amount):
	if is_glucolife_active:
		hygiene_level = clamp(hygiene_level + amount, 0, 100)
		_save_data()

func update_happiness(amount):
	if is_glucolife_active:
		happiness_level = clamp(happiness_level + amount, 0, 100)
		_save_data()

func get_stats():
	if is_glucolife_active:
		return {
			"glucose": glucose_level,
			"energy": energy_level,
			"hygiene": hygiene_level,
			"happiness": happiness_level
		}
	else:
		return {
			"glucose": 100.0,
			"energy": 100.0,
			"hygiene": 100.0,
			"happiness": 100.0
		}

func _load_data():
	if FileAccess.file_exists("user://glucolife_save.dat"):
		var file = FileAccess.open("user://glucolife_save.dat", FileAccess.READ)
		var save_data = file.get_var()
		
		glucose_level = save_data.get("glucose_level", 100.0)
		energy_level = save_data.get("energy_level", 100.0)
		hygiene_level = save_data.get("hygiene_level", 100.0)
		happiness_level = save_data.get("happiness_level", 100.0)
		last_update_time = save_data.get("last_update_time", Time.get_unix_time_from_system())

func _save_data():
	var save_data = {
		"glucose_level": glucose_level,
		"energy_level": energy_level,
		"hygiene_level": hygiene_level,
		"happiness_level": happiness_level,
		"last_update_time": Time.get_unix_time_from_system()
	}
	
	var file = FileAccess.open("user://glucolife_save.dat", FileAccess.WRITE)
	file.store_var(save_data)

func _calculate_offline_changes():
	var current_time = Time.get_unix_time_from_system()
	
	if last_update_time == 0:
		last_update_time = current_time
		return
	
	var seconds_passed = current_time - last_update_time
	var hours_passed = min(seconds_passed, 86400) / 3600.0
	
	if hours_passed > 0.1:
		glucose_level = max(0, glucose_level - (GLUCOSE_DECAY_PER_HOUR * hours_passed))
		energy_level = max(0, energy_level - (ENERGY_DECAY_PER_HOUR * hours_passed))
		hygiene_level = max(0, hygiene_level - (HYGIENE_DECAY_PER_HOUR * hours_passed))
		happiness_level = max(0, happiness_level - (HAPPINESS_DECAY_PER_HOUR * hours_passed))
	
	last_update_time = current_time

func _start_update_timer():
	var timer = Timer.new()
	timer.name = "UpdateTimer"
	timer.wait_time = 60.0
	timer.timeout.connect(_on_update_timer)
	add_child(timer)
	timer.start()

func _stop_update_timer():
	if has_node("UpdateTimer"):
		$UpdateTimer.stop()
		$UpdateTimer.queue_free()

func _on_update_timer():
	if is_glucolife_active:
		var minute_fraction = 1.0 / 60.0
		
		glucose_level = max(0, glucose_level - (GLUCOSE_DECAY_PER_HOUR * minute_fraction))
		energy_level = max(0, energy_level - (ENERGY_DECAY_PER_HOUR * minute_fraction))
		hygiene_level = max(0, hygiene_level - (HYGIENE_DECAY_PER_HOUR * minute_fraction))
		happiness_level = max(0, happiness_level - (HAPPINESS_DECAY_PER_HOUR * minute_fraction))
		
		if int(Time.get_unix_time_from_system()) % 300 < 60:
			_save_data()
