extends Control
## Mallow command nexus. Gameplay data and saves are unchanged.
const GOLD := Color("#ffcf36")
const CYAN := Color("#62d7ff")
const WHITE := Color("#ecf6ff")
const MUTED := Color("#a4bad9")
const STAT_NAMES := {"def": "Defense", "int": "Intelligence", "atk": "Attack", "wis": "Wisdom", "hp": "Max HP", "spd": "Move speed"}
const TIERS := ["In-Training (Lv 1)", "Rookie (Lv 3)", "Champion (Lv 6)", "Ultimate (Lv 12)", "Mega (Lv 15)"]
var sel: int = 2
var viewed_stage: int = 1
var selected_mon: int = -1
var tabs: TabContainer
var pages: Dictionary = {}
var core_lbl: Label
var drasil: OptionButton
var mon_info: VBoxContainer
var stage_info: VBoxContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_ui_theme()
	sel = clampi(Run.line, 0, maxi(0, Data.ROSTER.size() - 1))
	selected_mon = sel
	var bg := Control.new()
	bg.set_script(load("res://scripts/hub_data_stream.gd"))
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 12)
	margins.add_theme_constant_override("margin_right", 12)
	margins.add_theme_constant_override("margin_top", 10)
	margins.add_theme_constant_override("margin_bottom", 10)
	add_child(margins)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	margins.add_child(root)
	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", _panel(Color("#0c2452ee"), CYAN, 2, 14))
	root.add_child(header)
	header.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var top := HFlowContainer.new()
	top.add_theme_constant_override("h_separation", 16)
	top.add_theme_constant_override("v_separation", 8)
	header.add_child(top)
	var heading := VBoxContainer.new()
	heading.custom_minimum_size.x = 400
	heading.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	top.add_child(heading)
	_label(heading, "MALLOW  //  COMMAND NEXUS", 27, GOLD)
	_label(heading, "DIGITAL WORLD  /  POCKET DIMENSION  /  EXPEDITION PREPARATION", 12, MUTED)
	core_lbl = _label(top, "", 18, GOLD)
	core_lbl.custom_minimum_size = Vector2(185, 0)
	core_lbl.size_flags_horizontal = Control.SIZE_SHRINK_END
	core_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	core_lbl.clip_text = true
	var back := Button.new()
	back.text = "← TITLE SCREEN"
	back.custom_minimum_size = Vector2(150, 46)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/title.tscn"))
	top.add_child(back)
	if not Run.last_result.is_empty():
		var r: Dictionary = Run.last_result
		var report := _card(root, "LAST EXPEDITION  //  " + ("SUCCESS" if r.win else "FAILED"), GOLD)
		_label(report, "Level %d  •  %s  •  Nights %d/2  •  +%d Digicore  •  Equipment: %s" % [r.lv, r.name, r.cleared, r.core, ", ".join(PackedStringArray(r.got))], 13, WHITE)
		Run.last_result = {}
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_stylebox_override("panel", _panel(Color("#0b1b40ee"), CYAN, 2, 14))
	root.add_child(tabs)
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for n in ["Mercenary Digimon", "Equipment", ".mon Files", "Expedition"]:
		var sc := ScrollContainer.new()
		sc.name = n
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(sc)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 8)
		sc.add_child(v)
		pages[n] = v
	build_all()

func build_all() -> void:
	core_lbl.text = "◈  %d DIGICORE" % Save.core
	build_digi()
	build_equip()
	build_mon()
	build_exped()

func page(n: String) -> VBoxContainer:
	var v: VBoxContainer = pages[n]
	for child in v.get_children():
		v.remove_child(child)
		child.queue_free()
	return v

func _label(parent: Node, content: String, font_size: int = 15, color: Color = WHITE) -> Label:
	var l := Label.new()
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL if parent is VBoxContainer else Control.SIZE_SHRINK_BEGIN
	l.text = content
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

func _card(parent: Node, title: String, accent: Color = CYAN) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel(Color("#102b5be8"), accent, 2, 9))
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	panel.add_child(content)
	_label(content, title, 16, accent)
	return content

func _section(parent: Node, title: String, description: String) -> void:
	var header := _card(parent, title, GOLD)
	_label(header, description, 14, MUTED)

func _grid(parent: Node, cols: int) -> HFlowContainer:
	# Flow cards onto additional rows instead of forcing the whole tab wider.
	var g := HFlowContainer.new()
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	parent.add_child(g)
	return g

func _roster_button(parent: Node, i: int, active: bool, action: Callable) -> void:
	var r: Dictionary = Data.ROSTER[i]
	var b := Button.new()
	b.text = "%s\n%s  •  %s" % [r.stages[1], r.cls, r.attr]
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(205, 70)
	b.toggle_mode = true
	b.button_pressed = active
	b.pressed.connect(action)
	parent.add_child(b)

