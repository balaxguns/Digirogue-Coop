extends Node3D
## Shared expedition terrain renderer. Gameplay coordinates remain authoritative in run.gd.
const SCALE := 0.20
const COLORS := [
	Color("#243c2b"), Color("#718fa6"), Color("#8e7048"),
	Color("#42475b"), Color("#31565d"), Color("#553b36")
]
var camera: Camera3D
var geometry: Node3D
var digital_props: Node3D

func _ready() -> void:
	geometry = Node3D.new()
	add_child(geometry)
	digital_props = preload("res://scripts/digital_props.gd").new()
	add_child(digital_props)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#101a22")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#b8c6db")
	env.ambient_light_energy = 0.9
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, -20)
	sun.light_energy = 0.9
	add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.rotation = Vector3(-PI / 2.0, 0, 0)
	camera.position = Vector3(0, 550, 0)
	camera.current = true
	add_child(camera)

func _mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	return mat

func _batch(mesh: Mesh, color: Color, transforms: Array) -> void:
	if transforms.is_empty():
		return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in transforms.size():
		multi.set_instance_transform(i, transforms[i])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multi
	instance.material_override = _mat(color)
	geometry.add_child(instance)

func _position(point: Vector2, height: float = 0.0) -> Vector3:
	return Vector3((point.x - 4500.0) * SCALE, height, (point.y - 4500.0) * SCALE)

func rebuild(biomes: PackedByteArray, obstacles: Array, landmarks: Array) -> void:
	for child in geometry.get_children():
		geometry.remove_child(child)
		child.queue_free()
	var tiles: Array = [[], [], [], [], [], []]
	var ground := BoxMesh.new()
	ground.size = Vector3(100.5 * SCALE, 2.0, 100.5 * SCALE)
	for y in 90:
		for x in 90:
			var b: int = int(biomes[y * 90 + x])
			tiles[b].append(Transform3D(Basis(), _position(Vector2(x * 100.0 + 50.0, y * 100.0 + 50.0), -1.0)))
	for b in 6:
		_batch(ground, COLORS[b], tiles[b])
	var rock_colors := [Color("#425846"), Color("#a3c5da"), Color("#9b7851"), Color("#667082"), Color("#4c7777"), Color("#6b4b45")]
	# Distinct biome landmarks: forest pillars, icy spires, sandstone ruins,
	# industrial towers, marsh stones, and volcanic basalt columns.
	var column := CylinderMesh.new()
	column.top_radius = 0.75
	column.bottom_radius = 1.0
	column.height = 1.0
	column.radial_segments = 6
	var monuments: Array = [[], [], [], [], [], []]
	for area in landmarks:
		var biome: int = int(area.b)
		for i in 12:
			var angle: float = float(i) * TAU / 12.0
			var offset := Vector2.from_angle(angle) * 270.0
			var point: Vector2 = area.pos + offset
			var height: float = (28.0 + float((i * 17 + biome * 13) % 30)) * SCALE
			monuments[biome].append(Transform3D(Basis().scaled(Vector3(5.0 * SCALE, height, 5.0 * SCALE)), _position(point, height * 0.5)))
	for b in 6:
		_batch(column, rock_colors[b].lightened(0.15), monuments[b])

	# Sparse large-scale biome props are batched by mesh and biome.
	# Placement is decorative only; all solid objects use run.gd's obstacle positions.
	var trunks: Array = [[], [], [], [], [], []]
	var crowns: Array = [[], [], [], [], [], []]
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.55
	trunk_mesh.bottom_radius = 1.0
	trunk_mesh.height = 1.0
	trunk_mesh.radial_segments = 6
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 1.0
	crown_mesh.height = 2.0
	crown_mesh.radial_segments = 8
	crown_mesh.rings = 4
	for area in landmarks:
		var biome: int = int(area.b)
		for i in 60:
			var angle: float = float(i) * 2.399963
			var distance: float = 450.0 + float((i * 173 + biome * 91) % 730)
			var point: Vector2 = area.pos + Vector2.from_angle(angle) * distance
			point = point.clamp(Vector2(70, 70), Vector2(8930, 8930))
			var size: float = (14.0 + float((i * 19) % 15)) * SCALE
			trunks[biome].append(Transform3D(Basis().scaled(Vector3(size * 0.3, size * 2.5, size * 0.3)), _position(point, size * 1.25)))
			crowns[biome].append(Transform3D(Basis().scaled(Vector3(size, size * 1.4, size)), _position(point, size * 3.0)))
	var trunk_colors := [Color("#423c32"), Color("#d6ecf5"), Color("#9b7550"), Color("#434e62"), Color("#355b53"), Color("#352b30")]
	var crown_colors := [Color("#345b40"), Color("#b4e0f1"), Color("#bd9a63"), Color("#4a8a9b"), Color("#528b77"), Color("#9d5140")]
	for b in 6:
		_batch(trunk_mesh, trunk_colors[b], trunks[b])
		_batch(crown_mesh, crown_colors[b], crowns[b])
	digital_props.call("populate", landmarks, obstacles)

func follow(world_center: Vector2, viewport_height: float) -> void:
	camera.position = _position(world_center, 550.0)
	camera.size = viewport_height * SCALE
