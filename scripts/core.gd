extends Control
## Godot 4 native reimplementation of the v2.4 browser game.
## Source reference: game.js and story-24.json; never evaluates JavaScript or embeds a webview.

const SPEED := 3.15
const ACCELERATION := 20.0
const DECELERATION := 28.0
const INTERACT_RADIUS := 2.4
const GLOW_TIME := 1.05
const GLOW_RECHARGE := 1.15
const BASE_LEVELS = [
	{"title":"The Whispering Woods", "size":65, "background":"forest", "kind":"key", "decor":7, "trees":0.48, "bats":2},
	{"title":"Glowcap Glade", "size":73, "background":"level-2", "kind":"scroll", "decor":0, "trees":0.57, "bats":2},
	{"title":"Puddlebrook Crossing", "size":77, "background":"level-3", "kind":"wood", "decor":1, "trees":0.58, "bats":2},
	{"title":"Stargazer Hollow", "size":81, "background":"level-4", "kind":"stars", "decor":6, "trees":0.56, "bats":3},
	{"title":"Pillowmoon Garden", "size":85, "background":"level-5", "kind":"flowers", "decor":4, "trees":0.58, "bats":1}
]
const QUEST_TITLES = ["The Lost Woodland Key", "The Torn Moon Scroll", "The Wobbly Brook Bridge", "The Sleepy Constellation", "Ira's Moonflower Lullaby"]
const QUEST_HINTS = [
	"Meet Pip, Bramble and Moss. Moss knows of three pale birches near the blue-lantern trail. Glow to reveal a lost brass key.",
	"Talk to Pip. Glow beside three purple nests, collect their moon-scroll pages, then rebuild the scroll at the lectern.",
	"Talk to Bramble. Pick up three bundles of driftwood. Repair the bridge near the far end of the brook.",
	"Talk to Moss. Collect three star crystals, then glow at the stones in order: Moon, Star, Heart.",
	"Talk to Pip. Wake three moonflowers with your lantern and play the lullaby at the cottage music box."
]
const INTRO = [
	{"title":"The suspiciously giggly cushion.", "caption":"One last game before bedtime.", "text":"Ira was very good at being a pillow. Being a quiet pillow? A little trickier.", "bubble":"Ready or not, here I come!", "scene":"comic-1"},
	{"title":"One sister, suddenly missing.", "caption":"Then the giggling stopped.", "text":"No Ira. Just an open window, a fluttering ribbon… and a very unhelpful teacup.", "bubble":"Oh no! Ira's missing!", "scene":"comic-2"},
	{"title":"Brave. Mostly brave. Brave-ish.", "caption":"A little light. A big deep breath.", "text":"Ara followed the ribbon into the woods. Finding her sister mattered more than a few spooky shadows.", "bubble":"Hold on, Ira. I'm coming!", "scene":"comic-3"}
]
const TREE_RECTS = [
	[15,13,310,313],[336,5,314,320],[650,4,311,321], [35,330,260,297],[335,329,302,301],[666,331,281,300],
	[15,634,299,301],[325,632,325,302],[669,633,287,302], [13,935,311,333],[338,936,297,329],[671,935,277,335],
	[13,1275,312,323],[325,1272,322,325],[660,1275,294,322]
]
const LAMP_RECTS = [[175,4,112,393],[493,65,170,331],[161,397,133,396],[484,467,197,311],[166,793,124,397],[482,833,190,343],[155,1190,141,396],[475,1236,207,331],[155,1586,143,384],[484,1616,197,350]]
const GROUND_RECTS = [[2,2,276,272],[282,2,278,272],[564,2,277,272],[845,2,275,272],[2,278,276,273],[282,278,278,273],[564,278,277,273],[845,278,275,273],[2,555,276,273],[282,555,278,273],[564,555,277,273],[845,555,275,273],[2,832,276,271],[282,832,278,271],[564,832,277,271],[845,832,275,271],[2,1107,276,293],[282,1107,278,293],[564,1107,277,293],[845,1107,275,293]]
const DECOR_RECTS = [[0,0,385,512],[384,125,405,375],[790,175,435,345],[1230,35,305,480],[0,550,390,474],[385,540,460,450],[870,540,270,470],[1190,560,346,440]]
const QUEST_RECTS = [[91,79,329,354],[564,56,407,400],[1099,69,361,373],[40,587,432,362],[625,551,286,433],[1118,568,323,400],[75,1065,361,429],[582,1078,372,404],[1127,1079,306,401]]
const RIG_RECTS = [[0,32,588,451],[628,106,458,392],[1209,92,239,390],[125,515,330,465],[626,660,314,276],[1165,659,314,274]]
const COLORS = [Color("#ffdca3"), Color("#ffe4bd"), Color("#ffe5b3"), Color("#e8ddff"), Color("#ffd297")]

var beauty: RefCounted = preload("res://scripts/hidden_wonders.gd").new()
var living: RefCounted = preload("res://scripts/living_woodland.gd").new()
var sound_enabled := true
var restoring := false
var journal: RefCounted = preload("res://scripts/adventure_journal.gd").new()
var personality: RefCounted = preload("res://scripts/personality.gd").new()
var exploration: RefCounted = preload("res://scripts/exploration.gd").new()
var soundscape: Node
var save_clock := 0.0
var nav_column := 0
var nav_row := -1
var nav_high := 0
var navigation_ready := false
var pending_destination := false
var nav_build_us := 0
var nav_slice_us := 0
var nav_work_us := 0
var pathways: RefCounted = preload("res://scripts/pathways.gd").new()
var ui_canvas: CanvasLayer
var atmosphere: Node2D
var light_trails: RefCounted
var ground_layer: ColorRect
var graphics_quality := 1
var relief_material: ShaderMaterial
var tree_render_chunks: Dictionary = {}
var foliage_focus: Array[Vector2] = []
var visible_trees: Array = []
var visibility_camera := Vector2(INF,INF)
var visibility_size := Vector2.ZERO
var render_cpu_us := 0
var ambience: RefCounted
var celebration := 0.0
var foot_dust := 0.0

