extends "res://scripts/core.gd"

var beauty_art = preload("res://scripts/hidden_wonders_art.gd").new()

const LIVING_ART = preload("res://scripts/living_art.gd")
const ADVENTURE_ART = preload("res://scripts/adventure_art.gd")
const PATHWAY_ART = preload("res://scripts/pathway_art.gd")

# --- Art renderer: native CanvasItem / Godot Texture2D drawing ---
func _draw() -> void:
	if tex.is_empty(): return
	if state == "menu" or state == "comic" or (state == "dialog" and not conversation.active and (dialog_from in ["menu","newgame"] or dialog_from.begins_with("travel-"))):
		_cover("keepsake-cover")
		_moon_haze()
		for i in range(28):
			var px: float = _randseed(i * 17) * size.x + (sin(elapsed * 0.4 + i) * 16 if not quieter_motion else 0.0)
			var py: float = _randseed(i * 23 + 5) * size.y + (cos(elapsed * 0.3 + i) * 12 if not quieter_motion else 0.0)
			_disc(Vector2(px,py), 1.4, Color(0.98,0.89,0.61,0.25))
		return
	if not (state == "play" or state == "dialog" or state == "win"): return
	var draw_begin := Time.get_ticks_usec()
	foliage_focus=_focus_points()
	_refresh_visible_trees()
	_draw_level_surface()
	_draw_lantern_clues_ground()
	var selected: Dictionary=_interaction_target()
	if not selected.is_empty():
		var selected_foot: Vector2=_project(selected.pos)
		draw_set_transform(selected_foot,0,Vector2(1,.48))
		draw_arc(Vector2.ZERO,23,0,TAU,40,Color("#f5df9d"),3,true)
		draw_set_transform(Vector2.ZERO)
	_moon_haze()
	ADVENTURE_ART.signs(self)
	LIVING_ART.ground(self)
	beauty_art.paths(self)
	var entities: Array = []
	for plant in botany.plants:
		if _visible(_project(plant.pos),tile*3): entities.append({"depth":plant.pos.x+plant.pos.y,"type":"botanical","data":plant})
	for prop in objects.items:
		if _visible(_project(prop.pos),tile*3): entities.append({"depth":prop.pos.x+prop.pos.y,"type":"whimsy","data":prop})
	for crossing in pathways.crossings:
		if _visible(_project(crossing.pos),tile*7): entities.append({"depth":crossing.pos.x+crossing.pos.y+crossing.offset+2.0,"type":"bridge_front","data":crossing})
	for prop in beauty.scenery:
		if _visible(_project(prop.pos),tile*3): entities.append({"depth":prop.pos.x+prop.pos.y,"type":"beauty_prop","data":prop})
	for chest in beauty.chests:
		if _visible(_project(chest.pos),tile*3): entities.append({"depth":chest.pos.x+chest.pos.y,"type":"treasure","data":chest})
	for star in beauty.stars:
		if not star.found and _visible(_project(star.pos),tile): entities.append({"depth":star.pos.x+star.pos.y,"type":"star","data":star})
	for clue in living.clues:
		if _visible(_project(clue.pos),tile*2): entities.append({"depth":clue.pos.x+clue.pos.y,"type":"ira_clue","data":clue})
	if not living.visitor.is_empty() and _visible(_project(living.visitor.pos),tile*2): entities.append({"depth":living.visitor.pos.x+living.visitor.pos.y,"type":"visitor","data":{}})
	for loop in exploration.loops:
		if _visible(_project(loop.pos),tile*3): entities.append({"depth":loop.pos.x+loop.pos.y,"type":"secret","data":loop})
	for o in pathways.obstacles:
		if _visible(_project(o.pos),tile*3): entities.append({"depth":o.pos.x+o.pos.y,"type":"path_obstacle","data":o})
	if level_index==1:
		var wp: Vector2 = pathways.web_position()
		entities.append({"depth":wp.x+wp.y,"type":"web","data":{}})
	for t in visible_trees:
		if _visible(_project(t.pos),tile*5): entities.append({"depth":t.pos.x+t.pos.y, "type":"tree", "data":t})
	for t in lanterns:
		if _visible(_project(t.pos),tile*3): entities.append({"depth":t.pos.x+t.pos.y,"type":"lantern","data":t})
	for t in decorations:
		if _visible(_project(t.pos),tile*2): entities.append({"depth":t.pos.x+t.pos.y,"type":"decor","data":t})
	for npc in npcs:
		if _visible(_project(npc.pos),tile*3): entities.append({"depth":npc.pos.x+npc.pos.y,"type":"npc","data":npc})
	for m in marks:
		if beauty.item_available(m) and _visible(_project(m.pos),tile*3): entities.append({"depth":m.pos.x+m.pos.y,"type":"item","data":m})
	for rune in runes:
		if _visible(_project(rune.pos),tile*3): entities.append({"depth":rune.pos.x+rune.pos.y,"type":"rune","data":rune})
	for b in bats:
		if _visible(_project(b.pos),tile*3): entities.append({"depth":b.pos.x+b.pos.y,"type":"bat","data":b})
	for prop in ambience.scenery:
		if _visible(_project(prop.pos),tile*5): entities.append({"depth":prop.pos.x+prop.pos.y,"type":"flourish","data":prop})
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
	entities.append({"depth":exit_pos.x+exit_pos.y-(3.5 if player.distance_to(exit_pos)<4 else 0.0),"type":"exit","data":{}})
	entities.append({"depth":player.x+player.y,"type":"ara","data":{}})
	entities.sort_custom(func(a,b): return a.depth < b.depth)
	for entity in entities:
		var d: Dictionary = entity.data
		match entity.type:
			"botanical": botany.draw_plant(self,d)
			"whimsy": object_art.prop(self,d)
			"bridge_front": object_art.rail(self,d,1)
			"beauty_prop": beauty_art.scenery(self,d)
			"treasure": beauty_art.chest(self,d)
			"star": beauty_art.star(self,d)
			"ira_clue": LIVING_ART.clue(self,d)
			"visitor": LIVING_ART.visitor(self)
			"secret": ADVENTURE_ART.secret(self,d)
			"path_obstacle": PATHWAY_ART.obstacle(self,d)
			"web": PATHWAY_ART.web(self)
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
			"flourish": _draw_woodland_prop(d)
	ADVENTURE_ART.moments(self)
	LIVING_ART.guide(self)
	_draw_landmark_names()
	for part in particles:
		var fade: float = part.life / part.max
		var dust: bool = part.get("kind","") == "dust"
		var at: Vector2 = _project(part.pos)+part.offset*(1.0-fade)*(18 if dust else 90)-Vector2(0,4 if dust else 45)
		_disc(at,(4.0 if dust else 3.3)*fade,Color(0.75,0.77,0.64,fade*0.22) if dust else Color(1.0,0.91,0.62,fade))
	if pulse > 0:
		var expansion := 1.0 - pulse/GLOW_TIME
		var radius := 2.4 if quieter_motion else lerpf(0.6,light_trails.REVEAL_RADIUS,expansion)
		var wave := PackedVector2Array()
		for i in range(65):
			wave.append(_project(player+Vector2(radius,0).rotated(float(i)*TAU/64.0)))
		draw_polyline(wave,Color(1.0,0.88,0.60,(0.16 if quieter_motion else 0.50)*(1.0-expansion)),2.0,true)
	if has_destination or destination_feedback>0:
		var at := _project(destination)
		var tint := Color("#efb4ad") if destination_status=="blocked" else Color("#f5df9d")
		var radius: float=13 if quieter_motion else 13+sin(elapsed*4)*2
		draw_arc(at,radius,0,TAU,32,tint,2,true)
		if destination_status=="blocked":
			draw_line(at-Vector2(5,5),at+Vector2(5,5),tint,2,true)
			draw_line(at+Vector2(-5,5),at+Vector2(5,-5),tint,2,true)
		elif destination_status=="arrived":
			draw_polyline(PackedVector2Array([at+Vector2(-5,0),at+Vector2(-1,4),at+Vector2(6,-4)]),tint,2,true)
		else: _disc(at,3,tint)
		for i in range(route_index, route.size()):
			var waypoint := _project(route[i])
			if _visible(waypoint,10): _disc(waypoint,2.5,Color(tint,.35))
	if level_index==0 and not opening.found:
		var ribbon_at: Vector2=_project(opening.ribbon)
		draw_polyline(PackedVector2Array([ribbon_at+Vector2(-14,-5),ribbon_at+Vector2(0,2),ribbon_at+Vector2(12,-7),ribbon_at+Vector2(5,9)]),Color("#efb2c4"),5,true)
	_draw_interaction_hint()
	_draw_shadow_inscriptions()
	_draw_lantern_plant_names()
	_draw_woodland_air()
	render_cpu_us = Time.get_ticks_usec()-draw_begin

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
			_disc(at, float(k)*80.0, Color(0.65,0.77,1.0,0.007))

