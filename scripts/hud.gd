extends CanvasLayer
## In-run HUD and the live field terminal (Equipment / Consumables / Option Cards / Moves / Quit Game).
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
var equip_box: VBoxContainer
var consumables_box: VBoxContainer
var option_box: VBoxContainer
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

# ---------------------------------------------------------------- Translucent in-run command overlay
const UI_GOLD := Color("#ffcf36")
const UI_CYAN := Color("#62d7ff")
const UI_MUTED := Color("#b5cbe4")
var menu_shell: MarginContainer
var menu_dim: ColorRect

func _ui_panel(fill: Color, edge: Color, pad: int = 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = edge
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(pad)
	return sb

func _build_menu() -> void:
	# A CanvasLayer renders above the game. Only the overlay is transparent;
	# the expedition continues updating and remains visible underneath.
	menu_dim = ColorRect.new()
	menu_dim.color = Color(0.015, 0.04, 0.12, 0.12)
	menu_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_dim.visible = false
	add_child(menu_dim)
	menu_shell = MarginContainer.new()
	menu_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_shell.add_theme_constant_override("margin_left", 16)
	menu_shell.add_theme_constant_override("margin_right", 16)
	menu_shell.add_theme_constant_override("margin_top", 74)
	menu_shell.add_theme_constant_override("margin_bottom", 76)
	menu_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_shell.visible = false
	add_child(menu_shell)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_shell.add_child(center)
	menu = PanelContainer.new()
	menu.custom_minimum_size = Vector2(0, 0)
	menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu.add_theme_stylebox_override("panel", _ui_panel(Color(0.035, 0.105, 0.23, 0.77), Color("#4aabdb"), 12))
	center.add_child(menu)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 9)
	menu.add_child(body)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	body.add_child(header)
	var title := Label.new()
	title.text = "EXPEDITION  //  FIELD TERMINAL"
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", UI_GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "CLOSE  [ESC]"
	close.custom_minimum_size = Vector2(132, 34)
	close.pressed.connect(close_menu)
	header.add_child(close)
	tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(740, 340)
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_stylebox_override("panel", _ui_panel(Color(0.045, 0.14, 0.29, 0.64), Color("#4387bf"), 10))
	body.add_child(tabs)
	for n in ["Equipment", "Consumables", "Option Cards", "Moves", "Quit Game"]:
		var sc := ScrollContainer.new()
		sc.name = n
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(sc)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 7)
		sc.add_child(v)
		if n == "Equipment": equip_box = v
		elif n == "Consumables": consumables_box = v
		elif n == "Option Cards": option_box = v
		elif n == "Moves": moves_box = v
		else: quit_box = v
	var foot := Label.new()
	foot.text = "LIVE EXPEDITION  •  THE WORLD CONTINUES WHILE THIS TERMINAL IS OPEN"
	foot.add_theme_font_size_override("font_size", 11)
	foot.add_theme_color_override("font_color", UI_CYAN)
	body.add_child(foot)
	var th := Theme.new()
	th.set_stylebox("normal", "Button", _ui_panel(Color(0.08, 0.23, 0.43, 0.85), Color("#4387bf"), 7))
	th.set_stylebox("hover", "Button", _ui_panel(Color(0.12, 0.32, 0.54, 0.94), UI_GOLD, 7))
	th.set_stylebox("pressed", "Button", _ui_panel(Color(0.09, 0.25, 0.44, 0.95), UI_GOLD, 7))
	th.set_stylebox("focus", "Button", _ui_panel(Color.TRANSPARENT, UI_GOLD, 1))
	th.set_color("font_color", "Button", Color("#e9f5ff"))
	th.set_color("font_hover_color", "Button", UI_GOLD)
	th.set_stylebox("tab_selected", "TabContainer", _ui_panel(Color(0.09, 0.26, 0.47, 0.94), UI_GOLD, 8))
	th.set_stylebox("tab_unselected", "TabContainer", _ui_panel(Color(0.07, 0.17, 0.33, 0.80), Color("#4387bf"), 8))
	th.set_color("font_selected_color", "TabContainer", UI_GOLD)
	menu.theme = th

func toggle_menu(tab: int = 0) -> void:
	if menu_shell.visible:
		close_menu()
		return
	moves_stage = g.P.stage
	rebuild_inv()
	rebuild_moves()
	rebuild_quit()
	tabs.current_tab = tab
	# Never pause the world for an inventory inspection.
	menu_dim.visible = true
	menu_shell.visible = true
	menu.visible = true

func close_menu() -> void:
	menu_shell.visible = false
	menu_dim.visible = false

func _unhandled_input(ev: InputEvent) -> void:
	if menu_shell.visible and ((ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE) or ev.is_action_pressed("inventory")):
		close_menu()
		get_viewport().set_input_as_handled()

func _clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()

func _head(box: Node, t: String) -> void:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", UI_GOLD)
	box.add_child(l)

func _text(box: Node, t: String, col: Color = Color.WHITE, w: float = 0.0) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", col)
	box.add_child(l)
	return l

