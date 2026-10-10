extends RefCounted
## Each beat has one speaker and one short caption. Progress changes reminders.
static func beat(speaker: String, text: String, mood: String="warm") -> Dictionary:
	return {"speaker":speaker,"text":text,"mood":mood}

static func talk(game: Control, id: String) -> Array:
	var lines: Array=quest_talk(game,id)
	if game.living.count_clues()>0 and not game.quest_done and not game.key_collected:
		lines.insert(1,beat(id,["Ira passed this way. I recognise that very determined little bounce!","She asked whether mushrooms make good umbrellas. I think you know who I mean.","A small cushion crossed here humming. The brook hummed back!","Someone has been counting the stars and leaving biscuit crumbs.","Your sister is very close. I heard two biscuits being carefully counted."][game.level_index],"happy"))
	return lines

static func quest_talk(game: Control, id: String) -> Array:
	var chapter: int = game.level_index
	if chapter==0:
		if game.key_collected:
			return [beat(id,"A brass key! Ira's trail is opening up."),beat("ara","One woodland door, coming right up!","happy")]
		match id:
			"pip": return [beat("pip","A missing pillow sister? That is a very important owl emergency!","happy"),beat("ara","She's called Ira. Small, squishy, surprisingly sneaky."),beat("pip","Follow the lanterns to Bramble and Moss. Move with the arrows or tap the path; Space makes your lantern shine.")]
			"bramble": return [beat("bramble","I checked my clipboard. The woodland door is definitely locked."),beat("ara","Does your clipboard know where the key went?","curious"),beat("bramble","Moss saw it near the blue lanterns. He remembers everything. Except where he leaves his tea.","happy")]
			"moss": return [beat("moss","Three pale birches are keeping a little brass secret.","curious"),beat("ara","A key-sized secret?"),beat("moss","Take the blue-lantern side trail. Shine between their roots, pick up the key, then open the woodland door.")]
	if game.quest_done:
		return [beat(id,["","The moon scroll is whole again. Even the moon likes a happy ending!","That bridge is steady now. My clipboard gives it three very firm ticks!","Moon, Star, Heart. The whole hollow is smiling!","The lullaby is playing. Ira must be just beside the cottage."][chapter],"happy"),beat("ara","Follow the lanterns. I'm getting closer!","happy")]
	if game.quest_count>=3:
		return [beat(id,["","All three pages! Put them together at the moon-scroll lectern.","Three bundles! Bring them to the broken bridge and we'll make a proper crossing.","Three crystals! Now shine at Moon, then Star, then Heart.","Three flowers awake! Play the music box beside the cottage."][chapter]),beat("ara","A little light, a little teamwork. Let's do this!","happy")]
	if game.quest_started:
		return [beat(id,["","Purple nests are hiding the scroll pages. Shine beside each nest and pick up its page.","Driftwood waits on both sides of the trail. Gather three bundles, then visit the bridge.","Find three star crystals. Then wake the stones: Moon, Star, Heart.","Shine beside three sleeping moonflowers. Then visit the cottage music box."][chapter]),beat("ara","I've found %d of three. One little step at a time!" % game.quest_count,"happy")]
	match chapter:
		1: return [beat(id,"The moon scroll blew into three pieces. The purple nests are using it as wallpaper!","curious"),beat("ara","Let's rescue the story before anyone eats the ending."),beat(id,"Shine beside three purple nests and collect their pages. Bring all three to the lectern.")]
		2: return [beat(id,"The brook bridge has a wobble. A very wobbly wobble.","curious"),beat("ara","I vote for a bridge that stays under my feet."),beat(id,"Gather three driftwood bundles along the trail. Bring them to the broken bridge and help me repair it.")]
		3: return [beat(id,"The constellation has fallen asleep. It even snores in sparkles!","happy"),beat("ara","Ira likes sparkles. Which stars do we wake?","curious"),beat(id,"Collect three star crystals. Then shine at the stones in order: Moon, Star, Heart.")]
		4: return [beat(id,"I heard a giggle near the cottage. The moonflowers know the way.","happy"),beat("ara","That sounds exactly like my suspiciously giggly sister!","happy"),beat(id,"Shine beside three sleeping moonflowers. Then play their lullaby at the cottage music box.")]
	return []

static func reunion() -> Array:
	return [beat("ira","You found me! I was practising being a mysterious cushion.","happy"),beat("ara","You are very mysterious. And very huggable.","happy"),beat("ira","Next time, shall we hide somewhere with biscuits?","happy"),beat("ara","Five little chapters. One very big hug.","happy")]

static func caption_pages(message: String) -> Array[String]:
	var pages: Array[String] = []
	var line := ""
	for sentence in message.replace("\n"," ").split(". "):
		var part := str(sentence).strip_edges()
		if part.is_empty(): continue
		if not line.is_empty() and line.length()+part.length()>170:
			pages.append(line)
			line = ""
		line += (". " if not line.is_empty() else "")+part
	if not line.is_empty(): pages.append(line)
	return pages
