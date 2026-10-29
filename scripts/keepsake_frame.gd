extends Control
## Small native foil ornaments stay sharp at every viewport size.
var ink := Color("#bd9c60")
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	for corner in [Vector2(17, 17), Vector2(size.x - 17, 17), Vector2(17, size.y - 17), size - Vector2(17, 17)]:
		var direction := Vector2(1 if corner.x < size.x * .5 else -1, 1 if corner.y < size.y * .5 else -1)
		for axis in [Vector2(direction.x, 0), Vector2(0, direction.y)]:
			draw_line(corner, corner + axis * 35, Color(ink, .55), 1.2, true)
			for i in [12, 24]:
				var p: Vector2 = corner + axis * i
				var leaf: Vector2 = axis.orthogonal() * 3
				draw_line(p - axis * 3 - leaf, p + axis * 3 + leaf, Color(ink, .75), 2, true)
		var star: Vector2 = corner + direction * 7
		draw_line(star - Vector2(3, 0), star + Vector2(3, 0), ink, 1, true)
		draw_line(star - Vector2(0, 3), star + Vector2(0, 3), ink, 1, true)