var tex: Dictionary = {}
var chapter_stories: Array = []
var level_index := 0
var state := "menu"
var story_chapter := -1
var story_page := 0
var player := Vector2(2, 3)
var destination := Vector2.ZERO
var has_destination := false
var walk_dir := Vector2.ZERO
var velocity := Vector2.ZERO
var camera_lead := Vector2.ZERO
var body_lean := 0.0
var navigation: AStarGrid2D
var route := PackedVector2Array()
var route_index := 0
var stuck_time := 0.0
var held_directions: Dictionary = {}
var landmarks: Array = []
var glow_buffer := 0.0
var facing := 1.0
var foot_time := 0.0
var elapsed := 0.0
var cooldown := 0.0
var pulse := 0.0
var heart := 3
var invulnerable := 0.0
var quest_count := 0
var quest_done := false
var quest_started := false
var key_revealed := false
var key_collected := false
var rune_step := 0
var runes: Array = []
var marks: Array = []
var trees: Array = []
var tree_cells: Dictionary = {}
var lanterns: Array = []
var decorations: Array = []
var npcs: Array = []
var bats: Array = []
var particles: Array = []
var toast_seconds := 0.0
var completed := false
var tile := 58.0
var camera := Vector2.ZERO
var quieter_motion := false
var music_enabled := true
var mobile_axis := Vector2.ZERO
var dialog_from := "play"
var conversation: Control
var menu_layer: Control
var story_layer: Control
var hud_layer: Control
var modal_layer: Control
var hud_chapter: Label
var hud_title: Label
var hud_objective: Label
var hud_hearts: Label
var hud_glow: Label
var hud_discoveries: Label
var toast_label: Label
var action_button: Button
var glow_button: Button
var story_title: Label
var story_caption: Label
var story_body: Label
var story_bubble: Label
var story_image: TextureRect
var story_back: Button
var story_next: Button
var modal_heading: Label
var modal_text: Label
var modal_primary: Button
var modal_secondary: Button
var continue_button: Button
var options_sound: CheckButton
var joystick: Control
var options_music: CheckButton
var options_motion: CheckButton
var options_quality: OptionButton
var menu_audio: AudioStreamPlayer
var game_audio: AudioStreamPlayer

# Virtual UI hooks are overridden by scripts/main.gd. Declaring them in the base
# lets Godot statically resolve callbacks from the gameplay layer.
func _layout_ui() -> void:
	pass

func _story_advance() -> void:
	pass

func _build_ui() -> void:
	pass

func _talk(_npc: Dictionary) -> void:
	pass

func _reunion() -> void:
	pass

func _show_dialog(_title: String, _body: String, _primary: String, _secondary: String, _action: String) -> void:
	pass

func _show_story() -> void:
	pass

func _pause() -> void:
	pass

func _resume() -> void:
	pass

