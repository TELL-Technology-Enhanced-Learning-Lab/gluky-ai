extends Control

# ══════════════════════════════════════════════
# GLUCORUN — LEVEL SELECT  (stile Candy/Arcobaleno)
# ══════════════════════════════════════════════

@onready var glucose_bar: ProgressBar    = $PanelContainer/TopBar/GlucoseBar
@onready var glucose_label: Label        = $PanelContainer/TopBar/GlucoseValue
@onready var header: VBoxContainer       = $Header

var _glucose_time: float = 0.0
var _glucose_base: float = 128.0
var _scene_changing: bool = false  # ← anti doppio tap mobile

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

# Palette candy/arcobaleno
const SKY_BLUE   = Color(0.40, 0.82, 1.00, 1.0)
const CANDY_PINK = Color(1.00, 0.42, 0.70, 1.0)
const CANDY_YELL = Color(1.00, 0.88, 0.20, 1.0)
const CANDY_PURP = Color(0.72, 0.35, 1.00, 1.0)
const CANDY_MINT = Color(0.30, 0.95, 0.65, 1.0)
const CANDY_ORG  = Color(1.00, 0.60, 0.15, 1.0)
const WHITE      = Color(1.00, 1.00, 1.00, 1.0)
const DARK_BG    = Color(0.10, 0.22, 0.45, 1.0)

const LEVEL_COLORS = [CANDY_PINK, CANDY_YELL, CANDY_MINT]

# ══════════════════════════════════════════════
func _ready():
	_paint_background()
	_style_glucose_bar()
	_add_header_line()
	_build_cards()

func _paint_background():
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.55, 0.85, 1.0, 1.0)
	add_child(bg)
	move_child(bg, 0)

	var rainbow = HBoxContainer.new()
	rainbow.set_anchor(SIDE_LEFT,   0.0)
	rainbow.set_anchor(SIDE_RIGHT,  1.0)
	rainbow.set_anchor(SIDE_TOP,    1.0)
	rainbow.set_anchor(SIDE_BOTTOM, 1.0)
	rainbow.offset_top    = -18
	rainbow.offset_bottom = 0
	rainbow.add_theme_constant_override("separation", 0)
	add_child(rainbow)
	var rainbow_cols = [
		Color(1,0.3,0.3), Color(1,0.6,0.1), CANDY_YELL,
		Color(0.3,1,0.4), SKY_BLUE, CANDY_PURP, CANDY_PINK
	]
	for c in rainbow_cols:
		var strip = ColorRect.new()
		strip.color = c
		strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rainbow.add_child(strip)

func _style_glucose_bar():
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.35)
	bg.set_corner_radius_all(8)
	glucose_bar.add_theme_stylebox_override("background", bg)

	var fill = StyleBoxFlat.new()
	fill.bg_color = CANDY_PINK
	fill.set_corner_radius_all(8)
	glucose_bar.add_theme_stylebox_override("fill", fill)

	var ps = StyleBoxFlat.new()
	ps.bg_color     = Color(1.0, 1.0, 1.0, 0.55)
	ps.border_color = CANDY_PURP
	ps.set_border_width_all(3)
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
	glucose_label.add_theme_color_override("font_color", CANDY_PURP)

func _add_header_line():
	var g = Gradient.new()
	g.set_color(0, Color(1, 0.4, 0.7, 0.0))
	g.add_point(0.25, Color(1, 0.85, 0.2, 1.0))
	g.add_point(0.5,  Color(0.4, 0.9, 1.0, 1.0))
	g.add_point(0.75, Color(0.75, 0.4, 1.0, 1.0))
	g.add_point(1.0,  Color(1, 0.4, 0.7, 0.0))
	var gt = GradientTexture2D.new()
	gt.gradient = g
	gt.width  = 320
	gt.height = 4
	var line = TextureRect.new()
	line.texture = gt
	line.custom_minimum_size = Vector2(320, 4)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	header.add_child(line)

