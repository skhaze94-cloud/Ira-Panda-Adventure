extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.music_enabled = false
	game.sound_enabled = false
	game.menu_audio.stop()
	game.game_audio.stop()
	var directory := OS.get_environment("IRA_CAPTURE_DIR")
	if directory.is_empty(): directory = "user://quest-captures"
	DirAccess.make_dir_recursive_absolute(directory)
	for chapter in range(5):
		game.start_level(chapter)
		game.bats.clear()
		game.player = game.npcs[0].home+Vector2(0.5,0)
		game.camera = game.size*Vector2(0.5,0.52)-Vector2((game.player.x-game.player.y)*game.tile,(game.player.x+game.player.y)*game.tile*0.49)
		game.interact()
		game.conversation.caption.visible_characters = -1
		for frame in range(15): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory.path_join("chapter-%d-guide.png" % (chapter+1)))
		game.conversation.advance()
		game.conversation.caption.visible_characters = -1
		for frame in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory.path_join("chapter-%d-ara.png" % (chapter+1)))
		game.conversation.advance()
		game.conversation.caption.visible_characters = -1
		for frame in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory.path_join("chapter-%d-instruction.png" % (chapter+1)))
		game.conversation.close()
		game.quest_count = 3
		game._finish_quest()
		for frame in range(15): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory.path_join("chapter-%d-reward.png" % (chapter+1)))
	game.start_level(4)
	game.quest_done = true
	game._complete_chapter()
	game.conversation.caption.visible_characters = -1
	for frame in range(15): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join("reunion.png"))
	game.conversation.close()
	game.start_level(0)
	root.size = Vector2i(854,480)
	await process_frame
	game.player = game.npcs[0].home
	game.interact()
	game.conversation.caption.visible_characters = -1
	for frame in range(15): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join("compact.png"))
	game.queue_free()
	await process_frame
	quit()
