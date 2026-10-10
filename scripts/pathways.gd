extends RefCounted
## One source of truth for the trail, stream banks, crossings and travel reactions.
const OFFSETS = [
	[0,0,5,-5,-8,7,9,-7,-5,6,2,0],
	[0,0,-6,8,10,-7,-10,6,9,-5,-2,0],
	[0,0,7,10,-6,-9,8,11,-7,-5,1,0],
	[0,0,-7,-10,8,5,-9,-6,9,6,2,0],
	[0,0,6,-8,-5,9,6,-9,-6,7,3,0]
]
var game: Control
var crossings: Array = []
var obstacles: Array = []
var web_clear := false
var web_fade := 1.0
var seen: Dictionary = {}
func build(owner_game: Control) -> void:
	game = owner_game
	crossings.clear()
	obstacles.clear()
	seen.clear()
	web_clear = false
	web_fade = 1.0
	var n: float = game.BASE_LEVELS[game.level_index].size
	for i in range(2):
		var fraction: float = [[.28,.65],[.32,.78],[.26,.62],[.40,.75],[.30,.74]][game.level_index][i]
		var x := 3.0+(n-6.0)*fraction
		var kind: String = [["bridge","stones"],["stones","log_bridge"],["bridge","stones"],["stones","bridge"],["bridge","log_bridge"]][game.level_index][i]
		crossings.append({"x":x,"pos":Vector2(x,y(x)),"kind":kind,"width":1.15,"offset":-0.85 if kind=="stones" else 0.8})
	if game.level_index==2:
		var x: float = game._station().x+1.4
		crossings.append({"x":x,"pos":Vector2(x,y(x)),"kind":"repair","width":0.8,"offset":0.0})
	for fraction in [0.24,0.48,0.76]:
		var x: float = n*fraction
		obstacles.append({"pos":Vector2(x,y(x)+0.2),"kind":"log" if game.level_index%2==0 else "boulder"})
func y(x: float) -> float:
	var n: float = game.BASE_LEVELS[game.level_index].size
	var u := clampf((x-3.0)/(n-6.0)*11.0,0,11)
	var i := mini(10,floori(u))
	# Flat approaches let bridges sit squarely between curved woodland stretches.
	var t := u-float(i)
	return x+lerpf(float(OFFSETS[game.level_index][i]),float(OFFSETS[game.level_index][i+1]),t*t*(3.0-2.0*t))*0.8
func distance(p: Vector2) -> float:
	return absf(p.y-y(p.x))
func blocked(p: Vector2) -> bool:
	for c in crossings:
		if absf(p.x-c.x)>c.width+0.12: continue
		if c.kind=="repair" and not game.quest_done: return true
		if absf(p.y-crossing_y(c,p.x)-c.offset)>2.0: return true
	for o in obstacles:
		var delta: Vector2 = p-o.pos
		if (delta/Vector2(0.8,1.3)).length()<1.0: return true
	return false
func web_position() -> Vector2:
	var x: float = game.BASE_LEVELS[game.level_index].size*0.40
	return Vector2(x,y(x))
func pace(p: Vector2) -> float:
	return 0.55 if game.level_index==1 and not web_clear and p.distance_to(web_position())<2.3 else 1.0
func glow() -> void:
	if game.level_index==1 and not web_clear and game.player.distance_to(web_position())<4.5:
		web_clear = true
		game.soundscape.play("web")
		game._burst(web_position())
		game.show_toast("The silvery web folds into sparkles. Thank you, little spider!",3.5)
func visit() -> void:
	if game.level_index==1 and not web_clear and game.player.distance_to(web_position())<2.6 and not seen.has("web"):
		seen["web"] = true
		game.show_toast("A tickly spiderweb! Your lantern can gently untangle it.",3.5)
	for i in range(crossings.size()):
		var c: Dictionary = crossings[i]
		if game.player.distance_to(c.pos)<1.8 and not seen.has(i) and (c.kind!="repair" or game.quest_done):
			seen[i] = true
			game._burst(game.player)
			game.show_toast("Tiptoe over the stepping stones!" if c.kind=="stones" else "A fallen tree makes a splendid little bridge!" if c.kind=="log_bridge" else "Little paws, big crossing!",2.5)

func protect_objectives() -> void:
	var targets: Array[Vector2] = [game._station(),game._exit(),game._key_location() if game.level_index==0 else game.player]
	for item in game.marks+game.runes+game.npcs: targets.append(item.pos)
	for loop in game.exploration.loops:
		targets.append(loop.points[0]);targets.append(loop.points[3])
	for o in obstacles:
		for shift in [0.0,2.5,-2.5,4.5,-4.5]:
			var x: float = o.pos.x+shift
			var p := Vector2(x,y(x)+0.2)
			var safe := true
			for target in targets:
				if p.distance_to(target)<2.8: safe = false
			for c in crossings:
				if absf(x-c.x)<c.width+1.5: safe = false
			if safe:
				o.pos = p
				break

func update(dt: float) -> void:
	if web_clear: web_fade = 0.0 if game.quieter_motion else maxf(0,web_fade-dt/0.65)

func crossing_y(c: Dictionary, x: float) -> float:
	return float(c.pos.y)+(x-float(c.x))*0.35
