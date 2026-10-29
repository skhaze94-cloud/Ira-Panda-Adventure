extends SceneTree
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
	for frame in range(12):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("IRA_CAPTURE_DIR").path_join(name+".png"))
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.music_enabled=false;game.sound_enabled=false;game.menu_audio.stop();game.game_audio.stop()
	game.start_level(0);game.bats.clear()
	game.conversation.clear_notices()
	game.player=game.npcs[0].pos+Vector2(.7,.7)
	game.camera=game.size*Vector2(.5,.55)-Vector2((game.player.x-game.player.y)*game.tile,(game.player.x+game.player.y)*game.tile*.49)
	await shot("selected-pip")
	game._request_destination(game.player+Vector2(2,2))
	await shot("tap-route")
	root.size=Vector2i(740,360);root.content_scale_size=Vector2i(740,360)
	game._cancel_navigation();game._request_destination(game.player+Vector2(1,1))
	await shot("compact-route")
	game.queue_free();game=null;await process_frame;await create_timer(.2).timeout;quit()
