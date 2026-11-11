extends Control
## Golden six-sided outline matching the beveled DIGIROGUE menu artwork.
const GOLD := Color("#ffdc3d")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var bevel := minf(23.0, h * 0.27)
	var inset := 3.0
	var points := PackedVector2Array([
		Vector2(bevel, inset),
		Vector2(w - bevel, inset),
		Vector2(w - inset, h * 0.5),
		Vector2(w - bevel, h - inset),
		Vector2(bevel, h - inset),
		Vector2(inset, h * 0.5),
		Vector2(bevel, inset)
	])
	draw_polyline(points, Color("#ffac17", 0.32), 12.0, true)
	draw_polyline(points, GOLD, 5.0, true)
	draw_polyline(points, Color("#fff4b0"), 1.5, true)
