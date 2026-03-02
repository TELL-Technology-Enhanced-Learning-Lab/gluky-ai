extends ColorRect

# ============================
# 🎨 ANIMAZIONE COLORE
# ============================
@export var cycle_duration: float = 60.0
@export var saturation: float = 0.6
@export var value: float = 0.9

var _time_passed: float = 0.0
var _start_hue: float = 0.0

# ============================
# READY
# ============================
func _ready():
	# Colore iniziale
	_start_hue = color.h
	color = Color.from_hsv(_start_hue, saturation, value)

	# I bottoni NON sono figli del ColorRect → li cerchiamo nel parent
	var parent = get_parent()

	var window1: TextureButton = parent.get_node("Window1")
	var window2: TextureButton = parent.get_node("Window2")
	var window3: TextureButton = parent.get_node("Window3")
	var window4: TextureButton = parent.get_node("Window4")
	

	# Connessioni bottoni con i percorsi che mi hai dato
	window1.pressed.connect(func():
		_change_scene("res://scenes/menus/glucorun/glucorun_menu.tscn")
	)

	window2.pressed.connect(func():
		_change_scene("res://scenes/menus/glucolife/SplashScreen.tscn")
	)

	window3.pressed.connect(func():
		_change_scene("res://scenes/scenes_tutorial/Menu_inizio.tscn")
	)

	window4.pressed.connect(func():
		_change_scene("res://scenes/GlukoQuizScenes/Menuiniziale.tscn")
	

	
	)

# ============================
# PROCESS (animazione colore)
# ============================
func _process(delta):
	_time_passed += delta

	var progress = fposmod(_time_passed / cycle_duration, 1.0)
	progress = smoothstep(0.0, 1.0, progress)

	var hue = fposmod(_start_hue + progress, 1.0)
	color = Color.from_hsv(hue, saturation, value)

# ============================
# CAMBIO SCENA
# ============================
func _change_scene(path: String) -> void:
	if FileAccess.file_exists(path):
		get_tree().change_scene_to_file(path)
	else:
		push_error("❌ Scena non trovata: " + path)
