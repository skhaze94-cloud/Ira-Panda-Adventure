extends "res://scripts/core.gd"

# --- Art renderer: native CanvasItem / Godot Texture2D drawing ---
func _draw() -> void:
	if tex.is_empty(): return
	if state == "menu" or state == "comic":
		_cover("forest")
		_moon_haze()
		for i in range(28):
			var px: float = _randseed(i * 17) * size.x + sin(elapsed * 0.4 + i) * 16
			var py: float = _randseed(i * 23 + 5) * size.y + cos(elapsed * 0.3 + i) * 12
			draw_circle(Vector2(px,py), 1.4, Color(0.98,0.89,0.61,0.25))
		return
	if not (state == "play" or state == "dialog" or state == "win"): return
	draw_rect(Rect2(Vector2.ZERO,size), Color("#101d2a"))
	_cover(BASE_LEVELS[level_index].background, 0.47)
	tile = clampf(size.x / 20.0, 38, 58)
	camera = size * Vector2(0.5, 0.55) - Vector2((player.x-player.y)*tile,(player.x+player.y)*tile*0.49)
	var corners := [_unproject(Vector2(-tile,-tile)), _unproject(Vector2(size.x+tile,-tile)), _unproject(Vector2(-tile,size.y+tile)), _unproject(size+Vector2(tile,tile))]
	var min_x := int(maxf(0.0, floor(minf(minf(corners[0].x,corners[1].x),minf(corners[2].x,corners[3].x)))))
	var max_x := int(minf(BASE_LEVELS[level_index]["size"]-1, ceil(maxf(maxf(corners[0].x,corners[1].x),maxf(corners[2].x,corners[3].x)))))
	var min_y := int(maxf(0.0, floor(minf(minf(corners[0].y,corners[1].y),minf(corners[2].y,corners[3].y)))))
	var max_y := int(minf(BASE_LEVELS[level_index]["size"]-1, ceil(maxf(maxf(corners[0].y,corners[1].y),maxf(corners[2].y,corners[3].y)))))
	for s in range(min_x + min_y, max_x + max_y + 1):
		for x in range(min_x,max_x+1):
			var y := s - x
			if y < min_y or y > max_y: continue
			var center := _project(Vector2(x,y))
			if not _visible(center, tile*1.2): continue
			_draw_ground(x,y,center)
	_moon_haze()
	var entities: Array = []
	for t in trees:
		if _visible(_project(t.pos),tile*5): entities.append({"depth":t.pos.x+t.pos.y, "type":"tree", "data":t})
	for t in lanterns:
		if _visible(_project(t.pos),tile*3): entities.append({"depth":t.pos.x+t.pos.y,"type":"lantern","data":t})
	for t in decorations:
		if _visible(_project(t.pos),tile*2): entities.append({"depth":t.pos.x+t.pos.y,"type":"decor","data":t})
	for npc in npcs:
		if _visible(_project(npc.pos),tile*3): entities.append({"depth":npc.pos.x+npc.pos.y,"type":"npc","data":npc})
	for m in marks:
		if _visible(_project(m.pos),tile*3): entities.append({"depth":m.pos.x+m.pos.y,"type":"item","data":m})
	for rune in runes:
		if _visible(_project(rune.pos),tile*3): entities.append({"depth":rune.pos.x+rune.pos.y,"type":"rune","data":rune})
	for b in bats:
		if _visible(_project(b.pos),tile*3): entities.append({"depth":b.pos.x+b.pos.y,"type":"bat","data":b})
	if level_index == 0:
		var key_spot := Vector2(29,_path_y(29)+6)
		entities.append({"depth":key_spot.x+key_spot.y,"type":"birches","data":{}})
	else:
		var station_pos := _station()
		entities.append({"depth":station_pos.x+station_pos.y,"type":"station","data":{}})
	var exit_pos := _exit()
	entities.append({"depth":exit_pos.x+exit_pos.y,"type":"exit","data":{}})
	entities.append({"depth":player.x+player.y,"type":"ara","data":{}})
	entities.sort_custom(func(a,b): return a.depth < b.depth)
	for entity in entities:
		var d: Dictionary = entity.data
		match entity.type:
			"tree": _draw_tree(d)
			"lantern": _draw_lantern(d)
			"decor": _draw_decoration(d)
			"npc": _draw_npc(d)
			"item": _draw_item(d)
			"rune": _draw_rune(d)
			"bat": _draw_bat(d)
			"birches": _draw_birches()
			"station": _draw_station()
			"exit": _draw_exit()
			"ara": _draw_ara()
	for part in particles:
		var fade: float = part.life / part.max
		var at := _project(part.pos) + part.offset * (1.0 - fade) * 90 - Vector2(0,45)
		draw_circle(at, 3.3 * fade, Color(1.0,0.91,0.62,fade))
	if pulse > 0:
		var at := _project(player)-Vector2(0,55)
		var expansion := 1.0 - pulse/GLOW_TIME
		draw_arc(at, 50.0+125.0*expansion, 0, TAU, 64, Color(1.0,0.88,0.60,0.62 * (1.0-expansion)),4.5,true)
	if has_destination:
		var at := _project(destination)
		draw_arc(at,12,0,TAU,24,Color(1,0.89,0.65,0.7),2)

