extends "res://scripts/core.gd"

const ADVENTURE_ART = preload("res://scripts/adventure_art.gd")
const PATHWAY_ART = preload("res://scripts/pathway_art.gd")

# --- Art renderer: native CanvasItem / Godot Texture2D drawing ---
func _draw() -> void:
	if tex.is_empty(): return
	if state == "menu" or state == "comic":
		_cover("forest")
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
	_moon_haze()
	ADVENTURE_ART.signs(self)
	var entities: Array = []
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
		if _visible(_project(m.pos),tile*3): entities.append({"depth":m.pos.x+m.pos.y,"type":"item","data":m})
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
	entities.append({"depth":exit_pos.x+exit_pos.y,"type":"exit","data":{}})
	entities.append({"depth":player.x+player.y,"type":"ara","data":{}})
	entities.sort_custom(func(a,b): return a.depth < b.depth)
	for entity in entities:
		var d: Dictionary = entity.data
		match entity.type:
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
	if has_destination:
		var at := _project(destination)
		draw_arc(at,12,0,TAU,24,Color(1,0.89,0.65,0.7),2)
		for i in range(route_index, route.size()):
			var waypoint := _project(route[i])
			if _visible(waypoint,10): _disc(waypoint,2.5,Color(1,0.89,0.65,0.35))
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
	var at := _project(t.pos)
	var h: float = tile*3.9*float(t["size"])
	var crop: Array = TREE_RECTS[level_index*3 + int(t.variant)]
	var w: float = minf(tile*2.25,h*float(crop[2])/float(crop[3]))
	_shadow(at,30*t["size"])
	var relative := at-_project(player)
	var overlap := (1.0-smoothstep(tile*0.65,tile*1.3,absf(relative.x)))*smoothstep(0.0,18.0,relative.y)*(1.0-smoothstep(h*0.55,h*0.78,relative.y))
	for target in foliage_focus:
		var delta := at-_project(target)
		var cover := (1-smoothstep(tile*.55,tile*1.5,absf(delta.x)))*smoothstep(0,16,delta.y)*(1-smoothstep(h*.65,h*.95,delta.y))
		overlap=maxf(overlap,cover)
	var alpha := lerpf(1.0,0.12,overlap)
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
	var at := _project(n.pos)
	var phase: float = elapsed+float(n.home.x)*0.13
	var motion := 0.0 if quieter_motion else 1.0
	var greeting: float = minf(1.0,float(n.greeting))*motion
	var joy: float = minf(1.0,float(n.reaction))*motion
	var breath := sin(phase*2.0)*1.2*motion
	var head_tilt := (sin(phase*1.3)*0.025+sin(phase*7.0)*greeting*0.055)*motion
	var hop := absf(sin(phase*7.0))*joy*5.0
	_shadow(at,25)
	match n.id:
		"pip":
			_npc_part(n,2,Vector2(-24,-49-breath-hop),Vector2(39,31),sin(phase*6.0)*greeting*0.6,Vector2(0.8,0.18))
			_npc_part(n,1,Vector2(0,-35-breath-hop),Vector2(62,60))
			_npc_part(n,4,Vector2(19,-55-breath-hop),Vector2(25,30),sin(phase*2.5)*0.10*motion,Vector2(0.35,0.1))
			_npc_part(n,3,Vector2(23,-48-breath-hop),Vector2(34,41),sin(phase*2.1)*0.07*motion-greeting*0.25,Vector2(0.18,0.12))
			_npc_part(n,0,Vector2(0,-80-breath-hop),Vector2(69,56),head_tilt)
			_draw_halo(at+Vector2(33*float(n.facing),-56-hop),35,Color("#ffe0a0"),1.0)
		"bramble":
			_npc_part(n,9,Vector2(0,-38-hop),Vector2(58,60),sin(phase*1.3)*0.025*motion)
			_npc_part(n,6,Vector2(0,-32-breath-hop),Vector2(63,51))
			_npc_part(n,7,Vector2(-20,-40-hop),Vector2(49,37),sin(phase*1.5)*0.035*motion,Vector2(0.28,0.2))
			var scribble := sin(phase*10.0)*0.10*motion if greeting<0.1 else sin(phase*7.0)*greeting*0.5
			_npc_part(n,8,Vector2(23,-41-hop),Vector2(31,35),scribble,Vector2(0.24,0.15))
			_npc_part(n,5,Vector2(0,-75-breath-hop),Vector2(65,53),head_tilt)
		"moss":
			_npc_part(n,14,Vector2(22,-28-hop),Vector2(47,48),sin(phase*2.4)*0.12*motion,Vector2(0.35,0.8))
			_npc_part(n,11,Vector2(0,-33-breath-hop),Vector2(65,56))
			_npc_part(n,13,Vector2(-20,-48-hop),Vector2(29,31),sin(phase*2.0)*0.045*motion,Vector2(0.75,0.12))
			_npc_part(n,12,Vector2(21,-48-hop),Vector2(40,31),-greeting*0.25+sin(phase*3.0)*0.04*motion,Vector2(0.14,0.2))
			_npc_part(n,10,Vector2(0,-82-breath-hop),Vector2(66,60),head_tilt)

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
	var at := _project(b.pos)
	var h: float = tile*0.85
	var w: float = tile*1.1
	var floaty := 12.0 + (sin(elapsed*4+b.phase)*8.0 if not quieter_motion else 0.0)
	var flap := sin(elapsed*10.0+b.phase)*0.07 if not quieter_motion else 0.0
	w *= 1.0+flap
	h *= 1.0-flap*0.5
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
		if quest_done:
			var breath := sin(elapsed*1.8)*0.012 if not quieter_motion else 0.0
			var ira_at := at+Vector2(lerpf(45,39,personality.reunion),5)
			_shadow(ira_at,22)
			draw_set_transform(ira_at,0,Vector2(1.0-breath,1.0+breath))
			_draw_png("ira",Vector2.ZERO,65,82)
			draw_set_transform(Vector2.ZERO)
	else:
		_draw_crop("lamps-v2",LAMP_RECTS[level_index*2],Rect2(at-Vector2(100,152),Vector2(75,152)))
		_draw_crop("lamps-v2",LAMP_RECTS[level_index*2],Rect2(at+Vector2(28,-152),Vector2(75,152)))

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
	var at := _project(player)
	_shadow(at,25)
	var gait := sin(foot_time) * minf(1.0,walk_dir.length()) if not quieter_motion else 0.0
	var bounce := absf(sin(foot_time)) * minf(1.0,walk_dir.length()) * 3.2 if not quieter_motion else 0.0
	var breath := sin(elapsed*2.0)*0.65 if not quieter_motion else 0.0
	var base := _ara_root()
	_rig_part(4,base+Vector2(-12,-9+gait*2),Vector2(18,14),-gait*0.15)
	_rig_part(5,base+Vector2(12,-9-gait*2),Vector2(18,14),gait*0.15)
	_rig_part(2,base+Vector2(-14,-52-breath),Vector2(18,34),gait*0.16+personality.arm(0),Vector2(0.42,0.10))
	_rig_part(1,base+Vector2(0,-35-breath),Vector2(45,44),0.0)
	var lift := sin((1-pulse/GLOW_TIME)*PI) if pulse > 0 else 0.0
	_rig_part(3,base+Vector2(14,-51-breath),Vector2(35,49),-lift*0.42+gait*0.04+personality.arm(1),Vector2(0.16,0.10))
	_rig_part(0,base+Vector2(0,-52-breath),Vector2(70,59),(sin(elapsed*1.4)*0.018 if not quieter_motion else 0.0),Vector2(0.5,0.95))
	_draw_halo(_lantern_tip(),62,COLORS[level_index],2.0)


