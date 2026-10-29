extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_level(0)
	game._return_menu()
	game._new_adventure()
	var saved: Dictionary=game.journal.data.checkpoint.duplicate(true)
	var key:=InputEventKey.new();key.keycode=KEY_ESCAPE;key.pressed=true
	game._unhandled_key_input(key)
	assert(game.state=="menu" and game.journal.data.checkpoint==saved,"Escape must preserve the saved adventure")
	game._open_options();game._resume();game.journal.resume()
	game._talk(game.npcs[0])
	assert(game.dialog_from=="" and game.conversation.active,"NPC dialogue must retain the world backdrop")
	game.conversation.close();game._pause();game._open_options()
	assert(game.dialog_from=="options-pause")
	game._resume();assert(game.dialog_from=="resume" and game.state=="dialog")
	game.volume_music.value=.62;game.volume_effects.value=.48
	game.journal.settings()
	assert(is_equal_approx(game.journal.data.settings.music_volume,.62))
	assert(is_equal_approx(game.journal.data.settings.effects_volume,.48))
	assert(game.modal_primary.focus_mode==Control.FOCUS_ALL)
	game._return_menu();game._start_intro()
	root.size=Vector2i(740,360);root.content_scale_size=Vector2i(740,360)
	await process_frame
	game._layout_ui()
	assert(game.story_bubble.visible,"Compact story keeps every quotation")
	game.queue_free();game=null;key=null
	await process_frame
	await process_frame
	# Audio playback is released by the mixer asynchronously.
	await create_timer(.2).timeout
	print("STORYBOOK UI REGRESSIONS PASSED")
	quit()