func _cover(name: String, alpha: float=1.0) -> void:
	var texture: Texture2D = tex.get(name)
	if not texture: return
	var wh := texture.get_size()
	var scale_factor: float = maxf(size.x/wh.x, size.y/wh.y)
	var dest := Rect2((size-wh*scale_factor)*0.5,wh*scale_factor)
	draw_texture_rect(texture,dest,false,Color(1,1,1,alpha))

func _moon_haze() -> void:
	for i in range(3):
		var at := Vector2(size.x * (0.2+float(i)*0.3), size.y * 0.15)
		for k in range(5,0,-1):
			draw_circle(at, float(k)*80.0, Color(0.65,0.77,1.0,0.007))

func _visible(point: Vector2, pad: float=130) -> bool:
	return point.x > -pad and point.y > -pad and point.x < size.x+pad and point.y < size.y+pad

func _draw_ground(x: int, y: int, center: Vector2) -> void:
	var tex_ground: Texture2D = tex.get("ground-v2")
	var trail := absf(float(y)-_path_y(x)) < 2.1 or _key_trail(Vector2(x,y))
	var col := (0 if trail else 2) + (x+y) % 2
	var rect: Array = GROUND_RECTS[level_index*4 + col]
	var points := PackedVector2Array([center + Vector2(0,-tile*0.49),center+Vector2(tile,0),center+Vector2(0,tile*0.49),center+Vector2(-tile,0)])
	if tex_ground:
		var ts: Vector2 = tex_ground.get_size()
		var u := float(rect[0])/ts.x
		var v := float(rect[1])/ts.y
		var u2 := float(rect[0]+rect[2])/ts.x
		var v2 := float(rect[1]+rect[3])/ts.y
		draw_polygon(points, PackedColorArray([Color.WHITE,Color.WHITE,Color.WHITE,Color.WHITE]), PackedVector2Array([Vector2(u,v),Vector2(u2,v),Vector2(u2,v2),Vector2(u,v2)]),tex_ground)
	else:
		draw_colored_polygon(points, Color("#53635b") if trail else Color("#1b393b"))
	if (x+y) % 2 == 1:
		draw_colored_polygon(points,Color(0.04,0.12,0.19,0.035))

func _draw_crop(name: String, src: Array, dst: Rect2, color: Color=Color.WHITE) -> void:
	var texture: Texture2D = tex.get(name)
	if texture:
		draw_texture_rect_region(texture,dst,Rect2(float(src[0]),float(src[1]),float(src[2]),float(src[3])),color)

func _draw_png(name: String, at: Vector2, w: float, h: float, alpha: float=1.0) -> void:
	var t: Texture2D = tex.get(name)
	if t: draw_texture_rect(t,Rect2(Vector2(at.x-w*0.5,at.y-h),Vector2(w,h)),false,Color(1,1,1,alpha))

func _draw_halo(at: Vector2, radius: float, tint: Color, weight: float=1.0) -> void:
	for ring in range(7,0,-1):
		var f := float(ring)/7.0
		draw_circle(at,radius*f,Color(tint.r,tint.g,tint.b,weight * (1-f) * 0.034))

