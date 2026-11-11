def tb(s):
    out=[]
    for l in s.split('\n'):
        n=len(l)-len(l.lstrip(' '))
        out.append('\t'*(n//4)+l[n:])
    return '\n'.join(out)
open('scripts/bosses.gd','w').write(tb('''class_name Bosses extends RefCounted
## Boss move sets. g = the run script (scripts/run.gd). Called from run.gd's boss_ai().
## Passive beams: Light of Heaven (Reppamon, Angemon) and Dark Area Influence (Devimon, Sangloupmon).

const PASSIVE := {"reppamon": "Light", "angemon": "Light", "devimon": "Dark", "sangloupmon": "Dark"}
const RATE := {"reppamon": 1.7, "angemon": 1.5, "devimon": 1.6, "sangloupmon": 2.0}

# ---------------------------------------------------------------- helpers
static func later(b: Dictionary, t: float, fn: Callable) -> void:
    b.q.append({"t": t, "fn": fn})

static func shot(g, b: Dictionary, ang: float, sp: float, r: float, dmg: float, kind: String, extra: Dictionary = {}) -> void:
    var h := {"pos": b.pos, "vel": Vector2.from_angle(ang) * sp, "r": r, "dmg": dmg, "kind": kind, "from": "e", "src": b, "life": 3.0}
    h.merge(extra, true)
    g.shots.append(h)

static func tele_line(g, a: Vector2, b: Vector2, t: float, w: float = 3.0) -> void:
    g.fx.append({"line_a": a, "line_b": b, "t": t, "col": Color(1.0, 0.3, 0.3), "w": w})

static func tele_cone(g, b: Dictionary, a: float, rng: float, arc: float, t: float) -> void:
    g.fx.append({"pos": b.pos, "cone": true, "a": a, "rng": rng, "arc": arc, "t": t, "col": Color(0.6, 0.1, 0.3)})

static func res_hit(g, light: float, dark: float) -> void:
    var P = g.P
    P.res_l = minf(0.6, P.res_l + light)
    P.res_d = minf(0.6, P.res_d + dark)
    P.res_t = 20.0

static func cone_hit(g, b: Dictionary, a: float, rng: float, arc: float, dmg: float, kind: String) -> float:
    var P = g.P
    if P.pos.distance_to(b.pos) > rng + P.r: return 0.0
    if absf(angle_difference(a, (P.pos - b.pos).angle())) > arc / 2.0: return 0.0
    return g.hurt(dmg, b, kind)

# ---------------------------------------------------------------- per-frame
static func tick(g, b: Dictionary, dt: float) -> void:
    if b.key == "angemon" and b.hp < b.mhp * 0.5 and not b.get("half", false):
        b.half = true
        g.say("Salvation's Light! The beams grow wider and faster.")
    b.bt = b.get("bt", 2.0) - dt
    if b.bt <= 0.0:
        b.bt = RATE[b.key] * (0.6 if b.get("half", false) else 1.0)
        spawn_beam(g, b)
    if b.key == "devimon":
        b.fight += dt
        if b.fight >= 30.0 * (b.patch_n + 1):
            b.patch_n += 1
            var p := Vector2(randf_range(g.B.position.x + 90.0, g.B.end.x - 90.0), randf_range(g.B.position.y + 90.0, g.B.end.y - 90.0))
            g.patches.append({"pos": p, "r": 70.0, "dps": b.atk * 0.25})
            g.say("Corruption seeps into the arena!")

static func spawn_beam(g, b: Dictionary) -> void:
    var P = g.P
    var ty: String = PASSIVE[b.key]
    var half: bool = b.get("half", false)
    var p: Vector2
    if randf() < 0.5:
        p = P.pos + Vector2.from_angle(randf() * TAU) * randf_range(0.0, 300.0)
    else:
        p = Vector2(randf_range(g.B.position.x, g.B.end.x), randf_range(g.B.position.y, g.B.end.y))
    p = p.clamp(g.B.position + Vector2(40, 40), g.B.end - Vector2(40, 40))
    g.pillars.append({"pos": p, "r": 70.0 if half else 46.0, "t": 0.9, "e": false, "type": ty, "dmg": b.atk * (1.6 if half else 1.2),
        "res": 0.10 if half else 0.06, "src": {"attr": b.attr, "type": ty, "is_boss": true}})

static func vdash(g, b: Dictionary, dt: float) -> void:
    var P = g.P
    if b.vt > 0.0:
        b.vt -= dt
        b.pos += b.vdir * 1100.0 * dt
        if not b.vhit and b.pos.distance_to(P.pos) < b.r + P.r + 6.0:
            b.vhit = true
            var d: float = g.hurt(b.atk * (1.0 + 0.35 * b.vcombo), b, "phys")
            if d > 0.0: b.vcombo += 1
    else:
        b.vgap -= dt
        if b.vgap <= 0.0:
            if b.vn > 0:
                b.vn -= 1
                b.vdir = (P.pos - b.pos).normalized()
                b.vt = 0.18
                b.vgap = 0.3
                b.vhit = false
                b.hp = minf(b.mhp, b.hp + b.mhp * 0.02)
            else:
                b.st = ""

# ---------------------------------------------------------------- moves
static func act(g, b: Dictionary, p: String) -> void:
    var P = g.P
    var a: float = (P.pos - b.pos).angle()
    var dir := Vector2.from_angle(a)
    match p:
        "razor":  # Reppamon: Razor Wind
            shot(g, b, a, 820.0, 12.0, b.atk * 1.1, "phys", {"life": 2.0, "col": Color("#9dffd0")})
        "roll":  # Reppamon: Rolling Tackle (telegraph, then spinning dash)
            b.dvec = dir
            b.st = "tele"
            b.t = 0.5
        "blades":  # Sangloupmon: Sticker Blade (3 blades, heal per hit, return on the way back)
            for da in [-0.3, 0.0, 0.3]:
                shot(g, b, a + da, 340.0, 20.0, b.atk * 1.2, "phys", {"pierce": true, "leech": 0.03, "ret": true, "ot": 0.9, "life": 6.0, "col": Color("#c9d3e6")})
        "vdash":  # Sangloupmon: Vampiric Dash (1-5 dashes, stacking damage, heals)
            b.st = "vdash"
            b.vn = 1 + randi() % 5
            b.vt = 0.0
            b.vgap = 0.4
            b.vcombo = 0
            b.vhit = false
            b.vdir = dir
        "fang":  # Sangloupmon: Fang of Evil
            tele_cone(g, b, a, 150.0, 1.3, 0.45)
            later(b, 0.45, func(): Bosses.cone_hit(g, b, a, 150.0, 1.3, b.atk * 1.5, "phys"))
        "fist":  # Angemon: Heaven's Knuckle (fast, piercing, narrow)
            tele_line(g, b.pos, b.pos + dir * 900.0, 0.3, 4.0)
            later(b, 0.3, func(): Bosses.shot(g, b, a, 950.0, 14.0, b.atk * 1.8, "phys", {"pierce": true, "life": 1.2, "col": Color("#ffd23d")}))
        "shackles":  # Angemon: Holy Shackles (1s indicator, 5s stun)
            g.chains.append({"pos": P.pos, "r": 80.0, "t": 1.0, "stun": 5.0})
        "beam":  # Angemon: Beam of Light (leaves a 25s trail)
            tele_line(g, b.pos, b.pos + dir * 800.0, 0.5)
            later(b, 0.5, func(): Bosses.fire_beam(g, b, a))
        "dclaw":  # Devimon: Darkness Claw (spawns behind you, drags and stuns 3s)
            g.claws.append({"pos": P.pos + dir * 90.0, "r": 75.0, "t": 0.5})
        "wing":  # Devimon: Leather Wing (cone + knockback)
            tele_cone(g, b, a, 280.0, 1.6, 0.5)
            later(b, 0.5, func(): Bosses.wing(g, b, a))
        "glare":  # Devimon: Evil Glare (slow + dark resistance down)
            tele_line(g, b.pos, b.pos + dir * 800.0, 0.6)
            later(b, 0.6, func(): Bosses.glare(g, b, a))
        "touch":  # Devimon: Touch of Evil (grab, siphon HP)
            tele_cone(g, b, a, 240.0, 0.7, 0.6)
            later(b, 0.6, func(): Bosses.touch(g, b, a))

static func fire_beam(g, b: Dictionary, a: float) -> void:
    var P = g.P
    var from: Vector2 = b.pos
    var to: Vector2 = from + Vector2.from_angle(a) * 800.0
    g.fx.append({"line_a": from, "line_b": to, "t": 0.3, "col": Color("#fff3a0"), "w": 40.0})
    if Geometry2D.get_closest_point_to_segment(P.pos, from, to).distance_to(P.pos) < 24.0 + P.r:
        var d: float = g.hurt(b.atk * 1.4, {"attr": b.attr, "type": "Light", "is_boss": true}, "spec")
        if d > 0.0: res_hit(g, 0.06, 0.06)
    g.trails.append({"a": from, "b": to, "t": 25.0, "w": 36.0, "acc": 0.0, "dps": b.atk * 0.18})

static func wing(g, b: Dictionary, a: float) -> void:
    var P = g.P
    var d := cone_hit(g, b, a, 280.0, 1.6, b.atk * 1.3, "phys")
    if d > 0.0:
        P.kb_t = 0.25
        P.kb_v = (P.pos - b.pos).normalized() * 900.0

static func glare(g, b: Dictionary, a: float) -> void:
    var P = g.P
    var from: Vector2 = b.pos
    var to: Vector2 = from + Vector2.from_angle(a) * 800.0
    g.fx.append({"line_a": from, "line_b": to, "t": 0.3, "col": Color("#ff2222"), "w": 18.0})
    if Geometry2D.get_closest_point_to_segment(P.pos, from, to).distance_to(P.pos) < 14.0 + P.r:
        var d: float = g.hurt(b.atk * 1.1, b, "spec")
        if d > 0.0:
            P.slow_t = 4.0
            P.slow = 0.35
            res_hit(g, 0.0, 0.08)

static func touch(g, b: Dictionary, a: float) -> void:
    var P = g.P
    var d := cone_hit(g, b, a, 240.0, 0.7, b.atk * 1.8, "phys")
    if d > 0.0:
        b.hp = minf(b.mhp, b.hp + d)
        P.pull_t = 0.3
        g.stun_player(1.0)

static func fang(g, b: Dictionary, a: float) -> void:
    cone_hit(g, b, a, 150.0, 1.3, b.atk * 1.5, "phys")

# ---------------------------------------------------------------- hazards (called from run.gd update_world)
static func world(g, dt: float) -> void:
    var P = g.P
    for c in g.chains:
        c.t -= dt
        if c.t <= 0.0 and P.pos.distance_to(c.pos) < c.r: g.stun_player(c.stun)
    g.chains = g.chains.filter(func(c): return c.t > 0.0)
    for c in g.claws:
        c.t -= dt
        if c.t <= 0.0 and g.boss != null and P.pos.distance_to(c.pos) < c.r + P.r:
            g.hurt(g.boss.atk * 1.1, g.boss, "spec")
            P.pull_t = 0.4
            g.stun_player(3.0)
    g.claws = g.claws.filter(func(c): return c.t > 0.0)
    for pt in g.patches:
        if P.pos.distance_to(pt.pos) < pt.r + P.r:
            g.lose_hp(pt.dps * dt * (1.0 + P.res_d))
            P.res_d = minf(0.6, P.res_d + 0.04 * dt)
            P.res_t = 20.0
    for tr in g.trails:
        tr.t -= dt
        if Geometry2D.get_closest_point_to_segment(P.pos, tr.a, tr.b).distance_to(P.pos) < tr.w / 2.0 + P.r:
            g.lose_hp(tr.dps * dt * (1.0 + P.res_l))
            tr.acc += dt
            if tr.acc >= 3.0:
                tr.acc = 0.0
                res_hit(g, 0.06, 0.06)
    g.trails = g.trails.filter(func(t): return t.t > 0.0)
    for q in g.pillars:
        q.t -= dt
        if q.t <= 0.0 and not q.e:
            q.e = true
            q.t = 0.3
            if P.pos.distance_to(q.pos) < q.r + P.r:
                var d: float = g.hurt(q.dmg, q.src, "spec")
                if d > 0.0: res_hit(g, q.res if q.type == "Light" else 0.0, q.res)
    g.pillars = g.pillars.filter(func(q): return not (q.e and q.t <= 0.0))

static func draw(g) -> void:
    for pt in g.patches:
        g.draw_circle(pt.pos, pt.r, Color(0.4, 0.05, 0.5, 0.4))
        g.draw_arc(pt.pos, pt.r, 0.0, TAU, 32, Color("#9b3dff"), 3.0)
    for tr in g.trails:
        g.draw_line(tr.a, tr.b, Color(1.0, 0.9, 0.4, 0.25), tr.w)
    for c in g.chains:
        g.draw_arc(c.pos, c.r * (0.4 + 0.6 * c.t), 0.0, TAU, 32, Color("#ffe066"), 3.0)
        g.draw_arc(c.pos, c.r, 0.0, TAU, 32, Color(1, 0.88, 0.4, 0.3), 2.0)
    for c in g.claws:
        g.draw_circle(c.pos, c.r, Color(0.3, 0.0, 0.4, 0.3))
        g.draw_arc(c.pos, c.r * (0.4 + 0.6 * c.t * 2.0), 0.0, TAU, 32, Color("#9b3dff"), 3.0)
    for q in g.pillars:
        var light: bool = q.type == "Light"
        if q.e:
            var col := Color(1, 0.96, 0.69) if light else Color(0.45, 0.1, 0.6)
            g.draw_rect(Rect2(q.pos.x - q.r * 0.6, q.pos.y - 260, q.r * 1.2, 260), Color(col, minf(1.0, q.t * 3.0)))
        else:
            g.draw_arc(q.pos, q.r * (1.0 - q.t / 0.9 * 0.4), 0.0, TAU, 32, Color("#ffe066") if light else Color("#9b3dff"), 3.0)
'''))
print('bosses ok')
