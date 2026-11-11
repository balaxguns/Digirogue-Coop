class_name KitDiablo extends RefCounted
## Kuramon > Keramon > Chrysalimon > Infermon > Diablomon (roster index 11). Every move scales with Intelligence.
## g = the run script (scripts/run.gd). Called from kit.gd.

static func kv(g) -> Dictionary:
	var k: Dictionary = g.P.kv
	if not k.has("d_init"):
		k.d_init = true
		k.ult_bonus = 0.0
		k.charging = false
		k.charge = 0.0
		k.mis = false
	return k

static func iv(g) -> float:
	return g.P.st["int"]

static func extra(g) -> String:
	var k := kv(g)
	if k.charging: return "   Charge %d%%" % int(k.charge / 1.5 * 100.0)
	if g.P.stage == 4 and k.ult_bonus > 0.0: return "   Next ult +30%"
	return ""

static func tick(g, dt: float) -> void:
	var P = g.P
	var k := kv(g)
	if k.charging:
		if P.ch == null:
			k.charging = false
		else:
			k.charge = minf(1.5, k.charge + dt)
			if not Input.is_action_pressed("ultimate"): fire_grenade(g)

static func wis_roll(g, e: Dictionary, ch: float, amt: float = 0.15) -> void:
	if randf() < ch: g.wdown(e, amt, 8.0)

static func palm(g, e: Dictionary) -> void:
	if randf() < 0.30: g.wdown(e, 0.15, 8.0)
	g.P.cd.r = maxf(0.0, g.P.cd.r - 1.0)

static func spiral_hit(g, _e: Dictionary) -> void:
	g.P.cd.r = maxf(0.0, g.P.cd.r - 1.5)

static func boom(g, rad: float, dmg: float, col: Color) -> void:
	var P = g.P
	for e in g.foes():
		if P.pos.distance_to(e.pos) < rad + e.r: g.hit_enemy(e, dmg, P, g.crit(), "spec")
	g.fx.append({"pos": P.pos, "ring": rad, "t": 0.4, "col": col})

static func mis_boom(g, _e: Dictionary) -> void:
	var k := kv(g)
	if k.mis: return
	k.mis = true
	boom(g, 240.0, iv(g) * 6.0, Color("#ff3df0"))

static func mis_end(g) -> void:
	var k := kv(g)
	if k.mis: return
	k.mis = true
	boom(g, 240.0, iv(g) * 6.0, Color("#ff3df0"))

static func fire_grenade(g) -> void:
	var P = g.P
	var k := kv(g)
	if not k.charging: return
	k.charging = false
	var c: float = k.charge
	var d: float = iv(g) * (3.0 + 2.5 * c)
	P.cd.r = 18.0
	P.ch = null
	g.proj({"sp": 640.0, "life": 1.4, "r": 18.0, "dmg": d, "ex": 110.0 + 70.0 * c, "exd": d, "end_ex": true, "col": Color("#ff6a3d")})

static func basic(g) -> void:
	var I := iv(g)
	match g.P.stage:
		0:  # Light Charge
			g.cone(42.0, 1.6, I * 1.0, Callable(), Color.WHITE, "spec", true)
		1:  # Crazy Bullet
			g.proj({"sp": 650.0, "life": 0.55, "r": 8.0, "dmg": I * 1.0, "basic": true, "col": Color("#b06bff"), "hf": func(e): KitDiablo.wis_roll(g, e, 0.25, 0.10)})
		2:  # Data Crasher (piercing tentacles)
			g.beam(170.0, 30.0, I * 1.2, "spec", func(e): KitDiablo.wis_roll(g, e, 0.15), Color("#9b3dff"), true)
		3:  # Cocoon Attack
			g.cone(75.0, 1.2, I * 1.1, func(e): KitDiablo.wis_roll(g, e, 0.20), Color.WHITE, "spec", true)
		_:  # Paradise Lost
			g.cone(80.0, 1.4, I * 1.3, func(e): KitDiablo.palm(g, e), Color("#ff4d4d"), "spec", true)

static func skill(g, n: int) -> void:
	var P = g.P
	var k := kv(g)
	var st: int = P.stage
	var I := iv(g)
	if n == 1:
		match st:
			0:  # Venomous Spit
				P.cd.q = 5.0
				g.cone(220.0, 1.1, I * 2.2, func(e): g.poison(e, 5.0, KitDiablo.iv(g) * 0.25 + 2.0), Color("#5ccb5f"), "spec")
			1:  # Crazy Beam
				P.cd.q = 5.0
				g.beam(380.0, 40.0, I * 2.6, "spec", Callable(), Color("#7a2cff"), false, true)
			2:  # Virus Spiral (each enemy hit lowers ultimate cooldown)
				P.cd.q = 7.0
				g.cone(140.0, TAU, I * 2.4, func(e): KitDiablo.spiral_hit(g, e), Color("#9b3dff"), "spec")
			3:  # Single Shot
				P.cd.q = 4.0
				g.proj({"sp": 720.0, "life": 1.1, "r": 10.0, "dmg": I * 1.6, "ex": 70.0, "exd": I * 1.6, "end_ex": true, "col": Color("#ff6a3d")})
			_:  # Connection Terminated
				P.cd.q = 12.0
				g.add_tbuff({"int": 0.25, "aspd": 0.3}, 8.0)
				k.ult_bonus = 0.3
				g.txt(P.pos + Vector2(0, -30), "Connection Terminated!", Color("#ff4d4d"))
	else:
		match st:
			0:  # Virus Gaze
				P.cd.r = 16.0
				g.beam(700.0, 18.0, I * 5.0, "spec", Callable(), Color("#ff3df0"), false, true)
			1:  # Crazy Giggle: 3 exploding projectiles
				P.cd.r = 16.0
				for da in [-0.15, 0.0, 0.15]:
					g.proj({"sp": 600.0, "life": 1.3, "r": 10.0, "da": da, "dmg": I * 1.8, "ex": 90.0, "exd": I * 1.8, "end_ex": true, "col": Color("#b06bff")})
			2:  # Misconnecting: long dash, explodes on first enemy or at the end (terrain)
				P.cd.r = 20.0
				k.mis = false
				g.rush(950.0, 0.6, "mis", 1.0, func(e): KitDiablo.mis_boom(g, e), true, 14.0)
				P.ch = {"t": 0.6, "k": 9.0, "f": Callable(), "end": func(): KitDiablo.mis_end(g)}
			3:  # Hell's Grenade: hold R to charge, release to fire
				k.charging = true
				k.charge = 0.0
				g.add_tbuff({"int": 0.25}, 5.0)
				P.ch = {"t": 1.5, "k": 9.0, "f": Callable(), "end": func(): KitDiablo.fire_grenade(g)}
			_:  # Catastrophe Cannon
				var bonus: float = 1.0 + k.ult_bonus
				k.ult_bonus = 0.0
				P.cd.r = 22.0
				P.ch = {"t": 0.8, "k": 9.0, "f": Callable(), "end": func(): g.beam(520.0, 120.0, KitDiablo.iv(g) * 7.0 * bonus, "spec", Callable(), Color("#ff4d4d"), false, true)}
