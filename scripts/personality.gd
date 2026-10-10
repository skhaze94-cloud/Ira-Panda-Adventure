extends RefCounted
## Semantic, shared-body poses: arms and lantern retain their original pivots.
var game: Control
var action := ""
var action_time := 0.0
var action_length := 1.0
var repair := 1.0
var reunion := 0.0
var story_clock := 0.0
var lullaby_clock := 0.0
var key_glimmer := 0.0
func build(owner_game: Control) -> void:
	game=owner_game;action="";action_time=0;repair=1;reunion=0;story_clock=0;lullaby_clock=0;key_glimmer=0
func react(kind: String, duration: float=0.8) -> void:
	action=kind;action_length=duration;action_time=duration
	if kind=="repair": repair=0.0
	if kind=="reveal": key_glimmer=1.8
	game.soundscape.play({"pickup":"pickup","reveal":"reveal","repair":"repair","celebrate":"victory","startle":"startle","flower":"glow","reunion":"victory"}.get(kind,"pickup"))
func surface() -> String:
	for c in game.pathways.crossings:
		if absf(game.player.x-c.x)<c.width+0.4 and absf(game.player.y-game.pathways.crossing_y(c,game.player.x)-c.offset)<2.2:
			return "stone" if c.kind=="stones" else "wood"
	return "grass"
func update(dt: float) -> void:
	if game.state not in ["play","win"]: return
	story_clock+=dt
	action_time=maxf(0,action_time-dt)
	key_glimmer=maxf(0,key_glimmer-dt)
	if game.level_index==2 and game.quest_done: repair=1.0 if game.quieter_motion else minf(1,repair+dt/1.8)
	if game.level_index==4 and game.quest_done:
		lullaby_clock-=dt
		if lullaby_clock<=0:
			game.soundscape.play("musicbox",1.0,-17+maxf(0,1-game.player.distance_to(game._exit())/20)*7)
			lullaby_clock=3.6
	if game.state=="win": reunion=1.0 if game.quieter_motion else minf(1,reunion+dt/2.3)
func strength() -> float:
	if game.quieter_motion or action_time<=0: return 0
	return sin((1-action_time/action_length)*PI)
func lean() -> float:
	if game.quieter_motion: return 0
	var moving: float = minf(1,game.walk_dir.length())
	var sway := sin(game.foot_time*0.5)*0.045*moving if surface()=="wood" else 0.0
	if action=="startle": sway+=sin(action_time*16)*strength()*0.1
	return sway
func arm(side: int) -> float:
	if game.quieter_motion: return 0
	var value := strength()
	if action in ["pickup","flower"]: return value*(0.35 if side==0 else -0.20)
	if action=="repair": return sin(action_time*14)*value*0.25
	if action in ["celebrate","reunion"]: return value*(-0.65 if side==1 else 0.65)
	if surface()=="wood": return sin(game.foot_time*.5)*0.1+(0.24 if side==0 else -0.14)
	return 0
func dip() -> float:
	if game.quieter_motion: return 0
	if action in ["pickup","flower","repair"]: return strength()*6
	if action=="celebrate": return -absf(sin(action_time*9))*strength()*9
	return 0
func hop() -> float:
	if game.quieter_motion or surface()!="stone": return 0
	return absf(sin(game.foot_time))*minf(1,game.walk_dir.length())*5
