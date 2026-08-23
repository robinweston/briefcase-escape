extends CanvasLayer

const TITLE_BANNER := preload("res://assets/title_banner.png")
const OSWALD_FONT := preload("res://assets/fonts/oswald/Oswald-Variable.ttf")
const IBM_PLEX_MONO_FONT := preload("res://assets/fonts/ibm-plex-mono/IBMPlexMono-Regular.ttf")
const IBM_PLEX_MONO_MEDIUM_FONT := preload("res://assets/fonts/ibm-plex-mono/IBMPlexMono-Medium.ttf")

# Edit the title-screen copy here.
const START_PROMPT := "PRESS SPACE TO BEGIN"
const MISSION_TITLE := "CONFIDENTIAL MISSION FILE"
const MISSION_BYLINE := "MADE BY BOSS DUCK GAMES"
const HOW_TO_PLAY_HEADING := "HOW TO PLAY"
const HOW_TO_PLAY_STEPS := [
	"Escape three increasingly difficult office floors without being spotted.",
	"Enter disguise mode to look like a normal briefcase and avoid detection (although you may be tidied away!).",
	"Disguise mode can only be activated for a limited time.",
	"Collect potions to restore one second of disguise mode time.",
]
const CONTROLS_HEADING := "CONTROLS"
const CONTROL_KEY_HEADING := "KEY"
const CONTROL_ACTION_HEADING := "ACTION"
const CONTROL_ROWS := [
	["WASD / ARROWS", "MOVE"],
	["SPACE", "ENTER / EXIT DISGUISE MODE"],
	["P", "PAUSE"],
]


func _ready() -> void:
	layer = 20
	_build_screen()


func _build_screen() -> void:
	var backdrop := PanelContainer.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop_style := StyleBoxFlat.new()
	backdrop_style.bg_color = Color("#101a2d")
	backdrop.add_theme_stylebox_override("panel", backdrop_style)
	add_child(backdrop)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	backdrop.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 0)
	margin.add_child(content)

	var illustration := Control.new()
	illustration.custom_minimum_size = Vector2(0.0, 384.0)
	illustration.clip_contents = true
	content.add_child(illustration)
	_build_chase_illustration(illustration)
	_build_mission_file(content)
	_build_commit_indicator()


func _build_commit_indicator() -> void:
	var indicator := _make_mono_label("BUILD %s" % _get_build_commit(), 10, Color("#6d7b94"), true)
	indicator.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	indicator.offset_left = 12.0
	indicator.offset_top = -24.0
	indicator.offset_right = 160.0
	indicator.offset_bottom = -8.0
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(indicator)


func _get_build_commit() -> String:
	if not OS.has_feature("web"):
		return "DEV"
	var commit: Variant = JavaScriptBridge.eval(
		"window.BRIEFCASE_BUILD_COMMIT || 'UNKNOWN'",
		true,
	)
	if commit is String and not commit.is_empty():
		return commit
	return "UNKNOWN"


func _build_chase_illustration(parent: Control) -> void:
	var office := PanelContainer.new()
	office.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	var office_style := StyleBoxFlat.new()
	office_style.bg_color = Color("#d8e1e3")
	office_style.border_color = Color("#40516b")
	office_style.set_border_width_all(4)
	office_style.set_corner_radius_all(18)
	office.add_theme_stylebox_override("panel", office_style)
	parent.add_child(office)

	var banner := TextureRect.new()
	banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner.offset_left = 8.0
	banner.offset_top = 8.0
	banner.offset_right = -8.0
	banner.offset_bottom = -8.0
	banner.texture = TITLE_BANNER
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(banner)

	var prompt_panel := PanelContainer.new()
	prompt_panel.anchor_left = 0.32
	prompt_panel.anchor_right = 0.68
	prompt_panel.anchor_top = 1.0
	prompt_panel.anchor_bottom = 1.0
	prompt_panel.offset_top = -64.0
	prompt_panel.offset_bottom = -16.0
	prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var prompt_style := StyleBoxFlat.new()
	prompt_style.bg_color = Color(0.04, 0.07, 0.12, 0.86)
	prompt_style.content_margin_left = 16.0
	prompt_style.content_margin_right = 16.0
	prompt_panel.add_theme_stylebox_override("panel", prompt_style)
	parent.add_child(prompt_panel)

	var prompt := _make_oswald_label(START_PROMPT, 22, Color("#7bf1a8"))
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_panel.add_child(prompt)

	var pulse := create_tween().set_loops()
	pulse.tween_property(prompt_panel, "modulate:a", 0.35, 0.55)
	pulse.tween_property(prompt_panel, "modulate:a", 1.0, 0.55)