func _visible(point: Vector2, pad: float=130) -> bool:
	return point.x > -pad and point.y > -pad and point.x < size.x+pad and point.y < size.y+pad

func _draw_crop(name: String, src: Array, dst: Rect2, color: Color=Color.WHITE) -> void:
	var texture: Texture2D = tex.get(name)
	if texture:
		draw_texture_rect_region(texture,dst,Rect2(float(src[0]),float(src[1]),float(src[2]),float(src[3])),color)

func _draw_png(name: String, at: Vector2, w: float, h: float, alpha: float=1.0) -> void:
	var t: Texture2D = tex.get(name)
	if t: draw_texture_rect(t,Rect2(Vector2(at.x-w*0.5,at.y-h),Vector2(w,h)),false,Color(1,1,1,alpha))

func _draw_halo(at: Vector2, radius: float, tint: Color, weight: float=1.0) -> void:
	for ring in range(3,0,-1):
		var f := float(ring)/3.0
		_disc(at,radius*f,Color(tint.r,tint.g,tint.b,weight * (1-f) * 0.065))

func _draw_tree(t: Dictionary) -> void:
	keepsake.tree(self,t)

func _draw_lantern(l: Dictionary) -> void:
	keepsake.lamp(self,l)

func _draw_decoration(d: Dictionary) -> void:
	keepsake.scenery(self,2,_project(d.pos),tile*.95*float(d["size"]))

