extends RefCounted
## Native CanvasItem art. Dimensions match the collision lanes in pathways.gd.
static func crossings(g: Control) -> void:
	for c in g.pathways.crossings:
		if g._visible(g._project(c.pos),g.tile*7):g.object_art.crossing(g,c)

static func _stone(g: Control, p: Vector2, radius: Vector2, seed_value: int) -> void:
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	var uv := PackedVector2Array()
	var colors := PackedColorArray()
	var crop: Array = g.GROUND_RECTS[12]
	var texture_size: Vector2 = g.tex["ground-v2"].get_size()
	for i in range(9):
		var a := float(i)*TAU/9
		var shape: Vector2 = Vector2(cos(a),sin(a))*(.86+g._randseed(seed_value*11+i)*.14)
		var at: Vector2=g._project(p+shape*radius)
		top.append(at-Vector2(0,4));bottom.append(at+Vector2(0,3))
		uv.append((Vector2(crop[0],crop[1])+(shape*.47+Vector2(.5,.5))*Vector2(crop[2],crop[3]))/texture_size)
		colors.append(Color(1.2,1.25,1.15,1))
	g.draw_colored_polygon(bottom,Color("#3c595b"))
	g.draw_polygon(top,colors,uv,g.tex["ground-v2"])
	g.draw_line(top[5],top[6],Color("#bdd1b5"),1.5,true)
	if seed_value%3==0: g._disc(top[2].lerp(top[3],.5),2.2,Color("#83a374"))

static func obstacle(g: Control, o: Dictionary) -> void:
	var at: Vector2 = g._project(o.pos)
	g._shadow(at,46)
	if o.kind=="boulder":
		var top := PackedVector2Array()
		for delta in [Vector2(-0.7,-0.6),Vector2(0.1,-1.25),Vector2(0.7,-0.6),Vector2(0.7,0.7),Vector2(0,1.2),Vector2(-0.7,0.4)]:
			top.append(g._project(o.pos+delta)-Vector2(0,24))
		var bottom := PackedVector2Array()
		for point in top: bottom.append(point+Vector2(0,24))
		g.draw_colored_polygon(bottom,Color("#526c73"))
		for i in range(6):
			g.draw_colored_polygon(PackedVector2Array([top[i],top[(i+1)%6],bottom[(i+1)%6],bottom[i]]),Color("#688489") if i%2 else Color("#526c73"))
		var crop: Array = g.GROUND_RECTS[12]
		var uv := PackedVector2Array()
		var colors := PackedColorArray()
		var texture_size: Vector2 = g.tex["ground-v2"].get_size()
		for point in top:
			var local: Vector2 = ((point-at)/Vector2(140,120)+Vector2(0.5,0.65)).clamp(Vector2.ZERO,Vector2.ONE)
			uv.append((Vector2(crop[0],crop[1])+local*Vector2(crop[2],crop[3]))/texture_size)
			colors.append(Color(1.35,1.4,1.2,1))
		g.draw_polygon(top,colors,uv,g.tex["ground-v2"])
		g.draw_line(top[0],top[1],Color("#d6dfc2"),2,true)
		g.draw_line(top[3],(top[3]+top[0])*0.5,Color("#788f8b"),1.5,true)
		g._storybook_fern(at+Vector2(20,-24),float(o.pos.x))
	else:
		var a: Vector2 = g._project(o.pos-Vector2(0,1.15))-Vector2(0,12)
		var b: Vector2 = g._project(o.pos+Vector2(0,1.15))-Vector2(0,12)
		g.draw_line(a,b,Color("#513f37"),28,true)
		g.draw_line(a-Vector2(0,5),b-Vector2(0,5),Color("#997351"),17,true)
		g.draw_line(a-Vector2(0,10),b-Vector2(0,10),Color("#a7ac6c"),5,true)
		for i in range(12):
			var p: Vector2 = a.lerp(b,float(i)/12)
			g.draw_line(p-Vector2(0,9),p+Vector2(7,-3),Color(.35,.24,.17,.58),1.2,true)
		g._disc(b,13,Color("#dfb382"))
		g.draw_arc(b,8,0,TAU,18,Color("#986b4b"),2,true)
		g._storybook_fern(a+Vector2(0,-7),float(o.pos.x))

static func web(g: Control) -> void:
	var p: Vector2 = g.pathways.web_position()
	var alpha: float = g.pathways.web_fade
	var a: Vector2 = g._project(p+Vector2(0,-2.1))
	var b: Vector2 = g._project(p+Vector2(0,2.1))
	for foot in [a,b]:
		g.draw_line(foot,foot-Vector2(0,100),Color("#625b65"),7,true)
		g._storybook_fern(foot,1.0)
	var center: Vector2 = (a+b)*0.5-Vector2(0,57)
	var radius := Vector2(absf(a.x-b.x)*0.5,50)*lerpf(0.4,1.0,alpha)
	for i in range(12):
		var angle := float(i)*TAU/12.0
		g.draw_line(center,center+Vector2(cos(angle),sin(angle))*radius,Color(0.8,0.85,1,0.6*alpha),1.3,true)
	for ring in range(1,5):
		var points := PackedVector2Array()
		for i in range(25):
			var angle := float(i)*TAU/24.0
			points.append(center+Vector2(cos(angle),sin(angle))*radius*float(ring)/4.0)
		g.draw_polyline(points,Color(0.85,0.91,1,0.55*alpha),1.2,true)
	var clock: float = 0.0 if g.quieter_motion else g.elapsed
	var spider := center+Vector2(14+sin(clock)*5,sin(clock*1.2)*8-15)
	if g.pathways.web_clear: spider.y-=absf(sin(clock*3))*5
	g.draw_line(center-Vector2(0,45),spider,Color("#cbd9f3"),1,true)
	for side in [-1.0,1.0]:
		for i in range(3):
			g.draw_line(spider+Vector2(side*3,float(i)*2-3),spider+Vector2(side*12,float(i)*5-6),Color("#85749d"),2,true)
	g._disc(spider,7,Color("#9481b4"))
	g._disc(spider+Vector2(-2,-2),1.4,Color("#fff3dc"))
	g._disc(spider+Vector2(2,-2),1.4,Color("#fff3dc"))
	g.draw_arc(spider+Vector2(0,1),3,0,PI,8,Color("#f1d9e9"),1,true)