func _build_mission_file(parent: Control) -> void:
	var dossier := PanelContainer.new()
	var dossier_style := StyleBoxFlat.new()
	dossier_style.bg_color = Color("#e8dfc8")
	dossier_style.content_margin_left = 30.0
	dossier_style.content_margin_right = 30.0
	dossier_style.content_margin_top = 18.0
	dossier_style.content_margin_bottom = 20.0
	dossier.add_theme_stylebox_override("panel", dossier_style)
	parent.add_child(dossier)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	dossier.add_child(rows)

	var header := HBoxContainer.new()
	rows.add_child(header)
	var mission_title := _make_oswald_label(MISSION_TITLE, 19, Color("#8e281f"))
	mission_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(mission_title)
	var byline := _make_mono_label(MISSION_BYLINE, 12, Color("#5d594d"), true)
	byline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(byline)

	var first_rule := HSeparator.new()
	first_rule.modulate = Color(0.25, 0.23, 0.18, 0.42)
	rows.add_child(first_rule)

	var lower := HBoxContainer.new()
	lower.add_theme_constant_override("separation", 28)
	rows.add_child(lower)

	var how_to_play := VBoxContainer.new()
	how_to_play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	how_to_play.add_theme_constant_override("separation", 3)
	lower.add_child(how_to_play)
	how_to_play.add_child(_make_oswald_label(HOW_TO_PLAY_HEADING, 16, Color("#222018")))
	_build_how_to_play_steps(how_to_play)

	var divider := VSeparator.new()
	divider.modulate = Color(0.25, 0.23, 0.18, 0.3)
	lower.add_child(divider)

	var controls := VBoxContainer.new()
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_theme_constant_override("separation", 5)
	lower.add_child(controls)
	controls.add_child(_make_oswald_label(CONTROLS_HEADING, 16, Color("#222018")))
	_build_controls_table(controls)


func _build_how_to_play_steps(parent: Control) -> void:
	var steps := GridContainer.new()
	steps.columns = 2
	steps.add_theme_constant_override("h_separation", 10)
	steps.add_theme_constant_override("v_separation", 6)
	parent.add_child(steps)
	for index in HOW_TO_PLAY_STEPS.size():
		_add_how_to_play_step(steps, str(index + 1), HOW_TO_PLAY_STEPS[index])


func _add_how_to_play_step(parent: Control, number: String, copy: String) -> void:
	var number_label := _make_oswald_label(number, 13, Color("#8e281f"))
	number_label.custom_minimum_size = Vector2(18.0, 0.0)
	parent.add_child(number_label)
	var copy_label := _make_mono_label(copy, 12, Color("#222018"))
	copy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(copy_label)


func _build_controls_table(parent: Control) -> void:
	var table := GridContainer.new()
	table.columns = 2
	table.add_theme_constant_override("h_separation", 22)
	table.add_theme_constant_override("v_separation", 3)
	parent.add_child(table)

	var key_heading := _make_oswald_label(CONTROL_KEY_HEADING, 12, Color("#8e281f"))
	key_heading.custom_minimum_size = Vector2(145.0, 0.0)
	table.add_child(key_heading)
	table.add_child(_make_oswald_label(CONTROL_ACTION_HEADING, 12, Color("#8e281f")))
	for row in CONTROL_ROWS:
		_add_control_row(table, row[0], row[1])


func _add_control_row(parent: Control, key: String, action: String) -> void:
	var key_label := _make_oswald_label(key, 12, Color("#222018"))
	key_label.custom_minimum_size = Vector2(145.0, 0.0)
	parent.add_child(key_label)
	parent.add_child(_make_mono_label(action, 12, Color("#222018"), true))


func _make_oswald_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", OSWALD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_mono_label(text: String, font_size: int, color: Color, medium := false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", IBM_PLEX_MONO_MEDIUM_FONT if medium else IBM_PLEX_MONO_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
