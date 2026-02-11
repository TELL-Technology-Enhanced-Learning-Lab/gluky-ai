# res://scripts/Bathroom.gd
# COLLEGARE A: Bathroom (nodo root della scena)
extends Node3D

# === SISTEMA ORIENTAMENTO E UI ESISTENTE ===
@export var preferred_orientation := OrientationManager.OrientationMode.PORTRAIT

# === SISTEMA ANIMAZIONE VASCA ===
# Riferimenti ai nodi
var player: Node3D
var camera: Camera3D
var bathtub: Node3D
var bathtub_click_detector: Area3D

# Effetti
var water_splash_scene: PackedScene

# Componenti script
var camera_animator: Node

# Stati
var animation_in_progress: bool = false

func _ready():
	# Sistema esistente
	GlucolifeDataManager.enter_glucolife()
	_update_ui()
	
	# Sistema animazione vasca
	await get_tree().process_frame
	initialize_bathtub_system()

func _update_ui():
	var stats = GlucolifeDataManager.get_stats()
	
	if has_node("UI/GlucoseBar"):
		$UI/GlucoseBar.value = stats.glucose
	if has_node("UI/EnergyBar"):
		$UI/EnergyBar.value = stats.energy
	if has_node("UI/HygieneBar"):
		$UI/HygieneBar.value = stats.hygiene
	if has_node("UI/HappinessBar"):
		$UI/HappinessBar.value = stats.happiness

# ====================================================================
# SISTEMA ANIMAZIONE VASCA
# ====================================================================

func initialize_bathtub_system():
	print("==================================================")
	print("🛁 BATHTUB INTERACTION SYSTEM INITIALIZING")
	print("==================================================")
	
	# Carica la scena dello splash
	if ResourceLoader.exists("res://scenes/effects/WaterSplash.tscn"):
		water_splash_scene = load("res://scenes/effects/WaterSplash.tscn")
		print("✓ Water splash effect loaded")
	else:
		print("⚠ Water splash scene not found - will skip splash effect")
	
	find_required_nodes()
	
	if validate_setup():
		setup_animations()
		connect_signals()
		print("==================================================")
		print("✅ BATHTUB SYSTEM READY - Click on the bathtub to start!")
		print("==================================================")
	else:
		print("==================================================")
		print("⚠ BATHTUB SYSTEM NOT READY - Check the errors above")
		print("  (Il gioco funzionerà comunque, ma senza animazione vasca)")
		print("==================================================")

func find_required_nodes():
	print("\n🔍 Searching for required nodes...")
	
	# Trova Player
	player = find_child("Player", true, false)
	if player:
		print("  ✓ Found Player: %s" % player.name)
	else:
		print("  ⚠ Player not found")
	
	# Trova Camera
	camera = find_node_by_type(self, "Camera3D")
	if camera:
		print("  ✓ Found Camera: %s" % camera.name)
	else:
		print("  ⚠ Camera not found")
	
	# Trova la vasca (nodo chiamato "bath")
	bathtub = find_child("bath", true, false)
	if bathtub:
		print("  ✓ Found Bathtub: %s" % bathtub.name)
		
		# Cerca l'Area3D child della vasca
		bathtub_click_detector = find_node_by_type(bathtub, "Area3D")
		if bathtub_click_detector:
			print("  ✓ Found Click Detector: %s" % bathtub_click_detector.name)
		else:
			print("  ⚠ Click detector not found - you need to add Area3D to bath!")
	else:
		print("  ⚠ Bathtub 'bath' not found")

func find_node_by_type(node: Node, type: String) -> Node:
	if node.get_class() == type:
		return node
	
	for child in node.get_children():
		var result = find_node_by_type(child, type)
		if result:
			return result
	
	return null

func validate_setup() -> bool:
	var valid = true
	
	print("\n🔧 Validating bathtub setup...")
	
	if not player:
		print("  ⚠ Player not found - bathtub animation disabled")
		valid = false
	
	if not camera:
		print("  ⚠ Camera not found - bathtub animation disabled")
		valid = false
	
	if not bathtub:
		print("  ⚠ Bathtub not found - bathtub animation disabled")
		valid = false
	
	if not bathtub_click_detector:
		print("  ⚠ Bathtub click detector not found - bathtub animation disabled")
		print("     → Add Area3D as child of 'bath' node")
		print("     → Add CollisionShape3D as child of Area3D")
		print("     → Attach BathtubClickDetector.gd to Area3D")
		valid = false
	
	return valid

func setup_animations():
	print("\n⚙️ Setting up animations...")
	
	camera_animator = camera
	
	# Setup player animation
	if player and player.has_method("setup_bathtub_animation"):
		player.setup_bathtub_animation(bathtub)
		print("  ✓ Player animation setup complete")
	else:
		print("  ⚠ Player doesn't have bathtub animation support")
	
	# Setup camera animation
	if camera_animator and camera_animator.has_method("setup_bathtub_camera"):
		camera_animator.setup_bathtub_camera(bathtub)
		print("  ✓ Camera animation setup complete")
	else:
		print("  ⚠ Camera doesn't have bathtub animation support")

