extends SceneTree
var game: Control
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures+=1;push_error(message)
func walk(target: Vector2) -> void:
	game._request_destination(target)
	for frame in range(18000):
		if not game.has_destination: break
		game._advance_movement(Vector2.ZERO,1.0/60)
		game.beauty.update(.016)
	check(game.player.distance_to(target)<.2,"Hidden wonder unreachable: "+str(target)+" from "+str(game.player))
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.set_process(false);game.music_enabled=false;game.sound_enabled=false;game.menu_audio.stop();game.game_audio.stop()
	check(game.beauty_art.atlases.size()==5,"Missing chapter atlases")
	for chapter in range(5):
		game.start_level(chapter);game.bats.clear()
		check(game.beauty.stars.size()==18 and game.beauty.chests.size()==3,"Wrong chapter treasure totals")
		check(game.beauty_art.regions[chapter].size()==4,"Fewer than four new chapter artworks")
		for route in game.beauty.paths:
			for p in route.points: walk(p)
			walk(route.pos)
			check(not game._blocked(route.pos),"Chest in inaccessible terrain")
			game._update_collectibles();game.cooldown=0;game.glow()
			if route.index==1:
				check(not game.key_collected and (chapter==0 or not game.marks[1].lit),"Hidden quest item collected through closed chest")
			game.interact();game.beauty.update(.15)
			check(game.beauty.chests[route.index].open,"Treasure interaction failed")
			check(game.beauty.chests[route.index].lid>0 and game.beauty.chests[route.index].lid<1,"Missing animated chest lid")
			game._update_collectibles();game.cooldown=0;game.glow()
			if route.index==1: check(game.key_collected if chapter==0 else game.marks[1].lit,"Hidden quest item fails after chest opens")
		for star in game.beauty.stars:
			check(not game._blocked(star.pos),"Star is blocked")
			walk(star.pos);game.beauty.update(.016)
		check(game.beauty.star_count()==18 and game.beauty.chest_count()==3,"Treasures missing after actual navigation")
		game.quest_done=true;game.beauty.update(.016)
		check(game.beauty.score()==400 and game.beauty.crown_announced,"Top score / crown cannot be earned")
		game.beauty.update(5);check(game.beauty.score()==400,"Repeat pickups farm points")
		game.journal.checkpoint();game.journal.resume()
		check(game.beauty.score()==400 and game.beauty.chest_count()==3,"Continue loses treasures / score")
		game.journal.data.checkpoint.erase("beauty");game.journal.resume()
		check(game.beauty.chests[1].open,"Legacy completed quest lost its hidden item")
		print("HIDDEN WONDERS CHAPTER ",chapter+1," · trees ",game.trees.size())
	game._return_menu();game._open_album()
	check(game.album.visible and game.album_buttons.size()==5,"Chapter album missing")
	for b in game.album_buttons: check(not b.disabled and b.text.contains("CROWN"),"Best score / unlocked chapter missing")
	var checkpoint: Dictionary=game.journal.data.checkpoint.duplicate(true)
	game._choose_chapter(0);game._return_menu()
	check(game.journal.data.checkpoint==checkpoint,"Cancel replay changed checkpoint")
	game._open_album();game._choose_chapter(0);game._resume()
	check(game.level_index==0 and game.beauty.star_count()==0 and game.journal.data.best_scores[0]==400,"Replay fails to reset treasures / keep best")
	game.journal.data.erase("unlocked");game.journal.data.erase("checkpoint");game._open_album()
	check(not game.album_buttons[0].disabled and game.album_buttons[1].disabled,"Unvisited chapters unlocked")
	game._resume();game.start_level(0);game.player=game.beauty.chests[0].pos;game.quieter_motion=true;game.interact();game.beauty.update(.01)
	check(game.beauty.chests[0].lid==1,"Gentler motion retains lid tween")
	game._pause();var count: int=game.beauty.star_count();game.beauty.update(10);check(game.beauty.star_count()==count,"Pause collects stars")
	game.queue_free();await process_frame
	print("HIDDEN WONDERS FAILURES: ",failures);quit(failures)