# MERCENARY DIGIMON
func build_digi() -> void:
	var v := page("Mercenary Digimon")
	_section(v, "01  //  MERCENARY DATABASE", "Choose a partner, then select an evolution stage from the dropdown to inspect its abilities.")
	var g := _grid(v, 3)
	for i in Data.ROSTER.size():
		var idx: int = i
		_roster_button(g, i, i == sel, func():
			sel = idx
			viewed_stage = 1
			build_digi()
			build_exped())
	var r: Dictionary = Data.ROSTER[sel]
	var detail := _card(v, "◈  %s  //  %s CLASS" % [r.stages[1], r.cls], GOLD)
	_label(detail, "ATTRIBUTE  %s     •     TYPE  %s     •     DAMAGE  %s" % [r.attr, r.type, "Intelligence" if Data.line_scaling(sel) == "int" else "Attack"], 14, WHITE)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 10)
	detail.add_child(row)
	_label(row, "STAGE", 13, CYAN)
	var stage_picker := OptionButton.new()
	stage_picker.custom_minimum_size = Vector2(255, 36)
	stage_picker.clip_text = true
	stage_picker.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	for stage in 5:
		stage_picker.add_item("%s  (%s)" % [r.stages[stage], ["In-Training", "Rookie", "Champion", "Ultimate", "Mega"][stage]], stage)
	stage_picker.select(viewed_stage)
	stage_picker.item_selected.connect(func(index: int):
		viewed_stage = index
		_update_stage_details())
	row.add_child(stage_picker)
	var passive: Array = Data.CLASS_PASSIVE[r.cls]
	_label(detail, "CLASS PASSIVE  •  %s  (+%d%% %s)" % [passive[0], int(float(passive[2]) * 100.0), STAT_NAMES.get(passive[1], passive[1])], 14, MUTED)
	stage_info = _card(v, "DIGIVOLUTION STAGE DATA", CYAN)
	_update_stage_details()
	var chain: Array[String] = []
	for st in 5:
		chain.append(str(r.stages[st]))
	_label(v, "DIGIVOLUTION PATH   " + "  ›  ".join(PackedStringArray(chain)), 13, MUTED)

func _update_stage_details() -> void:
	if stage_info == null:
		return
	for child in stage_info.get_children():
		stage_info.remove_child(child)
		child.queue_free()
	var r: Dictionary = Data.ROSTER[sel]
	_label(stage_info, "STAGE %02d  //  %s" % [viewed_stage + 1, r.stages[viewed_stage]], 18, CYAN)
	_label(stage_info, TIERS[viewed_stage] + "    •    " + r.type + "-type attacks", 14, MUTED)
	var moves: Array = MoveInfo.get_moves(sel, viewed_stage)
	if moves.is_empty():
		_label(stage_info, "Move data pending. Default projectile attack and short-range shockwave are available.", 15, WHITE)
	else:
		var kinds := ["BASIC ATTACK  /  CLICK", "SPECIAL SKILL  /  Q", "ULTIMATE  /  R"]
		for k in mini(3, moves.size()):
			var move_row := VBoxContainer.new()
			move_row.add_theme_constant_override("separation", 2)
			stage_info.add_child(move_row)
			var move_name := _label(move_row, kinds[k] + "  •  " + str(moves[k][0]), 13, CYAN)
			move_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_label(move_row, str(moves[k][1]), 13, WHITE)

# EQUIPMENT
func build_equip() -> void:
	var v := page("Equipment")
	_section(v, "02  //  EQUIPMENT VAULT", "Permanent expedition upgrades. Equip up to three pieces; select a card to toggle it.")
	var summary := HFlowContainer.new()
	summary.add_theme_constant_override("h_separation", 18)
	summary.add_theme_constant_override("v_separation", 6)
	v.add_child(summary)
	_label(summary, "EQUIPPED  %d / 3" % Save.equipped.size(), 15, GOLD)
	_label(summary, "COLLECTION  %d  •  PERMANENT UPGRADES" % Save.owned.size(), 13, MUTED)
	var g := _grid(v, 3)
	var items: Array = Save.owned.duplicate()
	items.sort_custom(func(a, b): return Data.equip[a.id].rar > Data.equip[b.id].rar)
	if items.is_empty():
		_label(v, "No equipment collected yet. Complete expeditions to earn permanent upgrades.", 16, WHITE)
	for o in items:
		var d: Dictionary = Data.equip[o.id]
		var equipped: bool = Save.equipped.has(int(o.u))
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = equipped
		b.text = "%s  •  %s\n%s  —  %s" % [Data.RARITIES[d.rar], "EQUIPPED" if equipped else "AVAILABLE", d.name, d.desc]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(250, 88)
		var uid: int = int(o.u)
		b.pressed.connect(func():
			if Save.equipped.has(uid):
				Save.equipped.erase(uid)
			elif Save.equipped.size() < 3:
				Save.equipped.append(uid)
			Save.save_game()
			build_equip()
			build_exped())
		g.add_child(b)

