extends Node3D
## Standalone 3D world-art prototype. Open scenes/terrain_preview.tscn (F6) to explore.
## Existing 2D expedition combat remains untouched.
const WORLD_SIZE := 2400.0
const ZONE_RADIUS := 105.0
const BIOMES := ["Marble", "Volcanic", "Coral", "Tropical", "Machine", "Desert", "Jungle"]
const ZONE_COLORS := [Color("#d3d5d2"), Color("#342a30"), Color("#347c8a"), Color("#a5a477"), Color("#536b7d"), Color("#b9a075"), Color("#365b39")]
var rng := RandomNumberGenerator.new()
var camera: Camera3D
var focus := Vector3.ZERO
var zoom := 150.0
var yaw := 0.7
var pitch := 0.9
var zones: Array[Vector3] = []
var embedded_mode := false

func _ready() -> void:
	rng.seed = 478921
	_build_world()
	_build_camera()
	if not embedded_mode:
		_build_legend()

func _mat(color: Color, glow: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.94
	if glow:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 2.2
	return m

func _box(pos: Vector3, size: Vector3, color: Color, rot: float = 0.0) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _mat(color)
	node.position = pos
	node.rotation.y = rot
	add_child(node)

func _cylinder(pos: Vector3, radius: float, height: float, color: Color, top_radius: float = -1.0) -> void:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top_radius < 0.0 else top_radius
	mesh.height = height
	mesh.radial_segments = 12
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _mat(color)
	node.position = pos
	add_child(node)

func _sphere(pos: Vector3, radius: float, color: Color, glow: bool = false) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _mat(color, glow)
	node.position = pos
	add_child(node)

func _build_world() -> void:
	_box(Vector3(0, -2.5, 0), Vector3(WORLD_SIZE, 5, WORLD_SIZE), Color("#57533b"))
	var env := WorldEnvironment.new()
	var resource := Environment.new()
	resource.background_mode = Environment.BG_COLOR
	resource.background_color = Color("#181d28")
	resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	resource.ambient_light_color = Color("#a0b2c7")
	resource.ambient_light_energy = 0.75
	env.environment = resource
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 1.1
	sun.light_color = Color("#ffe5b9")
	add_child(sun)
	# Seven distinct islands, far apart in a broad dead-grass wilderness.
	zones = [
		Vector3(-760, 0, -720), Vector3(0, 0, -810),
		Vector3(770, 0, -690), Vector3(-790, 0, 110),
		Vector3(800, 0, 120), Vector3(-470, 0, 790),
		Vector3(480, 0, 790)
	]
	for i in zones.size():
		_build_zone(zones[i], i)
	# Low-poly, dead grass clumps dominate the huge open map.
	for i in 1150:
		var p := Vector3(rng.randf_range(-1150, 1150), 0, rng.randf_range(-1150, 1150))
		var near_zone := false
		for z in zones:
			if p.distance_to(z) < ZONE_RADIUS + 28.0:
				near_zone = true
				break
		if near_zone:
			continue
		var height := rng.randf_range(1.5, 5.0)
		_cylinder(p + Vector3(0, height * 0.5, 0), rng.randf_range(0.25, 0.8), height, Color("#77734a") if i % 3 else Color("#a0995e"), 0.05)
	# Sparse rocky placeholder obstacles, deliberately simple.
	if not embedded_mode:
		for i in 95:
			var p := Vector3(rng.randf_range(-1120, 1120), 0, rng.randf_range(-1120, 1120))
			_box(p + Vector3(0, 3, 0), Vector3(8, 6, 8), Color("#77716c"), rng.randf_range(0, TAU))

func _build_zone(center: Vector3, kind: int) -> void:
	_cylinder(center + Vector3(0, 0.3, 0), ZONE_RADIUS, 0.65, ZONE_COLORS[kind])
	# Each biome has its own 3D silhouettes and landmark props.
	for i in 25:
		var a := rng.randf_range(0, TAU)
		var r := sqrt(rng.randf()) * (ZONE_RADIUS - 15.0)
		var p := center + Vector3(cos(a) * r, 0, sin(a) * r)
		match kind:
			0: # Marble: white columns, fallen capitals, ruined platforms
				_cylinder(p + Vector3(0, 8, 0), 2.4, 16, Color("#e3e2d8"))
				_box(p + Vector3(0, 16, 0), Vector3(8, 2, 8), Color("#f3eee1"))
				if i % 4 == 0:
					_box(p + Vector3(6, 2, 0), Vector3(15, 4, 13), Color("#c3c2bb"), 0.3)
			1: # Volcanic: basalt spires and lava vents
				_cylinder(p + Vector3(0, 10, 0), 5, 20, Color("#181b22"), 0.6)
				if i % 2 == 0:
					_sphere(p + Vector3(5, 0.9, 4), 3.2, Color("#ff5c16"), true)
			2: # Coral: reef pillars, luminous coral and shallow pools
				_cylinder(p + Vector3(0, 6, 0), 3, 12, Color("#d18ca2"), 1.2)
				_sphere(p + Vector3(0, 13, 0), 5, Color("#5fe1e4"), true)
				if i % 3 == 0:
					_sphere(p + Vector3(5, 2, 0), 4, Color("#c17eb5"))
			3: # Tropical: palms, pale sand and stilt huts
				_cylinder(p + Vector3(0, 10, 0), 1.8, 20, Color("#7e5b39"), 1.1)
				_sphere(p + Vector3(0, 21, 0), 8, Color("#3d7852"))
				if i % 6 == 0:
					_box(p + Vector3(9, 5, 0), Vector3(15, 10, 13), Color("#8d6647"))
			4: # Machine: metal pylons, damaged modules and glowing cores
				_box(p + Vector3(0, 10, 0), Vector3(8, 20, 8), Color("#718494"))
				_box(p + Vector3(0, 18, 0), Vector3(10, 2, 10), Color("#a0b1b9"))
				if i % 2 == 0:
					_sphere(p + Vector3(0, 21, 0), 2.5, Color("#42d9f5"), true)
			5: # Desert: sandstone pillars, eroded mesas and relics
				_cylinder(p + Vector3(0, 4, 0), rng.randf_range(4, 9), 8, Color("#c7a46b"), 3.5)
				if i % 5 == 0:
					_box(p + Vector3(0, 12, 0), Vector3(12, 10, 9), Color("#a8875a"), 0.2)
			6: # Jungle: thick trunks, huge crowns and old stone ruins
				_cylinder(p + Vector3(0, 12, 0), 3, 24, Color("#524c37"), 2.2)
				_sphere(p + Vector3(0, 27, 0), 10, Color("#284e35"))
				if i % 5 == 0:
					_box(p + Vector3(9, 4, 0), Vector3(10, 8, 12), Color("#62695a"))
	# One large visual landmark in the center of each zone.
	match kind:
		0:
			_box(center + Vector3(0, 3, 0), Vector3(35, 6, 35), Color("#f0ece4"))
		1:
			_cylinder(center + Vector3(0, 18, 0), 16, 36, Color("#25222b"), 5)
		2:
			_sphere(center + Vector3(0, 12, 0), 12, Color("#59d4e0"), true)
		3:
			_box(center + Vector3(0, 8, 0), Vector3(25, 16, 20), Color("#987652"))
		4:
			_box(center + Vector3(0, 24, 0), Vector3(17, 48, 17), Color("#667b8c"))
		5:
			_cylinder(center + Vector3(0, 13, 0), 19, 26, Color("#d2b17a"), 12)
		6:
			_cylinder(center + Vector3(0, 19, 0), 7, 38, Color("#554b38"), 5)
			_sphere(center + Vector3(0, 44, 0), 20, Color("#254c32"))

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 60
	add_child(camera)
	_update_camera()

func _update_camera() -> void:
	var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * zoom
	camera.position = focus + offset
	camera.look_at(focus, Vector3.UP)

func _process(dt: float) -> void:
	var speed := zoom * 0.9 * dt
	var forward := Vector3(-sin(yaw), 0, -cos(yaw))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	if Input.is_key_pressed(KEY_W): focus += forward * speed
	if Input.is_key_pressed(KEY_S): focus -= forward * speed
	if Input.is_key_pressed(KEY_D): focus += right * speed
	if Input.is_key_pressed(KEY_A): focus -= right * speed
	focus.x = clampf(focus.x, -1150, 1150)
	focus.z = clampf(focus.z, -1150, 1150)
	_update_camera()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: zoom = maxf(35, zoom * 0.82)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: zoom = minf(1100, zoom * 1.22)
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw -= event.relative.x * 0.006
		pitch = clampf(pitch + event.relative.y * 0.004, 0.25, 1.35)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_7:
			focus = zones[event.keycode - KEY_1]
			zoom = 160.0

func _build_legend() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.text = "DARK AREA  //  3D TERRAIN PROTOTYPE\nWASD: PAN   •   RIGHT MOUSE: ORBIT   •   WHEEL: ZOOM\n1 MARBLE   2 VOLCANIC   3 CORAL   4 TROPICAL\n5 MACHINE   6 DESERT   7 JUNGLE\nWITHERED GRASSLAND: PRIMARY TERRAIN"
	label.position = Vector2(18, 18)
	label.add_theme_color_override("font_color", Color("#e6f3ff"))
	label.add_theme_font_size_override("font_size", 16)
	layer.add_child(label)
