extends RefCounted
## Full-body painted poses share the same crops in the world, portraits and menus.
const CHAPTERS = ["woods", "glade", "brook", "hollow", "garden"]
const CAST = ["ara", "ira", "pip", "bramble", "moss", "friends"]
const ACCENTS = [Color("#d9b971"), Color("#b7a1da"), Color("#91c6bf"), Color("#b2bbe5"), Color("#dfb0bf")]
var characters: Dictionary = {}
var settings: Dictionary = {}
var regions: Dictionary = {}
var portraits: Dictionary = {}
var loaded_chapter := -1
var stories: Dictionary = {}
const STORY_PAGES = {
	"comic-1":["beginning",0], "comic-2":["beginning",1], "comic-3":["beginning",2],
	"interlude-1-1":["journey",0], "interlude-1-2":["journey",1],
	"interlude-2-1":["journey",2], "interlude-2-2":["journey",3],
	"interlude-3-1":["homeward",0], "interlude-3-2":["homeward",1],
	"interlude-4-1":["homeward",2], "interlude-4-2":["homeward",3],
}

func load_assets() -> void:
	regions = JSON.parse_string(FileAccess.get_file_as_string("res://assets/keepsake/regions.json"))
	for name in CAST:
		characters[name] = load("res://assets/keepsake/characters/%s.png" % name)
	for name in ["beginning","journey","homeward"]:
		stories[name]=load("res://assets/keepsake/story-%s.png"%name)

func install_story(textures: Dictionary) -> void:
	for name in STORY_PAGES:
		var data: Array=STORY_PAGES[name]
		var texture: Texture2D=stories[data[0]]
		var wh: Vector2=texture.get_size()*.5
		var frame: int=data[1]
		var page := AtlasTexture.new()
		page.atlas=texture
		page.region=Rect2(Vector2((frame%2)*wh.x,(frame/2)*wh.y)+Vector2.ONE,wh-Vector2.ONE*2)
		page.filter_clip=true
		textures[name]=page

func ensure_chapter(chapter: int) -> void:
	if loaded_chapter == chapter: return
	settings.clear()
	settings["atlas"] = load("res://assets/keepsake/settings/%s.png" % CHAPTERS[chapter])
	loaded_chapter = chapter

func crop(group: String, name: String, index: int) -> Rect2:
	var r: Array = regions[group][name][index]
	return Rect2(r[0], r[1], r[2], r[3])

func portrait(name: String, frame: int = 0) -> AtlasTexture:
	var key := "%s-%d" % [name, frame]
	if not portraits.has(key):
		var atlas := AtlasTexture.new()
		atlas.atlas = characters[name]
		atlas.region = crop("characters", name, frame)
		atlas.filter_clip = true
		portraits[key] = atlas
	return portraits[key]

func sprite(canvas: CanvasItem, texture: Texture2D, source: Rect2, foot: Vector2, height: float, alpha: float = 1.0) -> void:
	var wh := Vector2(height * source.size.x / source.size.y, height)
	canvas.draw_texture_rect_region(texture, Rect2(foot - Vector2(wh.x * .5, wh.y), wh), source, Color(1, 1, 1, alpha))

func character(canvas: CanvasItem, name: String, frame: int, foot: Vector2, height: float, facing: float = 1.0, tilt: float = 0.0) -> void:
	canvas.draw_set_transform(foot, tilt, Vector2(facing, 1))
	sprite(canvas, characters[name], crop("characters", name, frame), Vector2.ZERO, height)
	canvas.draw_set_transform(Vector2.ZERO)

func ara_frame(g: Control) -> int:
	if g.quieter_motion: return 0
	if g.pulse > 0 or (g.personality.action_time > 0 and g.personality.action in ["celebrate", "reunion"]): return 3
	if g.walk_dir.length() > .05: return 1 if sin(g.foot_time) >= 0 else 2
	return 0

func ara(g: Control) -> void:
	var at: Vector2 = g._ara_root()
	var breath: float = 0 if g.quieter_motion else sin(g.elapsed * 1.8) * .7
	g._shadow(g._project(g.player), 25)
	var tilt: float = 0 if g.quieter_motion else g.body_lean * .45 + g.personality.lean() * .5
	character(g, "ara", ara_frame(g), at - Vector2(0, breath), 126, g.facing, tilt)
	g._draw_halo(ara_lantern(g), 57, g.COLORS[g.level_index], 1.7)

func ara_lantern(g: Control) -> Vector2:
	# The new complete poses keep the lamp in the painted paw, including its lift.
	var offset := Vector2(-34, -27) if ara_frame(g) != 3 else Vector2(46, -70)
	offset.x *= g.facing
	var breath: float = 0 if g.quieter_motion else sin(g.elapsed * 1.8) * .7
	var tilt: float = 0 if g.quieter_motion else g.body_lean * .45 + g.personality.lean() * .5
	return g._ara_root() - Vector2(0, breath) + offset.rotated(tilt)

