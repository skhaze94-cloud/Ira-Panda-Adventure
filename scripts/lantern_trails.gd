extends RefCounted
## Optional exploration clues. None replace or gate the original quest objects.
const REVEAL_RADIUS := 4.8
const TRACK_LIFETIME := 18.0
const SHADOW_LIFETIME := 18.0
const PLANT_RADIUS := 3.2
const HINTS = [
	"Tiny prints leave the blue lantern trail. Look between the pale birch roots.",
	"The purple nests hide torn pages. A lantern glow will coax them out.",
	"Driftwood lies on both sides of the trail. Gather three bundles before the brook.",
	"Gather three crystals, then wake the stones: Moon, Star, Heart.",
	"Wake three moonflowers with your lantern, then visit the cottage music box."
]
var game: Control
var tracks: Array = []
var plants: Array = []
var stones: Array = []
var trail_found: Dictionary = {}
var discovered := 0
var total := 0

func build(owner_game: Control) -> void:
	game = owner_game
	tracks.clear()
	plants.clear()
	stones.clear()
	trail_found.clear()
	discovered = 0
	# A short teaching trail near the first plant; chapter clues lead to quest items.
	_add_trail([_on_path(6.0),_on_path(8.0),_on_path(11.0)],0)
	var targets: Array[Vector2] = []
	if game.level_index == 0:
		targets.append(game._key_location())
		_add_trail([_on_path(24.0),Vector2(26,game._path_y(26)+3),targets[0]],1)
	else:
		for mark in game.marks:
			targets.append(mark.pos)
			_add_trail([_on_path(mark.pos.x-3.6),_on_path(mark.pos.x-1.7),mark.pos],int(mark.index)+1)
	var n: float = float(game.BASE_LEVELS[game.level_index].size)
	for i in range(3):
		var x: float = [7.5,n*0.36,n*0.64][i]
		var p := Vector2(x,game._path_y(x)+(2.0 if i % 2 == 0 else -2.0))
		if game._blocked(p): p = _on_path(x)
		plants.append({"pos":p,"awake":false,"index":i})
	for i in range(targets.size()):
		var target := targets[i]
		var x := 24.5 if game.level_index == 0 else target.x-3.6
		var pos := Vector2(x,game._path_y(x)+0.8)
		var text: String = "Birch roots hide the brass key." if game.level_index == 0 else ["","A scroll page rests in this purple nest.","Driftwood waits beside the trail.","A star crystal shines just ahead.","Shine at the sleeping moonflower."][game.level_index]
		_add_stone(pos,target,text,false)
	if game.level_index == 3:
		_add_stone(_on_path(60.0)+Vector2(0,1.0),game.runes[1].pos,"Moon  >  Star  >  Heart",true)
	total = trail_found.size()+plants.size()+stones.size()

func _on_path(x: float) -> Vector2:
	return Vector2(x,game._path_y(x))

func _add_trail(points: Array, id: int) -> void:
	trail_found[id] = false
	for part in range(points.size()-1):
		var a: Vector2 = points[part]
		var b: Vector2 = points[part+1]
		var count := maxi(2,int(ceil(a.distance_to(b)/0.55)))
		for i in range(count):
			var direction := (b-a).normalized()
			var side := Vector2(-direction.y,direction.x)*(0.12 if i % 2 else -0.12)
			var p := a.lerp(b,float(i)/float(count))+side
			if game._blocked(p): continue
			tracks.append({"pos":p,"direction":direction,"side":i%2,"time":0.0,"trail":id})

func _add_stone(pos: Vector2, target: Vector2, text: String, sequence: bool) -> void:
	var direction := (target-pos).normalized()
	var stand := pos-direction*1.65
	# Clearings are authored wide enough for the stone and its light-source marker.
	if game._blocked(pos) or game._blocked(stand): return
	stones.append({"pos":pos,"target":target,"direction":direction,"stand":stand,"text":text,"sequence":sequence,"found":false,"time":0.0})

func update(dt: float) -> void:
	if game.state != "play": return
	for track in tracks: track.time = maxf(0.0,float(track.time)-dt)
	for stone in stones: stone.time = maxf(0.0,float(stone.time)-dt)

func shine() -> void:
	if game.state != "play": return
	var message := ""
	for track in tracks:
		if game.player.distance_to(track.pos) > REVEAL_RADIUS: continue
		track.time = TRACK_LIFETIME
		var id: int = int(track.trail)
		if not trail_found[id]:
			trail_found[id] = true
			discovered += 1
			message = "Tiny footprints! Follow their silver glow and shine again as you explore."
	for plant in plants:
		if plant.awake or game.player.distance_to(plant.pos) > PLANT_RADIUS: continue
		plant.awake = true
		discovered += 1
		game._burst(plant.pos)
		var restored: bool = game.heart < 3
		game.heart = mini(3,game.heart+1)
		# An awakened bloom extends the nearby trail and becomes a permanent light.
		for track in tracks:
			if plant.pos.distance_to(track.pos) <= REVEAL_RADIUS:
				track.time = TRACK_LIFETIME
				var id: int = int(track.trail)
				if not trail_found[id]:
					trail_found[id] = true
					discovered += 1
		message = ("A lantern bloom restores one heart! " if restored else "A lantern bloom wakes! ")+HINTS[game.level_index]
	for stone in stones:
		var distance: float = game.player.distance_to(stone.pos)
		if distance > REVEAL_RADIUS or distance < 0.6: continue
		var shadow_direction: Vector2 = (stone.pos-game.player).normalized()
		if shadow_direction.dot(stone.direction) < 0.7:
			if message.is_empty(): message = "A shadow hides a clue. Shine from the brass crescent behind the stone."
			continue
		stone.time = SHADOW_LIFETIME
		if not stone.found:
			stone.found = true
			discovered += 1
			game._burst(stone.pos)
		message = "The shadow points the way: "+str(stone.text)
	if not message.is_empty(): game.show_toast(message,5.0)
	game._update_hud()

func nearby_hint() -> String:
	for plant in plants:
		if not plant.awake and game.player.distance_to(plant.pos) <= PLANT_RADIUS:
			return "Space / GLOW: wake this lantern bloom"
	for stone in stones:
		if game.player.distance_to(stone.pos) <= REVEAL_RADIUS:
			if stone.time > 0: return "Shadow clue revealed: follow the golden arrow"
			if stone.found: return "Space / GLOW: relight this shadow clue"
			return "Shadow clue: shine from the brass crescent"
	for track in tracks:
		if track.time <= 0 and game.player.distance_to(track.pos) <= REVEAL_RADIUS:
			return "Space / GLOW: search for hidden footprints"
	return "Space / GLOW: explore with your lantern"
