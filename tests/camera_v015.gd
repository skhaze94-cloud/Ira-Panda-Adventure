extends SceneTree
var game: Control
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:failures+=1;push_error(message)
func settle(seconds: float=3.0) -> void:
	for frame in range(int(seconds*60)):game.trail_camera.update(game,1.0/60)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.set_process(false);game.music_enabled=false;game.sound_enabled=false
	game.menu_audio.stop();game.game_audio.stop()
	game.start_level(0)
	for frame in range(8):await process_frame
	check(game.conversation.notice_panel.size.y<game.size.y*.4,"First discovery card remains excessively tall")
	game.conversation.clear_notices()
	game.player=Vector2(35,game._path_y(35));game.trail_camera.snap(game)
	for reveal in game.trail_camera.reveals:game.trail_camera.seen[reveal.id]=true
	var before: Vector2=game.camera
	game.player+=Vector2.ONE
	game.trail_camera.update(game,1.0/60)
	check(game.camera.distance_to(before)<10,"Follow starts with a jump")
	settle()
	var settled: Vector2=game.camera;settle()
	check(game.camera.distance_to(settled)<.2,"Stationary camera never settles")
	game._pause();before=game.camera
	game.trail_camera.update(game,.5)
	check(game.camera==before,"Camera drifts during pause")
	game._resume();game.player=game.npcs[0].pos;game.interact();before=game.camera
	game.trail_camera.update(game,.5)
	check(game.camera==before,"Camera drifts during dialogue")
	game.conversation.close()
	var positions: Array[Vector2]=[]
	for fps in [30,60,120]:
		game.player=Vector2(35,game._path_y(35));game.trail_camera.snap(game)
		var origin: Vector2=game.player
		game.velocity=Vector2(.5,.2)
		for frame in range(fps*2):
			game.player=origin+game.velocity*float(frame+1)/fps
			game.trail_camera.update(game,1.0/fps)
		positions.append(game.camera)
	check(positions[0].distance_to(positions[2])<3,"Camera follow varies excessively with frame rate")
	game.start_level(4);game.conversation.clear_notices()
	var reveal: Dictionary=game.trail_camera.reveals[0]
	game.player=reveal.pos+Vector2(4,0);game.trail_camera.snap(game)
	game.trail_camera.seen.erase(reveal.id);game.trail_camera.rest=0
	settle(1.3)
	check(not game.trail_camera.active.is_empty(),"Crossing reveal failed")
	check(game.trail_camera.scenic_offset.length()>1 and game.trail_camera.scenic_offset.length()<=64,"Scenic reveal is missing or unbounded")
	check(game.state=="play","Reveal locks gameplay")
	settle(3)
	check(game.trail_camera.active.is_empty() and game.trail_camera.seen.has(reveal.id),"Reveal does not finish / remember visit")
	game.quieter_motion=true;game.velocity=Vector2.ONE
	game.trail_camera.update(game,1.0/60)
	check(game.camera_lead==Vector2.ZERO and game.trail_camera.scenic_offset==Vector2.ZERO,"Gentler Motion retains camera flourish")
	check(game._project(game.player).distance_to(game.trail_camera.safe_feet(game).get_center())<.1,"Gentler Motion failed to frame Ara")
	game.quieter_motion=false
	for dims in [Vector2i(1280,720),Vector2i(740,360)]:
		root.size=dims;root.content_scale_size=dims;await process_frame;await process_frame
		game.tile=clampf(game.size.x/20,38,58)
		for chapter in range(5):
			game.start_level(chapter);game.conversation.clear_notices()
			game.player=game.npcs[0].pos+Vector2(1.1,.2);game.trail_camera.snap(game);settle()
			check(game.trail_camera.safe_feet(game).grow(.1).has_point(game._project(game.player)),"Ara leaves HUD safe corridor")
			for foot in [game._project(game.player),game._project(game.npcs[0].pos)]:
				check(Rect2(Vector2(0,126),game.size-Vector2(0,126)).has_point(foot),"Character cropped by viewport")
		game.conversation.clear_notices();game.trail_camera.snap(game);settle()
		before=game.camera
		game.show_toast("A friendly discovery appears while little paws are exploring. The camera should make room gently, without suddenly jumping above a taller caption.",4)
		await process_frame;game.conversation._process(.01)
		game.trail_camera.update(game,1.0/60)
		check(game.camera.distance_to(before)<10,"A new caption jolts the camera")
		game.conversation.clear_notices()
		game.world_label_boxes.clear()
		var first: Rect2=game._place_world_label(Rect2(Vector2(game.size.x*.5-80,game.size.y*.5),Vector2(160,24)))
		var second: Rect2=game._place_world_label(first)
		check(not first.has_area() or not second.has_area() or not first.intersects(second),"World prompts overlap")
	game.queue_free();game=null;await process_frame;await create_timer(.2).timeout
	print("CAMERA V0.15 FAILURES: ",failures);quit(failures)