const NPC_CROPS = [
	[18,22,340,277],[379,2,330,319],[711,42,230,177],[1073,12,258,300],[1384,46,223,251],
	[7,319,343,279],[360,319,350,286],[729,343,300,223],[1063,331,222,248],[1336,328,278,287],
	[10,602,352,319],[363,613,408,350],[765,656,263,208],[1052,653,237,257],[1305,620,310,319]
]

func _npc_part(n: Dictionary, index: int, offset: Vector2, wh: Vector2, spin: float=0.0, pivot: Vector2=Vector2(0.5,0.5)) -> void:
	var facing_npc: float = float(n.facing)
	var at := _project(n.pos)+Vector2(offset.x*facing_npc,offset.y)
	draw_set_transform(at,spin*facing_npc,Vector2(facing_npc,1.0))
	_draw_crop("npc-rig-22",NPC_CROPS[index],Rect2(-wh*pivot,wh))
	draw_set_transform(Vector2.ZERO)

func _draw_npc(n: Dictionary) -> void:
	keepsake.npc(self,n)

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
		return # Repaired deck is rendered in the ground pass.
	var art_index: int = [0,8,3,4,7][level_index]
	var w := 175.0 if level_index == 2 else 110.0
	var h := 120.0 if level_index == 2 else 100.0
	_draw_crop("quests-23",QUEST_RECTS[art_index],Rect2(at-Vector2(w*0.5,h),Vector2(w,h)))
	_draw_halo(at-Vector2(0,h*0.6),55,Color("#ffeaa5") if quest_done else Color("#c3ddff"),1.2)

func _draw_bat(b: Dictionary) -> void:
	keepsake.bat(self,b)

