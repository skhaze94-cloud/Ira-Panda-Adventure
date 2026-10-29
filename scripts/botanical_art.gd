extends RefCounted
## Five exclusive painted textures per chapter; only the current set stays loaded.
const CHAPTERS = ["woods","glade","brook","hollow","garden"]
const NAMES = [
	["rowan","hazel","fern","strawberry","birch_branch"],
	["alder","mushroom_tree","bell_mushrooms","silver_fern","log_planter"],
	["willow","river_birch","cattails","water_mint","driftwood_lily"],
	["silver_tree","juniper","moon_ferns","starflowers","lichen_stone"],
	["crabapple","magnolia","peonies","moonflower","sweetpea_can"]
]
var textures: Array[Texture2D] = []
var plants: Array = []
var protected: Array[Vector2] = []
var loaded_chapter := -1

func build(g: Control) -> void:
	if loaded_chapter != g.level_index:
		textures.clear()
		for name in NAMES[g.level_index]:
			textures.append(load("res://assets/botanical/%s/%s.png" % [CHAPTERS[g.level_index],name]))
		loaded_chapter=g.level_index
	plants.clear()
	protected.clear()
	protected.append(g._exit())
	protected.append(g._station())
	protected.append(g._key_location())
	for group in [g.npcs,g.marks,g.runes,g.beauty.chests,g.objects.items,g.light_trails.plants,g.landmarks,g.living.clues,g.pathways.obstacles]:
		for item in group: protected.append(item.pos)
	for crossing in g.pathways.crossings: protected.append(crossing.pos)
	# Sparse alternating banks: no node-per-plant, random spawning or new collision.
	var n: float=g.BASE_LEVELS[g.level_index].size
	for i in range(12):
		var preferred: float=6.0+float(i)*(n-13.0)/12.0
		for offset in [0.0,1.7,-1.7,3.0,-3.0]:
			var x: float=clampf(preferred+offset,4.0,n-4.0)
			var side: float=1.0 if i%2==0 else -1.0
			var pos:=Vector2(x,g._path_y(x)+side*(3.5+g._randseed(i*113+g.level_index*37)*1.3))
			if safe(g,pos):
				plants.append({"pos":pos,"kind":2+plants.size()%3,"scale":.9+g._randseed(i*29+71)*.2})
				break

func safe(g: Control, pos: Vector2) -> bool:
	var n: float=g.BASE_LEVELS[g.level_index].size
	if pos.x<1 or pos.y<1 or pos.x>n-1 or pos.y>n-1: return false
	for crossing in g.pathways.crossings:
		if absf(pos.x-crossing.x)<crossing.width+.8: return false
	for point in protected:
		if pos.distance_squared_to(point)<7.84: return false
	for plant in plants:
		if pos.distance_squared_to(plant.pos)<12.25: return false
	for tree in g.trees:
		if pos.distance_squared_to(tree.pos)<3.24: return false
	for group in [g.decorations,g.lanterns,g.beauty.scenery,g.ambience.scenery]:
		for item in group:
			if pos.distance_squared_to(item.pos)<3.24: return false
	return true

func draw_sprite(g: Control, index: int, at: Vector2, height: float, alpha: float=1.0, sway: float=0.0) -> void:
	var texture: Texture2D=textures[index]
	var dimensions:=Vector2(height*texture.get_width()/texture.get_height(),height)
	g.draw_set_transform(at,sway)
	g.draw_texture_rect(texture,Rect2(Vector2(-dimensions.x*.5,-height),dimensions),false,Color(1,1,1,alpha))
	g.draw_set_transform(Vector2.ZERO)

func draw_plant(g: Control, plant: Dictionary) -> void:
	var height: float=g.tile*[1.05,.8,1.1][int(plant.kind)-2]*float(plant.scale)
	var at: Vector2=g._project(plant.pos)
	g._shadow(at,14)
	var sway: float=0.0 if g.quieter_motion else sin(g.elapsed*.7+plant.pos.x)*.012
	draw_sprite(g,int(plant.kind),at,height,1.0,sway)
