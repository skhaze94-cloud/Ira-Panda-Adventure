extends ColorRect
## One textured ground draw; no per-cell geometry or repeated light passes.
var game: Control
var surface: ShaderMaterial
var last_chapter := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = -1
	show_behind_parent = true
	surface = ShaderMaterial.new()
	surface.shader = load("res://shaders/woodland_ground.gdshader")
	material = surface
	var crops: Array[Vector4] = []
	for rect in game.GROUND_RECTS: crops.append(Vector4(rect[0],rect[1],rect[2],rect[3]))
	surface.set_shader_parameter("crops",crops)
	surface.set_shader_parameter("atlas",game.tex["ground-v2"])
	surface.set_shader_parameter("atlas_size",game.tex["ground-v2"].get_size())

func sync() -> void:
	visible = game.state in ["play","dialog","win"]
	if not visible: return
	size = game.size
	if last_chapter != game.level_index:
		last_chapter = game.level_index
		surface.set_shader_parameter("chapter",last_chapter)
		surface.set_shader_parameter("map_size",float(game.BASE_LEVELS[last_chapter].size))
		surface.set_shader_parameter("route_offsets",PackedFloat32Array(game.pathways.OFFSETS[last_chapter]))
		var crossings: Array[Vector4] = []
		for c in game.pathways.crossings: crossings.append(Vector4(c.x,c.width,0,0))
		while crossings.size()<3: crossings.append(Vector4.ZERO)
		surface.set_shader_parameter("crossings",crossings)
		surface.set_shader_parameter("crossing_count",game.pathways.crossings.size())
		surface.set_shader_parameter("ambient_tint",game.atmosphere.AMBIENT[last_chapter].lightened(0.12))
	surface.set_shader_parameter("viewport_size",game.size)
	surface.set_shader_parameter("camera_offset",game.camera)
	surface.set_shader_parameter("tile_size",game.tile)
	surface.set_shader_parameter("player_world",game.player)
	surface.set_shader_parameter("pulse",game.pulse)
	surface.set_shader_parameter("clock",0.0 if game.quieter_motion else game.elapsed)
	surface.set_shader_parameter("water_center",game._station().x+1.4)
	surface.set_shader_parameter("detail",float(game.graphics_quality))
	var pools: Array[Vector4] = []
	var colors: Array[Vector3] = []
	var sources: Array = []
	for lamp in game.lanterns:
		if lamp.pos.distance_squared_to(game.player) < 65:
			sources.append({"pos":lamp.pos,"color":Color("#9ad9ff") if lamp.get("blue",false) else game.COLORS[last_chapter]})
	for plant in game.light_trails.plants:
		if plant.awake and plant.pos.distance_squared_to(game.player) < 65:
			sources.append({"pos":plant.pos,"color":Color("#94ffe1")})
	sources.sort_custom(func(a,b): return a.pos.distance_squared_to(game.player)<b.pos.distance_squared_to(game.player))
	var count := mini(sources.size(),6)
	for i in range(6):
		var col: Color = sources[i].color if i < count else Color.BLACK
		var pos: Vector2 = sources[i].pos if i < count else Vector2.ZERO
		pools.append(Vector4(pos.x,pos.y,0.9 if i < count else 0.0,2.5))
		colors.append(Vector3(col.r,col.g,col.b))
	surface.set_shader_parameter("pools",pools)
	surface.set_shader_parameter("pool_colors",colors)
	surface.set_shader_parameter("pool_count",count)