# ══════════════════════════════════════════════
func _build_cards():
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 28)
	hbox.set_anchor(SIDE_LEFT,   0.0)
	hbox.set_anchor(SIDE_RIGHT,  1.0)
	hbox.set_anchor(SIDE_TOP,    0.0)
	hbox.set_anchor(SIDE_BOTTOM, 1.0)
	hbox.offset_top    = 400
	hbox.offset_bottom = -30
	hbox.offset_left   = 20
	hbox.offset_right  = -20
	add_child(hbox)

	for i in range(LEVEL_DATA.size()):
		var card = _make_card(LEVEL_DATA[i], i)
		hbox.add_child(card)
		card.modulate.a = 0.0
		card.position.y += 60
		var tw = create_tween()
		tw.tween_interval(0.12 * i)
		tw.tween_property(card, "modulate:a", 1.0, 0.45)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.parallel().tween_property(card, "position:y", card.position.y - 60, 0.45)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _make_card(data: Dictionary, idx: int) -> PanelContainer:
	var state  = data["state"]
	var accent = LEVEL_COLORS[idx % LEVEL_COLORS.size()]
	var card   = PanelContainer.new()
	card.custom_minimum_size = Vector2(270, 320)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_card(card, state, accent)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	var badge_row = HBoxContainer.new()
	var badge = PanelContainer.new()
	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color = accent
	badge_style.set_corner_radius_all(20)
	badge_style.content_margin_left   = 12
	badge_style.content_margin_right  = 12
	badge_style.content_margin_top    = 4
	badge_style.content_margin_bottom = 4
	badge.add_theme_stylebox_override("panel", badge_style)
	var badge_lbl = Label.new()
	badge_lbl.text = "LIVELLO %02d" % data["id"]
	badge_lbl.add_theme_font_size_override("font_size", 11)
	badge_lbl.add_theme_color_override("font_color", WHITE)
	badge.add_child(badge_lbl)
	badge_row.add_child(badge)
	vbox.add_child(badge_row)

	var emojis = ["🍭", "🍯", "🌿"]
	var emoji_lbl = Label.new()
	emoji_lbl.text = emojis[data["id"] - 1]
	emoji_lbl.add_theme_font_size_override("font_size", 36)
	emoji_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var tw_e = create_tween().set_loops()
	tw_e.tween_property(emoji_lbl, "position:y", emoji_lbl.position.y - 6, 0.9)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw_e.tween_property(emoji_lbl, "position:y", emoji_lbl.position.y, 0.9)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	vbox.add_child(emoji_lbl)

	var title = Label.new()
	title.text = data["title"]
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", DARK_BG)
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = data["desc"]
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.15, 0.15, 0.35, 0.75))
	vbox.add_child(desc)

	vbox.add_child(_make_separator(accent))
	var stats = HBoxContainer.new()
	stats.add_theme_constant_override("separation", 20)
	vbox.add_child(stats)
	stats.add_child(_make_stat("DISTANZA", data["distance"], accent))
	stats.add_child(_make_stat("RECORD",   data["record"],   accent))
	stats.add_child(_make_difficulty(data["difficulty"], accent))
	vbox.add_child(_make_progress(data, state, accent))

	var btn = _make_button(state, accent)
	vbox.add_child(btn)
	btn.pressed.connect(_on_play.bind(data, card))

	card.mouse_entered.connect(_on_hover_enter.bind(card))
	card.mouse_exited.connect(_on_hover_exit.bind(card))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	return card

func _style_card(card: PanelContainer, state: String, accent: Color):
	var s = StyleBoxFlat.new()
	s.set_corner_radius_all(20)
	s.content_margin_left   = 22
	s.content_margin_right  = 22
	s.content_margin_top    = 22
	s.content_margin_bottom = 22
	s.set_border_width_all(3)
	match state:
		"completed":
			s.bg_color     = Color(1.0, 1.0, 1.0, 0.92)
			s.border_color = accent
			s.shadow_color = Color(accent.r, accent.g, accent.b, 0.4)
			s.shadow_size  = 8
		"unlocked":
			s.bg_color     = Color(1.0, 1.0, 1.0, 0.85)
			s.border_color = Color(accent.r, accent.g, accent.b, 0.6)
			s.shadow_color = Color(accent.r, accent.g, accent.b, 0.25)
			s.shadow_size  = 6
		"locked":
			s.bg_color     = Color(0.75, 0.80, 0.90, 0.70)
			s.border_color = Color(0.6, 0.6, 0.7, 0.4)
	card.add_theme_stylebox_override("panel", s)

