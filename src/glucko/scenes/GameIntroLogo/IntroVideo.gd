extends Control

# ══════════════════════════════════════════════
# GLUCOWORLD — INTRO VIDEO
# ══════════════════════════════════════════════

const NEXT_SCENE = "res://scenes/menus/glucky/Intro_3d.tscn"
const VIDEO_PATH = "res://scenes/GameIntroLogo/Gluky_s_GlukoWorld_Adventure_Intro.ogv"

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var skip_label: Label               = $SkipLabel

var _can_skip: bool = false
var _scene_changing: bool = false  # ← evita chiamate doppie

func _ready():
	modulate = Color(0, 0, 0, 1)
	skip_label.text = "[ SPAZIO / CLICK per saltare ]"
	skip_label.modulate.a = 0.0
	video_player.expand = true

	var stream = load(VIDEO_PATH)
	if stream == null:
		push_error("Video non trovato: " + VIDEO_PATH)
		_go_to_next_scene()
		return

	video_player.stream = stream
	video_player.finished.connect(_on_video_finished)

	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.6)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(func():
		video_player.play()
		_can_skip = true
		_show_skip_hint()
	)

func _show_skip_hint():
	var tw = create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(skip_label, "modulate:a", 0.7, 0.5)
	tw.tween_interval(4.0)
	tw.tween_property(skip_label, "modulate:a", 0.0, 1.0)

func _input(event: InputEvent):
	if not _can_skip:
		return
	var skip = false
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_ESCAPE:
			skip = true
	if event is InputEventMouseButton and event.pressed:
		skip = true
	if event is InputEventScreenTouch and event.pressed:
		skip = true
	if skip:
		_can_skip = false
		video_player.stop()
		_cinematic_transition()

func _on_video_finished():
	_can_skip = false
	_cinematic_transition()

func _cinematic_transition():
	if _scene_changing:  # ← blocca doppie chiamate
		return
	_scene_changing = true

	var vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.set_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float strength : hint_range(0.0, 20.0) = 0.0;
void fragment() {
	vec2 uv = UV - vec2(0.5);
	float v = 1.0 - dot(uv, uv) * strength;
	v = clamp(v, 0.0, 1.0);
	COLOR = vec4(0.0, 0.0, 0.0, 1.0 - v);
}
"""
	var mat = ShaderMaterial.new()
	mat.shader = shader
	vignette.material = mat

	var flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.set_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 1, 1, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	var tw = create_tween()
	tw.tween_method(
		func(v: float): mat.set_shader_parameter("strength", v),
		0.0, 8.0, 1.2
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(flash, "color:a", 1.0, 0.15)\
		.set_ease(Tween.EASE_OUT)
	tw.tween_property(flash, "color", Color(0, 0, 0, 1), 0.5)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(_go_to_next_scene)

	# ← Fallback Android: se il tween si blocca, cambia scena dopo 4s
	get_tree().create_timer(4.0).timeout.connect(func():
		if is_inside_tree():
			_go_to_next_scene()
	)

func _go_to_next_scene():
	if not is_inside_tree():  # ← sicurezza extra su mobile
		return
	# FileAccess.file_exists rimosso — non funziona su Android con res://
	get_tree().change_scene_to_file(NEXT_SCENE)