func _draw_tree(t: Dictionary) -> void:
	var at := _project(t.pos)
	var h: float = tile*3.9*float(t["size"])
	var crop: Array = TREE_RECTS[level_index*3 + int(t.variant)]
	var w: float = minf(tile*2.25,h*float(crop[2])/float(crop[3]))
	_shadow(at,30*t["size"])
	var alpha := 0.28 if at.y > _project(player).y and absf(at.x-_project(player).x)<tile*1.2 and at.y-_project(player).y < h*0.7 else 1.0
	_draw_crop("trees-v2",crop,Rect2(at-Vector2(w*0.5,h),Vector2(w,h)),Color(1,1,1,alpha))

func _draw_lantern(l: Dictionary) -> void:
	var at := _project(l.pos)
	var h: float = tile*(1.75 if int(l.variant) else 2.7)
	var crop: Array = LAMP_RECTS[level_index*2 + int(l.variant)]
	var w: float = minf(tile*1.25,h*float(crop[2])/float(crop[3]))
	_draw_crop("lamps-v2",crop,Rect2(at-Vector2(w*0.5,h),Vector2(w,h)))
	var light := Color("#9ad9ff") if l.get("blue",false) else COLORS[level_index]
	_draw_halo(at-Vector2(0,h*0.72),45,light,1.4)

func _draw_decoration(d: Dictionary) -> void:
	var at := _project(d.pos)
	var h: float = tile*1.5*d["size"]
	var w := h*0.88
	var crop: Array = DECOR_RECTS[int(d.variant)]
	_draw_crop("decor",crop,Rect2(at-Vector2(w*0.5,h),Vector2(w,h)))

func _draw_npc(n: Dictionary) -> void:
	var at: Vector2 = _project(n.pos)
	var near := player.distance_to(n.pos) < 4
	var bounce := (sin(elapsed*3.1+float(n.pos.x))*3.5 if not quieter_motion else 0.0)
	_shadow(at,24)
	_draw_png("npc-"+n.id,at-Vector2(0,bounce),tile*1.46,tile*2.1)
	if near:
		_draw_halo(at-Vector2(0,90),32,Color("#d4f4ff"),0.6)

func _draw_item(m: Dictionary) -> void:
	if m.lit and level_index != 4: return
	var at := _project(m.pos)
	var bob := sin(elapsed*2 + m.index)*3 if not quieter_motion else 0.0
	if level_index == 1 and not m.revealed:
		_draw_crop("decor",DECOR_RECTS[0],Rect2(at-Vector2(27,60),Vector2(54,60)))
		_draw_halo(at-Vector2(0,26),55,Color("#ba99ff"),0.8)
		return
	var art_index := [0,0,2,5,6][level_index]
	var h := 70.0 if level_index == 4 else 48.0
	var w := 62.0 if level_index == 2 else 50.0
	_draw_crop("quests-23",QUEST_RECTS[art_index],Rect2(at-Vector2(w*0.5,h+bob),Vector2(w,h)))
	_draw_halo(at-Vector2(0,h*0.55),45,COLORS[level_index],1.2)

func _draw_rune(r: Dictionary) -> void:
	var at := _project(r.pos)
	_draw_crop("quests-23",QUEST_RECTS[4],Rect2(at-Vector2(33,100),Vector2(66,100)))
	_draw_halo(at-Vector2(0,55),45,Color("#fff4bc") if r.lit else Color("#b3beff"),1.0)

func _draw_station() -> void:
	var at := _project(_station())
	var art_index := [0,8,3,4,7][level_index]
	var w := 175.0 if level_index == 2 else 110.0
	var h := 120.0 if level_index == 2 else 100.0
	_draw_crop("quests-23",QUEST_RECTS[art_index],Rect2(at-Vector2(w*0.5,h),Vector2(w,h)))
	_draw_halo(at-Vector2(0,h*0.6),55,Color("#ffeaa5") if quest_done else Color("#c3ddff"),1.2)

