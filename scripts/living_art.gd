extends RefCounted
static func ground(g: Control) -> void:
	for pile in g.living.leaves:
		var at: Vector2=g._project(pile.pos)
		if not g._visible(at,95): continue
		var scattered: float=1-pile.scatter/1.1 if pile.scatter>0 else 0.0
		for i in range(8):
			var angle:=float(i)*2.4
			var spread: float=12+(scattered*45 if pile.scatter>0 else 0)
			var p: Vector2=at+Vector2(cos(angle)*spread,sin(angle)*spread*.4)
			if pile.scatter>0 and not g.quieter_motion: p.y-=sin(scattered*PI)*(13+float(i%3)*5)
			var tint:=Color("#bd9b65") if i%2 else Color("#ad7059")
			if g.level_index==1: tint=Color("#b491ac") if i%2 else Color("#8a94b0")
			g._storybook_petal(p,angle+(scattered if not g.quieter_motion else 0),8,3,tint)
			g.draw_line(p,p+Vector2(5,2).rotated(angle),tint.lightened(.15),1,true)
	for note in g.living.notes:
		var p: Vector2=g._project(note.pos)
		if not g._visible(p,85): continue
		g._world_oval(note.pos,Vector2(.36,.38),Color("#63727e"))
		g._world_oval(note.pos-Vector2(.035,.035),Vector2(.32,.34),Color("#a9b6bb"))
		for i in range(note.index+1): g._disc(p+Vector2(float(i)*7-note.index*3.5,-4),1.8,Color("#f7e3a9"))
		if note.ring>0:
			g._draw_halo(p-Vector2(0,5),45,Color("#d1defc"),note.ring)
			if not g.quieter_motion:
				var rise: float=(1-note.ring/1.2)*30
				g.draw_line(p+Vector2(0,-15-rise),p+Vector2(0,-26-rise),Color("#f7e3a9"),2,true)
				g._disc(p+Vector2(-3,-14-rise),3,Color("#f7e3a9"))
static func clue(g: Control, clue_data: Dictionary) -> void:
	var at: Vector2=g._project(clue_data.pos)
	var clock: float=0 if g.quieter_motion else g.living.clock
	g._shadow(at,16)
	var ink:=Color("#e4c19b") if clue_data.found else Color("#eecee1")
	match str(clue_data.kind):
		"ribbon":
			g.draw_line(at+Vector2(8,1),at+Vector2(5,-27),Color("#8f7964"),3,true)
			g.draw_line(at+Vector2(5,-21),at+Vector2(-14,-27),Color("#8f7964"),2,true)
			var center:=at+Vector2(-6,-24)
			for side in [-1.0,1.0]:
				g._storybook_petal(center,PI if side<0 else 0,13,5,ink)
				var ribbon:=PackedVector2Array()
				for i in range(8): ribbon.append(center+Vector2(side*5+sin(clock*1.5+i*.4)*2,float(i)*2.8))
				g.draw_polyline(ribbon,ink,3,true)
			g._disc(center,3,Color("#fff0d4"))
		"prints":
			for i in range(4):
				var p:=at+Vector2(float(i)*12-18,-float(i)*5+float(i%2)*5)
				var pillow:=PackedVector2Array([p+Vector2(-7,-2),p+Vector2(-3,-5),p+Vector2(5,-4),p+Vector2(8,0),p+Vector2(3,4),p+Vector2(-5,3),p+Vector2(-7,-2)])
				g.draw_polyline(pillow,Color("#dacbaa"),1.8,true)
				g.draw_line(p+Vector2(-3,0),p+Vector2(3,1),Color("#d2b6cd"),1,true)
		"biscuit":
			g._disc(at-Vector2(0,5),10,Color("#886547"));g._disc(at-Vector2(0,7),9,Color("#dfbb7e"))
			for i in range(5): g._disc(at+Vector2(cos(float(i)*2)*5,-7+sin(float(i)*2)*4),1.5,Color("#966447"))
			for i in range(3): g._disc(at+Vector2(14+i*5,float(i%2)*3),1.7,Color("#d9bd88"))
	if clue_data.found: g._draw_halo(at-Vector2(0,14),37,Color("#f9e1b1"),.55)
	else:
		var alpha: float=.5 if g.quieter_motion else .45+sin(clock*1.2+clue_data.index)*.15
		g._disc(at+Vector2(15,-23),2,Color(1,.91,.71,alpha))
static func guide(g: Control) -> void:
	var data: Dictionary=g.living.guide
	if data.is_empty(): return
	var at: Vector2=g._project(data.pos)-Vector2(0,36)
	if not g._visible(at,100): return
	var clock: float=0 if g.quieter_motion else g.living.clock
	for i in range(5):
		var angle:=float(i)*TAU/5+clock*.7
		var p:=at+Vector2(cos(angle)*17,sin(angle)*7+sin(clock*1.3+i)*3)
		g._disc(p,2.4,Color("#fff0b1"))
		g.draw_line(p-Vector2(4,2),p+Vector2(4,-2),Color(1,.95,.74,.5),1,true)
	g._draw_halo(at,48,Color("#ffe3a1"),.85+float(data.spark)*.2)
	if data.active and not data.finished:
		var target: Vector2=g._project(data.points[data.step])
		for i in range(4):
			var p: Vector2=at.lerp(target-Vector2(0,24),float(i)/5)
			g._disc(p,1.4,Color(1,.93,.69,.3))
