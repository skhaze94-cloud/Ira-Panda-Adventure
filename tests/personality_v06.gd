extends SceneTree
var game: Control
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func walk(target: Vector2) -> void:
	game._request_destination(target)
	for frame in range(20000):
		if not game.has_destination: break
		game._advance_movement(Vector2.ZERO,1.0/60)
	check(game.player.distance_to(target)<0.2,"Optional route unreachable: "+str(target))
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await process_frame
	game.set_process(false);game.music_enabled=false;game.sound_enabled=false
	game.menu_audio.stop();game.game_audio.stop()
	var profile: Array=[]
	for chapter in range(5):
		game.start_level(chapter);game.bats.clear()
		var begun := Time.get_ticks_usec()
		game._request_destination(game.exploration.loops[0].pos)
		var request_us := Time.get_ticks_usec()-begun
		check(request_us<30000,"Destination request blocks too long")
		for loop in game.exploration.loops:
			walk(loop.points[0]);walk(loop.points[1]);walk(loop.pos)
			game.heart=2;game.exploration.visit()
			check(game.exploration.found[loop.index] and game.heart==3,"Discovery reward absent")
			game.heart=2;game.exploration.visit();check(game.heart==2,"Reward can repeat")
			walk(loop.points[2]);walk(loop.points[3])
		check(not game.quest_done,"Optional loops complete required quest")
		profile.append({"chapter":chapter+1,"request_ms":request_us/1000.0,"navigation_work_ms":game.nav_work_us/1000.0,"max_slice_ms":game.nav_slice_us/1000.0})
	game.start_level(2);game.quest_done=true;game.personality.react("repair",1.8)
	var before: Vector2=game.player
	game._advance_movement(Vector2.RIGHT,.5)
	check(game.player==before and game.personality.repair>0 and game.personality.repair<1,"Repair should animate while standing")
	game._advance_movement(Vector2.ZERO,2)
	check(game.personality.repair==1,"Bridge remains unfinished")
	game.personality.react("pickup",1);game.personality.update(.5)
	check(game.personality.dip()>0,"Pickup has no crouch")
	game.quieter_motion=true
	check(game.personality.dip()==0 and game.personality.arm(0)==0 and game.personality.lean()==0,"Gentler motion animates action")
	game.quieter_motion=false
	# Real touch events: one pointer owns the stick, release outside always clears.
	var stick: Control=game.joystick
	var touch:=InputEventScreenTouch.new();touch.index=2;touch.pressed=true
	touch.position=stick.get_global_transform_with_canvas()*(stick.size*.5+Vector2(35,0));stick._input(touch)
	check(stick.pointer==2 and not game.held_directions.is_empty(),"Touch stick did not acquire input")
	var drag:=InputEventScreenDrag.new();drag.index=3;drag.position=Vector2.ZERO;stick._input(drag)
	check(stick.pointer==2,"Second finger stole stick")
	touch.pressed=false;touch.position=Vector2(-200,-200);stick._input(touch)
	check(stick.pointer==-1 and game.held_directions.is_empty(),"Outside release leaves Ara walking")
	# Disk save round-trip, settings, corrupt-primary recovery and new-game preferences.
	var journal=game.journal;journal.enabled=true;journal.path="user://ira-v06-save-test.json"
	for suffix in ["",".backup",".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(journal.path+suffix))
	game.start_level(1);game.player=game.exploration.loops[0].pos
	game.exploration.found[0]=true;game.pathways.web_clear=true;game.quest_started=true
	game.marks[0].lit=true;game.quest_count=1;game.quieter_motion=true;game.graphics_quality=0
	journal.checkpoint();var position: Vector2=game.player
	var saved_count: int=game.quest_count
	journal.checkpoint() # create last-good backup
	var corrupt:=FileAccess.open(journal.path,FileAccess.WRITE);corrupt.store_string("{broken");corrupt.close()
	OS.set_environment("IRA_SAVE_PATH",journal.path)
	journal.data={};journal.attach(game)
	check(journal.has_checkpoint() and game.quieter_motion and game.graphics_quality==0,"Backup/settings recovery failed")
	journal.resume()
	check(game.level_index==1 and game.player.distance_to(position)<.01 and game.quest_count==saved_count and game.marks[0].lit and game.exploration.found[0] and game.pathways.web_clear,"Resume loses progress")
	journal.checkpoint(2);journal.resume();check(game.level_index==2 and not game.quest_done,"Chapter transition checkpoint failed")
	journal.reset_checkpoint();check(not journal.has_checkpoint() and journal.data.settings.motion,"New game erases preferences")
	journal.enabled=false;OS.set_environment("IRA_SAVE_PATH","off")
	for suffix in ["",".backup",".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(journal.path+suffix))
	print("NAVIGATION PROFILE ",JSON.stringify(profile))
	var file:=FileAccess.open("res://tests/benchmarks/personality-navigation.json",FileAccess.WRITE);file.store_string(JSON.stringify(profile,"  "));file.close()
	game.queue_free();await process_frame
	print("PERSONALITY / SAVE / TOUCH FAILURES: ",failures);quit(failures)