func _make_separator(accent: Color) -> Control:
	var g = Gradient.new()
	g.set_color(0, Color(accent.r, accent.g, accent.b, 0.0))
	g.add_point(0.5, Color(accent.r, accent.g, accent.b, 0.8))
	g.add_point(1.0, Color(accent.r, accent.g, accent.b, 0.0))
	var gt = GradientTexture2D.new()
	gt.gradient = g
	gt.width  = 200
	gt.height = 3
	var line = TextureRect.new()
	line.texture = gt
	line.custom_minimum_size = Vector2(0, 3)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return line

func _make_stat(label_text: String, value_text: String, accent: Color) -> VBoxContainer:
	var vb = VBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.5, 0.7))
	var val = Label.new()
	val.text = value_text
	val.add_theme_font_size_override("font_size", 15)
	val.add_theme_color_override("font_color", accent.darkened(0.15))
	vb.add_child(lbl)
	vb.add_child(val)
	return vb

func _make_difficulty(level: int, accent: Color) -> VBoxContainer:
	var vb = VBoxContainer.new()
	var lbl = Label.new()
	lbl.text = "DIFFICOLTÀ"
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.5, 0.7))
	vb.add_child(lbl)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	for i in range(5):
		var star = Label.new()
		if i < level:
			star.text = "★"
			star.add_theme_color_override("font_color", accent)
			star.add_theme_font_size_override("font_size", 14)
			var tw = create_tween().set_loops()
			tw.tween_interval(i * 0.2)
			tw.tween_property(star, "modulate:a", 0.5, 0.6)
			tw.tween_property(star, "modulate:a", 1.0, 0.6)
		else:
			star.text = "☆"
			star.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7, 0.4))
			star.add_theme_font_size_override("font_size", 14)
		row.add_child(star)
	vb.add_child(row)
	return vb

func _make_progress(_data: Dictionary, state: String, accent: Color) -> VBoxContainer:
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	var row = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = "COMPLETAMENTO"
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.5, 0.7))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pct_val = 100 if state == "completed" else (65 if state == "unlocked" else 0)
	var pct_lbl = Label.new()
	pct_lbl.text = "%d%%" % pct_val
	pct_lbl.add_theme_font_size_override("font_size", 11)
	pct_lbl.add_theme_color_override("font_color", accent.darkened(0.1))
	row.add_child(lbl)
	row.add_child(pct_lbl)
	vb.add_child(row)

	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 8)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 0
	bar.show_percentage = false
	var bg2 = StyleBoxFlat.new()
	bg2.bg_color = Color(accent.r, accent.g, accent.b, 0.15)
	bg2.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg2)
	var fill2 = StyleBoxFlat.new()
	fill2.bg_color = accent
	fill2.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill2)
	vb.add_child(bar)

	var tw = create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(bar, "value", float(pct_val), 1.2)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	return vb

func _make_button(state: String, accent: Color) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 44)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	match state:
		"completed": btn.text = "✓  RIGIOCA"
		"unlocked":  btn.text = "▶  GIOCA!"
		"locked":    btn.text = "🔒  BLOCCATO"
	btn.disabled = (state == "locked")

	var normal = StyleBoxFlat.new()
	normal.set_corner_radius_all(22)
	normal.set_border_width_all(0)
	normal.bg_color = accent
	normal.shadow_color = Color(accent.r, accent.g, accent.b, 0.5)
	normal.shadow_size  = 6
	btn.add_theme_stylebox_override("normal", normal)

	var hover = StyleBoxFlat.new()
	hover.set_corner_radius_all(22)
	hover.bg_color = accent.lightened(0.15)
	hover.shadow_color = Color(accent.r, accent.g, accent.b, 0.7)
	hover.shadow_size  = 10
	btn.add_theme_stylebox_override("hover", hover)

	var pressed_s = StyleBoxFlat.new()
	pressed_s.set_corner_radius_all(22)
	pressed_s.bg_color = accent.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", pressed_s)

	btn.add_theme_color_override("font_color", WHITE)
	btn.add_theme_font_size_override("font_size", 14)
	return btn

