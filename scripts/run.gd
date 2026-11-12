extends Node2D
## The expedition: map generation, nights, corruption, combat, bosses, rewards.
const WORLD := 9000.0
const GRID := 90
const BOSS_PAT := {"reppamon": ["razor", "roll", "razor"], "sangloupmon": ["blades", "vdash", "fang"], "angemon": ["fist", "shackles", "beam", "fist"], "devimon": ["dclaw", "wing", "glare", "touch"]}
const BOSS_DMG := 2.0
const BOSS_SCALE := {"sangloupmon": 0.88}
const BASE_CD := 1.8
const BOSS_CD := {"reppamon": 1.6, "sangloupmon": 1.8, "angemon": 1.1, "devimon": 1.0}  # attack interval multipliers (faster)
const BOSS_R := {"reppamon": 30.0, "sangloupmon": 34.0, "angemon": 34.0, "devimon": 42.0}
const ATTRS := ["Vaccine", "Virus", "Data"]
const BIO_A := [Color("#16261d"), Color("#1a2634"), Color("#2e2418"), Color("#1f1e2e"), Color("#132a2e"), Color("#2a181a")]
const BIO_B := [Color("#1b2e23"), Color("#203040"), Color("#352a1c"), Color("#262538"), Color("#183238"), Color("#331d20")]
const BIO_OBS := [Color("#1d3a27"), Color("#5f8fb0"), Color("#5a4126"), Color("#3c3a58"), Color("#1e4d55"), Color("#4d2327")]
const BIO_EDGE := [Color("#3f7a52"), Color("#bfe6ff"), Color("#8a6a3e"), Color("#6e6b99"), Color("#3a8a94"), Color("#e0652e")]

var P: Dictionary
var R: Dictionary
var B := Rect2(0, 0, WORLD, WORLD)
var boss = null
var mobs: Array = []
var shots: Array = []
var chests: Array = []
var camps: Array = []
var drops: Array = []
var obs: Array = []
var og := {}
var spots: Array = []
var pillars: Array = []
var patches: Array = []
var chains: Array = []
var claws: Array = []
var allies: Array = []   # other players (multiplayer, not implemented yet)
var trails: Array = []
var fx: Array = []
var areas: Array = []
var bio := PackedByteArray()
var door = null
var cam: Camera2D
var hud
var font: Font
var terrain_view: SubViewport
var terrain_camera: Camera3D
var terrain_root: Node3D
var terrain_props: Node3D
var terrain_actors: Node3D
var actor_player: MeshInstance3D
var actor_boss: MeshInstance3D
var actor_mobs: MultiMeshInstance3D
var actor_shots: MultiMeshInstance3D
var actor_chests: MultiMeshInstance3D
var actor_drops: MultiMeshInstance3D
const TERRAIN_SCALE := 2400.0 / WORLD

func _ready() -> void:
	randomize()
	font = ThemeDB.fallback_font
	_setup_terrain()
	cam = Camera2D.new()
	add_child(cam)
	hud = load("res://scripts/hud.gd").new()
	hud.g = self
	add_child(hud)
	start_run()

func _setup_terrain() -> void:
	# The playable expedition remains Node2D for now. Render the new 3D terrain
	# underneath the existing combat sprites through a transparent-free viewport.
	terrain_view = SubViewport.new()
	terrain_view.disable_3d = false
	terrain_view.transparent_bg = false
	terrain_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	terrain_view.size = Vector2i(1280, 720)
	add_child(terrain_view)
	var terrain_scene: PackedScene = preload("res://scenes/terrain_preview.tscn")
	var terrain: Node3D = terrain_scene.instantiate() as Node3D
	terrain.set("embedded_mode", true)
	terrain_root = terrain
	terrain.set_process(false)
	terrain.set_process_unhandled_input(false)
	terrain_view.add_child(terrain)
	terrain_props = Node3D.new()
	terrain_root.add_child(terrain_props)
	terrain_actors = Node3D.new()
	terrain_root.add_child(terrain_actors)
	_build_3d_actors()
	terrain_camera = terrain.get("camera") as Camera3D
	if terrain_camera == null:
		push_error("3D terrain camera was not created.")
		return
	terrain_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	terrain_camera.rotation = Vector3(-PI / 2.0, 0, 0)
	terrain_camera.position = Vector3(0, 450, 0)
	terrain_camera.size = 720.0 * TERRAIN_SCALE
	terrain_camera.current = true
	# Preview's screen-space legend is not part of the live expedition.
	for child: Node in terrain.get_children():
		if child is CanvasLayer:
			child.hide()

func _world3(p: Vector2, height: float = 0.0) -> Vector3:
	return Vector3((p.x - WORLD * 0.5) * TERRAIN_SCALE, height, (p.y - WORLD * 0.5) * TERRAIN_SCALE)

func _actor_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.72
	return mat

func _build_3d_actors() -> void:
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 1.0
	body_mesh.height = 2.0
	body_mesh.radial_segments = 12
	body_mesh.rings = 6
	actor_player = MeshInstance3D.new()
	actor_player.mesh = body_mesh
	actor_player.material_override = _actor_material(Color("#66dfff"))
	terrain_actors.add_child(actor_player)
	actor_boss = MeshInstance3D.new()
	actor_boss.mesh = body_mesh
	actor_boss.material_override = _actor_material(Color("#ff685f"))
	terrain_actors.add_child(actor_boss)
	actor_mobs = MultiMeshInstance3D.new()
	var mob_mesh := MultiMesh.new()
	mob_mesh.transform_format = MultiMesh.TRANSFORM_3D
	mob_mesh.mesh = body_mesh
	mob_mesh.use_colors = true
	mob_mesh.instance_count = 0
	actor_mobs.multimesh = mob_mesh
	terrain_actors.add_child(actor_mobs)
	actor_shots = MultiMeshInstance3D.new()
	var shot_mesh := MultiMesh.new()
	shot_mesh.transform_format = MultiMesh.TRANSFORM_3D
	shot_mesh.mesh = body_mesh
	shot_mesh.instance_count = 0
	actor_shots.multimesh = shot_mesh
	actor_shots.material_override = _actor_material(Color("#ffdc72"))
	terrain_actors.add_child(actor_shots)
	actor_chests = MultiMeshInstance3D.new()
	var chest_mesh := MultiMesh.new()
	chest_mesh.transform_format = MultiMesh.TRANSFORM_3D
	var chest_shape := BoxMesh.new()
	chest_shape.size = Vector3.ONE
	chest_mesh.mesh = chest_shape
	chest_mesh.instance_count = 0
	actor_chests.multimesh = chest_mesh
	actor_chests.material_override = _actor_material(Color("#dba746"))
	terrain_actors.add_child(actor_chests)
	actor_drops = MultiMeshInstance3D.new()
	var drop_mesh := MultiMesh.new()
	drop_mesh.transform_format = MultiMesh.TRANSFORM_3D
	drop_mesh.mesh = body_mesh
	drop_mesh.use_colors = true
	drop_mesh.instance_count = 0
	actor_drops.multimesh = drop_mesh
	terrain_actors.add_child(actor_drops)

func _sync_3d_actors() -> void:
	if terrain_actors == null:
		return
	var active: bool = R.mode == "night"
	terrain_actors.visible = active
	if not active:
		return
	var player_radius: float = (P.r + P.stage * 3.0) * TERRAIN_SCALE
	actor_player.scale = Vector3.ONE * player_radius
	actor_player.position = _world3(P.pos, player_radius)
	actor_player.visible = not P.downed
	actor_boss.visible = boss != null
	if boss != null:
		var boss_radius: float = float(boss.r) * TERRAIN_SCALE
		actor_boss.scale = Vector3.ONE * boss_radius
		actor_boss.position = _world3(boss.pos, boss_radius)
	var mm: MultiMesh = actor_mobs.multimesh
	mm.instance_count = mobs.size()
	for i in mobs.size():
		var enemy: Dictionary = mobs[i]
		var radius: float = float(enemy.r) * TERRAIN_SCALE
		var pos: Vector3 = _world3(enemy.pos, radius)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * radius), pos))
		mm.set_instance_color(i, Color("#e6a968") if enemy.get("el", false) else Color("#b48de3"))
	var sm: MultiMesh = actor_shots.multimesh
	sm.instance_count = shots.size()
	for i in shots.size():
		var shot: Dictionary = shots[i]
		var radius: float = float(shot.r) * TERRAIN_SCALE
		sm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * radius), _world3(shot.pos, radius)))

	var cm: MultiMesh = actor_chests.multimesh
	cm.instance_count = chests.size()
	for i in chests.size():
		var chest: Dictionary = chests[i]
		var size: float = 12.0 * TERRAIN_SCALE
		var transform := Transform3D(Basis().scaled(Vector3(size, size * 0.7, size)), _world3(chest.pos, size * 0.35))
		if chest.open:
			transform = Transform3D(Basis().scaled(Vector3.ZERO), _world3(chest.pos))
		cm.set_instance_transform(i, transform)
	var dm: MultiMesh = actor_drops.multimesh
	dm.instance_count = drops.size()
	for i in drops.size():
		var drop: Dictionary = drops[i]
		var radius: float = 7.0 * TERRAIN_SCALE
		dm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * radius), _world3(drop.pos, radius)))
		dm.set_instance_color(i, Color("#42ddff") if drop.k == "items" else Color("#ff8ad8"))