func _ready() -> void:
	journal.attach(self)
	personality.game=self
	living.game=self
	beauty.game=self
	pathways.game=self
	exploration.game=self
	mouse_filter = Control.MOUSE_FILTER_PASS
	for name in ["forest","ground-v2","trees-v2","lamps-v2","decor","atlas","ara-rig-22","ara","ira","npc-rig-22","key-birches","woodland-key","woodland-door","quests-23","comic-1","comic-2","comic-3","interlude-1-1","interlude-1-2","interlude-2-1","interlude-2-2","interlude-3-1","interlude-3-2","interlude-4-1","interlude-4-2"]:
		tex[name] = load("res://assets/%s.png" % name)
	var file := FileAccess.open("res://story-24.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Array:
			chapter_stories = parsed
	soundscape=preload("res://scripts/soundscape.gd").new()
	soundscape.game=self
	add_child(soundscape)
	ui_canvas = CanvasLayer.new()
	ui_canvas.layer = 10
	add_child(ui_canvas)
	_build_ui()
	light_trails = load("res://scripts/lantern_trails.gd").new()
	atmosphere = load("res://scripts/atmosphere.gd").new()
	atmosphere.game = self
	add_child(atmosphere)
	relief_material = ShaderMaterial.new()
	relief_material.shader = load("res://shaders/stitched_surface.gdshader")
	ambience = load("res://scripts/woodland_flourishes.gd").new()
	ambience.game=self
	ground_layer = load("res://scripts/woodland_ground.gd").new()
	ground_layer.game = self
	add_child(ground_layer)
	set_graphics_quality(graphics_quality)
	menu_audio = _music("menu-music")
	game_audio = _music("gameplay-music")
	_set_state("menu")
	resized.connect(queue_redraw)
	resized.connect(_layout_ui)
	_layout_ui()

func _music(filename: String) -> AudioStreamPlayer:
	var a := AudioStreamPlayer.new()
	a.name = filename
	a.bus = "Master"
	a.volume_db = -9.0
	var stream = load("res://assets/%s.mp3" % filename)
	if stream is AudioStreamMP3:
		stream.loop = true
		a.stream = stream
	add_child(a)
	return a

func _set_state(next_state: String) -> void:
	if conversation!=null and next_state not in ["dialog","win"]: conversation.dismiss()
	if next_state != "play": _reset_controls()
	state = next_state
	menu_layer.visible = state == "menu"
	if continue_button!=null:
		continue_button.visible=journal.has_checkpoint()
		if continue_button.visible: continue_button.text="CONTINUE · CHAPTER %d" % (int(journal.data.checkpoint.chapter)+1)
	story_layer.visible = state == "comic"
	hud_layer.visible = state == "play"
	modal_layer.visible = state == "dialog" or state == "win"
	if music_enabled:
		if state == "menu" or (state == "comic" and story_chapter == -1):
			if game_audio.playing: game_audio.stream_paused = true
			if menu_audio.playing: menu_audio.stream_paused = false
			elif menu_audio.stream: menu_audio.play()
		else:
			if menu_audio.playing: menu_audio.stream_paused = true
			if game_audio.playing: game_audio.stream_paused = false
			elif game_audio.stream: game_audio.play()
	queue_redraw()

func _curve(x: float) -> float:
	return pathways.y(x)-x

func _clearing_radius(x: float) -> float:
	return 8.0 if (level_index==3 and x>58) or (level_index==4 and x>69) else 6.0

func _build_landmarks() -> void:
	landmarks.clear()
	var names: Array = [
		["Blue Lantern Turn", "The Pale Birch Grove", "Woodland Door"],
		["Violet Cap Clearing", "Silver Spore Circle", "Moon Scroll Lectern"],
		["Willowbank Bend", "Pebble Pools", "Bramble's Crossing"],
		["Falling Star Meadow", "The Open Hollow", "Constellation Circle"],
		["Ribbon Garden", "Moonflower Walk", "Ira's Cottage"]
	]
	var anchors: Array = [[24.0,29.0,62.0],[18.0,39.0,69.0],[20.0,43.0,68.0],[20.0,60.0,73.0],[20.0,52.0,80.0]][level_index]
	for i in range(3):
		var x: float = float(anchors[i])
		var side := 6.0 if level_index == 0 and i == 1 else -3.1 if i % 2 == 0 else 3.1
		landmarks.append({"pos":Vector2(x, _path_y(x)+side), "name":names[level_index][i], "index":i})

func _path_y(x: float) -> float:
	return x + _curve(x)

func _exit() -> Vector2:
	var x: float = float(BASE_LEVELS[level_index]["size"] - 3)
	return Vector2(x, _path_y(x))

func _randseed(n: float) -> float:
	var v: float = sin(n * 127.1 + 311.7) * 43758.5453
	return v - floor(v)

func _key_location() -> Vector2:
	return Vector2(29.85, _path_y(29.0) + 6.15)

func _key_clearing(p: Vector2) -> bool:
	if level_index != 0: return false
	var a := Vector2(24, _path_y(24))
	var b := Vector2(26, _path_y(26) + 3)
	var c := Vector2(29, _path_y(29) + 6)
	return _segment_distance(p, a, b) < 2.4 or _segment_distance(p, b, c) < 2.4 or p.distance_to(c) < 3.4

func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var delta := b - a
	var u: float = clampf((p - a).dot(delta) / maxf(0.001, delta.length_squared()), 0.0, 1.0)
	return p.distance_to(a + delta * u)

func _key_trail(p: Vector2) -> bool:
	if level_index != 0: return false
	var a := Vector2(24, _path_y(24))
	var b := Vector2(26, _path_y(26) + 3)
	var c := Vector2(29, _path_y(29) + 6)
	return _segment_distance(p, a, b) < 1.4 or _segment_distance(p, b, c) < 1.4 or p.distance_to(c) < 2.4

func start_level(index: int) -> void:
	level_index = clampi(index, 0, 4)
	pathways.build(self)
	exploration.build(self)
	personality.build(self)
	beauty.layout(self)
	player = Vector2(2, _path_y(2))
	tile = clampf(size.x / 20.0,38,58)
	camera = size * Vector2(0.5, 0.55) - Vector2((player.x-player.y)*tile,(player.x+player.y)*tile*0.49)
	_reset_controls()
	camera_lead = Vector2.ZERO
	body_lean = 0.0
	navigation = null
	_build_landmarks()
	has_destination = false
	mobile_axis = Vector2.ZERO
	cooldown = 0.0
	pulse = 0.0
	heart = 3
	invulnerable = 0.0
	quest_count = 0
	quest_done = false
	quest_started = false
	key_collected = false
	key_revealed = false
	completed = false
	rune_step = 0
	runes.clear()
	particles.clear()
	marks.clear()
	trees.clear()
	lanterns.clear()
	decorations.clear()
	npcs.clear()
	bats.clear()
	tree_cells.clear()
	tree_render_chunks.clear()
	visible_trees.clear()
	visibility_camera = Vector2(INF,INF)
	celebration = 0.0
	foot_dust = 0.0
	var level: Dictionary = BASE_LEVELS[level_index]
	var n: int = level["size"]
	var exit_pos := _exit()
	for x in range(n):
		for y in range(n):
			var p := Vector2(float(x) + 0.2 + _randseed(x + y * 36 + level_index) * 0.25, float(y) + 0.2 + _randseed(x * 7 + y + level_index) * 0.25)
			if exploration.open(p,3.0) or beauty.open_floor(p,3.0): continue
			if _randseed(x*71+y*83+level_index*129)<.42: continue
			if _key_clearing(p) or (level_index==1 and p.distance_to(pathways.web_position())<4.8): continue
			var d: float = pathways.distance(p)
			if d < _clearing_radius(p.x) or (d>_clearing_radius(p.x)+2.0 and _randseed(x * 29 + y + level_index * 71) <= float(level.trees)) or p.distance_to(exit_pos) < 2.5: continue
			if level_index == 4 and d>10.0 and (x % 3 == 1 or y % 3 == 1): continue
			var t := {"pos":p, "variant":int(floor(_randseed(x + y * 14 + level_index * 21) * 3.0)), "beauty":_randseed(x*39+y*87)>.60, "size":(0.78 + _randseed(x * 39 + y) * 0.45) * (1.18 if level_index == 0 else 0.88 if level_index == 3 else 1.0)}
			trees.append(t)
			var chunk := Vector2i(floori(p.x/8.0),floori(p.y/8.0))
			if not tree_render_chunks.has(chunk): tree_render_chunks[chunk] = []
			tree_render_chunks[chunk].append(t)
			var cell := Vector2i(int(floor(p.x)), int(floor(p.y)))
			if not tree_cells.has(cell): tree_cells[cell] = []
			tree_cells[cell].append(p)
	for x in range(3, n - 3, 3):
		var side := 1.0 if (int(x / 3) % 2) else -1.0
		lanterns.append({"pos":Vector2(x, _path_y(x) + side * 2.15), "variant":int(x / 3) % 2, "phase":_randseed(x * 3) * TAU})
		decorations.append({"pos":Vector2(x + 0.8, _path_y(x + 0.8) - side * 2.8), "variant":level.decor, "size":0.75})
	for i in range(int(level.bats)):
		var x := 8.0 + float(i) * float(n - 15) / maxf(1.0, float(level.bats - 1))
		bats.append({"pos":Vector2(x, _path_y(x) + 0.4), "home":Vector2(x, _path_y(x) + 0.4), "phase":float(i) * 2.0, "fear":0.0})
	if level_index == 0:
		for npc in [["pip","Pip",4.5,0.75],["bramble","Bramble",10.0,-0.65],["moss","Moss",17.0,0.75]]:
			npcs.append({"id":npc[0], "name":npc[1], "pos":Vector2(npc[2], _path_y(npc[2]) + npc[3]), "home":Vector2(npc[2], _path_y(npc[2]) + npc[3]), "met":false})
		lanterns.append({"pos":Vector2(24.2, _path_y(24) + 1.9), "variant":1, "blue":true, "phase":0.0})
	else:
		var guide_name: String = ["","Pip","Bramble","Moss","Pip"][level_index]
		var gid: String = guide_name.to_lower()
		npcs.append({"id":gid, "name":guide_name, "pos":Vector2(5, _path_y(5) + 0.65), "home":Vector2(5, _path_y(5) + 0.65), "met":false})
		for i in range(3):
			var x: float = 2.0 + float(n - 5) * [0.22, 0.48, 0.72][i]
			marks.append({"pos":Vector2(x, _path_y(x) + (2.35 if i % 2 else -2.35)), "lit":false, "revealed":level_index != 1, "index":i})
		if level_index == 3:
			for info in [["Star",-12,1],["Moon",-8,0],["Heart",-4,2]]:
				var rx: float = float(n + info[1])
				runes.append({"name":info[0], "pos":Vector2(rx,_path_y(rx)), "order":info[2], "lit":false})
	for npc in npcs:
		npc["facing"] = 1.0
		npc["greeting"] = 0.0
		npc["reaction"] = 0.0
		npc["near_before"] = false
	pathways.protect_objectives()
	light_trails.build(self)
	ambience.build(self)
	living.build(self)
	beauty.finish_layout()
	pathways.protect_objectives()
	_set_state("play")
	_update_hud()
	show_toast("Chapter %d: %s" % [level_index + 1, level.title], 3.0)
	_begin_navigation()
	if not restoring: journal.checkpoint()

func _station() -> Vector2:
	var sx: float = float(BASE_LEVELS[level_index]["size"] - (9 if level_index == 2 else 4))
	return Vector2(sx, _path_y(sx) + (2.1 if level_index == 4 else 0.0))

func _blocked(p: Vector2) -> bool:
	var n: float = float(BASE_LEVELS[level_index]["size"])
	if p.x < 0.5 or p.y < 0.5 or p.x > n - 1 or p.y > n - 1: return true
	if level_index == 2 and not quest_done and p.x > _station().x + 0.75: return true
	if pathways.blocked(p): return true
	if pathways.distance(p)>_clearing_radius(p.x) and not _key_clearing(p) and not exploration.open(p) and not beauty.open_floor(p) and not (level_index==1 and p.distance_to(pathways.web_position())<4.8): return true
	var c := Vector2i(int(floor(p.x)), int(floor(p.y)))
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for pos in tree_cells.get(c + Vector2i(dx, dy), []):
				if p.distance_to(pos) < 0.57: return true
	return false

func _walk(d: Vector2) -> void:
	if not _blocked(player+d):
		player += d
		return
	var nx := player + Vector2(d.x, 0)
	if not _blocked(nx): player.x = nx.x
	var ny := player + Vector2(0, d.y)
	if not _blocked(ny): player.y = ny.y

func _process(dt: float) -> void:
	if state == "play" or state == "menu" or state == "comic" or state=="win": elapsed += dt
	tile = clampf(size.x / 20.0, 38, 58)
	if state == "play":
		var axis := mobile_axis
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): axis.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): axis.y += 1
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): axis.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): axis.x += 1
		_advance_movement(axis, dt)
		light_trails.update(dt)
		cooldown = maxf(0, cooldown - dt)
		pulse = maxf(0, pulse - dt)
		if glow_buffer > 0:
			glow_buffer = maxf(0.0, glow_buffer-dt)
			if cooldown <= 0: glow()
		invulnerable = maxf(0, invulnerable - dt)
		_update_npc_animation(dt)
		ambience.update(dt)
		living.update(dt)
		beauty.update(dt)
		pathways.update(dt)
		exploration.visit()
		save_clock+=dt
		if save_clock>12:
			save_clock=0
			journal.checkpoint()
		celebration = maxf(0.0,celebration-dt)
		_update_collectibles()
		_update_bats(dt)
		if level_index == 0 and player.distance_to(_exit()) < INTERACT_RADIUS and key_collected:
			action_button.text = "OPEN DOOR"
		elif beauty.nearest_chest()>=0:
			action_button.text="OPEN CHEST"
		elif _nearest_npc() >= 0:
			action_button.text = "TALK"
		elif level_index > 0 and player.distance_to(_station()) < INTERACT_RADIUS:
			action_button.text = "FINISH"
		else:
			action_button.text = "INTERACT"
		if level_index > 0 and quest_done and player.distance_to(_exit()) < 1.15: _complete_chapter()
		if toast_seconds > 0:
			toast_seconds -= dt
			toast_label.visible = false
		hud_glow.text = "LANTERN READY" if cooldown <= 0 else "GLOW %.1fs" % cooldown
		_update_hud()
	if state=="win": personality.update(dt)
	soundscape.update(dt)
	var lead_target := velocity * 0.38 if state == "play" and not quieter_motion else Vector2.ZERO
	camera_lead = camera_lead.lerp(lead_target, 1.0-exp(-dt*4.0))
	var focus := player + camera_lead
	var camera_target := size * Vector2(0.5, 0.55) - Vector2((focus.x-focus.y)*tile,(focus.x+focus.y)*tile*0.49)
	camera = camera_target if quieter_motion else camera.lerp(camera_target,1.0-exp(-dt*7.0))
	if state == "play":
		for i in range(particles.size()-1, -1, -1):
			particles[i].life -= dt
			if particles[i].life <= 0: particles.remove_at(i)
	_refresh_visible_trees()
	ground_layer.sync()
	queue_redraw()

