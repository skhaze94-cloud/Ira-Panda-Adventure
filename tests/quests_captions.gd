extends SceneTree
var failures := 0
var game: Control
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void: call_deferred("run")
func finish_talk() -> void:
	var count := 0
	while game.conversation.active and count<20:
		game.conversation.advance()
		count += 1
	check(not game.conversation.active,"Conversation failed to finish")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.conversation.set_process(false)
	game.music_enabled = false
	game.menu_audio.stop()
	game.game_audio.stop()
	for chapter in range(5):
		game.start_level(chapter)
		var npc: Dictionary = game.npcs[0]
		game.player = npc.home
		game.velocity = Vector2.ONE
		game.mobile_axis = Vector2.ONE
		game.interact()
		check(game.state=="dialog" and game.conversation.active,"NPC did not open focused dialogue")
		check(not game.modal_layer.visible and not game.hud_layer.visible,"Generic modal / HUD overlaps dialogue")
		check(game.velocity==Vector2.ZERO and game.mobile_axis==Vector2.ZERO,"Conversation retained movement input")
		check(game.conversation.portrait.speaker==npc.id,"Wrong first speaker")
		check(game.conversation.beats.size()==3,"First quest greeting lost introduction")
		var position: Vector2 = game.player
		var pulse_before: float = game.pulse
		game._process(0.5)
		check(game.player==position and game.pulse==pulse_before,"Gameplay advanced during NPC conversation")
		game.conversation.advance()
		check(game.conversation.page==0 and game.conversation.caption.visible_characters==-1,"First press should reveal, not skip")
		game.conversation.advance()
		check(game.conversation.page==1 and game.conversation.portrait.speaker=="ara","Speaker turn failed")
		check(not game.conversation.notice_panel.visible,"Toast overlaps single caption")
		finish_talk()
		check(game.state=="play","Conversation did not return to play")
		if chapter>0:
			game.quest_count = 2
			game.interact()
			check(game.conversation.beats.size()==2,"Progress reminder repeats full introduction")
			check(game.conversation.beats[1].text.contains("2 of three"),"Reminder ignores actual quest progress")
			finish_talk()
			game.quest_count = 3
			game.interact()
			check(game.conversation.beats[0].text.contains("three") or game.conversation.beats[0].text.contains("Three"),"Ready reminder ignores completed collection")
			game.conversation.close()
		game.show_toast("First clue. A second clue with enough detail to keep reading. A third clue is still part of the same discovery and should never be chopped off just because it is long. A final clue completes this useful instruction.",4)
		check(game.conversation.notices.size()>0,"Long clue was not sequenced")
		check(not game.toast_label.visible,"Legacy toast still visible")
		game._pause()
		check(not game.conversation.notice_panel.visible and not game.conversation.active,"Pause overlaps caption")
		game._resume()
		game.quieter_motion = true
		game.interact()
		check(game.conversation.caption.visible_characters==-1,"Gentler Motion still types text")
		finish_talk()
		game.quieter_motion = false
		print("QUEST / CAPTION CHECKED CHAPTER ",chapter+1)
	game.start_level(0)
	for npc in game.npcs:
		game.player = npc.home
		game.interact()
		check(game.conversation.portrait.speaker==npc.id,"Chapter one neighbour portrait mismatch")
		check(game.conversation.beats.size()==3,"Chapter one neighbour lost tailored conversation")
		game.conversation.close()
	game.start_level(4)
	game.quest_done = true
	game._complete_chapter()
	check(game.conversation.active and game.conversation.portrait.speaker=="ira","Reunion lost Ira's first line")
	finish_talk()
	check(game.state=="win" and game.modal_primary.text=="PLAY AGAIN","Reunion lost replay controls")
	game._resume()
	check(game.state=="play" and game.level_index==0 and not game.conversation.active,"Replay retained conversation")
	# Exercise real viewport dispatch, rather than only calling button callbacks.
	game.player = game.npcs[0].home
	game.interact()
	game.conversation.set_process(true)
	for frame in range(8): await process_frame
	game.conversation.set_process(false)
	game.conversation.caption.visible_characters = -1
	var before_page: int = game.conversation.page
	var before_glow: float = game.pulse
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	root.push_input(event)
	await process_frame
	check(game.conversation.page==before_page+1,"Space dispatch did not advance exactly one beat")
	check(game.pulse==before_glow,"Caption input leaked into lantern")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.index = 0
	touch.position = game.conversation.caption.get_global_transform_with_canvas()*(game.conversation.caption.size*0.5)
	root.push_input(touch,true)
	await process_frame
	check(game.conversation.page==before_page+1 and game.conversation.caption.visible_characters==-1,"Caption tap must reveal current line first: page=%d chars=%d" % [game.conversation.page,game.conversation.caption.visible_characters])
	var duplicate := InputEventMouseButton.new()
	duplicate.button_index = MOUSE_BUTTON_LEFT
	duplicate.pressed = true
	duplicate.position = touch.position
	root.push_input(duplicate,true)
	await process_frame
	check(game.conversation.page==before_page+1,"Emulated touch mouse event skipped a beat")
	game.conversation.set_process(true)
	for frame in range(8): await process_frame
	var box: Rect2 = game.conversation.panel.get_global_rect()
	check(box.end.y<=game.size.y and box.position.y>=0,"Dialogue card exceeds viewport")
	check(box.encloses(game.conversation.caption.get_global_rect()),"Caption extends outside card")
	check(box.encloses(game.conversation.next_button.get_global_rect()),"Continue button extends outside card")
	game.conversation.close()
	game.show_toast("A little discovery.",3)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	game.conversation.last_caption_touch = -1000
	game.conversation._notice_input(click)
	check(game.conversation.notice_left==0.0 and not game.conversation.notice_panel.visible,"Tap failed to dismiss last notice")
	game._open_options()
	check(game.options_music.visible and not game.conversation.dialogue_root.visible,"Options retained speaker stage")
	game.queue_free()
	await process_frame
	print("QUEST / CAPTION FAILURES: ",failures)
	quit(0 if failures==0 else 1)
