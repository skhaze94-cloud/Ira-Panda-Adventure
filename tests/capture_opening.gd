extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(game: Control, name: String) -> void:
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("IRA_CAPTURE_DIR").path_join(name+".png"))
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.music_enabled=false;game.sound_enabled=false
	game.menu_audio.stop();game.game_audio.stop()
	game.start_level(0);await shot(game,"first-step")
	game.player=game.opening.ribbon;game.opening.update();await shot(game,"ribbon-found")
	root.size=Vector2i(740,360);root.content_scale_size=Vector2i(740,360)
	await shot(game,"compact-opening")
	game.queue_free();await process_frame;await create_timer(.2).timeout;quit()
