extends Control
## Landscape touch stick, one owned pointer; keyboard and tap-to-walk coexist.
var game: Control
var pointer := -1
var knob := Vector2.ZERO
var mouse_down := false
var last_touch := 0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	custom_minimum_size=Vector2(136,136)
func local_point(p: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse()*p
func set_axis(p: Vector2) -> void:
	var delta := p-size*.5
	var radius := size.x*.34
	knob=delta.limit_length(radius)
	var axis := knob/radius
	if axis.length()<.16: axis=Vector2.ZERO
	game._hold_direction(get_instance_id(),axis,true)
	queue_redraw()
func release() -> void:
	pointer=-1;mouse_down=false;knob=Vector2.ZERO
	game._hold_direction(get_instance_id(),Vector2.ZERO,false);queue_redraw()
func _input(event: InputEvent) -> void:
	if game.state!="play" or not visible:
		if pointer>=0 or mouse_down: release()
		return
	if event is InputEventScreenTouch:
		var p := local_point(event.position)
		if event.pressed and pointer<0 and Rect2(Vector2.ZERO,size).has_point(p):
			pointer=event.index;last_touch=Time.get_ticks_msec();set_axis(p);get_viewport().set_input_as_handled()
		elif event.index==pointer and not event.pressed:
			last_touch=Time.get_ticks_msec();release();get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index==pointer:
		set_axis(local_point(event.position));get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and not event.pressed and mouse_down:
		release()
func _gui_input(event: InputEvent) -> void:
	if game.state!="play" or Time.get_ticks_msec()-last_touch<200: return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed: mouse_down=true;set_axis(event.position)
		else: release()
	elif event is InputEventMouseMotion and mouse_down: set_axis(event.position)
func _draw() -> void:
	var center := size*.5
	draw_circle(center,size.x*.46,Color(0.06,.14,.17,.62))
	draw_arc(center,size.x*.44,0,TAU,48,Color(.82,.77,.57,.8),2,true)
	draw_circle(center,size.x*.30,Color(.18,.36,.34,.65))
	for i in range(4):
		var a := float(i)*PI*.5
		var p := center+Vector2(cos(a),sin(a))*size.x*.35
		draw_circle(p,2,Color("#e4d5ac"))
	var at := center+knob
	draw_circle(at+Vector2(0,3),23,Color(0,.05,.07,.3))
	draw_circle(at,23,Color("#679e8a") if knob.length()>2 else Color("#477e73"))
	draw_arc(at,22,0,TAU,32,Color("#eddfb1"),2,true)
	# A small paw makes the stick read as a woodland control.
	draw_circle(at+Vector2(0,5),7,Color("#eddfb1"))
	for p in [Vector2(-9,-6),Vector2(0,-10),Vector2(9,-6)]: draw_circle(at+p,3.5,Color("#eddfb1"))
