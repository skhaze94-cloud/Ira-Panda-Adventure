extends SceneTree
var game: Control
var directory: String
var records: Array = []

func _initialize() -> void:
	call_deferred("run")

func inspect(node: Node, items: Array) -> void:
	if node is Control and node.is_visible_in_tree() and (node is BaseButton or node is Label):
		var r: Rect2 = node.get_global_rect()
		items.append({"class":node.get_class(),"text":node.text,"rect":[r.position.x,r.position.y,r.size.x,r.size.y],"focus":node.focus_mode})
	for child in node.get_children(): inspect(child,items)

func capture(label: String) -> void:
	for frame in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join(label+".png"))
	var items: Array = []
	inspect(game.ui_canvas,items)
	records.append({"capture":label,"size":[game.size.x,game.size.y],"state":game.state,"items":items})
	print("CAPTURED ",label," ",game.size)

func run() -> void:
	directory=OS.get_environment("IRA_CAPTURE_DIR")
	DirAccess.make_dir_recursive_absolute(directory)
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.music_enabled=false
	game.sound_enabled=false
	game.menu_audio.stop()
	game.game_audio.stop()
	await capture("desktop-title")
	for dims in [Vector2i(1280,720),Vector2i(854,480),Vector2i(740,360)]:
		root.size=dims
		root.content_scale_size=dims
		await process_frame
		game._layout_ui()
		var prefix: String = "%dx%d" % [dims.x,dims.y]
		game._return_menu()
		game._open_options()
		await capture(prefix+"-options")
		game._return_menu()
		game._open_album()
		await capture(prefix+"-album")
		game.start_level(0)
		await capture(prefix+"-hud")
		game._pause()
		await capture(prefix+"-pause")
		game._return_menu()
		await capture(prefix+"-continue-title")
		game._new_adventure()
		await capture(prefix+"-new-save-confirm")
		game._return_menu()
		game._start_intro()
		await capture(prefix+"-intro")
		game.start_level(0)
		game._talk(game.npcs[0])
		game.conversation.visible_letters=game.conversation.caption.text.length()
		game.conversation.caption.visible_characters=-1
		await capture(prefix+"-dialogue")
		game.conversation.close()
	var file: FileAccess = FileAccess.open(directory.path_join("layout-review.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(records,"\t"))
	game.queue_free()
	await process_frame
	print("UI REVIEW CAPTURES COMPLETE")
	quit()
