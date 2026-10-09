extends Control
## Native Godot 4 port of Ira Panda Adventure 2.4 Storybook.

const SPEED := 2.3
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
var menu_layer: Control
var story_layer: Control
var hud_layer: Control
var modal_layer: Control
var hud_chapter: Label
var hud_title: Label
var hud_objective: Label
var hud_hearts: Label
var hud_glow: Label
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
var options_music: CheckButton
var options_motion: CheckButton
var menu_audio: AudioStreamPlayer
var game_audio: AudioStreamPlayer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	for name in ["forest","level-2","level-3","level-4","level-5","ground-v2","trees-v2","lamps-v2","decor","atlas","ara-rig-22","ara","ira","npc-pip","npc-bramble","npc-moss","key-birches","woodland-key","woodland-door","quests-23","comic-1","comic-2","comic-3","interlude-1-1","interlude-1-2","interlude-2-1","interlude-2-2","interlude-3-1","interlude-3-2","interlude-4-1","interlude-4-2"]:
		tex[name] = load("res://assets/%s.webp" % name)
	var file := FileAccess.open("res://story-24.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Array:
			chapter_stories = parsed
	_build_ui()
	menu_audio = _music("menu-music")
	game_audio = _music("gameplay-music")
	_set_state("menu")
	resized.connect(queue_redraw)

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
	state = next_state
	menu_layer.visible = state == "menu"
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
	return sin(x * (0.45 + level_index * 0.025) + level_index * 0.6) * (1.3 + level_index * 0.18)

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
	player = Vector2(2, _path_y(2))
	walk_dir = Vector2.ZERO
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
	var level: Dictionary = BASE_LEVELS[level_index]
	var n: int = level["size"]
	var exit_pos := _exit()
	for x in range(n):
		for y in range(n):
			var p := Vector2(float(x) + 0.2 + _randseed(x + y * 36 + level_index) * 0.25, float(y) + 0.2 + _randseed(x * 7 + y + level_index) * 0.25)
			if _key_clearing(p): continue
			var d: float = absf(p.y - _path_y(p.x))
			var clearing := (level_index == 1 and sin(p.x * 0.34) > 0.45) or (level_index == 4 and sin(p.x * 0.28) > 0.4)
			if d < (4.8 if clearing else 3.4) or _randseed(x * 29 + y + level_index * 71) <= float(level.trees) or p.distance_to(exit_pos) < 2.5: continue
			if level_index == 4 and (x % 3 == 1 or y % 3 == 1): continue
			var t := {"pos":p, "variant":int(floor(_randseed(x + y * 14 + level_index * 21) * 3.0)), "size":(0.78 + _randseed(x * 39 + y) * 0.45)}
			trees.append(t)
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
		var guide_name := ["","Pip","Bramble","Moss","Pip"][level_index]
		var gid := guide_name.to_lower()
		npcs.append({"id":gid, "name":guide_name, "pos":Vector2(5, _path_y(5) + 0.65), "home":Vector2(5, _path_y(5) + 0.65), "met":false})
		for i in range(3):
			var x := 2.0 + float(n - 5) * [0.22, 0.48, 0.72][i]
			marks.append({"pos":Vector2(x, _path_y(x) + (2.35 if i % 2 else -2.35)), "lit":false, "revealed":level_index != 1, "index":i})
		if level_index == 3:
			for info in [["Star",-12,1],["Moon",-8,0],["Heart",-4,2]]:
				var rx: float = float(n + info[1])
				runes.append({"name":info[0], "pos":Vector2(rx,_path_y(rx)), "order":info[2], "lit":false})
	_set_state("play")
	_update_hud()
	show_toast("Chapter %d: %s" % [level_index + 1, level.title], 3.0)

func _station() -> Vector2:
	var sx: float = float(BASE_LEVELS[level_index]["size"] - (9 if level_index == 2 else 4))
	return Vector2(sx, _path_y(sx) + (2.1 if level_index == 4 else 0.0))

func _blocked(p: Vector2) -> bool:
	var n: float = float(BASE_LEVELS[level_index]["size"])
	if p.x < 0.5 or p.y < 0.5 or p.x > n - 1 or p.y > n - 1: return true
	if level_index == 2 and not quest_done and p.x > _station().x + 0.75: return true
	var c := Vector2i(int(floor(p.x)), int(floor(p.y)))
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for pos in tree_cells.get(c + Vector2i(dx, dy), []):
				if p.distance_to(pos) < 0.57: return true
	return false

func _walk(d: Vector2) -> void:
	var nx := player + Vector2(d.x, 0)
	if not _blocked(nx): player.x = nx.x
	var ny := player + Vector2(0, d.y)
	if not _blocked(ny): player.y = ny.y

func _process(dt: float) -> void:
	elapsed += dt
	if state == "play":
		var axis := mobile_axis
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): axis.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): axis.y += 1
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): axis.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): axis.x += 1
		var world_axis := Vector2(axis.x + axis.y, axis.y - axis.x) * 0.70710678
		if axis.length_squared() > 0: has_destination = false
		elif has_destination:
			world_axis = destination - player
			if world_axis.length() < 0.14:
				has_destination = false
				world_axis = Vector2.ZERO
		walk_dir = world_axis.normalized()
		if walk_dir.length_squared() > 0:
			facing = 1.0 if walk_dir.x - walk_dir.y >= 0 else -1.0
			var before := player
			_walk(walk_dir * SPEED * minf(dt, 0.05))
			foot_time += before.distance_to(player) * 5.0
			if has_destination and before.distance_to(player) < 0.0001: has_destination = false
		cooldown = maxf(0, cooldown - dt)
		pulse = maxf(0, pulse - dt)
		invulnerable = maxf(0, invulnerable - dt)
		_update_collectibles()
		_update_bats(dt)
		if level_index == 0 and player.distance_to(_exit()) < 1.8 and key_collected:
			action_button.text = "OPEN DOOR"
		elif _nearest_npc() >= 0:
			action_button.text = "TALK"
		elif level_index > 0 and player.distance_to(_station()) < 2:
			action_button.text = "COMPLETE QUEST"
		else:
			action_button.text = "INTERACT"
		if level_index > 0 and quest_done and player.distance_to(_exit()) < 1.15: _complete_chapter()
		if toast_seconds > 0:
			toast_seconds -= dt
			toast_label.visible = toast_seconds > 0
		hud_glow.text = "LANTERN READY" if cooldown <= 0 else "GLOW %.1fs" % cooldown
		_update_hud()
	for i in range(particles.size()-1, -1, -1):
		particles[i].life -= dt
		if particles[i].life <= 0: particles.remove_at(i)
	queue_redraw()

