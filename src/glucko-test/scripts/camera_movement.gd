extends Camera3D

@export var mouse_sensitivity: float = 0.003
@export var touch_sensitivity: float = 0.002
@export var min_vertical_offset: float = 2.0
@export var max_vertical_offset: float = 6.0
@export var camera_distance: float = 5.0
@export var vertical_sensitivity: float = 0.01
@export var smooth_speed: float = 8.0
@export var collision_margin: float = 0.3
@export var min_camera_height: float = 0.5
@export var low_glucose_threshold: float = 70.0
@export var high_glucose_threshold: float = 180.0
@export var low_symptom_intensity: float = 3.0
@export var high_symptom_intensity: float = 2.5

var yaw: float = 0.0
var vertical_offset: float = 4.0
var player: CharacterBody3D
var actual_camera_distance: float = camera_distance
var touch_delta: Vector2 = Vector2.ZERO
var glucose_value: float = 90.0
var low_symptom_timer: float = 0.0
var high_symptom_timer: float = 0.0
var base_smooth_speed: float
var base_mouse_sensitivity: float
var dizziness_offset: Vector2 = Vector2.ZERO
var original_fov: float

var world_environment: WorldEnvironment
var post_process_material: ShaderMaterial
var screen_tint: Color = Color.WHITE
var chromatic_aberration_strength: float = 0.0
var vignette_strength: float = 0.0
var screen_shake_offset: Vector2 = Vector2.ZERO
var shake_timer: float = 0.0

var last_glucose_state: String = "normal"
var subviewport_container: SubViewportContainer
var effects_setup_complete: bool = false
var glucose_bar_connected: bool = false