func _update_collectibles() -> void:
	if level_index == 0:
		if key_revealed and not key_collected and beauty.key_available() and player.distance_to(_key_location()) < 1.15:
			key_collected = true
			beauty.bank()
			personality.react("pickup")
			journal.checkpoint()
			celebration = 1.2
			_burst(_key_location())
			show_toast("The brass key is yours! Follow the lanterns to the woodland door.", 4)
	else:
		for m in marks:
			if not m.lit and m.revealed and beauty.item_available(m) and level_index != 4 and player.distance_to(m.pos) < 1.15:
				m.lit = true
				quest_count += 1
				personality.react("pickup")
				journal.checkpoint()
				_burst(m.pos)
				var noun: String = ["key","scroll page","driftwood bundle","star crystal","moonflower"][level_index]
				show_toast("A %s! That's %d of three." % [noun,quest_count] if quest_count<3 else "All three! "+["","Time to mend the story at the lectern.","Let's make that bridge sturdy!","Now wake Moon, Star, Heart.","The cottage music box is ready."][level_index],3.0)

func _update_bats(dt: float) -> void:
	for b in bats:
		b.fear = maxf(0.0, b.fear - dt)
		b.pos = b.home + Vector2(sin(elapsed * 1.2 + b.phase), cos(elapsed * 1.7 + b.phase) * 0.25) * (1.2 if b.fear <= 0 else 3.4)
		if player.distance_to(b.pos) < 0.95 and b.fear <= 0 and invulnerable <= 0:
			heart -= 1
			personality.react("startle",0.55)
			invulnerable = 1.8
			show_toast("A startled bat! Ara needs a little space.", 2.4)
			if heart <= 0:
				heart = 3
				player = Vector2(2, _path_y(2))
				_reset_controls()
				camera_lead = Vector2.ZERO
				show_toast("Try again from the lantern trail. You've got this!", 3.5)

