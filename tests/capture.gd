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
	var capture_dir := OS.get_environment("IRA_CAPTURE_DIR")
	if capture_dir.is_empty(): capture_dir = "user://v03-captures"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	for chapter in range(5):
		game.start_level(chapter)
		var x: float = [26.0,39.0,65.0,70.0,79.0][chapter]
		game.player = Vector2(x,game._path_y(x))
		if chapter == 2: game.player = Vector2(game._station().x-2,game._path_y(game._station().x-2))
		if chapter == 3: game.player = Vector2(70,game._path_y(70))
		if chapter == 4: game.player = Vector2(79,game._path_y(79))
		game.camera = game.size * Vector2(0.5,0.55)-Vector2((game.player.x-game.player.y)*game.tile,(game.player.x+game.player.y)*game.tile*0.49)
		game.has_destination = false
		game.mobile_axis = Vector2.ZERO
		game.facing = 1
		for frame in range(10): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(capture_dir.path_join("level-%d.png" % (chapter+1)))
		game.facing = -1
		for frame in range(3): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(capture_dir.path_join("level-%d-left.png" % (chapter+1)))
		if chapter == 2 or chapter == 4:
			game.quest_done = true
			game.quest_count = 3
			for frame in range(5): await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(capture_dir.path_join("level-%d-complete.png" % (chapter+1)))
	game.queue_free()
	await process_frame
	quit()