func _draw_birches() -> void:
	var at := _project(Vector2(29,_path_y(29)+6))
	_draw_png("key-birches",at,tile*3.2,tile*3.6,.18 if player.distance_to(_key_location())<4 else 1.0)
	_draw_halo(at-Vector2(0,35),72,Color("#a1dfff"),1.0)
	if key_revealed and not key_collected and beauty.key_available():
		var k := _project(_key_location())
		_draw_png("woodland-key",k-Vector2(0,13+(sin(elapsed*3)*4 if not quieter_motion else 0.0)),39,40)
		_draw_halo(k-Vector2(0,37),40,Color("#ffe99f"),1.7)

func _draw_exit() -> void:
	var at := _project(_exit())
	_draw_halo(at-Vector2(0,75),95,COLORS[level_index],1.3 if quest_done or key_collected else .6)
	keepsake.gate(self,at)

func _shadow(at: Vector2, rad: float) -> void:
	draw_set_transform(at, 0.0, Vector2(1.0,0.32))
	for ring in range(2,0,-1):
		_disc(Vector2(5,2),rad*(0.65+float(ring)*0.12),Color(0.025,0.04,0.07,0.09))
	_disc(Vector2.ZERO,rad*0.68,Color(0.025,0.04,0.07,0.24))
	draw_set_transform(Vector2.ZERO)

func _rig_part(index: int, center: Vector2, wh: Vector2, spin: float=0.0, pivot: Vector2=Vector2(0.5,0.5)) -> void:
	var rect: Array = RIG_RECTS[index]
	# Mirror both the shoulder position AND the local crop around the body.
	var root := _ara_root()
	var mirrored := _ara_frame(center-root)
	draw_set_transform(mirrored,spin*facing+(body_lean+personality.lean() if not quieter_motion else 0.0),Vector2(facing,1))
	_draw_crop("ara-rig-22",rect,Rect2(-wh*pivot,wh))
	draw_set_transform(Vector2.ZERO)

func _draw_ara() -> void:
	keepsake.ara(self)

func _ara_root() -> Vector2:
	var motion: float = minf(1.0,walk_dir.length())
	var bounce: float = absf(sin(foot_time))*motion*3.2 if not quieter_motion else 0.0
	var at := _project(player)-Vector2(0,bounce+personality.hop())+Vector2(0,personality.dip())
	if state=="win" and level_index==4: at=at.lerp(_project(_exit())+Vector2(18,4),personality.reunion)
	return at

func _lantern_tip() -> Vector2:
	return keepsake.ara_lantern(self)

func _ara_frame(local: Vector2) -> Vector2:
	var pivot := Vector2(0,-32)
	var tilt: float = body_lean+personality.lean() if not quieter_motion else 0.0
	var mirrored := Vector2(local.x*facing,local.y)
	return _ara_root()+pivot+(mirrored-pivot).rotated(tilt)

