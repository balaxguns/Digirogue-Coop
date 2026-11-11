extends CanvasLayer
## In-run HUD and the Escape menu (Inventory / Moves / Quit Game), built entirely in code. g = the run script.
const TIERS := ["In-Training (Lv 1)", "Rookie (Lv 3)", "Champion (Lv 6)", "Ultimate (Lv 12)", "Mega (Lv 15)"]
var g
var lbl_name: Label
var lbl_hp: Label
var lbl_time: Label
var lbl_msg: Label
var lbl_boss: Label
var hp_bar: ProgressBar
var xp_bar: ProgressBar
var stam_bar: ProgressBar
var boss_bar: ProgressBar
var items_box: HBoxContainer
var cards_box: HBoxContainer
var mini: Control
var sig := ""
var menu: PanelContainer
var tabs: TabContainer
var inv_box: VBoxContainer
var moves_box: VBoxContainer
var quit_box: VBoxContainer
var moves_stage := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var tl := VBoxContainer.new()
	tl.position = Vector2(10, 8)
	add_child(tl)
	lbl_name = Label.new(); tl.add_child(lbl_name)
	hp_bar = ProgressBar.new(); hp_bar.custom_minimum_size = Vector2(220, 14); hp_bar.show_percentage = false; tl.add_child(hp_bar)
	xp_bar = ProgressBar.new(); xp_bar.custom_minimum_size = Vector2(220, 8); xp_bar.show_percentage = false; tl.add_child(xp_bar)
	stam_bar = ProgressBar.new(); stam_bar.custom_minimum_size = Vector2(220, 8); stam_bar.show_percentage = false; tl.add_child(stam_bar)
	lbl_hp = Label.new(); tl.add_child(lbl_hp)
	var tc := VBoxContainer.new()
	tc.position = Vector2(440, 8)
	tc.custom_minimum_size = Vector2(400, 0)
	add_child(tc)
	lbl_time = Label.new(); lbl_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; tc.add_child(lbl_time)
	lbl_msg = Label.new(); lbl_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; tc.add_child(lbl_msg)
	lbl_boss = Label.new(); lbl_boss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; tc.add_child(lbl_boss)
	boss_bar = ProgressBar.new(); boss_bar.custom_minimum_size = Vector2(400, 12); boss_bar.show_percentage = false; tc.add_child(boss_bar)
	items_box = HBoxContainer.new(); add_child(items_box)
	cards_box = HBoxContainer.new(); add_child(cards_box)
	mini = Control.new(); mini.custom_minimum_size = Vector2(150, 150); mini.size = Vector2(150, 150); mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mini.draw.connect(_draw_mini)
	add_child(mini)
	_build_menu()

