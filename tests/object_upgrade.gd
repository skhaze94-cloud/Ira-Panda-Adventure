extends SceneTree
var game: Control
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:failures+=1;push_error(message)
func walk(p: Vector2) -> void:
	game._request_destination(p)
	for frame in range(18000):
		if not game.has_destination:break
		game._advance_movement(Vector2.ZERO,1.0/60)
	check(game.player.distance_to(p)<.2,"Object unreachable: "+str(p))
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.set_process(false);game.music_enabled=false;game.sound_enabled=false;game.menu_audio.stop();game.game_audio.stop()
	for chapter in range(5):
		game.start_level(chapter);game.bats.clear()
		check(game.objects.items.size()==9,"Object pool incomplete")
		for kind in ["bridge","pumpkin","sign","prop"]:
			check(game.object_art.textures[chapter][kind] is Texture2D,"Missing illustration")
			check(game.object_art.rect(game,kind).size.x>100,"Invalid illustrated region")
		for item in game.objects.items:
			check(not game._blocked(item.pos),"Blocked object")
			walk(item.pos);var score: int=game.beauty.score()
			check(game.objects.interact() and item.found and item.response>0,"Object fails to react: "+str(item))
			check(game.beauty.score()==score and not game.quest_done and not game.key_collected,"Object changes quest / crown")
		game.journal.checkpoint();game.journal.resume()
		for item in game.objects.items:check(item.found,"Continue loses discoveries")
		game.journal.data.checkpoint.erase("objects");game.journal.resume()
		for item in game.objects.items:check(not item.found,"Legacy save flags invalid")
		var pumpkin: Dictionary=game.objects.items[1];game.player=pumpkin.pos;game.cooldown=0;game.glow()
		check(pumpkin.response>0 and pumpkin.found,"Lantern fails to wake pumpkin")
		game._pause();var response: float=pumpkin.response;game.objects.update(10);check(pumpkin.response==response,"Pause advances object animation")
		game._resume();game.objects.update(10);check(pumpkin.response==0,"Object animation never settles")
		game.quieter_motion=true;game.objects.interact();check(pumpkin.found,"Gentler Motion disables object")
		game.quieter_motion=false
		for previous in range(5):
			if previous!=chapter:check(game.object_art.textures[previous].is_empty(),"Old chapter object textures retained")
		print("OBJECT UPGRADE CHAPTER ",chapter+1)
	game.start_level(2);check(game._blocked(game.pathways.crossings[-1].pos),"Repair gate opens early")
	game.quest_count=3;game.player=game._station();game.interact();check(game.quest_done,"Bridge repair fails")
	game._advance_movement(Vector2.ZERO,2);check(game.personality.repair==1,"Bridge reveal does not complete")
	game.queue_free();await process_frame
	print("OBJECT UPGRADE FAILURES: ",failures);quit(failures)
