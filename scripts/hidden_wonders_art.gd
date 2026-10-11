extends RefCounted
## Original atlases stay intact. Godot draws alpha-bounded regions and animates lids.
var atlases: Array = []
var regions: Array = []
func load_assets() -> void:
	regions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/beauty/regions.json"))
	for name in ["woods","glade","brook","hollow","garden"]:
		atlases.append(load("res://assets/beauty/"+name+".png"))
func sprite(g: Control, kind: int, at: Vector2, height: float, alpha: float=1.0) -> void:
	var r: Array=regions[g.level_index][kind]
	var source:=Rect2(r[0],r[1],r[2],r[3])
	var dimensions:=Vector2(height*float(r[2])/float(r[3]),height)
	g.draw_texture_rect_region(atlases[g.level_index],Rect2(at-Vector2(dimensions.x*.5,dimensions.y),dimensions),source,Color(1,1,1,alpha))
func tree(g: Control, data: Dictionary, alpha: float, sway: float) -> void:
	var at: Vector2=g._project(data.pos)
	g.draw_set_transform(at,sway)
	sprite(g,0,Vector2.ZERO,g.tile*4.0*float(data["size"]),alpha)
	g.draw_set_transform(Vector2.ZERO)
func scenery(g: Control, data: Dictionary) -> void:
	var at: Vector2=g._project(data.pos)
	g._shadow(at,25)
	var h: float=g.tile*(3.1 if data.kind==0 else 1.35 if data.kind==1 else 1.85)
	var alpha: float=.15 if data.kind==0 and g.player.distance_to(data.pos)<4 else 1.0
	sprite(g,data.kind,at,h,alpha)
func chest(g: Control, data: Dictionary) -> void:
	var at: Vector2=g._project(data.pos)
	var clock: float=0 if g.quieter_motion else g.living.clock
	g._shadow(at,34)
	var lid: float=data.lid
	if lid<=0:
		sprite(g,2,at,g.tile*1.30)
	else:
		var r: Array=regions[g.level_index][2]
		var height: float=g.tile*1.30
		var width: float=height*float(r[2])/float(r[3])
		# The illustrated lower half stays planted; the upper lid tilts around its hinge.
		var split: float=float(r[3])*.52
		var hinge:=at-Vector2(0,height*.48)
		g.draw_texture_rect_region(atlases[g.level_index],Rect2(at-Vector2(width*.5,height*.48),Vector2(width,height*.48)),Rect2(r[0],float(r[1])+split,r[2],float(r[3])-split))
		g._draw_halo(hinge,55,Color("#ffe6a2"),lid)
		g._disc(hinge+Vector2(0,6),12,Color("#ffe1a2"))
		g.draw_set_transform(hinge,-.34*lid,Vector2(1,1-.32*lid))
		g.draw_texture_rect_region(atlases[g.level_index],Rect2(Vector2(-width*.5,-height*.52),Vector2(width,height*.52)),Rect2(r[0],r[1],r[2],split))
		g.draw_set_transform(Vector2.ZERO)
	if not data.open:
		var hint: float=.55+data.glimmer*.16
		g._draw_halo(at-Vector2(0,32),42,Color("#ffe8aa"),hint)
		for i in range(3):
			var p:=at+Vector2(cos(clock*.7+float(i)*2.1)*28,-35+sin(clock*.9+float(i)*2)*8)
			g._disc(p,1.8,Color(1,.91,.65,.6))
func star(g: Control, data: Dictionary) -> void:
	if data.found: return
	var at: Vector2=g._project(data.pos)
	var bob: float=0 if g.quieter_motion else sin(g.living.clock*1.7+data.index)*4
	g._shadow(at,10)
	at-=Vector2(0,20+bob)
	g._draw_halo(at,32,Color("#ffe0a3"),1.0)
	var points:=PackedVector2Array()
	for i in range(10):
		points.append(at+Vector2(0,-(10.0 if i%2==0 else 4.5)).rotated(float(i)*PI/5))
	g.draw_colored_polygon(points,Color("#ffdea0"));points.append(points[0])
	g.draw_polyline(points,Color("#fff4cb"),1.4,true)
	g.draw_line(at+Vector2(-3,-3),at+Vector2(-1,-7),Color("#fffdf0"),1.4,true)
func paths(g: Control) -> void:
	for branch in g.beauty.paths:
		var p: Vector2=g._project(branch.points[0])
		if not g._visible(p,80): continue
		# A small stitched star is an invitation, without revealing the treasure itself.
		g._world_oval(branch.points[0]+Vector2(.2,-.7),Vector2(.35,.30),Color("#8f9d82"))
		g.draw_line(p+Vector2(15,-6),p+Vector2(15,-20),Color("#e5d5aa"),1.5,true)
		g.draw_line(p+Vector2(9,-13),p+Vector2(21,-13),Color("#e5d5aa"),1.5,true)
