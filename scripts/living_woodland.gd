extends RefCounted
## A bounded chapter world: three clues, six leaf piles, one guide and one visitor.
var game: Control
var clock := 0.0
var clues: Array = []
var leaves: Array = []
var notes: Array = []
var guide: Dictionary = {}
var visitor: Dictionary = {}
var clearing := 0.0
var brook := 0.0
var home_warmth := 0.0
func build(owner_game: Control) -> void:
	game=owner_game;clock=0;clues.clear();leaves.clear();notes.clear()
	clearing=0;brook=0;home_warmth=0
	var n: float=game.BASE_LEVELS[game.level_index].size
	for i in range(3):
		var x: float = 3+(n-6)*[.18,.53,.86][i]
		var pos:=safe_spot(Vector2(x,game._path_y(x)+.8))
		clues.append({"pos":pos,"kind":["ribbon","prints","biscuit"][i],"found":false,"index":i})
	for i in range(6):
		var x:=6+float(i)*(n-15)/6
		leaves.append({"pos":safe_spot(Vector2(x,game._path_y(x)-.8)),"scatter":0.0,"cooldown":0.0,"inside":false,"index":i})
	var loop: Dictionary=game.exploration.loops[0]
	guide={"pos":loop.points[0],"points":[loop.points[0],loop.points[0].lerp(loop.points[1],.5),loop.points[1],loop.pos],"step":0,"active":false,"finished":false,"spark":0.0}
	var home: Vector2=safe_spot(game.exploration.loops[1].pos+Vector2(.6,.4))
	visitor={"home":home,"pos":home,"attention":0.0,"greeted":false}
	if game.level_index==3:
		for i in range(3):
			var pos: Vector2=safe_spot(game.exploration.loops[1].points[1].lerp(game.exploration.loops[1].points[2],float(i)/2))
			notes.append({"pos":pos,"index":i,"ring":0.0,"cooldown":0.0,"inside":false})
	for npc in game.npcs:
		npc["work"]=0.0;npc["stride"]=0.0;npc["welcome_cooldown"]=0.0;npc["noticed_done"]=false
func safe_spot(p: Vector2) -> Vector2:
	for delta in [Vector2.ZERO,Vector2(0,-1),Vector2(0,1),Vector2(-1,-1),Vector2(1,1),Vector2(-2,-2),Vector2(2,2)]:
		if not game._blocked(p+delta): return p+delta
	return game.player
func count_clues() -> int:
	var total:=0
	for clue in clues: total+=int(clue.found)
	return total
func update_npcs(dt: float) -> void:
	for npc in game.npcs:
		var near: bool=game.player.distance_to(npc.home)<4.5
		npc.welcome_cooldown=maxf(0,npc.welcome_cooldown-dt)
		if near and not npc.near_before and npc.welcome_cooldown<=0:
			npc.greeting=1.8;npc.welcome_cooldown=9
			game.soundscape.play("voice-"+str(npc.id),1,-21)
		if near and (game.quest_done or game.key_collected) and not npc.noticed_done:
			npc.noticed_done=true;npc.reaction=2.8;npc.greeting=2.0
			game.soundscape.play("victory",1.15,-21)
		npc.near_before=near
		npc.greeting=maxf(0,npc.greeting-dt);npc.reaction=maxf(0,npc.reaction-dt)
		var screen_side: float=(game.player.x-game.player.y)-(npc.pos.x-npc.pos.y)
		if near and absf(screen_side)>.45: npc.facing=signf(screen_side)
		var work_clock: float=clock+float(npc.home.x)*.13
		npc.work=0.0 if near or game.quieter_motion else (.5+.5*sin(work_clock*1.4))
		var wander:=Vector2.ZERO
		if not near and not game.quieter_motion:
			match str(npc.id):
				"pip": wander=Vector2(sin(work_clock*.7)*.25,cos(work_clock*.7)*.12)
				"bramble": wander=Vector2(sin(work_clock*.65),sin(work_clock*.65))*.48
				"moss": wander=Vector2(sin(work_clock*.5)*.36,cos(work_clock*.5)*.20)
		var target: Vector2=npc.home+wander
		if game._blocked(target): target=npc.home
		var before: Vector2=npc.pos
		npc.pos=npc.home if game.quieter_motion else npc.pos.lerp(target,1-exp(-dt*4))
		npc.stride=0.0 if game.quieter_motion else minf(1,npc.pos.distance_to(before)/maxf(.001,dt)*3)