func _rebuild_terrain_props() -> void:
	if terrain_props == null:
		return
	for child: Node in terrain_props.get_children():
		terrain_props.remove_child(child)
		child.queue_free()
	if R.mode != "night":
		return
	# Render the actual gameplay obstacles in 3D at their collision coordinates.
	# The old 2D placeholder circles are no longer drawn.
	var rock_mesh := CylinderMesh.new()
	rock_mesh.top_radius = 0.65
	rock_mesh.bottom_radius = 1.0
	rock_mesh.height = 1.0
	rock_mesh.radial_segments = 7
	var rocks := MultiMesh.new()
	rocks.transform_format = MultiMesh.TRANSFORM_3D
	rocks.mesh = rock_mesh
	rocks.instance_count = obs.size()
	for i in obs.size():
		var o: Dictionary = obs[i]
		var world_pos := Vector3((o.pos.x - WORLD * 0.5) * TERRAIN_SCALE, 0, (o.pos.y - WORLD * 0.5) * TERRAIN_SCALE)
		var radius: float = o.r * TERRAIN_SCALE
		rocks.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(radius, radius * 1.6, radius)), world_pos + Vector3(0, radius * 0.8, 0)))
	var rock_instances := MultiMeshInstance3D.new()
	rock_instances.multimesh = rocks
	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color("#716c67")
	rock_instances.material_override = rock_mat
	terrain_props.add_child(rock_instances)
	# Camps occupy the same world positions as their gameplay interactions.
	var camp_mesh := CylinderMesh.new()
	camp_mesh.top_radius = 3.5
	camp_mesh.bottom_radius = 5.0
	camp_mesh.height = 2.0
	var markers := MultiMesh.new()
	markers.transform_format = MultiMesh.TRANSFORM_3D
	markers.mesh = camp_mesh
	markers.instance_count = camps.size()
	for i in camps.size():
		var c: Dictionary = camps[i]
		var p := Vector3((c.pos.x - WORLD * 0.5) * TERRAIN_SCALE, 1.0, (c.pos.y - WORLD * 0.5) * TERRAIN_SCALE)
		markers.set_instance_transform(i, Transform3D(Basis(), p))
	var camp_instances := MultiMeshInstance3D.new()
	camp_instances.multimesh = markers
	var camp_mat := StandardMaterial3D.new()
	camp_mat.albedo_color = Color("#49b79c")
	camp_mat.emission_enabled = true
	camp_mat.emission = Color("#1c7363")
	camp_instances.material_override = camp_mat
	terrain_props.add_child(camp_instances)

func _sync_terrain() -> void:
	if terrain_view == null or terrain_camera == null:
		return
	var vp := get_viewport_rect().size
	var target := Vector2i(maxi(1, int(vp.x)), maxi(1, int(vp.y)))
	if terrain_view.size != target:
		terrain_view.size = target
	terrain_camera.size = vp.y * TERRAIN_SCALE
	var center: Vector2 = cam.get_screen_center_position()
	terrain_camera.position = Vector3((center.x - WORLD * 0.5) * TERRAIN_SCALE, 450.0, (center.y - WORLD * 0.5) * TERRAIN_SCALE)

func nm() -> String:
	return Data.ROSTER[P.line].stages[P.stage]

# ------------------------------------------------------------------ setup
func start_run() -> void:
	var r: Dictionary = Data.ROSTER[Run.line]
	P = {"pos": Vector2.ZERO, "line": Run.line, "cls": r.cls, "attr": r.attr, "type": r.type, "lv": 1, "xp": 0.0, "stage": 0,
		"items": [], "cards": [], "eq": [], "buff": {"atk": 0.0, "spd": 0.0, "sh": 0.0}, "cd": {"a": 0.0, "q": 0.0, "d": 0.0, "r": 0.0},
		"inv": 0.0, "dash": 0.0, "dvel": Vector2.ZERO, "face": 0.0, "hp": 1.0, "mhp": 0.0, "mv": false, "at": 0.0, "hurt_t": 0.0,
		"ct": 0.0, "bd": 0.0, "bdv": 0.0, "ba": 0.0, "rg": 0.0, "ch": null, "dk": "", "dset": [], "r": 14.0, "st": {}, "m": {}, "tb": [], "shield": 0.0, "shield_t": 0.0, "stun_t": 0.0, "pull_t": 0.0, "supp": 0.0, "phoenix_used": false, "weak_t": 0.0, "war_t": 0.0, "war_cd": 0.0, "nail_cd": 0.0, "poison_imm": 0.0, "kv": {}, "kb_t": 0.0, "kb_v": Vector2.ZERO, "slow_t": 0.0, "slow": 0.0, "res_l": 0.0, "res_d": 0.0, "res_t": 0.0, "mvel": Vector2.ZERO, "stam": 100.0, "stam_t": 0.0, "stam_lock": false, "downed": false, "down_t": 0.0, "revive_used": false, "heal_t": 0.0, "reviving": false}
	for u in Save.equipped:
		var o := Save.find_owned(int(u))
		if not o.is_empty() and Data.equip.has(o.id):
			P.eq.append(o)
	R = {"night": 1, "clock": 0.0, "speed": Run.speed, "xpm": Run.xpm, "cleared": 0, "over": false, "out": 0.0, "msg": "", "msg_t": 0.0,
		"mode": "night", "boss_up": false, "sg": 0, "p": 1.0, "a": {}, "chain": [], "fc": Vector2.ZERO, "cpos": Vector2.ZERO, "cr": 1.0, "fog": PackedByteArray()}
	recalc()
	P.hp = P.mhp
	start_night()

func add_fx(m: Dictionary, fx: Dictionary) -> void:
	for k in fx:
		m[k] = m.get(k, 0.0) + fx[k]

func rebuild_mods() -> void:
	var m := {}
	var pp: Array = Data.CLASS_PASSIVE[P.cls]
	add_fx(m, {pp[1]: pp[2]})
	for e in P.eq: add_fx(m, Data.equip[e.id].fx)
	for c in P.cards: add_fx(m, c.fx)
	for b in P.tb: add_fx(m, b.fx)
	P.m = m

func recalc() -> void:
	rebuild_mods()
	var b: Array = Data.CLASS_BASE[P.cls]
	var g: float = 1.0 + P.stage * 0.35 + (P.lv - 1) * 0.05
	var gd: float = g
	if P.cls == "Speedster": gd = 1.0 + P.stage * 0.2 + (P.lv - 1) * 0.03
	var gh: float = gd
	if P.line == 2: gh = 1.0 + P.stage * 0.42 + (P.lv - 1) * 0.06
	var s := {"hp": b[0] * gh * 1.2, "atk": b[1] * g, "def": b[2] * gd, "int": b[3] * g, "wis": b[4] * gd, "crit": float(b[5]), "aspd": float(b[6]), "spd": 1.0, "ls": 0.0}
	if P.line == 2:  # Koromon > WarGreymon bruisers hit harder
		s.atk *= 1.2
	for k in ["hp", "atk", "def", "int", "wis", "aspd", "spd"]:
		s[k] *= 1.0 + P.m.get(k, 0.0)
	s.crit += P.m.get("crit", 0.0)
	var ratio: float = P.hp / P.mhp if P.mhp > 0.0 else 1.0
	P.st = s
	P.mhp = s.hp
	P.hp = ratio * P.mhp

func set_bounds(r: Rect2) -> void:
	B = r
	cam.limit_left = int(r.position.x)
	cam.limit_top = int(r.position.y)
	cam.limit_right = int(r.end.x)
	cam.limit_bottom = int(r.end.y)

func clear_lists() -> void:
	mobs.clear(); shots.clear(); chests.clear(); camps.clear(); drops.clear(); obs.clear(); og.clear(); spots.clear(); pillars.clear(); patches.clear(); chains.clear(); claws.clear(); trails.clear(); fx.clear(); areas.clear()
	door = null
	boss = null

