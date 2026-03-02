extends Control

signal chiuso

@onready var music_slider = $PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/HSlider
@onready var sound_slider = $PanelContainer/MarginContainer/VBoxContainer/VBoxContainer2/HSlider
@onready var ok_button = $Control/OkButton

const MUSIC_BUS = "Music"
const SFX_BUS = "SFX"

func _ready():
	# Configura gli slider
	setup_sliders()
	
	# Carica le impostazioni
	load_settings()
	
	# Connetti il bottone
	ok_button.pressed.connect(_on_ok_pressed)
	
	# Connetti il segnale di visibilità
	visibility_changed.connect(_on_visibility_changed)

func setup_sliders():
	# AGGIUNGI QUESTO CHECK
	if music_slider == null or sound_slider == null:
		print("Slider non ancora pronti, salto la configurazione")
		return
	
	# Configura slider musica
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.step = 1
	music_slider.editable = true
	music_slider.scrollable = true
	
	# Configura slider suoni
	sound_slider.min_value = 0
	sound_slider.max_value = 100
	sound_slider.step = 1
	sound_slider.editable = true
	sound_slider.scrollable = true
	
	# Disconnetti eventuali connessioni precedenti (per evitare duplicati)
	if music_slider.value_changed.is_connected(_on_music_slider_changed):
		music_slider.value_changed.disconnect(_on_music_slider_changed)
	if sound_slider.value_changed.is_connected(_on_sound_slider_changed):
		sound_slider.value_changed.disconnect(_on_sound_slider_changed)
	
	# Connetti i segnali
	music_slider.value_changed.connect(_on_music_slider_changed)
	sound_slider.value_changed.connect(_on_sound_slider_changed)
	
	print("Slider configurati correttamente")

func _on_music_slider_changed(value: float):
	print("Music slider: ", value)
	apply_volume(MUSIC_BUS, value)

func _on_sound_slider_changed(value: float):
	print("Sound slider: ", value)
	apply_volume(SFX_BUS, value)

func apply_volume(bus_name: String, value: float):
	var bus_idx = AudioServer.get_bus_index(bus_name)
	
	if bus_idx == -1:
		push_error("Bus '" + bus_name + "' non trovato!")
		return
	
	var db = linear_to_db(value / 100.0)
	if value == 0:
		db = -80
	
	AudioServer.set_bus_volume_db(bus_idx, db)
	print("✓ Volume ", bus_name, " impostato a: ", db, " dB")

func _on_back_pressed():
	load_settings()
	chiuso.emit()
	hide()

func _on_ok_pressed():
	save_settings()
	chiuso.emit()
	hide()

func save_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "music_volume", music_slider.value)
	config.set_value("audio", "sound_volume", sound_slider.value)
	config.save("user://settings.cfg")
	print("Impostazioni salvate")

func load_settings():
	# AGGIUNGI QUESTO CHECK ANCHE QUI
	if music_slider == null or sound_slider == null:
		print("Slider non ancora pronti per il caricamento")
		return
		
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		music_slider.value = config.get_value("audio", "music_volume", 80)
		sound_slider.value = config.get_value("audio", "sound_volume", 80)
		print("Impostazioni caricate")
	else:
		music_slider.value = 80
		sound_slider.value = 80
		print("Valori di default applicati")

func linear_to_db(linear: float) -> float:
	if linear <= 0:
		return -80
	return 20 * log(linear) / log(10)

func _on_visibility_changed():
	# AGGIUNGI QUESTO CHECK
	if visible and music_slider != null and sound_slider != null:
		print("Menu impostazioni aperto - riconfigurazione slider")
		setup_sliders()
