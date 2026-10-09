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
	var corners := [_unproject(Vector2(-tile,-tile)), _unproject(Vector2(size.x+tile,-tile)), _unproject(Vector2(-tile,size.y+tile)), _unproject(size+Vector2(tile,tile))]
	var min_x := int(floor(minf(minf(corners[0].x,corners[1].x),minf(corners[2].x,corners[3].x))))
	var max_x := int(ceil(maxf(maxf(corners[0].x,corners[1].x),maxf(corners[2].x,corners[3].x))))
	var min_y := int(floor(minf(minf(corners[0].y,corners[1].y),minf(corners[2].y,corners[3].y))))
	var max_y := int(ceil(maxf(maxf(corners[0].y,corners[1].y),maxf(corners[2].y,corners[3].y))))
	for s in range(min_x + min_y, max_x + max_y + 1):
		for x in range(min_x,max_x+1):
			var y := s - x
			if y < min_y or y > max_y: continue
			var center := _project(Vector2(x,y))
			if not _visible(center, tile*1.2): continue
			_draw_ground(x,y,center)
	_draw_level_surface()
	_draw_lantern_clues_ground()
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
	for landmark in landmarks:
		if _visible(_project(landmark.pos),tile*5): entities.append({"depth":landmark.pos.x+landmark.pos.y,"type":"landmark","data":landmark})
	for plant in light_trails.plants:
		if _visible(_project(plant.pos),tile*2): entities.append({"depth":plant.pos.x+plant.pos.y,"type":"light_plant","data":plant})
	for stone in light_trails.stones:
		if _visible(_project(stone.pos),tile*2): entities.append({"depth":stone.pos.x+stone.pos.y,"type":"shadow_stone","data":stone})
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
			"landmark": _draw_landmark(d)
			"light_plant": _draw_lantern_plant(d)
			"shadow_stone": _draw_shadow_stone(d)
	_draw_landmark_names()
	for part in particles:
		var fade: float = part.life / part.max
		var at: Vector2 = _project(part.pos) + part.offset * (1.0 - fade) * 90 - Vector2(0,45)
		draw_circle(at, 3.3 * fade, Color(1.0,0.91,0.62,fade))
	if pulse > 0:
		var expansion := 1.0 - pulse/GLOW_TIME
		var radius := 2.4 if quieter_motion else lerpf(0.6,light_trails.REVEAL_RADIUS,expansion)
		var wave := PackedVector2Array()
		for i in range(65):
			wave.append(_project(player+Vector2(radius,0).rotated(float(i)*TAU/64.0)))
		draw_polyline(wave,Color(1.0,0.88,0.60,(0.16 if quieter_motion else 0.50)*(1.0-expansion)),2.0,true)
	if has_destination:
		var at := _project(destination)
		draw_arc(at,12,0,TAU,24,Color(1,0.89,0.65,0.7),2)
		for i in range(route_index, route.size()):
			var waypoint := _project(route[i])
			if _visible(waypoint,10): draw_circle(waypoint,2.5,Color(1,0.89,0.65,0.35))
	_draw_interaction_hint()
	_draw_shadow_inscriptions()
	_draw_lantern_plant_names()

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
	var col := (0 if trail else 2) + posmod(x+y,2)
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
	# Stable per-tile tint breaks the checkerboard without changing the art.
	var variation: float = _randseed(x * 13 + y * 37 + level_index * 83)
	draw_colored_polygon(points, Color(0.09,0.16,0.23,0.035 + variation * 0.055))
	if not trail and variation > 0.72:
		var glint := center + Vector2((variation-0.5)*tile, 0)
		draw_line(glint,glint+Vector2(3,-5),Color(0.53,0.72,0.63,0.24),1.0,true)
	if posmod(x+y,2) == 1:
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
	var sway: float = sin(elapsed * 0.8 + t.pos.x) * 0.013 if not quieter_motion else 0.0
	draw_set_transform(at,sway)
	_draw_crop("trees-v2",crop,Rect2(Vector2(-w*0.5,-h),Vector2(w,h)),Color(1,1,1,alpha))
	draw_set_transform(Vector2.ZERO)