func _draw_level_surface() -> void:
	# Effects sit above the textured ground and below every depth-sorted actor.
	_draw_chapter_landscape()
	PATHWAY_ART.crossings(self)
	for i in range(22):
		var x: float = 3.0+float(i)*3.4
		var p := Vector2(x,_path_y(x)+(2.7 if i%2 else -2.7))
		var at := _project(p)
		if not _visible(at,50): continue
		match level_index:
			0: # Little leaf clusters along the birch trail.
				_storybook_fern(at,float(i))
			1: # Violet glowcaps with clear luminous caps.
				draw_line(at,at-Vector2(0,12),Color(0.75,0.66,0.84,0.7),2,true)
				_disc(at-Vector2(0,13),5,Color(0.69,0.49,0.98,0.85))
			3: # Star flecks embedded in the hollow floor.
				var twinkle: float = 0.35+(sin(elapsed+float(i))*0.15 if not quieter_motion else 0.0)
				draw_line(at-Vector2(3,0),at+Vector2(3,0),Color(0.82,0.85,1,twinkle),1,true)
				draw_line(at-Vector2(0,3),at+Vector2(0,3),Color(0.82,0.85,1,twinkle),1,true)
			4: # Petals encircle a warm moonflower garden.
				_woodland_flower(at-Vector2(0,7),Color("#e4bdce"),7.0)

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
				_world_oval(center,Vector2(3.7,3.7),Color(0.64,0.58,0.77,0.04))
				for i in range(8):
					var p := center+Vector2(3.6,0).rotated(float(i)*TAU/8.0)
					keepsake.scenery(self,2,_project(p),tile*.55)
		2:
			# Pebble pools and reeds track the brook banks, leaving the walk clear.
			for c in pathways.crossings:
				var p := Vector2(c.x,c.pos.y+5.8)
				if not _visible(_project(p),tile*5): continue

				for i in range(8):
					var at := _project(p+Vector2(2.7,0).rotated(float(i)*TAU/8.0))
					_disc(at,5,Color("#859f9d"))
					draw_line(at,at+Vector2(4,-22),Color("#78978b"),2,true)
		3:
			var center := Vector2(70,_path_y(70))
			if _visible(_project(center),tile*14):
				_world_oval(center,Vector2(8,8),Color(0.48,0.53,0.70,0.055))
				for ring in [2.8,4.5,7.5]:
					var orbit := PackedVector2Array()
					for i in range(65):
						orbit.append(_project(center+Vector2(ring,0).rotated(float(i)*TAU/64.0)))
					draw_polyline(orbit,Color(0.77,0.79,1,0.22),1.3,true)
					for i in range(12):
						var angle := float(i)*TAU/12.0+(elapsed*0.025 if not quieter_motion else 0.0)
						var star := _project(center+Vector2(ring,0).rotated(angle))
						_disc(star,2.1,Color(0.87,0.87,1,0.65))
						if graphics_quality>0: _draw_halo(star,12,Color("#c7bfff"),0.7)
				for i in range(runes.size()-1):
					var a := _project(runes[i].pos)-Vector2(0,60)
					var b := _project(runes[i+1].pos)-Vector2(0,60)
					draw_line(a,b,Color(0.81,0.83,1,0.6 if quest_done else 0.14),2,true)
		4:
			for x in range(70,83,3):
				for side in [-1.0,1.0]:
					var p := Vector2(x,_path_y(x)+side*4.0)
					if not _visible(_project(p),tile*3): continue
					keepsake.scenery(self,2,_project(p),tile*1.05)
					for i in range(9):
						var at := _project(p+Vector2(0.9,0).rotated(float(i)*TAU/9.0))
						_woodland_flower(at-Vector2(0,10),Color("#d8a8c5"),8.0)

func _draw_landmark(mark: Dictionary) -> void:
	if int(mark.index) >= 2: return
	keepsake.scenery(self,3,_project(mark.pos),tile*1.85)

func _draw_landmark_names() -> void:
	if state!="play" or (conversation!=null and conversation.notice_left>0): return
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
	if state!="play": return
	var focus: Dictionary=_interaction_target()
	if focus.is_empty(): return
	var foot: Vector2=_project(focus.pos)
	if conversation!=null and conversation.notice_left>0:return
	var target: Vector2=foot-Vector2(0,tile*1.9)
	var text: String=("Tap "+str(focus.action)+" · " if joystick.visible else "E · ")+str(focus.label)
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
		_disc(Vector2.ZERO,5.0,Color(0.63,0.91,1.0,0.62*fade))
		for toe in range(3):
			_disc(Vector2(float(toe-1)*4.0,7.0-absf(float(toe-1))*1.0),2.1,Color(0.88,0.98,1.0,0.90*fade))
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
		_world_polygon(shape,Color(0.10,0.16,0.20,0.30 if lit else 0.15))
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
		_disc(marker+Vector2(0,-3),2,Color("#fff0bd"))

func _draw_lantern_plant(plant: Dictionary) -> void:
	var at := _project(plant.pos)
	var awake: bool = plant.awake
	var bob := sin(elapsed*1.6+float(plant.index))*2.0 if awake and not quieter_motion else 0.0
	_shadow(at,15)
	var stem := at-Vector2(0,32+bob)
	draw_line(at,stem,Color("#699c94"),3,true)
	for side in [-1.0,1.0]:
		_storybook_petal(at-Vector2(0,9),-0.65 if side>0 else PI+0.65,19.0,5.5,Color("#83b5a4") if awake else Color("#46786b"))
	_draw_halo(stem,70 if awake else 28,Color("#94ffe1"),2.4 if awake else 0.5)
	if awake:
		for petal in range(7):
			var opening := smoothstep(0.0,1.0,float(plant.bloom))
			_storybook_petal(stem,float(petal)*TAU/7.0,lerpf(5.0,17.0,opening),lerpf(2.0,6.5,opening),Color("#a4eee0"))
		_disc(stem,6.5,Color("#fff0b0"))
	else:
		_disc(stem,7,Color("#416f87"))
		draw_arc(stem,7,-PI*0.8,-PI*0.2,12,Color("#a0d0e6"),2,true)

