extends SceneTree
var game: Control
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures+=1;push_error(message)
func walk(target: Vector2) -> void:
	game._request_destination(target)
	for frame in range(18000):
		if not game.has_destination: break
		game._advance_movement(Vector2.ZERO,1.0/60)
	check(game.player.distance_to(target)<.2,"Ira clue/toy unreachable: "+str(target))
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await process_frame
	game.set_process(false);game.music_enabled=false;game.sound_enabled=false;game.menu_audio.stop();game.game_audio.stop()
	for chapter in range(5):
		game.start_level(chapter);game.bats.clear()
		check(game.living.clues.size()==3 and game.living.leaves.size()==6,"Unbounded world pool")
		for clue in game.living.clues:
			check(not game._blocked(clue.pos),"Clue is in blocked terrain")
			walk(clue.pos);game.living.update(.016)
			check(clue.found,"Clue not discovered by approach")
		check(game.living.count_clues()==3 and not game.quest_done,"Clues gate or complete main quest")
		game.living.update(.1);check(game.living.count_clues()==3,"Repeat clue adds progress")
		var snapshot: Dictionary=game.living.saved()
		game.living.build(game);game.living.restore(snapshot)
		check(game.living.count_clues()==3,"Saved clue discoveries lost")
		var pile: Dictionary=game.living.leaves[0]
		walk(pile.pos);game.living.update(.016)
		check(pile.scatter>0,"Leaves do not rustle")
		var cooldown: float=pile.cooldown;game.living.update(.016)
		check(pile.cooldown<cooldown,"Leaf cooldown resets every frame")
		game.velocity=Vector2.ZERO;game.living.update(5)
		check(pile.scatter==0,"Standing still repeatedly rustles leaves")
		var guide: Dictionary=game.living.guide
		game.player=guide.pos;game.living.update(.1)
		check(guide.active and guide.step==1,"Fireflies fail to invite Ara")
		game.player=guide.pos+Vector2(-10,-10)
		var before: Vector2=guide.pos;game.living.update(1)
		check(guide.pos==before,"Guide leaves Ara behind")
		for frame in range(3000):
			game.player=guide.pos;game.living.update(.016)
			if guide.finished: break
		check(guide.finished and guide.pos.distance_to(game.exploration.loops[0].pos)<.1,"Guide fails to reach clearing")
		game.living.restore(game.living.saved());check(game.living.guide.finished,"Completed guide not persistent")
		game.quest_done=true
		for npc in game.npcs:
			game.player=npc.home+Vector2(1,-1);game._update_npc_animation(.1)
			check(npc.greeting>0 and npc.noticed_done,"NPC fails to welcome / celebrate quest")
			game.player=npc.home+Vector2(12,12);game.living.clock=2;game._update_npc_animation(.5)
			check(npc.work>0 and npc.pos.distance_to(npc.home)<1 and not game._blocked(npc.pos),"NPC routine escapes safe home")
			game.quieter_motion=true;game._update_npc_animation(.1)
			check(npc.pos==npc.home and npc.work==0 and npc.stride==0,"Gentler motion retains NPC routine")
			game.quieter_motion=false
		game.player=game.living.visitor.home+Vector2(2,0);game.living.update(.5)
		check(game.living.visitor.attention>0 and game.living.visitor.greeted,"Visitor ignores Ara")
		game.player=game.exploration.loops[0].pos;game.living.update(.1)
		check(game.living.clearing>0 and game.living.clearing<1,"Clearing does not blend gradually")
		game._set_state("dialog");var clock: float=game.living.clock;var clearing: float=game.living.clearing
		game.living.update(10);check(game.living.clock==clock and game.living.clearing==clearing,"World changes during pause")
		game._set_state("play")
		if chapter==3:
			for note in game.living.notes:
				walk(note.pos);game.living.update(.016);check(note.ring>0,"Musical pebble fails to respond")
		print("LIVING WOODLAND CHECKED CHAPTER ",chapter+1)
	game.start_level(4);game.player=game._exit()-Vector2(1,1);game.living.update(.2)
	check(game.living.home_warmth>0 and game.living.home_warmth<1,"Cottage warmth snaps / absent")
	# Continue round trip and backward-compatible v0.6 checkpoint without living flags.
	game.living.clues[0].found=true;game.living.guide.finished=true;game.journal.checkpoint()
	game.journal.resume();check(game.living.clues[0].found and game.living.guide.finished,"Continue loses new discoveries")
	game.journal.data.checkpoint.erase("living");game.journal.resume()
	check(game.living.count_clues()==0 and not game.living.guide.finished,"v0.6 saves fail to get fresh world flags")
	game.queue_free();await process_frame
	print("LIVING WOODLAND FAILURES: ",failures);quit(failures)