func glow() -> void:
	if state != "play": return
	if cooldown > 0:
		glow_buffer = 0.2
		return
	glow_buffer = 0.0
	cooldown = GLOW_RECHARGE
	pulse = GLOW_TIME
	_burst(player)
	soundscape.play("glow")
	light_trails.shine()
	pathways.glow()
	ambience.react_to_glow()
	living.glow()
	beauty.shine()
	for npc in npcs:
		if player.distance_to(npc.pos)<5.0: npc.reaction = 1.6
	if level_index == 0 and not key_collected and player.distance_to(_key_location()) < 3.0:
		if not key_revealed: personality.react("reveal",1.0)
		key_revealed = true
		quest_started = true
		show_toast("Something brass glitters between the birch roots!", 3.5)
	if level_index > 0:
		for m in marks:
			if not m.lit and beauty.item_available(m) and player.distance_to(m.pos) < 2.5:
				if level_index == 1: m.revealed = true
				if level_index == 4:
					m.lit = true
					quest_count += 1
					personality.react("flower",1.0)
					journal.checkpoint()
					_burst(m.pos)
					show_toast("Wake up, little moonflower! %d of three are shining." % quest_count if quest_count<3 else "All three flowers are awake! Let's play their lullaby at the cottage.",3.5)
		if level_index == 3 and not quest_done:
			for rune in runes:
				if player.distance_to(rune.pos) < 2.5 and not rune.lit:
					if quest_count < 3:
						show_toast("First collect all three star crystals.", 3)
					elif int(rune.order) == rune_step:
						rune.lit = true
						rune_step += 1
						soundscape.play("rune-%d" % rune.order)
						_burst(rune.pos)
						journal.checkpoint()
						if rune_step == 3: _finish_quest()
						else: show_toast("%s awake! Glow at %s next." % [rune.name, ["Moon", "Star", "Heart"][rune_step]], 3)
					else:
						rune_step = 0
						for r in runes: r.lit = false
						show_toast("Try Moon → Star → Heart. Your crystals are safe.", 3)
					break
	for b in bats:
		if player.distance_to(b.pos) < 4.5: b.fear = 2.4

	journal.checkpoint()

