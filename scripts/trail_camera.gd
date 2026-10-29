extends RefCounted
## Pixel-space framing for the native isometric renderer. No zoom or input lock.
var speed := Vector2.ZERO
var attention := Vector2.ZERO
var last_size := Vector2.ZERO
var last_tile := 0.0
var reveals: Array = []
var seen: Dictionary = {}
var active: Dictionary = {}
var reveal_time := 0.0
var rest := 0.0
var scenic_offset := Vector2.ZERO
const REVEAL_SECONDS := 2.8

func project_delta(g: Control, point: Vector2) -> Vector2:
	return Vector2((point.x-point.y)*g.tile,(point.x+point.y)*g.tile*.49)

func safe_feet(g: Control, caption: bool=true) -> Rect2:
	var edge: float=minf(180.0,g.size.x*.22)
	var top: float=maxf(150.0,g.size.y*.34)
	var bottom: float=g.size.y-42.0
	if caption and g.conversation!=null and g.conversation.notice_panel.visible:
		bottom=minf(bottom,g.conversation.notice_panel.position.y-12.0)
	bottom=maxf(top+12.0,bottom)
	return Rect2(Vector2(edge,top),Vector2(maxf(40,g.size.x-edge*2),bottom-top))

func build(g: Control) -> void:
	reveals.clear();seen.clear();active.clear();reveal_time=0;rest=0
	for i in range(g.pathways.crossings.size()):
		reveals.append({"id":"bridge-%d"%i,"pos":g.pathways.crossings[i].pos,"kind":"crossing"})
	for i in range(g.exploration.loops.size()):
		reveals.append({"id":"clearing-%d"%i,"pos":g.exploration.loops[i].pos,"kind":"clearing"})
	if g.level_index==4: reveals.append({"id":"home","pos":g._exit(),"kind":"home"})
	snap(g)

func snap(g: Control) -> void:
	speed=Vector2.ZERO;attention=Vector2.ZERO;scenic_offset=Vector2.ZERO
	g.camera_lead=Vector2.ZERO
	g.camera=safe_feet(g).get_center()-project_delta(g,g.player)
	last_size=g.size;last_tile=g.tile
	# Continue, respawn and resize never start a surprise pan around Ara.
	active.clear();reveal_time=0
	for reveal in reveals:
		if g.player.distance_to(reveal.pos)<5.8: seen[reveal.id]=true

func update(g: Control, delta: float) -> void:
	if g.state!="play":
		speed=Vector2.ZERO
		return
	if g.size!=last_size or not is_equal_approx(g.tile,last_tile): snap(g)
	var dt: float=clampf(delta,0,.1)
	var area:=safe_feet(g)
	if g.quieter_motion:
		snap(g)
		return
	var lead: Vector2=g.velocity*.28
	g.camera_lead=g.camera_lead.lerp(lead,1-exp(-dt*4.5))
	var lead_pixels:=project_delta(g,g.camera_lead).limit_length(minf(50,g.size.y*.08))
	var wanted:=Vector2.ZERO
	var focus: Dictionary=g._interaction_target()
	if not focus.is_empty() and focus.kind in ["npc","chest","door","station"]:
		wanted=project_delta(g,focus.pos-g.player)*.24
	elif g.has_destination and g.player.distance_to(g.destination)<4.0:
		wanted=project_delta(g,g.destination-g.player)*.12
	attention=attention.lerp(wanted.limit_length(44),1-exp(-dt*3.5))
	rest=maxf(0,rest-dt)
	if active.is_empty() and rest<=0:
		for reveal in reveals:
			if seen.has(reveal.id) or g.player.distance_to(reveal.pos)>5.2: continue
			seen[reveal.id]=true;active=reveal.duplicate();reveal_time=0;rest=8.0
			break
	scenic_offset=Vector2.ZERO
	if not active.is_empty():
		reveal_time+=dt
		var progress: float=clampf(reveal_time/REVEAL_SECONDS,0,1)
		var envelope: float=pow(sin(progress*PI),2)
		scenic_offset=(project_delta(g,active.pos-g.player)*.18).limit_length(minf(64,g.size.y*.10))*envelope
		if progress>=1: active.clear()
	var player_at: Vector2=area.get_center()-lead_pixels-attention-scenic_offset
	player_at=player_at.clamp(area.position,area.end)
	var target:=player_at-project_delta(g,g.player)
	# Exact critically damped spring for a stationary target, stable across frame rates.
	var omega:=7.0
	var displacement: Vector2=g.camera-target
	var step: Vector2=(speed+displacement*omega)*dt
	var decay: float=exp(-omega*dt)
	g.camera=target+(displacement+step)*decay
	speed=(speed-step*omega)*decay
	# Keep Ara's feet in the safe corridor even after a long frame or sharp turn.
	var actual: Vector2=project_delta(g,g.player)+g.camera
	var hard_area:=safe_feet(g,false)
	var correction: Vector2=actual.clamp(hard_area.position,hard_area.end)-actual
	g.camera+=correction
	if correction.x!=0:speed.x=0
	if correction.y!=0:speed.y=0

func frame_reunion(g: Control) -> void:
	if g.size.y<500:return # The compact dialogue stage uses the speaker portrait.
	speed=Vector2.ZERO
	g.camera=Vector2(g.size.x*.5-22,g.size.y*.45)-project_delta(g,g.player)

func frame_result(g: Control) -> void:
	speed=Vector2.ZERO
	var foot_y: float=maxf(138,g.size.y*.37) if g.size.y<500 else g.size.y*.44
	g.camera=Vector2(g.size.x*.5-22,foot_y)-project_delta(g,g.player)
