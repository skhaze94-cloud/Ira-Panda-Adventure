extends RefCounted
static func signs(g: Control) -> void:
	for loop in g.exploration.loops:
		for i in [0,3]:
			var at: Vector2 = g._project(loop.points[i]+Vector2(0,1.2))
			if not g._visible(at,60): continue
			g.draw_line(at,at-Vector2(0,25),Color("#7e6551"),4,true)
			g.draw_line(at-Vector2(9,22),at+Vector2(9,-22),Color("#c1ac7e"),9,true)
			g.draw_line(at-Vector2(4,22),at+Vector2(5,-22),Color("#e9dbaf"),2,true)
			g.draw_line(at+Vector2(5,-22),at+Vector2(1,-26),Color("#e9dbaf"),2,true)
static func secret(g: Control, loop: Dictionary) -> void:
	var at: Vector2 = g._project(loop.pos)
	g._shadow(at,46)
	var clock: float = 0 if g.quieter_motion else g.elapsed
	var found: bool = g.exploration.found[loop.index]
	var color := Color("#f4d49b") if found else Color("#aadbd0")
	g._draw_halo(at-Vector2(0,24),65,color,1.3)
	match g.level_index:
		0,4:
			# Woven picnic cloth and a tiny biscuit bowl; garden has sister ribbons.
			g.draw_colored_polygon(PackedVector2Array([at+Vector2(-42,0),at+Vector2(0,-20),at+Vector2(44,0),at+Vector2(0,20)]),Color("#dacda3"))
			for i in range(5): g.draw_line(at+Vector2(-32+i*12,-4),at+Vector2(-6+i*12,10),Color(.61,.29,.34,.55),3,true)
			g._disc(at-Vector2(0,10),14,Color("#75594a"));g._disc(at-Vector2(0,13),12,Color("#dfb775"))
			for i in range(4): g._disc(at+Vector2(-6+i*4,-14+float(i%2)*4),2,Color("#725442"))
			if loop.index==1:
				for side in [-1.0,1.0]:
					var p: Vector2 = at+Vector2(side*30,-12)
					g.draw_line(p,p-Vector2(0,70),Color("#907055"),4,true)
					var ribbon := PackedVector2Array()
					for j in range(12): ribbon.append(p+Vector2(sin(float(j)*.6+clock*1.4)*8,-65+float(j)*4))
					g.draw_polyline(ribbon,Color("#daa4b5"),3,true)
		1:
			for i in range(7):
				var p := at+Vector2(cos(float(i))*28,sin(float(i))*12)
				g._storybook_mushroom(p,11,21,Color("#c8a5e6"),float(i))
				var moth := p+Vector2(sin(clock*.8+i)*10,-30+sin(clock+i)*5)
				g.draw_line(moth-Vector2(5,3),moth+Vector2(5,-3),color,3,true)
				g._disc(moth,1.5,Color("#ffe2be"))
		2:
			for i in range(3):
				var p := at+Vector2(float(i)*20-20,float(i%2)*8-5)
				g._disc(p,11,Color("#c1d4c0"));g._disc(p+Vector2(8,-9),6,Color("#d7dfc4"))
				g.draw_line(p+Vector2(12,-8),p+Vector2(17,-6),Color("#daa878"),3,true)
				g._disc(p+Vector2(9,-11),1.4,Color("#496964"))
			if loop.index==1:
				for i in range(5):
					var p := at+Vector2(-30+i*14,-48+sin(clock+i)*2)
					g.draw_line(p,p+Vector2(0,24+i*3),Color("#d6c390"),2,true)
		3:
			if loop.index==0:
				g.draw_line(at,at-Vector2(0,42),Color("#958d96"),5,true)
				g.draw_line(at-Vector2(0,18),at+Vector2(-22,9),Color("#958d96"),3,true)
				g.draw_line(at-Vector2(0,18),at+Vector2(22,9),Color("#958d96"),3,true)
				g.draw_line(at+Vector2(-20,-35),at+Vector2(26,-51),Color("#b0a2c4"),16,true)
				g._disc(at+Vector2(28,-51),10,Color("#eadbb5"));g._disc(at+Vector2(28,-51),7,Color("#6a7d9b"))
			else:
				for side in [-1.0,1.0]: g.draw_line(at+Vector2(side*24,0),at+Vector2(side*24,-18),Color("#6d6476"),5,true)
				g.draw_line(at+Vector2(-35,-18),at+Vector2(35,-18),Color("#b7a487"),12,true)
				g._disc(at-Vector2(0,44),4,Color("#fff0a7"))
	if found:
		for i in range(5):
			var p := at+Vector2(cos(clock*.4+i)*39,-35+sin(clock*.4+i)*15)
			g._disc(p,1.7,Color("#ffe0a3"))
static func moments(g: Control) -> void:
	if g.level_index==0 and g.personality.key_glimmer>0:
		var at: Vector2 = g._project(g._key_location())
		var clock: float = g.personality.story_clock
		for i in range(8):
			var p := at+Vector2(cos(float(i)*TAU/8+clock)*45,-20+sin(float(i)*TAU/8+clock)*18)
			g.draw_line(p-Vector2(3,0),p+Vector2(3,0),Color("#eddb95"),2,true)
	if g.level_index==3:
		var ordered: Array = g.runes.duplicate()
		ordered.sort_custom(func(a,b): return a.order<b.order)
		for i in range(2):
			if not ordered[i].lit: continue
			var a: Vector2 = g._project(ordered[i].pos)-Vector2(0,70)
			var b: Vector2 = g._project(ordered[i+1].pos)-Vector2(0,70)
			g.draw_line(a,b,Color(1,.91,.63,.85 if ordered[i+1].lit else .25),2,true)
			for j in range(5): g._disc(a.lerp(b,float(j)/4),2,Color("#ffe9ad"))
	if g.level_index==4 and g.quest_done:
		var at: Vector2 = g._project(g._exit())
		for i in range(6):
			var a: float = float(i)*TAU/6+g.personality.story_clock*.18
			g._disc(at+Vector2(cos(a)*75,-50+sin(a)*25),2.5,Color("#ffe0a9"))
