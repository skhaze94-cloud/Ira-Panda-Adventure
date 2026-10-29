extends Control
## The same complete illustrated poses appear in conversation and on the trail.
var game: Control
var speaker := "ara"
var mood := "warm"
var clock := 0.0
var speaking := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(dt: float) -> void:
	if not is_visible_in_tree(): return
	if not game.quieter_motion: clock += dt
	queue_redraw()

func _draw() -> void:
	if game == null or game.keepsake.characters.is_empty(): return
	var name: String = speaker if game.keepsake.characters.has(speaker) else "ara"
	var at := size * Vector2(.5, .94)
	var radius: float = minf(size.x, size.y) * .44
	draw_circle(size * Vector2(.5, .52), radius, Color("#e5e8d5"))
	draw_arc(size * Vector2(.5, .52), radius, 0, TAU, 64, Color("#c4ac73"), 1.2, true)
	var frame := 0
	if name == "ira": frame = 1 if mood == "sleepy" else 2 if mood in ["joy", "happy", "delighted", "bright"] else 0
	elif mood in ["joy", "happy", "delighted", "proud", "bright"]: frame = 3
	elif speaking and not game.quieter_motion: frame = 1 if sin(clock * 1.1) > .5 else 2
	var source: Rect2 = game.keepsake.crop("characters", name, frame)
	var height: float = minf(size.y * .87, size.x * .92 * source.size.y / source.size.x)
	var bounce: float = 0 if game.quieter_motion else sin(clock * 1.6) * .6
	game.keepsake.character(self, name, frame, at - Vector2(0, bounce), height)