func _slot(text: String, tip: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.tooltip_text = tip
	b.custom_minimum_size = Vector2(96, 44)
	b.focus_mode = Control.FOCUS_NONE
	b.gui_input.connect(cb)
	return b

func refresh() -> void:
	var P = g.P
	var vp := get_viewport().get_visible_rect().size
	items_box.position = Vector2(10, vp.y - 54)
	cards_box.position = Vector2(vp.x - 6 * 100 - 10, vp.y - 54)
	mini.position = Vector2(vp.x - 160, 8)
	var can_evo: bool = Data.stage_for_level(P.lv) > P.stage
	lbl_name.text = "%s  Lv %d%s   [Esc] Menu" % [g.nm(), P.lv, "   [E] Digivolve!" if can_evo else ""]
	hp_bar.max_value = P.mhp
	hp_bar.value = maxf(0.0, P.hp)
	xp_bar.max_value = Data.xp_needed(P.lv) if P.lv < 15 else 1
	xp_bar.value = P.xp if P.lv < 15 else 1
	stam_bar.max_value = 100.0
	stam_bar.value = P.stam
	stam_bar.modulate = Color(1.0, 0.4, 0.4) if P.stam_lock else Color(0.5, 1.0, 0.6)
	var sk := "Q %ds" % maxi(0, int(P.cd.q))
	if Kit.has_kit(P.line):
		var nm: Array = Kit.names(P.line, P.stage)
		sk = "%s (Q) %ds   %s (R) %ds" % [nm[1], maxi(0, int(P.cd.q)), nm[2], maxi(0, int(P.cd.r))]
	lbl_hp.text = "HP %d/%d   %s" % [int(P.hp), int(P.mhp), sk + Kit.extra(g)]
	lbl_time.text = g.time_text()
	lbl_msg.text = g.R.msg if g.R.msg_t > 0.0 else ""
	lbl_boss.visible = g.boss != null
	boss_bar.visible = g.boss != null
	if g.boss != null:
		lbl_boss.text = g.boss.name
		boss_bar.max_value = g.boss.mhp
		boss_bar.value = maxf(0.0, g.boss.hp)
	var s := str(P.items.map(func(i): return "%s%d" % [i.name, i.n])) + str(P.cards.map(func(c): return c.name))
	if s != sig:
		sig = s
		for c in items_box.get_children(): c.queue_free()
		for c in cards_box.get_children(): c.queue_free()
		for i in 3:
			var has: bool = i < P.items.size()
			var idx := i
			var txt := "%d: %s x%d" % [i + 1, P.items[i].name, P.items[i].n] if has else "%d: empty" % (i + 1)
			items_box.add_child(_slot(txt, (P.items[i].desc + "  Left click: use. Right click: drop one.") if has else "empty", func(ev):
				if ev is InputEventMouseButton and ev.pressed:
					if ev.button_index == MOUSE_BUTTON_LEFT: g.use_item(idx)
					elif ev.button_index == MOUSE_BUTTON_RIGHT: g.drop_item(idx)))
		for i in 6:
			var has: bool = i < P.cards.size()
			var idx := i
			cards_box.add_child(_slot(P.cards[i].name if has else "empty", (P.cards[i].desc + "  Right click: drop.") if has else "empty", func(ev):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT: g.drop_card(idx)))
	mini.queue_redraw()

func _draw_mini() -> void:
	if g.R.mode != "night":
		return
	var sz := 150.0
	var k: float = float(sz) / float(g.WORLD)
	mini.draw_rect(Rect2(0, 0, sz, sz), Color(0, 0, 0, 0.65))
	var cell := sz / float(g.GRID)
	for i in g.GRID * g.GRID:
		if g.R.fog[i] == 1:
			mini.draw_rect(Rect2((i % g.GRID) * cell, (i / g.GRID) * cell, cell + 0.5, cell + 0.5), Color(0.54, 0.49, 0.75, 0.35))
	mini.draw_arc(g.R.cpos * k, g.R.cr * k, 0, TAU, 48, Color("#c77dff"), 1.5)
	mini.draw_rect(Rect2(g.P.pos * k - Vector2(2, 2), Vector2(4, 4)), Color.WHITE)
	if g.boss != null:
		mini.draw_rect(Rect2(g.boss.pos * k - Vector2(2, 2), Vector2(4, 4)), Color("#ff5555"))

# ---------------------------------------------------------------- Escape menu
func _build_menu() -> void:
	menu = PanelContainer.new()
	menu.visible = false
	add_child(menu)
	tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(780, 500)
	menu.add_child(tabs)
	for n in ["Inventory", "Moves", "Quit Game"]:
		var sc := ScrollContainer.new()
		sc.name = n
		tabs.add_child(sc)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(v)
		if n == "Inventory": inv_box = v
		elif n == "Moves": moves_box = v
		else: quit_box = v

func toggle_menu(tab: int = 0) -> void:
	if menu.visible:
		close_menu()
		return
	moves_stage = g.P.stage
	rebuild_inv()
	rebuild_moves()
	rebuild_quit()
	tabs.current_tab = tab
	var vp := get_viewport().get_visible_rect().size
	menu.position = vp / 2.0 - Vector2(390, 250)
	menu.visible = true
	get_tree().paused = true

func close_menu() -> void:
	menu.visible = false
	get_tree().paused = false

func _unhandled_input(ev: InputEvent) -> void:
	if menu.visible and ((ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE) or ev.is_action_pressed("inventory")):
		close_menu()
		get_viewport().set_input_as_handled()

func _clear(box: Node) -> void:
	for c in box.get_children(): c.queue_free()

func _head(box: Node, t: String) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 18)
	box.add_child(l)

func _text(box: Node, t: String, col: Color = Color.WHITE, w: float = 700.0) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(w, 0)
	l.add_theme_color_override("font_color", col)
	box.add_child(l)
	return l

func _row(box: Node, title: String, desc: String, btns: Array) -> void:
	var row := HBoxContainer.new()
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text(col, title, Color("#ffd23d"), 480.0)
	_text(col, desc, Color.WHITE, 480.0)
	row.add_child(col)
	for b in btns:
		var bt := Button.new()
		bt.text = b[0]
		bt.pressed.connect(b[1])
		row.add_child(bt)
	box.add_child(row)
	box.add_child(HSeparator.new())

