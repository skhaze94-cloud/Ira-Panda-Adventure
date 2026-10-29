extends SceneTree
var game: Control
var directory: String
var report: Dictionary = {"engine":Engine.get_version_info().string,"renderer":"GL Compatibility; Linux software rendering","samples_per_scene":30,"profiles":[]}
func _initialize() -> void: call_deferred("run")
func percentile(samples: Array, fraction: float) -> float:
	var values:=samples.duplicate();values.sort()
	return float(values[mini(values.size()-1,int(ceil(values.size()*fraction))-1)])
func run() -> void:
	directory=OS.get_environment("IRA_CAPTURE_DIR")
	DirAccess.make_dir_recursive_absolute(directory)
	var started:=Time.get_ticks_usec()
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await process_frame;await RenderingServer.frame_post_draw
	report["startup_first_frame_ms"]=(Time.get_ticks_usec()-started)/1000.0
	game.music_enabled=false;game.sound_enabled=false
	game.menu_audio.stop();game.game_audio.stop()
	for chapter in range(5):
		started=Time.get_ticks_usec();game.start_level(chapter)
		var build_ms: float=(Time.get_ticks_usec()-started)/1000.0
		await process_frame;await RenderingServer.frame_post_draw
		var first_ms: float=(Time.get_ticks_usec()-started)/1000.0
		game.bats.clear()
		for quality in [1,2]:
			game.set_graphics_quality(quality)
			for frame in range(8): await process_frame
			var frames: Array=[];var draws: Array=[]
			for frame in range(30):
				var began:=Time.get_ticks_usec()
				await process_frame;await RenderingServer.frame_post_draw
				frames.append((Time.get_ticks_usec()-began)/1000.0)
				draws.append(game.render_cpu_us/1000.0)
			var entry: Dictionary={"chapter":chapter+1,"quality":"Balanced" if quality==1 else "Rich","chapter_build_ms":build_ms,"chapter_first_frame_ms":first_ms,"frame_median_ms":percentile(frames,.5),"frame_p95_ms":percentile(frames,.95),"draw_cpu_p95_ms":percentile(draws,.95),"godot_static_memory_bytes":OS.get_static_memory_usage()}
			report.profiles.append(entry)
			if quality==2: root.get_texture().get_image().save_png(directory.path_join("chapter-%d.png"%(chapter+1)))
			print("RENDER PROFILE ",JSON.stringify(entry))
	var file:=FileAccess.open(directory.path_join("runtime-profile.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"));file.close()
	game.queue_free();game=null
	await process_frame;await create_timer(.2).timeout
	print("NATIVE RUNTIME PROFILE COMPLETE");quit()
