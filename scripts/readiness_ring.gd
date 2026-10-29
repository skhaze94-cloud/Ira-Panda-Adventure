extends Control
var game: Control
func _ready() -> void:
	custom_minimum_size=Vector2.ZERO
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(_dt: float) -> void: queue_redraw()
func _draw() -> void:
	var fraction: float=1.0-clampf(game.cooldown/game.GLOW_RECHARGE,0,1)
	var c := Vector2(size.x*.5,18)
	draw_arc(c,17,-PI*.5,TAU-PI*.5,48,Color("#183b37"),2,true)
	if fraction>0.01: draw_arc(c,17,-PI*.5,-PI*.5+TAU*fraction,48,Color("#efd399"),2,true)
func style(tint: Color) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=tint;s.set_corner_radius_all(3);return s
