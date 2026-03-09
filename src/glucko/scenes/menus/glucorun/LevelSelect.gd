extends Control

# ══════════════════════════════════════════════
# GLUCORUN — LEVEL SELECT  (3 livelli, tutto via script)
# ══════════════════════════════════════════════

@onready var glucose_bar: ProgressBar    = $PanelContainer/TopBar/GlucoseBar
@onready var glucose_label: Label        = $PanelContainer/TopBar/GlucoseValue
@onready var header: VBoxContainer       = $Header

var _glucose_time: float = 0.0
var _glucose_base: float = 128.0

const LEVEL_DATA = [
	{
		"id": 1, "title": "Mondo Arcobaleno",
		"desc": "Lecca-lecca giganti e mongolfiere!\nImpara a raccogliere frutta e schiva le torte.",
		"difficulty": 1, "distance": "1.2 km", "record": "0:48",
		"scene": "res://scenes/glucorun levels/livello1.tscn",
		"state": "unlocked"
	},
	{
		"id": 2, "title": "Mondo Caramello",
		"desc": "Colline dorate e tanti dolci ostacolo!\nUsa le insuline virtuali con anticipo.",
		"difficulty": 2, "distance": "2.0 km", "record": "1:12",
		"scene": "res://scenes/glucorun levels/livello2.tscn",
		"state": "unlocked"
	},
	{
		"id": 3, "title": "Mondo Menta",
		"desc": "Ritmo intenso tra colline azzurre!\nTieni la barra virtuale sempre in zona verde.",
		"difficulty": 3, "distance": "2.8 km", "record": "—",
		"scene": "res://scenes/glucorun levels/livello3.tscn",
		"state": "unlocked"
	},
]

const TEAL = Color(0.0, 1.0, 0.8, 1.0)
const TEAL2 = Color(0.0, 0.67, 1.0, 1.0)
const RED  = Color(1.0, 0.18, 0.33, 1.0)
const DARK = Color(0.02, 0.09, 0.14, 1.0)

# ══════════════════════════════════════════════
func _ready():
	_style_glucose_bar()
	_add_header_line()
	_build_cards()

func _style_glucose_bar():
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0, 1, 0.8, 0.1)
	bg.set_corner_radius_all(6)
	glucose_bar.add_theme_stylebox_override("background", bg)

	var fill = StyleBoxFlat.new()
	fill.bg_color = TEAL
	fill.set_corner_radius_all(6)
	glucose_bar.add_theme_stylebox_override("fill", fill)

	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.17, 0.13, 1.0)
	ps.border_color = Color(0, 1, 0.8, 0.4)
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(22)
	ps.content_margin_left   = 16
	ps.content_margin_right  = 16
	ps.content_margin_top    = 8
	ps.content_margin_bottom = 8
	$PanelContainer.add_theme_stylebox_override("panel", ps)

	glucose_bar.min_value = 70
	glucose_bar.max_value = 200
	glucose_bar.value     = _glucose_base
	glucose_label.text    = "%d mg/dL" % int(_glucose_base)

func _add_header_line():
	var g = Gradient.new()
	g.set_color(0, Color(0, 1, 0.8, 0.0))
	g.add_point(0.5, Color(0, 1, 0.8, 0.8))
	g.add_point(1.0, Color(0, 1, 0.8, 0.0))
	var gt = GradientTexture2D.new()
	gt.gradient = g
	gt.width  = 220
	gt.height = 2
	var line = TextureRect.new()
	line.texture = gt
	line.custom_minimum_size = Vector2(220, 2)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	header.add_child(line)

