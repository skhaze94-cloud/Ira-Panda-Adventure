extends SceneTree
var game: Control
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func walk_to(point: Vector2) -> void:
	game._request_destination(point)
	for frame in range(12000):
		if not game.has_destination:break
		game._advance_movement(Vector2.ZERO,1.0/60)
		check(not game._blocked(game.player),"Walked into scenery")
	check(game.player.distance_to(point)<.25,"Destination not reached")
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.set_process(false);game.music_enabled=false;game.sound_enabled=false
	game.menu_audio.stop();game.game_audio.stop()
	game.start_level(0)
	var home: Vector2=Vector2(3,game._path_y(3))
	game.player=home;game._reset_controls()
	game._advance_movement(Vector2.RIGHT,.025)
	check(game.velocity.length()>0 and game.velocity.length()<game.SPEED,"Walking start is not gradual")
	game._advance_movement(Vector2.ZERO,.2)
	check(game.velocity.length()<.001,"Walking does not stop")
	var speeds: Array=[]
	for axis in [Vector2.RIGHT,Vector2(1,1),Vector2(.25,0)]:
		game.player=home;game._reset_controls()
		game._advance_movement(axis,.2);speeds.append(game.velocity.length())
	check(absf(speeds[0]-speeds[1])<.08,"Diagonal gains extra speed")
	check(speeds[2]<speeds[0]*.4 and speeds[2]>0,"Joystick strength ignored")
	game.player=home;game._reset_controls()
	game._request_destination(home+Vector2(2,2))
	check(game.has_destination,"Tap ignored")
	game._hold_direction(999,Vector2.LEFT,true)
	check(not game.has_destination and not game.pending_destination and game.route.is_empty() and game.destination_status=="","Touch takeover retains old route")
	game._hold_direction(999,Vector2.LEFT,false)
	game._request_destination(home+Vector2(2,2));game._advance_movement(Vector2.RIGHT,.01)
	check(not game.has_destination and not game.pending_destination,"Keyboard takeover retains old route")
	game._reset_controls();game.player=home
	game._request_destination(home+Vector2(.5,.5))
	check(game.velocity.length()==0,"Tap teleports to full speed")
	walk_to(home+Vector2(.5,.5))
	check(game.destination_status=="arrived","Arrival feedback missing")
	game._ensure_navigation();game._request_destination(Vector2(-20,-20))
	check(not game.has_destination and game.destination_status=="blocked","Blocked destination not indicated")
	# Cluster fixtures: closest target wins independently of its category.
	game.start_level(0);game.player=home
	game.npcs.resize(1);game.npcs[0].pos=home+Vector2(.6,.6)
	for chest in game.beauty.chests:chest.pos=Vector2(60,60)
	game.objects.items=[{"index":0,"kind":"pumpkin","pos":home+Vector2(.2,.2),"found":false,"response":0.0,"branch":0}]
	check(game._interaction_target().kind=="object","Nearest object not selected")
	game.interact();check(game.objects.items[0].found and not game.npcs[0].met,"Action differs from highlighted object")
	game.objects.items[0].pos=Vector2(60,60)
	game.beauty.chests[0].pos=home+Vector2(1.2,1.2)
	check(game._interaction_target().kind=="npc","Farther chest steals nearby NPC")
	var tap:=InputEventScreenTouch.new();tap.pressed=true;tap.position=game._project(game.npcs[0].pos)
	game._gui_input(tap)
	check(game.npcs[0].met and game.conversation.active,"Touch did not activate highlighted NPC")
	game.conversation.close()
	game.beauty.chests[0].pos=Vector2(60,60)
	game.npcs[0].pos=home+Vector2.ONE.normalized()*2.55
	check(game._interaction_target().kind=="npc","Comfortable NPC range missing")
	var trunk: Vector2=home.lerp(game.npcs[0].pos,.5)
	game.tree_cells={Vector2i(floori(trunk.x),floori(trunk.y)):[trunk]}
	check(game._interaction_target().is_empty(),"Interaction crosses a solid trunk")
	game.queue_free();game=null;await process_frame;await create_timer(.2).timeout
	print("MOVEMENT V0.13 FAILURES: ",failures);quit(failures)