func _draw_lantern(l: Dictionary) -> void:
	var at := _project(l.pos)
	var h: float = tile*(1.75 if int(l.variant) else 2.7)
	var crop: Array = LAMP_RECTS[level_index*2 + int(l.variant)]
	var w: float = minf(tile*1.25,h*float(crop[2])/float(crop[3]))
	_draw_crop("lamps-v2",crop,Rect2(at-Vector2(w*0.5,h),Vector2(w,h)))
	var light: Color = Color("#9ad9ff") if l.get("blue",false) else COLORS[level_index]
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
	var tilt: float = sin(elapsed * 1.7 + n.pos.x) * (0.065 if near else 0.025) if not quieter_motion else 0.0
	draw_set_transform(at-Vector2(0,bounce),tilt)
	_draw_png("npc-"+n.id,Vector2.ZERO,tile*1.46,tile*2.1)
	draw_set_transform(Vector2.ZERO)
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
	var art_index: int = [0,0,2,5,6][level_index]
	var h := 70.0 if level_index == 4 else 48.0
	var w := 62.0 if level_index == 2 else 50.0
	_draw_crop("quests-23",QUEST_RECTS[art_index],Rect2(at-Vector2(w*0.5,h+bob),Vector2(w,h)))
	_draw_halo(at-Vector2(0,h*0.55),45,COLORS[level_index],1.2)

