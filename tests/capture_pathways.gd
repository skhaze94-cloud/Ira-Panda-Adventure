extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.music_enabled = false
	game.sound_enabled = false
	game.menu_audio.stop();game.game_audio.stop()
	game.set_process(false)
	var directory := OS.get_environment("IRA_CAPTURE_DIR")
	if directory.is_empty(): directory="user://pathway-captures"
	DirAccess.make_dir_recursive_absolute(directory)
	for chapter in range(5):
		game.start_level(chapter)
		game.bats.clear()
		game.conversation.notice_left=0
		game.conversation.notice_panel.visible=false
		for view in range(4):
			game.quest_done = view==3
			var x: float = game.pathways.crossings[view%2].x
			if view==2: x=game.pathways.web_position().x if chapter==1 else game.pathways.obstacles[0].pos.x
			if view==3: x=game._station().x if chapter==2 else float(game.BASE_LEVELS[chapter].size)*0.52
			game.player=Vector2(x-1.8,game._path_y(x-1.8))
			if game._blocked(game.player): game.player.y+=2.5
			game.camera=game.size*Vector2(0.5,0.58)-Vector2((game.player.x-game.player.y)*game.tile,(game.player.x+game.player.y)*game.tile*0.49)
			game.visibility_camera=Vector2(INF,INF)
			game._refresh_visible_trees();game.ground_layer.sync();game.queue_redraw()
			for frame in range(5): await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(directory.path_join("chapter-%d-view-%d.png" % [chapter+1,view+1]))
	game.queue_free();await process_frame;quit()
