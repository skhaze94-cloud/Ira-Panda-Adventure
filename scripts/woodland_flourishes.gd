extends RefCounted
## Fixed-size world ambience: no node-per-particle or unbounded spawn queues.
var game: Control
var creatures: Array = []
var scenery: Array = []
var response := 0.0

func build(owner_game: Control) -> void:
	game = owner_game
	creatures.clear()
	scenery.clear()
	response = 0.0
	var n: int = int(game.BASE_LEVELS[game.level_index].size)
	for i in range(36):
		var x := 5.0+float(i)*float(n-10)/36.0
		var y: float = game._path_y(x)+(2.0+game._randseed(i*19+4)*1.8)*(1 if i%2 else -1)
		creatures.append({"home":Vector2(x,y),"phase":float(i)*2.17,"index":i})
	var stops: Array = [16,29,43,55] if game.level_index==2 else [72,77,81] if game.level_index==4 else [61,68,75] if game.level_index==3 else range(12,n-8,14)
	for x in stops:
		var kind: String = ["ribbon","mushroom","lily","orrery","garden_arch"][game.level_index]
		var side := 5.8 if game.level_index==2 else 3.8 if x%3 else -3.8
		var p := Vector2(x,game._path_y(x)+side)
		# Decorative props never create collision or obscure a required quest object.
		var close := false
		for mark in game.marks:
			if p.distance_to(mark.pos)<2.0: close = true
		if not close: scenery.append({"pos":p,"kind":kind,"phase":float(x)})

func update(dt: float) -> void:
	if game.state == "play": response = maxf(0.0,response-dt)

func react_to_glow() -> void:
	response = 2.2

func nearby_creatures() -> Array:
	var visible: Array = []
	var budget: int = [8,16,24][game.graphics_quality]
	for creature in creatures:
		if creature.home.distance_squared_to(game.player)>100.0: continue
		visible.append(creature)
		if visible.size()>=budget: break
	return visible
