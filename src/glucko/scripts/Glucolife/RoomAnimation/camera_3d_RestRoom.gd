extends Camera3D

var original_transform: Transform3D
var bathtub_node: Node3D
var is_animating: bool = false
var idle_tween: Tween

@export_group("Final Camera Pose (Exact)")
@export var final_position: Vector3 = Vector3(13.278, 3.411, 1.754)
@export var final_rotation_deg: Vector3 = Vector3(-15.0, -105.0, 0.0)

@export_group("Animation Timing")
@export var zoom_duration: float = 0.8
@export var move_duration: float = 2.2
@export var settle_duration: float = 0.5

func _ready():
	add_to_group("camera_pivot")
	original_transform = global_transform

func _exit_tree():
	if idle_tween and is_instance_valid(idle_tween):
		idle_tween.kill()
	
	var tweens = get_tree().get_processed_tweens()
	for t in tweens:
		if is_instance_valid(t) and t.is_bound_to(self):
			t.kill()

func setup_bathtub_camera(bathtub: Node3D):
	bathtub_node = bathtub

func start_camera_animation():
	if is_animating:
		return
	
	var camera_pivot = get_tree().get_first_node_in_group("camera_pivot")
	if camera_pivot and camera_pivot.has_method("set_bathtub_mode"):
		camera_pivot.set_bathtub_mode(true)

	is_animating = true

	if idle_tween and is_instance_valid(idle_tween):
		idle_tween.kill()

	var target_transform: Transform3D = _build_final_transform()

	await camera_phase_1_initial_movement()
	await camera_phase_2_main_movement(target_transform)
	await camera_phase_3_settle(target_transform)

	start_camera_idle()

func _build_final_transform() -> Transform3D:
	var final_basis := Basis()
	final_basis = final_basis.rotated(Vector3.RIGHT, deg_to_rad(final_rotation_deg.x))
	final_basis = final_basis.rotated(Vector3.UP, deg_to_rad(final_rotation_deg.y))
	final_basis = final_basis.rotated(Vector3.FORWARD, deg_to_rad(final_rotation_deg.z))

	var t := Transform3D()
	t.basis = final_basis
	t.origin = final_position
	return t

func camera_phase_1_initial_movement():
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)

	var prep_offset = (
		global_transform.basis.z * -0.35 +
		global_transform.basis.y * -0.2
	)

	tween.tween_property(
		self,
		"global_position",
		global_position + prep_offset,
		zoom_duration
	)

	await tween.finished

func camera_phase_2_main_movement(target: Transform3D):
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		self,
		"global_transform",
		target,
		move_duration
	)

	await tween.finished

func camera_phase_3_settle(target: Transform3D):
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	var overshoot_pos = target.origin + Vector3(0, 0.08, 0)

	tween.tween_property(self, "global_position", overshoot_pos, settle_duration * 0.6)
	tween.tween_property(self, "global_position", target.origin, settle_duration * 0.4)

	await tween.finished

func start_camera_idle():
	idle_tween = create_tween()
	idle_tween.set_loops()
	idle_tween.set_trans(Tween.TRANS_SINE)
	idle_tween.set_ease(Tween.EASE_IN_OUT)

	var base_pos = global_position

	idle_tween.tween_property(
		self,
		"global_position",
		base_pos + global_transform.basis.x * 0.06,
		4.0
	)
	idle_tween.tween_property(
		self,
		"global_position",
		base_pos - global_transform.basis.x * 0.06,
		4.0
	)

	var rot_tween := create_tween()
	rot_tween.set_loops()
	rot_tween.set_trans(Tween.TRANS_SINE)
	rot_tween.set_ease(Tween.EASE_IN_OUT)

	var base_y = rotation.y
	rot_tween.tween_property(self, "rotation:y", base_y + deg_to_rad(1.2), 5.0)
	rot_tween.tween_property(self, "rotation:y", base_y - deg_to_rad(1.2), 5.0)

func reset_camera():
	if idle_tween and is_instance_valid(idle_tween):
		idle_tween.kill()

	is_animating = false

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(self, "global_transform", original_transform, 1.5)

	await tween.finished
	
	var camera_pivot = get_tree().get_first_node_in_group("camera_pivot")
	if camera_pivot and camera_pivot.has_method("set_bathtub_mode"):
		camera_pivot.set_bathtub_mode(false)
