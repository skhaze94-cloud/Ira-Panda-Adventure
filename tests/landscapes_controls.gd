extends SceneTree
var game: Control
var failures := 0

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func walk_to(target: Vector2) -> void:
	game._request_destination(target)
	check(game.has_destination,"No route to " + str(target))
	for frame in range(12000):
		if not game.has_destination: break
		game._advance_movement(Vector2.ZERO,1.0/60.0)
		check(not game._blocked(game.player),"Navigation walked into an obstacle")
	check(game.player.distance_to(target) < 0.25,"Did not reach " + str(target) + " from " + str(game.player))

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
		check(game.landmarks.size() == 3,"Missing chapter landmarks")
		if chapter == 0:
			walk_to(game._key_location())
			game.interact()
			game.glow()
			game._update_collectibles()
			check(game.key_collected,"Key navigation/collection failed")
		else:
			for mark in game.marks:
				walk_to(mark.pos)
				if mark.has("chest"): game.interact()
				game.cooldown = 0.0
				game.glow()
				game._update_collectibles()
			check(game.quest_count == 3,"Item route failed")
			if chapter == 3:
				for order in range(3):
					for rune in game.runes:
						if rune.order != order: continue
						walk_to(rune.pos)
						game.cooldown = 0
						game.glow()
			else:
				walk_to(game._station())
				if chapter == 2:
					check(game._blocked(Vector2(game._station().x+2,game._path_y(game._station().x+2))),"Unrepaired crossing is open")
				game.interact()
			check(game.quest_done,"Quest failed after actual navigation")
		walk_to(game._exit())
		print("NAVIGATED CHAPTER ",chapter+1)
	# Screen diagonal should project in exactly the requested direction.
	for axis in [Vector2.UP,Vector2.RIGHT,Vector2(1,-1)]:
		var world: Vector2 = game._screen_to_world(axis)
		var screen := Vector2(world.x-world.y,(world.x+world.y)*0.49)
		check(screen.normalized().dot(axis.normalized()) > 0.999,"Direction differs from screen input")
	var endpoints: Array[Vector2] = []
	for fps in [30,60,120]:
		game.start_level(0)
		for frame in range(fps*2): game._advance_movement(Vector2(0,1),1.0/float(fps))
		endpoints.append(game.player)
	check(endpoints[0].distance_to(endpoints[2]) < 0.04,"Movement varies with frame rate")
	game._advance_movement(Vector2.ZERO,0.2)
	check(game.velocity.length() < 0.001,"Release does not stop motion")
	game._hold_direction(1,Vector2.LEFT,true)
	game._hold_direction(2,Vector2.UP,true)
	game._hold_direction(1,Vector2.LEFT,false)
	game._hold_direction(1,Vector2.LEFT,false)
	check(game.mobile_axis == Vector2.UP,"Duplicate touch release corrupted input")
	game._pause()
	check(game.velocity == Vector2.ZERO and game.mobile_axis == Vector2.ZERO and not game.has_destination,"Pause retained input")
	game._resume()
	game.quieter_motion = true
	game._advance_movement(Vector2.DOWN,0.1)
	check(game.walk_dir.length() > 0,"Gentler motion disabled movement")
	game.cooldown = 0.1
	game.glow()
	check(game.glow_buffer > 0,"Early lantern press was not buffered")
	game._reset_controls()
	check(game.glow_buffer == 0,"Cancelled input retained lantern buffer")
	game.queue_free()
	await process_frame
	print("LANDSCAPE / CONTROL FAILURES: ",failures)
	quit(failures)
