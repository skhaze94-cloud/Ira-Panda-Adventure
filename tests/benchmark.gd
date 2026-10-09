extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.music_enabled = false
	game.menu_audio.stop()
	game.game_audio.stop()
	var quality := OS.get_environment("IRA_BENCH_QUALITY")
	if game.get("graphics_quality") != null and not quality.is_empty(): game.set_graphics_quality(quality.to_int())
	var report: Array = []
	for chapter in range(5):
		game.start_level(chapter)
		var x: float = [7.0,39.0,65.0,70.0,79.0][chapter]
		game.player = Vector2(x,game._path_y(x))
		game.camera = game.size*Vector2(0.5,0.55)-Vector2((game.player.x-game.player.y)*game.tile,(game.player.x+game.player.y)*game.tile*0.49)
		game.bats.clear()
		for frame in range(8):
			await process_frame
			await RenderingServer.frame_post_draw
		var samples: Array[float] = []
		var draw_calls := 0.0
		for frame in range(24):
			var begin := Time.get_ticks_usec()
			await process_frame
			await RenderingServer.frame_post_draw
			samples.append(float(Time.get_ticks_usec()-begin)/1000.0)
			draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		samples.sort()
		var row := {"chapter":chapter+1,"median_ms":samples[12],"p95_ms":samples[22],"mean_draw_calls":draw_calls/24.0,"texture_mib":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)/1048576.0}
		if game.get("visible_trees") != null: row["visible_trees"] = game.visible_trees.size()
		if game.get("render_cpu_us") != null: row["last_draw_cpu_ms"] = float(game.render_cpu_us)/1000.0
		report.append(row)
		print("BENCHMARK CHAPTER ",chapter+1," ",JSON.stringify(row))
	var output := OS.get_environment("IRA_BENCH_OUTPUT")
	if not output.is_empty():
		var file := FileAccess.open(output,FileAccess.WRITE)
		file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"size":game.size,"quality":quality,"views":report},"  "))
	game.queue_free()
	await process_frame
	quit()
