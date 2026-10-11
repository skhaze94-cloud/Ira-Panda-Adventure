extends Control
## One caption surface owns both conversations and transient quest feedback.
var game: Control
var active := false
var beats: Array = []
var page := 0
var destination := "play"
var panel: PanelContainer
var dialogue_root: Control
var portrait: Control
var name_label: Label
var caption: Label
var progress: Label
var next_button: Button
var close_button: Button
var notice_panel: PanelContainer
var notice_portrait: Control
var notice_text: Label
var notice_name: Label
var notices: Array = []
var notice_left := 0.0
var visible_letters := 0.0
var last_caption_touch := -1000
var entrance: Tween
var speaker_transition: Tween
const NAMES = {"ara":"Ara", "ira":"Ira", "pip":"Pip", "bramble":"Bramble", "moss":"Moss"}
const INK = Color("#263f48")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_root = Control.new()
	add_child(dialogue_root)
	dialogue_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.025,0.055,0.085,0.48)
	dialogue_root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = game._panel(dialogue_root,Color("#f5eddc"),28)
	var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
	style.border_color = Color("#bba67c")
	style.shadow_color = Color(0.01,0.03,0.05,0.4)
	style.shadow_size = 18
	panel.add_theme_stylebox_override("panel",style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",20)
	panel.add_child(row)
	portrait = load("res://scripts/speaker_portrait.gd").new()
	portrait.game = game
	portrait.custom_minimum_size = Vector2(160,178)
	row.add_child(portrait)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation",9)
	row.add_child(col)
	var heading := HBoxContainer.new()
	col.add_child(heading)
	name_label = label(heading,"Ara",24,Color("#356f69"))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	progress = label(heading,"1 / 3",14,Color("#856f4c"))
	progress.autowrap_mode = TextServer.AUTOWRAP_OFF
	progress.custom_minimum_size.x = 64
	caption = label(col,"",25,INK)
	caption.custom_minimum_size.y = 102
	caption.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.gui_input.connect(_caption_input)
	caption.mouse_filter = Control.MOUSE_FILTER_STOP
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation",14)
	col.add_child(actions)
	next_button = game._button(actions,"NEXT",advance,Vector2(168,48))
	close_button = game._button(actions,"BACK TO WOODS",close,Vector2(170,48))
	close_button.add_theme_font_size_override("font_size",14)
	var help := label(col,"Space / Enter · tap the caption to reveal or continue",12,Color("#7b786e"))
	help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_root.visible = false

	notice_panel = game._panel(self,Color("#f5eddc"),22)
	var nstyle: StyleBoxFlat = style.duplicate()
	nstyle.set_content_margin_all(12)
	notice_panel.add_theme_stylebox_override("panel",nstyle)
	var nrow := HBoxContainer.new()
	nrow.add_theme_constant_override("separation",12)
	notice_panel.add_child(nrow)
	notice_portrait = load("res://scripts/speaker_portrait.gd").new()
	notice_portrait.game = game
	notice_portrait.custom_minimum_size = Vector2(72,80)
	nrow.add_child(notice_portrait)
	var ncol := VBoxContainer.new()
	ncol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nrow.add_child(ncol)
	notice_name = label(ncol,"ARA",12,Color("#356f69"))
	notice_text = label(ncol,"",18,INK)
	notice_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	notice_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notice_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice_panel.gui_input.connect(_notice_input)
	nrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ncol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice_panel.visible = false
	_layout()
	resized.connect(_layout)

func label(parent: Node, text: String, font_size: int, tint: Color) -> Label:
	var item: Label = game._label(parent,text,font_size,tint)
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item

func _layout() -> void:
	if panel==null: return
	var compact := size.x<1000 or size.y<600
	panel.size = Vector2(size.x*0.84,maxf(220.0,size.y*0.43))
	panel.position = Vector2(size.x*0.08,maxf(16.0,size.y-panel.size.y-24))
	portrait.custom_minimum_size = Vector2(120,142) if compact else Vector2(160,178)
	caption.add_theme_font_size_override("font_size",21 if compact else 25)
	caption.custom_minimum_size.y = 70 if compact else 102
	next_button.custom_minimum_size = Vector2(130,42) if compact else Vector2(168,48)
	close_button.custom_minimum_size = Vector2(140,42) if compact else Vector2(170,48)
	notice_panel.position = Vector2(size.x*0.24,size.y*0.76)
	notice_panel.size = Vector2(size.x*0.52,maxf(108.0,size.y*0.18))

func start(lines: Array, ending: String="play") -> void:
	if lines.is_empty(): return
	dismiss()
	beats = lines
	page = 0
	destination = ending
	active = true
	game._set_state("dialog")
	game.modal_layer.visible = false
	dialogue_root.visible = true
	show_beat()
	animate_in(panel)

func show_beat() -> void:
	var line: Dictionary = beats[page]
	name_label.text = NAMES.get(line.speaker,"Ara")
	caption.text = line.text
	visible_letters = 0.0
	caption.visible_characters = -1 if game.quieter_motion else 0
	portrait.speaker = line.speaker
	game.soundscape.play("voice-"+str(line.speaker),1.0,-16)
	portrait.mood = line.get("mood","warm")
	portrait.clock = 0.0
	progress.text = "%d / %d" % [page+1,beats.size()]
	next_button.text = "ONE BIG HUG" if page==beats.size()-1 and destination=="replay" else "LET'S GO" if page==beats.size()-1 else "NEXT"
	close_button.visible = destination!="replay"
	portrait.queue_redraw()
	if speaker_transition!=null: speaker_transition.kill()
	portrait.modulate = Color.WHITE
	if not game.quieter_motion:
		portrait.modulate.a = 0.4
		speaker_transition = create_tween()
		speaker_transition.tween_property(portrait,"modulate:a",1.0,0.14).set_trans(Tween.TRANS_SINE)

func advance() -> void:
	if not active: return
	if caption.visible_characters>=0 and caption.visible_characters<caption.get_total_character_count():
		caption.visible_characters = -1
		return
	if page<beats.size()-1:
		page += 1
		show_beat()
	else:
		close()

func close() -> void:
	var ending := destination
	dismiss()
	if ending=="replay":
		game._show_dialog("One very big hug", "Ara and Ira are together again. Adventure tastes even better with biscuits!\n"+game.beauty.result(), "PLAY AGAIN", "TITLE SCREEN", "replay")
		game.state = "win"
	else:
		game._set_state("play")

func dismiss() -> void:
	active = false
	beats.clear()
	page = 0
	if entrance!=null: entrance.kill()
	if speaker_transition!=null: speaker_transition.kill()
	if dialogue_root!=null: dialogue_root.visible = false
	clear_notices()

func clear_notices() -> void:
	notices.clear()
	notice_left = 0.0
	if notice_panel!=null: notice_panel.visible = false

func notify(message: String, duration: float=3.0) -> void:
	if active or game.state!="play": return
	var pages: Array[String] = load("res://scripts/quest_dialogue.gd").caption_pages(message)
	# A newer progress event replaces stale progress; multi-sentence clues stay ordered.
	clear_notices()
	for text in pages:
		if notices.size()>=4: break
		notices.append({"text":text,"duration":maxf(duration,2.5+float(text.length())/38.0)})
	show_notice()

func show_notice() -> void:
	if notices.is_empty():
		notice_left = 0.0
		notice_panel.visible = false
		return
	var entry: Dictionary = notices.pop_front()
	notice_text.text = entry.text
	notice_name.text = "ARA  ·  A LITTLE DISCOVERY"
	if entry.text.contains("Quest complete") or entry.text.contains("All three"):
		notice_name.text = "ARA  ·  WONDERFULLY DONE!"
	notice_portrait.mood = "happy"
	notice_panel.visible = true
	notice_left = entry.duration
	animate_in(notice_panel)

func animate_in(item: Control) -> void:
	if entrance!=null: entrance.kill()
	item.modulate = Color.WHITE
	if game.quieter_motion: return
	item.modulate.a = 0.0
	entrance = create_tween()
	entrance.tween_property(item,"modulate:a",1.0,0.18).set_trans(Tween.TRANS_SINE)

func _process(dt: float) -> void:
	if active:
		panel.size = Vector2(size.x*0.84,maxf(220.0,size.y*0.43))
		panel.position = Vector2(size.x*0.08,maxf(16.0,size.y-panel.size.y-24))
		if game.quieter_motion: caption.visible_characters = -1
		elif caption.visible_characters>=0:
			visible_letters += dt*44.0
			caption.visible_characters = mini(int(visible_letters),caption.get_total_character_count())
		portrait.speaking = caption.visible_characters>=0 and caption.visible_characters<caption.get_total_character_count()
	elif game.state=="play" and notice_left>0:
		notice_left = maxf(0.0,notice_left-dt)
		if notice_left<=0: show_notice()
	notice_panel.visible = not active and game.state=="play" and notice_left>0

func _unhandled_key_input(event: InputEvent) -> void:
	if not active or not event.is_pressed() or event.is_echo(): return
	if event is InputEventKey:
		if event.keycode in [KEY_SPACE,KEY_ENTER,KEY_E]:
			advance()
			get_viewport().set_input_as_handled()
		elif event.keycode==KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	# Touch captions explicitly; suppress the corresponding emulated mouse press.
	if not (event is InputEventScreenTouch and event.pressed): return
	var item: Control = caption if active else notice_panel
	if not item.is_visible_in_tree(): return
	var local: Vector2 = item.get_global_transform_with_canvas().affine_inverse()*event.position
	if not Rect2(Vector2.ZERO,item.size).has_point(local): return
	last_caption_touch = Time.get_ticks_msec()
	if active: advance()
	else: show_notice()
	get_viewport().set_input_as_handled()

func _caption_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		if Time.get_ticks_msec()-last_caption_touch>200: advance()
		accept_event()

func _notice_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		if Time.get_ticks_msec()-last_caption_touch>200: show_notice()
		accept_event()
