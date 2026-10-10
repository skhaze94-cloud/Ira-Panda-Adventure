extends Node
## Original synthesized effects, bounded eight-voice pool and one stream bed.
var game: Control
var clips: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var bed: AudioStreamPlayer
var bed_level := -60.0
var water: AudioStreamPlayer
var next_voice := 0
var steps := 0.0
var water_level := -60.0
var played := 0
func _ready() -> void:
	for name in ["grass","wood","stone","glow","pickup","reveal","repair","web","startle","victory","musicbox","rune-0","rune-1","rune-2","voice-ara","voice-ira","voice-pip","voice-bramble","voice-moss","water","woodland"]:
		clips[name]=load("res://assets/audio/%s.wav" % name)
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		voice.volume_db=-8
		add_child(voice);voices.append(voice)
	water=AudioStreamPlayer.new()
	var stream: AudioStreamWAV = clips.water
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin=0
	stream.loop_end=int(stream.get_length()*stream.mix_rate)
	water.stream=stream;water.volume_db=-60
	add_child(water)
	bed=AudioStreamPlayer.new()
	var forest: AudioStreamWAV=clips.woodland
	forest.loop_mode=AudioStreamWAV.LOOP_FORWARD;forest.loop_begin=0;forest.loop_end=int(forest.get_length()*forest.mix_rate)
	bed.stream=forest;bed.volume_db=-60
	add_child(bed)
func play(name: String, pitch: float=1.0, volume: float=-8.0) -> void:
	if not game.sound_enabled or voices.is_empty() or not clips.has(name): return
	var voice: AudioStreamPlayer = voices[next_voice]
	next_voice=(next_voice+1)%voices.size()
	voice.stream=clips[name];voice.pitch_scale=pitch;voice.volume_db=volume
	voice.play();played+=1
func step(distance: float) -> void:
	steps+=distance
	if steps<0.8: return
	steps=0
	var surface: String = game.personality.surface()
	play(surface,0.95+game._randseed(game.foot_time)*0.1,-15)
func update(dt: float) -> void:
	var active: bool=game.sound_enabled and game.state=="play"
	var target: float=-22-game.living.brook*8-game.living.home_warmth*4 if active else -60.0
	bed_level=lerpf(bed_level,target,1-exp(-dt*1.4));bed.volume_db=bed_level
	if active and not bed.playing: bed.play()
	if not active and bed_level<-57: bed.stop()
	var near := 0.0
	if game.sound_enabled and game.state=="play":
		for c in game.pathways.crossings: near=maxf(near,1.0-smoothstep(2,9,game.player.distance_to(c.pos)))
	water_level=lerpf(water_level,-44+near*19 if near>0 else -60,1-exp(-dt*3))
	water.volume_db=water_level
	if near>0.01 and not water.playing: water.play()
	if near<=0.01 and water_level<-57: water.stop()
func silence() -> void:
	for voice in voices: voice.stop()
	if water!=null: water.stop()
	if bed!=null: bed.stop()

func _exit_tree() -> void:
	silence()
	for voice in voices: voice.stream=null
	if water!=null: water.stream=null
	if bed!=null: bed.stream=null
	clips.clear()
