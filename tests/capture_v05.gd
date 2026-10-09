extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.music_enabled = false
	game.menu_audio.stop()
	game.game_audio.stop()
	var directory := OS.get_environment("IRA_CAPTURE_DIR")
	if directory.is_empty(): directory = "user://v05-captures"
	DirAccess.make_dir_recursive_absolute(directory)
	for chapter in range(5):
		game.start_level(chapter)
		game.bats.clear()
		game.player = game.npcs[0].home+Vector2(1,0)
		game.camera = game.size*Vector2(0.5,0.55)-Vector2((game.player.x-game.player.y)*game.tile,(game.player.x+game.player.y)*game.tile*0.49)
		game.glow()
		for frame in range(6): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory.path_join("npc-%d.png" % chapter))
	for chapter in range(5):
		game.start_level(chapter)
		game.bats.clear()
		var prop: Dictionary = game.ambience.scenery[game.ambience.scenery.size()-1]
		game.player = prop.pos-Vector2(1.5,0)
		game.camera = game.size*Vector2(0.5,0.55)-Vector2((game.player.x-game.player.y)*game.tile,(game.player.x+game.player.y)*game.tile*0.49)
		for frame in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory.path_join("scenery-%d.png" % chapter))
	game.start_level(0)
	for i in range(game.npcs.size()):
		game.player = game.npcs[i].home+Vector2(-1,0)
		game.camera = game.size*Vector2(0.5,0.55)-Vector2((game.player.x-game.player.y)*game.tile,(game.player.x+game.player.y)*game.tile*0.49)
		for frame in range(6): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory.path_join("neighbour-%d.png" % i))
	game._open_options()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join("options.png"))
	game.queue_free()
	await process_frame
	quit()