func _draw_rune(r: Dictionary) -> void:
	var at := _project(r.pos)
	_draw_crop("quests-23",QUEST_RECTS[4],Rect2(at-Vector2(33,100),Vector2(66,100)))
	_draw_halo(at-Vector2(0,55),45,Color("#fff4bc") if r.lit else Color("#b3beff"),1.0)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(r.name,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
	draw_string(font,at-Vector2(width*0.5,105),r.name,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#ffe9b3") if r.lit else Color("#d9ddff"))

func _draw_station() -> void:
	var at := _project(_station())
	if level_index == 2:
		if not quest_done:
			_draw_crop("quests-23",QUEST_RECTS[2],Rect2(at-Vector2(31,52),Vector2(62,52)))
			_draw_halo(at-Vector2(0,26),45,Color("#c3ddff"),1.0)
			return
		at = _project(Vector2(_station().x+1.4,_path_y(_station().x+1.4)))+Vector2(35,30)
	var art_index: int = [0,8,3,4,7][level_index]
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
		_draw_png("woodland-key",k-Vector2(0,13+(sin(elapsed*3)*4 if not quieter_motion else 0.0)),39,40)
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
	draw_set_transform(at, 0.0, Vector2(1.0,0.32))
	for ring in range(4,0,-1):
		draw_circle(Vector2(5,2),rad*(0.65+float(ring)*0.12),Color(0.025,0.04,0.07,0.09))
	draw_circle(Vector2.ZERO,rad*0.68,Color(0.025,0.04,0.07,0.24))
	draw_set_transform(Vector2.ZERO)

func _rig_part(index: int, center: Vector2, wh: Vector2, spin: float=0.0, pivot: Vector2=Vector2(0.5,0.5)) -> void:
	var rect: Array = RIG_RECTS[index]
	# Mirror both the shoulder position AND the local crop around the body.
	var root := _ara_root()
	var mirrored := root + Vector2((center.x-root.x)*facing,center.y-root.y)
	draw_set_transform(mirrored,spin*facing,Vector2(facing,1))
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
	_rig_part(2,base+Vector2(-14,-52-breath),Vector2(18,34),gait*0.16,Vector2(0.42,0.10))
	_rig_part(1,base+Vector2(0,-35-breath),Vector2(45,44),body_lean*facing if not quieter_motion else 0.0)
	var lift := sin((1-pulse/GLOW_TIME)*PI) if pulse > 0 else 0.0
	_rig_part(3,base+Vector2(14,-51-breath),Vector2(35,49),-lift*0.42+gait*0.04,Vector2(0.16,0.10))
	_rig_part(0,base+Vector2(0,-52-breath),Vector2(70,59),(body_lean*facing*0.6+sin(elapsed*1.4)*0.03 if not quieter_motion else 0.0),Vector2(0.5,0.95))
	_draw_halo(_lantern_tip(),62,COLORS[level_index],2.0)


func _ara_root() -> Vector2:
	var motion: float = minf(1.0,walk_dir.length())
	var bounce: float = absf(sin(foot_time))*motion*3.2 if not quieter_motion else 0.0
	return _project(player)-Vector2(0,bounce)

func _lantern_tip() -> Vector2:
	var lift: float = sin((1.0-pulse/GLOW_TIME)*PI) if pulse > 0 else 0.0
	var breath: float = sin(elapsed*2.0)*0.65 if not quieter_motion else 0.0
	var gait: float = sin(foot_time)*minf(1.0,walk_dir.length()) if not quieter_motion else 0.0
	var arm_spin: float = -lift*0.42+gait*0.04
	var tip := Vector2(14,-51-breath) + Vector2(19,32).rotated(arm_spin)
	return _ara_root()+Vector2(tip.x*facing,tip.y)

func _draw_level_surface() -> void:
	# Effects sit above the textured ground and below every depth-sorted actor.
	_draw_chapter_landscape()
	if level_index == 2:
		var x: float = _station().x + 1.4
		var a := _project(Vector2(x, _path_y(x)-5))
		var b := _project(Vector2(x, _path_y(x)+5))
		var side := Vector2(tile*0.8,tile*0.39)
		draw_colored_polygon(PackedVector2Array([a-side,a+side,b+side,b-side]),Color(0.08,0.30,0.43,0.82))
		for i in range(18):
			var f := float(i)/18.0
			var at := a.lerp(b,f)+side*sin((0.0 if quieter_motion else elapsed)*1.4+float(i))*0.16
			draw_line(at-side*0.65,at+side*0.65,Color(0.53,0.87,0.92,0.13),1.4,true)
		if quest_done:
			# Real planks cross the full brook, rather than just an upright bridge picture.
			for i in range(9):
				var px := x-0.9+float(i)*0.23
				var py := _path_y(x)
				_world_polygon([Vector2(px,py-1.1),Vector2(px+0.18,py-1.1),Vector2(px+0.18,py+1.1),Vector2(px,py+1.1)],Color("#947054"))
			for side_y in [-1.15,1.15]:
				draw_line(_project(Vector2(x-0.95,_path_y(x)+side_y)),_project(Vector2(x+1.1,_path_y(x)+side_y)),Color("#deb287"),4,true)
	for i in range(22):
		var x: float = 3.0+float(i)*3.4
		var p := Vector2(x,_path_y(x)+(2.7 if i%2 else -2.7))
		var at := _project(p)
		if not _visible(at,50): continue
		match level_index:
			0: # Little leaf clusters along the birch trail.
				draw_line(at,at+Vector2(5,-3),Color(0.72,0.64,0.36,0.45),2,true)
			1: # Violet glowcaps with clear luminous caps.
				draw_line(at,at-Vector2(0,12),Color(0.75,0.66,0.84,0.7),2,true)
				draw_circle(at-Vector2(0,13),5,Color(0.69,0.49,0.98,0.85))
			3: # Star flecks embedded in the hollow floor.
				var twinkle: float = 0.35+(sin(elapsed+float(i))*0.15 if not quieter_motion else 0.0)
				draw_line(at-Vector2(3,0),at+Vector2(3,0),Color(0.82,0.85,1,twinkle),1,true)
				draw_line(at-Vector2(0,3),at+Vector2(0,3),Color(0.82,0.85,1,twinkle),1,true)
			4: # Petals encircle a warm moonflower garden.
				for petal in range(5):
					var offset := Vector2(4,0).rotated(float(petal)*TAU/5.0)
					draw_circle(at+offset-Vector2(0,6),2.4,Color(0.96,0.77,0.85,0.68))

func _world_polygon(points: Array, tint: Color) -> void:
	var projected := PackedVector2Array()
	for point in points: projected.append(_project(point))
	draw_colored_polygon(projected,tint)

func _world_oval(center: Vector2, radius: Vector2, tint: Color) -> void:
	var points: Array = []
	for i in range(48):
		var angle := float(i)*TAU/48.0
		points.append(center+Vector2(cos(angle)*radius.x,sin(angle)*radius.y))
	_world_polygon(points,tint)

func _draw_chapter_landscape() -> void:
	match level_index:
		0:
			# A pale-blue side trail makes the key grove discoverable from the main walk.
			var trail := [Vector2(24,_path_y(24)),Vector2(26,_path_y(26)+3),Vector2(29,_path_y(29)+6)]
			for i in range(2):
				for j in range(12):
					var p: Vector2 = trail[i].lerp(trail[i+1],float(j)/12.0)
					if _visible(_project(p),100): _world_oval(p,Vector2(0.65,0.65),Color(0.55,0.76,0.86,0.055))
		1:
			for x in [18.0,39.0,55.0]:
				var center := Vector2(x,_path_y(x))
				if not _visible(_project(center),tile*8): continue
				_world_oval(center,Vector2(3.7,3.7),Color(0.43,0.30,0.57,0.20))
				for i in range(18):
					var p := center+Vector2(3.6,0).rotated(float(i)*TAU/18.0)
					var at := _project(p)
					draw_line(at,at-Vector2(0,17),Color("#b4a2c8"),3,true)
					_draw_halo(at-Vector2(0,18),24,Color("#b995ff"),0.7)
					draw_circle(at-Vector2(0,18),7,Color("#aa7bd4"))
					draw_circle(at-Vector2(2,20),2,Color("#ece0ff"))
		2:
			# Pebble pools and reeds track the brook banks, leaving the walk clear.
			for x in [16.0,29.0,43.0,55.0]:
				var p := Vector2(x,_path_y(x)+5.8)
				if not _visible(_project(p),tile*5): continue
				_world_oval(p,Vector2(2.9,1.8),Color("#527076"))
				_world_oval(p,Vector2(2.55,1.5),Color("#214d64"))
				for i in range(8):
					var at := _project(p+Vector2(2.7,0).rotated(float(i)*TAU/8.0))
					draw_circle(at,5,Color("#859f9d"))
					draw_line(at,at+Vector2(4,-22),Color("#78978b"),2,true)
		3:
			var center := Vector2(70,_path_y(70))
			if _visible(_project(center),tile*14):
				_world_oval(center,Vector2(8,8),Color(0.28,0.29,0.46,0.26))
				for ring in [2.8,4.5,7.5]:
					for i in range(48):
						var p := center+Vector2(ring,0).rotated(float(i)*TAU/48.0)
						draw_circle(_project(p),3.0,Color(0.77,0.79,1,0.72))
				for i in range(runes.size()-1):
					var a := _project(runes[i].pos)-Vector2(0,60)
					var b := _project(runes[i+1].pos)-Vector2(0,60)
					draw_line(a,b,Color(0.81,0.83,1,0.6 if quest_done else 0.14),2,true)
		4:
			for x in range(70,83,3):
				for side in [-1.0,1.0]:
					var p := Vector2(x,_path_y(x)+side*4.0)
					if not _visible(_project(p),tile*3): continue
					_world_oval(p,Vector2(1.3,1.3),Color(0.33,0.25,0.29,0.55))
					_draw_crop("quests-23",QUEST_RECTS[6],Rect2(_project(p)-Vector2(23,55),Vector2(46,55)))
					for i in range(9):
						var at := _project(p+Vector2(0.9,0).rotated(float(i)*TAU/9.0))
						for petal in range(5):
							draw_circle(at+Vector2(4,0).rotated(float(petal)*TAU/5.0)-Vector2(0,10),3.2,Color("#d8a8c5"))
						draw_circle(at-Vector2(0,10),2.8,Color("#ffe6a0"))

func _draw_landmark(mark: Dictionary) -> void:
	var at := _project(mark.pos)
	var i: int = int(mark.index)
	# Existing painted assets anchor the landscape details in the original art style.
	if level_index == 1 and i < 2:
		_draw_crop("decor",DECOR_RECTS[0],Rect2(at-Vector2(55,112),Vector2(110,112)))
	elif level_index == 2 and i < 2:
		_draw_crop("decor",DECOR_RECTS[1],Rect2(at-Vector2(48,100),Vector2(96,100)))
	elif level_index == 3 and i < 2:
		_draw_crop("decor",DECOR_RECTS[6],Rect2(at-Vector2(40,110),Vector2(80,110)))
	elif level_index == 4 and i < 2:
		_draw_crop("decor",DECOR_RECTS[4],Rect2(at-Vector2(45,85),Vector2(90,85)))

func _draw_landmark_names() -> void:
	for mark in landmarks:
		if player.distance_to(mark.pos) >= 7.0: continue
		var at := _project(mark.pos)
		var font := ThemeDB.fallback_font
		var text: String = mark.name
		var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
		var pos := at+Vector2(-width*0.5,22)
		if not _landmark_label_clear(Rect2(pos-Vector2(10,17),Vector2(width+20,25))): continue
		draw_style_box(_landmark_style(),Rect2(pos-Vector2(10,17),Vector2(width+20,25)))
		draw_string(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#eee4cb"))

func _landmark_label_clear(box: Rect2) -> bool:
	# Discovery clues and toast messages take priority over scenery labels.
	if toast_seconds > 0 and box.intersects(Rect2(size*Vector2(0.24,0.79),size*Vector2(0.52,0.14))): return false
	if light_trails == null: return true
	for stone in light_trails.stones:
		if stone.time <= 0: continue
		var at := _project(stone.pos+stone.direction*1.6)+Vector2(0,24)
		var width := ThemeDB.fallback_font.get_string_size(stone.text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
		if box.intersects(Rect2(at-Vector2(width*0.5+14,23),Vector2(width+28,35))): return false
	return true

func _landmark_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04,0.09,0.16,0.80)
	style.set_corner_radius_all(7)
	return style

func _draw_interaction_hint() -> void:
	if state != "play": return
	var target := Vector2.ZERO
	var text := ""
	var npc := _nearest_npc()
	if npc >= 0:
		target = _project(npcs[npc].pos)-Vector2(0,tile*2.2)
		text = "E · Talk to " + str(npcs[npc].name)
	elif level_index > 0 and player.distance_to(_station()) < INTERACT_RADIUS:
		target = _project(_station())-Vector2(0,115)
		text = "E · Quest station"
	elif level_index == 0 and player.distance_to(_exit()) < INTERACT_RADIUS:
		target = _project(_exit())-Vector2(0,175)
		text = "E · Open door" if key_collected else "Door locked"
	if text.is_empty(): return
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
	draw_style_box(_landmark_style(),Rect2(target-Vector2(width*0.5+10,20),Vector2(width+20,30)))
	draw_string(font,target-Vector2(width*0.5,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#ffe1a1"))

func _draw_lantern_clues_ground() -> void:
	if light_trails == null: return
	for track in light_trails.tracks:
		if track.time <= 0: continue
		var at := _project(track.pos)
		if not _visible(at,30): continue
		var direction: Vector2 = track.direction
		var projected := Vector2(direction.x-direction.y,(direction.x+direction.y)*0.49)
		var fade := minf(1.0,float(track.time)/3.0)
		_draw_halo(at,18,Color("#b9f3ff"),fade*1.7)
		draw_set_transform(at,projected.angle()-PI*0.5,Vector2(0.85,1.0))
		draw_circle(Vector2.ZERO,5.0,Color(0.63,0.91,1.0,0.62*fade))
		for toe in range(3):
			draw_circle(Vector2(float(toe-1)*4.0,7.0-absf(float(toe-1))*1.0),2.1,Color(0.88,0.98,1.0,0.90*fade))
		draw_set_transform(Vector2.ZERO)
	for stone in light_trails.stones:
		var at := _project(stone.pos)
		if not _visible(at,tile*4): continue
		var cast: Vector2 = (stone.pos-player).normalized()
		if player.distance_to(stone.pos) > 7.0: cast = Vector2(1,0.3).normalized()
		var lit: bool = stone.time > 0
		if lit: cast = stone.direction
		var side := Vector2(-cast.y,cast.x)
		var tip: Vector2 = stone.pos+cast*2.7
		var p: Vector2 = stone.pos
		var shape := [p-side*0.22,p+cast*1.9-side*0.22,p+cast*1.9-side*0.65,tip,p+cast*1.9+side*0.65,p+cast*1.9+side*0.22,p+side*0.22]
		if not lit: shape = [p-side*0.30,p+cast*1.9-side*0.16,p+cast*2.2,p+cast*1.9+side*0.16,p+side*0.30]
		_world_polygon(shape,Color(0.015,0.03,0.08,0.76))
		if lit:
			var fade := minf(1.0,float(stone.time)/3.0)
			var line := PackedVector2Array()
			for point in shape: line.append(_project(point))
			line.append(_project(shape[0]))
			draw_polyline(line,Color(0.95,0.83,0.54,0.8*fade),2.0,true)
			_draw_halo(_project(tip),32,Color("#ffe7ae"),fade)
		# This visible marker teaches the alignment without revealing the answer.
		var marker := _project(stone.stand)
		draw_arc(marker,14.0,0.25,PI*1.65,24,Color(0.94,0.76,0.39,0.85),3,true)
		draw_circle(marker+Vector2(0,-3),2,Color("#fff0bd"))

func _draw_lantern_plant(plant: Dictionary) -> void:
	var at := _project(plant.pos)
	var awake: bool = plant.awake
	var bob := sin(elapsed*1.6+float(plant.index))*2.0 if awake and not quieter_motion else 0.0
	_shadow(at,15)
	var stem := at-Vector2(0,32+bob)
	draw_line(at,stem,Color("#699c94"),3,true)
	for side in [-1.0,1.0]:
		var leaf := PackedVector2Array([at-Vector2(0,9),at+Vector2(side*15,-18),at+Vector2(side*9,-5)])
		draw_colored_polygon(leaf,Color("#83b5a4") if awake else Color("#46786b"))
	_draw_halo(stem,70 if awake else 28,Color("#94ffe1"),2.4 if awake else 0.5)
	if awake:
		for petal in range(7):
			var offset := Vector2(9,0).rotated(float(petal)*TAU/7.0)
			draw_circle(stem+offset,6,Color("#87d6cb"))
			draw_circle(stem+offset*1.15,2.8,Color("#c9fff0"))
		draw_circle(stem,6.5,Color("#fff0b0"))
	else:
		draw_circle(stem,7,Color("#416f87"))
		draw_arc(stem,7,-PI*0.8,-PI*0.2,12,Color("#a0d0e6"),2,true)

func _draw_lantern_plant_names() -> void:
	if light_trails == null: return
	for plant in light_trails.plants:
		if player.distance_to(plant.pos) >= 3.5: continue
		var at := _project(plant.pos)
		var font := ThemeDB.fallback_font
		var text := "Lantern bloom" if plant.awake else "Space / GLOW"
		var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
		draw_style_box(_landmark_style(),Rect2(at-Vector2(width*0.5+7,73),Vector2(width+14,23)))
		draw_string(font,at-Vector2(width*0.5,57),text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#c8ffe9"))

func _draw_shadow_stone(stone: Dictionary) -> void:
	var at := _project(stone.pos)
	_shadow(at,24)
	var top := at-Vector2(0,35)
	draw_colored_polygon(PackedVector2Array([at+Vector2(-20,-3),at+Vector2(-17,-28),top,at+Vector2(17,-28),at+Vector2(21,-3),at+Vector2(0,6)]),Color("#4d6171"))
	draw_colored_polygon(PackedVector2Array([at+Vector2(-17,-28),top,at+Vector2(17,-28),at+Vector2(0,-19)]),Color("#899fa3"))
	draw_line(at-Vector2(0,18),at-Vector2(0,3),Color("#e9c990"),2,true)
	draw_arc(at-Vector2(0,12),6,-PI*0.8,PI*0.2,16,Color("#e9c990"),2,true)
	if stone.time > 0: _draw_halo(top,50,Color("#ffe5a3"),1.5)

func _draw_shadow_inscriptions() -> void:
	if light_trails == null: return
	for stone in light_trails.stones:
		if stone.time <= 0: continue
		var at := _project(stone.pos+stone.direction*1.6)+Vector2(0,24)
		if not _visible(at,100): continue
		var text: String = stone.text
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
		var fade := minf(1.0,float(stone.time)/3.0)
		var box := _landmark_style()
		box.bg_color.a *= fade
		draw_style_box(box,Rect2(at-Vector2(width*0.5+10,19),Vector2(width+20,27)))
		draw_string(font,at-Vector2(width*0.5,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(1.0,0.90,0.65,fade))
