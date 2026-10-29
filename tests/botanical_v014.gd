extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures+=1
		push_error(message)
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.music_enabled=false;game.sound_enabled=false
	game.menu_audio.stop();game.game_audio.stop()
	var report: Array=[]
	for chapter in range(5):
		game.start_level(chapter)
		check(game.botany.textures.size()==5,"Five textures must load")
		var kinds: Dictionary={}
		var tree_kinds: Dictionary={}
		for texture in game.botany.textures:
			check(texture!=null and texture.get_width()>0,"Texture missing")
		for tree in game.trees:
			tree_kinds[int(tree.variant)]=true
			for crossing in game.pathways.crossings:
				check(absf(tree.pos.x-crossing.x)>=crossing.width+.7,"Tree planted in stream")
		check(tree_kinds.size()==4,"All four tree silhouettes must appear")
		for a in range(game.trees.size()):
			for b in range(a+1,game.trees.size()):
				check(game.trees[a].pos.distance_to(game.trees[b].pos)>=2.3-.001,"Tree spacing violated")
		for a in range(game.botany.plants.size()):
			var plant: Dictionary=game.botany.plants[a]
			kinds[int(plant.kind)]=true
			for crossing in game.pathways.crossings:
				check(absf(plant.pos.x-crossing.x)>=crossing.width+.8,"Ground plant in stream")
			for point in game.botany.protected:
				check(plant.pos.distance_to(point)>=2.8-.001,"Plant crowds an objective")
			for b in range(a+1,game.botany.plants.size()):
				check(plant.pos.distance_to(game.botany.plants[b].pos)>=3.5-.001,"Plant spacing violated")
		check(kinds.size()==3,"All three new small prop species must appear")
		var first: Array=game.botany.plants.duplicate(true)
		game.botany.build(game)
		check(first==game.botany.plants,"Placement must be deterministic")
		report.append({"chapter":chapter+1,"trees":game.trees.size(),"previous_tree_count":baseline_tree_count(game),"tree_silhouettes":tree_kinds.size(),"new_small_props":game.botany.plants.size(),"small_prop_species":kinds.size(),"lamps":game.lanterns.size(),"regular_decorations":game.decorations.size()})
	print(JSON.stringify(report))
	game.queue_free();game=null
	await process_frame;await create_timer(.2).timeout
	print("BOTANICAL V0.14 PASSED" if failures==0 else "BOTANICAL FAILURES: %d"%failures)
	quit(1 if failures else 0)

func baseline_tree_count(g: Control) -> int:
	var total:=0
	var level: Dictionary=g.BASE_LEVELS[g.level_index]
	var n: int=level.size
	for x in range(n):
		for y in range(n):
			var pos:=Vector2(float(x)+.2+g._randseed(x+y*36+g.level_index)*.25,float(y)+.2+g._randseed(x*7+y+g.level_index)*.25)
			if g.exploration.open(pos,3.0) or g.beauty.open_floor(pos,3.0): continue
			if g._randseed(x*71+y*83+g.level_index*129)<.42: continue
			if g._key_clearing(pos) or (g.level_index==1 and pos.distance_to(g.pathways.web_position())<4.8):continue
			var d: float=g.pathways.distance(pos)
			if d<g._clearing_radius(pos.x) or (d>g._clearing_radius(pos.x)+2.0 and g._randseed(x*29+y+g.level_index*71)<=float(level.trees)) or pos.distance_to(g._exit())<2.5: continue
			if g.level_index==4 and d>10.0 and (x%3==1 or y%3==1):continue
			total+=1
	return total
