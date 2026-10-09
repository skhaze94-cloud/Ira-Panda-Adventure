extends Control
## Reuse the painted rigs in a native, animated single-speaker medallion.
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
func part(atlas: String, rect: Array, center: Vector2, wh: Vector2, spin: float=0.0, pivot: Vector2=Vector2(0.5,0.5)) -> void:
	draw_set_transform(center,spin)
	draw_texture_rect_region(game.tex[atlas],Rect2(-wh*pivot,wh),Rect2(rect[0],rect[1],rect[2],rect[3]))
	draw_set_transform(Vector2.ZERO)
func _draw() -> void:
	if game==null or game.tex.is_empty(): return
	var scale_factor := minf(size.x/160.0,size.y/178.0)
	var base := size*0.5+Vector2(0,66*scale_factor)
	var still: bool = game.quieter_motion
	var bounce := sin(clock*2.0)*1.0 if not still else 0.0
	var tilt := sin(clock*(3.6 if speaking else 1.5))*0.025 if not still else 0.0
	var wave := sin(clock*4.0)*0.13 if not still and mood=="happy" else 0.0
	var tint: Color = {"pip":Color("#d4b575"),"bramble":Color("#d8ad92"),"moss":Color("#9bb49a"),"ira":Color("#d2adbf")}.get(speaker,Color("#a3bdb4"))
	draw_circle(size*0.5,65*scale_factor,tint.lightened(0.57))
	draw_arc(size*0.5,66*scale_factor,0,TAU,64,tint,1.5,true)
	if mood=="happy":
		for i in range(3):
			var at := size*0.5+Vector2(58,0).rotated(-2.7+float(i)*0.65)*scale_factor
			var radius := (3.0+sin(clock*2.0+i)*0.7 if not still else 3.0)*scale_factor
			draw_line(at-Vector2(radius,0),at+Vector2(radius,0),tint,1.2,true)
			draw_line(at-Vector2(0,radius),at+Vector2(0,radius),tint,1.2,true)
	# Draw in a 160x178 local stage; one rig, never a row of characters.
	var pieces: Array = []
	var atlas := "npc-rig-22"
	match speaker:
		"pip": pieces=[[2,Vector2(-24,-49),Vector2(39,31),wave],[1,Vector2(0,-35),Vector2(62,60),0.0],[4,Vector2(19,-55),Vector2(25,30),tilt],[3,Vector2(23,-48),Vector2(34,41),wave],[0,Vector2(0,-80),Vector2(69,56),tilt]]
		"bramble": pieces=[[9,Vector2(0,-38),Vector2(58,60),0.0],[6,Vector2(0,-32),Vector2(63,51),0.0],[7,Vector2(-20,-40),Vector2(49,37),0.0],[8,Vector2(23,-41),Vector2(31,35),wave],[5,Vector2(0,-75),Vector2(65,53),tilt]]
		"moss": pieces=[[14,Vector2(22,-28),Vector2(47,48),tilt],[11,Vector2(0,-33),Vector2(65,56),0.0],[13,Vector2(-20,-48),Vector2(29,31),0.0],[12,Vector2(21,-48),Vector2(40,31),wave],[10,Vector2(0,-82),Vector2(66,60),tilt]]
		"ira":
			var wh := Vector2(84,107)*scale_factor
			draw_texture_rect(game.tex["ira"],Rect2(base-Vector2(wh.x*0.5,wh.y+bounce),wh),false)
			return
		_:
			atlas = "ara-rig-22"
			pieces=[[4,Vector2(-12,-9),Vector2(18,14),0.0],[5,Vector2(12,-9),Vector2(18,14),0.0],[2,Vector2(-14,-52),Vector2(18,34),wave],[1,Vector2(0,-35),Vector2(45,44),0.0],[3,Vector2(14,-51),Vector2(35,49),-wave],[0,Vector2(0,-52),Vector2(70,59),tilt]]
	for piece in pieces:
		var index: int = piece[0]
		var rect: Array = game.RIG_RECTS[index] if atlas=="ara-rig-22" else game.NPC_CROPS[index]
		var pivot := Vector2(0.5,0.5)
		if atlas=="npc-rig-22":
			pivot = {2:Vector2(0.8,0.18),3:Vector2(0.18,0.12),4:Vector2(0.35,0.1),7:Vector2(0.28,0.2),8:Vector2(0.24,0.15),12:Vector2(0.14,0.2),13:Vector2(0.75,0.12),14:Vector2(0.35,0.8)}.get(index,pivot)
		if atlas=="ara-rig-22":
			if index==0: pivot=Vector2(0.5,0.95)
			elif index==2: pivot=Vector2(0.42,0.10)
			elif index==3: pivot=Vector2(0.16,0.10)
		part(atlas,rect,base+(piece[1]*1.2-Vector2(0,bounce))*scale_factor,piece[2]*scale_factor*1.2,piece[3],pivot)
