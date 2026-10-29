extends "res://scripts/render.gd"

var options_origin := "menu"
var volume_music: HSlider
var volume_effects: HSlider
var text_size: OptionButton
var album: ScrollContainer
var album_col: VBoxContainer
var album_buttons: Array = []

var menu_card: PanelContainer
var menu_col: VBoxContainer
var menu_avatar: TextureRect
var dialog_card: PanelContainer
var modal_dim: ColorRect
var menu_cast: HBoxContainer
var menu_title: Label
var menu_edition: Label
var story_card: PanelContainer
var heading_font: Font = preload("res://assets/fonts/DejaVuSerif.ttf")

# --- User interface: Godot native Control nodes (no HTML overlay) ---
func _panel(parent: Control, bg: Color=Color(0.04,0.09,0.16,0.9), radius: int=22) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.76,0.66,0.43,0.65)
	style.shadow_color = Color(0.015,0.045,0.05,0.30)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0,6)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	p.add_theme_stylebox_override("panel",style)
	parent.add_child(p)
	return p

func _label(parent: Node, text: String, font_size: int, tint: Color=Color("#f8ecd8")) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color",tint)
	l.add_theme_font_size_override("font_size",font_size)
	if font_size >= 24: l.add_theme_font_override("font",heading_font)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l