static func visitor(g: Control) -> void:
	var data: Dictionary=g.living.visitor
	if data.is_empty(): return
	var at: Vector2=g._project(data.pos)
	var clock: float=0 if g.quieter_motion else g.living.clock
	var interest: float=data.attention
	g._shadow(at,13)
	match g.level_index:
		0,4:
			# A tiny woodland rabbit turns toward Ara, ears pricked in curiosity.
			var side: float=1 if g.player.x-g.player.y>data.pos.x-data.pos.y else -1
			var head:=at+Vector2(side*5,-14-interest*2)
			g._disc(at-Vector2(0,8),11,Color("#b8afa0"))
			g._disc(at+Vector2(-side*9,-8),4,Color("#e3ddce"))
			g._disc(head,8,Color("#d4cbb9"))
			for i in range(2): g._storybook_petal(head+Vector2(-2+i*6,-5),-PI/2+sin(clock*.7+i)*.06,14,3,Color("#d4cbb9"))
			g._disc(head+Vector2(side*4,-2),1.6,Color("#364b48"));g._disc(head+Vector2(side*8,1),1.4,Color("#bd8887"))
		2:
			var hop: float=maxf(0,sin(clock*2))*interest*5
			var frog:=at-Vector2(0,8+hop)
			g._disc(frog,10,Color("#8bae82"))
			for side in [-1.0,1.0]:
				g._disc(frog+Vector2(side*6,-7),4,Color("#c5d5a6"));g._disc(frog+Vector2(side*6,-8),1.8,Color("#364e46"))
				g.draw_line(frog+Vector2(side*7,7),frog+Vector2(side*13,9),Color("#729a79"),3,true)
			g.draw_arc(frog+Vector2(0,-1),4,0,PI,10,Color("#466653"),1,true)
		1,3:
			var moth:=at-Vector2(0,27+sin(clock*1.5)*4)
			var wing: float=13+sin(clock*5)*2
			for side in [-1.0,1.0]:
				g._storybook_petal(moth,PI*.8 if side<0 else .2,wing,7,Color("#d5c2e9"))
				g._storybook_petal(moth,PI*1.2 if side<0 else -.2,wing*.7,4,Color("#bdcce4"))
			g.draw_line(moth-Vector2(0,5),moth+Vector2(0,5),Color("#e5d9bd"),2,true)
			if interest>.1: g._draw_halo(moth,33,Color("#d8e7ef"),interest*.7)
static func npc_props(g: Control, npc: Dictionary) -> void:
	var at: Vector2=g._project(npc.home)
	if npc.id=="moss":
		g._storybook_mushroom(at+Vector2(32,7),11,23,Color("#a5c3ae"),npc.home.x)
		if npc.work>.25 and not g.quieter_motion:
			for i in range(4):
				var fall: float=fmod(g.living.clock*1.7+float(i)/4,1)
				g._disc(at+Vector2(29+float(i%2)*3,-25+fall*30),1.2,Color(.71,.89,.93,.65))
	elif npc.id=="bramble":
		g.draw_line(at+Vector2(-28,2),at+Vector2(-28,-12),Color("#806c54"),3,true)
		g.draw_line(at+Vector2(-35,-13),at+Vector2(-21,-13),Color("#c1ac7e"),6,true)
	elif npc.id=="pip":
		for i in range(3): g._disc(at+Vector2(-26+i*4,4),2,Color("#baa282"))
	if npc.get("noticed_done",false):
		var p: Vector2=g._project(npc.pos)-Vector2(0,107)
		g.draw_line(p+Vector2(-5,0),p+Vector2(-1,4),Color("#d6e4a9"),2,true)
		g.draw_line(p+Vector2(-1,4),p+Vector2(7,-4),Color("#d6e4a9"),2,true)

static func npc_hands(g: Control, npc: Dictionary) -> void:
	if npc.id!="moss" or npc.get("work",0.0)<.25: return
	var at: Vector2=g._project(npc.pos)+Vector2(24*float(npc.facing),-38)
	var tint:=Color("#8baca1")
	g._disc(at,6,tint)
	g.draw_arc(at+Vector2(-5,0),5,PI*.5,PI*1.5,12,Color("#bfd0b0"),1.6,true)
	g.draw_line(at+Vector2(4,0),at+Vector2(11,4),tint,3,true)
	g.draw_line(at+Vector2(10,2),at+Vector2(12,6),Color("#bfd0b0"),2,true)
