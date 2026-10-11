extends SceneTree
var game: Control
var failures := 0

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func shine_at(point: Vector2) -> void:
	game.player = point
	game.cooldown = 0.0
	game.glow()

func check_route(point: Vector2) -> void:
	game.player = Vector2(2,game._path_y(2))
	game._reset_controls()
	game._request_destination(point)
	check(game.has_destination,"Discovery is unreachable: " + str(point))
	for frame in range(12000):
		if not game.has_destination: break
		game._advance_movement(Vector2.ZERO,1.0/60.0)
	check(game.player.distance_to(point) < 0.25,"Cannot walk to discovery: " + str(point))

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.music_enabled = false
	game.sound_enabled = false
	game.menu_audio.stop()
	game.game_audio.stop()
	for chapter in range(5):
		game.start_level(chapter)
		var clues: RefCounted = game.light_trails
		check(clues.plants.size() == 3,"Three lantern blooms must exist")
		check(clues.stones.size() == (1 if chapter == 0 else 4 if chapter == 3 else 3),"Shadow clue missing")
		check(clues.tracks.size() > 0,"No footprints")
		for track in clues.tracks:
			check(track.time == 0.0 and not game._blocked(track.pos),"Footprints visible initially or blocked")
		shine_at(game._exit())
		check(clues.discovered == 0,"Out-of-range glow discovered clues")
		for plant in clues.plants:
			check_route(plant.pos)
			game.heart = 2
			shine_at(plant.pos)
			check(plant.awake and game.heart == 3,"Bloom did not wake and restore one heart")
			var count: int = clues.discovered
			game.heart = 1
			shine_at(plant.pos)
			check(game.heart == 1 and count == clues.discovered,"Repeat bloom farmed a heart or discovery")
		for stone in clues.stones:
			check_route(stone.stand)
			# Other exploration pulses may already have illuminated this nearby stone.
			if stone.found: clues.discovered -= 1
			stone.found = false
			stone.time = 0.0
			shine_at(stone.pos+stone.direction*1.65)
			check(not stone.found and stone.time == 0.0,"Wrong-side light exposed a shadow clue")
			shine_at(stone.stand)
			check(stone.found and stone.time > 0,"Correct-side light failed to reveal a shadow clue")
			var count: int = clues.discovered
			shine_at(stone.stand)
			check(count == clues.discovered,"Shadow discovery counted twice")
		for track in clues.tracks: shine_at(track.pos)
		check(clues.discovered == clues.total,"All discoveries do not match total")
		check(game.quest_count == (2 if chapter == 4 else 0),"Exploration broke original collection rules")
		var track: Dictionary = clues.tracks[0]
		shine_at(track.pos)
		game._pause()
		clues.update(30.0)
		check(track.time > 0,"Pause expired clues")
		var count: int = clues.discovered
		game.cooldown = 0
		game.glow()
		check(count == clues.discovered,"Paused glow changed discoveries")
		game._resume()
		clues.update(19.0)
		for footprint in clues.tracks: check(footprint.time == 0.0,"Footprints failed to fade")
		for stone in clues.stones: check(stone.time == 0.0 and stone.found,"Shadow expiry lost discovery or did not fade")
		shine_at(track.pos)
		check(track.time > 0 and count == clues.discovered,"Refresh failed or double-counted discovery")
		game.quieter_motion = true
		shine_at(track.pos)
		check(track.time > 0,"Gentler Motion hid required clues")
		# Original defensive glow still repels nearby bats.
		game.bats[0].fear = 0.0
		shine_at(game.bats[0].pos)
		check(game.bats[0].fear > 0,"Glow no longer repels bats")
		game.start_level(chapter)
		check(game.light_trails.discovered == 0,"Chapter restart retained old discoveries")
		print("LANTERN CHECKED CHAPTER ",chapter+1)
	game.queue_free()
	await process_frame
	print("LANTERN FAILURES: ",failures)
	quit(failures)
