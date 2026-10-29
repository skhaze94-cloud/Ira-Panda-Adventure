extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
	for frame in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("IRA_CAPTURE_DIR").path_join(name+".png"))
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.set_process(false);game.music_enabled=false;game.sound_enabled=false
	game.menu_audio.stop();game.game_audio.stop()
	for chapter in range(5):
		game.start_level(chapter);game.bats.clear();game.quieter_motion=true
		game.conversation.clear_notices();game.opening.label.hide()
		for view in range(3):
			var x: float=7.0 if view==0 else game.botany.plants[0].pos.x if view==1 else float(game.BASE_LEVELS[chapter].size)*.66
			game.player=Vector2(x,game._path_y(x))
			game.camera=game.size*Vector2(.5,.58)-Vector2((game.player.x-game.player.y)*game.tile,(game.player.x+game.player.y)*game.tile*.49)
			game.ground_layer.sync();game.queue_redraw();await shot("chapter-%d-view-%d"%[chapter+1,view+1])
	root.size=Vector2i(740,360);root.content_scale_size=Vector2i(740,360)
	await process_frame
	game.tile=clampf(game.size.x/20.0,38,58)
	game.player=game.npcs[0].pos+Vector2(.8,.8)
	game.camera=game.size*Vector2(.5,.55)-Vector2((game.player.x-game.player.y)*game.tile,(game.player.x+game.player.y)*game.tile*.49)
	game.ground_layer.sync();game.queue_redraw();await shot("compact-garden")
	game.queue_free();game=null;await process_frame;await create_timer(.2).timeout;quit()
