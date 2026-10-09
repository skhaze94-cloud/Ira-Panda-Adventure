extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.music_enabled = false
	game.menu_audio.stop()
	game.game_audio.stop()
	for chapter in range(5):
		game.start_level(chapter)
		for quality in range(3):
			game.set_graphics_quality(quality)
			game.atmosphere._process(0)
			game.ground_layer.sync()
			check(game.atmosphere.finish.visible==(quality>0),"Finish pass quality mismatch")
			check(game.ground_layer.surface.get_shader_parameter("chapter")==chapter,"Terrain chapter mismatch")
			check(is_equal_approx(game.ground_layer.surface.get_shader_parameter("water_center"),game._station().x+1.4),"Water misses authored crossing")
		game.body_lean = 0.0
		game.facing = 1
		game.pulse = game.GLOW_TIME*0.5
		var right: Vector2 = game._lantern_tip()-game._ara_root()
		game.facing = -1
		var left: Vector2 = game._lantern_tip()-game._ara_root()
		check(right.distance_to(Vector2(-left.x,left.y))<0.001,"Mirrored lantern no longer follows sleeve")
		var local := Vector2(14,-51)
		var pivot: Vector2 = game._ara_root()+Vector2(0,-32)
		var radius := (local-Vector2(0,-32)).length()
		for lean in [-0.12,0.0,0.12]:
			game.body_lean = lean
			check(absf(game._ara_frame(local).distance_to(pivot)-radius)<0.001,"Shoulder separates from shared torso frame")
		var plant: Dictionary = game.light_trails.plants[0]
		game.player = plant.pos
		game.light_trails.shine()
		check(plant.awake and plant.bloom==0.0,"Bloom must begin closed")
		game.light_trails.update(0.4)
		check(is_equal_approx(plant.bloom,0.5),"Bloom transition duration changed")
		game.state = "dialog"
		game.light_trails.update(1.0)
		check(is_equal_approx(plant.bloom,0.5),"Bloom animation advanced during dialogue")
		game.state = "play"
		game.quieter_motion = true
		game.light_trails.update(0.01)
		game.ground_layer.sync()
		game.atmosphere._process(0)
		check(plant.bloom==1.0,"Gentler Motion should show completed bloom")
		check(game.ground_layer.surface.get_shader_parameter("clock")==0.0,"Gentler Motion water still animates")
		check(game.atmosphere.air.get_shader_parameter("clock")==0.0,"Gentler Motion air still animates")
		game.quieter_motion = false
		print("MASTERCLASS CHECKED CHAPTER ",chapter+1)
	game.queue_free()
	await process_frame
	print("MASTERCLASS FAILURES: ",failures)
	quit(0 if failures==0 else 1)