func _ara_root() -> Vector2:
	var motion: float = minf(1.0,walk_dir.length())
	var bounce: float = absf(sin(foot_time))*motion*3.2 if not quieter_motion else 0.0
	var at := _project(player)-Vector2(0,bounce+personality.hop())+Vector2(0,personality.dip())
	if state=="win" and level_index==4: at=at.lerp(_project(_exit())+Vector2(18,4),personality.reunion)
	return at

func _lantern_tip() -> Vector2:
	var lift: float = sin((1.0-pulse/GLOW_TIME)*PI) if pulse > 0 else 0.0
	var breath: float = sin(elapsed*2.0)*0.65 if not quieter_motion else 0.0
	var gait: float = sin(foot_time)*minf(1.0,walk_dir.length()) if not quieter_motion else 0.0
	var arm_spin: float = -lift*0.42+gait*0.04+personality.arm(1)
	var tip := Vector2(14,-51-breath) + Vector2(19,32).rotated(arm_spin)
	return _ara_frame(tip)

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
				_world_oval(center,Vector2(3.7,3.7),Color(0.43,0.30,0.57,0.20))
				for i in range(18):
					var p := center+Vector2(3.6,0).rotated(float(i)*TAU/18.0)
					var at := _project(p)
					_storybook_mushroom(at,8.0,17.0,Color("#b191d4"),float(i))
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
				_world_oval(center,Vector2(8,8),Color(0.28,0.29,0.46,0.26))
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
					_world_oval(p,Vector2(1.3,1.3),Color(0.33,0.25,0.29,0.55))
					_draw_crop("quests-23",QUEST_RECTS[6],Rect2(_project(p)-Vector2(23,55),Vector2(46,55)))
					for i in range(9):
						var at := _project(p+Vector2(0.9,0).rotated(float(i)*TAU/9.0))
						_woodland_flower(at-Vector2(0,10),Color("#d8a8c5"),8.0)

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
	if state!="play" or (conversation!=null and conversation.notice_left>0): return
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
	_shadow(at,24)
	var top := at-Vector2(0,35)
	draw_colored_polygon(PackedVector2Array([at+Vector2(-20,-3),at+Vector2(-17,-28),top,at+Vector2(17,-28),at+Vector2(21,-3),at+Vector2(0,6)]),Color("#4d6171"))
	draw_colored_polygon(PackedVector2Array([at+Vector2(-17,-28),top,at+Vector2(17,-28),at+Vector2(0,-19)]),Color("#899fa3"))
	draw_line(at-Vector2(0,18),at-Vector2(0,3),Color("#e9c990"),2,true)
	draw_arc(at-Vector2(0,12),6,-PI*0.8,PI*0.2,16,Color("#e9c990"),2,true)
	if stone.time > 0: _draw_halo(top,50,Color("#ffe5a3"),1.5)

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
	var sway := sin(elapsed*1.2+float(prop.phase))*3.0 if not quieter_motion else 0.0
	_shadow(at,29)
	match prop.kind:
		"ribbon":
			for side in [-1.0,1.0]:
				draw_line(at+Vector2(side*34,0),at+Vector2(side*28,-86),Color("#73665a"),5,true)
			draw_arc(at+Vector2(0,-91),31,0,PI,20,Color("#bda984"),3,true)
			for i in range(5):
				var tip := at+Vector2(-26+i*13,-82+sway*float(i%2))
				draw_colored_polygon(PackedVector2Array([tip,tip+Vector2(8,1),tip+Vector2(4,17)]),Color("#dbb887") if i%2 else Color("#88b8bb"))
		"mushroom":
			for i in range(3):
				var foot := at+Vector2((i-1)*22,abs(i-1)*6)
				var h := 35.0+float(i%2)*18.0
				_storybook_mushroom(foot,19.0 if i==1 else 14.0,h,Color("#a58bc1"),float(prop.phase)+i)
		"lily":
			for i in range(3):
				var pad := at+Vector2((i-1)*24,i%2*12)
				draw_set_transform(pad,0,Vector2(1,0.45))
				_disc(Vector2.ZERO,19,Color("#548e88"))
				draw_arc(Vector2.ZERO,19,0.2,TAU-0.4,20,Color("#86b3a0"),2,true)
				draw_set_transform(Vector2.ZERO)
				if i==1: _woodland_flower(pad-Vector2(0,7+sway*0.3),Color("#ebcbdd"),8)
		"orrery":
			var center := at-Vector2(0,53+sway)
			draw_line(at,center+Vector2(0,15),Color("#9a91a8"),5,true)
			draw_arc(center,30,0,TAU,32,Color("#bbab83"),2,true)
			draw_set_transform(center,-0.6,Vector2(1,0.45))
			draw_arc(Vector2.ZERO,39,0,TAU,32,Color("#b4bce5"),2,true)
			draw_set_transform(Vector2.ZERO)
			_draw_halo(center,47,Color("#b4bce5"),1.6)
			for i in range(3):
				var angle := float(i)*TAU/3.0+(elapsed*0.4 if not quieter_motion else 0.0)
				_disc(center+Vector2(30,0).rotated(angle),4,Color("#fff0bb"))
		"garden_arch":
			for side in [-1.0,1.0]: draw_line(at+Vector2(side*34,0),at+Vector2(side*34,-69),Color("#7b9c86"),5,true)
			draw_arc(at-Vector2(0,69),34,PI,TAU,24,Color("#7b9c86"),5,true)
			for i in range(7):
				var angle := PI+float(i)*PI/6.0
				_woodland_flower(at-Vector2(0,69)+Vector2(34,0).rotated(angle),Color("#e4b8c9") if i%2 else Color("#b8d5bc"),6)

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
	if player.distance_to(_station())<6: points.append(_station())
	return points
