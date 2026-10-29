extends SceneTree
var failures := 0
func check(value: bool, message: String) -> void:
	if not value: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);await process_frame
	game.set_process(false);game.music_enabled=false;game.sound_enabled=false
	game.menu_audio.stop();game.game_audio.stop()
	var journal=game.journal
	journal.path="user://ira-v011-reliability-isolated.json";journal.enabled=true
	OS.set_environment("IRA_SAVE_PATH",journal.path)
	for chapter in range(5):
		game.start_level(chapter)
		game.player=game.exploration.loops[0].pos
		game.quest_started=true;game.quest_count=1;game.heart=2
		if not game.marks.is_empty(): game.marks[0].lit=true
		game.exploration.found[0]=true
		game.music_volume=.23;game.effects_volume=.67;game.large_text=true
		game.quieter_motion=true;game.graphics_quality=2
		journal.checkpoint();var expected: Vector2=game.player
		journal.checkpoint()
		check(journal.last_error==OK,"Save write chapter %d"%chapter)
		journal.data={};journal.attach(game);journal.resume()
		check(game.level_index==chapter and game.player.distance_to(expected)<.01,"Restored position/chapter")
		check(game.heart==2 and game.quest_count==1 and (game.marks.is_empty() or game.marks[0].lit) and game.exploration.found[0],"Restored quest/discovery")
		check(is_equal_approx(game.music_volume,.23) and is_equal_approx(game.effects_volume,.67) and game.large_text,"Restored reading/audio settings")
		var f:=FileAccess.open(journal.path,FileAccess.WRITE);f.store_string("{broken");f.close()
		journal.data={};journal.attach(game);journal.resume()
		check(game.level_index==chapter and game.player.distance_to(expected)<.01,"Backup recovery chapter %d"%chapter)
		print("RELIABILITY SAVE/RECOVERY CHAPTER ",chapter+1)
	for dims in [Vector2i(740,360),Vector2i(1280,720),Vector2i(854,480)]:
		root.size=dims;root.content_scale_size=dims;await process_frame
		game._layout_ui();game.conversation._layout()
		var expected: int=(15 if dims.y<400 else 16 if dims.y<600 else 18)+2
		check(game.story_body.get_theme_font_size("font_size")==expected,"Larger text survives resize")
	journal.data.settings.music_volume=4.0;journal.data.settings.effects_volume=-2.0
	journal.write();journal.attach(game)
	check(game.music_volume==1.0 and game.effects_volume==.01,"Saved volumes stay in supported range")
	journal.reset_checkpoint()
	check(not journal.has_checkpoint() and journal.data.settings.large_text,"New game retains reading preference")
	for suffix in ["",".backup",".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(journal.path+suffix))
	journal.path="user://missing-v011-directory/save.json"
	check(not journal.write() and journal.last_error!=OK,"Unwritable save reports failure")
	journal.enabled=false;OS.set_environment("IRA_SAVE_PATH","off")
	game.queue_free();game=null;journal=null
	await process_frame;await create_timer(.2).timeout
	print("RELIABILITY FAILURES: ",failures);quit(failures)
