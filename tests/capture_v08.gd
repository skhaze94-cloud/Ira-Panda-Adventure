extends SceneTree
var game: Control
var directory: String
func _initialize() -> void: call_deferred("run")
func place(p: Vector2) -> void:
	game.player=p;game.bats.clear();game._reset_controls()
	game.camera=game.size*Vector2(.5,.55)-Vector2((p.x-p.y)*game.tile,(p.x+p.y)*game.tile*.49)
func capture(name: String) -> void:
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join(name+".png"))
func run() -> void:
	directory=OS.get_environment("IRA_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(directory)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.music_enabled=false;game.sound_enabled=false;game.menu_audio.stop();game.game_audio.stop()
	await capture("menu")
	for chapter in range(5):
		game.start_level(chapter)
		place(game.beauty.chests[1].pos-Vector2(1.5,1.5));await capture("chapter-%d-treasure"%chapter)
		place(game.beauty.chests[1].pos);game.interact();await create_timer(.6).timeout;await capture("chapter-%d-open"%chapter)
		place(game.beauty.paths[0].points[1]);await capture("chapter-%d-stars"%chapter)
	game.journal.data.unlocked=4;game.journal.data.best_scores=[400,270,400,160,400];game._return_menu();game._open_album();await capture("album")
	root.size=Vector2i(854,480);await process_frame;game._layout_ui();await capture("compact-album")
	game._resume();await capture("compact-title")
	game.start_level(4);place(game.beauty.chests[1].pos);game._pause();await capture("compact-pause")
	game.queue_free();await process_frame;await process_frame
	print("V0.8 NATIVE CAPTURES COMPLETE");quit()
