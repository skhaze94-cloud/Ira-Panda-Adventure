extends SceneTree
var failures := 0
var game: Control
func check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error(description)
func _initialize() -> void: call_deferred("run")
func center_at(p: Vector2) -> void:
	game.player = p
	game.camera = game.size*Vector2(0.5,0.55)-Vector2((p.x-p.y)*game.tile,(p.x+p.y)*game.tile*0.49)
	game.visibility_camera = Vector2(INF,INF)
	game._refresh_visible_trees()
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
		check(game.ambience.creatures.size()==36,"Ambience pool should have fixed size")
		check(not game.tree_render_chunks.is_empty(),"Forest render chunks missing")
		for x in [7.0,29.0,55.0,float(game.BASE_LEVELS[chapter].size)-6]:
			center_at(Vector2(x,game._path_y(x)))
			for tree in game.trees:
				var at: Vector2 = game._project(tree.pos)
				var height: float = game.tile*3.9*float(tree["size"])
				if at.x>-game.tile and at.x<game.size.x+game.tile and at.y>0 and at.y<game.size.y+height:
					check(game.visible_trees.has(tree),"Visible tree missing from spatial cache")
			check(game.visible_trees.size()<game.trees.size(),"Offscreen forest not culled")
		for quality in range(3):
			var quest_before: int = game.quest_count
			game.set_graphics_quality(quality)
			game.atmosphere._process(0)
			var enabled := 0
			for light in game.atmosphere.lights:
				if light.enabled: enabled += 1
			check(enabled<=[2,3,5][quality],"Too many lights for selected quality")
			check(game.atmosphere.lights[0].shadow_enabled==(quality==2),"Shadow quality mismatch")
			check(game.ambience.nearby_creatures().size()<=[8,16,24][quality],"Creature budget exceeded")
			check((game.material!=null)==(quality==2),"Relief material quality mismatch")
			check(game.quest_count==quest_before,"Quality setting changed quest progress")
		var npc: Dictionary = game.npcs[0]
		game.player = npc.home+Vector2(1,0)
		game._update_npc_animation(0.05)
		check(npc.greeting>0 and npc.facing==1,"NPC failed to greet / face Ara")
		game.player = npc.home-Vector2(1,0)
		game._update_npc_animation(0.05)
		check(npc.facing==-1,"NPC failed to face left")
		game.cooldown = 0
		game.glow()
		check(npc.reaction>0 and game.ambience.response>0,"Lantern did not animate neighbours / creatures")
		game.quieter_motion = true
		game._update_npc_animation(0.05)
		check(npc.pos==npc.home,"Gentler motion should stop NPC wandering")
		var reaction: float = npc.reaction
		var response: float = game.ambience.response
		game.state = "dialog"
		game._process(0.5)
		check(npc.reaction==reaction and game.ambience.response==response,"Paused animation timers advanced")
		game.state = "play"
		game.quieter_motion = false
		game.particles.clear()
		for i in range(50): game._burst(game.player)
		check(game.particles.size()<=96,"Sparkle pool grew beyond cap")
		print("GRAPHICS CHECKED CHAPTER ",chapter+1)
	game.set_graphics_quality(1)
	game._open_options()
	check(game.options_quality.visible and game.options_quality.selected==1,"Graphics selector not accessible")
	game._show_dialog("Test","Test","BACK","","resume")
	check(not game.options_quality.visible,"Graphics selector leaked into dialogue")
	game.queue_free()
	await process_frame
	print("GRAPHICS V0.5 FAILURES: ",failures)
	quit(0 if failures==0 else 1)