func _draw_bat(b: Dictionary) -> void:
	var at := _project(b.pos)
	var h: float = tile*0.85
	var w: float = tile*1.1
	var floaty := 12.0 + sin(elapsed*4+b.phase)*8.0
	var src := [1090,185,446,320] if int(b.phase) % 2 == 0 else [20,605,430,390]
	var t: Texture2D = tex.get("atlas")
	if t:
		var dimensions := t.get_size()
		var sx: float = dimensions.x/1536.0
		var sy: float = dimensions.y/1024.0
		_draw_crop("atlas",[src[0]*sx,src[1]*sy,src[2]*sx,src[3]*sy],Rect2(at-Vector2(w*0.5,h+floaty),Vector2(w,h)))

func _draw_birches() -> void:
	var at := _project(Vector2(29,_path_y(29)+6))
	_draw_png("key-birches",at,tile*3.2,tile*3.6)
	_draw_halo(at-Vector2(0,35),72,Color("#a1dfff"),1.0)
	if key_revealed and not key_collected:
		var k := _project(_key_location())
		_draw_png("woodland-key",k-Vector2(0,13+sin(elapsed*3)*4),39,40)
		_draw_halo(k-Vector2(0,37),40,Color("#ffe99f"),1.7)

func _draw_exit() -> void:
	var at := _project(_exit())
	_draw_halo(at-Vector2(0,60),85,COLORS[level_index],1.3 if quest_done or key_collected else 0.6)
	if level_index == 0:
		_draw_png("woodland-door",at,170,168)
	elif level_index == 4:
		_draw_crop("decor",DECOR_RECTS[5],Rect2(at-Vector2(110,200),Vector2(220,200)))
		if quest_done: _draw_png("ira",at+Vector2(45,5),65,82)
	else:
		_draw_crop("lamps-v2",LAMP_RECTS[level_index*2],Rect2(at-Vector2(100,152),Vector2(75,152)))
		_draw_crop("lamps-v2",LAMP_RECTS[level_index*2],Rect2(at+Vector2(28,-152),Vector2(75,152)))

func _shadow(at: Vector2, rad: float) -> void:
	draw_set_transform(at, 0.0, Vector2(1.0,0.28))
	draw_circle(Vector2.ZERO,rad,Color(0.03,0.07,0.09,0.35))
	draw_set_transform(Vector2.ZERO)

func _rig_part(index: int, center: Vector2, wh: Vector2, spin: float=0.0, pivot: Vector2=Vector2(0.5,0.5)) -> void:
	var rect: Array = RIG_RECTS[index]
	draw_set_transform(center,spin,Vector2(facing,1))
	_draw_crop("ara-rig-22",rect,Rect2(-wh*pivot,wh))
	draw_set_transform(Vector2.ZERO)

func _draw_ara() -> void:
	var at := _project(player)
	_shadow(at,25)
	var gait := sin(foot_time) * minf(1.0,walk_dir.length()) if not quieter_motion else 0.0
	var bounce := absf(sin(foot_time)) * minf(1.0,walk_dir.length()) * 3.2 if not quieter_motion else 0.0
	var breath := sin(elapsed*2.0)*0.65 if not quieter_motion else 0.0
	var base := at-Vector2(0,bounce)
	_rig_part(4,base+Vector2(-12,-9+gait*2),Vector2(18,14),-gait*0.15)
	_rig_part(5,base+Vector2(12,-9-gait*2),Vector2(18,14),gait*0.15)
	_rig_part(2,base+Vector2(-18,-54),Vector2(20,36),gait*0.2,Vector2(0.6,0.12))
	_rig_part(1,base+Vector2(0,-35-breath),Vector2(45,44))
	var lift := sin((1-pulse/GLOW_TIME)*PI) if pulse > 0 else 0.0
	_rig_part(3,base+Vector2(18,-54-breath),Vector2(33,56),-lift*0.65,Vector2(0.14,0.09))
	_rig_part(0,base+Vector2(0,-52-breath),Vector2(70,59),sin(elapsed*1.4)*0.03,Vector2(0.5,0.95))
	_draw_halo(base+Vector2(facing*38,-52-lift*12),62,COLORS[level_index],2.0)
