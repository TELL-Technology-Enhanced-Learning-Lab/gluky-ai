extends Node

signal stats_changed(stats)

enum MealType {
	BREAKFAST,
	SNACK1,
	LUNCH,
	SNACK2,
	DINNER
}

class MealData:
	var type: MealType
	var glucose_change: float
	var energy_change: float
	var happiness_change: float
	var digestion_time: float
	var eaten_time: float
	var eaten_date: Dictionary  # {year, month, day}
	
	func _init(p_type: MealType, p_glucose: float, p_energy: float, p_happiness: float, p_digestion: float, p_time: float, p_date: Dictionary):
		type = p_type
		glucose_change = p_glucose
		energy_change = p_energy
		happiness_change = p_happiness
		digestion_time = p_digestion
		eaten_time = p_time
		eaten_date = p_date
	
	func is_digested(current_time: float) -> bool:
		var hours_passed = (current_time - eaten_time) / 3600.0
		return hours_passed >= digestion_time
	
	func get_remaining_effect(current_time: float) -> Dictionary:
		var hours_passed = (current_time - eaten_time) / 3600.0
		var remaining_factor = max(0.0, 1.0 - (hours_passed / digestion_time))
		
		return {
			"glucose": glucose_change * remaining_factor,
			"energy": energy_change * remaining_factor,
			"happiness": happiness_change * remaining_factor,
			"active": remaining_factor > 0
		}
	
	func is_same_day(other_date: Dictionary) -> bool:
		return (eaten_date.year == other_date.year and 
				eaten_date.month == other_date.month and 
				eaten_date.day == other_date.day)

var is_glucolife_active := false
var last_update_time := 0.0

var glucose_level := 0.0
var energy_level := 0.0
var hygiene_level := 0.0
var happiness_level := 0.0

var breakfast: MealData = null
var snack1: MealData = null
var lunch: MealData = null
var snack2: MealData = null
var dinner: MealData = null

const SAVE_PATH := "user://glucolife_save.dat"

const GLUCOSE_DECAY_PER_HOUR := 15.0
const ENERGY_DECAY_PER_HOUR := 12.0
const HYGIENE_DECAY_PER_HOUR := 8.0
const HAPPINESS_DECAY_PER_HOUR := 5.0

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

func add_meal(meal_type: MealType, glucose: float, energy: float, happiness: float, digestion_hours: float):
	if not is_glucolife_active:
		return false
	
	var current_time = Time.get_unix_time_from_system()
	var current_date = Time.get_date_dict_from_system()
	var meal_data = MealData.new(meal_type, glucose, energy, happiness, digestion_hours, current_time, current_date)
	
	match meal_type:
		MealType.BREAKFAST:
			if _can_override_meal(breakfast, current_date):
				breakfast = meal_data
				_save_data()
				return true
		MealType.SNACK1:
			if _can_override_meal(snack1, current_date):
				snack1 = meal_data
				_save_data()
				return true
		MealType.LUNCH:
			if _can_override_meal(lunch, current_date):
				lunch = meal_data
				_save_data()
				return true
		MealType.SNACK2:
			if _can_override_meal(snack2, current_date):
				snack2 = meal_data
				_save_data()
				return true
		MealType.DINNER:
			if _can_override_meal(dinner, current_date):
				dinner = meal_data
				_save_data()
				return true
	
	return false

func can_eat_meal(meal_type: MealType) -> bool:
	var current_date = Time.get_date_dict_from_system()
	var current_hour = Time.get_time_dict_from_system().hour
	
	if not _is_within_meal_hours(meal_type, current_hour):
		return false
	
	match meal_type:
		MealType.BREAKFAST:
			return _can_override_meal(breakfast, current_date)
		MealType.SNACK1:
			return _can_override_meal(snack1, current_date)
		MealType.LUNCH:
			return _can_override_meal(lunch, current_date)
		MealType.SNACK2:
			return _can_override_meal(snack2, current_date)
		MealType.DINNER:
			return _can_override_meal(dinner, current_date)
	
	return false

func _is_within_meal_hours(meal_type: MealType, hour: int) -> bool:
	match meal_type:
		MealType.BREAKFAST:
			return hour >= 6 and hour <= 10
		MealType.SNACK1:
			return hour >= 11 and hour <= 12
		MealType.LUNCH:
			return hour >= 13 and hour <= 15
		MealType.SNACK2:
			return hour >= 16 and hour <= 18
		MealType.DINNER:
			return hour >= 19 and hour <= 22
	return false

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

