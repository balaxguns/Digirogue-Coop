extends Control
## Interactive overlay for the approved DIGIROGUE title artwork.
## Original artwork was composed at 1672x941. Buttons follow proportional positions.
const GOLD := Color("#ffdc3d")
const IMAGE_SIZE := Vector2(1672, 941)
var settings_panel: PanelContainer
var active_effects: Dictionary = {}
var hover_buttons: Array[Button] = []

func _ready() -> void:
	Save.apply_settings()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var art := TextureRect.new()
	art.texture = load("res://assets/digirogue_title_art.png")
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	_add_menu_button("Start Game", Rect2(550, 544, 565, 78), func(): get_tree().change_scene_to_file("res://scenes/hub.tscn"))
	_add_menu_button("Multiplayer", Rect2(558, 631, 555, 72), Callable(), true)
	_add_menu_button("Settings", Rect2(558, 709, 555, 73), func(): settings_panel.visible = not settings_panel.visible)
	_add_menu_button("Quit Game", Rect2(558, 789, 555, 77), func(): get_tree().quit())
	_create_settings()

func _add_menu_button(_caption: String, bounds: Rect2, action: Callable, unavailable: bool = false) -> void:
	var b := Button.new()
	b.text = ""
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_ARROW if unavailable else Control.CURSOR_POINTING_HAND
	b.anchor_left = bounds.position.x / IMAGE_SIZE.x
	b.anchor_top = bounds.position.y / IMAGE_SIZE.y
	b.anchor_right = (bounds.position.x + bounds.size.x) / IMAGE_SIZE.x
	b.anchor_bottom = (bounds.position.y + bounds.size.y) / IMAGE_SIZE.y
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE if unavailable else Control.MOUSE_FILTER_STOP
	b.tooltip_text = "Online co-op is coming later." if unavailable else ""
	var blank := StyleBoxEmpty.new()
	b.add_theme_stylebox_override("normal", blank)
	b.add_theme_stylebox_override("hover", blank)
	b.add_theme_stylebox_override("pressed", blank)
	b.add_theme_stylebox_override("focus", blank)
	add_child(b)
	if not unavailable:
		b.pressed.connect(action)
		hover_buttons.append(b)

func _process(_delta: float) -> void:
	# Poll the actual pointer position: transparent artwork overlays can prevent
	# mouse_entered signals from behaving consistently across window sizes.
	var pointer := get_global_mouse_position()
	for b in hover_buttons:
		if b.get_global_rect().has_point(pointer) and not settings_panel.visible:
			_begin_effect(b)
		else:
			_end_effect(b)

func _begin_effect(b: Button) -> void:
	if active_effects.has(b):
		return
	# Draw above the full-screen art, independent of button clipping.
	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var outline := Panel.new()
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outline.position = b.position
	outline.size = b.size
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = GOLD
	style.set_border_width_all(5)
	style.set_corner_radius_all(8)
	outline.add_theme_stylebox_override("panel", style)
	overlay.add_child(outline)
	var tweens: Array = []
	for side in 2:
		for i in 8:
			var pixel := ColorRect.new()
			pixel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pixel.color = GOLD if i % 2 == 0 else Color("#fff3a1")
			pixel.size = Vector2(5 + (i % 3) * 2, 5 + (i % 3) * 2)
			var x := b.position.x - 19.0 - float(i % 2) * 7.0 if side == 0 else b.position.x + b.size.x + 11.0 + float(i % 2) * 7.0
			var origin := Vector2(x, b.position.y + 12.0 + float(i % 5) * 11.0)
			pixel.position = origin
			overlay.add_child(pixel)
			var tw := create_tween().set_loops()
			tw.tween_property(pixel, "position", origin + Vector2(0, -16), 0.72).from(origin)
			tw.parallel().tween_property(pixel, "modulate:a", 0.0, 0.72).from(1.0)
			tw.tween_interval(0.10 + float(i % 4) * 0.06)
			tweens.append(tw)
	active_effects[b] = {"overlay": overlay, "tweens": tweens}

func _end_effect(b: Button) -> void:
	if not active_effects.has(b):
		return
	var entry: Dictionary = active_effects[b]
	for tw in entry["tweens"]:
		if tw.is_valid():
			tw.kill()
	entry["overlay"].queue_free()
	active_effects.erase(b)

func _create_settings() -> void:
	settings_panel = PanelContainer.new()
	settings_panel.visible = false
	settings_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	settings_panel.offset_left = -205
	settings_panel.offset_top = -150
	settings_panel.offset_right = 205
	settings_panel.offset_bottom = 150
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0a1d4c")
	style.border_color = GOLD
	style.set_border_width_all(3)
	style.set_content_margin_all(22)
	settings_panel.add_theme_stylebox_override("panel", style)
	add_child(settings_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 15)
	settings_panel.add_child(column)
	var heading := Label.new()
	heading.text = "SETTINGS"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", GOLD)
	heading.add_theme_font_size_override("font_size", 26)
	column.add_child(heading)
	var volume_label := Label.new()
	volume_label.text = "Master volume"
	column.add_child(volume_label)
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = float(Save.settings.get("vol", 1.0))
	volume.value_changed.connect(func(value):
		Save.settings["vol"] = value
		Save.apply_settings()
		Save.save_game())
	column.add_child(volume)
	var fullscreen := CheckButton.new()
	fullscreen.text = "Fullscreen"
	fullscreen.button_pressed = bool(Save.settings.get("fullscreen", false))
	fullscreen.toggled.connect(func(on):
		Save.settings["fullscreen"] = on
		Save.apply_settings()
		Save.save_game())
	column.add_child(fullscreen)
	var close := Button.new()
	close.text = "CLOSE"
	close.pressed.connect(func(): settings_panel.hide())
	column.add_child(close)