func start_night() -> void:
	R.mode = "night"; R.clock = 0.0; R.out = 0.0; R.boss_up = false; R.sg = 0; R.p = 1.0
	set_bounds(Rect2(0, 0, WORLD, WORLD))
	clear_lists()
	R.chain = make_chain()
	R.fc = R.chain[2].pos
	R.cpos = R.chain[0].pos
	R.cr = R.chain[0].r
	R.fog = PackedByteArray()
	R.fog.resize(GRID * GRID)
	gen_map()
	_rebuild_terrain_props()
	say("Night %d begins. Stay inside the safe zone." % R.night)

func make_chain() -> Array:
	var c := [{"pos": Vector2(WORLD / 2.0, WORLD / 2.0), "r": 4800.0}]
	for r in [2300.0, 700.0]:
		var p: Dictionary = c[c.size() - 1]
		var q: Vector2 = p.pos + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * (p.r - r)
		c.append({"pos": Vector2(clampf(q.x, 400.0, WORLD - 400.0), clampf(q.y, 400.0, WORLD - 400.0)), "r": r})
	return c

# ------------------------------------------------------------------ map generation
func bio_at(p: Vector2) -> int:
	return bio[clampi(int(p.y / 100.0), 0, GRID - 1) * GRID + clampi(int(p.x / 100.0), 0, GRID - 1)]

func gen_bio() -> void:
	var ids := [0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4, 5]
	ids.shuffle()
	var seeds: Array = []
	for b in ids:
		seeds.append({"b": b, "pos": Vector2(randf_range(300, WORLD - 300), randf_range(300, WORLD - 300))})
	bio.resize(GRID * GRID)
	for gy in GRID:
		for gx in GRID:
			var h: int = ((gx * 73856093) ^ (gy * 19349663)) & 0x7fffffff
			var bd := 1e9
			var bb := 0
			for s in seeds:
				var d: float = Vector2(gx * 100.0 + 50.0, gy * 100.0 + 50.0).distance_to(s.pos) + float(((h ^ int(s.pos.x * 31.0)) & 0x7fffffff) % 90)
				if d < bd:
					bd = d
					bb = s.b
			bio[gy * GRID + gx] = bb
	for i in 6:
		areas.append({"n": Data.BIOMES[seeds[i].b].name, "pos": seeds[i].pos})

func add_obs(p: Vector2, r: float) -> void:
	var o := {"pos": p, "r": r, "b": bio_at(p)}
	obs.append(o)
	var k := Vector2i(int(p.x / 200.0), int(p.y / 200.0))
	if not og.has(k): og[k] = []
	og[k].append(o)

func near_obs(p: Vector2) -> Array:
	var out: Array = []
	var c := Vector2i(int(p.x / 200.0), int(p.y / 200.0))
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var k := Vector2i(c.x + dx, c.y + dy)
			if og.has(k): out.append_array(og[k])
	return out

func push_out(e: Dictionary) -> void:
	for o in near_obs(e.pos):
		var d: Vector2 = e.pos - o.pos
		var m: float = o.r + e.r
		var l := d.length()
		if l < m:
			e.pos = o.pos + (d / l if l > 0.0 else Vector2.RIGHT) * m

func hits_obs(p: Vector2) -> bool:
	for o in near_obs(p):
		if p.distance_to(o.pos) < o.r: return true
	return false

func obs_ok(p: Vector2) -> bool:
	return p.distance_to(R.fc) > 600.0 and p.distance_to(R.cpos) < R.cr + 100.0 and p.x > 40 and p.y > 40 and p.x < WORLD - 40 and p.y < WORLD - 40

func gen_obs() -> void:
	for i in 90:
		var p: Vector2 = R.cpos + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * R.cr
		var dir := randf() * TAU
		for k in 5 + randi() % 9:
			dir += randf_range(-0.4, 0.4)
			p += Vector2.from_angle(dir) * 46.0
			if not obs_ok(p): break
			add_obs(p, randf_range(24.0, 40.0))
	for i in 300:
		var p: Vector2 = R.cpos + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * R.cr
		if obs_ok(p): add_obs(p, randf_range(18.0, 38.0))

func is_free(p: Vector2, r: float, gap: float) -> bool:
	if p.distance_to(R.cpos) > R.cr - r - 60.0: return false
	if p.distance_to(R.fc) < 560.0 + r: return false
	if p.x < r or p.y < r or p.x > WORLD - r or p.y > WORLD - r: return false
	for s in spots:
		if p.distance_to(s.pos) < s.r + r + gap: return false
	for o in near_obs(p) + near_obs(p + Vector2(200, 0)) + near_obs(p + Vector2(0, 200)) + near_obs(p - Vector2(200, 0)) + near_obs(p - Vector2(0, 200)):
		if p.distance_to(o.pos) < o.r + r * 0.5 + 20.0: return false
	return true

func add_spot(r: float, gap: float, kind: String):
	for i in 250:
		var p: Vector2 = R.cpos + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * R.cr
		if is_free(p, r, gap):
			var s := {"pos": p, "r": r, "k": kind}
			spots.append(s)
			return s
	return null

func add_mob(p: Vector2, el: bool, home: Vector2, lr: float) -> void:
	var n: int = R.night
	var hp := (34.0 + n * 34.0) * (2.2 if el else 1.0) * randf_range(0.85, 1.15)
	var types: Array = Data.BIOMES[bio_at(p)].types
	mobs.append({"pos": p, "home": home, "lr": lr, "hp": hp, "mhp": hp, "atk": (6.0 + n * 5.0) * (1.4 if el else 1.0), "df": 8.0 + n * 6.0,
		"r": 17.0 if el else 12.0, "sp": 60.0 + n * 10.0, "attr": ATTRS.pick_random(), "type": types.pick_random(), "rng": randf() < 0.3,
		"cd": randf_range(0.0, 2.0), "tc": 0.0, "xp": (10.0 + n * 4.0) * (3.0 if el else 1.0), "el": el, "ret": false, "aggro": false,
		"burn": 0.0, "bd": 0.0, "dd": 0.0, "df0": 0.0, "up": 0.0, "stun": 0.0, "lv": 2 + n * 3 + (3 if el else 0), "dragon": randf() < 0.1})

func add_mini(p: Vector2) -> void:
	add_mob(p, true, p, 520.0)
	var m: Dictionary = mobs[mobs.size() - 1]
	m.mini = true
	m.mhp *= 6.0 * Run.players
	m.hp = m.mhp
	m.atk *= 2.2
	m.r = 28.0
	m.xp *= 7.0
	m.sp *= 1.1
	m.mcd = 3.0

func gen_map() -> void:
	gen_bio()
	gen_obs()
	var ps = add_spot(260.0, 0.0, "start")
	P.pos = ps.pos if ps != null else R.cpos + Vector2(600, 0)
	for i in 6:
		var ms = add_spot(120.0, 500.0, "mini")
		if ms == null: break
		add_mini(ms.pos)
	for i in 40:
		var s = add_spot(150.0, 150.0, "camp")
		if s == null: break
		for k in 4:
			add_mob(s.pos + Vector2.from_angle(k / 4.0 * TAU + randf()) * randf_range(30.0, 70.0), k == 0, s.pos, 480.0)
		chests.append({"pos": s.pos, "open": false, "mon": false})
	for i in 24:
		var s = add_spot(70.0, 100.0, "roam")
		if s == null: break
		for k in 2 + randi() % 2:
			add_mob(s.pos + Vector2(randf_range(-40, 40), randf_range(-40, 40)), false, s.pos, 380.0)
	for i in 3:
		var s = add_spot(60.0, 400.0, "heal")
		if s != null: camps.append({"pos": s.pos, "used": false, "w": 0.0})
	var t := 0
	var made := 0
	while made < 14 and t < 1500 and not obs.is_empty():
		t += 1
		var o: Dictionary = obs.pick_random()
		var p: Vector2 = o.pos + Vector2.from_angle(randf() * TAU) * (o.r + 40.0)
		if is_free(p, 10.0, 60.0):
			spots.append({"pos": p, "r": 10.0, "k": "chest"})
			chests.append({"pos": p, "open": false, "mon": false})
			made += 1
	if not chests.is_empty():
		chests.pick_random().mon = true

func safe_room() -> void:
	R.mode = "safe"
	clear_lists()
	_rebuild_terrain_props()
	set_bounds(Rect2(0, 0, 900, 560))
	P.hp = P.mhp
	P.pos = Vector2(450, 500)
	door = {"pos": Vector2(450, 60), "w": 90.0}
	say("Safe area. Walk through the giant doors.")

func final_room() -> void:
	R.mode = "final"
	clear_lists()
	_rebuild_terrain_props()
	set_bounds(Rect2(0, 0, 900, 620))
	P.pos = Vector2(450, 560)
	spawn_boss("angemon", Vector2(450, 200))
	say("The False Drasil awaits.")

