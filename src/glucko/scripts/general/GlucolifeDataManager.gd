extends Node

signal stats_changed(stats)

var is_glucolife_active := false
var last_update_time := 0.0

var glucose_level := 0.0
var energy_level := 0.0
var hygiene_level := 0.0
var happiness_level := 0.0

const SAVE_PATH := "user://glucolife_save.dat"

const GLUCOSE_DECAY_PER_HOUR := 15.0
const ENERGY_DECAY_PER_HOUR := 12.0
const HYGIENE_DECAY_PER_HOUR := 8.0
const HAPPINESS_DECAY_PER_HOUR := 5.0


# ============================================================
# PUBLIC
# ============================================================

func enter_glucolife():
	if is_glucolife_active:
		return

	is_glucolife_active = true

	_load_data()
	_calculate_offline_changes()
	_start_update_timer()
	_emit_stats()

	print("[Glucolife] Entered.")


func exit_glucolife():
	if not is_glucolife_active:
		return

	is_glucolife_active = false
	_stop_update_timer()
	_save_data()

	print("[Glucolife] Exited & Saved.")


func update_glucose(amount: float):
	_modify_stat("glucose", amount)


func update_energy(amount: float):
	_modify_stat("energy", amount)


func update_hygiene(amount: float):
	_modify_stat("hygiene", amount)


func update_happiness(amount: float):
	_modify_stat("happiness", amount)


func get_stats() -> Dictionary:
	return {
		"glucose": glucose_level,
		"energy": energy_level,
		"hygiene": hygiene_level,
		"happiness": happiness_level
	}


# ============================================================
# INTERNAL STAT HANDLING
# ============================================================

func _modify_stat(stat_name: String, amount: float):
	if not is_glucolife_active:
		return

	match stat_name:
		"glucose":
			glucose_level = clamp(glucose_level + amount, 0.0, 100.0)
		"energy":
			energy_level = clamp(energy_level + amount, 0.0, 100.0)
		"hygiene":
			hygiene_level = clamp(hygiene_level + amount, 0.0, 100.0)
		"happiness":
			happiness_level = clamp(happiness_level + amount, 0.0, 100.0)

	_save_data()
	_emit_stats()


func _emit_stats():
	var stats := get_stats()
	print("[Glucolife] Emit Stats:", stats)
	emit_signal("stats_changed", stats)


# ============================================================
# SAVE / LOAD
# ============================================================

func _load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		glucose_level = 40.0
		energy_level = 60.0
		hygiene_level = 40.0
		happiness_level = 80.0

		last_update_time = Time.get_unix_time_from_system()

		_save_data()
		_emit_stats()

		print("[Glucolife] No save found. Initialized defaults.")
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var save_data = file.get_var()

	glucose_level = save_data.get("glucose_level", 40.0)
	energy_level = save_data.get("energy_level", 60.0)
	hygiene_level = save_data.get("hygiene_level", 40.0)
	happiness_level = save_data.get("happiness_level", 80.0)

	last_update_time = save_data.get(
		"last_update_time",
		Time.get_unix_time_from_system()
	)

	if last_update_time <= 0.0:
		last_update_time = Time.get_unix_time_from_system()

	print("[Glucolife] Save loaded.")
	print("Values:", get_stats())


func _save_data():
	var save_data := {
		"glucose_level": glucose_level,
		"energy_level": energy_level,
		"hygiene_level": hygiene_level,
		"happiness_level": happiness_level,
		"last_update_time": Time.get_unix_time_from_system()
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(save_data)


# ============================================================
# OFFLINE DECAY
# ============================================================

func _calculate_offline_changes():
	if last_update_time <= 0.0:
		last_update_time = Time.get_unix_time_from_system()
		return

	var current_time: float = Time.get_unix_time_from_system()
	var seconds_passed: float = current_time - last_update_time

	var capped_seconds: float = min(seconds_passed, 86400.0)
	var hours_passed: float = capped_seconds / 3600.0

	print("[Glucolife] Offline hours passed:", hours_passed)

	if hours_passed > 0.1:
		glucose_level = max(0.0, glucose_level - GLUCOSE_DECAY_PER_HOUR * hours_passed)
		energy_level = max(0.0, energy_level - ENERGY_DECAY_PER_HOUR * hours_passed)
		hygiene_level = max(0.0, hygiene_level - HYGIENE_DECAY_PER_HOUR * hours_passed)
		happiness_level = max(0.0, happiness_level - HAPPINESS_DECAY_PER_HOUR * hours_passed)

	last_update_time = current_time

# ============================================================
# TIMER
# ============================================================

func _start_update_timer():
	if has_node("UpdateTimer"):
		return

	var timer := Timer.new()
	timer.name = "UpdateTimer"
	timer.wait_time = 60.0
	timer.timeout.connect(_on_update_timer)

	add_child(timer)
	timer.start()


func _stop_update_timer():
	if has_node("UpdateTimer"):
		var timer := $UpdateTimer
		timer.stop()
		timer.queue_free()


func _on_update_timer():
	if not is_glucolife_active:
		return

	var minute_fraction := 1.0 / 60.0

	glucose_level = max(0.0, glucose_level - GLUCOSE_DECAY_PER_HOUR * minute_fraction)
	energy_level = max(0.0, energy_level - ENERGY_DECAY_PER_HOUR * minute_fraction)
	hygiene_level = max(0.0, hygiene_level - HYGIENE_DECAY_PER_HOUR * minute_fraction)
	happiness_level = max(0.0, happiness_level - HAPPINESS_DECAY_PER_HOUR * minute_fraction)

	var now := Time.get_unix_time_from_system()
	if int(now) % 300 < 60:
		_save_data()

	_emit_stats()