# ══════════════════════════════════════════════
func _build_cards():
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 24)
	hbox.set_anchor(SIDE_LEFT,   0.0)
	hbox.set_anchor(SIDE_RIGHT,  1.0)
	hbox.set_anchor(SIDE_TOP,    0.0)
	hbox.set_anchor(SIDE_BOTTOM, 1.0)
	hbox.offset_top    = 400
	hbox.offset_bottom = -20
	hbox.offset_left   = 20
	hbox.offset_right  = -20
	add_child(hbox)

	for i in range(LEVEL_DATA.size()):
		var card = _make_card(LEVEL_DATA[i])
		hbox.add_child(card)
		card.modulate.a = 0.0
		card.position.y += 50
		var tw = create_tween()
		tw.tween_interval(0.15 * i)
		tw.tween_property(card, "modulate:a", 1.0, 0.5)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.parallel().tween_property(card, "position:y", card.position.y - 50, 0.5)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _make_card(data: Dictionary) -> PanelContainer:
	var state = data["state"]
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(260, 300)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_card(card, state)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	var num_lbl = Label.new()
	num_lbl.text = "LIVELLO %02d" % data["id"]
	num_lbl.add_theme_font_size_override("font_size", 11)
	num_lbl.add_theme_color_override("font_color", TEAL)
	vbox.add_child(num_lbl)

	var title = Label.new()
	title.text = data["title"]
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = data["desc"]
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	vbox.add_child(desc)

	vbox.add_child(_make_separator())
	var stats = HBoxContainer.new()
	stats.add_theme_constant_override("separation", 20)
	vbox.add_child(stats)
	stats.add_child(_make_stat("DISTANZA", data["distance"]))
	stats.add_child(_make_stat("RECORD",   data["record"]))
	stats.add_child(_make_difficulty(data["difficulty"]))
	vbox.add_child(_make_progress(data, state))

	var btn = _make_button(state)
	vbox.add_child(btn)
	btn.pressed.connect(_on_play.bind(data, card))

	card.mouse_entered.connect(_on_hover_enter.bind(card))
	card.mouse_exited.connect(_on_hover_exit.bind(card))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	return card

func _style_card(card: PanelContainer, state: String):
	var s = StyleBoxFlat.new()
	s.set_corner_radius_all(16)
	s.content_margin_left   = 22
	s.content_margin_right  = 22
	s.content_margin_top    = 22
	s.content_margin_bottom = 22
	s.set_border_width_all(1)
	match state:
		"completed":
			s.bg_color     = Color(0.0, 1.0, 0.8, 0.10)
			s.border_color = Color(0.0, 1.0, 0.8, 0.50)
		"unlocked":
			s.bg_color     = Color(0.0, 1.0, 0.8, 0.06)
			s.border_color = Color(0.0, 1.0, 0.8, 0.25)
		"locked":
			s.bg_color     = Color(0.04, 0.08, 0.12, 0.95)
			s.border_color = Color(1.0,  1.0,  1.0,  0.05)
	card.add_theme_stylebox_override("panel", s)

func _make_separator() -> Control:
	var c = ColorRect.new()
	c.custom_minimum_size = Vector2(0, 1)
	c.color = Color(1, 1, 1, 0.07)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c

func _make_stat(label_text: String, value_text: String) -> VBoxContainer:
	var vb = VBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
	var val = Label.new()
	val.text = value_text
	val.add_theme_font_size_override("font_size", 14)
	val.add_theme_color_override("font_color", TEAL)
	vb.add_child(lbl)
	vb.add_child(val)
	return vb

func _make_difficulty(level: int) -> VBoxContainer:
	var vb = VBoxContainer.new()
	var lbl = Label.new()
	lbl.text = "DIFFICOLTÀ"
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
	vb.add_child(lbl)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	for i in range(5):
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(8, 8)
		if i < level:
			dot.color = TEAL
			var tw = create_tween().set_loops()
			tw.tween_interval(i * 0.15)
			tw.tween_property(dot, "modulate:a", 0.4, 0.8)
			tw.tween_property(dot, "modulate:a", 1.0, 0.8)
		else:
			dot.color = Color(0, 1, 0.8, 0.15)
		row.add_child(dot)
	vb.add_child(row)
	return vb

func _make_progress(data: Dictionary, state: String) -> VBoxContainer:
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	var row = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = "COMPLETAMENTO"
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pct_val = 100 if state == "completed" else (65 if state == "unlocked" else 0)
	var pct_lbl = Label.new()
	pct_lbl.text = "%d%%" % pct_val
	pct_lbl.add_theme_font_size_override("font_size", 11)
	pct_lbl.add_theme_color_override("font_color", TEAL)
	row.add_child(lbl)
	row.add_child(pct_lbl)
	vb.add_child(row)

	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 4)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 0
	bar.show_percentage = false
	var bg2 = StyleBoxFlat.new()
	bg2.bg_color = Color(1, 1, 1, 0.06)
	bg2.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg2)
	var fill2 = StyleBoxFlat.new()
	fill2.bg_color = TEAL
	fill2.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill2)
	vb.add_child(bar)

	var tw = create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(bar, "value", float(pct_val), 1.2)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	return vb

