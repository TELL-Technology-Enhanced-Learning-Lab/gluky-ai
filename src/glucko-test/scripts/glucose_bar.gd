extends CanvasLayer

@onready var label_value: Label = $Label_Value
@onready var fill_bar: ColorRect = $FillBar

@onready var limit_low_line: ColorRect = $ColorRect_LowThreshold
@onready var limit_high_line: ColorRect = $ColorRect_HighThreshold
@onready var safe_min_line: ColorRect = $ColorRect_SafeMin
@onready var safe_max_line: ColorRect = $ColorRect_SafeMax

var min_glucose := 50.0
var max_glucose := 250.0
var low_threshold := 70.0        
var high_threshold := 180.0    
var safe_min := 80.0            
var safe_max := 140.0         

var current_glucose := 90.0     
var bar_width := 400.0
var bar_height := 30.0
var bar_x := 20.0
var bar_y := 20.0

var effects: Array = []
var base_decay: float = 1.0
var game_over_triggered: bool = false

func _ready():
	update_indicators()
	update_display()

func _process(delta: float):
	if game_over_triggered:
		return
	
	var total_change = 0.0
	var active_effects = []
	
	for effect in effects:
		if effect.elapsed < effect.duration:
			var effect_rate = effect.total_amount / effect.duration
			var frame_change = effect_rate * delta
			total_change += frame_change
			effect.elapsed += delta
			active_effects.append(effect)

	effects = active_effects
	
	total_change -= base_decay * delta
	
	current_glucose += total_change
	current_glucose = clamp(current_glucose, min_glucose, max_glucose)
	
	update_display()
	
	check_game_over()

func add_food_effect(id: String, total_amount: float, duration_seconds: float):
	if game_over_triggered:
		return
		
	var effect = {
		"id": id,
		"total_amount": total_amount,
		"duration": duration_seconds,
		"elapsed": 0.0
	}
	
	effects.append(effect)

func get_glucose_value() -> float:
	return current_glucose

func update_display() -> void:
	var percentage = (current_glucose - min_glucose) / (max_glucose - min_glucose)
	percentage = clamp(percentage, 0.0, 1.0)
	
	var target_width = bar_width * percentage
	var bar_color = get_color_for_glucose(current_glucose)
	
	fill_bar.size.x = target_width
	fill_bar.color = bar_color
	label_value.text = str(int(current_glucose)) + " mg/dL"

func get_color_for_glucose(value: float) -> Color:
	if value <= low_threshold:
		return Color(0.1, 0.4, 1.0)   
	elif value >= high_threshold:
		return Color(1.0, 0.2, 0.2)   
	elif value >= safe_min and value <= safe_max:
		return Color(0.2, 1.0, 0.3)    
	else:
		return Color(1.0, 0.8, 0.0)    

func update_indicators():
	var line_width = 3
	
	_place_indicator(limit_low_line, low_threshold, line_width)
	_place_indicator(limit_high_line, high_threshold, line_width)
	_place_indicator(safe_min_line, safe_min, line_width)
	_place_indicator(safe_max_line, safe_max, line_width)

func _place_indicator(node: ColorRect, value: float, line_width: int):
	var percentage = (value - min_glucose) / (max_glucose - min_glucose)
	percentage = clamp(percentage, 0.0, 1.0)
	
	node.size = Vector2(line_width, bar_height)
	node.position.x = bar_x + bar_width * percentage - line_width * 0.5
	node.position.y = bar_y

func check_game_over():
	if current_glucose <= min_glucose or current_glucose >= max_glucose:
		trigger_game_over()

func trigger_game_over():
	if game_over_triggered:
		return
	
	game_over_triggered = true
	
	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.size = get_viewport().get_visible_rect().size
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.modulate.a = 0
	
	get_tree().root.add_child(fade_rect)
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	await get_tree().create_timer(0.3).timeout
	
	fade_rect.queue_free()
	get_tree().call_deferred("reload_current_scene")
