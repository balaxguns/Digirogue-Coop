class_name KitGaruru extends RefCounted
## Tsunomon > Gabumon > Garurumon > WereGarurumon > MetalGarurumon (roster index 1). Physical scaling.
## g = the run script (scripts/run.gd). Called from kit.gd.

const BASIC := [[42.0, 1.6, 1.0], [52.0, 1.5, 1.1], [62.0, 1.4, 1.2], [72.0, 1.6, 1.3], [90.0, 2.2, 1.5]]

static func kv(g) -> Dictionary:
	var k: Dictionary = g.P.kv
	if not k.has("g_init"):
		k.g_init = true
		k.bb_t = 0.0        # Beast Blitz recast window
		k.bb_o = Vector2.ZERO
		k.ck_t = 0.0        # Circle Kick recast window
		k.ck_n = 0
		k.miss = 0          # Grand Cross Freezer missiles left
		k.mt = 0.0
		k.mwin = 0.0
	return k

static func extra(g) -> String:
	var k := kv(g)
	var st: int = g.P.stage
	if st == 2 and k.bb_t > 0.0: return "   RECAST Q %.1fs" % k.bb_t
	if st == 3 and k.ck_t > 0.0: return "   RECAST Q x%d" % (2 - k.ck_n)
	if st == 4 and k.miss > 0: return "   Missiles %d" % k.miss
	return ""

static func tick(g, dt: float) -> void:
	var P = g.P
	var k := kv(g)
	if k.bb_t > 0.0:
		k.bb_t -= dt
		if k.bb_t <= 0.0: P.cd.q = maxf(P.cd.q, 7.0)
	if k.ck_t > 0.0:
		k.ck_t -= dt
		if k.ck_t <= 0.0: P.cd.q = maxf(P.cd.q, 8.0)
	if k.miss > 0:
		k.mwin -= dt
		k.mt -= dt
		if k.mwin <= 0.0:
			k.miss = 0
		elif k.mt <= 0.0:
			k.mt = 0.1
			var tg: Array = g.foes().filter(func(x): return x.pos.distance_to(P.pos) < 450.0 + x.r)
			if not tg.is_empty():
				k.miss -= 1
				var t: Dictionary = tg.pick_random()
				g.fx.append({"line_a": P.pos, "line_b": t.pos, "t": 0.2, "col": Color("#9fe8ff"), "w": 5.0})
				g.hit_enemy(t, g.atkv() * 0.9, P, g.crit(), "phys", false, true)
				if randf() < 0.10: g.stun_e(t, 3.0)

# ---- small effect helpers (kept static so lambdas can call them)
static func fang(g, e: Dictionary) -> void:
	if randf() < 0.05: g.stun_e(e, 2.0)

static func knuckle(g, e: Dictionary) -> void:
	if randf() < 0.10: g.ddown(e, 0.2, 6.0)

static func def_roll(g, e: Dictionary) -> void:
	if randf() < 0.10: g.ddown(e, 0.2, 6.0)

static func freeze_roll(g, e: Dictionary, ch: float) -> void:
	if randf() < ch: g.stun_e(e, 3.0)

static func ignite(g, e: Dictionary) -> void:
	e.burn = 4.0
	e.bd = g.atkv() * 0.3 + 2.0

static func quake(g) -> void:
	var P = g.P
	for e in g.foes():
		if P.pos.distance_to(e.pos) < 140.0 + e.r: g.hit_enemy(e, g.atkv() * 1.8, P, g.crit(), "phys")
	g.fx.append({"pos": P.pos, "ring": 140.0, "t": 0.35, "col": Color("#9fe8ff")})

static func basic(g) -> void:
	var t: Array = BASIC[g.P.stage]
	var fn := Callable()
	if g.P.stage == 2: fn = func(e): KitGaruru.fang(g, e)
	elif g.P.stage == 3: fn = func(e): KitGaruru.knuckle(g, e)
	g.cone(t[0], t[1], g.atkv() * t[2], fn, Color.WHITE, "phys", true, g.P.stage == 2)