func npc(g: Control, data: Dictionary) -> void:
	var at: Vector2 = g._project(data.pos)
	var still: bool = g.quieter_motion
	var frame := 0
	if not still:
		if data.reaction > .2: frame = 3
		elif data.greeting > .15: frame = 1
		elif data.get("work", 0.0) > .2: frame = 2
		at.y -= sin(g.elapsed * 1.7 + data.home.x) * .8 + absf(sin(g.elapsed * 4)) * data.get("stride", 0.0) * 2
	g.LIVING_ART.npc_props(g, data)
	g._shadow(g._project(data.pos), 25)
	character(g, data.id, frame, at, 130 if data.id == "moss" else 121, data.facing)
	if data.id == "pip": g._draw_halo(at + Vector2(31 * data.facing, -44), 30, Color("#ffdfa0"), .6)

func scenery(g: Control, index: int, at: Vector2, height: float, alpha: float = 1.0, spin: float = 0.0) -> void:
	g.draw_set_transform(at, spin)
	sprite(g, settings.atlas, crop("settings", CHAPTERS[g.level_index], index), Vector2.ZERO, height, alpha)
	g.draw_set_transform(Vector2.ZERO)

func tree(g: Control, data: Dictionary) -> void:
	var at: Vector2 = g._project(data.pos)
	var height: float = g.tile * (3.55 if int(data.variant)>=2 else 3.3) * float(data["size"])
	var source := crop("settings", CHAPTERS[g.level_index], int(data.variant) % 2)
	var width: float = height * source.size.x / source.size.y
	if int(data.variant)>=2:
		var texture: Texture2D=g.botany.textures[int(data.variant)-2]
		width=height*texture.get_width()/texture.get_height()
	var overlap := 0.0
	for target in g.foliage_focus:
		var delta: Vector2 = at - g._project(target)
		var cover: float = (1 - smoothstep(maxf(38, width * .28), maxf(85, width * .6), absf(delta.x))) * smoothstep(0, 14, delta.y) * (1 - smoothstep(height * .6, height * .96, delta.y))
		overlap = maxf(overlap, cover)
	var alpha := lerpf(1.0, .065, overlap)
	var sway: float = 0 if g.quieter_motion else sin(g.elapsed * .65 + data.pos.x) * .009
	g._shadow(at, 28 * float(data["size"]))
	if int(data.variant)>=2:
		g.botany.draw_sprite(g,int(data.variant)-2,at,height,alpha,sway)
	else:
		scenery(g, int(data.variant) % 2, at, height, alpha, sway)

func lamp(g: Control, data: Dictionary) -> void:
	var at: Vector2 = g._project(data.pos)
	var height: float = g.tile * (2.45 if int(data.variant) == 0 else 1.85)
	scenery(g, 4, at, height)
	var tint: Color = Color("#bce9f3") if data.get("blue", false) else g.COLORS[g.level_index]
	g._draw_halo(at - Vector2(0, height * .72), 45, tint, 1.25)

func gate(g: Control, at: Vector2) -> void:
	var height: float = 238 if g.level_index == 4 else 180
	# The cottage sits behind its front garden, where the sisters reunite.
	var building_foot: Vector2=at-Vector2(0,90) if g.level_index==4 else at
	g._shadow(building_foot, 65)
	scenery(g, 5, building_foot, height)
	if g.level_index == 4 and g.quest_done:
		var breath: float = 0 if g.quieter_motion else sin(g.elapsed * 1.8) * .7
		var ira_at: Vector2 = at + Vector2(lerpf(48, 37, g.personality.reunion), 4 - breath)
		g._shadow(ira_at, 24)
		character(g, "ira", 2 if g.state == "win" else 0, ira_at, 91)

func visitor(g: Control) -> void:
	var data: Dictionary = g.living.visitor
	if data.is_empty(): return
	var at: Vector2 = g._project(data.pos)
	var frame: int = 1 if g.level_index in [0, 4] else 2 if g.level_index == 2 else 3
	var clock: float = 0 if g.quieter_motion else g.living.clock
	var height: float = 44 if frame == 1 else 32
	if frame == 3: at.y -= 21 + sin(clock * 1.5) * 3
	elif frame == 2: at.y -= maxf(0, sin(clock * 2)) * data.attention * 4
	g._shadow(g._project(data.pos), 13)
	character(g, "friends", frame, at, height)

func bat(g: Control, data: Dictionary) -> void:
	var at: Vector2 = g._project(data.pos)
	var clock: float = 0 if g.quieter_motion else g.elapsed
	at.y -= 18 + sin(clock * 4 + data.phase) * (0 if g.quieter_motion else 6)
	g.draw_set_transform(at, 0, Vector2(1, 1 + sin(clock * 9 + data.phase) * (.0 if g.quieter_motion else .06)))
	sprite(g, characters.friends, crop("characters", "friends", 0), Vector2.ZERO, 45)
	g.draw_set_transform(Vector2.ZERO)