func _draw_lantern_plant_names() -> void:
	if state!="play" or (conversation!=null and conversation.notice_left>0): return
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
	_shadow(at,20)
	_draw_crop("quests-23",QUEST_RECTS[4],Rect2(at-Vector2(21,63),Vector2(42,63)))
	if stone.time>0: _draw_halo(at-Vector2(0,37),43,Color("#ffe5a3"),1.4)


func _draw_shadow_inscriptions() -> void:
	if state!="play" or (conversation!=null and conversation.notice_left>0): return
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

# Each chapter has its own small set of animated, nonblocking scenic props.
func _draw_woodland_prop(prop: Dictionary) -> void:
	var at := _project(prop.pos)
	var floral: bool=prop.kind in ["mushroom","lily"]
	var height: float=tile*(1.0 if floral else 1.9)
	keepsake.scenery(self,2 if floral else 3,at,height)

var flower_textures: Dictionary = {}
func _woodland_flower(at: Vector2, tint: Color, radius: float) -> void:
	var key := tint.to_html()
	if not flower_textures.has(key):
		var image := Image.create(96,96,false,Image.FORMAT_RGBA8)
		for y in range(96):
			for x in range(96):
				var q := Vector2((float(x)+0.5)/48.0-1.0,(float(y)+0.5)/48.0-1.0)
				var result := Color(0,0,0,0)
				for i in range(5):
					var local := q.rotated(-float(i)*TAU/5.0)
					var v := local.y/0.42
					var distance := Vector2((local.x-0.5)*2.0,v).length()
					var alpha := 1.0-smoothstep(0.94,1.0,distance)
					if alpha<=result.a: continue
					var shade := 0.89-v*0.12
					var vein := (1.0-smoothstep(0.01,0.055,absf(v)))*smoothstep(0.08,0.2,local.x)*(1.0-smoothstep(0.65,0.88,local.x))
					shade -= vein*0.16
					result = Color(shade*tint.r,shade*tint.g,shade*tint.b,alpha)
				if q.length()<0.27:
					result = Color("#b88b54")
				if (q+Vector2(0,0.08)).length()<0.19:
					result = Color("#fff0ba")
				image.set_pixel(x,y,result)
		flower_textures[key] = ImageTexture.create_from_image(image)
	draw_texture_rect(flower_textures[key],Rect2(at-Vector2.ONE*radius,Vector2.ONE*radius*2.0),false)

