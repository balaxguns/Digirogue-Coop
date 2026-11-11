extends Node2D
## Seamless beveled hover rim; positions are local to the button.
func _draw() -> void:
	var points: PackedVector2Array = get_meta("outline_points")
	if points.size() < 3:
		return
	var closed := PackedVector2Array(points)
	closed.append(points[0])
	draw_polyline(closed, Color("#ffb819", 0.28), 18.0, true)
	draw_polyline(closed, Color("#ffda36"), 9.0, true)
	for point in points:
		draw_circle(point, 4.5, Color("#ffda36"), true)