func _update_collectibles() -> void:
	if level_index == 0:
		if key_revealed and not key_collected and player.distance_to(_key_location()) < 0.9:
			key_collected = true
			_burst(_key_location())
			show_toast("The brass key is yours! Follow the lanterns to the woodland door.", 4)
	else:
		for m in marks:
			if not m.lit and m.revealed and level_index != 4 and player.distance_to(m.pos) < 0.95:
				m.lit = true
				quest_count += 1
				_burst(m.pos)
				show_toast("Found: %d of 3!" % quest_count, 2.2)

func _update_bats(dt: float) -> void:
	for b in bats:
		b.fear = maxf(0.0, b.fear - dt)
		b.pos = b.home + Vector2(sin(elapsed * 1.2 + b.phase), cos(elapsed * 1.7 + b.phase) * 0.25) * (1.2 if b.fear <= 0 else 3.4)
		if player.distance_to(b.pos) < 0.95 and b.fear <= 0 and invulnerable <= 0:
			heart -= 1
			invulnerable = 1.8
			show_toast("A startled bat! Ara needs a little space.", 2.4)
			if heart <= 0:
				heart = 3
				player = Vector2(2, _path_y(2))
				show_toast("Try again from the lantern trail. You've got this!", 3.5)

func glow() -> void:
	if state != "play" or cooldown > 0: return
	cooldown = GLOW_RECHARGE
	pulse = GLOW_TIME
	_burst(player)
	if level_index == 0 and not key_collected and player.distance_to(_key_location()) < 3.0:
		key_revealed = true
		quest_started = true
		show_toast("Something brass glitters between the birch roots!", 3.5)
	if level_index > 0:
		for m in marks:
			if not m.lit and player.distance_to(m.pos) < 2.5:
				if level_index == 1: m.revealed = true
				if level_index == 4:
					m.lit = true
					quest_count += 1
					_burst(m.pos)
					show_toast("Moonflower awakened! %d / 3" % quest_count, 3)
		if level_index == 3 and not quest_done:
			for rune in runes:
				if player.distance_to(rune.pos) < 2.5 and not rune.lit:
					if quest_count < 3:
						show_toast("First collect all three star crystals.", 3)
					elif int(rune.order) == rune_step:
						rune.lit = true
						rune_step += 1
						if rune_step == 3: _finish_quest()
						else: show_toast("%s awake! Glow at %s next." % [rune.name, ["Moon", "Star", "Heart"][rune_step]], 3)
					else:
						rune_step = 0
						for r in runes: r.lit = false
						show_toast("Try Moon → Star → Heart. Your crystals are safe.", 3)
					break
	for b in bats:
		if player.distance_to(b.pos) < 4.5: b.fear = 2.4

