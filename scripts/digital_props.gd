extends Node3D
## Procedural Digital World scenery. Decorative meshes never create invisible collision.
## All placement is deterministic, and gameplay obstacles remain in run.gd.
const S := 0.20
var meshes: Dictionary = {}
var groups: Dictionary = {}
var materials: Dictionary = {}
var time_passed := 0.0
var lights: Array[OmniLight3D] = []

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	time_passed += delta
	for i in lights.size():
		var light: OmniLight3D = lights[i]
		light.light_energy = 0.5 + 0.17 * sin(time_passed * 1.6 + float(i) * 2.4)

func _material(color: Color, pattern: int = 0, glow: bool = false) -> StandardMaterial3D:
	var key := "%s:%d:%s" % [color.to_html(), pattern, str(glow)]
	if materials.has(key):
		return materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	# Procedurally generated textured surfaces: no external files or UV dependencies.
	var noise := FastNoiseLite.new()
	noise.seed = 2391 + pattern * 31
	noise.frequency = 0.09 if pattern == 0 else 0.18
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var n: float = noise.get_noise_2d(float(x), float(y))
			var variation: float = 0.79 + n * 0.23
			if pattern == 2:
				var seam: bool = (y % 15 == 0) or (x % 22 == 0 and (y / 15) % 2 == 0)
				if seam:
					variation *= 0.48
			elif pattern == 3 and (x % 12 == 0 or y % 12 == 0):
				variation *= 1.35
			image.set_pixel(x, y, Color(clampf(variation, 0.1, 1.0), clampf(variation, 0.1, 1.0), clampf(variation, 0.1, 1.0)))
	var tex := ImageTexture.create_from_image(image)
	m.albedo_texture = tex
	m.uv1_triplanar = true
	if glow:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 1.4
	materials[key] = m
	return m

func _mesh(shape: String) -> Mesh:
	if meshes.has(shape):
		return meshes[shape]
	var mesh: Mesh
	match shape:
		"box":
			mesh = BoxMesh.new()
		"cone":
			var cone := CylinderMesh.new()
			cone.top_radius = 0.05
			cone.bottom_radius = 0.5
			cone.height = 1.0
			cone.radial_segments = 7
			mesh = cone
		"cylinder":
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.5
			cyl.bottom_radius = 0.5
			cyl.height = 1.0
			cyl.radial_segments = 8
			mesh = cyl
		"sphere":
			var sphere := SphereMesh.new()
			sphere.radius = 0.5
			sphere.height = 1.0
			sphere.radial_segments = 9
			sphere.rings = 5
			mesh = sphere
		_:
			mesh = BoxMesh.new()
	meshes[shape] = mesh
	return mesh

func _add(shape: String, color: Color, pos: Vector3, size: Vector3, rotation: float = 0.0, pattern: int = 0, glow: bool = false) -> void:
	var key := "%s:%s:%d:%s" % [shape, color.to_html(), pattern, str(glow)]
	if not groups.has(key):
		groups[key] = {"shape": shape, "color": color, "pattern": pattern, "glow": glow, "items": []}
	var basis := Basis(Vector3.UP, rotation).scaled(size)
	groups[key].items.append(Transform3D(basis, pos))

func _p(world: Vector2, y: float = 0.0) -> Vector3:
	return Vector3((world.x - 4500.0) * S, y, (world.y - 4500.0) * S)

