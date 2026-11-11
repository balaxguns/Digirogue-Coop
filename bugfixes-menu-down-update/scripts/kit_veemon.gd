class_name KitVeemon extends RefCounted
## Veemon line (roster index 6): DemiVeemon > Veemon > V-dramon > AeroV-dramon > UlforceV-dramon.
## Physical scaling. g = the run script (scripts/run.gd). Called from kit.gd.

# [range, arc (radians), damage multiplier]
const BASIC := [[42.0, 1.6, 1.0], [52.0, 1.5, 1.1], [65.0, 1.3, 1.25], [70.0, 2.0, 1.35], [95.0, 1.9, 1.7]]

static func kv(g) -> Dictionary:
	var k: Dictionary = g.P.kv
	if not k.has("init"):
		k.init = true
		k.ch = 3            # Boom-Boom Punch charges
		k.rt = 0.0          # recharge timer
		k.combo = 0
		k.ct = 0.0          # combo window
		k.ult_bonus = 0.0   # Victory Sign bonus for next ultimate
		k.charging = false  # Ray of Victory! charge state
		k.charge = 0.0
		k.bhit = []
	return k

static func extra(g) -> String:
	var k := kv(g)
	var st: int = g.P.stage
	if st == 1: return "   Punch %d/3" % k.ch
	if st == 2 and k.ult_bonus > 0.0: return "   Next ult +30%"
	if st == 4 and k.charging: return "   Charge %d%%" % int(k.charge / 1.5 * 100.0)
	return ""

static func tick(g, dt: float) -> void:
	var P = g.P
	var k := kv(g)
	if k.ch < 3:
		k.rt -= dt
		if k.rt <= 0.0:
			k.ch += 1
			k.rt = 5.0 if k.ch < 3 else 0.0
	k.ct -= dt
	if k.ct <= 0.0: k.combo = 0
	if k.charging:
		if P.ch == null:
			k.charging = false
		else:
			k.charge = minf(1.5, k.charge + dt)
			if not Input.is_action_pressed("ultimate"): fire_ray(g)

static func basic(g) -> void:
	var t: Array = BASIC[g.P.stage]
	g.cone(t[0], t[1], g.atkv() * t[2], Callable(), Color.WHITE, "phys", true)

static func shockwave(g, hit_enemy: Dictionary, mult: float) -> void:
	for e in g.foes():
		if e != hit_enemy and e.pos.distance_to(hit_enemy.pos) < 150.0 + e.r:
			g.hit_enemy(e, g.atkv() * mult * 0.7, g.P, g.crit(), "phys")
	g.fx.append({"pos": hit_enemy.pos, "ring": 150.0, "t": 0.35, "col": Color("#7fd8ff")})

static func tackle_hit(g) -> void:
	g.P.cd.q = maxf(0.0, g.P.cd.q - 1.2)

static func impulse_hit(g, e: Dictionary) -> void:
	if e.hp > 0.0: g.ddown(e, 0.25, 6.0)
	g.add_tbuff({"aspd": 0.08, "crit": 4.0}, 8.0)

static func ray_tick(g, power: float) -> void:
	var P = g.P
	var k := kv(g)
	P.at = 0.35
	var a: Vector2 = P.pos
	var b: Vector2 = a + Vector2.from_angle(P.face) * 650.0
	g.fx.append({"line_a": a, "line_b": b, "t": 0.2, "col": Color("#7fd8ff"), "w": 36.0})
	for e in g.foes():
		if Geometry2D.get_closest_point_to_segment(e.pos, a, b).distance_to(e.pos) < 22.0 + e.r:
			g.hit_enemy(e, g.atkv() * 0.9 * power, P, g.crit(), "phys", false, true)
			if not k.bhit.has(e):
				k.bhit.append(e)
				g.add_tbuff({"aspd": 0.05, "crit": 2.0}, 8.0)

static func fire_ray(g) -> void:
	var P = g.P
	var k := kv(g)
	if not k.charging: return
	k.charging = false
	var power: float = 1.0 + k.charge
	k.bhit = []
	P.cd.r = 22.0
	P.ch = {"t": 1.2, "k": 0.0, "f": func(): KitVeemon.ray_tick(g, power), "end": Callable()}

