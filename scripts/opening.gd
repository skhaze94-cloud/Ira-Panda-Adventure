extends RefCounted
var game: Control
var origin := Vector2.ZERO
var ribbon := Vector2.ZERO
var moved := false
var found := false
var talked := false
var glowed := false
var celebrated := false
var label: Label
func begin() -> void:
	origin=Vector2(2,game._path_y(2))
	ribbon=origin.lerp(game.npcs[0].pos,.45)
	var value=game.journal.data.get("opening",{})
	var saved: Dictionary=value if value is Dictionary else {}
	moved=saved.get("moved",false);found=saved.get("found",false)
	talked=saved.get("talked",false);glowed=saved.get("glowed",false);celebrated=saved.get("celebrated",false)
	if label==null:
		label=game._label(game.hud_layer,"",16,Color("#fff0ce"))
		label.anchor_left=0;label.anchor_right=0
		label.anchor_top=0;label.anchor_bottom=0
		label.add_theme_color_override("font_shadow_color",Color("#173c37"))
		label.add_theme_constant_override("shadow_outline_size",5)
	update()
func save() -> void:
	game.journal.data["opening"]={"moved":moved,"found":found,"talked":talked,"glowed":glowed,"celebrated":celebrated}
	game.journal.settings()
func update() -> void:
	if label==null:return
	label.position=Vector2(24,145)
	label.size=Vector2(minf(360,game.size.x*.34),76)
	label.visible=game.level_index==0 and not (talked and glowed)
	if game.level_index!=0:return
	if not moved and game.player.distance_to(origin)>.8:
		moved=true;save()
	if moved and not found and game.player.distance_to(ribbon)<.9:
		found=true
		game.show_toast("Ira’s pink ribbon! Pip might know which way she bounced.",4)
		game.personality.react("pickup",.6)
		game.soundscape.play("pickup")
		save()
	if talked and glowed and not celebrated and game.state=="play":
		celebrated=true
		game.show_toast("A little light, a brave beginning! Follow the lanterns to Bramble and Moss.",4)
		game.soundscape.play("reveal")
		save()
	if not moved:label.text="Take a little step · WASD / arrows, paw stick or tap"
	elif not found:label.text="A pink ribbon on the path! Walk over to it."
	elif not talked:label.text="Pip is just ahead · approach him and use Interact"
	else:label.text="Make a little light · Space or tap Glow"
func talk() -> void:
	if game.level_index!=0:return
	talked=true
	if not found:found=true;moved=true
	save();update()
func glow() -> void:
	if game.level_index!=0:return
	glowed=true;save();update()
