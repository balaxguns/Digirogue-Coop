extends Control
## Title screen: Start Game, Multiplayer (not implemented), Settings, Quit Game.
var settings_panel: PanelContainer

func _ready() -> void:
	Save.apply_settings()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#110f1b")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(340, 0)
	v.add_theme_constant_override("separation", 14)
	center.add_child(v)
	var t := Label.new()
	t.text = "DARK AREA EXPEDITION"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 38)
	v.add_child(t)
	var sub := Label.new()
	sub.text = "A Digimon roguelike"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var start := _btn(v, "Start Game")
	start.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/hub.tscn"))
	var mp := _btn(v, "Multiplayer")
	mp.tooltip_text = "Not yet implemented"   # intentionally does nothing
	var st := _btn(v, "Settings")
	st.pressed.connect(func(): settings_panel.visible = not settings_panel.visible)
	var q := _btn(v, "Quit Game")
	q.pressed.connect(func(): get_tree().quit())
	settings_panel = PanelContainer.new()
	settings_panel.visible = false
	v.add_child(settings_panel)
	var sv := VBoxContainer.new()
	settings_panel.add_child(sv)
	var vol_l := Label.new()
	vol_l.text = "Master volume"
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
	keys.text = "Controls: WASD move, mouse aim, click/J attack, Q skill, R ultimate, Space dodge, E digivolve, 1-3 items, I inventory, Esc abandon run"
	keys.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	keys.custom_minimum_size = Vector2(320, 0)
	sv.add_child(keys)

func _btn(parent: Node, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 46)
	parent.add_child(b)
	return b