func spawn_boss(key: String, pos: Vector2) -> void:
	if key != "devimon": P.revive_used = false   # single-player: one revive per boss fight
	var d: Dictionary = Data.BOSSES[key]
	boss = {"key": key, "name": d.name, "attr": d.attr, "type": d.type, "hp": float(d.hp) * Run.players, "mhp": float(d.hp) * Run.players, "atk": float(d.atk) * BOSS_DMG * BOSS_SCALE.get(key, 1.0), "xp": float(d.xp),
		"df": 20.0, "r": BOSS_R[key], "pat": BOSS_PAT[key], "pi": 0, "cd": 2.0, "st": "", "t": 0.0, "tc": 0.0, "q": [], "dvec": Vector2.ZERO,
		"pil": 0.0, "pk": 0.0, "pos": pos, "burn": 0.0, "bd": 0.0, "dd": 0.0, "df0": 0.0, "up": 0.0, "stun": 0.0, "aggro": false, "is_boss": true, "lv": 20, "fight": 0.0, "patch_n": 0}

func say(t: String) -> void:
	R.msg = t
	R.msg_t = 5.0

func time_text() -> String:
	if R.mode == "safe": return "Safe area"
	if R.mode == "final": return "Night 3: False Drasil"
	var k: float = R.clock
	var t := "Night %d  " % R.night
	if k < 270.0: t += "Circle closes in " + fmt((270.0 - k) / R.speed)
	elif k < 450.0: t += "Final circle in " + fmt((450.0 - k) / R.speed)
	else: t += "Defeat the boss"
	if R.out > 0.0: t += "   CORRUPTION!"
	return t

func fmt(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]

# ------------------------------------------------------------------ input
func _unhandled_input(ev: InputEvent) -> void:
	if R.over: return
	if ev.is_action_pressed("inventory") or (ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE):
		hud.toggle_menu(0)
		get_viewport().set_input_as_handled()
		return
	if hud.menu_shell.visible:
		return
	if ev.is_action_pressed("digivolve") and Data.stage_for_level(P.lv) > P.stage:
		P.stage += 1
		recalc()
		heal(P.mhp * (0.3 + P.m.get("evo_heal", 0.0)))
		if P.m.has("evo_dmg"): add_tbuff({"dmg": P.m.evo_dmg}, 10.0)
		if P.stage >= 2: Save.set_mon(P.line, P.stage - 1)
		say("Digivolved into %s!" % nm())
	for i in 3:
		if ev.is_action_pressed("item%d" % (i + 1)): use_item(i)
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_L and P.lv < 15:
			P.xp = Data.xp_needed(P.lv)
			gain(0.0)

# ------------------------------------------------------------------ helpers
func sv() -> float:  # the stat this line scales with
	return P.st["int"] if Data.line_scaling(P.line) == "int" else atkv()

func skind() -> String:  # damage kind for this line
	return "spec" if Data.line_scaling(P.line) == "int" else "phys"

func atkv() -> float:
	return P.st.atk * (1.3 if P.buff.atk > 0 else 1.0) * (1.25 if P.ba > 0 else 1.0)

func crit() -> bool:
	return randf() * 100.0 < P.st.crit

func foes() -> Array:
	var a := mobs.duplicate()
	if boss != null: a.append(boss)
	return a

func txt(p: Vector2, s: String, col: Color) -> void:
	fx.append({"pos": p, "txt": s, "t": 0.9, "col": col})

func gain(x: float) -> void:
	P.xp += x * R.xpm * (1.0 + P.m.get("exp", 0.0) + (P.m.get("exp_low", 0.0) if P.stage < 2 else 0.0))
	while P.lv < 15 and P.xp >= Data.xp_needed(P.lv):
		P.xp -= Data.xp_needed(P.lv)
		P.lv += 1
		recalc()
		P.hp = minf(P.mhp, P.hp + P.mhp * 0.15)
		txt(P.pos + Vector2(0, -30), "Level up!", Color("#ffd84d"))
		if Data.stage_for_level(P.lv) > P.stage: say("You can digivolve! Press E.")
	if P.lv >= 15: P.xp = 0.0

func out_mult(e: Dictionary, kind: String, basic: bool, elemental: bool = false) -> float:
	var m: Dictionary = P.m
	var b: float = m.get("dmg", 0.0) + (m.get("phys", 0.0) if kind == "phys" else m.get("spec", 0.0))
	if basic: b += m.get("basic", 0.0)
	if e == boss: b += m.get("boss", 0.0)
	if e == boss or e.get("el", false): b += m.get("champ", 0.0)
	var r: float = e.hp / e.mhp
	if r > 0.75: b += m.get("hp_hi75", 0.0)
	if r > 0.8: b += m.get("hp_hi80", 0.0)
	if r < 0.25: b += m.get("lo25", 0.0)
	if r < 0.3: b += m.get("lo30", 0.0)
	if e.type == "Dark": b += m.get("vs_Dark", 0.0)
	if e.type == "Light": b += m.get("vs_Light", 0.0)
	if e.get("dragon", false): b += m.get("dragon", 0.0)
	if e.burn > 0.0 or e.stun > 0.0 or e.dd > 0.0: b += m.get("status", 0.0)
	if e.get("lv", 1) > P.lv: b += m.get("higher", 0.0)
	var hp: float = P.hp / P.mhp
	if hp > 0.8: b += m.get("self_hi80", 0.0)
	if hp < 0.5: b += m.get("self_lo50", 0.0)
	if hp < 0.4: b += m.get("self_lo40", 0.0)
	b += m.get("t_" + str(P.type), 0.0) + m.get("elem", 0.0)  # every move is of the Digimon's typing: typing damage bonuses always apply
	if P.weak_t > 0.0: b += m.get("weak", 0.0)
	if P.war_t > 0.0: b += m.get("war_drum", 0.0)
	return maxf(0.1, 1.0 + b)

func heal(a: float) -> void:
	P.hp = minf(P.mhp, P.hp + a * (1.0 + P.m.get("heal_in", 0.0)))
	P.heal_t = 2.0

func add_tbuff(fx: Dictionary, t: float) -> void:
	P.tb.append({"fx": fx, "t": t})
	recalc()

func hit_enemy(e: Dictionary, base: float, src: Dictionary, is_crit: bool, kind: String = "spec", basic: bool = false, elemental: bool = false) -> void:
	var tm := Data.type_mult(src.attr, src.type, e.attr, e.type)
	var cm: float = 1.0
	if is_crit: cm = 1.7 * (1.0 + float(P.m.get("crit_dmg", 0.0)))
	var d := Data.damage(base * out_mult(e, kind, basic, elemental), tm, e.df * (1.0 - (e.get("wd", 0.0) if kind == "spec" else 0.0)), cm)
	e.hp -= d
	e.aggro = true
	if tm > 1.2 and P.m.has("weak"): P.weak_t = 5.0
	if is_crit and P.m.has("nail") and P.nail_cd <= 0.0:
		heal(P.mhp * P.m.nail)
		P.nail_cd = 2.0
	var col := Color.WHITE
	if is_crit: col = Color("#ffd84d")
	elif tm > 1.2: col = Color("#ff9a4d")
	txt(e.pos + Vector2(0, -e.r), str(int(d)) + (" !" if tm > 1.2 else (" ~" if tm < 0.9 else "")), col)

func boss_fight() -> bool:
	return (boss != null and R.mode == "night") or R.mode == "final"

func any_ally_alive() -> bool:
	for a in allies:
		if not a.downed and a.hp > 0.0: return true
	return false

func find_safe_spot(from: Vector2) -> Vector2:
	for i in 80:
		var p: Vector2 = from + Vector2.from_angle(randf() * TAU) * randf_range(250.0, 650.0)
		p = p.clamp(B.position + Vector2(60, 60), B.end - Vector2(60, 60))
		if R.mode == "night" and p.distance_to(R.cpos) > R.cr - 120.0: continue
		if hits_obs(p): continue
		var ok := true
		for e in mobs:
			if e.pos.distance_to(p) < 380.0:
				ok = false
				break
		if ok: return p
	return from

func respawn_safe(msg: String) -> void:
	P.pos = find_safe_spot(P.pos)
	P.hp = P.mhp * 0.5
	P.inv = 2.0
	P.stun_t = 0.0
	P.pull_t = 0.0
	P.kb_t = 0.0
	P.dash = 0.0
	P.ch = null
	R.out = 0.0
	say(msg)

