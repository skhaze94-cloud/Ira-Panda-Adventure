extends "res://scripts/render.gd"

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
	style.border_color = Color(0.77,0.82,0.73,0.33)
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
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l

func _button(parent: Node, text: String, fn: Callable, minimum: Vector2=Vector2(150,44)) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = minimum
	b.add_theme_font_size_override("font_size",18)
	b.add_theme_color_override("font_color",Color("#fef1d8"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#426c69")
	style.set_corner_radius_all(16)
	style.set_content_margin_all(10)
	b.add_theme_stylebox_override("normal",style)
	var hover: StyleBoxFlat = style.duplicate()
	hover.bg_color = Color("#648f88")
	b.add_theme_stylebox_override("hover",hover)
	b.add_theme_stylebox_override("pressed",hover)
	parent.add_child(b)
	b.pressed.connect(fn)
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
	menu_layer = Control.new()
	menu_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	ui_canvas.add_child(menu_layer)
	_fill(menu_layer)
	var menu_card := _panel(menu_layer,Color(0.05,0.12,0.17,0.91),28)
	_center(menu_card,0.52,0.75)
	var menu_col := VBoxContainer.new()
	menu_col.add_theme_constant_override("separation",16)
	menu_card.add_child(menu_col)
	_label(menu_col,"✦ LITTLE TALKS, BIG ADVENTURE · v0.4 ✦",17,Color("#e8d6a4"))
	_label(menu_col,"ARA THE PANDA",42)
	_label(menu_col,"Quest to Find Ira",28,Color("#fedbb3"))
	var avatar := TextureRect.new()
	avatar.texture = tex.get("ara")
	avatar.custom_minimum_size = Vector2(110,146)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	menu_col.add_child(avatar)
	_label(menu_col,"Five little chapters. One very big hug.",18)
	_button(menu_col,"START ADVENTURE",_start_intro,Vector2(220,56))
	_button(menu_col,"OPTIONS",_open_options,Vector2(190,46))
	_button(menu_col,"CREDITS",func(): _show_dialog("Made with moonlight", "Ara and Ira's artwork, five original woodland chapters, and the music from the 2.4 Storybook edition.\n\nGodot conversion: native GDScript, Godot Controls, 2D CanvasItem, and input handling.","BACK", "", "menu"),Vector2(190,46))

	story_layer = Control.new()
	ui_canvas.add_child(story_layer)
	_fill(story_layer)
	var comic_card := _panel(story_layer,Color(0.055,0.095,0.16,0.96),25)
	_center(comic_card,0.72,0.91)
	var story_col := VBoxContainer.new()
	story_col.add_theme_constant_override("separation",10)
	comic_card.add_child(story_col)
	story_caption = _label(story_col,"A bedtime story",16,Color("#f8cf98"))
	story_title = _label(story_col,"The beginning",30)
	story_image = TextureRect.new()
	story_image.custom_minimum_size = Vector2(360,225)
	story_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	story_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	story_col.add_child(story_image)
	story_bubble = _label(story_col,"",22,Color("#ffe3b3"))
	story_body = _label(story_col,"",19)
	story_body.custom_minimum_size = Vector2(0,68)
	var story_row := HBoxContainer.new()
	story_row.alignment = BoxContainer.ALIGNMENT_CENTER
	story_row.add_theme_constant_override("separation",12)
	story_col.add_child(story_row)
	story_back = _button(story_row,"BACK",_story_back)
	story_next = _button(story_row,"NEXT PAGE",_story_advance,Vector2(180,46))
	_button(story_col,"SKIP STORY",_story_end,Vector2(100,35))

	hud_layer = Control.new()
	hud_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	ui_canvas.add_child(hud_layer)
	_fill(hud_layer)
	var title_plate := _panel(hud_layer,Color(0.06,0.14,0.19,0.86),16)
	title_plate.anchor_left = 0.02
	title_plate.anchor_top = 0.02
	title_plate.anchor_right = 0.43
	title_plate.anchor_bottom = 0.02
	title_plate.offset_bottom = 112
	var title_col := VBoxContainer.new()
	title_col.add_theme_constant_override("separation",3)
	title_plate.add_child(title_col)
	hud_chapter = _label(title_col,"CHAPTER 1 OF 5",12,Color("#eed6a1"))
	hud_chapter.visible = false
	hud_title = _label(title_col,"Whispering Woods",18)
	hud_objective = _label(title_col,"Find the key",14)
	hud_discoveries = _label(title_col,"Explore with your lantern",12,Color("#a9e4df"))
	hud_discoveries.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hud_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hud_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hud_chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var hearts_plate := _panel(hud_layer,Color(0.06,0.14,0.19,0.82),16)
	hearts_plate.anchor_left = 0.79
	hearts_plate.anchor_right = 0.97
	hearts_plate.anchor_top = 0.02
	hearts_plate.anchor_bottom = 0.02
	hearts_plate.offset_bottom = 100
	var health_col := VBoxContainer.new()
	hearts_plate.add_child(health_col)
	hud_hearts = _label(health_col,"♥ ♥ ♥",22,Color("#ffb9bc"))
	hud_glow = _label(health_col,"LANTERN READY",13,Color("#ffde9f"))
	var pause_button := _button(hud_layer,"Ⅱ",_pause,Vector2(54,52))
	pause_button.anchor_left = 0.735
	pause_button.anchor_right = 0.735
	pause_button.anchor_top = 0.03
	pause_button.anchor_bottom = 0.03
	pause_button.offset_left = -27
	pause_button.offset_right = 27
	pause_button.offset_bottom = 52
	var pad_origin := Vector2(36, -30)
	_direction_button("▲",Vector2(pad_origin.x+62, pad_origin.y-140),Vector2(0,-1))
	_direction_button("◀",Vector2(pad_origin.x, pad_origin.y-77),Vector2(-1,0))
	_direction_button("▼",Vector2(pad_origin.x+62,pad_origin.y-77),Vector2(0,1))
	_direction_button("▶",Vector2(pad_origin.x+124,pad_origin.y-77),Vector2(1,0))
	glow_button = _button(hud_layer,"✦ GLOW",glow,Vector2(126,64))
	glow_button.anchor_left = 1
	glow_button.anchor_right = 1
	glow_button.anchor_top = 1
	glow_button.anchor_bottom = 1
	glow_button.offset_left = -178
	glow_button.offset_right = -36
	glow_button.offset_top = -150
	glow_button.offset_bottom = -86
	action_button = _button(hud_layer,"INTERACT",interact,Vector2(126,58))
	action_button.anchor_left = 1
	action_button.anchor_right = 1
	action_button.anchor_top = 1
	action_button.anchor_bottom = 1
	action_button.offset_left = -178
	action_button.offset_right = -36
	action_button.offset_top = -77
	action_button.offset_bottom = -19
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
	dim.color = Color(0,0,0,0.62)
	modal_layer.add_child(dim)
	_fill(dim)
	var dialog := _panel(modal_layer,Color(0.065,0.13,0.18,0.98),26)
	_center(dialog,0.60,0.60)
	var dcol := VBoxContainer.new()
	dcol.alignment = BoxContainer.ALIGNMENT_CENTER
	dcol.add_theme_constant_override("separation",17)
	dialog.add_child(dcol)
	_label(dcol,"✦ A LITTLE MOMENT BY MOONLIGHT ✦",15,Color("#f8d79e"))
	modal_heading = _label(dcol,"Pause",28)
	modal_text = _label(dcol,"",19)
	modal_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	options_music = CheckButton.new()
	options_music.text = "Play music"
	options_music.button_pressed = music_enabled
	options_music.visible = false
	dcol.add_child(options_music)
	options_music.toggled.connect(_toggle_music)
	options_motion = CheckButton.new()
	options_motion.text = "Gentler motion"
	options_motion.button_pressed = quieter_motion
	options_motion.visible = false
	if options_quality != null: options_quality.visible = false
	dcol.add_child(options_motion)
	options_motion.toggled.connect(func(yes: bool): quieter_motion = yes)
	options_quality = OptionButton.new()
	options_quality.add_item("Graphics: Light")
	options_quality.add_item("Graphics: Balanced")
	options_quality.add_item("Graphics: Rich")
	options_quality.selected = graphics_quality
	options_quality.visible = false
	dcol.add_child(options_quality)
	options_quality.item_selected.connect(set_graphics_quality)

	var drow := HBoxContainer.new()
	drow.alignment = BoxContainer.ALIGNMENT_CENTER
	drow.add_theme_constant_override("separation",12)
	dcol.add_child(drow)
	modal_primary = _button(drow,"CONTINUE",_resume,Vector2(175,50))
	modal_secondary = _button(drow,"TITLE",_return_menu,Vector2(175,50))

	conversation = load("res://scripts/conversation.gd").new()
	conversation.game = self
	ui_canvas.add_child(conversation)

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
	dialog_from = action
	options_music.visible = false
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
	if state == "win":
		start_level(0)
		return
	if dialog_from == "menu": _set_state("menu")
	elif dialog_from == "replay": start_level(0)
	else: _set_state("play")

func _return_menu() -> void:
	story_chapter = -1
	story_page = 0
	_set_state("menu")

func _pause() -> void:
	if state != "play": return
	_show_dialog("A little breather", "The woods can wait. Your lantern is still glowing.\n\nWASD / arrow keys to move · Space to glow · E to talk.\nTap a destination or use the direction pad on touchscreens.","KEEP ADVENTURING","TITLE SCREEN","resume")

func _open_options() -> void:
	_show_dialog("Options", "Choose how your moonlit adventure feels.", "BACK", "", "menu")
	options_music.button_pressed = music_enabled
	options_motion.button_pressed = quieter_motion
	options_music.visible = true
	options_motion.visible = true
	options_quality.selected = graphics_quality
	options_quality.visible = true

func _toggle_music(enabled: bool) -> void:
	music_enabled = enabled
	if not enabled:
		menu_audio.stop()
		game_audio.stop()
	else:
		if state == "menu" or state == "dialog":
			menu_audio.play()
		else:
			game_audio.play()
