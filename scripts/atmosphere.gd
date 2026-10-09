extends Node2D
## Native 2D lights, trunk occluders, procedural air, and fireflies.
## Bounded pools avoid creating a node per tree in the large level maps.
const AMBIENT = [Color("#8e9eb5"),Color("#9693b7"),Color("#86aab7"),Color("#898bab"),Color("#b2a2ac")]
const MIST = [Color("#94b5c7"),Color("#bda4dd"),Color("#87cfda"),Color("#a7afe8"),Color("#e5c2ce")]
var game: Control
var ambient: CanvasModulate
var lights: Array[PointLight2D] = []
var occluders: Array[LightOccluder2D] = []
var fog: ColorRect
var air: ShaderMaterial
var motes: GPUParticles2D
var overlay: CanvasLayer
var finish: ColorRect
var finish_material: ShaderMaterial

func _ready() -> void:
	ambient = CanvasModulate.new()
	add_child(ambient)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0,0.18,0.50,1.0])
	gradient.colors = PackedColorArray([Color(1,1,1,1),Color(1,1,1,0.72),Color(1,1,1,0.22),Color(1,1,1,0)])
	var falloff := GradientTexture2D.new()
	falloff.gradient = gradient
	falloff.width = 256
	falloff.height = 256
	falloff.fill = GradientTexture2D.FILL_RADIAL
	falloff.fill_from = Vector2(0.5,0.5)
	falloff.fill_to = Vector2(1,0.5)
	for i in range(5):
		var light := PointLight2D.new()
		light.texture = falloff
		light.texture_scale = 1.0
		light.height = 55.0
		light.range_item_cull_mask = 1
		light.shadow_enabled = i == 0
		light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
		light.shadow_color = Color(0.05,0.08,0.16,0.36)
		add_child(light)
		lights.append(light)
	for i in range(36):
		var blocker := LightOccluder2D.new()
		var polygon := OccluderPolygon2D.new()
		polygon.polygon = PackedVector2Array([Vector2(-7,-3),Vector2(0,-10),Vector2(7,-3),Vector2(0,4)])
		blocker.occluder = polygon
		add_child(blocker)
		occluders.append(blocker)
	overlay = CanvasLayer.new()
	overlay.layer = 1
	add_child(overlay)
	fog = ColorRect.new()
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	air = ShaderMaterial.new()
	air.shader = load("res://shaders/moonlit_air.gdshader")
	fog.material = air
	overlay.add_child(fog)
	motes = GPUParticles2D.new()
	motes.texture = falloff
	motes.amount = 40
	motes.lifetime = 7.0
	motes.preprocess = 7.0
	motes.randomness = 0.7
	var motion := ParticleProcessMaterial.new()
	motion.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	motion.emission_box_extents = Vector3(640,360,0)
	motion.direction = Vector3(0,-1,0)
	motion.spread = 55.0
	motion.gravity = Vector3.ZERO
	motion.initial_velocity_min = 3.0
	motion.initial_velocity_max = 10.0
	motion.scale_min = 0.009
	motion.scale_max = 0.022
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0,0.2,0.75,1])
	fade.colors = PackedColorArray([Color(1,1,1,0),Color(1,1,1,0.65),Color(1,1,1,0.45),Color(1,1,1,0)])
	var fade_texture := GradientTexture1D.new()
	fade_texture.gradient = fade
	motion.color_ramp = fade_texture
	motes.process_material = motion
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	unlit.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	motes.material = unlit
	overlay.add_child(motes)
	var finish_layer := CanvasLayer.new()
	finish_layer.layer = 2
	add_child(finish_layer)
	finish = ColorRect.new()
	finish.mouse_filter = Control.MOUSE_FILTER_IGNORE
	finish_material = ShaderMaterial.new()
	finish_material.shader = load("res://shaders/storybook_finish.gdshader")
	finish.material = finish_material
	finish_layer.add_child(finish)