func interact() -> void:
	if state != "play": return
	if beauty.interact(): return
	var ni := _nearest_npc()
	if ni >= 0:
		var npc: Dictionary = npcs[ni]
		_talk(npc)
		npc.met = true
		npc.reaction = 1.6
		if npc.id == "moss" and level_index == 0: quest_started = true
		if level_index > 0: quest_started = true
		_update_hud()
		journal.checkpoint()
		return
	if level_index == 0:
		if player.distance_to(_exit()) < INTERACT_RADIUS:
			if key_collected: _complete_chapter()
			else: show_toast("The woodland door is locked. Ask Moss about the missing key.", 4)
		return
	if player.distance_to(_station()) < INTERACT_RADIUS:
		if quest_done:
			show_toast("The path is open. Find the next lantern gate.", 3)
		elif quest_count < 3:
			show_toast("Gather all three quest items first: %d / 3." % quest_count, 3)
		elif level_index == 3:
			show_toast("Glow at Moon, Star and Heart in that order.", 3)
		else:
			_finish_quest()

func _nearest_npc() -> int:
	var best := -1
	var distance := INTERACT_RADIUS
	for i in range(npcs.size()):
		var d: float = player.distance_to(npcs[i].pos)
		if d < distance:
			best = i
			distance = d
	return best

func _finish_quest() -> void:
	quest_done = true
	beauty.bank()
	personality.react("repair" if level_index==2 else "celebrate",1.8)
	journal.checkpoint()
	celebration = 2.5
	navigation = null # Rebuild navigation when the bridge opens.
	_burst(_station())
	show_toast("Quest complete! "+["","The story is whole again. Let's follow the lanterns!","A proper sturdy bridge! Onward, little paws!","The stars are awake. Ira must be getting closer!","The lullaby is playing. Ira is beside the cottage!"][level_index],4.5)

func _complete_chapter() -> void:
	if completed: return
	if level_index == 0 and not key_collected: return
	if level_index > 0 and not quest_done: return
	completed = true
	beauty.bank()
	if level_index == 4:
		personality.react("reunion",2.3)
		journal.checkpoint()
		_reunion()
	else:
		journal.checkpoint(level_index+1)
		story_chapter = level_index
		story_page = 0
		_show_story()

func _burst(location: Vector2) -> void:
	for i in range((12 if graphics_quality == 0 else 20) if not quieter_motion else 5):
		if particles.size() >= 96: break
		var a := float(i) * TAU / 22.0
		particles.append({"pos":location, "offset":Vector2(cos(a), sin(a)), "life":0.9, "max":0.9})

func _update_hud() -> void:
	if light_trails != null:
		hud_discoveries.text = "Stars %d/18 · Chests %d/3 · %d/400" % [beauty.star_count(),beauty.chest_count(),beauty.score()]
	hud_chapter.text = "CHAPTER %d OF 5" % (level_index + 1)
	hud_title.text = BASE_LEVELS[level_index].title
	hud_hearts.text = "♥ ".repeat(heart) + "♡ ".repeat(3-heart)
	if level_index == 0:
		hud_objective.text = "Quest 1 · " + ("Open the woodland door" if key_collected else "Collect the shimmering key" if key_revealed and beauty.key_available() else "Open the chest between the birches" if key_revealed else "Search the birches near the blue lantern" if quest_started else "Meet your woodland neighbours")
	else:
		var verb: String = ["", "Collect moon-scroll pages", "Collect driftwood", "Collect star crystals", "Wake moonflowers"][level_index]
		hud_objective.text = ("Quest complete · Follow the lantern path" if quest_done else "Quest %d · %s · %d / 3" % [level_index + 1, verb, quest_count] if quest_count < 3 else "Glow: Moon → Star → Heart" if level_index == 3 else "Use the quest station near the end of the path")

func show_toast(message: String, duration: float = 3.0) -> void:
	toast_label.text = message # Preserve the last message for gameplay/debug callers.
	toast_seconds = duration
	toast_label.visible = false
	if conversation!=null: conversation.notify(message,duration)

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo: return
	if conversation!=null and conversation.active: return
	if key.keycode == KEY_ESCAPE:
		if state == "play": _pause()
		elif state == "dialog": _resume()
		elif state == "comic": _set_state("menu")
	elif state == "play":
		if key.keycode == KEY_SPACE: glow()
		elif key.keycode == KEY_E: interact()
	elif state == "comic" and (key.keycode == KEY_SPACE or key.keycode == KEY_ENTER):
		_story_advance()

