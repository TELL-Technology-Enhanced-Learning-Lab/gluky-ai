# res://scripts/Player.gd
# COLLEGARE A: Bathroom/Player
extends Node3D

# ===============================
# SISTEMA SKIN
# ===============================
@onready var _skin: CharacterSkin = $PlayerSkin

# ===============================
# STATO
# ===============================
var bathtub_node: Node3D
var is_animating := false
var is_in_bathtub := false

var original_position: Vector3
var original_rotation: Vector3

# ===============================
# POSA FINALE ESATTA (DA FOTO)
# ===============================
@export_group("Final Bathtub Pose (Exact)")
@export var final_position: Vector3 = Vector3(15.948, 1.5, 2.984)
@export var final_rotation_deg: Vector3 = Vector3(0.0, -93.6, 0.0)

# ===============================
# PARAMETRI CINEMATICI
# ===============================
@export_group("Cinematic Settings")
@export var walk_speed := 2.0
@export var jump_height := 0.6
@export var jump_duration := 0.8

# Tween attivi
var active_tweens: Array[Tween] = []

# ===============================
# READY
# ===============================
func _ready():
	add_to_group("player")
	original_position = global_position
	original_rotation = rotation
	print("✓ Player ready (cinematic bathtub)")

func _process(_delta):
	if not is_animating:
		update_animation_state()

func update_animation_state():
	if not _skin:
		return
	_skin.idle()
	_skin.run_tilt = 0.0

# ====================================================================
# SETUP
# ====================================================================
func setup_bathtub_animation(bathtub: Node3D):
	bathtub_node = bathtub
	print("✓ Bathtub linked: %s" % bathtub.name)

# ====================================================================
# SEQUENZA PRINCIPALE
# ====================================================================
func start_bathtub_sequence():
	if is_animating:
		return

	is_animating = true
	is_in_bathtub = false
	set_process_input(false)

	print("🎬 Bathtub cinematic start")

	await phase_1_walk_like_a_movie()
	await phase_2_jump_cinematic()
	await phase_3_force_final_pose()
	await phase_4_relax_idle()

	is_in_bathtub = true
	print("🛀 Player settled in bathtub")

# ====================================================================
# FASE 1 – CAMMINATA CINEMATICA
# ====================================================================
func phase_1_walk_like_a_movie():
	if _skin and _skin.has_method("walk"):
		_skin.walk()

	var tween := create_tween()
	active_tweens.append(tween)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)

	var approach_pos := final_position + Vector3(-1.2, 0, 0.6)
	var dir := (approach_pos - global_position).normalized()
	var target_rot := atan2(dir.x, dir.z)

	tween.tween_property(self, "rotation:y", target_rot, 0.4)

	var duration := global_position.distance_to(approach_pos) / walk_speed
	tween.parallel().tween_property(self, "global_position", approach_pos, duration)

	await tween.finished
	if _skin:
		_skin.idle()

# ====================================================================
# FASE 2 – SALTO MORBIDO
# ====================================================================
func phase_2_jump_cinematic():
	if _skin and _skin.has_method("jump"):
		_skin.jump()

	var tween := create_tween()
	active_tweens.append(tween)
	tween.set_trans(Tween.TRANS_QUAD)

	var start := global_position
	var peak := Vector3(
		(start.x + final_position.x) * 0.5,
		max(start.y, final_position.y) + jump_height,
		(start.z + final_position.z) * 0.5
	)

	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", peak, jump_duration * 0.5)
	tween.parallel().tween_property(self, "rotation:x", deg_to_rad(12), jump_duration * 0.5)

	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "global_position", final_position, jump_duration * 0.5)
	tween.parallel().tween_property(self, "rotation:x", 0.0, jump_duration * 0.5)

	await tween.finished
	if _skin:
		_skin.idle()

# ====================================================================
# FASE 3 – BLOCCO POSA FINALE (KEYFRAME HARD)
# ====================================================================
func phase_3_force_final_pose():
	print("📌 Locking final hero pose")

	var tween := create_tween()
	active_tweens.append(tween)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "global_position", final_position, 0.4)
	tween.parallel().tween_property(
		self,
		"rotation",
		Vector3(
			deg_to_rad(final_rotation_deg.x),
			deg_to_rad(final_rotation_deg.y),
			deg_to_rad(final_rotation_deg.z)
		),
		0.4
	)

	await tween.finished

# ====================================================================
# FASE 4 – IDLE CINEMATOGRAFICO (RELAX)
# ====================================================================
func phase_4_relax_idle():
	if _skin:
		_skin.idle()
		_skin.run_tilt = 0.0

	# Oscillazione laterale
	var sway := create_tween()
	sway.set_loops()
	sway.set_trans(Tween.TRANS_SINE)
	sway.set_ease(Tween.EASE_IN_OUT)

	var base_y := rotation.y
	sway.tween_property(self, "rotation:y", base_y + deg_to_rad(2.5), 3.0)
	sway.tween_property(self, "rotation:y", base_y - deg_to_rad(2.5), 3.0)

	# Galleggiamento
	var float_tween := create_tween()
	float_tween.set_loops()
	float_tween.set_trans(Tween.TRANS_SINE)
	float_tween.set_ease(Tween.EASE_IN_OUT)

	float_tween.tween_property(self, "global_position", final_position + Vector3(0, 0.04, 0), 2.0)
	float_tween.tween_property(self, "global_position", final_position - Vector3(0, 0.04, 0), 2.0)

# ====================================================================
# USCITA
# ====================================================================
func exit_bathtub():
	for t in active_tweens:
		if t.is_valid():
			t.kill()
	active_tweens.clear()

	is_animating = false
	is_in_bathtub = false
	set_process_input(true)

	var tween := create_tween()
	tween.tween_property(self, "global_position", original_position, 0.6)
	tween.parallel().tween_property(self, "rotation", original_rotation, 0.6)

	if _skin:
		_skin.idle()

	print("👋 Player exited bathtub")