static func beast_blitz(g, k: Dictionary) -> void:
	var P = g.P
	var fn := func(e): KitGaruru.def_roll(g, e)
	if k.bb_t > 0.0:  # recast: dash back to where you first cast it
		var to: Vector2 = k.bb_o - P.pos
		var t: float = clampf(to.length() / 900.0, 0.1, 0.6)
		k.bb_t = 0.0
		P.cd.q = 7.0
		P.face = to.angle()
		g.rush(900.0, t, "blitz", 2.2, fn)
		P.ch = {"t": t, "k": 9.0, "f": Callable(), "end": func(): KitGaruru.quake(g)}
	else:
		k.bb_o = P.pos
		k.bb_t = 3.0
		P.cd.q = 0.4
		g.rush(800.0, 0.3, "blitz", 2.2, fn)
		P.ch = {"t": 0.3, "k": 9.0, "f": Callable(), "end": func(): KitGaruru.quake(g)}

static func circle_kick(g, k: Dictionary) -> void:
	var P = g.P
	if k.ck_t > 0.0 and k.ck_n < 2:  # recast: dash forward and kick again (twice)
		k.ck_n += 1
		P.cd.q = 0.4
		g.rush(700.0, 0.22, "kick", 2.4, Callable(), false, 30.0)
		if k.ck_n >= 2:
			k.ck_t = 0.0
			P.cd.q = 8.0
	else:
		k.ck_t = 5.0
		k.ck_n = 0
		P.cd.q = 0.4
		P.inv = maxf(P.inv, 0.4)
		g.cone(130.0, 1.6, g.atkv() * 2.6, Callable(), Color("#ffd23d"), "phys")

static func skill(g, n: int) -> void:
	var P = g.P
	var k := kv(g)
	var st: int = P.stage
	var A: float = g.atkv()
	if n == 1:
		match st:
			0:  # Frothy Spit
				P.cd.q = 5.0
				g.cone(220.0, 1.1, A * 2.4, func(e): g.ddown(e, 0.2, 6.0), Color("#c8f0ff"), "phys")
			1:  # Petite Horn
				P.cd.q = 6.0
				g.rush(760.0, 0.3, "horn", 2.0, func(_e): g.add_tbuff({"atk": 0.03, "def": 0.03}, 6.0), false, 20.0)
			2:
				beast_blitz(g, k)
			3:
				circle_kick(g, k)
			_:  # Cocytus Breath
				P.cd.q = 7.0
				g.beam(520.0, 80.0, A * 2.8, "phys", func(e): KitGaruru.freeze_roll(g, e, 0.2), Color("#9fe8ff"), false, true)
	else:
		match st:
			0:  # Mammal Spiral
				P.cd.r = 16.0
				g.rush(850.0, 0.45, "spiral", 2.8, func(e): g.ddown(e, 0.25, 6.0), false, 24.0)
			1:  # Blue Blaster
				P.cd.r = 16.0
				g.proj({"sp": 520.0, "life": 0.9, "r": 14.0, "kind": "phys", "dmg": A * 3.5, "hf": func(e): KitGaruru.ignite(g, e), "col": Color("#4dc3ff")})
			2:  # Howling Blaster
				P.cd.r = 18.0
				g.proj({"sp": 560.0, "life": 1.2, "r": 20.0, "kind": "phys", "dmg": A * 4.5, "hf": func(e): KitGaruru.ignite(g, e), "col": Color("#4dc3ff")})
			3:  # Kaiser Nail
				P.cd.r = 20.0
				P.inv = maxf(P.inv, 0.6)
				P.at = 0.35
				for e in g.foes():
					if P.pos.distance_to(e.pos) < 220.0 + e.r:
						g.hit_enemy(e, A * 5.0, P, g.crit(), "phys")
						if randf() < 0.15: g.stun_e(e, 2.0)
				g.fx.append({"pos": P.pos, "ring": 220.0, "t": 0.35, "col": Color("#ffd23d")})
			_:  # Grand Cross Freezer: 20 missiles over ~2s, no slow while casting
				P.cd.r = 28.0
				k.miss = 20
				k.mt = 0.0
				k.mwin = 7.0
				g.txt(P.pos + Vector2(0, -30), "Grand Cross Freezer!", Color("#9fe8ff"))