func interact() -> void:
	if state != "play": return
	var ni := _nearest_npc()
	if ni >= 0:
		var npc: Dictionary = npcs[ni]
		npc.met = true
		if npc.id == "moss" and level_index == 0: quest_started = true
		if level_index > 0: quest_started = true
		_show_dialog("%s · Woodland Neighbour" % npc.name, _guide_text(npc.id), "KEEP EXPLORING", "", "resume")
		return
	if level_index == 0:
		if player.distance_to(_exit()) < 1.8:
			if key_collected: _complete_chapter()
			else: show_toast("The woodland door is locked. Ask Moss about the missing key.", 4)
		return
	if player.distance_to(_station()) < 2.0:
		if quest_done:
			show_toast("The path is open. Find the next lantern gate.", 3)
		elif quest_count < 3:
			show_toast("Gather all three quest items first: %d / 3." % quest_count, 3)
		elif level_index == 3:
			show_toast("Glow at Moon, Star and Heart in that order.", 3)
		else:
			_finish_quest()

func _guide_text(id: String) -> String:
	if level_index > 0: return "QUEST %d: %s\n\n%s" % [level_index + 1, QUEST_TITLES[level_index], QUEST_HINTS[level_index]]
	match id:
		"pip": return "Let's find Ira! Walk with WASD / arrows, or the touch direction pad. Shine your lantern with Space or GLOW. Press E to talk. The woodland path leads to three helpful friends."
		"bramble": return "The wooden door at the far end of the woods is locked. Moss knows something about a brass key near the blue lantern trail."
		"moss": return "QUEST 1: The Lost Woodland Key\n\nThree pale birches stand beside a blue-lantern side trail. Go there, glow between their roots, then pick up the key. Return to the woodland door."
	return QUEST_HINTS[0]

func _nearest_npc() -> int:
	var best := -1
	var distance := 2.0
	for i in range(npcs.size()):
		var d: float = player.distance_to(npcs[i].pos)
		if d < distance:
			best = i
			distance = d
	return best

func _finish_quest() -> void:
	quest_done = true
	_burst(_station())
	show_toast("Quest complete! Follow the lantern path.", 4.0)

func _complete_chapter() -> void:
	if completed: return
	if level_index == 0 and not key_collected: return
	if level_index > 0 and not quest_done: return
	completed = true
	if level_index == 4:
		_show_dialog("Found you, little sister!", "Ara found Ira among the moonflowers by the cottage. Five little chapters. One very big hug.\n\n'Next time,' Ara smiled, 'we hide somewhere with biscuits.'", "PLAY AGAIN", "TITLE SCREEN", "replay")
		state = "win"
		modal_layer.visible = true
	else:
		story_chapter = level_index
		story_page = 0
		_show_story()

func _burst(location: Vector2) -> void:
	for i in range(22 if not quieter_motion else 5):
		var a := float(i) * TAU / 22.0
		particles.append({"pos":location, "offset":Vector2(cos(a), sin(a)), "life":0.9, "max":0.9})

func _update_hud() -> void:
	hud_chapter.text = "CHAPTER %d OF 5" % (level_index + 1)
	hud_title.text = BASE_LEVELS[level_index].title
	hud_hearts.text = "♥ ".repeat(heart) + "♡ ".repeat(3-heart)
	if level_index == 0:
		hud_objective.text = "Quest 1 · " + ("Open the woodland door" if key_collected else "Collect the shimmering key" if key_revealed else "Search the birches near the blue lantern" if quest_started else "Meet your woodland neighbours")
	else:
		var verb := ["", "Collect moon-scroll pages", "Collect driftwood", "Collect star crystals", "Wake moonflowers"][level_index]
		hud_objective.text = ("Quest complete · Follow the lantern path" if quest_done else "Quest %d · %s · %d / 3" % [level_index + 1, verb, quest_count] if quest_count < 3 else "Glow: Moon → Star → Heart" if level_index == 3 else "Use the quest station near the end of the path")

func show_toast(message: String, duration: float = 3.0) -> void:
	toast_label.text = message
	toast_seconds = duration
	toast_label.visible = true

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo: return
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
		var v := _unproject(mouse.position)
		if _nearest_npc() >= 0 and v.distance_to(npcs[_nearest_npc()].pos) < 1.3:
			interact()
		else:
			destination = v
			has_destination = true
	if touch != null and touch.pressed:
		destination = _unproject(touch.position)
		has_destination = true

func _project(p: Vector2) -> Vector2:
	return Vector2((p.x-p.y) * tile, (p.x+p.y) * tile * 0.49) + camera

func _unproject(p: Vector2) -> Vector2:
	var a := (p.x-camera.x)/tile
	var b := (p.y-camera.y)/(tile*0.49)
	return Vector2((a+b)*0.5,(b-a)*0.5)