func connect_signals():
	print("\n🔗 Connecting signals...")
	
	if bathtub_click_detector and bathtub_click_detector.has_signal("bathtub_clicked"):
		bathtub_click_detector.bathtub_clicked.connect(_on_bathtub_clicked)
		print("  ✓ Click signal connected")

func _on_bathtub_clicked():
	if animation_in_progress:
		print("⚠ Animation already in progress!")
		return
	
	if not player or not camera:
		print("⚠ Cannot start animation - missing required nodes")
		return
	
	print("\n==================================================")
	print("🎬 STARTING BATHTUB ANIMATION SEQUENCE")
	print("==================================================")
	
	animation_in_progress = true
	start_complete_animation()

func start_complete_animation():
	# Inizia animazione player
	if player.has_method("start_bathtub_sequence"):
		player.start_bathtub_sequence()
	else:
		print("❌ Player doesn't have start_bathtub_sequence method!")
		animation_in_progress = false
		return
	
	# Aspetta che il player inizi il salto prima di muovere la camera
	await get_tree().create_timer(2.3).timeout
	print("🎥 Camera movement starting...")
	
	if camera_animator and camera_animator.has_method("start_camera_animation"):
		camera_animator.start_camera_animation()
	
	# Splash al momento giusto
	await get_tree().create_timer(1.0).timeout
	print("💦 Creating water splash...")
	create_water_splash()
	
	# Aggiorna stats dopo il bagno (aumenta igiene!)
	await get_tree().create_timer(0.5).timeout
	update_hygiene_after_bath()
	
	# Feedback completamento
	await get_tree().create_timer(1.0).timeout
	print("\n==================================================")
	print("✅ ANIMATION SEQUENCE COMPLETE")
	print("==================================================\n")
	
	animation_in_progress = false

func create_water_splash():
	if not water_splash_scene:
		print("⚠ No splash scene available")
		return
	
	var splash = water_splash_scene.instantiate()
	add_child(splash)
	
	var splash_position = bathtub.global_position
	splash_position.y += 0.35
	
	splash.global_position = splash_position
	
	print("  ✓ Water splash created at: %s" % str(splash_position))
	
	if splash is GPUParticles3D:
		splash.emitting = true
		splash.one_shot = true
		
		await get_tree().create_timer(splash.lifetime + 0.5).timeout
		splash.queue_free()
		print("  ✓ Water splash cleaned up")

func update_hygiene_after_bath():
	"""Aumenta l'igiene dopo il bagno"""
	print("🧼 Updating hygiene stats...")
	
	# Ottieni stats correnti
	var stats = GlucolifeDataManager.get_stats()
	
	# Aumenta igiene e happiness
	# ADATTA QUESTI METODI IN BASE ALLA TUA API DI GlucolifeDataManager
	# Esempio 1: Se hai metodi diretti
	if GlucolifeDataManager.has_method("update_hygiene"):
		GlucolifeDataManager.update_hygiene(30)
		GlucolifeDataManager.update_happiness(10)
	# Esempio 2: Se modifichi direttamente gli stats
	elif stats.has("hygiene"):
		stats.hygiene = min(stats.hygiene + 30, 100)
		stats.happiness = min(stats.happiness + 10, 100)
	
	# Aggiorna UI con animazione delle barre
	animate_stat_bars()
	
	print("  ✓ Hygiene and Happiness updated!")

func animate_stat_bars():
	"""Anima le barre delle stats quando aumentano"""
	var stats = GlucolifeDataManager.get_stats()
	
	# Anima barra igiene
	if has_node("UI/HygieneBar"):
		var hygiene_bar = $UI/HygieneBar
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(hygiene_bar, "value", stats.hygiene, 1.0)
	
	# Anima barra happiness
	if has_node("UI/HappinessBar"):
		var happiness_bar = $UI/HappinessBar
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(happiness_bar, "value", stats.happiness, 1.0)

func _input(event):
	# SPAZIO per testare l'animazione manualmente
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if not animation_in_progress:
			print("\n🔑 SPACE pressed - triggering animation manually")
			_on_bathtub_clicked()
	
	# R per resettare
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if animation_in_progress:
			print("\n🔄 R pressed - resetting scene")
			reset_scene()

func reset_scene():
	print("Resetting all animations...")
	
	if player and player.has_method("exit_bathtub"):
		player.exit_bathtub()
	
	if camera_animator and camera_animator.has_method("reset_camera"):
		await camera_animator.reset_camera()
	
	animation_in_progress = false
	print("✓ Scene reset complete")