func on_zero_hp() -> void:
	if R.over: return
	if Run.players <= 1:
		if boss_fight():
			# single player, boss fight: one revive per fight, exactly where you fell, at 50% HP
			if not P.revive_used:
				P.revive_used = true
				P.hp = P.mhp * 0.5
				P.inv = 2.0
				P.stun_t = 0.0
				P.pull_t = 0.0
				txt(P.pos + Vector2(0, -40), "Revived at 50% HP!", Color("#77ff77"))
				say("You were revived. This only happens once per boss fight.")
			else:
				end_run(false)
		else:
			respawn_safe("You were defeated and respawned at a safe spot.")
	else:
		# multiplayer rules: downed for 45s; if the last player alive falls in a boss fight the expedition is lost
		if boss_fight() and not any_ally_alive():
			end_run(false)
			return
		P.downed = true
		P.down_t = 45.0
		P.hp = 0.0
		P.dash = 0.0
		P.ch = null
		say("You are downed! Wait to be revived (45s).")

func update_down(dt: float) -> void:
	if P.downed:
		P.down_t -= dt
		if P.down_t <= 0.0:
			P.downed = false
			if boss_fight(): end_run(false)
			else: respawn_safe("You were not revived and respawned at a safe spot.")
	var near = null
	if not P.downed:
		for a in allies:
			if a.downed and a.pos.distance_to(P.pos) < 80.0:
				near = a
				break
	var reviving: bool = near != null and Input.is_action_pressed("attack") and P.hurt_t <= 0.0 and P.stun_t <= 0.0
	P.reviving = reviving
	for a in allies:
		if not a.downed: continue
		a.down_t -= dt
		if a == near and reviving:
			a.rev_p += dt
			if a.rev_p >= 5.0:
				a.downed = false
				a.hp = a.mhp * 0.5
				a.rev_p = 0.0
				txt(a.pos + Vector2(0, -30), "Revived!", Color("#77ff77"))
		else:
			a.rev_p = maxf(0.0, a.rev_p - 0.5 * dt)   # progress drops 1s every 2s while not being revived
		if a.downed and a.down_t <= 0.0:
			a.downed = false
			a.pos = find_safe_spot(a.pos)
			a.hp = a.mhp * 0.5
	if boss_fight() and P.downed and not any_ally_alive(): end_run(false)

func lose_hp(a: float) -> void:
	if P.downed: return
	if P.shield > 0.0:
		var ab := minf(P.shield, a)
		P.shield -= ab
		a -= ab
	P.hp -= a
	P.ct = 5.0
	if P.hp <= 0.0:
		if P.m.has("phoenix") and not P.phoenix_used:
			P.phoenix_used = true
			P.hp = P.mhp * 0.1
			P.inv = 1.5
			txt(P.pos + Vector2(0, -40), "Phoenix Insignia!", Color("#ffb347"))
		else:
			on_zero_hp()

func stun_player(t: float) -> void:
	P.stun_t = t * (1.0 - P.m.get("stat_dur", 0.0))
	P.dash = 0.0
	P.ch = null
	txt(P.pos + Vector2(0, -30), "Chained!", Color("#ffe066"))

func hurt(dmg: float, src: Dictionary, kind: String) -> float:
	if P.inv > 0.0 or R.over or P.downed: return 0.0
	var m: Dictionary = P.m
	var hpr: float = P.hp / P.mhp
	var defn: float = P.st.def if kind == "phys" else P.st.wis
	if P.bd > 0.0: defn *= 1.0 + P.bdv
	if hpr < 0.3: defn *= 1.0 + m.get("def_lo30", 0.0)
	var dr: float = m.get("dr", 0.0) + m.get("dr_elem", 0.0) + m.get("td_" + str(src.type), 0.0)
	dr += m.get("dr_phys", 0.0) if kind == "phys" else m.get("dr_spec", 0.0)
	if src.get("is_boss", false): dr += m.get("dr_boss", 0.0)
	if hpr > 0.7: dr += m.get("dr_hi70", 0.0)
	if hpr < 0.4: dr += m.get("dr_lo40", 0.0)
	var d: float = dmg * Data.type_mult(src.attr, src.type, P.attr, P.type) * 40.0 / (40.0 + defn) * clampf(1.0 - dr, 0.2, 1.6)
	if src.type == "Light": d *= 1.0 + P.res_l
	elif src.type == "Dark": d *= 1.0 + P.res_d
	P.inv = 0.2
	P.hurt_t = 0.3
	txt(P.pos + Vector2(0, -20), "-" + str(int(d)), Color("#ff6b6b"))
	lose_hp(d)
	return d

func burn(e: Dictionary, ch: float) -> void:
	if randf() < ch:
		e.burn = 4.0
		e.bd = sv() * 0.35 + 2.0

func ddown(e: Dictionary, p: float, t: float) -> void:
	if e.df0 == 0.0: e.df0 = e.df
	e.df = e.df0 * (1.0 - p)
	e.dd = t

func boss_like(e: Dictionary) -> bool:
	return e == boss or e.get("mini", false)

func stun_e(e: Dictionary, t: float) -> void:
	e.stun = t * (0.5 if boss_like(e) else 1.0)   # bosses, mini bosses and False Drasils are stunned for half as long
	e.up = 0.5

func tick(e: Dictionary, dt: float) -> void:
	var k: float = 2.0 if boss_like(e) else 1.0   # statuses and debuffs wear off twice as fast on bosses
	if e.burn > 0.0:
		e.burn -= dt * k
		e.hp -= e.bd * dt
	if e.dd > 0.0:
		e.dd -= dt * k
		if e.dd <= 0.0: e.df = e.df0
	if e.up > 0.0: e.up -= dt
	if e.get("pois", 0.0) > 0.0:
		e.pois -= dt * k
		e.hp -= e.get("pd", 2.0) * dt
	if e.get("wt", 0.0) > 0.0:
		e.wt -= dt * k
		if e.wt <= 0.0: e.wd = 0.0

# ---- attacks used by the kit scripts (restored)
func in_cone(e: Dictionary, rng: float, arc: float) -> bool:
	var d: float = P.pos.distance_to(e.pos)
	if d > rng + e.r: return false
	return absf(angle_difference(P.face, (e.pos - P.pos).angle())) <= arc / 2.0 or d < e.r + P.r + 8.0

func cone(rng: float, arc: float, dmg: float, fn: Callable, col: Color, kind: String = "spec", basic: bool = false, elemental: bool = false) -> void:
	P.at = 0.35
	for e in foes():
		if in_cone(e, rng, arc):
			hit_enemy(e, dmg, P, crit(), kind, basic, elemental)
			if fn.is_valid(): fn.call(e)
	fx.append({"pos": P.pos, "cone": true, "a": P.face, "rng": rng, "arc": arc, "t": 0.25, "col": col})

func beam(length: float, width: float, dmg: float, kind: String, fn: Callable, col: Color, basic: bool = false, elemental: bool = false) -> void:
	P.at = 0.35
	var a: Vector2 = P.pos
	var b: Vector2 = a + Vector2.from_angle(P.face) * length
	for e in foes():
		if Geometry2D.get_closest_point_to_segment(e.pos, a, b).distance_to(e.pos) < width / 2.0 + e.r:
			hit_enemy(e, dmg, P, crit(), kind, basic, elemental)
			if fn.is_valid(): fn.call(e)
	fx.append({"line_a": a, "line_b": b, "t": 0.25, "col": col, "w": width})

func wdown(e: Dictionary, amt: float, t: float) -> void:
	e.wd = amt
	e.wt = t

func poison(e: Dictionary, t: float, dps: float) -> void:
	e.pois = t
	e.pd = dps

func proj(o: Dictionary) -> void:
	P.at = 0.35
	var a: float = P.face + o.get("da", 0.0)
	var h := {"pos": P.pos + Vector2.from_angle(a) * 20.0, "vel": Vector2.from_angle(a) * o.sp, "r": 8.0, "kind": "spec", "from": "p", "crit": crit()}
	h.merge(o, true)
	shots.append(h)

func explode(h: Dictionary) -> void:
	h.done = true
	var cnt := 0
	for e in foes():
		if h.pos.distance_to(e.pos) < h.ex + e.r:
			cnt += 1
			hit_enemy(e, h.exd, P, false, h.kind, false, h.get("elem", false))
			if h.has("xf"): h.xf.call(e)
	fx.append({"pos": h.pos, "ring": h.ex, "t": 0.35, "col": Color("#ff7a3d")})
	if h.has("af"): h.af.call(cnt)

func p_hit(h: Dictionary, e: Dictionary) -> void:
	hit_enemy(e, h.dmg, P, h.crit, h.kind, h.get("basic", false), h.get("elem", false))
	if h.has("hf"): h.hf.call(e)
	h.life = 0.0
	if h.has("ex") and not h.get("done", false): explode(h)

func rush(sp: float, t: float, k: String, mul: float = 2.4, fn: Callable = Callable(), stop: bool = false, pad: float = 14.0, elem: bool = false) -> void:
	P.at = 0.35
	P.dash = t
	P.inv = maxf(P.inv, t + 0.05)
	P.dvel = Vector2.from_angle(P.face) * sp
	P.dk = k
	P.dset = []
	P.dmul = mul
	P.dfn = fn
	P.dstop = stop
	P.dpad = pad
	P.delem = elem