func _place(b: int, point: Vector2, i: int) -> void:
	var pos := _p(point)
	var height := (18.0 + float((i * 19) % 22)) * S
	var rot := float(i) * 2.39996
	match b:
		0: # Withered Forest: old circuit-root trees, luminous data fungi, terminal stones.
			_add("cone", Color("#4e3d38"), pos + Vector3(0, height * 0.65, 0), Vector3(height * 0.52, height * 1.3, height * 0.52), rot, 1)
			for j in 3:
				_add("sphere", Color("#354f42"), pos + Vector3(sin(rot + j * 2.1) * height * 0.3, height * (1.3 + j * 0.18), cos(rot + j * 2.1) * height * 0.3), Vector3(height * 1.2, height * 0.7, height * 1.0), 0, 1)
			_add("sphere", Color("#36c4a0"), pos + Vector3(height * 0.75, 0.7, 0), Vector3(1.7, 0.7, 1.7), 0, 3, true)
		1: # Freezeland: glacier spires, layered snow, cold blue data crystals.
			_add("cone", Color("#a9d9e8"), pos + Vector3(0, height * 0.8, 0), Vector3(height * 0.8, height * 1.6, height * 0.8), rot, 1)
			_add("cone", Color("#e6f3f7"), pos + Vector3(0, height * 1.55, 0), Vector3(height * 0.46, height * 0.75, height * 0.46), rot, 1)
			_add("cone", Color("#65dcff"), pos + Vector3(height * 0.7, height * 0.4, 0), Vector3(2.5, height * 0.8, 2.5), rot, 3, true)
		2: # Scorched Savanna: cactus-like digital flora, mesas and sandstone ruins.
			_add("cylinder", Color("#4f8660"), pos + Vector3(0, height * 0.5, 0), Vector3(3.0, height, 3.0), rot, 1)
			for j in 2:
				var side: float = -1.0 if j == 0 else 1.0
				_add("box", Color("#69976a"), pos + Vector3(side * 3.0, height * 0.55, 0), Vector3(5.0, 1.5, 1.7), 0, 1)
				_add("cylinder", Color("#4f8660"), pos + Vector3(side * 5.0, height * 0.7, 0), Vector3(1.7, height * 0.35, 1.7), 0, 1)
			_add("box", Color("#b89468"), pos + Vector3(9, 1.5, 0), Vector3(7, 3, 9), rot, 2)
		3: # Dead File City: abandoned data houses, monorail sleepers, neon terminals.
			_add("box", Color("#526070"), pos + Vector3(0, height * 0.35, 0), Vector3(12, height * 0.7, 10), rot, 2)
			_add("cone", Color("#313746"), pos + Vector3(0, height * 0.8, 0), Vector3(15, 5, 13), rot, 1)
			_add("box", Color("#36c5e6"), pos + Vector3(0, height * 0.38, 5.2), Vector3(4, 4, 0.4), rot, 3, true)
			for j in 2:
				_add("box", Color("#9b8f7d"), pos + Vector3(-7.0 if j == 0 else 7.0, 0.4, 16), Vector3(1.3, 0.8, 25), rot, 1)
			for j in 5:
				_add("box", Color("#4a4447"), pos + Vector3(0, 0.3, 5.0 + float(j) * 5.0), Vector3(17, 0.6, 1.8), rot, 1)
		4: # Black Tide Marsh: giant mangroves, phosphorescent bulbs, ruined pylons.
			_add("cylinder", Color("#3a4b43"), pos + Vector3(0, height * 0.55, 0), Vector3(3.5, height * 1.1, 3.5), rot, 1)
			_add("sphere", Color("#466c61"), pos + Vector3(0, height * 1.15, 0), Vector3(height, height * 0.6, height), rot, 1)
			for j in 3:
				_add("cone", Color("#596b61"), pos + Vector3(sin(rot + j * 2.1) * 5.0, 2.0, cos(rot + j * 2.1) * 5.0), Vector3(2.0, 6.0, 2.0), rot, 1)
			_add("sphere", Color("#4bf2d0"), pos + Vector3(7, 1.0, 0), Vector3(2.5, 2.0, 2.5), 0, 3, true)
		5: # Ash Volcano: layered basalt cones, molten fractures, blackened boulders.
			_add("cone", Color("#373238"), pos + Vector3(0, height * 0.55, 0), Vector3(height * 1.5, height * 1.1, height * 1.5), rot, 1)
			_add("cone", Color("#705047"), pos + Vector3(0, height * 1.02, 0), Vector3(height * 0.7, height * 0.45, height * 0.7), rot, 1)
			_add("sphere", Color("#ff6734"), pos + Vector3(0, height * 1.25, 0), Vector3(height * 0.3, 1.2, height * 0.3), 0, 3, true)
			_add("box", Color("#d95131"), pos + Vector3(6, 0.35, 0), Vector3(3.5, 0.7, 17), rot, 3, true)

func populate(landmarks: Array, obstacles: Array) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	groups.clear()
	lights.clear()
	for area in landmarks:
		var biome: int = int(area.b)
		for i in 28:
			var angle: float = float(i) * 2.399963
			var distance: float = 500.0 + float((i * 193 + biome * 61) % 800)
			var point: Vector2 = area.pos + Vector2.from_angle(angle) * distance
			point = point.clamp(Vector2(100, 100), Vector2(8900, 8900))
			_place(biome, point, i)
		# The biome's primary digital landmark: a pulsing data obelisk.
		var anchor: Vector2 = area.pos + Vector2(0, -260)
		var center := _p(anchor)
		_add("box", Color("#29394c"), center + Vector3(0, 3, 0), Vector3(16, 6, 16), 0, 2)
		_add("cone", Color("#48d8ee"), center + Vector3(0, 17, 0), Vector3(9, 25, 9), 0, 3, true)
		var light := OmniLight3D.new()
		light.position = center + Vector3(0, 15, 0)
		light.light_color = Color("#48d8ee")
		light.omni_range = 45
		light.light_energy = 0.5
		add_child(light)
		lights.append(light)
	# Rock obstacles use the gameplay's real collision positions, so no decorative
	# boulder can imply an impassable wall where none exists.
	for obstacle in obstacles:
		var biome: int = int(obstacle.b)
		var radius: float = float(obstacle.r) * S
		if biome == 1:
			_add("cone", Color("#b7d8e7"), _p(obstacle.pos, radius), Vector3(radius * 1.5, radius * 2.0, radius * 1.5), 0, 1)
		elif biome == 5:
			_add("cone", Color("#423638"), _p(obstacle.pos, radius), Vector3(radius * 1.5, radius * 2.0, radius * 1.5), 0, 1)
		else:
			_add("sphere", Color("#66645b") if biome != 3 else Color("#68788a"), _p(obstacle.pos, radius * 0.6), Vector3(radius * 1.8, radius * 1.2, radius * 1.8), 0, 1)
	for key in groups:
		var g: Dictionary = groups[key]
		var transforms: Array = g.items
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = _mesh(g.shape)
		multimesh.instance_count = transforms.size()
		for i in transforms.size():
			multimesh.set_instance_transform(i, transforms[i])
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		instance.material_override = _material(g.color, g.pattern, g.glow)
		add_child(instance)