func _process(_dt: float) -> void:
	var active: bool = game.state in ["play","dialog","win"]
	ambient.color = AMBIENT[game.level_index] if active else Color.WHITE
	fog.visible = active
	fog.size = game.size
	finish.size = game.size
	finish.visible = active and game.graphics_quality > 0
	finish_material.set_shader_parameter("quality",float(game.graphics_quality))
	finish_material.set_shader_parameter("palette",game.COLORS[game.level_index])
	air.set_shader_parameter("rays_amount",[0.025,0.04,0.055][game.graphics_quality])
	air.set_shader_parameter("clock",0.0 if game.quieter_motion else game.elapsed)
	air.set_shader_parameter("mist_tint",MIST[game.level_index])
	air.set_shader_parameter("mist_amount",0.07 if game.level_index == 2 else 0.045)
	air.set_shader_parameter("drift",game.camera / Vector2(8000,8000))
	motes.visible = active and not game.quieter_motion
	motes.emitting = active and not game.quieter_motion and game.state == "play"
	motes.speed_scale = 1.0 if game.state == "play" else 0.0
	motes.position = game.size * 0.5
	var motion := motes.process_material as ParticleProcessMaterial
	motion.emission_box_extents = Vector3(game.size.x*0.5,game.size.y*0.5,0)
	motion.color = MIST[game.level_index].lightened(0.3)
	for light in lights: light.enabled = false
	for blocker in occluders: blocker.visible = false
	if not active: return
	var player_light := lights[0]
	player_light.enabled = true
	player_light.position = game._lantern_tip()
	player_light.color = game.COLORS[game.level_index]
	player_light.energy = 0.78 + game.pulse * 0.65
	player_light.texture_scale = 1.05 + game.pulse * 0.45
	# Select nearest visible lights, giving quest objects priority.
	var sources: Array = []
	if game.light_trails != null:
		for plant in game.light_trails.plants:
			if plant.awake:
				sources.append({"at":game._project(plant.pos)-Vector2(0,34),"color":Color("#94ffe1"),"energy":0.7})
		for stone in game.light_trails.stones:
			if stone.time > 0:
				sources.append({"at":game._project(stone.pos)-Vector2(0,20),"color":Color("#ffe5a3"),"energy":0.5})
	for m in game.marks:
		if not m.lit or game.level_index == 4:
			sources.append({"at":game._project(m.pos)-Vector2(0,25),"color":MIST[game.level_index],"energy":0.42})
	for rune in game.runes:
		sources.append({"at":game._project(rune.pos)-Vector2(0,55),"color":Color("#ffebb0") if rune.lit else Color("#a8b5ff"),"energy":0.42})
	for lamp in game.lanterns:
		var h: float = game.tile * (1.75 if int(lamp.variant) else 2.7)
		var at: Vector2 = game._project(lamp.pos)-Vector2(0,h*0.72)
		if not game._visible(at,180): continue
		var flicker: float = 1.0 if game.quieter_motion else 0.96+sin(game.elapsed*3.2+lamp.phase)*0.04
		sources.append({"at":at,"color":Color("#9ad9ff") if lamp.get("blue",false) else game.COLORS[game.level_index],"energy":0.52*flicker})
	sources.append({"at":game._project(game._exit())-Vector2(0,65),"color":game.COLORS[game.level_index],"energy":0.65})
	sources.sort_custom(func(a,b): return a.at.distance_squared_to(player_light.position)<b.at.distance_squared_to(player_light.position))
	var li := 1
	for source in sources:
		if li >= [2,3,5][game.graphics_quality]: break
		if not game._visible(source.at,180): continue
		lights[li].enabled = true
		lights[li].position = source.at
		lights[li].color = source.color
		lights[li].energy = source.energy
		lights[li].texture_scale = 0.78
		li += 1
	var oi := 0
	for tree in game.visible_trees:
		if game.graphics_quality < 2: break
		if tree.pos.distance_squared_to(game.player) > 20: continue
		if oi >= occluders.size(): break
		occluders[oi].visible = true
		occluders[oi].position = game._project(tree.pos)
		oi += 1

func apply_quality(index: int) -> void:
	if lights.is_empty(): return
	lights[0].shadow_enabled = index == 2
	motes.amount = [12,24,40][index]
