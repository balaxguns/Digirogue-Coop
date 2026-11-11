class_name KitSlayer extends RefCounted
## Babydmon > Dracomon > Coredramon > Wingdramon > Slayerdramon (roster index 4). Physical scaling.
## g = the run script (scripts/run.gd). Called from kit.gd.

# [range, arc (radians), damage multiplier]
const BASIC := [[44.0, 1.6, 1.0], [52.0, 1.5, 1.1], [62.0, 1.4, 1.2], [62.0, 1.4, 1.3], [100.0, 1.8, 1.5]]

static func kv(g) -> Dictionary:
	var k: Dictionary = g.P.kv
	if not k.has("s_init"):
		k.s_init = true
		k.stacks = 0
		k.br = {}           # active breath that does not slow you
		k.seq_n = 0         # spheres left to fire
		k.seq_t = 0.0
		k.gs = 0            # spheres that have dealt damage this cast
		k.zones = []        # draconic trail on the ground
		k.zt = 0.0
		k.lastz = Vector2.ZERO
	return k

static func extra(g) -> String:
	var k := kv(g)
	var mx := 15 if g.P.stage == 4 else 10
	return "   Stacks %d/%d" % [k.stacks, mx]

static func ignite(g, e: Dictionary) -> void:
	e.burn = 4.0
	e.bd = g.atkv() * 0.3 + 2.0

static func flame_burn(g, e: Dictionary) -> void:
	if randf() < 0.2: ignite(g, e)

static func set_buff(g) -> void:
	var P = g.P
	var k := kv(g)
	for b in P.tb:
		if b.get("tag", "") == "stack":
			b.t = 6.0
			b.fx = {"atk": 0.03 * k.stacks}
			g.recalc()
			return
	P.tb.append({"fx": {"atk": 0.03 * k.stacks}, "t": 6.0, "tag": "stack"})
	g.recalc()

static func stack(g, _e: Dictionary) -> void:
	var k := kv(g)
	k.stacks = mini(k.stacks + 1, 15 if g.P.stage == 4 else 10)
	set_buff(g)

static func refresh(g) -> void:
	for b in g.P.tb:
		if b.fx.has("atk"): b.t = maxf(b.t, 6.0)

static func gs_up(g, n: int) -> void:
	if n > 0: kv(g).gs += 1

static func breath_tick(g, br: Dictionary) -> void:
	g.cone(br.rng, br.arc, g.atkv() * br.mult, func(e): KitSlayer.ignite(g, e), br.col, "phys", false, true)

static func start_breath(g, dur: float, rng: float, arc: float, mult: float, col: Color, slow: bool) -> void:
	var P = g.P
	var k := kv(g)
	refresh(g)
	var br := {"t": dur, "k": 0.0, "rng": rng, "arc": arc, "mult": mult, "col": col}
	if slow:
		P.ch = {"t": dur, "k": 0.0, "f": func(): KitSlayer.breath_tick(g, br), "end": Callable()}
	else:
		k.br = br

static func fire_sphere(g) -> void:
	var k := kv(g)
	var A: float = g.atkv()
	var bonus: float = 1.0 + 0.4 * k.gs
	if g.P.stage == 1:
		g.proj({"sp": 780.0, "life": 1.1, "r": 11.0, "kind": "phys", "dmg": A * 2.2 * bonus, "hf": func(_e): KitSlayer.gs_up(g, 1), "col": Color("#ff8a3d")})
	else:
		g.proj({"sp": 700.0, "life": 1.2, "r": 17.0, "kind": "phys", "dmg": A * 2.4 * bonus, "ex": 110.0, "exd": A * 1.6 * bonus, "end_ex": true, "af": func(cnt = 0): KitSlayer.gs_up(g, cnt), "col": Color("#ff6a3d")})