func rush_hit() -> void:
	for e in foes():
		if not P.dset.has(e) and P.pos.distance_to(e.pos) < e.r + P.r + P.dpad:
			P.dset.append(e)
			hit_enemy(e, sv() * P.dmul, P, crit(), skind(), false, P.get("delem", false))
			if P.dfn.is_valid(): P.dfn.call(e)
			if P.dstop:
				P.dash = 0.0
				break

func blast(rad: float, base: float) -> void:
	P.at = 0.35
	for e in foes():
		if P.pos.distance_to(e.pos) < rad + e.r: hit_enemy(e, base, P, false, skind())
	fx.append({"pos": P.pos, "ring": rad, "t": 0.35, "col": Color(Data.TYPE_COLORS[P.type])})

func eshot(pos: Vector2, ang: float, sp: float, dmg: float, src: Dictionary, kind: String) -> void:
	shots.append({"pos": pos, "vel": Vector2.from_angle(ang) * sp, "r": 7.0, "dmg": dmg, "kind": kind, "from": "e", "src": src, "life": 4.0})

func fan(b: Dictionary, n: int, spread: float, sp: float) -> void:
	var a: float = (P.pos - b.pos).angle()
	for i in n:
		eshot(b.pos, a + (i - (n - 1) / 2.0) * spread / (n - 1), sp, b.atk, b, "spec")

func use_item(i: int) -> void:
	if i >= P.items.size(): return
	var it: Dictionary = P.items[i]
	if it.has("revive"):
		say("No downed teammate to revive (needs multiplayer).")
		return
	it.n -= 1
	if it.n <= 0: P.items.remove_at(i)
	if it.has("heal"): heal(P.mhp * it.heal)
	if it.has("team"): heal(P.mhp * it.team)
	if it.has("sp"):
		P.cd.q *= 1.0 - it.sp
		P.cd.r *= 1.0 - it.sp
	if it.has("bandage"): heal(P.mhp * 0.08)
	if it.has("antidote"): P.poison_imm = 3.0
	if it.has("cleanse"): P.stun_t = 0.0
	if it.has("suppress"): P.supp = it.suppress
	if it.has("shield"):
		P.shield = P.mhp * it.shield
		P.shield_t = 8.0
	if it.has("buff"): add_tbuff(it.buff, it.dur)
	txt(P.pos + Vector2(0, -24), it.name, Color("#77ffff"))

func pickup_item(it: Dictionary) -> bool:
	for s in P.items:
		if s.name == it.name and s.n < 3:   # items stack up to 3 per slot
			s.n += 1
			return true
	if P.items.size() < 3:
		var c: Dictionary = it.duplicate(true)
		c.n = 1
		P.items.append(c)
		return true
	return false

func drop_item(i: int) -> void:
	if i >= P.items.size(): return
	var it: Dictionary = P.items[i]
	var one: Dictionary = it.duplicate(true)
	one.n = 1
	drops.append({"k": "items", "d": one, "pos": P.pos + Vector2(randf_range(-30, 30), randf_range(20, 40)), "t": 1.5})
	it.n -= 1
	if it.n <= 0: P.items.remove_at(i)

func drop_card(i: int) -> void:
	if i >= P.cards.size(): return
	drops.append({"k": "cards", "d": P.cards[i], "pos": P.pos + Vector2(randf_range(-30, 30), randf_range(20, 40)), "t": 1.5})
	P.cards.remove_at(i)
	recalc()

func roll_drop(p: Vector2, chest: bool = false) -> void:
	var wc: Array = [0.6, 0.3, 0.1] if chest else [0.72, 0.23, 0.05]
	if randf() < 0.55:
		drops.append({"k": "cards", "d": Data.random_card(wc), "pos": p, "t": 0.0})
	else:
		drops.append({"k": "items", "d": Data.random_item(wc), "pos": p, "t": 0.0})

func kill_mob(m: Dictionary) -> void:
	gain(m.xp)
	if m.get("mini", false):
		for i in 4: roll_drop(m.pos + Vector2.from_angle(randf() * TAU) * randf_range(20.0, 60.0), true)
		say("Mini boss defeated!")
	elif randf() < (0.2 if m.el else 0.06): roll_drop(m.pos)
	if m.el and P.m.has("jack"):
		heal(P.mhp * 0.03)
		add_tbuff({"atk": 0.05}, 10.0)
	if P.m.has("war_drum") and P.war_cd <= 0.0:
		P.war_t = 5.0
		P.war_cd = 8.0

# ------------------------------------------------------------------ main update
func _physics_process(dt: float) -> void:
	if R.over: return
	update(dt)
	_sync_terrain()
	_sync_3d_actors()
	queue_redraw()
	hud.refresh()

func update(dt: float) -> void:
	var s: Dictionary = P.st
	for k in ["atk", "spd", "sh"]: P.buff[k] = maxf(0.0, P.buff[k] - dt)
	for k in ["a", "q", "d", "r"]: P.cd[k] -= dt
	P.inv -= dt
	R.msg_t -= dt
	P.ct = maxf(0.0, P.ct - dt)
	P.bd = maxf(0.0, P.bd - dt)
	P.ba = maxf(0.0, P.ba - dt)
	P.at = maxf(0.0, P.at - dt)
	P.hurt_t = maxf(0.0, P.hurt_t - dt)
	for k in ["stun_t", "pull_t", "supp", "weak_t", "war_t", "war_cd", "nail_cd", "poison_imm", "shield_t", "kb_t", "slow_t", "res_t", "heal_t"]:
		P[k] = maxf(0.0, P[k] - dt)
	if P.shield_t <= 0.0: P.shield = 0.0
	if P.res_t <= 0.0:
		P.res_l = 0.0
		P.res_d = 0.0
	update_down(dt)
	Kit.tick(self, dt)
	for tbf in P.tb: tbf.t -= dt
	var keep: Array = P.tb.filter(func(x): return x.t > 0.0)
	if keep.size() != P.tb.size():
		P.tb = keep
		recalc()
	if P.rg > 0.0:
		P.rg -= dt
		heal(P.mhp * 0.03 * dt)
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var locked: bool = P.stun_t > 0.0 or P.pull_t > 0.0 or P.kb_t > 0.0 or P.downed
	if locked: dir = Vector2.ZERO
	if P.pull_t > 0.0 and boss != null:
		P.pos = P.pos.move_toward(boss.pos + (P.pos - boss.pos).normalized() * (boss.r + P.r + 4.0), 1100.0 * dt)
	if P.kb_t > 0.0: P.pos += P.kb_v * dt
	P.mv = dir != Vector2.ZERO
	var sp: float = 175.0 * s.spd * (1.3 if P.buff.spd > 0 else 1.0) * (0.4 if P.ch != null else 1.0) * ((1.0 - P.slow) if P.slow_t > 0.0 else 1.0)
	if P.dash > 0.0:
		P.pos += P.dvel * dt
		P.mvel = P.dvel
		P.dash -= dt
	else:
		P.pos += dir * sp * dt
		P.mvel = dir * sp
	P.pos = P.pos.clamp(B.position + Vector2(P.r, P.r), B.end - Vector2(P.r, P.r))
	push_out(P)
	if P.dash > 0.0 and P.dk != "": rush_hit()
	if P.ch != null:
		P.ch.t -= dt
		P.ch.k -= dt
		if P.ch.k <= 0.0 and P.ch.t > 0.0:
			P.ch.k = 0.25
			if P.ch.f.is_valid(): P.ch.f.call()
		if P.ch.t <= 0.0:
			var en: Callable = P.ch.end
			P.ch = null
			if en.is_valid(): en.call()
	P.face = (get_global_mouse_position() - P.pos).angle()
	cam.global_position = P.pos
	# attacks
	if Input.is_action_pressed("attack") and P.cd.a <= 0.0 and P.dash <= 0.0 and not locked and not P.reviving:
		P.cd.a = 0.6 / s.aspd
		if Kit.has_kit(P.line):
			Kit.basic(self)
		else:
			P.at = 0.35
			shots.append({"pos": P.pos, "vel": Vector2.from_angle(P.face) * 520.0, "r": 6.0, "dmg": sv(), "kind": skind(), "from": "p", "life": 0.5, "crit": crit(), "basic": true})
	if Input.is_action_pressed("skill1") and P.cd.q <= 0.0 and P.ch == null and not locked:
		if Kit.has_kit(P.line):
			Kit.skill(self, 1)
		else:
			P.cd.q = 6.0
			blast(120.0, sv() * 2.2)
			if P.cls == "Support": P.hp = minf(P.mhp, P.hp + P.mhp * 0.2)
	if Input.is_action_pressed("ultimate") and P.cd.r <= 0.0 and Kit.has_kit(P.line) and P.ch == null and not locked:
		Kit.skill(self, 2)
	P.stam_t = maxf(0.0, P.stam_t - dt)
	if P.stam_t <= 0.0 and P.dash <= 0.0: P.stam = minf(100.0, P.stam + 21.0 * dt)
	if P.stam_lock and P.stam >= 100.0: P.stam_lock = false
	if Input.is_action_just_pressed("dodge") and P.cd.d <= 0.0 and not locked and not P.stam_lock and P.stam > 0.0:
		P.cd.d = 0.35
		P.stam = maxf(0.0, P.stam - 30.0)
		P.stam_t = 0.8
		if P.stam <= 0.0: P.stam_lock = true
		P.dash = 0.2
		P.inv = 0.28 * (1.0 + P.m.get("evade", 0.0))
		P.dk = ""
		var dd := dir if dir != Vector2.ZERO else Vector2.from_angle(P.face)
		P.dvel = dd * 450.0
	if R.mode == "night": update_night(dt)
	if door != null and P.pos.y < 110.0 and absf(P.pos.x - door.pos.x) < door.w: final_room()
	update_shots(dt)
	update_mobs(dt)
	if boss != null:
		tick(boss, dt)
		boss_ai(boss, dt)
		if boss.hp <= 0.0: boss_down()
	update_world(dt)

