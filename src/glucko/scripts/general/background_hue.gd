extends ColorRect

@export var cycle_duration: float = 60.0
@export var saturation: float = 0.6
@export var value: float = 0.9

var _time_passed: float = 0.0
var _start_hue: float = 0.0

func _ready():
	_start_hue = color.h
	color = Color.from_hsv(_start_hue, saturation, value)

func _process(delta):
	_time_passed += delta
	var progress = fposmod(_time_passed / cycle_duration, 1.0)
	progress = smoothstep(0.0, 1.0, progress)
	var hue = fposmod(_start_hue + progress, 1.0)
	color = Color.from_hsv(hue, saturation, value)