func _use(i: int) -> void:
	g.use_item(i)
	rebuild_inv()

func _drop_i(i: int) -> void:
	g.drop_item(i)
	rebuild_inv()

func _drop_c(i: int) -> void:
	g.drop_card(i)
	rebuild_inv()

func rebuild_inv() -> void:
	_clear(inv_box)
	var P = g.P
	_head(inv_box, "Equipment  %d/3  (permanent, cannot be dropped)" % P.eq.size())
	if P.eq.is_empty(): _row(inv_box, "Nothing equipped", "Equip gear in the hub before an expedition.", [])
	for e in P.eq:
		var d: Dictionary = Data.equip[e.id]
		_row(inv_box, "%s   [%s]" % [d.name, Data.RARITIES[d.rar]], d.desc, [])
	_head(inv_box, "Items  %d/3 slots  (each slot stacks up to 3; lost when the expedition ends)" % P.items.size())
	if P.items.is_empty(): _row(inv_box, "No items", "Pick up items from enemies and chests.", [])
	for i in P.items.size():
		var it: Dictionary = P.items[i]
		var idx: int = i
		_row(inv_box, "%s  x%d   [%s]" % [it.name, it.n, Data.RARITIES[it.rar]], it.desc, [["Use", func(): _use(idx)], ["Drop 1", func(): _drop_i(idx)]])
	_head(inv_box, "Option Cards  %d/6  (last for this expedition)" % P.cards.size())
	if P.cards.is_empty(): _row(inv_box, "No option cards", "Defeat enemies and open chests to find them.", [])
	for i in P.cards.size():
		var c: Dictionary = P.cards[i]
		var idx: int = i
		_row(inv_box, "%s   [%s]" % [c.name, Data.RARITIES[c.rar]], c.desc, [["Drop", func(): _drop_c(idx)]])

func _pick_stage(st: int) -> void:
	moves_stage = st
	rebuild_moves()

func rebuild_moves() -> void:
	_clear(moves_box)
	var P = g.P
	var r: Dictionary = Data.ROSTER[P.line]
	_head(moves_box, "%s line" % r.stages[1])
	_text(moves_box, "Class: %s   |   Attribute: %s   |   Typing: %s   |   Scaling: %s" % [r.cls, r.attr, r.type, "Intelligence" if Data.line_scaling(P.line) == "int" else "Physical (Attack)"])
	_text(moves_box, "Every move is %s-type. Click an evolution stage to see its moves." % r.type, Color("#9fe8ff"))
	var row := HBoxContainer.new()
	moves_box.add_child(row)
	for st in 5:
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = st == moves_stage
		b.text = "%s\n%s%s" % [TIERS[st], r.stages[st], "  (current)" if st == P.stage else ""]
		b.custom_minimum_size = Vector2(140, 56)
		var idx := st
		b.pressed.connect(func(): _pick_stage(idx))
		row.add_child(b)
	moves_box.add_child(HSeparator.new())
	_head(moves_box, "%s  -  %s" % [r.stages[moves_stage], TIERS[moves_stage]])
	_text(moves_box, "Attribute: %s   |   Typing: %s" % [r.attr, r.type], Color("#ffd23d"))
	var mv: Array = MoveInfo.get_moves(P.line, moves_stage)
	if mv.is_empty():
		_text(moves_box, "Moves not implemented yet for this line. It uses a default projectile attack (click) and a short shockwave (Q).")
	else:
		var kinds := ["Basic Attack", "Skill (Q)", "Ultimate (R)"]
		for k in 3:
			_row(moves_box, "%s: %s" % [kinds[k], mv[k][0]], mv[k][1], [])

func _quit_yes() -> void:
	menu.visible = false
	get_tree().paused = false
	g.end_run(false)

func rebuild_quit() -> void:
	_clear(quit_box)
	_head(quit_box, "Quit Game")
	_text(quit_box, "Exit the expedition and return to the hub? Items and option cards are lost, and nothing is rewarded for an abandoned run.")
	var row := HBoxContainer.new()
	quit_box.add_child(row)
	var yes := Button.new()
	yes.text = "Yes"
	yes.custom_minimum_size = Vector2(120, 44)
	yes.pressed.connect(_quit_yes)
	row.add_child(yes)
	var no := Button.new()
	no.text = "No"
	no.custom_minimum_size = Vector2(120, 44)
	no.pressed.connect(close_menu)
	row.add_child(no)