func _row(box: Node, title: String, desc: String, btns: Array) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _ui_panel(Color(0.06, 0.16, 0.33, 0.68), Color(0.23, 0.49, 0.72, 0.85), 7))
	box.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	_text(col, title, UI_CYAN)
	_text(col, desc, Color("#e1ebf8"))
	for b in btns:
		var bt := Button.new()
		bt.text = b[0]
		bt.custom_minimum_size = Vector2(78, 34)
		bt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bt.pressed.connect(b[1])
		row.add_child(bt)

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
	rebuild_equipment()
	rebuild_consumables()
	rebuild_option_cards()

func rebuild_equipment() -> void:
	_clear(equip_box)
	var P = g.P
	_head(equip_box, "EQUIPMENT  //  %d / 3" % P.eq.size())
	_text(equip_box, "Permanent equipment selected at the Mallow hub. Equipment cannot be dropped during expeditions.", UI_MUTED)
	if P.eq.is_empty():
		_row(equip_box, "No equipment equipped", "Equip permanent gear at the Mallow hub.", [])
	for e in P.eq:
		var d: Dictionary = Data.equip[e.id]
		_row(equip_box, "%s  •  %s" % [d.name, Data.RARITIES[d.rar]], d.desc, [])

func rebuild_consumables() -> void:
	_clear(consumables_box)
	var P = g.P
	_head(consumables_box, "CONSUMABLE ITEMS  //  %d / 3 SLOTS" % P.items.size())
	_text(consumables_box, "Each slot holds up to three items. Consumables are lost when the expedition ends.", UI_MUTED)
	if P.items.is_empty():
		_row(consumables_box, "No consumables", "Find items from enemies and chests.", [])
	for i in P.items.size():
		var it: Dictionary = P.items[i]
		var idx: int = i
		_row(consumables_box, "%s  ×%d  •  %s" % [it.name, it.n, Data.RARITIES[it.rar]], it.desc, [["USE", func(): _use(idx)], ["DROP", func(): _drop_i(idx)]])

func rebuild_option_cards() -> void:
	_clear(option_box)
	var P = g.P
	_head(option_box, "OPTION CARDS  //  %d / 6" % P.cards.size())
	_text(option_box, "Cards provide expedition-only bonuses. Dropping a card removes its effects.", UI_MUTED)
	if P.cards.is_empty():
		_row(option_box, "No option cards", "Defeat enemies and open chests to discover cards.", [])
	for i in P.cards.size():
		var c: Dictionary = P.cards[i]
		var idx: int = i
		_row(option_box, "%s  •  %s" % [c.name, Data.RARITIES[c.rar]], c.desc, [["DROP", func(): _drop_c(idx)]])

func _pick_stage(st: int) -> void:
	moves_stage = st
	rebuild_moves()

func rebuild_moves() -> void:
	_clear(moves_box)
	var P = g.P
	var r: Dictionary = Data.ROSTER[P.line]
	_head(moves_box, "MERCENARY  //  %s" % r.stages[1])
	_text(moves_box, "%s CLASS  •  %s ATTRIBUTE  •  %s TYPE" % [r.cls, r.attr, r.type], UI_MUTED)
	var picker := OptionButton.new()
	picker.custom_minimum_size = Vector2(250, 36)
	for st in 5:
		picker.add_item("%s  •  %s%s" % [r.stages[st], ["In-Training", "Rookie", "Champion", "Ultimate", "Mega"][st], "  (CURRENT)" if st == P.stage else ""], st)
	picker.select(moves_stage)
	picker.item_selected.connect(_pick_stage)
	moves_box.add_child(picker)
	_head(moves_box, "STAGE DATA  //  %s" % r.stages[moves_stage])
	_text(moves_box, "%s  •  %s-type abilities" % [TIERS[moves_stage], r.type], UI_MUTED)
	var mv: Array = MoveInfo.get_moves(P.line, moves_stage)
	if mv.is_empty():
		_row(moves_box, "Moves pending", "Default projectile attack and short-range shockwave.", [])
	else:
		var kinds := ["BASIC ATTACK  /  CLICK", "SPECIAL SKILL  /  Q", "ULTIMATE  /  R"]
		for k in mini(3, mv.size()):
			_row(moves_box, "%s  •  %s" % [kinds[k], mv[k][0]], str(mv[k][1]), [])

func _quit_yes() -> void:
	close_menu()
	g.end_run(false)

func rebuild_quit() -> void:
	_clear(quit_box)
	_head(quit_box, "ABANDON EXPEDITION")
	_text(quit_box, "Return to the hub? Items and option cards are lost, and an abandoned run earns no rewards.", UI_MUTED)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	quit_box.add_child(row)
	var yes := Button.new()
	yes.text = "ABANDON RUN"
	yes.custom_minimum_size = Vector2(150, 42)
	yes.pressed.connect(_quit_yes)
	row.add_child(yes)
	var no := Button.new()
	no.text = "CONTINUE"
	no.custom_minimum_size = Vector2(140, 42)
	no.pressed.connect(close_menu)
	row.add_child(no)