func _gui_input(event: InputEvent) -> void:
	if state != "play": return
	var mouse := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		_request_destination(_unproject(mouse.position))
	if touch != null and touch.pressed:
		_request_destination(_unproject(touch.position))

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST and state=="play": journal.checkpoint()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_reset_controls()
		if state == "play": _pause()

func _reset_controls() -> void:
	velocity = Vector2.ZERO
	walk_dir = Vector2.ZERO
	mobile_axis = Vector2.ZERO
	held_directions.clear()
	if joystick!=null: joystick.release()
	route.clear()
	route_index = 0
	has_destination = false
	pending_destination=false
	stuck_time = 0.0
	glow_buffer = 0.0

func _hold_direction(id: int, direction: Vector2, pressed: bool) -> void:
	if pressed and state == "play":
		held_directions[id] = direction
	else:
		held_directions.erase(id)
	mobile_axis = Vector2.ZERO
	for value in held_directions.values(): mobile_axis += value

func _screen_to_world(axis: Vector2) -> Vector2:
	# Inverse of the actual diamond projection: diagonal keys match the screen.
	return Vector2(axis.x + axis.y / 0.49, axis.y / 0.49 - axis.x).normalized()

func _advance_movement(axis: Vector2, dt: float) -> void:
	personality.update(dt)
	_navigation_tick(2000)
	var remaining := minf(dt, 0.25)
	while remaining > 0.00001:
		var step := minf(remaining, 1.0/120.0)
		remaining -= step
		_movement_step(axis, step)

func _movement_step(axis: Vector2, dt: float) -> void:
	if personality.action=="repair" and personality.action_time>0: return
	if pending_destination:
		if axis.length_squared()>0.001:
			pending_destination=false;has_destination=false
		else: return
	var target_velocity := Vector2.ZERO
	if axis.length_squared() > 0.001:
		has_destination = false
		route.clear()
		target_velocity = _screen_to_world(axis) * SPEED * pathways.pace(player) * (0.8 if personality.surface()=="wood" else 0.72 if personality.surface()=="stone" else 1.0)
	elif has_destination:
		while route_index < route.size() and player.distance_to(route[route_index]) < 0.015:
			route_index += 1
		if route_index >= route.size():
			has_destination = false
			velocity = Vector2.ZERO
		else:
			var delta := route[route_index] - player
			var speed := minf(SPEED * pathways.pace(player) * (0.8 if personality.surface()=="wood" else 0.72 if personality.surface()=="stone" else 1.0), delta.length() / dt)
			if route_index == route.size()-1: speed = minf(speed, sqrt(2.0*DECELERATION*delta.length()))
			target_velocity = delta.normalized() * speed
	if has_destination: velocity = target_velocity
	velocity = velocity.move_toward(target_velocity, (ACCELERATION if target_velocity != Vector2.ZERO else DECELERATION)*dt)
	var before := player
	_walk(velocity * dt)
	var actual := (player-before)/dt
	walk_dir = actual / SPEED
	if absf(actual.x-actual.y) > 0.15: facing = signf(actual.x-actual.y)
	body_lean = lerpf(body_lean, clampf((actual.x-actual.y)/SPEED, -1.0, 1.0)*0.045, 1.0-exp(-dt*12.0))
	pathways.visit()
	soundscape.step(before.distance_to(player))
	foot_time += before.distance_to(player) * 5.0
	foot_dust += before.distance_to(player)
	if foot_dust > 0.65:
		foot_dust = 0.0
		if not quieter_motion and particles.size() < 96:
			particles.append({"pos":player,"offset":Vector2(-0.2,0.2),"life":0.5,"max":0.5,"kind":"dust"})
	if has_destination and actual.length() < 0.01:
		stuck_time += dt
		if stuck_time > 0.5:
			_reset_controls()
			show_toast("That spot is tucked behind an obstacle. Try the lantern path.", 2.5)
	else: stuck_time = 0.0

func _segment_open(a: Vector2, b: Vector2) -> bool:
	var steps := maxi(1, int(ceil(a.distance_to(b)/0.05)))
	for i in range(steps+1):
		var p := a.lerp(b,float(i)/float(steps))
		if _blocked(p): return false
		for offset in [Vector2(0.06,0),Vector2(-0.06,0),Vector2(0,0.06),Vector2(0,-0.06)]:
			if _blocked(p+offset): return false
	return true

func _begin_navigation() -> void:
	navigation=AStarGrid2D.new()
	var n: int = int(BASE_LEVELS[level_index].size)*4
	navigation.region=Rect2i(0,0,n,n)
	navigation.cell_size=Vector2(.25,.25)
	navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.default_compute_heuristic=AStarGrid2D.HEURISTIC_OCTILE
	navigation.default_estimate_heuristic=AStarGrid2D.HEURISTIC_OCTILE
	navigation.update();navigation.fill_solid_region(navigation.region,true)
	nav_column=2;nav_row=-1;navigation_ready=false;nav_work_us=0;nav_slice_us=0