func _draw_woodland_air() -> void:
	var clock := 0.0 if quieter_motion else elapsed
	for creature in ambience.nearby_creatures():
		var phase: float = creature.phase
		var at := _project(creature.home)+Vector2(sin(clock*0.7+phase)*23,-29+cos(clock*1.1+phase)*9)
		if not _visible(at,20): continue
		var responding: bool = ambience.response>0 and creature.home.distance_to(player)<5
		var wing := 2.0+absf(sin(clock*9.0+phase))*3.0
		match level_index:
			0:
				var alpha := 0.35+(sin(clock*2.0+phase)+1.0)*0.22
				_disc(at,2.1,Color(1.0,0.89,0.57,alpha))
				if responding: _draw_halo(at,17,Color("#ffe8a9"),2.0)
			1,4:
				var tint := Color("#e4c9ef") if level_index==1 else Color("#ffe3b4")
				if responding: tint = Color("#b9ffe0")
				for side in [-1.0,1.0]:
					_storybook_petal(at,-0.8 if side>0 else PI+0.8,wing*2.2,wing*0.85,tint)
					_storybook_petal(at,0.65 if side>0 else PI-0.65,wing*1.5,wing*0.6,tint.darkened(0.13))
				draw_line(at-Vector2(0,4),at+Vector2(0,4),Color("#59626c"),1.5,true)
			2:
				var ripple := fmod(clock*0.45+phase,1.0)
				var water := _project(creature.home)+Vector2(0,8)
				draw_set_transform(water,0,Vector2(1,0.4))
				draw_arc(Vector2.ZERO,8+ripple*23,0,TAU,24,Color(0.65,0.88,0.91,(1-ripple)*0.3),1,true)
				draw_set_transform(Vector2.ZERO)
				if int(creature.index)%4==0:
					var hop := maxf(0,sin(clock*1.8+phase))*8.0
					var frog := water-Vector2(0,hop+8)
					_disc(frog,5,Color("#8eb68c"))
					for side in [-1.0,1.0]: _disc(frog+Vector2(side*3,-3),2,Color("#e9e6bb"))
			3:
				var radius := 3.0+(sin(clock+phase)+1)*0.7
				draw_line(at-Vector2(radius,0),at+Vector2(radius,0),Color("#d2d5fa"),1.5,true)
				draw_line(at-Vector2(0,radius),at+Vector2(0,radius),Color("#d2d5fa"),1.5,true)
		if responding and level_index!=0: draw_arc(at,11,0,TAU,16,Color(1,0.91,0.69,0.35),1,true)
	if level_index==3 and not quieter_motion:
		var flight := fmod(elapsed,8.0)
		if flight<1.0:
			var star := Vector2(size.x*0.15+flight*size.x*0.55,190+flight*90)
			draw_line(star-Vector2(44,7),star,Color(0.79,0.83,1,(1-flight)*0.45),2,true)
			_disc(star,2.5,Color("#fff4cf"))
	if level_index==4 and quest_done:
		var center := _project(_station())-Vector2(0,85)
		for i in range(3):
			var rise := fmod(clock*0.22+float(i)/3.0,1.0)
			var note := center+Vector2(sin(rise*TAU+float(i))*24,-rise*55)
			draw_line(note,note-Vector2(0,13),Color(1,0.90,0.66,1-rise),1.5,true)
			_disc(note-Vector2(2,0),3,Color(1,0.90,0.66,1-rise))
	if celebration>0:
		var at := _project(player)-Vector2(0,70)
		for i in range(8):
			var angle := float(i)*TAU/8.0
			var radius := 38.0 if quieter_motion else 24.0+(2.5-celebration)*22.0
			var spark := at+Vector2(radius,0).rotated(angle)
			_disc(spark,3,Color(1,0.89,0.62,minf(1,celebration)))

# A shared antialiased disc lets petals, shadows and motes batch as textured quads.
var disc_texture: GradientTexture2D
func _disc(at: Vector2, radius: float, tint: Color) -> void:
	if disc_texture == null:
		disc_texture = GradientTexture2D.new()
		disc_texture.width = 64
		disc_texture.height = 64
		disc_texture.fill = GradientTexture2D.FILL_RADIAL
		disc_texture.fill_from = Vector2(0.5,0.5)
		disc_texture.fill_to = Vector2(1.0,0.5)
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0,0.92,1.0])
		gradient.colors = PackedColorArray([Color.WHITE,Color.WHITE,Color(1,1,1,0)])
		disc_texture.gradient = gradient
	draw_texture_rect(disc_texture,Rect2(at-Vector2.ONE*radius,Vector2.ONE*radius*2),false,tint)

