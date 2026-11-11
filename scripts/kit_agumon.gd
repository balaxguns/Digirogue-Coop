class_name KitAgumon extends RefCounted
## Koromon > Agumon > Greymon > MetalGreymon > WarGreymon (roster index 2).
## PHYSICAL scaling for every move (basic, skill and ultimate). Fire moves are tagged elemental ("elem"), so
## Fire damage bonuses (cards, equipment) apply to them ON TOP of the physical scaling.

const BASIC := [[48.0, 1.6, 1.0], [55.0, 1.7, 1.1], [60.0, 1.8, 1.2], [80.0, 2.4, 1.4], [90.0, 2.8, 1.6]]

static func basic(g) -> void:
	var t: Array = BASIC[g.P.stage]
	g.cone(t[0], t[1], g.atkv() * t[2], Callable(), Color.WHITE, "phys", true)

static func skill(g, n: int) -> void:
	var P = g.P
	var st: int = P.stage
	var A: float = g.atkv()
	var bf := func(_n = 0):
		P.bd = 8.0
		P.bdv = 0.3
	if n == 1:
		if st == 0:  # Frothy Spit
			P.cd.q = 5.0
			g.cone(220.0, 1.1, A * 3.2, Callable(), Color("#c8f0ff"), "phys")
		elif st == 1:  # Pepper Breath (fire)
			P.cd.q = 5.0
			g.proj({"sp": 520.0, "life": 0.9, "kind": "phys", "elem": true, "dmg": A * 0.5, "ex": 90.0, "exd": A * 3.0, "xf": func(e): g.burn(e, 0.4)})
		elif st == 2:  # Great Horns
			P.cd.q = 6.0
			g.rush(820.0, 0.28, "horn", 2.4, func(e): g.stun_e(e, 1.2))
		elif st == 3:  # Tether Claw
			P.cd.q = 6.0
			var hf := func(e):
				g.ddown(e, 0.25, 6.0)
				if e != g.boss:
					var dirv: Vector2 = (e.pos - P.pos).normalized()
					e.pos = P.pos + dirv * (P.r + e.r + 14.0)
			g.proj({"sp": 700.0, "life": 0.6, "r": 10.0, "kind": "phys", "dmg": A * 1.5, "hf": hf})
		else:  # Great Tornado
			P.cd.q = 7.0
			g.rush(650.0, 0.45, "torn", 3.0, Callable(), false, 40.0)
	else:
		P.cd.r = 22.0
		if st == 0:  # Froth Barrage
			g.cone(260.0, 1.3, A * 7.5, func(e): g.ddown(e, 0.2, 6.0), Color("#c8f0ff"), "phys")
		elif st == 1:  # Intense Burner (fire)
			P.cd.r = 25.0
			P.ch = {"t": 2.5, "k": 0.0, "f": func(): g.cone(230.0, 0.9, A * 1.6, Callable(), Color("#ff9a4d"), "phys", false, true), "end": Callable()}
			P.bd = 6.0
			P.bdv = 0.2
			P.rg = 6.0
		elif st == 2:  # Nova Blast (fire)
			bf.call()
			P.ch = {"t": 0.5, "k": 9.0, "f": Callable(), "end": func(): g.proj({"sp": 480.0, "life": 1.4, "r": 16.0, "kind": "phys", "elem": true, "dmg": A * 3.0, "ex": 130.0, "exd": A * 5.0, "end_ex": true, "af": bf})}
		elif st == 3:  # Giga Blaster (fire)
			var xf := func(e):
				e.burn = 5.0
				e.bd = g.sv() * 0.4 + 3.0
			for da in [-0.08, 0.08]:
				g.proj({"sp": 600.0, "life": 1.2, "r": 10.0, "da": da, "kind": "phys", "elem": true, "dmg": A * 2.0, "ex": 90.0, "exd": A * 2.5, "end_ex": true, "xf": xf, "af": bf})
		else:  # Terra Force (fire)
			var af := func(_n = 0):
				bf.call()
				P.ba = 10.0
			P.ch = {"t": 0.6, "k": 9.0, "f": Callable(), "end": func(): g.proj({"sp": 420.0, "life": 1.6, "r": 26.0, "kind": "phys", "elem": true, "dmg": A * 4.0, "ex": 170.0, "exd": A * 7.0, "xf": func(e): g.burn(e, 1.0), "af": af})}
