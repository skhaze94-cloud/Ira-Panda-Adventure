extends RefCounted
## Versioned checkpoints, validated restoration and a last-good backup.
const VERSION := 1
var game: Control
var path := "user://ira-adventure-v06.json"
var data: Dictionary = {}
var enabled := true
var last_error := OK
func attach(owner_game: Control) -> void:
	game=owner_game
	var override := OS.get_environment("IRA_SAVE_PATH")
	if override=="off": enabled=false
	elif not override.is_empty(): path=override
	if enabled:
		for candidate in [path,path+".backup"]:
			if not FileAccess.file_exists(candidate): continue
			var f := FileAccess.open(candidate,FileAccess.READ)
			if f==null or f.get_length()>131072: continue
			var parser := JSON.new()
			if parser.parse(f.get_as_text())!=OK: continue
			var parsed = parser.data
			if parsed is Dictionary and int(parsed.get("version",0))==VERSION:
				data=parsed;break
	var prefs: Dictionary = data.get("settings",{}) if data.get("settings",{}) is Dictionary else {}
	game.music_enabled=bool(prefs.get("music",true))
	game.sound_enabled=bool(prefs.get("sound",true))
	game.quieter_motion=bool(prefs.get("motion",false))
	game.graphics_quality=clampi(int(prefs.get("quality",1)),0,2)
func has_checkpoint() -> bool:
	return data.get("checkpoint",null) is Dictionary and int(data.checkpoint.get("chapter",-1)) in range(5)
func settings() -> void:
	data["version"]=VERSION
	data["settings"]={"music":game.music_enabled,"sound":game.sound_enabled,"motion":game.quieter_motion,"quality":game.graphics_quality}
	write()
func checkpoint(next_chapter: int=-1) -> void:
	if game.trees.is_empty(): return
	data["unlocked"]=maxi(int(data.get("unlocked",0)),maxi(game.level_index,next_chapter))
	if next_chapter>=0:
		data["checkpoint"]={"chapter":clampi(next_chapter,0,4)}
	else:
		var marks: Array=[]
		for m in game.marks: marks.append({"lit":m.lit,"revealed":m.revealed})
		var npc_flags: Array=[]
		for npc in game.npcs: npc_flags.append(npc.met)
		var rune_flags: Array=[]
		for rune in game.runes: rune_flags.append(rune.lit)
		var plants: Array=[]
		for plant in game.light_trails.plants: plants.append(plant.awake)
		var stones: Array=[]
		for stone in game.light_trails.stones: stones.append(stone.found)
		data["checkpoint"]={"chapter":game.level_index,"pos":[game.player.x,game.player.y],"heart":game.heart,"started":game.quest_started,"done":game.quest_done,"count":game.quest_count,"key":game.key_collected,"revealed":game.key_revealed,"rune_step":game.rune_step,"marks":marks,"npcs":npc_flags,"runes":rune_flags,"plants":plants,"stones":stones,"trails":game.light_trails.trail_found.values(),"web":game.pathways.web_clear,"explored":game.exploration.found.duplicate(),"living":game.living.saved(),"beauty":game.beauty.saved()}
	settings()
func reset_checkpoint() -> void:
	data.erase("checkpoint");settings()
func resume() -> void:
	if not has_checkpoint(): return
	var saved: Dictionary = data.checkpoint.duplicate(true)
	game.restoring=true
	game.start_level(clampi(int(saved.chapter),0,4))
	game.quest_started=bool(saved.get("started",false));game.quest_done=bool(saved.get("done",false))
	game.key_collected=bool(saved.get("key",false));game.key_revealed=bool(saved.get("revealed",false))
	game.quest_count=clampi(int(saved.get("count",0)),0,3);game.rune_step=clampi(int(saved.get("rune_step",0)),0,3)
	game.heart=clampi(int(saved.get("heart",3)),1,3)
	var marks: Array = saved.get("marks",[]) if saved.get("marks",[]) is Array else []
	for i in range(mini(marks.size(),game.marks.size())):
		if marks[i] is Dictionary:
			game.marks[i].lit=bool(marks[i].get("lit",false));game.marks[i].revealed=bool(marks[i].get("revealed",true))
	for entry in [["npcs",game.npcs,"met"],["runes",game.runes,"lit"],["plants",game.light_trails.plants,"awake"],["stones",game.light_trails.stones,"found"]]:
		var flags: Array = saved.get(entry[0],[]) if saved.get(entry[0],[]) is Array else []
		for i in range(mini(flags.size(),entry[1].size())): entry[1][i][entry[2]]=bool(flags[i])
	for plant in game.light_trails.plants: plant.bloom=1.0 if plant.awake else 0.0
	var trails: Array = saved.get("trails",[]) if saved.get("trails",[]) is Array else []
	var keys: Array = game.light_trails.trail_found.keys()
	for i in range(mini(trails.size(),keys.size())): game.light_trails.trail_found[keys[i]]=bool(trails[i])
	game.light_trails.discovered=0
	for value in game.light_trails.trail_found.values(): game.light_trails.discovered+=int(value)
	for plant in game.light_trails.plants: game.light_trails.discovered+=int(plant.awake)
	for stone in game.light_trails.stones: game.light_trails.discovered+=int(stone.found)
	game.pathways.web_clear=bool(saved.get("web",false));game.pathways.web_fade=0.0 if game.pathways.web_clear else 1.0
	var found: Array = saved.get("explored",[]) if saved.get("explored",[]) is Array else []
	for i in range(mini(2,found.size())): game.exploration.found[i]=bool(found[i])
	var pos: Array = saved.get("pos",[]) if saved.get("pos",[]) is Array else []
	if pos.size()==2 and pos[0] is float and pos[1] is float:
		var p := Vector2(pos[0],pos[1])
		if is_finite(p.x) and is_finite(p.y) and not game._blocked(p): game.player=p
	game.living.restore(saved.get("living",{}) if saved.get("living",{}) is Dictionary else {})
	game.beauty.restore(saved.get("beauty",{}) if saved.get("beauty",{}) is Dictionary else {})
	game.navigation=null;game._begin_navigation()
	game.camera=game.size*Vector2(.5,.55)-Vector2((game.player.x-game.player.y)*game.tile,(game.player.x+game.player.y)*game.tile*.49)
	game.restoring=false
	game._update_hud();game.show_toast("Back on the trail. Ira is waiting!",2.5)
func write() -> bool:
	if not enabled: return true
	var f := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if f==null: last_error=FileAccess.get_open_error();return false
	f.store_string(JSON.stringify(data));f.flush();f.close()
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path+".backup"): DirAccess.remove_absolute(absolute+".backup")
		last_error=DirAccess.rename_absolute(absolute,absolute+".backup")
		if last_error!=OK: return false
	last_error=DirAccess.rename_absolute(absolute+".tmp",absolute)
	return last_error==OK
