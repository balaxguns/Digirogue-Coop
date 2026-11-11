extends Control
## Animated procedural digital horizon behind the title UI.
var clock: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 1.0 or h < 1.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#08133a"))
	for i in 18:
		var y: float = float(i) * h / 18.0
		draw_rect(Rect2(0.0, y, w, h / 18.0 + 1.0), Color("#122e77").lerp(Color("#082a68"), y / h))
	# Digital skyline and faint grid.
	var horizon: float = h * 0.77
	for i in 32:
		var x: float = float(i) * w / 31.0
		var height: float = 18.0 + float((i * 17 + 9) % 7) * 13.0
		draw_rect(Rect2(x, horizon - height, w / 45.0, height), Color("#1263b2", 0.38), false, 2.0)
	for i in 13:
		var depth: float = float(i + 1) / 13.0
		var yy: float = horizon + pow(depth, 1.7) * (h - horizon)
		draw_line(Vector2(0.0, yy), Vector2(w, yy), Color("#2aa8ff", 0.18 + depth * 0.35), 1.0)
	for i in 19:
		var x: float = float(i) / 18.0 * w
		draw_line(Vector2(w * 0.5, horizon), Vector2(w * 0.5 + (x - w * 0.5) * 2.4, h), Color("#2aa8ff", 0.26), 1.0)
	# Tech rings at the sides.
	for side in 2:
		var cx: float = -w * 0.02 if side == 0 else w * 1.02
		var cy: float = h * 0.27
		for ring in 3:
			draw_arc(Vector2(cx, cy), w * (0.22 + float(ring) * 0.055), 0.3, 5.7, 70, Color("#2caaff", 0.2 + float(ring) * 0.08), 3.0)
	# Small drifting square particles.
	for i in 52:
		var x: float = fposmod(float(i * 127 + 29), w)
		var y: float = fposmod(float(i * 73 + 19) - clock * (6.0 + float(i % 4) * 3.0), h)
		var opacity: float = 0.15 + 0.28 * (0.5 + 0.5 * sin(clock * 1.5 + float(i)))
		draw_rect(Rect2(x, y, 3.0 + float(i % 3) * 2.0, 3.0 + float(i % 3) * 2.0), Color("#5ecbff", opacity))
