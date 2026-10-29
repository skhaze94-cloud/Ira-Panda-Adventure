extends SceneTree
## Integration contracts for painted poses, story continuity and compact layouts.
var game: Control
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error(description)

func within(control: Control, parent: Control, description: String) -> void:
	check(parent.get_global_rect().grow(2).encloses(control.get_global_rect()), description)

func settle() -> void:
	for frame in range(4): await process_frame

func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.set_process(false)
	game.music_enabled=false;game.sound_enabled=false
	game.menu_audio.stop();game.game_audio.stop()
	for name in game.keepsake.CAST:
		var texture: Texture2D=game.keepsake.characters[name]
		var full := Rect2(Vector2.ZERO,texture.get_size())
		for frame in range(4):
			var crop: Rect2=game.keepsake.crop("characters",name,frame)
			check(crop.size.x>200 and crop.size.y>200 and full.encloses(crop),"Character crop clipped or empty: %s/%d"%[name,frame])
			var portrait: AtlasTexture=game.keepsake.portrait(name,frame)
			check(portrait.atlas==texture and portrait.region==crop,"Portrait does not share the world illustration")
	# Exercise the settings overlay before there is a world to render.
	game._open_options();game.atmosphere._process(0)
	check(not game.atmosphere.fog.visible,"Menu options retain world fog")
	game._resume()
	for chapter in range(5):
		game.start_level(chapter)
		var atlas: Texture2D=game.keepsake.settings.atlas
		var full := Rect2(Vector2.ZERO,atlas.get_size())
		check(game.keepsake.settings.size()==1,"Previous scenery atlases retained")
		for kind in range(6):
			check(full.encloses(game.keepsake.crop("settings",game.keepsake.CHAPTERS[chapter],kind)),"Scenery crop escapes atlas")
		game.walk_dir=Vector2.RIGHT;game.pulse=0;game.personality.action_time=0
		game.foot_time=PI*.5
		var first: int=game.keepsake.ara_frame(game)
		game.foot_time=PI*1.5
		check(first!=game.keepsake.ara_frame(game),"Walking never changes painted pose")
		game.pulse=game.GLOW_TIME
		check(game.keepsake.ara_frame(game)==3,"Lantern lift has no painted pose")
		for facing in [-1.0,1.0]:
			game.facing=facing
			check(game._lantern_tip().is_finite(),"Lantern attachment becomes invalid")
		game.quieter_motion=true
		check(game.keepsake.ara_frame(game)==0,"Gentler motion keeps changing poses")
		game.quieter_motion=false
		print("KEEPSAKE ART CHAPTER ",chapter+1)
	for chapter in range(-1,4):
		game.story_chapter=chapter
		for page in range(3 if chapter<0 else 2):
			game.story_page=page;game._show_story()
			check(game.story_image.texture is AtlasTexture,"Legacy story art remains in refreshed story")
	# Test real logical viewport changes, not a scaled 1280-wide screenshot.
	for viewport in [Vector2i(1280,720),Vector2i(854,480)]:
		root.size=viewport;root.content_scale_size=viewport
		await settle();game._layout_ui();game._return_menu();await settle()
		within(game.menu_card,game,"Menu clipped by viewport")
		within(game.menu_col,game.menu_card,"Menu content escapes paper frame")
		game._start_intro();game._layout_ui();await settle()
		within(game.story_card,game,"Story card clipped by viewport")
		within(game.story_card.get_child(0),game.story_card,"Story content clipped by paper frame")
		for child in game.story_card.get_child(0).get_children():
			if child is Control and child.visible: within(child,game.story_card,"Story child clipped: "+child.name)
		game._open_options();await settle()
		within(game.dialog_card,game,"Options clipped by viewport")
		print("KEEPSAKE LAYOUT ",viewport)
	game.queue_free();await process_frame
	print("MOONLIT KEEPSAKE FAILURES: ",failures)
	quit(failures)
