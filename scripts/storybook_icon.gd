extends Control
var kind := "lantern"
func _ready() -> void: mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var c := size*.5
	var ink := Color("#f7e3ad")
	if kind=="lantern":
		draw_arc(c+Vector2(0,-9),6,PI,TAU,14,ink,2,true)
		draw_style_box(box(Color("#eabd71")),Rect2(c-Vector2(8,5),Vector2(16,18)))
		draw_line(c+Vector2(-10,-5),c+Vector2(10,-5),ink,3,true)
		draw_line(c+Vector2(-10,13),c+Vector2(10,13),ink,3,true)
		draw_line(c+Vector2(0,-2),c+Vector2(0,8),Color("#fff9df"),3,true)
	elif kind=="hand":
		draw_arc(c+Vector2(0,3),9,0,PI,18,ink,3,true)
		for i in range(4): draw_line(c+Vector2(-7+i*4,4),c+Vector2(-7+i*4,-9+absf(float(i)-1.5)*3),ink,3,true)
		draw_line(c+Vector2(-7,4),c+Vector2(-12,-1),ink,3,true)
	elif kind=="pause":
		for side in [-1,1]: draw_line(c+Vector2(side*5,-9),c+Vector2(side*5,9),ink,4,true)
func box(color: Color) -> StyleBoxFlat:
	var b := StyleBoxFlat.new();b.bg_color=color;b.set_corner_radius_all(3)
	return b