func _navigation_tick(budget_us: int=2000) -> void:
	if navigation==null: _begin_navigation()
	if navigation_ready: return
	var began := Time.get_ticks_usec()
	var n: int = navigation.region.size.x
	while nav_column<n-3:
		var x := nav_column
		var wx := float(x)*.25
		if nav_row<0:
			var low := _nav_cell(_path_y(wx)-_clearing_radius(wx)-.5)
			var high := _nav_cell(_path_y(wx)+_clearing_radius(wx)+.5)
			if level_index==0 and wx>21 and wx<34:
				low=mini(low,_nav_cell(_key_location().y-4));high=maxi(high,_nav_cell(_key_location().y+4))
			if level_index==1 and absf(wx-pathways.web_position().x)<5:
				low=mini(low,_nav_cell(pathways.web_position().y-5));high=maxi(high,_nav_cell(pathways.web_position().y+5))
			for loop in exploration.loops+beauty.paths:
				if wx<float(loop.points[0].x)-3 or wx>float(loop.points[3].x)+3: continue
				for point in loop.points:
					low=mini(low,_nav_cell(point.y-3));high=maxi(high,_nav_cell(point.y+3))
			nav_row=maxi(2,low);nav_high=mini(n-4,high)
		while nav_row<=nav_high:
			navigation.set_point_solid(Vector2i(x,nav_row),_navigation_blocked(Vector2(x,nav_row)*.25))
			nav_row+=1
			if Time.get_ticks_usec()-began>=budget_us: break
		if nav_row>nav_high: nav_column+=1;nav_row=-1
		if Time.get_ticks_usec()-began>=budget_us: break
	var work := Time.get_ticks_usec()-began
	nav_work_us+=work;nav_slice_us=maxi(nav_slice_us,work)
	if nav_column>=n-3:
		navigation_ready=true;nav_build_us=nav_work_us
		if pending_destination:
			pending_destination=false
			_request_destination(destination)

func _ensure_navigation() -> void:
	if navigation==null: _begin_navigation()
	while not navigation_ready: _navigation_tick(16000)

func _nav_cell(value: float) -> int:
	return floori(value*4.0)

func _nearest_walkable(point: Vector2) -> Vector2i:
	var center := Vector2i((point*4.0).round())
	var best := Vector2i(-1,-1)
	var distance := INF
	for x in range(-4,5):
		for y in range(-4,5):
			var id := center + Vector2i(x,y)
			if not navigation.is_in_boundsv(id) or navigation.is_point_solid(id): continue
			if not _blocked(point) and not _segment_open(point,Vector2(id)*0.25): continue
			var d := point.distance_squared_to(Vector2(id)*0.25)
			if d < distance:
				distance = d
				best = id
	return best

func _request_destination(point: Vector2) -> void:
	if state != "play": return
	var npc := _nearest_npc()
	if npc >= 0 and point.distance_to(npcs[npc].pos) < 1.3:
		interact()
		return
	route.clear()
	route_index = 0
	has_destination = false
	pending_destination=false
	stuck_time = 0.0
	if _segment_open(player, point):
		route.append(point)
	else:
		if navigation==null: _begin_navigation()
		if not navigation_ready:
			destination=point;pending_destination=true;has_destination=true
			return
		var from := _nearest_walkable(player)
		var to := _nearest_walkable(point)
		if from.x < 0 or to.x < 0:
			show_toast("Choose a spot on the woodland floor.", 2.5)
			return
		var raw := navigation.get_point_path(from,to)
		var anchor := player
		var i := 0
		while i < raw.size():
			if not _segment_open(anchor,raw[i]):
				route.clear()
				break
			var far := i
			while far+1 < raw.size() and _segment_open(anchor,raw[far+1]): far += 1
			route.append(raw[far])
			anchor = raw[far]
			i = far+1
		if not route.is_empty() and _segment_open(route[route.size()-1],point): route.append(point)
	if route.is_empty():
		show_toast("That route is closed. Try a nearby lantern.", 2.5)
		return
	destination = route[route.size()-1]
	has_destination = true

func _project(p: Vector2) -> Vector2:
	return Vector2((p.x-p.y) * tile, (p.x+p.y) * tile * 0.49) + camera

func _unproject(p: Vector2) -> Vector2:
	var a := (p.x-camera.x)/tile
	var b := (p.y-camera.y)/(tile*0.49)
	return Vector2((a+b)*0.5,(b-a)*0.5)


func set_graphics_quality(index: int) -> void:
	graphics_quality = clampi(index,0,2)
	material = relief_material if graphics_quality == 2 else null
	if atmosphere != null: atmosphere.apply_quality(graphics_quality)
	if journal.game!=null: journal.settings()
	queue_redraw()

func _update_npc_animation(dt: float) -> void:
	living.update_npcs(dt)

func _refresh_visible_trees() -> void:
	if state not in ["play","dialog","win"]: return
	if camera.distance_squared_to(visibility_camera)<64.0 and size == visibility_size: return
	visibility_camera = camera
	visibility_size = size
	visible_trees.clear()
	var pad := tile*5.5
	var corners := [_unproject(Vector2(-pad,-pad)),_unproject(Vector2(size.x+pad,-pad)),_unproject(Vector2(-pad,size.y+pad)),_unproject(size+Vector2(pad,pad))]
	var low := Vector2(INF,INF)
	var high := Vector2(-INF,-INF)
	for p in corners:
		low = low.min(p)
		high = high.max(p)
	for x in range(floori(low.x/8.0),floori(high.x/8.0)+1):
		for y in range(floori(low.y/8.0),floori(high.y/8.0)+1):
			for tree in tree_render_chunks.get(Vector2i(x,y),[]):
				var at := _project(tree.pos)
				var height: float = tile*3.9*float(tree["size"])
				if at.x>-tile*1.8 and at.x<size.x+tile*1.8 and at.y>-20 and at.y<size.y+height+20:
					visible_trees.append(tree)

func _navigation_blocked(p: Vector2) -> bool:
	for dx in [-0.16,0.0,0.16]:
		for dy in [-0.16,0.0,0.16]:
			if _blocked(p+Vector2(dx,dy)): return true
	return false