# .MON FILES
func build_mon() -> void:
	var v := page(".mon Files")
	_section(v, "03  //  MEMORY ARCHIVE", "Recover encrypted .mon records by evolving, exploring, and winning expeditions.")
	var g := _grid(v, 4)
	for i in Data.ROSTER.size():
		var idx: int = i
		var b := Button.new()
		b.text = "%s\nDECRYPTED  %d / 3" % [Data.ROSTER[i].stages[1], Save.mon_count(i)]
		b.custom_minimum_size = Vector2(185, 66)
		b.pressed.connect(func():
			selected_mon = idx
			_show_mon_details())
		g.add_child(b)
	mon_info = _card(v, "ARCHIVE READER  //  SELECT A DIGIMON", GOLD)
	_show_mon_details()

func _show_mon_details() -> void:
	if mon_info == null:
		return
	for c in mon_info.get_children():
		mon_info.remove_child(c)
		c.queue_free()
	if selected_mon < 0 or selected_mon >= Data.ROSTER.size():
		_label(mon_info, "Choose a Digimon above to access its encrypted memory files.", 14, MUTED)
		return
	var name: String = str(Data.ROSTER[selected_mon].stages[1])
	var count: int = Save.mon_count(selected_mon)
	_label(mon_info, "%s  //  %d OF 3 FILES DECRYPTED" % [name, count], 17, CYAN)
	if count == 0:
		_label(mon_info, "ACCESS DENIED  •  No memory files unlocked yet.", 14, MUTED)
	else:
		for k in count:
			var record := _card(mon_info, "%s.mon  /  RECORD %02d" % [name, k + 1], CYAN)
			_label(record, "Encrypted memory placeholder. Story lore has not been authored yet.", 14, WHITE)

# EXPEDITION
func build_exped() -> void:
	var v := page("Expedition")
	_section(v, "04  //  DARK AREA GATEWAY", "Confirm your mercenary and loadout before deploying into the three-night expedition.")
	var r: Dictionary = Data.ROSTER[sel]
	var merc := _card(v, "ACTIVE MERCENARY  //  %s" % r.stages[1], GOLD)
	_label(merc, "CLASS  %s     •     ATTRIBUTE  %s     •     TYPE  %s" % [r.cls, r.attr, r.type], 15, WHITE)
	_label(merc, "DEPLOYMENT FORM  %s  •  LEVEL 1" % r.stages[0], 14, CYAN)
	var equip := _card(v, "EQUIPMENT LOADOUT  //  %d / 3" % Save.equipped.size(), CYAN)
	_label(equip, "Change equipped items in the Equipment Vault.", 14, MUTED)
	if not MoveInfo.MOVES.has(sel):
		_label(equip, "NOTICE  •  Full moveset for this line is still in development.", 13, GOLD)
	var gateway := _card(v, "FALSE DRASIL  //  TARGET SELECTION", GOLD)
	drasil = OptionButton.new()
	drasil.custom_minimum_size = Vector2(280, 44)
	drasil.clip_text = true
	drasil.add_item("FALSE DRASIL 01   /   ANGEMON + DEVIMON")
	gateway.add_child(drasil)
	var go := Button.new()
	go.text = "▶  BEGIN EXPEDITION"
	go.custom_minimum_size = Vector2(280, 60)
	go.add_theme_font_size_override("font_size", 22)
	go.pressed.connect(start)
	gateway.add_child(go)

func start() -> void:
	Run.line = sel
	Run.speed = 1.0
	Run.xpm = 1.0
	get_tree().change_scene_to_file("res://scenes/run.tscn")

func _panel(fill: Color, edge: Color, border_size: int, padding: int = 10) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(border_size)
	box.set_corner_radius_all(9)
	box.set_content_margin_all(padding)
	return box

func _apply_ui_theme() -> void:
	var th := Theme.new()
	var normal := _panel(Color("#15396c"), Color("#4387bf"), 2)
	var hover := _panel(Color("#1c5594"), GOLD, 3)
	var selected := _panel(Color("#16345e"), GOLD, 3)
	th.set_stylebox("normal", "Button", normal)
	th.set_stylebox("hover", "Button", hover)
	th.set_stylebox("pressed", "Button", selected)
	th.set_stylebox("hover_pressed", "Button", selected)
	th.set_stylebox("focus", "Button", _panel(Color.TRANSPARENT, GOLD, 1))
	th.set_stylebox("disabled", "Button", _panel(Color("#24334e"), Color("#465979"), 1))
	th.set_color("font_color", "Button", WHITE)
	th.set_color("font_hover_color", "Button", GOLD)
	th.set_color("font_pressed_color", "Button", GOLD)
	th.set_color("font_color", "Label", WHITE)
	th.set_stylebox("tab_selected", "TabContainer", selected)
	th.set_stylebox("tab_hovered", "TabContainer", hover)
	th.set_stylebox("tab_unselected", "TabContainer", normal)
	th.set_color("font_selected_color", "TabContainer", GOLD)
	theme = th