# ══════════════════════════════════════════════
func _on_hover_enter(card: PanelContainer):
	var tw = create_tween()
	tw.tween_property(card, "scale", Vector2(1.04, 1.04), 0.15)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_hover_exit(card: PanelContainer):
	var tw = create_tween()
	tw.tween_property(card, "scale", Vector2(1.0, 1.0), 0.15)\
		.set_ease(Tween.EASE_OUT)

func _on_play(data: Dictionary, card: PanelContainer):
	# ← Blocca doppi tap su mobile
	if _scene_changing:
		return

	if data["state"] == "locked":
		_shake(card)
		_show_toast("🔒  Completa prima il livello precedente!")
		return

	_scene_changing = true  # ← da qui in poi nessun altro tap viene accettato

	_burst_particles(card.global_position + card.size * 0.5, LEVEL_COLORS[data["id"] - 1])

	var tw = create_tween()
	tw.tween_property(card, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.10)
	tw.tween_property(card, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)

	var overlay = ColorRect.new()
	overlay.color = Color(1, 1, 1, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var tw2 = create_tween()
	tw2.tween_interval(0.25)
	tw2.tween_property(overlay, "color:a", 1.0, 0.4)
	tw2.tween_callback(func():
		# ← FileAccess.file_exists RIMOSSO: non funziona su Android con res://
		get_tree().change_scene_to_file(data["scene"])
	)

	# ← Fallback: se il tween si blocca su Android, cambia scena dopo 2s
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_inside_tree():
			get_tree().change_scene_to_file(data["scene"])
	)

func _burst_particles(pos: Vector2, accent: Color):
	var burst_colors = [accent, CANDY_PINK, CANDY_YELL, CANDY_PURP, CANDY_ORG, WHITE]
	for i in range(30):
		var p = ColorRect.new()
		var s = randf_range(4, 10)
		p.custom_minimum_size = Vector2(s, s)
		p.color = burst_colors[randi() % burst_colors.size()]
		p.position = pos
		add_child(p)
		var angle  = randf() * TAU
		var dist   = randf_range(70, 180)
		var target = pos + Vector2(cos(angle), sin(angle)) * dist
		var tw = create_tween()
		tw.tween_property(p, "position", target, randf_range(0.35, 0.65))\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.parallel().tween_property(p, "modulate:a", 0.0, randf_range(0.3, 0.55))\
			.set_delay(0.1)
		tw.tween_callback(p.queue_free)

func _shake(card: PanelContainer):
	var ox = card.position.x
	var tw = create_tween()
	for offset in [10, -10, 7, -7, 4, -4, 0]:
		tw.tween_property(card, "position:x", ox + offset, 0.05)

var _toast_node: PanelContainer = null

func _show_toast(msg: String):
	if _toast_node:
		_toast_node.queue_free()
	var panel = PanelContainer.new()
	var ps = StyleBoxFlat.new()
	ps.bg_color     = Color(1.0, 1.0, 1.0, 0.92)
	ps.border_color = CANDY_PINK
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(22)
	ps.content_margin_left   = 28
	ps.content_margin_right  = 28
	ps.content_margin_top    = 14
	ps.content_margin_bottom = 14
	ps.shadow_color = Color(1, 0.3, 0.5, 0.4)
	ps.shadow_size  = 8
	panel.add_theme_stylebox_override("panel", ps)
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_color_override("font_color", CANDY_PINK)
	lbl.add_theme_font_size_override("font_size", 14)
	panel.add_child(lbl)
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_bottom = -30
	panel.offset_top    = -80
	panel.modulate.a    = 0.0
	add_child(panel)
	_toast_node = panel
	var tw = create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.25)
	tw.tween_interval(2.2)
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
		var fill = StyleBoxFlat.new()
		fill.set_corner_radius_all(8)
		if _glucose_base < 100:
			fill.bg_color = CANDY_PURP
		elif _glucose_base > 150:
			fill.bg_color = CANDY_ORG
		else:
			fill.bg_color = CANDY_MINT
		glucose_bar.add_theme_stylebox_override("fill", fill)


func _on_btn_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/glucky/Minigame_Selection.tscn")
