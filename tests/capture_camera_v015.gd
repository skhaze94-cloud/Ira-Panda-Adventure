extends SceneTree
var game: Control
var directory: String
var frames: Array=[]
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
	game.ground_layer.sync();game.queue_redraw()
	for frame in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join(name+".png"))
	frames.append({"name":name,"ara":[game._project(game.player).x,game._project(game.player).y],"labels":game.world_label_boxes.size(),"scenic_offset":game.trail_camera.scenic_offset.length()})
func settle(seconds: float=3) -> void:
	for frame in range(int(seconds*60)):game.trail_camera.update(game,1.0/60)
func run() -> void:
	directory=OS.get_environment("IRA_CAPTURE_DIR")
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.set_process(false);game.conversation.set_process(false)
	game.music_enabled=false;game.sound_enabled=false;game.menu_audio.stop();game.game_audio.stop()
	for dims in [Vector2i(1280,720),Vector2i(740,360)]:
		root.size=dims;root.content_scale_size=dims;await process_frame;await process_frame
		game.tile=clampf(game.size.x/20,38,58)
		for chapter in range(5):
			game.start_level(chapter);game.conversation.clear_notices()
			game.player=game.npcs[0].pos+Vector2(1.6,-.2);game.trail_camera.snap(game);settle()
			await shot("%d-chapter-%d-guide"%[dims.x,chapter+1])
		game.start_level(4);game.conversation.clear_notices()
		var reveal: Dictionary=game.trail_camera.reveals[0]
		game.player=reveal.pos+Vector2(4,0);game.trail_camera.snap(game)
		game.trail_camera.seen.erase(reveal.id);game.trail_camera.rest=0
		await shot("%d-bridge-before"%dims.x)
		settle(1.3);await shot("%d-bridge-reveal"%dims.x)
		settle(3);await shot("%d-bridge-after"%dims.x)
		game.player=Vector2(52,game._path_y(52));game.trail_camera.snap(game)
		game.conversation.clear_notices();settle();await shot("%d-garden-labels"%dims.x)
		game.show_toast("A little light, a little room to explore. Ira is just ahead.",4)
		settle();await shot("%d-caption-framing"%dims.x)
		game.quieter_motion=true;settle();await shot("%d-gentler-motion"%dims.x)
		game.quieter_motion=false
		game.start_level(4);game.quest_done=true;game.player=game._exit()
		game._complete_chapter();game.conversation.close()
		await shot("%d-result-layout"%dims.x)
		if not game.modal_text.get_parent().get_parent().get_global_rect().encloses(game.modal_text.get_global_rect()):push_error("Result score needs scrolling at the default text size")
	var file:=FileAccess.open(directory.path_join("framing.json"),FileAccess.WRITE);file.store_string(JSON.stringify(frames,"\t"))
	game.queue_free();game=null;await process_frame;await create_timer(.2).timeout;quit()
