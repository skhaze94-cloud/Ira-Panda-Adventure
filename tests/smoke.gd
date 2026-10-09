extends SceneTree
var game: Control
var failures := 0
func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.music_enabled = false
	game.menu_audio.stop()
	game.game_audio.stop()
	for chapter in range(5):
		game.start_level(chapter)
		await process_frame
		check(game.state == "play", "Chapter fails to start")
		check(not game._blocked(game.player), "Spawn blocked")
		check(game.npcs.size() > 0,"Guide missing")
		for step in range(4, int(game._exit().x * 2)):
			var x: float = float(step) * 0.5
			if chapter == 2 and x > game._station().x + 0.75: continue
			check(not game._blocked(Vector2(x,game._path_y(x))),"Main path blocked")
		if chapter == 0:
			game.player = game._key_location()
			game.cooldown = 0
			game.glow()
			game._update_collectibles()
			check(game.key_collected,"Birch key cannot be collected")
		else:
			for mark in game.marks:
				check(not game._blocked(mark.pos),"Quest item blocked")
				game.player = mark.pos
				game.cooldown = 0
				game.glow()
				game._update_collectibles()
			check(game.quest_count == 3,"Quest collection failed")
			if chapter == 3:
				for order in range(3):
					for rune in game.runes:
						if rune.order == order:
							game.player = rune.pos
							game.cooldown = 0
							game.glow()
			else:
				game.player = game._station()
				game.interact()
			check(game.quest_done,"Quest station did not complete")
		game.player = game._exit()
		game._complete_chapter()
		check(game.completed,"Chapter completion failed")
		print("CHECKED CHAPTER ",chapter+1)
	game.queue_free()
	await process_frame
	print("SMOKE FAILURES: ",failures)
	quit(failures)