func get_meal(meal_type: MealType) -> MealData:
	match meal_type:
		MealType.BREAKFAST:
			return breakfast
		MealType.SNACK1:
			return snack1
		MealType.LUNCH:
			return lunch
		MealType.SNACK2:
			return snack2
		MealType.DINNER:
			return dinner
	return null

func get_all_meals() -> Dictionary:
	return {
		"breakfast": breakfast,
		"snack1": snack1,
		"lunch": lunch,
		"snack2": snack2,
		"dinner": dinner
	}

func _can_override_meal(existing_meal: MealData, current_date: Dictionary) -> bool:
	if existing_meal == null:
		return true
	
	return not existing_meal.is_same_day(current_date)

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

func _load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		glucose_level = 40.0
		energy_level = 60.0
		hygiene_level = 40.0
		happiness_level = 80.0
		
		breakfast = null
		snack1 = null
		lunch = null
		snack2 = null
		dinner = null

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
	
	breakfast = _dict_to_meal(save_data.get("breakfast", null))
	snack1 = _dict_to_meal(save_data.get("snack1", null))
	lunch = _dict_to_meal(save_data.get("lunch", null))
	snack2 = _dict_to_meal(save_data.get("snack2", null))
	dinner = _dict_to_meal(save_data.get("dinner", null))

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
		"breakfast": _meal_to_dict(breakfast),
		"snack1": _meal_to_dict(snack1),
		"lunch": _meal_to_dict(lunch),
		"snack2": _meal_to_dict(snack2),
		"dinner": _meal_to_dict(dinner),
		"last_update_time": Time.get_unix_time_from_system()
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(save_data)

func _meal_to_dict(meal: MealData):
	if meal == null:
		return null
	
	return {
		"type": meal.type,
		"glucose_change": meal.glucose_change,
		"energy_change": meal.energy_change,
		"happiness_change": meal.happiness_change,
		"digestion_time": meal.digestion_time,
		"eaten_time": meal.eaten_time,
		"eaten_date": meal.eaten_date
	}

func _dict_to_meal(data):
	if data == null:
		return null
	
	return MealData.new(
		data.get("type", MealType.BREAKFAST),
		data.get("glucose_change", 0.0),
		data.get("energy_change", 0.0),
		data.get("happiness_change", 0.0),
		data.get("digestion_time", 1.0),
		data.get("eaten_time", 0.0),
		data.get("eaten_date", {"year": 0, "month": 0, "day": 0})
	)

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
		
		_apply_meal_effects_over_time(current_time, hours_passed)

	last_update_time = current_time

func _apply_meal_effects_over_time(current_time: float, hours_passed: float):
	var meals = [breakfast, snack1, lunch, snack2, dinner]
	
	for meal in meals:
		if meal == null:
			continue
		
		if not meal.is_digested(current_time):
			var effect = meal.get_remaining_effect(current_time)
			if effect.active:
				var decay_factor = hours_passed / meal.digestion_time
				glucose_level = clamp(glucose_level + meal.glucose_change * decay_factor, 0.0, 100.0)
				energy_level = clamp(energy_level + meal.energy_change * decay_factor, 0.0, 100.0)
				happiness_level = clamp(happiness_level + meal.happiness_change * decay_factor, 0.0, 100.0)

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
	var current_time = Time.get_unix_time_from_system()

	glucose_level = max(0.0, glucose_level - GLUCOSE_DECAY_PER_HOUR * minute_fraction)
	energy_level = max(0.0, energy_level - ENERGY_DECAY_PER_HOUR * minute_fraction)
	hygiene_level = max(0.0, hygiene_level - HYGIENE_DECAY_PER_HOUR * minute_fraction)
	happiness_level = max(0.0, happiness_level - HAPPINESS_DECAY_PER_HOUR * minute_fraction)
	
	var meals = [breakfast, snack1, lunch, snack2, dinner]
	
	for meal in meals:
		if meal == null:
			continue
		
		if not meal.is_digested(current_time):
			var effect = meal.get_remaining_effect(current_time)
			if effect.active:
				var decay_factor = minute_fraction / meal.digestion_time
				glucose_level = clamp(glucose_level + meal.glucose_change * decay_factor, 0.0, 100.0)
				energy_level = clamp(energy_level + meal.energy_change * decay_factor, 0.0, 100.0)
				happiness_level = clamp(happiness_level + meal.happiness_change * decay_factor, 0.0, 100.0)

	var now := Time.get_unix_time_from_system()
	if int(now) % 300 < 60:
		_save_data()

	_emit_stats()
