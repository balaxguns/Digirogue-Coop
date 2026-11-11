extends Control
## Low-contrast animated data stream for the Mallow hub.
var tick: float = 0.0
const GLYPHS := "01001101011010100110"
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _process(delta: float) -> void:
	tick += delta
	queue_redraw()
func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color("#07122d"))
	for i in 24:
		var x := (float(i) + 0.5) * w / 24.0
		draw_line(Vector2(x, 0), Vector2(x, h), Color("#1c5f9d", 0.13), 1.0)
	for j in 15:
		var y := float(j) * h / 14.0
		draw_line(Vector2(0, y), Vector2(w, y), Color("#1c5f9d", 0.13), 1.0)
	var font := ThemeDB.fallback_font
	for col in 28:
		var x := float(col) * 52.0 + 8.0
		var speed := 17.0 + float(col % 6) * 6.0
		for row in 13:
			var y := fposmod(float(row) * 79.0 + tick * speed + float(col * 37), h + 80.0) - 40.0
			var bit := GLYPHS[(col * 7 + row * 3 + int(tick * 2.0)) % GLYPHS.length()]
			draw_string(font, Vector2(x, y), bit, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#51d9ff", 0.08 + 0.09 * float((row + col) % 3)))
