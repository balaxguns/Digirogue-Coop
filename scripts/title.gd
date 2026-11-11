extends Control
## DIGIROGUE title screen. All actions retain their original behavior.
const NAVY := Color("#101b43")
const BLUE := Color("#1556a6")
const GOLD := Color("#ffcf36")
const PALE := Color("#fff2b2")
var settings_panel: PanelContainer
var hover_particles: Dictionary = {}

func _ready() -> void:
	Save.apply_settings()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#080f27")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var backdrop := Panel.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var back_style := StyleBoxFlat.new()
	back_style.bg_color = Color("#0b1740")
	back_style.border_width_top = 7
	back_style.border_color = GOLD
	backdrop.add_theme_stylebox_override("panel", back_style)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(490, 0)
	frame.add_theme_stylebox_override("panel", _box(Color("#10245be8"), GOLD, 3, 22))
	center.add_child(frame)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 13)
	frame.add_child(v)
	var header := Label.new()
	header.text = "DIGIROGUE"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 57)
	header.add_theme_color_override("font_color", GOLD)
	header.add_theme_color_override("font_shadow_color", Color("#07142e"))
	header.add_theme_constant_override("shadow_offset_x", 3)
	header.add_theme_constant_override("shadow_offset_y", 4)
	v.add_child(header)
	var sub := Label.new()
	sub.text = "DARK AREA EXPEDITION"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 17)
	sub.add_theme_color_override("font_color", PALE)
	v.add_child(sub)
	v.add_child(HSeparator.new())
	var start := _btn(v, "START GAME")
	start.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/hub.tscn"))
	var mp := _btn(v, "MULTIPLAYER  •  COMING SOON")
	mp.disabled = true
	mp.tooltip_text = "Online co-op is planned for a later development phase."
	var st := _btn(v, "SETTINGS")
	st.pressed.connect(func(): settings_panel.visible = not settings_panel.visible)
	var q := _btn(v, "QUIT GAME")
	q.pressed.connect(func(): get_tree().quit())
	settings_panel = PanelContainer.new()
	settings_panel.visible = false
	settings_panel.add_theme_stylebox_override("panel", _box(Color("#091735"), BLUE, 2, 12))
	v.add_child(settings_panel)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 9)
	settings_panel.add_child(sv)
	var vol_l := Label.new()
	vol_l.text = "MASTER VOLUME"
	vol_l.add_theme_color_override("font_color", GOLD)
	sv.add_child(vol_l)
	var vol := HSlider.new()
	vol.min_value = 0.0
	vol.max_value = 1.0
	vol.step = 0.05
	vol.value = float(Save.settings.get("vol", 1.0))
	vol.custom_minimum_size = Vector2(300, 20)
	vol.value_changed.connect(func(x):
		Save.settings["vol"] = x
		Save.apply_settings()
		Save.save_game())
	sv.add_child(vol)
	var fs := CheckButton.new()
	fs.text = "Fullscreen"
	fs.button_pressed = bool(Save.settings.get("fullscreen", false))
	fs.toggled.connect(func(on):
		Save.settings["fullscreen"] = on
		Save.apply_settings()
		Save.save_game())
	sv.add_child(fs)
	var keys := Label.new()
	keys.text = "WASD Move  •  Mouse Aim  •  Click/J Attack  •  Q Skill  •  R Ultimate  •  Space Dodge  •  E Digivolve  •  1–3 Items  •  I Inventory"
	keys.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	keys.add_theme_color_override("font_color", PALE)
	sv.add_child(keys)

func _box(fill: Color, outline: Color, thickness: int, padding: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = outline
	s.set_border_width_all(thickness)
	s.set_corner_radius_all(12)
	s.set_content_margin_all(padding)
	return s

func _btn(parent: Node, caption: String) -> Button:
	var b := Button.new()
	b.text = caption
	b.custom_minimum_size = Vector2(0, 52)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", PALE)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_color_override("font_disabled_color", Color("#7883a4"))
	b.add_theme_stylebox_override("normal", _box(BLUE, Color("#4276bc"), 1, 7))
	b.add_theme_stylebox_override("hover", _box(Color("#174fa0"), GOLD, 4, 4))
	b.add_theme_stylebox_override("focus", _box(Color.TRANSPARENT, GOLD, 2, 0))
	b.add_theme_stylebox_override("pressed", _box(Color("#102c70"), GOLD, 3, 5))
	b.add_theme_stylebox_override("disabled", _box(Color("#18294c"), Color("#39466b"), 1, 7))
	parent.add_child(b)
	if not caption.begins_with("MULTIPLAYER"):
		b.mouse_entered.connect(func(): _start_hover_particles(b))
		b.mouse_exited.connect(func(): _stop_hover_particles(b))
	return b

# Short, looping digital pixels on both sides of the hovered menu entry.
# Each pixel drifts upward only 10-16 pixels, fades, and respawns.
func _start_hover_particles(button: Button) -> void:
	if hover_particles.has(button):
		return
	var particles: Array = []
	var tweens: Array = []
	for side in 2:
		for i in 3:
			var pixel := ColorRect.new()
			pixel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pixel.color = GOLD if i != 1 else Color("#fff0a0")
			var dimension := 5.0 if i == 1 else 8.0
			pixel.size = Vector2(dimension, dimension)
			button.add_child(pixel)
			var x_offset := -23.0 - float(i % 2) * 7.0 if side == 0 else button.size.x + 14.0 + float(i % 2) * 7.0
			var origin := Vector2(x_offset, 18.0 + float(i) * 9.0)
			pixel.position = origin
			pixel.modulate.a = 0.0
			var tween := create_tween().set_loops()
			tween.tween_interval(float(i) * 0.13)
			tween.tween_callback(func():
				if is_instance_valid(pixel):
					pixel.position = origin
					pixel.modulate.a = 1.0
			)
			tween.set_parallel(true)
			tween.tween_property(pixel, "position", origin + Vector2(0, -14), 0.7).set_trans(Tween.TRANS_SINE)
			tween.tween_property(pixel, "modulate:a", 0.0, 0.7).set_trans(Tween.TRANS_SINE)
			tween.set_parallel(false)
			tween.tween_interval(0.15)
			particles.append(pixel)
			tweens.append(tween)
	hover_particles[button] = {"pixels": particles, "tweens": tweens}

func _stop_hover_particles(button: Button) -> void:
	if not hover_particles.has(button):
		return
	var fx: Dictionary = hover_particles[button]
	for tween in fx["tweens"]:
		if tween.is_valid():
			tween.kill()
	for pixel in fx["pixels"]:
		if is_instance_valid(pixel):
			pixel.queue_free()
	hover_particles.erase(button)
