extends Node
## Autoload "Save": permanent progress (Digicore, equipment, .mon files)
const PATH := "user://save.json"
var core := 0
var owned: Array = []
var equipped: Array = []
var mon := {}
var next_uid := 3
var settings := {"vol": 1.0, "fullscreen": false}

func _ready() -> void:
	load_game()

func load_game() -> void:
	if FileAccess.file_exists(PATH):
		var f := FileAccess.open(PATH, FileAccess.READ)
		var d = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			core = int(d.get("core", 0))
			owned = d.get("owned", [])
			equipped = d.get("equipped", [])
			mon = d.get("mon", {})
			next_uid = int(d.get("next_uid", 3))
			settings = d.get("settings", settings)
	for o in owned:
		o["u"] = int(o["u"])
	owned = owned.filter(func(o): return Data.equip.has(o["id"]))
	equipped = equipped.map(func(x): return int(x))
	if owned.is_empty():
		owned = [{"u": 1, "id": "Broad Rapier"}, {"u": 2, "id": "Broad Shield"}]

func save_game() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"core": core, "owned": owned, "equipped": equipped, "mon": mon, "next_uid": next_uid, "settings": settings}))

func find_owned(u: int) -> Dictionary:
	for o in owned:
		if int(o["u"]) == u:
			return o
	return {}

func mon_count(line: int) -> int:
	return int(mon.get(str(line), 0))

func set_mon(line: int, k: int) -> void:
	mon[str(line)] = maxi(mon_count(line), mini(k, 3))

func reset_all() -> void:
	core = 0
	owned = []
	equipped = []
	mon = {}
	next_uid = 3
	load_game()
	save_game()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		settings["fullscreen"] = not bool(settings.get("fullscreen", false))
		apply_settings()
		save_game()
		get_viewport().set_input_as_handled()

func apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, float(settings.get("vol", 1.0)))))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if settings.get("fullscreen", false) else DisplayServer.WINDOW_MODE_WINDOWED)