static func tick(g, dt: float) -> void:
	var P = g.P
	var k := kv(g)
	if k.stacks > 0:
		var alive := false
		for b in P.tb:
			if b.get("tag", "") == "stack": alive = true
		if not alive: k.stacks = 0
	if not k.br.is_empty():
		k.br.t -= dt
		k.br.k -= dt
		if k.br.k <= 0.0 and k.br.t > 0.0:
			k.br.k = 0.25
			breath_tick(g, k.br)
		if k.br.t <= 0.0: k.br = {}
	if k.seq_n > 0:
		k.seq_t -= dt
		if k.seq_t <= 0.0:
			k.seq_t = 0.35
			k.seq_n -= 1
			fire_sphere(g)
	if P.dash > 0.0 and (P.dk == "lance" or P.dk == "tenryu"):
		if k.lastz == Vector2.ZERO or k.lastz.distance_to(P.pos) > 40.0:
			k.zones.append({"pos": P.pos, "r": 40.0, "t": 4.0})
			k.lastz = P.pos
	else:
		k.lastz = Vector2.ZERO
	for z in k.zones: z.t -= dt
	k.zones = k.zones.filter(func(z): return z.t > 0.0)
	k.zt -= dt
	if k.zt <= 0.0:
		k.zt = 0.3
		for e in g.foes():
			for z in k.zones:
				if z.pos.distance_to(e.pos) < z.r + e.r:
					g.hit_enemy(e, g.atkv() * 0.5, P, false, "phys")
					break

static func draw(g) -> void:
	var k := kv(g)
	for z in k.zones:
		g.draw_circle(z.pos, z.r, Color(1.0, 0.45, 0.15, 0.22))

static func basic(g) -> void:
	var t: Array = BASIC[g.P.stage]
	g.cone(t[0], t[1], g.atkv() * t[2], func(e): KitSlayer.stack(g, e), Color.WHITE, "phys", true)

static func skill(g, n: int) -> void:
	var P = g.P
	var k := kv(g)
	var st: int = P.stage
	var A: float = g.atkv()
	if n == 1:
		match st:
			0:  # Petite Flame
				P.cd.q = 4.0
				g.proj({"sp": 650.0, "life": 1.4, "r": 8.0, "kind": "phys", "elem": true, "dmg": A * 1.6, "ex": 70.0, "exd": A * 1.0, "end_ex": true, "xf": func(e): KitSlayer.flame_burn(g, e), "col": Color("#ff8a3d")})
			1:  # Baby Breath
				P.cd.q = 9.0
				start_breath(g, 3.0, 260.0, 0.5, 0.7, Color("#ff8a3d"), true)
			2:  # Blue Flare Breath
				P.cd.q = 9.0
				start_breath(g, 3.0, 280.0, 0.5, 0.9, Color("#4dc3ff"), true)
			3:  # Sonic Lance
				P.cd.q = 8.0
				refresh(g)
				g.rush(900.0, 0.35, "lance", 3.0, Callable(), false, 28.0)
			_:  # Tenryu Slash
				P.cd.q = 8.0
				refresh(g)
				g.fx.append({"pos": P.pos, "cone": true, "a": P.face, "rng": 180.0, "arc": 1.6, "t": 0.25, "col": Color("#ff6a3d")})
				g.rush(560.0, 0.25, "tenryu", 3.6, Callable(), false, 70.0)
	else:
		match st:
			0:  # Baby Flame
				P.cd.r = 18.0
				start_breath(g, 3.0, 320.0, 0.5, 1.0, Color("#ff8a3d"), true)
			1, 2:  # G Shurunen / G Shurunen II: 3 spheres in a row
				P.cd.r = 16.0 if st == 1 else 18.0
				k.gs = 0
				k.seq_n = 3
				k.seq_t = 0.0
			3:  # Blaze Sonic Breath (no slowdown)
				P.cd.r = 20.0
				start_breath(g, 3.0, 360.0, 0.5, 1.2, Color("#4dc3ff"), false)
			_:  # Shoryu Slash
				P.cd.r = 18.0
				refresh(g)
				g.cone(380.0, 1.3, A * 6.0, func(e): KitSlayer.ignite(g, e), Color("#ff4d1a"), "phys", false, true)
