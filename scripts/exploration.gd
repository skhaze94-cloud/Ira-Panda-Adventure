extends RefCounted
## Two optional loops rejoin the main trail; discoveries never gate a quest.
var game: Control
var loops: Array = []
var found: Array = [false,false]
func build(owner_game: Control) -> void:
	game=owner_game;loops.clear();found=[false,false]
	var n: float = game.BASE_LEVELS[game.level_index].size
	for i in range(2):
		var x := 3+(n-6)*(.12 if i==0 else .48)
		var side := -1.0 if i==0 else 1.0
		var a := Vector2(x,game._path_y(x))
		var b := Vector2(x+2,game._path_y(x+2)+side*8)
		var c := Vector2(x+4,game._path_y(x+4)+side*8)
		var d := Vector2(x+6,game._path_y(x+6))
		# Keep the first meadow within the square map bounds.
		b.y=maxf(3,b.y);c.y=maxf(3,c.y)
		loops.append({"points":[a,b,c,d],"pos":(b+c)*0.5,"name":[["Acorn Picnic","Ribbon Chimes"],["Moth Tea Party","Spore Wishes"],["Pebble Ducks","Willow Chimes"],["Pocket Observatory","Fallen-Star Bench"],["Biscuit Nook","Sister's Ribbons"]][game.level_index][i],"index":i})
func open(p: Vector2, width: float=2.3) -> bool:
	for loop in loops:
		var points: Array = loop.points
		for i in range(3):
			if game._segment_distance(p,points[i],points[i+1])<width: return true
	return false
func visit() -> void:
	for loop in loops:
		var i: int = loop.index
		if found[i] or game.player.distance_to(loop.pos)>1.8: continue
		found[i]=true
		game.heart=mini(3,game.heart+1)
		game.personality.react("celebrate",1.1)
		game._burst(loop.pos)
		game.show_toast(loop.name+"! "+[["Ara saves an acorn-sized seat for Ira.","A ribbon sings a tiny woodland tune."],["Even the moths have teacups!","Ara makes a little glowing wish."],["Three pebbles look exactly like ducks!","The willow hums beside the water."],["A telescope just the right size for little paws!","A quiet seat beneath a very big sky."],["A biscuit for Ara. One for Ira. Perfect.","These ribbons smell like home."]][game.level_index][i],4)
		game.journal.checkpoint()
func segments() -> Array[Vector4]:
	var data: Array[Vector4] = []
	for loop in loops:
		for i in range(3):
			var a: Vector2 = loop.points[i];var b: Vector2 = loop.points[i+1]
			data.append(Vector4(a.x,a.y,b.x,b.y))
	return data
