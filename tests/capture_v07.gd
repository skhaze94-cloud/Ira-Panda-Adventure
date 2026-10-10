extends SceneTree
var game: Control
var directory := "user://v07-captures"
func _initialize() -> void: call_deferred("run")
func place(p: Vector2) -> void:
	game.player=p;game.bats.clear();game._reset_controls()
	game.camera=game.size*Vector2(.5,.55)-Vector2((p.x-p.y)*game.tile,(p.x+p.y)*game.tile*.49)
func capture(name: String) -> void:
	for frame in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join(name+".png"))
func run() -> void:
	if not OS.get_environment("IRA_CAPTURE_DIR").is_empty(): directory=OS.get_environment("IRA_CAPTURE_DIR")
	DirAccess.make_dir_recursive_absolute(directory)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.music_enabled=false;game.sound_enabled=false;game.menu_audio.stop();game.game_audio.stop()
	await capture("menu")
	game.start_level(0)
	for npc in game.npcs:
		place(npc.home+Vector2(3.5,3.5));await create_timer(.5).timeout;await capture("routine-"+str(npc.id))
		place(npc.home+Vector2(-1,0));await capture("hello-"+str(npc.id))
	for chapter in range(5):
		game.start_level(chapter)
		place(game.living.clues[chapter%3].pos);await capture("clue-%d"%chapter)
		place(game.living.visitor.home+Vector2(1.8,0));await capture("visitor-%d"%chapter)
		place(game.living.guide.points[1]);game.living.guide.active=true;game.living.guide.step=2;game.living.guide.pos=game.player
		await capture("guide-%d"%chapter)
	game.start_level(3);place(game.living.notes[1].pos);game.living.glow();await capture("musical-pebbles")
	game.start_level(0);place(game.living.leaves[0].pos);await capture("leaves")
	game.start_level(4);place(game._exit()-Vector2(3,3));await create_timer(2).timeout;await capture("cottage-warmth")
	root.size=Vector2i(854,480);await process_frame
	place(game.living.clues[0].pos);await capture("compact-clue")
	game._pause();await capture("compact-pause")
	game._resume();game.sound_enabled=true;game.soundscape.play("voice-moss");game.soundscape.play("rune-1")
	await create_timer(.8).timeout
	assert(game.soundscape.voices.size()==8 and game.soundscape.clips.size()==21 and game.soundscape.bed.playing)
	game.sound_enabled=false;game.soundscape.silence();await create_timer(.2).timeout
	assert(not game.soundscape.bed.playing and not game.soundscape.water.playing)
	game.queue_free();await process_frame;await process_frame
	print("V0.7 CAPTURE / AUDIO FAILURES: 0");quit()