func _make_button(state: String) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 40)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	match state:
		"completed": btn.text = "✓  RIGIOCA"
		"unlocked":  btn.text = "▶  GIOCA"
		"locked":    btn.text = "🔒  BLOCCATO"
	btn.disabled = (state == "locked")
	var normal = StyleBoxFlat.new()
	normal.set_corner_radius_all(10)
	normal.set_border_width_all(1)
	normal.bg_color     = Color(0.0, 1.0, 0.8, 0.12)
	normal.border_color = Color(0.0, 1.0, 0.8, 0.35)
	btn.add_theme_stylebox_override("normal", normal)
	var hover = StyleBoxFlat.new()
	hover.set_corner_radius_all(10)
	hover.set_border_width_all(1)
	hover.bg_color     = Color(0.0, 1.0, 0.8, 0.28)
	hover.border_color = Color(0.0, 1.0, 0.8, 0.70)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_color", TEAL)
	btn.add_theme_font_size_override("font_size", 13)
	return btn

# ══════════════════════════════════════════════
func _on_hover_enter(card: PanelContainer):
	var tw = create_tween()
	tw.tween_property(card, "scale", Vector2(1.03, 1.03), 0.18)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_hover_exit(card: PanelContainer):
	var tw = create_tween()
	tw.tween_property(card, "scale", Vector2(1.0, 1.0), 0.18)\
		.set_ease(Tween.EASE_OUT)

func _on_play(data: Dictionary, card: PanelContainer):
	if data["state"] == "locked":
		_shake(card)
		_show_toast("🔒  Completa prima il livello precedente!")
		return

	_burst_particles(card.global_position + card.size * 0.5)

	var tw = create_tween()
	tw.tween_property(card, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.12)
	tw.tween_property(card, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var tw2 = create_tween()
	tw2.tween_interval(0.25)
	tw2.tween_property(overlay, "color:a", 1.0, 0.4)
	tw2.tween_callback(func():
		if FileAccess.file_exists(data["scene"]):
			get_tree().change_scene_to_file(data["scene"])
		else:
			push_error("Scena non trovata: " + data["scene"])
			overlay.queue_free()
	)

func _burst_particles(pos: Vector2):
	for i in range(30):
		var p = ColorRect.new()
		var s = randf_range(3, 8)
		p.custom_minimum_size = Vector2(s, s)
		var colors = [TEAL, TEAL2, Color(1,1,1,0.9), Color(0,1,0.8,0.6)]
		p.color = colors[randi() % colors.size()]
		p.position = pos
		add_child(p)
		var angle  = randf() * TAU
		var dist   = randf_range(60, 160)
		var target = pos + Vector2(cos(angle), sin(angle)) * dist
		var tw = create_tween()
		tw.tween_property(p, "position", target, randf_range(0.4, 0.7))\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.parallel().tween_property(p, "modulate:a", 0.0, randf_range(0.3, 0.6))\
			.set_delay(0.1)
		tw.tween_callback(p.queue_free)

func _shake(card: PanelContainer):
	var ox = card.position.x
	var tw = create_tween()
	for offset in [8, -8, 6, -6, 3, -3, 0]:
		tw.tween_property(card, "position:x", ox + offset, 0.05)

var _toast_node: PanelContainer = null

func _show_toast(msg: String):
	if _toast_node:
		_toast_node.queue_free()
	var panel = PanelContainer.new()
	var ps = StyleBoxFlat.new()
	ps.bg_color     = Color(1.0, 0.18, 0.33, 0.15)
	ps.border_color = Color(1.0, 0.18, 0.33, 0.5)
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(12)
	ps.content_margin_left   = 24
	ps.content_margin_right  = 24
	ps.content_margin_top    = 12
	ps.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", ps)
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_color_override("font_color", RED)
	lbl.add_theme_font_size_override("font_size", 13)
	panel.add_child(lbl)
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_bottom = -30
	panel.offset_top    = -80
	panel.modulate.a    = 0.0
	add_child(panel)
	_toast_node = panel
	var tw = create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.3)
	tw.tween_interval(2.0)
	tw.tween_property(panel, "modulate:a", 0.0, 0.3)
	tw.tween_callback(panel.queue_free)

# ══════════════════════════════════════════════
func _process(delta):
	_glucose_time += delta
	if _glucose_time > 1.5:
		_glucose_time = 0.0
		_glucose_base += randf_range(-4.0, 4.0)
		_glucose_base = clamp(_glucose_base, 90.0, 170.0)
		glucose_bar.value  = _glucose_base
		glucose_label.text = "%d mg/dL" % int(_glucose_base)
