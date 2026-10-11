extends SceneTree
var game: Control
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures+=1
		push_error(message)
func _initialize() -> void: call_deferred("run")
func walk_to(target: Vector2) -> void:
	game._request_destination(target)
	check(game.has_destination,"Cannot route to crossing approach "+str(target))
	for frame in range(18000):
		if not game.has_destination: break
		game._advance_movement(Vector2.ZERO,1.0/60.0)
		if game._blocked(game.player):
			check(false,"Walking entered water, wood or forest")
			break
	check(game.player.distance_to(target)<0.2,"Did not reach crossing approach "+str(target)+" from "+str(game.player)+" chapter "+str(game.level_index)+" obstacles "+str(game.pathways.obstacles))
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.music_enabled=false
	game.sound_enabled=false
	game.menu_audio.stop();game.game_audio.stop()
	for chapter in range(5):
		game.start_level(chapter)
		var total_length := 0.0
		var prev: Vector2 = game.player
		for i in range(3,int(game._exit().x*4)):
			var x := float(i)/4.0
			var p := Vector2(x,game._path_y(x))
			total_length+=p.distance_to(prev)
			prev=p
		check(total_length>game.player.distance_to(game._exit())*1.1,"Chapter lacks substantial winding travel")
		for c in game.pathways.crossings:
			if c.kind=="repair": continue
			var near_x: float = c.x-c.width-0.6
			var far_x: float = c.x+c.width+0.6
			var near := Vector2(near_x,game._path_y(near_x)+c.offset)
			var far := Vector2(far_x,game._path_y(far_x)+c.offset)
			walk_to(near);walk_to(far);walk_to(near)
			check(game._blocked(c.pos+Vector2(0,c.offset+2.3)),"Stream bank can be bypassed")
			check(not game._blocked(c.pos+Vector2(0,c.offset)),"Crossing deck is blocked")
		for o in game.pathways.obstacles:
			check(game._blocked(o.pos),"Obstacle is purely decorative")
		for m in game.marks:
			check(not game._blocked(m.pos),"Obstacle covers a quest object")
		print("PATHWAYS CROSSINGS CHECKED CHAPTER ",chapter+1)
	game.start_level(1)
	game.player=game.pathways.web_position()
	check(game.pathways.pace(game.player)<1.0,"Web should gently slow Ara")
	check(not game._blocked(game.player),"Web hard-locks travel")
	game.cooldown=0;game.glow()
	check(game.pathways.web_clear and game.pathways.pace(game.player)==1.0,"Glow fails to clear web slow-down")
	game.pathways.update(0.3)
	check(game.pathways.web_fade>0 and game.pathways.web_fade<1,"Web dissolve is missing")
	game.quieter_motion=true;game.pathways.update(0.01)
	check(game.pathways.web_fade==0,"Gentler Motion fails to complete web dissolve")
	game.start_level(1)
	check(not game.pathways.web_clear and game.pathways.seen.is_empty(),"Restart retains pathway discoveries")
	game.queue_free();await process_frame
	print("PATHWAY FAILURES: ",failures)
	quit(failures)
