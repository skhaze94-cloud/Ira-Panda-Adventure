extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.music_enabled = false
	game.menu_audio.stop()
	game.game_audio.stop()
	var output := OS.get_environment("IRA_CAPTURE_DIR")
	if output.is_empty(): output = "user://v04-captures"
	DirAccess.make_dir_recursive_absolute(output)
	for chapter in range(5):
		game.start_level(chapter)
		var stone: Dictionary = game.light_trails.stones[0]
		game.player = stone.stand
		game.camera_lead = Vector2.ZERO
		game.camera = game.size*Vector2(0.5,0.55)-Vector2((game.player.x-game.player.y)*game.tile,(game.player.x+game.player.y)*game.tile*0.49)
		for i in range(5): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("chapter-%d-before.png" % (chapter+1)))
		game.glow()
		for i in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("chapter-%d-lit.png" % (chapter+1)))
		if chapter == 0:
			var plant: Dictionary = game.light_trails.plants[0]
			game.player = plant.pos+Vector2(-0.8,-0.8)
			game.heart = 2
			game.camera = game.size*Vector2(0.5,0.55)-Vector2((game.player.x-game.player.y)*game.tile,(game.player.x+game.player.y)*game.tile*0.49)
			game.cooldown = 0
			game.glow()
			for i in range(8): await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join("bloom-awake.png"))
		if chapter == 3:
			var sequence: Dictionary = game.light_trails.stones[3]
			game.player = sequence.stand
			game.camera = game.size*Vector2(0.5,0.55)-Vector2((game.player.x-game.player.y)*game.tile,(game.player.x+game.player.y)*game.tile*0.49)
			game.cooldown = 0
			game.glow()
			for i in range(8): await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join("rune-order-clue.png"))
	game.queue_free()
	await process_frame
	quit()