func update_night(dt: float) -> void:
	R.clock += dt * R.speed
	var k: float = R.clock
	var cx := int(P.pos.x / 100.0)
	var cy := int(P.pos.y / 100.0)
	for i in range(-3, 4):
		for j in range(-3, 4):
			var gx := cx + i
			var gy := cy + j
			if gx >= 0 and gy >= 0 and gx < GRID and gy < GRID and i * i + j * j <= 10: R.fog[gy * GRID + gx] = 1
	var sg := 0 if k < 270.0 else (1 if k < 450.0 else 2)
	if sg > R.sg:
		R.sg = sg
		R.a = {"pos": R.cpos, "r": R.cr}
		R.p = 0.0
		say("The corruption begins to close in." if sg == 1 else "The final circle is closing.")
	if R.sg > 0 and R.p < 1.0:
		R.p = minf(1.0, R.p + dt / 30.0)
		var t: Dictionary = R.chain[R.sg]
		var e: float = R.p * R.p * (3.0 - 2.0 * R.p)
		R.cpos = R.a.pos.lerp(t.pos, e)
		R.cr = lerpf(R.a.r, t.r, e)
	if k >= 450.0 and not R.boss_up and R.sg == 2 and R.p >= 1.0:
		R.boss_up = true
		spawn_boss("reppamon" if R.night == 1 else "sangloupmon", R.cpos)
		say("The boss room opens at the center of the circle.")
	if P.pos.distance_to(R.cpos) > R.cr:
		if P.supp <= 0.0:
			R.out += dt
			lose_hp(P.mhp * 0.015 * (1.0 + R.out * 0.6) * dt * (1.0 - P.m.get("hazard", 0.0)))
	else:
		R.out = maxf(0.0, R.out - dt * 2.0)

func update_shots(dt: float) -> void:
	for h in shots:
		h.pos += h.vel * dt
		h.life -= dt
		if h.has("ret"):
			if h.get("ph", 0) == 0:
				h.ot = h.get("ot", 0.9) - dt
				if h.ot <= 0.0:
					h.ph = 1
					h.hit = false
			elif boss != null:
				var tbv: Vector2 = boss.pos - h.pos
				h.vel = tbv.normalized() * 560.0
				if tbv.length() < boss.r + h.r: h.life = 0.0
		if h.from == "p":
			for e in foes():
				if h.life > 0.0 and h.pos.distance_to(e.pos) < e.r + h.r: p_hit(h, e)
		elif h.pos.distance_to(P.pos) < P.r + h.r and not h.get("hit", false):
			var dd: float = hurt(h.dmg, h.src, h.kind)
			if not h.get("pierce", false): h.life = 0.0
			h.hit = true
			if dd > 0.0 and h.has("leech") and boss != null: boss.hp = minf(boss.mhp, boss.hp + boss.mhp * h.leech)
		if not B.has_point(h.pos) or hits_obs(h.pos): h.life = 0.0
	for h in shots:
		if h.life <= 0.0 and h.get("end_ex", false) and not h.get("done", false): explode(h)
	shots = shots.filter(func(h): return h.life > 0.0)

func update_mobs(dt: float) -> void:
	for e in mobs:
		if e.pos.distance_to(P.pos) > 1100.0: continue
		tick(e, dt)
		if e.stun > 0.0:
			e.stun -= dt
			continue
		var d: float = e.pos.distance_to(P.pos)
		var dh: float = e.pos.distance_to(e.home)
		e.cd -= dt
		e.tc -= dt
		if dh > e.lr: e.ret = true
		if e.ret:
			e.pos += (e.home - e.pos).normalized() * e.sp * 1.6 * dt
			if dh < 30.0:
				e.ret = false
				e.aggro = false
		elif d < 280.0 or e.aggro:
			var hold := 200.0 if e.rng else 0.0
			if d > hold: e.pos += (P.pos - e.pos).normalized() * e.sp * dt
			if e.rng and e.cd <= 0.0 and d < 420.0:
				e.cd = 2.0
				eshot(e.pos, (P.pos - e.pos).angle(), 260.0, e.atk, e, "spec")
		if e.get("mini", false) and not e.ret and d < 600.0:
			e.mcd -= dt
			if e.mcd <= 0.0:
				e.mcd = 4.0
				for i in 10: eshot(e.pos, i / 10.0 * TAU, 240.0, e.atk * 0.8, e, "spec")
		push_out(e)
		if d < e.r + P.r and e.tc <= 0.0 and not e.ret:
			hurt(e.atk, e, "phys")
			e.tc = 0.9
	for m in mobs:
		if m.hp <= 0.0: kill_mob(m)
	mobs = mobs.filter(func(m): return m.hp > 0.0)

func boss_ai(b: Dictionary, dt: float) -> void:
	if b.st == "" and b.q.is_empty(): b.cd -= dt
	b.tc -= dt
	Bosses.tick(self, b, dt)
	if b.stun > 0.0:
		b.stun -= dt
		return
	for q in b.q: q.t -= dt
	for q in b.q:
		if q.t <= 0.0:
			if q.has("fn"): q.fn.call()
			else: fan(b, 5, 0.9, 300.0)
	b.q = b.q.filter(func(q): return q.t > 0.0)
	if b.st == "dash":
		b.pos += b.dvec * 950.0 * dt
		b.t -= dt
		if b.t <= 0.0: b.st = ""
	elif b.st == "tele":
		b.t -= dt
		if b.t <= 0.0:
			b.st = "dash"
			b.t = 0.4
	elif b.st == "vdash":
		Bosses.vdash(self, b, dt)
	else:
		Bosses.move(self, b, dt)
		if b.cd <= 0.0:
			var p: String = Bosses.choose(self, b)
			b.cd = 1.4 * BOSS_CD.get(b.key, 1.0) * Bosses.cd_scale(self, b)
			Bosses.act(self, b, p)
	b.pos = b.pos.clamp(B.position + Vector2(b.r, b.r), B.end - Vector2(b.r, b.r))
	if b.st != "vdash" and P.pos.distance_to(b.pos) < b.r + P.r and b.tc <= 0.0:
		hurt(b.atk * (1.6 if b.st == "dash" else 0.7), b, "phys")
		b.tc = 0.6

func boss_down() -> void:
	var b: Dictionary = boss
	gain(b.xp)
	shots.clear()
	pillars.clear()
	patches.clear()
	chains.clear()
	claws.clear()
	trails.clear()
	if b.key == "angemon":
		spawn_boss("devimon", b.pos)
		say("Angemon is consumed by the Dark Area. Devimon rises!")
		return
	boss = null
	if b.key == "devimon":
		end_run(true)
		return
	R.cleared += 1
	if R.night == 1:
		R.night = 2
		P.hp = minf(P.mhp, P.hp + P.mhp * 0.5)
		start_night()
	else:
		safe_room()

