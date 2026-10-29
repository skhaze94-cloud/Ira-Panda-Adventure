extends SceneTree
## Drives the actual story, walking, interaction, glow and save systems in order.
## Optional native screenshots; no quest flags, items or chapter jumps are injected.
var game: Control
var failures:=0
var steps:=0
var travelled:=0.0
var records: Array=[]
var captures: Array=[]
var directory:=""
func _initialize() -> void:call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:failures+=1;push_error(message)
func tick() -> void:
	var before: Vector2=game.player
	game._process(1.0/60)
	game.conversation._process(1.0/60)
	travelled+=before.distance_to(game.player)
	steps+=1
func shot(name: String) -> void:
	if directory.is_empty():return
	for frame in range(90):game.trail_camera.update(game,1.0/60)
	if game.conversation.active and game.conversation.caption.visible_characters>=0:game.conversation.advance()
	game.ground_layer.sync();game.queue_redraw()
	for frame in range(8):
		game.conversation._process(1.0/60)
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join(name+".png"))
	captures.append(name)
func walk(target: Vector2, exit_walk: bool=false) -> void:
	game._request_destination(target)
	for frame in range(30000):
		if game.state!="play" or game.player.distance_to(target)<.2:break
		# Use the lantern to give approaching bats space, as a player can.
		if game.cooldown<=0 and not (game.level_index==3 and game.quest_count==3):
			for bat in game.bats:
				if bat.fear<=0 and game.player.distance_to(bat.pos)<2.8:game.glow();break
		tick()
		if frame%120==0:await process_frame
		if not game.has_destination and not game.pending_destination and game.player.distance_to(target)>.25:
			game._request_destination(target)
	check(game.player.distance_to(target)<(1.3 if exit_walk else .25),"Walk failed in chapter %d: %s from %s"%[game.level_index+1,target,game.player])
func finish_talk() -> void:
	for count in range(40):
		if not game.conversation.active:break
		game.conversation.advance()
	check(not game.conversation.active,"Dialogue did not finish")
func shine() -> void:
	for frame in range(120):
		if game.cooldown<=0:break
		tick()
	game.glow();tick()
func story() -> void:
	for count in range(8):
		if game.state!="comic":break
		game.story_next.pressed.emit()
	check(game.state=="play","Story transition did not reach the world")
func run() -> void:
	directory=OS.get_environment("IRA_CAPTURE_DIR")
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.set_process(false);game.conversation.set_process(false)
	game.music_enabled=false;game.sound_enabled=false;game.menu_audio.stop();game.game_audio.stop()
	check(game.state=="menu","Title missing")
	await shot("01-title")
	game._open_options();check(game.options_motion.visible,"Settings missing");game._return_menu()
	game._start_intro();await shot("02-opening-story");story()
	check(game.level_index==0,"Opening starts in wrong chapter")
	await shot("03-first-step")
	await walk(game.opening.ribbon)
	check(game.opening.found,"Ribbon was not discovered by walking")
	for chapter in range(5):
		check(game.level_index==chapter,"Chapter order changed")
		check(not game._navigation_blocked(game._station()),"Quest station is outside navigable ground")
		await walk(game.npcs[0].home);game.action_button.pressed.emit()
		check(game.conversation.active,"Guide interaction failed")
		await shot("chapter-%d-guide"%[chapter+1]);finish_talk()
		if chapter==0:
			shine()
			for i in [1,2]:
				await walk(game.npcs[i].home);game.interact();finish_talk()
			check(game.opening.celebrated,"Opening guidance never completed")
		# Visit a complete side path rather than teleporting to its clearing.
		var loop: Dictionary=game.exploration.loops[0]
		for point in loop.points:await walk(point)
		await walk(loop.pos)
		check(game.exploration.found[0],"Clearing was not discovered")
		await shot("chapter-%d-clearing"%[chapter+1])
		await walk(game.beauty.chests[0].pos);game.interact()
		check(game.beauty.chests[0].open,"Optional chest failed")
		if chapter==0:
			await walk(game.beauty.chests[1].pos);game.interact();shine();tick()
			check(game.key_collected,"Brass key failed")
		else:
			for mark in game.marks:
				await walk(mark.pos)
				if mark.has("chest"):game.interact()
				shine();tick()
			check(game.quest_count==3,"Quest items failed in chapter %d"%[chapter+1])
			if chapter==2:
				game.journal.checkpoint();var position: Vector2=game.player
				game._pause();await shot("chapter-3-pause")
				game._return_menu();game.continue_button.pressed.emit()
				check(game.level_index==2 and game.quest_count==3 and game.player.distance_to(position)<.01,"Continue lost quest or position")
			if chapter==3:
				for order in range(3):
					for rune in game.runes:
						if rune.order==order:await walk(rune.pos);shine()
			else:
				await walk(game._station());game.interact()
			check(game.quest_done,"Quest completion failed in chapter %d"%[chapter+1])
		await shot("chapter-%d-quest-complete"%[chapter+1])
		await walk(game._exit(),true)
		if chapter==0:game.interact()
		if chapter<4:
			check(game.state=="comic","Missing interlude")
			await shot("chapter-%d-interlude"%[chapter+1])
			records.append({"chapter":chapter+1,"completed":game.completed,"quest_items":game.quest_count,"key":game.key_collected,"chests":game.beauty.chest_count(),"hearts":game.heart,"reveals_seen":game.trail_camera.seen.keys()})
			story()
	check(game.conversation.active and game.conversation.portrait.speaker=="ira","Finale did not reach Ira")
	await shot("finale-reunion");finish_talk()
	check(game.state=="win" and game.modal_primary.text=="PLAY AGAIN","Finale / replay button failed")
	records.append({"chapter":5,"completed":game.completed,"quest_items":game.quest_count,"chests":game.beauty.chest_count(),"hearts":game.heart,"reveals_seen":game.trail_camera.seen.keys()})
	await shot("finale-complete")
	if not directory.is_empty():
		root.size=Vector2i(740,360);root.content_scale_size=Vector2i(740,360);await process_frame;await process_frame
		game.tile=38
		game._show_dialog("One very big hug","Ara and Ira are together again. Adventure tastes even better with biscuits!\n"+game.beauty.result(),"PLAY AGAIN","TITLE SCREEN","replay")
		game.state="win";game.trail_camera.frame_result(game)
		await shot("finale-compact")
		check(Rect2(Vector2.ZERO,game.size).encloses(game.modal_primary.get_global_rect()),"Compact replay button cropped")
		root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1280,720);await process_frame;await process_frame
		game.tile=58
	var best: Array=game.journal.data.best_scores.duplicate()
	game.modal_primary.pressed.emit()
	check(game.state=="play" and game.level_index==0 and not game.opening.celebrated,"Replay retained opening progress")
	check(game.journal.data.best_scores==best,"Replay lost best scores")
	await shot("replay-fresh-opening")
	var report={"failures":failures,"simulation_seconds":steps/60.0,"walked_ground_units":travelled,"chapters":records,"captures":captures,"method":"Scripted engine playthrough using live movement, quest interactions, story buttons, captions, hazards, Continue and replay; no quest flags injected."}
	print(JSON.stringify(report))
	var report_path:=OS.get_environment("IRA_PLAYTHROUGH_REPORT")
	if not report_path.is_empty():
		var file:=FileAccess.open(report_path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"))
	game.queue_free();game=null;await process_frame;await create_timer(.2).timeout
	print("FULL JOURNEY V0.15 FAILURES: ",failures);quit(failures)
