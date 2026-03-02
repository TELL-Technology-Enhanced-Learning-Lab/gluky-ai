extends MeshInstance3D

# ==================================================
# PARAMETRI CINEMATOGRAFICI
# ==================================================
@export_group("Base Water Motion (Idle)")
@export var breathe_height: float = 0.018
@export var breathe_speed: float = 0.35

@export var wave_a_height: float = 0.012
@export var wave_a_speed: float = 0.6

@export var wave_b_height: float = 0.008
@export var wave_b_speed: float = 0.9

@export var lateral_drift: float = 0.015

@export_group("Cinematic Splash")
@export var impact_lift: float = 0.14
@export var tilt_angle: float = 1.8
@export var impact_duration: float = 0.25
@export var aftershock_duration: float = 1.0
@export var settle_duration: float = 2.5

# ==================================================
# STATO
# ==================================================
var base_position: Vector3
var base_rotation: Vector3
var t: float = 0.0
var reacting: bool = false

# ==================================================
# READY
# ==================================================
func _ready():
	base_position = position
	base_rotation = rotation
	print("🎬 Cinematic bath water ready")

# ==================================================
# IDLE – ACQUA VIVA
# ==================================================
func _process(delta):
	if reacting:
		return

	t += delta

	# "Respiro" principale
	var breathe = sin(t * TAU * breathe_speed) * breathe_height

	# Onde secondarie (interferenza)
	var wave_a = sin(t * TAU * wave_a_speed) * wave_a_height
	var wave_b = cos(t * TAU * wave_b_speed) * wave_b_height

	# Drift laterale imperfetto
	var drift_x = sin(t * 0.4) * lateral_drift
	var drift_z = cos(t * 0.33) * lateral_drift

	position = Vector3(
		base_position.x + drift_x,
		base_position.y + breathe + wave_a + wave_b,
		base_position.z + drift_z
	)

	# Micro inclinazione (quasi invisibile)
	rotation.x = base_rotation.x + sin(t * 0.25) * deg_to_rad(0.25)
	rotation.z = base_rotation.z + cos(t * 0.22) * deg_to_rad(0.25)

# ==================================================
# SPLASH CINEMATOGRAFICO (CUTSCENE)
# ==================================================
func cinematic_splash():
	if reacting:
		return

	reacting = true
	print("💦 Cinematic splash")

	var tween := create_tween()

	# -------------------------------
	# 1️⃣ IMPATTO
	# -------------------------------
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		self,
		"position:y",
		base_position.y + impact_lift,
		impact_duration
	)

	tween.parallel().tween_property(
		self,
		"rotation:x",
		base_rotation.x + deg_to_rad(tilt_angle),
		impact_duration
	)

	tween.parallel().tween_property(
		self,
		"rotation:z",
		base_rotation.z - deg_to_rad(tilt_angle * 0.6),
		impact_duration
	)

	# -------------------------------
	# 2️⃣ AFTERSHOCK
	# -------------------------------
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		self,
		"position:y",
		base_position.y + impact_lift * 0.4,
		aftershock_duration
	)

	tween.parallel().tween_property(
		self,
		"rotation:x",
		base_rotation.x - deg_to_rad(tilt_angle * 0.4),
		aftershock_duration
	)

	# -------------------------------
	# 3️⃣ RILASSAMENTO LUNGO
	# -------------------------------
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		self,
		"position",
		base_position,
		settle_duration
	)

	tween.parallel().tween_property(
		self,
		"rotation",
		base_rotation,
		settle_duration
	)

	await tween.finished
	reacting = false