func update_world(dt: float) -> void:
	for c in chests:
		if not c.open and P.pos.distance_to(c.pos) < 30.0:
			c.open = true
			roll_drop(c.pos + Vector2(20, 0), true)
			if c.mon and Save.mon_count(P.line) < 3:
				Save.set_mon(P.line, Save.mon_count(P.line) + 1)
				say("You found a .mon file!")
	for c in camps:
		if not c.used and P.pos.distance_to(c.pos) < 50.0:
			if P.ct > 0.0:
				if c.w <= 0.0:
					c.w = 1.0
					txt(P.pos + Vector2(0, -24), "Cannot rest while under attack", Color("#ff8888"))
			else:
				c.used = true
				P.hp = P.mhp
				txt(P.pos + Vector2(0, -24), "Fully restored", Color("#77ff77"))
		c.w = maxf(0.0, c.w - dt)
	for d in drops:
		d.t -= dt
		if d.t <= 0.0 and P.pos.distance_to(d.pos) < 26.0:
			if d.k == "items":
				if pickup_item(d.d):
					d.got = true
					txt(P.pos + Vector2(0, -24), d.d.name, Color("#77ffff"))
			elif P.cards.size() < 6:
				P.cards.append(d.d)
				d.got = true
				recalc()
				txt(P.pos + Vector2(0, -24), d.d.name, Color("#77ffff"))
	drops = drops.filter(func(d): return not d.has("got"))
	Bosses.world(self, dt)
	for f in fx:
		f.t -= dt
		if f.has("txt"): f.pos.y -= 24.0 * dt
	fx = fx.filter(func(f): return f.t > 0.0)

func end_run(win: bool) -> void:
	if R.over: return
	R.over = true
	var core: int = 60 * R.cleared + (200 if win else 0) + P.lv * 10
	Save.core += core
	var n := 3 if win else (2 if R.cleared >= 1 else 1)
	var w := [0.50, 0.32, 0.15, 0.03] if win else [0.62, 0.28, 0.09, 0.01]
	var got: Array = []
	for i in n:
		var d: Dictionary = Data.random_equip(w)
		Save.owned.append({"u": Save.next_uid, "id": d.name})
		Save.next_uid += 1
		got.append("%s (%s)" % [d.name, Data.RARITIES[d.rar]])
	if win: Save.set_mon(P.line, 3)
	Save.save_game()
	Run.last_result = {"win": win, "lv": P.lv, "name": nm(), "cleared": R.cleared, "core": core, "got": got}
	get_tree().call_deferred("change_scene_to_file", "res://scenes/hub.tscn")

# ------------------------------------------------------------------ drawing (placeholder art)
func tcol(t: String) -> Color:
	return Color(Data.TYPE_COLORS[t])

func acol(a: String) -> Color:
	return {"Vaccine": Color.WHITE, "Virus": Color("#d04bff"), "Data": Color("#35e0ff")}[a]

func ent(pos: Vector2, r: float, t: String, a: String, face := NAN) -> void:
	draw_circle(pos, r, tcol(t))
	draw_arc(pos, r, 0.0, TAU, 24, acol(a), 3.0)
	if not is_nan(face): draw_circle(pos + Vector2.from_angle(face) * r * 0.55, r * 0.2, Color.BLACK)

func label(p: Vector2, s: String, size := 12, col := Color.WHITE) -> void:
	draw_string(font, p + Vector2(-60, 0), s, HORIZONTAL_ALIGNMENT_CENTER, 120, size, col)

func hpbar(p: Vector2, w: float, v: float) -> void:
	draw_rect(Rect2(p.x - w / 2.0, p.y, w, 4), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(p.x - w / 2.0, p.y, w * clampf(v, 0.0, 1.0), 4), Color("#e5484d"))

func _draw() -> void:
	if P.is_empty() or R.is_empty(): return
	var vp := get_viewport_rect().size
	var screen_center: Vector2 = cam.get_screen_center_position()
	var view := Rect2(screen_center - vp / 2.0 - Vector2(80, 80), vp + Vector2(160, 160))
	if R.mode == "night":
		# The 3D orthographic terrain replaces the old flat colored biome tiles.
		if terrain_view != null:
			draw_texture_rect(terrain_view.get_texture(), Rect2(screen_center - vp * 0.5, vp), false)
		draw_arc(R.fc, 440.0, 0.0, TAU, 48, Color(0.7, 0.42, 1.0, 0.35), 3.0)
		draw_arc(R.fc, 330.0, 0.0, TAU, 48, Color(0.7, 0.42, 1.0, 0.35), 3.0)
		# Characters, enemies, projectiles, camps, and obstacles now share
		# one 3D coordinate system. No duplicate 2D world entities.
		draw_arc(R.cpos, R.cr, 0.0, TAU, 128, Color("#c77dff"), 3.0)
		return
	else:
		draw_rect(B, Color("#14101f"))
	draw_rect(B, Color("#8a7cc0"), false, 3.0)
	if door != null:
		draw_rect(Rect2(door.pos.x - door.w, door.pos.y - 40, door.w * 2, 60), Color("#d9b45a"))
		label(door.pos, "GIANT DOORS", 12, Color.BLACK)
	# Obstacles and camps are now 3D objects at their gameplay positions.
	for c in chests:
		if P.pos.distance_to(c.pos) < 240.0: draw_rect(Rect2(c.pos - Vector2(10, 8), Vector2(20, 16)), Color("#555555") if c.open else Color("#e3a93b"))
	for d in drops:
		draw_rect(Rect2(d.pos - Vector2(7, 7), Vector2(14, 14)), Color("#4de0ff") if d.k == "items" else Color("#ff8ad8"))
		label(d.pos + Vector2(0, -10), d.d.name, 10)
	for e in mobs:
		if not view.has_point(e.pos): continue
		ent(e.pos + Vector2(0, -14 if e.up > 0.0 else 0), e.r, e.type, e.attr)
		if e.burn > 0.0: draw_rect(Rect2(e.pos.x - 3, e.pos.y - e.r - 14, 6, 4), Color("#ff7a3d"))
		if e.get("pois", 0.0) > 0.0: draw_rect(Rect2(e.pos.x + 4, e.pos.y - e.r - 14, 6, 4), Color("#5ccb5f"))
		if e.stun > 0.0: draw_arc(e.pos, e.r + 3.0, 0.0, TAU, 16, Color("#9fe8ff"), 3.0)
		hpbar(e.pos + Vector2(0, -e.r - 8), 64.0 if e.get("mini", false) else 28.0, e.hp / e.mhp)
		if e.get("mini", false):
			draw_arc(e.pos, e.r + 5.0, 0.0, TAU, 24, Color("#ffd23d"), 3.0)
			label(e.pos + Vector2(0, -e.r - 16), "MINI BOSS", 12, Color("#ffd23d"))
	if boss != null:
		ent(boss.pos, boss.r, boss.type, boss.attr)
		if boss.stun > 0.0: draw_arc(boss.pos, boss.r + 6.0, 0.0, TAU, 24, Color("#9fe8ff"), 4.0)
		if boss.st == "tele" or boss.st == "claw": draw_line(boss.pos, boss.pos + boss.dvec * (520.0 if boss.st == "claw" else 400.0), Color("#ff5555"), 2.0)
		label(boss.pos + Vector2(0, boss.r + 14), boss.name)
	Bosses.draw(self)
	Kit.draw(self)
	for h in shots:
		draw_circle(h.pos, h.r, h.get("col", tcol(P.type) if h.from == "p" else Color("#ff5c8a")))
	ent(P.pos, P.r + P.stage * 3, P.type, P.attr, P.face)
	if P.stun_t > 0.0: draw_arc(P.pos, P.r + 10.0, 0.0, TAU, 24, Color("#ffe066"), 4.0)
	if P.shield > 0.0: draw_arc(P.pos, P.r + 6.0, 0.0, TAU, 24, Color("#66ccff"), 3.0)
	label(P.pos + Vector2(0, P.r + P.stage * 3 + 14), ("DOWNED %ds" % int(P.down_t)) if P.downed else nm())
	for f in fx:
		if f.has("cone"):
			var c: Color = f.col
			draw_colored_polygon(cone_poly(f), Color(c, f.t * 2.0))
		elif f.has("line_a"):
			draw_line(f.line_a, f.line_b, Color(f.col, minf(1.0, f.t * 4.0)), f.get("w", 8.0))
		elif f.has("ring"):
			draw_arc(f.pos, f.ring * (1.0 - f.t / 0.35 * 0.4), 0.0, TAU, 32, Color(f.col, minf(1.0, f.t * 2.5)), 4.0)
		else:
			label(f.pos, f.txt, 14, f.col)
	if R.mode == "night":
		draw_arc(R.cpos, R.cr + 1500.0, 0.0, TAU, 128, Color(0.29, 0.04, 0.48, 0.55), 3000.0)
		draw_arc(R.cpos, R.cr, 0.0, TAU, 128, Color("#c77dff"), 3.0)

func cone_poly(f: Dictionary) -> PackedVector2Array:
	var pts := PackedVector2Array([f.pos])
	for i in 13:
		pts.append(f.pos + Vector2.from_angle(f.a - f.arc / 2.0 + f.arc * i / 12.0) * f.rng)
	return pts
