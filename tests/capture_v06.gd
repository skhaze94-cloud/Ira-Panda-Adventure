extends SceneTree
var game: Control
var directory := "user://v06-captures"
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for frame in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join(name+".png"))
func place(p: Vector2) -> void:
	game.player=p;game.bats.clear();game._reset_controls()
	game.camera=game.size*Vector2(.5,.55)-Vector2((p.x-p.y)*game.tile,(p.x+p.y)*game.tile*.49)
func run() -> void:
	if not OS.get_environment("IRA_CAPTURE_DIR").is_empty(): directory=OS.get_environment("IRA_CAPTURE_DIR")
	DirAccess.make_dir_recursive_absolute(directory)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await process_frame
	game.music_enabled=false;game.sound_enabled=false;game.menu_audio.stop();game.game_audio.stop()
	await capture("menu")
	game._open_options();await capture("options");game._return_menu()
	for chapter in range(5):
		game.start_level(chapter)
		place(game.exploration.loops[0].pos);game.exploration.visit()
		await capture("secret-%d"%chapter)
		place(game.pathways.crossings[0].pos+Vector2(0,game.pathways.crossings[0].offset))
		await capture("crossing-%d"%chapter)
	game.start_level(2);place(game._station());game.quest_done=true
	game.personality.react("repair",1.8);await capture("repair")
	await create_timer(2).timeout;await capture("repaired")
	game.start_level(4);game.quest_done=true;place(game._exit()-Vector2(2,2))
	game._complete_chapter();game.quieter_motion=true
	while game.conversation.active: game.conversation.advance()
	await create_timer(.3).timeout;await capture("reunion")
	game._return_menu();await capture("continue")
	root.size=Vector2i(854,480);await process_frame
	await capture("compact-menu");game._open_options();await capture("compact-options")
	game.start_level(1);place(game.pathways.web_position());await capture("compact-play")
	# Run audio for actual frames, validate bounded voices and mute.
	game.sound_enabled=true;game.soundscape.play("pickup");game.soundscape.play("rune-0")
	await create_timer(.8).timeout
	assert(game.soundscape.voices.size()==8 and game.soundscape.clips.size()==20)
	var played: int=game.soundscape.played
	game.sound_enabled=false;game.soundscape.silence();game.soundscape.play("glow")
	assert(game.soundscape.played==played)
	await create_timer(.15).timeout
	game.queue_free();await process_frame;await process_frame
	print("CAPTURE / AUDIO FAILURES: 0");quit()
