extends RefCounted
## Three generous secret loops, eighteen stars and three themed treasure chests.
const MAX_SCORE := 400
var game: Control
var paths: Array = []
var chests: Array = []
var stars: Array = []
var scenery: Array = []
var crown_announced := false
func layout(owner_game: Control) -> void:
	game=owner_game;paths.clear();chests.clear();stars.clear();scenery.clear();crown_announced=false
	var n: float=game.BASE_LEVELS[game.level_index].size
	for i in range(3):
		var preferred: float=3+(n-6)*[.17,.41,.82][i]
		var x:=preferred
		for shift in [0,-7,7,-12,12,-18,18]:
			var candidate: float=preferred+shift
			var safe: bool=candidate>7 and candidate+6<n-5
			if game.level_index==2 and candidate+6>game._station().x-2: safe=false
			for c in game.pathways.crossings:
				if c.x>candidate-2 and c.x<candidate+7: safe=false
			for branch in paths:
				if absf(candidate-branch.points[0].x)<7: safe=false
			if safe: x=candidate;break
		var side: float=-1 if i%2==0 else 1
		var a:=Vector2(x,game._path_y(x))
		var b:=Vector2(x+1.5,maxf(3,game._path_y(x+1.5)+side*6))
		var c:=Vector2(x+3,maxf(3,game._path_y(x+3)+side*7))
		var d:=Vector2(x+5,game._path_y(x+5))
		if game.level_index==0 and i==1:
			a=Vector2(24,game._path_y(24));b=Vector2(26,game._path_y(26)+3);c=game._key_location();d=Vector2(32,game._path_y(32))
		paths.append({"points":[a,b,c,d],"pos":c,"index":i})
		chests.append({"pos":c,"index":i,"open":false,"lid":0.0,"glimmer":0.0})
		for j in range(4):
			var p: Vector2=a.lerp(b,float(j+1)/5) if j<2 else b.lerp(c,float(j-1)/3)
			stars.append({"pos":p,"found":false,"index":stars.size()})
		# A few new plants and a landmark frame each alcove, never blocking its floor.
		scenery.append({"pos":c+Vector2(-1.6,1.2),"kind":1})
		scenery.append({"pos":c+Vector2(2.8,.6),"kind":0})
		scenery.append({"pos":c+Vector2(1.9,-.6),"kind":3})
	for i in range(6):
		var x: float=6+float(i)*(n-16)/6
		stars.append({"pos":Vector2(x,game._path_y(x)+.7),"found":false,"index":stars.size()})
func open_floor(p: Vector2, width: float=1.9) -> bool:
	for branch in paths:
		for i in range(3):
			if game._segment_distance(p,branch.points[i],branch.points[i+1])<width: return true
	return false
func segments() -> Array[Vector4]:
	var result: Array[Vector4]=[]
	for branch in paths:
		for i in range(3):
			var a: Vector2=branch.points[i];var b: Vector2=branch.points[i+1]
			result.append(Vector4(a.x,a.y,b.x,b.y))
	return result
func finish_layout() -> void:
	# Avoid logs and bridge banks without changing the route design.
	for star in stars: star.pos=game.living.safe_spot(star.pos)
	if game.level_index>0 and game.marks.size()>1:
		var mark: Dictionary=game.marks[1]
		mark.pos=chests[1].pos;mark["chest"]=1
func item_available(mark: Dictionary) -> bool:
	return not mark.has("chest") or chests[int(mark.chest)].open
func key_available() -> bool: return chests.size()>1 and chests[1].open
func nearest_chest() -> int:
	var best:=-1;var distance: float=game.INTERACT_RADIUS
	for chest in chests:
		var d: float=game.player.distance_to(chest.pos)
		if not chest.open and d<distance: best=chest.index;distance=d
	return best
func interact() -> bool:
	var index:=nearest_chest()
	if index<0: return false
	var chest: Dictionary=chests[index];chest.open=true
	game.personality.react("celebrate",1.0);game._burst(chest.pos)
	if index==1:
		if game.level_index==0: game.key_revealed=true;game.quest_started=true
		elif game.level_index==1: game.marks[1].revealed=true
	game.show_toast("Treasure found! "+(["The brass key was sleeping in here!","A missing scroll page, tucked safely inside!","A secret bundle of driftwood!","A star crystal with a very cosy hiding place!","A moonflower! Shine to wake it gently."][game.level_index] if index==1 else "Forty little points for curious paws."),3.7)
	bank();game.journal.checkpoint();return true
func shine() -> void:
	for chest in chests:
		if not chest.open and game.player.distance_to(chest.pos)<6: chest.glimmer=4
func update(dt: float) -> void:
	if game.state!="play": return
	for chest in chests:
		chest.glimmer=maxf(0,chest.glimmer-dt)
		if chest.open: chest.lid=1.0 if game.quieter_motion else minf(1,chest.lid+dt*2.5)
	for star in stars:
		if not star.found and game.player.distance_to(star.pos)<1.0:
			star.found=true;game._burst(star.pos);game.soundscape.play("pickup",1.2,-17)
			bank();game.journal.checkpoint()
	if score()==MAX_SCORE and not crown_announced:
		crown_announced=true;game.personality.react("celebrate",1.5)
		game.show_toast("Woodland crown earned! Every star, every chest, and one very happy adventure.",4.5)
		bank();game.journal.checkpoint()
func star_count() -> int:
	var count:=0
	for star in stars: count+=int(star.found)
	return count
func chest_count() -> int:
	var count:=0
	for chest in chests: count+=int(chest.open)
	return count
func score() -> int:
	return star_count()*10+chest_count()*40+(100 if game.quest_done or game.key_collected else 0)
func bank() -> void:
	var raw=game.journal.data.get("best_scores",[])
	var best: Array=raw.duplicate() if raw is Array else []
	while best.size()<5: best.append(0)
	best[game.level_index]=maxi(clampi(int(best[game.level_index]),0,400),score())
	game.journal.data["best_scores"]=best
func result() -> String:
	return "%s · %d / 400 · %d stars · %d chests" % ["WOODLAND CROWN" if score()==400 else "A lovely adventure",score(),star_count(),chest_count()]
func saved() -> Dictionary:
	var found: Array=[];var opened: Array=[]
	for star in stars: found.append(star.found)
	for chest in chests: opened.append(chest.open)
	return {"stars":found,"chests":opened,"crown":crown_announced}
func restore(data: Dictionary) -> void:
	var found: Array=data.get("stars",[]) if data.get("stars",[]) is Array else []
	var opened: Array=data.get("chests",[]) if data.get("chests",[]) is Array else []
	for i in range(mini(found.size(),stars.size())): stars[i].found=bool(found[i])
	for i in range(mini(opened.size(),chests.size())): chests[i].open=bool(opened[i]);chests[i].lid=1 if opened[i] else 0
	# Existing v0.6/v0.7 quest progress still has a valid home in the new chest.
	if game.key_collected or (game.level_index>0 and (game.quest_done or game.marks[1].lit)):
		chests[1].open=true;chests[1].lid=1
	crown_announced=bool(data.get("crown",false))