# Build one tiny shaded petal texture, then reuse it for flowers, ferns and wings.
# Textured quads batch across hundreds of petals; per-petal polygons do not.
var petal_texture: ImageTexture
func _storybook_petal(at: Vector2, angle: float, length_px: float, width: float, tint: Color) -> void:
	if petal_texture == null:
		var image := Image.create(96,48,false,Image.FORMAT_RGBA8)
		for y in range(48):
			for x in range(96):
				var u := (float(x)+0.5)/96.0
				var v := (float(y)+0.5)/24.0-1.0
				var distance := Vector2((u-0.5)*2.0,v).length()
				var alpha := 1.0-smoothstep(0.94,1.0,distance)
				var shade := 0.89-v*0.12
				var vein := (1.0-smoothstep(0.01,0.055,absf(v)))*smoothstep(0.08,0.2,u)*(1.0-smoothstep(0.65,0.88,u))
				shade -= vein*0.16
				image.set_pixel(x,y,Color(shade,shade,shade,alpha))
		petal_texture = ImageTexture.create_from_image(image)
	draw_set_transform(at,angle)
	draw_texture_rect(petal_texture,Rect2(Vector2(0,-width),Vector2(length_px,width*2.0)),false,tint)
	draw_set_transform(Vector2.ZERO)

func _storybook_mushroom(foot: Vector2, radius: float, height_px: float, tint: Color, phase: float) -> void:
	var sway := sin(elapsed*1.2+phase)*radius*0.035 if not quieter_motion else 0.0
	var cap := foot+Vector2(sway,-height_px-(absf(sin(elapsed*5+phase))*minf(1,ambience.response)*4 if not quieter_motion and level_index==1 else 0.0))
	draw_line(foot,cap,Color("#ad93b1"),maxf(2.0,radius*0.28),true)
	draw_line(foot-Vector2(radius*0.07,0),cap-Vector2(radius*0.07,0),Color("#e3ced5"),maxf(1.0,radius*0.10),true)
	var shape := PackedVector2Array()
	var shades := PackedColorArray()
	for i in range(17):
		var angle := PI+float(i)*PI/16.0
		shape.append(cap+Vector2(cos(angle)*radius,sin(angle)*radius*0.72))
		shades.append(tint.lightened(0.23) if i<9 else tint.darkened(0.15))
	draw_polygon(shape,shades)
	draw_set_transform(cap,0,Vector2(1,0.23))
	_disc(Vector2.ZERO,radius,tint.darkened(0.30))
	draw_set_transform(Vector2.ZERO)
	draw_line(cap-Vector2(radius,0),cap+Vector2(radius,0),tint.lightened(0.26),1.5,true)
	for i in range(3):
		_disc(cap+Vector2((float(i)-1.0)*radius*0.48,-radius*(0.24 if i%2 else 0.38)),radius*0.09,Color("#f4e4c6"))
	_draw_halo(cap,radius*2.2,tint,0.55)

func _storybook_fern(at: Vector2, phase: float) -> void:
	var sway := sin(elapsed*0.9+phase)*2.0 if not quieter_motion else 0.0
	for branch in [-1.0,1.0]:
		var tip := at+Vector2(branch*18+sway,-25)
		draw_line(at,tip,Color("#648978"),1.1,true)
		for i in range(1,5):
			var center := at.lerp(tip,float(i)/5.0)
			var length_px := 10.0-float(i)
			_storybook_petal(center,-0.6 if branch>0 else PI+0.6,length_px,2.3,Color("#83aa8e"))
			_storybook_petal(center,0.5 if branch>0 else PI-0.5,length_px*0.8,2.0,Color("#547d6c"))

func _focus_points() -> Array[Vector2]:
	var points: Array[Vector2] = [player]
	if level_index==1 and player.distance_to(pathways.web_position())<6: points.append(pathways.web_position())
	if level_index==0 and player.distance_to(_key_location())<7: points.append(_key_location())
	for m in marks:
		if player.distance_to(m.pos)<6 and (not m.lit or level_index==4): points.append(m.pos)
	for npc in npcs:
		if player.distance_to(npc.pos)<4: points.append(npc.pos)
	for loop in exploration.loops:
		if player.distance_to(loop.pos)<6: points.append(loop.pos)
	for prop in objects.items:
		if player.distance_to(prop.pos)<5: points.append(prop.pos)
	for chest in beauty.chests:
		if player.distance_to(chest.pos)<6: points.append(chest.pos)
	for clue in living.clues:
		if player.distance_to(clue.pos)<5: points.append(clue.pos)
	if not living.visitor.is_empty() and player.distance_to(living.visitor.pos)<5: points.append(living.visitor.pos)
	if player.distance_to(_station())<6: points.append(_station())
	return points
