extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.music_enabled = false
	game.menu_audio.stop()
	game.game_audio.stop()
	var directory := OS.get_environment("IRA_CAPTURE_DIR")
	if directory.is_empty(): directory = "user://masterclass-captures"
	DirAccess.make_dir_recursive_absolute(directory)
	for quality in range(3):
		game.set_graphics_quality(quality)
		for chapter in range(5):
			game.start_level(chapter)
			game.bats.clear()
			var x: float = [7.5,39.0,43.0,70.0,79.0][chapter]
			game.player = Vector2(x,game._path_y(x))
			game.camera = game.size*Vector2(0.5,0.55)-Vector2((game.player.x-game.player.y)*game.tile,(game.player.x+game.player.y)*game.tile*0.49)
			game.elapsed = 3.5
			game.pulse = 0.0
			game.walk_dir = Vector2.ZERO
			game.body_lean = 0.0
			game.facing = 1
			game.toast_seconds = 0.0
			game.light_trails.shine()
			game.light_trails.update(1.0)
			game.ground_layer.sync()
			game.queue_redraw()
			for frame in range(3): await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(directory.path_join("quality-%d-chapter-%d.png" % [quality,chapter+1]))
			game.facing = -1
			game.body_lean = 0.045
			game.walk_dir = Vector2.ONE.normalized()
			game.foot_time = 0.7
			game.pulse = game.GLOW_TIME*0.5
			game.ground_layer.sync()
			game.queue_redraw()
			for frame in range(3): await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(directory.path_join("quality-%d-chapter-%d-left-glow.png" % [quality,chapter+1]))
	game.queue_free()
	await process_frame
	quit()