func update(dt: float) -> void:
	if game.state!="play": return
	clock+=dt
	for clue in clues:
		if not clue.found and game.player.distance_to(clue.pos)<1.35:
			clue.found=true
			game.personality.react("reveal",.9);game._burst(clue.pos)
			game.show_toast(clue_caption(clue.index),4)
			game.journal.checkpoint()
	for pile in leaves:
		pile.scatter=maxf(0,pile.scatter-dt);pile.cooldown=maxf(0,pile.cooldown-dt)
		var inside: bool=game.player.distance_to(pile.pos)<1.1
		if pile.cooldown<=0 and inside and (not pile.inside or game.velocity.length()>.4):
			pile.scatter=1.1;pile.cooldown=4
			game.soundscape.play("grass",1.35,-17)
		pile.inside=inside
	for note in notes:
		note.ring=maxf(0,note.ring-dt);note.cooldown=maxf(0,note.cooldown-dt)
		var inside: bool=game.player.distance_to(note.pos)<.8
		if note.cooldown<=0 and inside and not note.inside:
			note.ring=1.2;note.cooldown=1.5
			game.soundscape.play("rune-%d"%note.index,1.15,-16)
		note.inside=inside
	update_guide(dt)
	var distance: float=game.player.distance_to(visitor.home)
	visitor.attention=move_toward(visitor.attention,1.0 if distance<4 else 0.0,dt*2)
	if distance<3 and not visitor.greeted:
		visitor.greeted=true;game.soundscape.play("voice-pip",1.5,-23)
	var target: Vector2=visitor.home
	if distance<4 and distance>1.2: target+=visitor.home.direction_to(game.player)*.65
	if not game._blocked(target): visitor.pos=visitor.home if game.quieter_motion else visitor.pos.lerp(target,1-exp(-dt*2))
	var clear_target:=0.0
	for loop in game.exploration.loops: clear_target=maxf(clear_target,1-smoothstep(1,7,game.player.distance_to(loop.pos)))
	for npc in game.npcs: clear_target=maxf(clear_target,(1-smoothstep(2,7,game.player.distance_to(npc.home)))*.65)
	var water_target:=0.0
	for crossing in game.pathways.crossings: water_target=maxf(water_target,1-smoothstep(2,8,game.player.distance_to(crossing.pos)))
	var home_target: float=1-smoothstep(3,18,game.player.distance_to(game._exit())) if game.level_index==4 else 0.0
	var blend:=1-exp(-dt*.9)
	clearing=lerpf(clearing,clear_target,blend);brook=lerpf(brook,water_target,blend);home_warmth=lerpf(home_warmth,home_target,blend)
func update_guide(dt: float) -> void:
	guide.spark=maxf(0,guide.spark-dt)
	if guide.finished: return
	if not guide.active and game.player.distance_to(guide.pos)<2.6: guide.active=true
	if not guide.active: return
	var step: int=guide.step
	var target: Vector2=guide.points[step]
	if guide.pos.distance_to(target)<.08 and game.player.distance_to(guide.pos)<2.5:
		if step==guide.points.size()-1:
			guide.finished=true;guide.spark=1.8
			game.soundscape.play("glow",1.3,-21);game.journal.checkpoint();return
		guide.step+=1;target=guide.points[guide.step]
	# Wait for little paws; the guide never leaves Ara behind.
	if game.player.distance_to(guide.pos)<3.6:
		guide.pos=guide.pos.move_toward(target,dt*1.7)
func glow() -> void:
	if not guide.is_empty() and game.player.distance_to(guide.pos)<5: guide.spark=1.6
	for note in notes:
		if game.player.distance_to(note.pos)<3:
			note.ring=1.2
			if note.cooldown<=0:
				note.cooldown=.6;game.soundscape.play("rune-%d"%note.index,1.15,-19)
func clue_caption(index: int) -> String:
	return [
		["Ira's ribbon! She always ties it with one very wonky loop.","Little pillow prints. Someone has been bouncing toward the woodland door!","A biscuit crumb! Ira calls that leaving a very important map."],
		["A ribbon caught on a glowcap. Ira must have stopped to admire the hats!","Squishy prints between the mushrooms. Very suspicious. Very Ira.","A biscuit tucked into a teacup. She is making friends ahead of me!"],
		["Ira's ribbon is dry. My clever sister found a way across the brook.","Pillow prints beside the willow. She stopped to listen to the water.","A biscuit crumb on the far bank. Onward, little paws!"],
		["Ira tied her ribbon into a star. She is getting good at mysterious clues!","Little prints under the telescope. Perhaps she was looking for me too.","A biscuit crumb beneath the stars. Our midnight picnic is getting closer!"],
		["Her ribbon smells like home. Ira must be just ahead!","Pillow prints pointing to the cottage. I know that happy little bounce!","Two biscuits. One for Ira. One for me. I am almost there!"]
	][game.level_index][index]
func saved() -> Dictionary:
	var found: Array=[]
	for clue in clues: found.append(clue.found)
	return {"clues":found,"guide":guide.get("finished",false)}
func restore(data: Dictionary) -> void:
	var found: Array=data.get("clues",[]) if data.get("clues",[]) is Array else []
	for i in range(mini(found.size(),clues.size())): clues[i].found=bool(found[i])
	if bool(data.get("guide",false)):
		guide.finished=true;guide.pos=guide.points[-1];guide.step=guide.points.size()-1