static func victory_stream(g) -> void:
	var P = g.P
	var dir := Vector2.from_angle(P.face)
	P.cd.q = 8.0
	P.at = 0.35
	P.inv = maxf(P.inv, 0.8)
	var start: Vector2 = P.pos
	var dest: Vector2 = start + dir * 260.0
	for i in range(1, 14):
		if g.hits_obs(start + dir * (20.0 * i)):
			dest = start + dir * (20.0 * (i - 1))
			break
	dest = dest.clamp(g.B.position + Vector2(P.r, P.r), g.B.end - Vector2(P.r, P.r))
	g.fx.append({"line_a": start, "line_b": dest, "t": 0.25, "col": Color("#7fd8ff"), "w": 10.0})
	P.pos = dest
	var list: Array = g.foes().filter(func(e): return e.pos.distance_to(dest) < 220.0)
	list.sort_custom(func(x, y): return x.pos.distance_to(dest) < y.pos.distance_to(dest))
	var n := 0
	for e in list:
		var from: Vector2 = P.pos
		P.pos = e.pos - (e.pos - P.pos).normalized() * (e.r + P.r + 4.0)
		g.fx.append({"line_a": from, "line_b": P.pos, "t": 0.25, "col": Color("#ffffff"), "w": 6.0})
		g.hit_enemy(e, g.atkv() * (1.8 + 0.35 * n), P, g.crit(), "phys")
		n += 1
	P.pos = P.pos.clamp(g.B.position + Vector2(P.r, P.r), g.B.end - Vector2(P.r, P.r))

static func skill(g, n: int) -> void:
	var P = g.P
	var k := kv(g)
	var st: int = P.stage
	var A: float = g.atkv()
	if n == 1:
		match st:
			0:  # Petite Tackle: hits everything in range, each hit lowers the cooldown
				P.cd.q = 7.0
				g.rush(760.0, 0.3, "tackle", 1.8, func(_e): KitVeemon.tackle_hit(g), false, 20.0)
			1:  # Boom-Boom Punch: 3 charges, chained punches hit harder
				if k.ch <= 0:
					P.cd.q = maxf(0.2, k.rt)
					return
				k.ch -= 1
				if k.rt <= 0.0: k.rt = 5.0
				var c: int = k.combo if k.ct > 0.0 else 0
				k.combo = mini(c + 1, 3)
				k.ct = 2.0
				P.cd.q = 0.45
				g.cone(80.0, 1.1, A * 2.2 * (1.0 + 0.35 * c), Callable(), Color("#7fd8ff"), "phys")
			2:  # Victory Sign
				P.cd.q = 10.0
				g.add_tbuff({"aspd": 0.3}, 8.0)
				k.ult_bonus = 0.3
				g.txt(P.pos + Vector2(0, -30), "Victory!", Color("#ffe066"))
			3:  # V-Stream
				P.cd.q = 9.0
				P.inv = maxf(P.inv, 0.5)
				g.cone(300.0, 1.2, A * 3.0, func(_e): g.add_tbuff({"aspd": 0.06}, 6.0), Color("#5b2a86"), "phys")
			_:
				victory_stream(g)
	else:
		match st:
			0:  # Charge!
				P.cd.r = 18.0
				g.rush(950.0, 0.45, "charge", 3.0, func(e): KitVeemon.shockwave(g, e, 3.0), true, 14.0)
			1:  # Vee Headbutt
				P.cd.r = 16.0
				g.rush(1000.0, 0.5, "charge", 3.6, func(e): KitVeemon.shockwave(g, e, 3.6), true, 14.0)
			2:  # V-Nova Blast
				var bonus: float = 1.0 + k.ult_bonus
				k.ult_bonus = 0.0
				P.cd.r = 14.0
				var af := func(cnt = 0):
					if cnt > 0:
						g.add_tbuff({"aspd": 0.08 * mini(cnt, 3)}, 8.0)
						P.cd.r = maxf(0.0, P.cd.r - 2.0 * cnt)
				g.proj({"sp": 560.0, "life": 1.4, "r": 26.0, "kind": "phys", "dmg": A * 4.0 * bonus, "ex": 120.0, "exd": A * 2.5 * bonus, "end_ex": true, "af": af})
			3:  # Dragon Impulse
				P.cd.r = 18.0
				P.ch = {"t": 0.3, "k": 9.0, "f": Callable(), "end": func(): g.rush(820.0, 0.5, "impulse", 3.2, func(e): KitVeemon.impulse_hit(g, e), false, 30.0)}
			_:  # Ray of Victory! (hold R to charge, release to fire)
				k.charging = true
				k.charge = 0.0
				P.ch = {"t": 1.5, "k": 9.0, "f": Callable(), "end": func(): KitVeemon.fire_ray(g)}
