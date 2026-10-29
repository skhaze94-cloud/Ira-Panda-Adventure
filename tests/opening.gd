extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.set_process(false);game.music_enabled=false;game.sound_enabled=false
	game.menu_audio.stop();game.game_audio.stop()
	game.start_level(0)
	var intro=game.opening
	assert(not intro.moved and not intro.found)
	assert(not game._blocked(intro.ribbon),"Ribbon must be reachable")
	game._request_destination(intro.ribbon)
	for frame in range(600):
		game._advance_movement(Vector2.ZERO,1.0/60)
		intro.update()
		if intro.found:break
	assert(intro.moved and intro.found)
	game.player=game.npcs[0].pos+Vector2(.5,.5);game.interact()
	assert(intro.talked and game.conversation.active)
	game.conversation.close();game.cooldown=0;game.glow()
	assert(intro.glowed and not intro.label.visible)
	game.journal.checkpoint();game.journal.resume()
	assert(intro.found and intro.talked and intro.glowed)
	game.start_level(1);assert(not intro.label.visible)
	game.journal.reset_checkpoint();game.start_level(0)
	assert(not intro.moved and not intro.glowed)
	game.cooldown=0;game.glow()
	game.player=game.npcs[0].pos+Vector2(.5,.5);game.interact()
	game.conversation.close();intro.update()
	assert(intro.celebrated,"An early glow or skipped ribbon cannot block the opening")
	game.queue_free();game=null;intro=null
	await process_frame;await create_timer(.2).timeout
	print("OPENING FLOW PASSED");quit()
