extends Control
## Mallow, the hub, with clickable tabs. All UI is built in code.
const STAT_NAMES := {"def": "Defense", "int": "Intelligence", "atk": "Attack", "wis": "Wisdom", "hp": "Max HP", "spd": "Move speed"}
const TIERS := ["In-Training (Lv 1)", "Rookie (Lv 3)", "Champion (Lv 6)", "Ultimate (Lv 12)", "Mega (Lv 15)"]
var sel := 2
var tabs: TabContainer
var pages := {}
var mon_info: Label
var core_lbl: Label
var drasil: OptionButton

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	sel = Run.line
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var top := HBoxContainer.new()
	root.add_child(top)
	var t := Label.new()
	t.text = "Mallow  (a pocket dimension where time does not exist)"
	t.add_theme_font_size_override("font_size", 22)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	core_lbl = Label.new()
	top.add_child(core_lbl)
	var back := Button.new()
	back.text = "Title screen"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/title.tscn"))
	top.add_child(back)
	if not Run.last_result.is_empty():
		var r: Dictionary = Run.last_result
		var l := Label.new()
		l.text = "%s: reached Lv %d as %s, nights cleared %d/2, Digicore earned %d, equipment: %s" % ["EXPEDITION COMPLETE" if r.win else "EXPEDITION FAILED", r.lv, r.name, r.cleared, r.core, ", ".join(PackedStringArray(r.got))]
		l.add_theme_color_override("font_color", Color("#ffd23d"))
		root.add_child(l)
		Run.last_result = {}
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)
	for n in ["Mercenary Digimon", "Equipment", ".mon Files", "Expedition"]:
		var sc := ScrollContainer.new()
		sc.name = n
		tabs.add_child(sc)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(v)
		pages[n] = v
	build_all()

func build_all() -> void:
	core_lbl.text = "Digicore: %d   " % Save.core
	build_digi()
	build_equip()
	build_mon()
	build_exped()

func page(n: String) -> VBoxContainer:
	var v: VBoxContainer = pages[n]
	for c in v.get_children(): c.queue_free()
	return v

func lbl(parent: Node, text: String, size: int = 14, col: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(900, 0)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l

func grid(parent: Node, cols: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	parent.add_child(g)
	return g

# ---------------------------------------------------------------- Mercenary Digimon
func build_digi() -> void:
	var v := page("Mercenary Digimon")
	lbl(v, "Click a Digimon to see its evolution line and moves. The selected Digimon is the one you take on the expedition.")
	var g := grid(v, 4)
	for i in Data.ROSTER.size():
		var r: Dictionary = Data.ROSTER[i]
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = i == sel
		b.text = "%s (%s)" % [r.stages[1], r.cls]
		b.custom_minimum_size = Vector2(230, 40)
		var idx := i
		b.pressed.connect(func():
			sel = idx
			build_digi()
			build_exped())
		g.add_child(b)
	v.add_child(HSeparator.new())
	var r: Dictionary = Data.ROSTER[sel]
	lbl(v, "%s line   |   Class: %s   |   Attribute: %s   |   Typing: %s" % [r.stages[1], r.cls, r.attr, r.type], 18, Color("#ffd23d"))
	var pp: Array = Data.CLASS_PASSIVE[r.cls]
	lbl(v, "Passive: %s (+%d%% %s). Cannot be changed." % [pp[0], int(pp[2] * 100.0), STAT_NAMES.get(pp[1], pp[1])])
	lbl(v, "Damage scaling: %s (every move in this line). Every move is %s-type, so type advantage and %s damage bonuses apply to all of them." % [("Intelligence" if Data.line_scaling(sel) == "int" else "Physical (Attack)"), r.type, r.type])
	var chain: Array = []
	for st in 5: chain.append("%s (%s)" % [r.stages[st], TIERS[st]])
	lbl(v, "Evolution line: " + " > ".join(PackedStringArray(chain)))
	v.add_child(HSeparator.new())
	for st in 5:
		lbl(v, "%s  -  %s" % [r.stages[st], TIERS[st]], 16, Color("#7fd8ff"))
		var mv: Array = MoveInfo.get_moves(sel, st)
		if mv.is_empty():
			lbl(v, "     Moves not implemented yet. This line uses a default projectile attack (click) and a short shockwave (Q).")
		else:
			var kinds := ["Basic Attack", "Skill (Q)", "Ultimate (R)"]
			for k in 3: lbl(v, "     %s - %s: %s" % [kinds[k], mv[k][0], mv[k][1]])

# ---------------------------------------------------------------- Equipment
func build_equip() -> void:
	var v := page("Equipment")
	lbl(v, "Collected equipment: %d.  Equipped: %d/3.  Click a piece to equip or unequip it. Equipment is permanent and cannot be dropped during a run." % [Save.owned.size(), Save.equipped.size()], 14)
	var g := grid(v, 3)
	var list: Array = Save.owned.duplicate()
	list.sort_custom(func(a, b): return Data.equip[a.id].rar > Data.equip[b.id].rar)
	for o in list:
		var d: Dictionary = Data.equip[o.id]
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = Save.equipped.has(int(o.u))
		b.text = "%s  [%s]\n%s" % [d.name, Data.RARITIES[d.rar], d.desc]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(300, 80)
		var u := int(o.u)
		b.pressed.connect(func():
			if Save.equipped.has(u): Save.equipped.erase(u)
			elif Save.equipped.size() < 3: Save.equipped.append(u)
			Save.save_game()
			build_equip())
		g.add_child(b)

# ---------------------------------------------------------------- .mon files
func build_mon() -> void:
	var v := page(".mon Files")
	lbl(v, "Unlock memories of the past by progressing with a Digimon: reach Champion, reach Ultimate, win a run, or find one on an expedition. Click a Digimon to read its files.")
	var g := grid(v, 4)
	for i in Data.ROSTER.size():
		var idx := i
		var b := Button.new()
		b.text = "%s (%s): %d/3" % [Data.ROSTER[i].stages[1], Data.ROSTER[i].cls, Save.mon_count(i)]
		b.custom_minimum_size = Vector2(230, 40)
		b.pressed.connect(func():
			var n := Save.mon_count(idx)
			var out: Array = []
			for k in n: out.append("%s.mon %d: placeholder memory. Replace with your lore." % [Data.ROSTER[idx].stages[1], k + 1])
			mon_info.text = "No files unlocked yet." if n == 0 else "\n".join(PackedStringArray(out)))
		g.add_child(b)
	v.add_child(HSeparator.new())
	mon_info = lbl(v, "Select a Digimon above.")

# ---------------------------------------------------------------- Expedition
func build_exped() -> void:
	var v := page("Expedition")
	var r: Dictionary = Data.ROSTER[sel]
	lbl(v, "Mercenary: %s (%s class, %s / %s), starts as %s." % [r.stages[1], r.cls, r.attr, r.type, r.stages[0]], 16)
	lbl(v, "Equipped: %d/3 (change in the Equipment tab)." % Save.equipped.size())
	if not MoveInfo.MOVES.has(sel):
		lbl(v, "Note: this line does not have its full moveset yet.", 14, Color("#ff9a4d"))
	var row := HBoxContainer.new()
	v.add_child(row)
	drasil = OptionButton.new()
	drasil.add_item("False Drasil 1: Angemon / Devimon")
	row.add_child(drasil)
	var go := Button.new()
	go.text = "Begin expedition"
	go.pressed.connect(start)
	row.add_child(go)

func start() -> void:
	Run.line = sel
	Run.speed = 1.0
	Run.xpm = 1.0
	get_tree().change_scene_to_file("res://scenes/run.tscn")