func _ready():
	player = get_parent()
	base_smooth_speed = smooth_speed
	base_mouse_sensitivity = mouse_sensitivity
	original_fov = fov
	
	if OS.has_feature("mobile"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	call_deferred("setup_visual_effects")
	
	await get_tree().create_timer(0.1).timeout
	setup_glucose_connection()

func setup_glucose_connection():
	var glucose_bar = get_tree().get_first_node_in_group("GlucoseBar")
	if glucose_bar and not glucose_bar_connected:
		if glucose_bar.has_signal("glucose_updated"):
			glucose_bar.connect("glucose_updated", Callable(self, "_on_glucose_updated"))
			glucose_bar_connected = true

func _on_glucose_updated(value: float):
	glucose_value = value
	
	var new_state = "normal"
	if glucose_value < low_glucose_threshold:
		new_state = "LOW"
	elif glucose_value > high_glucose_threshold:
		new_state = "HIGH"
	
	last_glucose_state = new_state

func setup_visual_effects():
	cleanup_visual_effects()
	
	post_process_material = ShaderMaterial.new()
	post_process_material.shader = create_post_process_shader()
	
	post_process_material.set_shader_parameter("blur_strength", 0.0)
	post_process_material.set_shader_parameter("distortion_strength", 0.0)
	post_process_material.set_shader_parameter("screen_tint", Color.WHITE)
	post_process_material.set_shader_parameter("chromatic_aberration", 0.0)
	post_process_material.set_shader_parameter("vignette_strength", 0.0)
	post_process_material.set_shader_parameter("noise_strength", 0.0)
	
	apply_post_process_material()
	create_world_environment()
	
	effects_setup_complete = true

func cleanup_visual_effects():
	if is_instance_valid(subviewport_container) and subviewport_container.is_inside_tree():
		get_tree().root.remove_child.call_deferred(subviewport_container)
		subviewport_container.queue_free()
		subviewport_container = null
	
	if is_instance_valid(world_environment) and world_environment.is_inside_tree():
		get_tree().root.remove_child.call_deferred(world_environment)
		world_environment.queue_free()
		world_environment = null

func create_world_environment():
	world_environment = WorldEnvironment.new()
	world_environment.name = "CameraWorldEnvironment"
	world_environment.environment = Environment.new()
	get_tree().root.add_child(world_environment)
	
	var env = world_environment.environment
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	
	env.glow_enabled = true
	env.glow_bloom = 0.3
	env.glow_intensity = 1.5
	env.glow_strength = 2.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

func apply_post_process_material():
	if is_instance_valid(subviewport_container) and subviewport_container.is_inside_tree():
		get_tree().root.remove_child(subviewport_container)
		subviewport_container.queue_free()
	
	subviewport_container = SubViewportContainer.new()
	subviewport_container.name = "CameraPostProcess"
	var subviewport = SubViewport.new()
	
	subviewport.size = get_viewport().size
	subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	subviewport.transparent_bg = true
	
	subviewport_container.add_child(subviewport)
	
	get_tree().root.add_child(subviewport_container)
	subviewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	subviewport_container.material = post_process_material
	
	if get_viewport().is_connected("size_changed", Callable(self, "_on_viewport_size_changed")):
		get_viewport().disconnect("size_changed", Callable(self, "_on_viewport_size_changed"))
	
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_size_changed").bind(subviewport), CONNECT_ONE_SHOT)

func _on_viewport_size_changed(subviewport: SubViewport):
	if subviewport:
		subviewport.size = get_viewport().size

func create_post_process_shader() -> Shader:
	var shader_code = """
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_strength : hint_range(0, 0.15) = 0.0;
uniform float distortion_strength : hint_range(0, 0.3) = 0.0;
uniform vec4 screen_tint : source_color = vec4(1.0);
uniform float chromatic_aberration : hint_range(0, 0.05) = 0.0;
uniform float vignette_strength : hint_range(0, 1.5) = 0.0;
uniform float noise_strength : hint_range(0, 0.3) = 0.0;

vec4 gaussian_blur(vec2 uv, float strength) {
	if (strength <= 0.001) return texture(screen_texture, uv);
	
	vec4 color = vec4(0.0);
	float total = 0.0;
	
	float kernel[25] = float[](
		0.003, 0.013, 0.022, 0.013, 0.003,
		0.013, 0.059, 0.097, 0.059, 0.013,
		0.022, 0.097, 0.159, 0.097, 0.022,
		0.013, 0.059, 0.097, 0.059, 0.013,
		0.003, 0.013, 0.022, 0.013, 0.003
	);
	
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			vec2 offset = vec2(float(x), float(y)) * strength * 0.5;
			int index = (x + 2) * 5 + (y + 2);
			color += texture(screen_texture, uv + offset) * kernel[index];
			total += kernel[index];
		}
	}
	
	return color / total;
}

vec2 apply_distortion(vec2 uv, float strength, float time) {
	if (strength <= 0.001) return uv;
	
	float wave1 = sin(uv.y * 15.0 + time * 5.0) * 0.003 * strength;
	float wave2 = cos(uv.x * 12.0 + time * 4.0) * 0.002 * strength;
	
	vec2 center = vec2(0.5, 0.5);
	vec2 dir = uv - center;
	float dist = length(dir);
	float radial_distortion = sin(dist * 15.0 + time * 6.0) * 0.005 * strength;
	
	return uv + vec2(wave1 + radial_distortion * dir.x * 1.0, 
					wave2 + radial_distortion * dir.y * 1.0);
}

vec4 apply_chromatic_aberration(vec2 uv, float strength) {
	if (strength <= 0.001) return texture(screen_texture, uv);
	
	vec2 direction = normalize(uv - vec2(0.5));
	float r = texture(screen_texture, uv - direction * strength * 1.0).r;
	float g = texture(screen_texture, uv - direction * strength * 0.5).g;
	float b = texture(screen_texture, uv).b;
	float a = texture(screen_texture, uv).a;
	
	return vec4(r, g, b, a);
}

float apply_vignette(vec2 uv, float strength) {
	if (strength <= 0.001) return 1.0;
	
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(uv, center);
	float vignette = 1.0 - dist * dist * strength * 3.0;
	
	return clamp(vignette, 0.0, 1.0);
}

float random(vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	float time = TIME;
	vec2 base_uv = UV;
	
	vec2 distorted_uv = apply_distortion(base_uv, distortion_strength, time);
	
	vec4 color = texture(screen_texture, distorted_uv);
	
	color = apply_chromatic_aberration(distorted_uv, chromatic_aberration);
	
	color = gaussian_blur(distorted_uv, blur_strength);
	
	float vignette = apply_vignette(base_uv, vignette_strength);
	color.rgb *= vignette;
	
	color *= screen_tint;
	
	if (noise_strength > 0.001) {
		float noise1 = random(base_uv * 50.0 + time);
		float noise2 = random(base_uv * 30.0 - time * 2.0);
		float noise = (noise1 + noise2 - 1.0) * noise_strength;
		color.rgb += noise;
		color.rgb = clamp(color.rgb, 0.0, 1.0);
	}
	
	COLOR = color;
}
"""
	
	var shader = Shader.new()
	shader.code = shader_code
	return shader

func set_glucose(value: float):
	glucose_value = value

func _input(event):
	var sensitivity_mod = 1.0
	if glucose_value < low_glucose_threshold:
		sensitivity_mod = lerp(0.4, 1.0, (glucose_value - 50.0) / 20.0)
	elif glucose_value > high_glucose_threshold:
		sensitivity_mod = lerp(1.0, 0.5, min((glucose_value - 180.0) / 70.0, 1.0))
	
	if OS.has_feature("mobile"):
		if event is InputEventScreenDrag:
			if event.index == 0:
				yaw -= event.relative.x * touch_sensitivity * sensitivity_mod
			elif event.index == 1:
				var inverted_vertical = -event.relative.y * sensitivity_mod
				vertical_offset = clamp(vertical_offset + inverted_vertical * vertical_sensitivity, min_vertical_offset, max_vertical_offset)
	else:
		if event is InputEventMouseMotion:
			yaw -= event.relative.x * mouse_sensitivity * sensitivity_mod
			var inverted_vertical = -event.relative.y * sensitivity_mod
			vertical_offset = clamp(vertical_offset + inverted_vertical * vertical_sensitivity, min_vertical_offset, max_vertical_offset)

func _physics_process(delta):
	if not player:
		return
	
	if not effects_setup_complete:
		setup_visual_effects()
	
	if not glucose_bar_connected:
		setup_glucose_connection()
	
	update_symptoms(delta)
	update_screen_shake(delta)
	
	var player_pos = player.global_position
	var camera_target = player_pos + Vector3(0, vertical_offset, 0)
	
	if screen_shake_offset.length() > 0.001:
		camera_target.x += screen_shake_offset.x * 0.5
		camera_target.z += screen_shake_offset.y * 0.5
	
	var yaw_with_dizziness = yaw
	if glucose_value < low_glucose_threshold:
		dizziness_offset = dizziness_offset.lerp(Vector2(randf_range(-1, 1), randf_range(-1, 1)) * low_symptom_intensity, delta * 3.0)
		yaw_with_dizziness += dizziness_offset.x * 0.3
		camera_target.y += dizziness_offset.y * 0.4
	
	var desired_offset = Vector3(0, 0, camera_distance).rotated(Vector3.UP, yaw_with_dizziness)

	actual_camera_distance = check_camera_collision(camera_target, desired_offset)
	var final_position = camera_target + desired_offset.normalized() * actual_camera_distance

	final_position = ensure_minimum_height(final_position, player_pos)
	
	var current_smooth_speed = smooth_speed
	if glucose_value > high_glucose_threshold:
		current_smooth_speed = lerp(base_smooth_speed, base_smooth_speed * 0.3, min((glucose_value - 180.0) / 70.0, 1.0))
	
	global_position = global_position.lerp(final_position, current_smooth_speed * delta)
	look_at(player_pos + Vector3(0, 1, 0), Vector3.UP)
	
	apply_visual_effects()

func update_symptoms(delta):
	if glucose_value < low_glucose_threshold:
		low_symptom_timer += delta
		high_symptom_timer = 0.0
		if glucose_value < 50.0:
			shake_timer += delta * 3.0
	elif glucose_value > high_glucose_threshold:
		high_symptom_timer += delta
		low_symptom_timer = 0.0
		if glucose_value > 250.0:
			shake_timer += delta * 1.0
	else:
		low_symptom_timer = max(low_symptom_timer - delta * 2.0, 0.0)
		high_symptom_timer = max(high_symptom_timer - delta * 2.0, 0.0)
		shake_timer = max(shake_timer - delta * 4.0, 0.0)

func update_screen_shake(delta):
	if shake_timer > 0.0:
		var shake_intensity = 0.0
		if glucose_value < low_glucose_threshold:
			shake_intensity = clamp((low_glucose_threshold - glucose_value) / 20.0, 0.0, 1.0) * 4.0
		elif glucose_value > high_glucose_threshold:
			shake_intensity = clamp((glucose_value - high_glucose_threshold) / 70.0, 0.0, 1.0)
		
		var time = Time.get_ticks_msec() / 1000.0
		screen_shake_offset.x = sin(time * 20.0 + 0.0) * 1.0 * shake_intensity
		screen_shake_offset.y = cos(time * 18.0 + 1.0) * 1.0 * shake_intensity
	else:
		screen_shake_offset = screen_shake_offset.lerp(Vector2.ZERO, delta * 3.0)

func apply_visual_effects():
	if not post_process_material or not effects_setup_complete:
		return
	
	var blur_amount = 0.0
	var distortion_amount = 0.0
	var chromatic_aberration_amount = 0.0
	var vignette_amount = 0.0
	var noise_amount = 0.0
	
	if glucose_value < low_glucose_threshold:
		var severity = clamp((low_glucose_threshold - glucose_value) / 20.0, 0.0, 1.0)
		blur_amount = severity * low_symptom_intensity * 0.08
		distortion_amount = severity * low_symptom_intensity * 0.08
		chromatic_aberration_amount = severity * low_symptom_intensity * 0.04
		vignette_amount = severity * 1.2
		noise_amount = severity * 0.15
		
		screen_tint = Color.from_hsv(0.6, 0.5, 0.8).lerp(Color.WHITE, 1.0 - severity * 0.8)
		
		fov = original_fov + sin(low_symptom_timer * 4.0) * 8.0 * severity
		
	elif glucose_value > high_glucose_threshold:
		var severity = clamp((glucose_value - high_glucose_threshold) / 70.0, 0.0, 1.0)
		blur_amount = severity * high_symptom_intensity * 0.06
		distortion_amount = severity * high_symptom_intensity * 0.04
		vignette_amount = severity * 1.4
		noise_amount = severity * 0.08
		
		screen_tint = Color.from_hsv(0.0, 0.4, 0.9).lerp(Color.WHITE, 1.0 - severity * 0.7)
		
		fov = original_fov - severity * 8.0
		
		if high_symptom_timer > 0.5:
			var pulse = sin(high_symptom_timer * 8.0) * severity * 0.2
			rotation.z += pulse
		
	else:
		fov = lerp(fov, original_fov, 0.05)
		rotation.z = lerp_angle(rotation.z, 0.0, 0.05)
		screen_tint = screen_tint.lerp(Color.WHITE, 0.05)
		blur_amount = lerp(blur_amount, 0.0, 0.05)
		distortion_amount = lerp(distortion_amount, 0.0, 0.05)
		chromatic_aberration_amount = lerp(chromatic_aberration_amount, 0.0, 0.05)
		vignette_amount = lerp(vignette_amount, 0.0, 0.05)
		noise_amount = lerp(noise_amount, 0.0, 0.05)
	
	if world_environment:
		var env = world_environment.environment
		
		env.glow_enabled = glucose_value > high_glucose_threshold
		if env.glow_enabled:
			var severity = clamp((glucose_value - high_glucose_threshold) / 70.0, 0.0, 1.0)
			env.glow_bloom = 0.3 + severity * 0.4
			env.glow_intensity = 1.5 + severity * 1.0
	
	post_process_material.set_shader_parameter("blur_strength", blur_amount)
	post_process_material.set_shader_parameter("distortion_strength", distortion_amount)
	post_process_material.set_shader_parameter("screen_tint", screen_tint)
	post_process_material.set_shader_parameter("chromatic_aberration", chromatic_aberration_amount)
	post_process_material.set_shader_parameter("vignette_strength", vignette_amount)
	post_process_material.set_shader_parameter("noise_strength", noise_amount)

func check_camera_collision(camera_target: Vector3, desired_offset: Vector3) -> float:
	var space_state = get_world_3d().direct_space_state
	var max_distance = desired_offset.length()
	var direction = desired_offset.normalized()
	
	var query = PhysicsRayQueryParameters3D.create(
		camera_target,
		camera_target + direction * (max_distance + collision_margin)
	)
	query.exclude = [player]
	
	var collision = space_state.intersect_ray(query)
	
	if collision:
		var collision_distance = camera_target.distance_to(collision.position) - collision_margin
		return max(collision_distance, collision_margin * 2)
	
	return max_distance

func ensure_minimum_height(camera_position: Vector3, player_pos: Vector3) -> Vector3:
	var space_state = get_world_3d().direct_space_state
	
	var ground_query = PhysicsRayQueryParameters3D.create(
		Vector3(camera_position.x, player_pos.y + 5.0, camera_position.z),
		Vector3(camera_position.x, player_pos.y - 10.0, camera_position.z)
	)
	
	var ground_collision = space_state.intersect_ray(ground_query)
	
	if ground_collision:
		var ground_height = ground_collision.position.y
		var desired_height = ground_height + min_camera_height
		
		if camera_position.y < desired_height:
			camera_position.y = desired_height
	
	return camera_position

func reset_camera():
	yaw = 0.0
	vertical_offset = 4.0
	glucose_value = 90.0
	low_symptom_timer = 0.0
	high_symptom_timer = 0.0
	dizziness_offset = Vector2.ZERO
	screen_shake_offset = Vector2.ZERO
	shake_timer = 0.0
	screen_tint = Color.WHITE
	
	fov = original_fov
	rotation.z = 0.0
	
	effects_setup_complete = false
	glucose_bar_connected = false
	
	cleanup_visual_effects()
	call_deferred("setup_visual_effects")

func _exit_tree():
	cleanup_visual_effects()
