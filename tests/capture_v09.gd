extends SceneTree
var game: Control
var directory: String
func _initialize() -> void:call_deferred("run")
func place(p: Vector2) -> void:
	game.player=p;game.bats.clear();game._reset_controls()
	game.camera=game.size*Vector2(.5,.55)-Vector2((p.x-p.y)*game.tile,(p.x+p.y)*game.tile*.49)
func capture(name: String) -> void:
	for frame in range(6):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join(name+".png"))
func run() -> void:
	directory=OS.get_environment("IRA_CAPTURE_DIR")
	if directory.is_empty():directory="user://v09-captures"
	DirAccess.make_dir_recursive_absolute(directory)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.music_enabled=false;game.sound_enabled=false;game.menu_audio.stop();game.game_audio.stop()
	for chapter in range(5):
		game.start_level(chapter)
		var c: Dictionary=game.pathways.crossings[0]
		place(c.pos+Vector2(0,c.offset));game.conversation.clear_notices();await capture("bridge-%d"%chapter)
		for i in range(3):
			place(game.objects.items[i].pos-Vector2(.5,.5));game.conversation.clear_notices();await capture("object-%d-%d"%[chapter,i])
	game.start_level(2);place(game._station());game.conversation.clear_notices();await capture("repair-before")
	game.quest_count=3;game.interact();await create_timer(.3).timeout;await capture("repair-during")
	await create_timer(2).timeout;game.conversation.clear_notices();await capture("repair-after")
	root.size=Vector2i(854,480);await process_frame
	game.start_level(0);place(game.objects.items[1].pos);game.interact();await capture("compact-boo")
	game.queue_free();await process_frame;await process_frame
	print("V0.9 NATIVE CAPTURES COMPLETE");quit()