func _button(parent: Node, text: String, fn: Callable, minimum: Vector2=Vector2(150,44)) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = minimum
	b.add_theme_font_size_override("font_size",18)
	b.add_theme_color_override("font_color",Color("#fef1d8"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#38695e")
	style.border_color=Color("#d6bc80")
	style.set_border_width_all(1)
	style.shadow_color=Color(0,.06,.06,.25)
	style.shadow_size=4
	style.shadow_offset=Vector2(0,3)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(10)
	b.add_theme_stylebox_override("normal",style)
	var hover: StyleBoxFlat = style.duplicate()
	hover.bg_color = Color("#527e6d")
	b.add_theme_stylebox_override("hover",hover)
	var pressed: StyleBoxFlat = style.duplicate()
	pressed.bg_color=Color("#224d48")
	pressed.border_color=Color("#f2d393")
	b.add_theme_stylebox_override("pressed",pressed)
	var focus: StyleBoxFlat = style.duplicate()
	focus.bg_color=Color(0,0,0,0)
	focus.border_color=Color("#fff0af")
	focus.set_border_width_all(3)
	b.add_theme_stylebox_override("focus",focus)
	var disabled: StyleBoxFlat = style.duplicate()
	disabled.bg_color=Color("#d9d3bc")
	disabled.shadow_size=0
	b.add_theme_stylebox_override("disabled",disabled)
	b.add_theme_color_override("font_disabled_color",Color("#666d5a"))
	parent.add_child(b)
	b.pressed.connect(fn)
	b.mouse_entered.connect(func():
		if not quieter_motion:
			var t := create_tween()
			t.tween_property(b,"self_modulate",Color("#fff0cb"),.12))
	b.mouse_exited.connect(func(): b.self_modulate=Color.WHITE)
	b.button_down.connect(func(): _button_feedback(b,true))
	b.button_up.connect(func(): _button_feedback(b,false))
	return b

func _fill(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _center(control: Control, width_percent: float, height_percent: float) -> void:
	control.anchor_left = (1.0-width_percent)*0.5
	control.anchor_right = (1.0+width_percent)*0.5
	control.anchor_top = (1.0-height_percent)*0.5
	control.anchor_bottom = (1.0+height_percent)*0.5
	control.offset_left = 0
	control.offset_right = 0
	control.offset_top = 0
	control.offset_bottom = 0

func _build_ui() -> void:
	keepsake.load_assets()
	keepsake.install_story(tex)
	beauty_art.load_assets()
	object_art.load_assets()
	menu_layer = Control.new()
	menu_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	ui_canvas.add_child(menu_layer)
	_fill(menu_layer)
	menu_card = _panel(menu_layer,Color(0.969,0.945,0.879,0.96),28)
	var foil := preload("res://scripts/keepsake_frame.gd").new()
	menu_layer.add_child(foil)
	menu_card.resized.connect(func(): foil.position=menu_card.position;foil.size=menu_card.size)
	menu_col = VBoxContainer.new()
	menu_col.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_col.add_theme_constant_override("separation",10)
	menu_card.add_child(menu_col)
	menu_edition = _label(menu_col,"✦  THE STORYBOOK WELCOME EDITION  ✦",13,Color("#8f7340"))
	menu_title = _label(menu_col,"Ara the Panda",40,Color("#244e48"))
	_label(menu_col,"✧  Quest to Find Ira  ✧",25,Color("#67735c"))
	menu_cast = HBoxContainer.new()
	menu_cast.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_cast.add_theme_constant_override("separation",8)
	menu_col.add_child(menu_cast)
	for name in ["pip","bramble","ara","ira","moss"]:
		var avatar := TextureRect.new()
		avatar.texture = keepsake.portrait(name)
		avatar.custom_minimum_size = Vector2(65,105)
		avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		menu_cast.add_child(avatar)
	_label(menu_col,"Five little chapters. One very big hug.",17,Color("#5c6b5b"))
	continue_button=_button(menu_col,"CONTINUE ADVENTURE",journal.resume,Vector2(220,48))
	continue_button.visible=journal.has_checkpoint()
	var start_button := _button(menu_col,"NEW ADVENTURE",_new_adventure,Vector2(220,48))
	start_button.name="NewAdventure"
	if journal.has_checkpoint():
		var secondary: StyleBoxFlat=start_button.get_theme_stylebox("normal").duplicate()
		secondary.bg_color=Color("#e5ddc6")
		start_button.add_theme_stylebox_override("normal",secondary)
		start_button.add_theme_color_override("font_color",Color("#345c50"))
		start_button.add_theme_color_override("font_hover_color",Color("#fef1d8"))
	var menu_row := HBoxContainer.new()
	menu_row.alignment=BoxContainer.ALIGNMENT_CENTER
	menu_row.add_theme_constant_override("separation",12)
	menu_col.add_child(menu_row)
	_button(menu_row,"SETTINGS",_open_options,Vector2(110,42))
	_button(menu_row,"ALBUM",_open_album,Vector2(110,42))
	_button(menu_row,"CREDITS",func(): _show_dialog("Made with moonlight", "Moonlit Keepsake · v0.11.1\n\nNew original character poses and woodland illustrations, native Godot animation, five little quests, hidden wonders, and the music from the 2.4 Storybook edition.\n\nMade for curious paws and very big hugs. Heading font: DejaVu Serif (Bitstream Vera licence).", "BACK", "", "menu"),Vector2(110,42))
	_label(menu_col,"✦ A LITTLE LIGHT. A LOVELY ADVENTURE. ✦  v0.11.1",11,Color("#8b846d"))

	story_layer = Control.new()
	ui_canvas.add_child(story_layer)
	_fill(story_layer)
	var theme := Theme.new()
	theme.default_font_size=17
	for state_name in ["on","off"]:
		theme.set_icon(state_name,"CheckButton",load("res://assets/ui/toggle-"+state_name+".svg"))
	var option_paper := StyleBoxFlat.new()
	option_paper.bg_color=Color("#38695e");option_paper.border_color=Color("#d6bc80")
	option_paper.set_border_width_all(1);option_paper.set_corner_radius_all(10)
	option_paper.set_content_margin_all(8)
	for state_name in ["normal","hover","pressed","focus"]:
		theme.set_stylebox(state_name,"OptionButton",option_paper)
	var track := StyleBoxFlat.new()
	track.bg_color=Color("#c4b58a");track.set_corner_radius_all(3)
	theme.set_stylebox("slider","HSlider",track)
	for kind in ["CheckButton","OptionButton","HSlider"]:
		theme.set_color("font_color",kind,Color("#f5eddc"))
		theme.set_font_size("font_size",kind,17)
	ui_canvas.get_parent().theme=theme
	var comic_card := _panel(story_layer,Color(0.97,0.948,0.894,0.98),25)
	story_card = comic_card
	_center(comic_card,0.72,0.91)
	var story_col := VBoxContainer.new()
	story_col.add_theme_constant_override("separation",10)
	var story_outer := VBoxContainer.new()
	comic_card.add_child(story_outer)
	var story_scroll := ScrollContainer.new()
	story_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	story_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	story_outer.add_child(story_scroll)
	story_col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	story_scroll.add_child(story_col)
	story_caption = _label(story_col,"A bedtime story",15,Color("#8a734c"))
	story_title = _label(story_col,"The beginning",28,Color("#2b554e"))
	story_image = TextureRect.new()
	story_image.custom_minimum_size = Vector2(360,225)
	story_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	story_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	story_col.add_child(story_image)
	story_bubble = _label(story_col,"",21,Color("#8a644f"))
	story_body = _label(story_col,"",18,Color("#3f514b"))
	story_body.custom_minimum_size = Vector2(0,68)
	var story_row := HBoxContainer.new()
	story_row.alignment = BoxContainer.ALIGNMENT_CENTER
	story_row.add_theme_constant_override("separation",12)
	story_outer.add_child(story_row)
	story_back = _button(story_row,"BACK",_story_back)
	story_next = _button(story_row,"NEXT PAGE",_story_advance,Vector2(180,46))
	var skip := _button(story_row,"SKIP",_story_end,Vector2(80,44))
	skip.add_theme_font_size_override("font_size",14)

	hud_layer = Control.new()
	hud_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	ui_canvas.add_child(hud_layer)
	_fill(hud_layer)
	var title_plate := _panel(hud_layer,Color(0.06,0.14,0.19,0.86),16)
	title_plate.anchor_left = 0.02
	title_plate.anchor_top = 0.02
	title_plate.anchor_right = 0.36
	title_plate.anchor_bottom = 0.02
	title_plate.offset_bottom = 92
	var compact_style: StyleBoxFlat = title_plate.get_theme_stylebox("panel").duplicate()
	compact_style.bg_color=Color(.055,.12,.15,.68)
	compact_style.set_content_margin_all(12)
	title_plate.add_theme_stylebox_override("panel",compact_style)
	var title_col := VBoxContainer.new()
	title_col.add_theme_constant_override("separation",3)
	title_plate.add_child(title_col)
	hud_chapter = _label(title_col,"CHAPTER 1 OF 5",12,Color("#eed6a1"))
	hud_chapter.visible = true
	hud_title = _label(title_col,"Whispering Woods",17)
	hud_objective = _label(title_col,"Find the key",13)
	hud_discoveries = _label(title_col,"Explore with your lantern",14,Color("#a9e4df"))
	hud_discoveries.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hud_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hud_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hud_chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var hearts_plate := _panel(hud_layer,Color(0.06,0.14,0.19,0.82),16)
	hearts_plate.anchor_left = 0.81
	hearts_plate.anchor_right = 0.97
	hearts_plate.anchor_top = 0.02
	hearts_plate.anchor_bottom = 0.02
	hearts_plate.offset_bottom = 84
	var health_col := VBoxContainer.new()
	hearts_plate.add_child(health_col)
	hud_hearts = _label(health_col,"♥ ♥ ♥",18,Color("#ffb9bc"))
	hud_hearts.autowrap_mode=TextServer.AUTOWRAP_OFF
	hud_glow = _label(health_col,"GLOW READY",13,Color("#ffde9f"))
	var pause_button := _button(hud_layer,"",_pause,Vector2(48,48))
	_add_icon(pause_button,"pause")
	pause_button.anchor_left = 0.78
	pause_button.anchor_right = 0.78
	pause_button.anchor_top = 0.03
	pause_button.anchor_bottom = 0.03
	pause_button.offset_left = -27
	pause_button.offset_right = 27
	pause_button.offset_bottom = 52
	joystick=preload("res://scripts/woodland_joystick.gd").new()
	joystick.game=self
	hud_layer.add_child(joystick)
	joystick.anchor_top=1;joystick.anchor_bottom=1
	joystick.offset_left=24;joystick.offset_right=160
	joystick.offset_top=-160;joystick.offset_bottom=-24
	glow_button = _button(hud_layer,"GLOW",glow,Vector2(108,60))
	glow_button.anchor_left = 1
	glow_button.anchor_right = 1
	glow_button.anchor_top = 1
	glow_button.anchor_bottom = 1
	glow_button.offset_left = -136
	glow_button.offset_right = -24
	glow_button.offset_top = -152
	glow_button.offset_bottom = -88
	action_button = _button(hud_layer,"INTERACT",interact,Vector2(108,56))
	action_button.anchor_left = 1
	action_button.anchor_right = 1
	action_button.anchor_top = 1
	action_button.anchor_bottom = 1
	action_button.offset_left = -136
	action_button.offset_right = -24
	action_button.offset_top = -80
	action_button.offset_bottom = -24
	_add_icon(glow_button,"lantern")
	var readiness := preload("res://scripts/readiness_ring.gd").new()
	readiness.game=self
	glow_button.add_child(readiness)
	readiness.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_add_icon(action_button,"hand")
	glow_button.add_theme_font_size_override("font_size",13)
	action_button.add_theme_font_size_override("font_size",12)
	toast_label = _label(hud_layer,"",18,Color("#f9e8c0"))
	toast_label.anchor_left = 0.24
	toast_label.anchor_right = 0.76
	toast_label.anchor_top = 0.81
	toast_label.anchor_bottom = 0.91
	toast_label.visible = false

	modal_layer = Control.new()
	ui_canvas.add_child(modal_layer)
	_fill(modal_layer)
	var dim := ColorRect.new()
	modal_dim=dim
	dim.color = Color(0,0,0,0.42)
	modal_layer.add_child(dim)
	_fill(dim)
	var dialog := _panel(modal_layer,Color("#244e48"),26)
	dialog_card=dialog
	_center(dialog,0.66,0.80)
	var dcol := VBoxContainer.new()
	dcol.alignment = BoxContainer.ALIGNMENT_CENTER
	dcol.add_theme_constant_override("separation",10)
	var outer := VBoxContainer.new()
	dialog.add_child(outer)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	dcol.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(dcol)
	_label(dcol,"✦ A LITTLE MOMENT BY MOONLIGHT ✦",15,Color("#f8d79e"))
	modal_heading = _label(dcol,"Pause",28)
	modal_text = _label(dcol,"",19)
	modal_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	album=ScrollContainer.new()
	album.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	album.custom_minimum_size=Vector2(0,200)
	album.size_flags_vertical=Control.SIZE_EXPAND_FILL
	album.visible=false
	dcol.add_child(album)
	album_col=VBoxContainer.new()
	album_col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	album_col.add_theme_constant_override("separation",6)
	album.add_child(album_col)
	for chapter in range(5):
		var chapter_button: Button=_button(album_col,"",func(): _choose_chapter(chapter),Vector2(0,82))
		chapter_button.icon=load("res://screenshots/%s.png" % ["woods","glade","brook","hollow","garden"][chapter])
		chapter_button.expand_icon=true
		chapter_button.add_theme_constant_override("icon_max_width",90)
		chapter_button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		chapter_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		album_buttons.append(chapter_button)
	options_music = CheckButton.new()
	options_music.text = "Play music"
	options_music.button_pressed = music_enabled
	options_music.visible = false
	dcol.add_child(options_music)
	options_music.toggled.connect(_toggle_music)
	options_sound=CheckButton.new()
	options_sound.text="Woodland sounds"
	options_sound.button_pressed=sound_enabled
	options_sound.visible=false
	dcol.add_child(options_sound)
	options_sound.toggled.connect(func(yes: bool): sound_enabled=yes;journal.settings();soundscape.silence() if not yes else null)
	options_motion = CheckButton.new()
	options_motion.text = "Gentler motion"
	options_motion.button_pressed = quieter_motion
	options_motion.visible = false
	if options_quality != null: options_quality.visible = false
	dcol.add_child(options_motion)
	options_motion.toggled.connect(func(yes: bool): quieter_motion = yes;journal.settings())
	options_quality = OptionButton.new()
	options_quality.add_item("Graphics: Light")
	options_quality.add_item("Graphics: Balanced")
	options_quality.add_item("Graphics: Rich")
	options_quality.selected = graphics_quality
	options_quality.visible = false
	dcol.add_child(options_quality)
	options_quality.item_selected.connect(set_graphics_quality)

	volume_music=_volume_row(dcol,"Music volume",func(value: float): music_volume=value;menu_audio.volume_db=linear_to_db(value);game_audio.volume_db=linear_to_db(value);journal.settings())
	volume_effects=_volume_row(dcol,"Woodland volume",func(value: float): effects_volume=value;journal.settings())
	text_size=OptionButton.new()
	text_size.add_item("Text: Standard")
	text_size.add_item("Text: Larger")
	text_size.visible=false
	dcol.add_child(text_size)
	text_size.item_selected.connect(func(index: int): large_text=index==1;_apply_reading_size();journal.settings())
	var drow := HBoxContainer.new()
	drow.alignment = BoxContainer.ALIGNMENT_CENTER
	drow.add_theme_constant_override("separation",12)
	outer.add_child(drow)
	modal_primary = _button(drow,"CONTINUE",_resume,Vector2(145,46))
	modal_secondary = _button(drow,"TITLE",_return_menu,Vector2(145,46))
	_button(drow,"SETTINGS",func(): options_origin="resume";_open_options(),Vector2(110,46)).name="PauseSettings"

	conversation = load("res://scripts/conversation.gd").new()
	conversation.game = self
	ui_canvas.add_child(conversation)
	_apply_reading_size()

func _talk(npc: Dictionary) -> void:
	conversation.start(load("res://scripts/quest_dialogue.gd").talk(self,npc.id))

func _reunion() -> void:
	conversation.start(load("res://scripts/quest_dialogue.gd").reunion(),"replay")

func _direction_button(symbol: String, offset: Vector2, vector: Vector2) -> void:
	var button := _button(hud_layer,symbol,func(): pass,Vector2(57,57))
	button.anchor_left = 0
	button.anchor_right = 0
	button.anchor_top = 1
	button.anchor_bottom = 1
	button.offset_left = offset.x
	button.offset_right = offset.x + 57
	button.offset_top = offset.y - 57
	button.offset_bottom = offset.y
	var id := button.get_instance_id()
	button.button_down.connect(func(): _hold_direction(id, vector, true))
	button.button_up.connect(func(): _hold_direction(id, vector, false))
	button.mouse_exited.connect(func(): _hold_direction(id, vector, false))

func _start_intro() -> void:
	journal.reset_checkpoint()
	story_chapter = -1
	story_page = 0
	_show_story()

func _show_story() -> void:
	_set_state("comic")
	var pages: Array = INTRO if story_chapter < 0 else chapter_stories[story_chapter] if chapter_stories.size() > story_chapter else []
	if pages.is_empty():
		_story_end()
		return
	story_page = clampi(story_page,0,pages.size()-1)
	var p: Dictionary = pages[story_page]
	story_title.text = p.get("title", "The story continues")
	story_caption.text = p.get("caption", "") + "  ·  %d / %d" % [story_page + 1, pages.size()]
	if story_chapter>=0 and story_chapter==level_index: story_caption.text=beauty.result()
	story_body.text = p.get("text", "")
	story_bubble.text = "“%s”" % p.get("bubble", "")
	var scene: String = p.get("scene", "")
	var image_name := scene.get_file().get_basename()
	story_image.texture = tex.get(image_name)
	story_back.disabled = story_page == 0
	story_next.text = "START CHAPTER" if story_page == pages.size()-1 else "NEXT PAGE"

func _story_back() -> void:
	if story_page > 0:
		story_page -= 1
		_show_story()

func _story_advance() -> void:
	var count: int = INTRO.size() if story_chapter < 0 else chapter_stories[story_chapter].size() if chapter_stories.size()>story_chapter else 0
	if story_page < count-1:
		story_page += 1
		_show_story()
	else:
		_story_end()

func _story_end() -> void:
	var next_level := 0 if story_chapter < 0 else story_chapter+1
	story_chapter = -1
	start_level(next_level)

func _show_dialog(title: String, body: String, primary: String, secondary: String, action: String) -> void:
	conversation.dismiss()
	album.visible=false
	volume_music.get_parent().visible=false
	volume_effects.get_parent().visible=false
	text_size.visible=false
	dialog_card.find_child("PauseSettings",true,false).visible=action=="resume"
	modal_text.visible=true
	dialog_from = action
	if action=="replay":
		dialog_card.anchor_left=.20;dialog_card.anchor_right=.80
		dialog_card.anchor_top=.65;dialog_card.anchor_bottom=.98
		modal_dim.color=Color(0,0,0,.10)
	else:
		_center(dialog_card,.92 if size.x<700 else .76 if size.y<600 else .66,.92 if size.y<600 else .80)
		modal_dim.color=Color(0,0,0,.42)
	options_music.visible = false
	options_sound.visible = false
	options_motion.visible = false
	if options_quality != null: options_quality.visible = false
	modal_heading.text = title
	modal_text.text = body
	modal_primary.text = primary
	modal_secondary.text = secondary
	modal_secondary.visible = not secondary.is_empty()
	_set_state("dialog")

func _resume() -> void:
	if conversation.active:
		conversation.close()
		return
	if dialog_from.begins_with("travel-"):
		start_level(int(dialog_from.trim_prefix("travel-")))
		return
	if dialog_from=="newgame":
		_start_intro()
		return
	if state == "win":
		start_level(0)
		return
	if dialog_from == "options-pause": _set_state("play");_pause()
	elif dialog_from == "menu": _set_state("menu")
	elif dialog_from == "replay": start_level(0)
	else: _set_state("play")

func _return_menu() -> void:
	if (state in ["play","win"] or (state=="dialog" and dialog_from=="resume")) and not trees.is_empty(): journal.checkpoint()
	story_chapter = -1
	story_page = 0
	_set_state("menu")

func _pause() -> void:
	if state != "play": return
	journal.checkpoint()
	_show_dialog("A little breather", ("Progress saved. " if journal.last_error==OK else "Your progress could not be saved this time. ")+"The woods can wait.\n\nWASD / arrows to move · Space to glow · E to talk.\nUse the paw stick or tap a destination.","KEEP ADVENTURING","TITLE SCREEN","resume")

func _open_album() -> void:
	_show_dialog("Your woodland album", "Revisit a chapter to find every hidden wonder.
A crown needs 18 stars, 3 chests, and the chapter quest.", "BACK", "", "menu")
	album.visible=true
	var scores: Array=journal.data.get("best_scores",[0,0,0,0,0])
	var unlocked: int=maxi(int(journal.data.get("unlocked",0)),int(journal.data.get("checkpoint",{}).get("chapter",0)))
	for i in range(5):
		var best: int=int(scores[i]) if i<scores.size() else 0
		album_buttons[i].text="%d · %s · %s" % [i+1,BASE_LEVELS[i].title,"CROWN · 400" if best==400 else str(best)+" / 400" if i<=unlocked else "Not visited yet"]
		album_buttons[i].disabled=i>unlocked
	album.scroll_vertical=0
func _choose_chapter(chapter: int) -> void:
	if chapter>maxi(int(journal.data.get("unlocked",0)),int(journal.data.get("checkpoint",{}).get("chapter",0))): return
	_show_dialog("A fresh little expedition", "Return to "+str(BASE_LEVELS[chapter].title)+"? This replaces your current trail checkpoint. Your best scores and crowns stay in the album.","LET'S GO","TITLE SCREEN","travel-"+str(chapter))

func _open_options() -> void:
	var from_pause: bool = state=="dialog" and dialog_from=="resume"
	_show_dialog("Options", "Choose how your moonlit adventure feels.", "BACK", "", "menu")
	if from_pause: dialog_from="options-pause"
	volume_music.get_parent().visible=true
	volume_effects.get_parent().visible=true
	volume_music.set_value_no_signal(music_volume)
	volume_effects.set_value_no_signal(effects_volume)
	text_size.visible=true
	text_size.selected=int(large_text)
	options_music.button_pressed = music_enabled
	options_motion.button_pressed = quieter_motion
	options_music.visible = true
	options_sound.button_pressed=sound_enabled
	options_sound.visible=true
	options_motion.visible = true
	options_quality.selected = graphics_quality
	options_quality.visible = true

func _toggle_music(enabled: bool) -> void:
	music_enabled = enabled
	journal.settings()
	if not enabled:
		menu_audio.stop()
		game_audio.stop()
	else:
		if state == "menu" or state == "dialog":
			menu_audio.play()
		else:
			game_audio.play()

func _new_adventure() -> void:
	if journal.has_checkpoint():
		_show_dialog("A fresh little adventure?","Starting again replaces your saved adventure. Your sound, motion and graphics preferences stay with you.","START AGAIN","KEEP MY SAVE","newgame")
	else: _start_intro()

func _button_feedback(button: Button, down: bool) -> void:
	button.pivot_offset=button.size*.5
	button.scale=Vector2.ONE*(0.97 if down and not quieter_motion else 1.0)

func _add_icon(button: Button, kind: String) -> void:
	var icon := preload("res://scripts/storybook_icon.gd").new()
	icon.kind=kind
	button.add_child(icon)
	icon.anchor_left=.5;icon.anchor_right=.5
	icon.offset_left=-18;icon.offset_right=18
	icon.offset_top=2;icon.offset_bottom=34
	if kind!="pause":
		var style: StyleBoxFlat = button.get_theme_stylebox("normal").duplicate()
		style.content_margin_top=32
		button.add_theme_stylebox_override("normal",style)
		for state_name in ["hover","pressed"]:
			var other: StyleBoxFlat = button.get_theme_stylebox(state_name).duplicate()
			other.content_margin_top=32
			button.add_theme_stylebox_override(state_name,other)

func _layout_ui() -> void:
	if album!=null: album.custom_minimum_size.y=clampf(size.y*.45,100,340)
	if hud_title!=null:
		hud_title.add_theme_font_size_override("font_size",15 if size.y<500 else 17)
		hud_objective.add_theme_font_size_override("font_size",13 if size.y<500 else 15)
	if menu_cast!=null: menu_cast.visible=size.y>=600
	if menu_col!=null: menu_col.add_theme_constant_override("separation",7 if size.y<600 else 12)
	if menu_title!=null: menu_title.add_theme_font_size_override("font_size",32 if size.y<600 else 38)
	if menu_card!=null:
		menu_card.anchor_left=.055 if size.x/size.y>1.5 else .08
		menu_card.anchor_right=(.57 if size.x<1000 else .48) if size.x/size.y>1.5 else .92
		menu_card.anchor_top=.10 if size.y>=600 else .04
		menu_card.anchor_bottom=.90 if size.y>=600 else .96
	if story_card!=null:
		var compact: bool = size.y<600
		_center(story_card,.88 if compact else .72,.95 if compact else .91)
		story_image.custom_minimum_size=Vector2(260,180 if compact else 225)
		story_bubble.visible=true
		story_bubble.add_theme_font_size_override("font_size",16 if compact else 21)
		story_body.custom_minimum_size.y=38 if compact else 68
		story_title.add_theme_font_size_override("font_size",21 if compact else 28)
		story_body.add_theme_font_size_override("font_size",16 if compact else 18)
		story_caption.add_theme_font_size_override("font_size",13 if compact else 15)
		var story_col: VBoxContainer = story_card.get_child(0)
		story_col.add_theme_constant_override("separation",4 if size.y<400 else 5 if compact else 10)
		if size.y<400:
			story_image.custom_minimum_size.y=160
			story_body.custom_minimum_size.y=30
			story_body.add_theme_font_size_override("font_size",15)
			story_title.add_theme_font_size_override("font_size",19)
		var margin: float=10.0 if size.y<400 else 18.0
		var current: StyleBoxFlat=story_card.get_theme_stylebox("panel")
		if current.content_margin_top!=margin:
			var paper: StyleBoxFlat=current.duplicate()
			paper.content_margin_top=margin;paper.content_margin_bottom=margin
			story_card.add_theme_stylebox_override("panel",paper)
		_apply_reading_size()

func _volume_row(parent: Node, title: String, change: Callable) -> HSlider:
	var row := HBoxContainer.new()
	parent.add_child(row)
	row.visible=false
	var label := _label(row,title,17)
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	var slider := HSlider.new()
	slider.min_value=0.01;slider.max_value=1.0;slider.step=0.01
	slider.custom_minimum_size=Vector2(160,28)
	row.add_child(slider)
	slider.value_changed.connect(change)
	return slider

func _apply_reading_size() -> void:
	modal_text.add_theme_font_size_override("font_size",21 if large_text else 19)
	var reading: int=15 if size.y<400 else 16 if size.y<600 else 18
	story_body.add_theme_font_size_override("font_size",reading+(2 if large_text else 0))
	if conversation!=null: conversation._layout()

func _input(event: InputEvent) -> void:
	if joystick==null: return
	if event is InputEventScreenTouch:
		joystick.visible=true
		glow_button.text="GLOW"
	elif event is InputEventKey and event.pressed:
		joystick.visible=false
		glow_button.text="SPACE · GLOW"
