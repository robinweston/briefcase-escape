extends Control

const WorkerFrames = preload("res://scripts/worker_sprite_frames.gd")
const MAIN_SCENE := preload("res://main.tscn")
const BRIEFCASE_ATLAS := preload("res://assets/briefcase_walk.svg")
const HIDDEN_BRIEFCASE := preload("res://assets/briefcase_hidden.svg")
const SCENERY_TEXTURES := [
	preload("res://assets/scenery/generated/workstation.png"),
	preload("res://assets/scenery/generated/divider.png"),
	preload("res://assets/scenery/generated/filing-cabinet.png"),
	preload("res://assets/scenery/generated/office-plant.png"),
	preload("res://assets/scenery/generated/exit-sign.png"),
	preload("res://assets/scenery/generated/disguise-potion.png"),
	preload("res://assets/scenery/generated/office-printer.png"),
	preload("res://assets/scenery/generated/vending-machine.png"),
	preload("res://assets/scenery/generated/bathroom-sinks.png"),
	preload("res://assets/scenery/generated/bathroom-toilet.png"),
	preload("res://assets/scenery/generated/boardroom-table.png"),
]
const SCENERY_NAMES := [
	"Workstation",
	"Cubicle Divider",
	"Filing Cabinet",
	"Office Plant",
	"Exit Sign",
	"Disguise Potion",
	"Office Printer",
	"Vending Machine",
	"Bathroom Sinks",
	"Bathroom Toilet",
	"Boardroom Table",
]
const DIRECTIONAL_SCENERY_ASSETS := {
	0: "workstation",
	2: "filing-cabinet",
	6: "office-printer",
	7: "vending-machine",
	8: "bathroom-sinks",
	9: "bathroom-toilet",
}
const PROP_DIRECTION_NAMES := ["S", "E", "N", "W"]
const MUSIC_TRACKS := [
	preload("res://assets/audio/stealth_in_the_woods.mp3"),
	preload("res://assets/audio/suspense.ogg"),
	preload("res://assets/audio/time_constraints.mp3"),
	preload("res://assets/audio/tension.mp3"),
]
const MUSIC_NAMES := ["Stealth in the Woods", "Suspense", "Time Constraints", "Tension"]
const MUSIC_DESCRIPTIONS := [
	"Dark, patient stealth atmosphere with a more cinematic sense of danger.",
	"Short ominous cue with an impending-doom feel and compact file size.",
	"Fast retro/MIDI-style pressure with a restless two-minute arrangement.",
	"A tighter 51-second MIDI loop: mechanical, anxious and game-like.",
]
const BUSY_OFFICE := preload("res://assets/audio/busy_office_ambience.mp3")
const SFX_ACTIONS := [
	"game_start", "disguise_on", "disguise_off", "potion_pickup",
	"worker_alert", "briefcase_pickup", "briefcase_drop", "caught",
	"level_complete", "pause", "resume",
]
const SFX_ACTION_NAMES := [
	"Game start", "Disguise on", "Disguise off", "Potion pickup",
	"Worker alert", "Briefcase pickup", "Briefcase drop", "Caught / reset",
	"Level complete", "Pause", "Resume",
]
const SFX_ACTION_DESCRIPTIONS := [
	"Leaves the title screen", "Transforms into an ordinary case",
	"Returns to playable form", "Restores disguise time", "A worker spots the player",
	"Worker lifts the case", "Worker puts the case down", "Detection failure sting",
	"Reaches the exit", "Freezes gameplay", "Returns to gameplay",
]
const SFX_OPTION_NAMES := ["Soft office", "Retro arcade", "Cinematic / cartoon"]
const SFX_SELECTED_OPTION := 0
const WORKER_ATLASES := [
	preload("res://assets/office_workers/animated/a-intern-atlas.svg"),
	preload("res://assets/office_workers/animated/b-anime-atlas.svg"),
	preload("res://assets/office_workers/animated/c-manager-atlas.svg"),
	preload("res://assets/office_workers/animated/d-analyst-atlas.svg"),
	preload("res://assets/office_workers/animated/e-supervisor-atlas.svg"),
	preload("res://assets/office_workers/animated/f-creative-atlas.svg"),
	preload("res://assets/office_workers/animated/g-coordinator-atlas.svg"),
	preload("res://assets/office_workers/animated/h-specialist-atlas.svg"),
]
const WORKER_NAMES := [
	"Eager Intern", "Anime Ace", "Tired Manager", "Precise Analyst",
	"Sharp Supervisor", "Cheerful Creative", "Calm Coordinator",
	"Resourceful Specialist",
]
const ROUTE_COLORS := [
	Color("#ef476f"), Color("#f78c3d"), Color("#ffd166"),
	Color("#06d6a0"), Color("#36a2eb"), Color("#9b5de5"),
	Color("#00a8a8"), Color("#7f5539"),
]
const STATES := [&"idle", &"walk", &"surprised", &"carry_cross"]
const STATE_LABELS := ["Idle", "Walk", "Caught: surprised", "Hidden catch: cross carry"]
const DIRECTIONS := [&"s", &"e", &"n", &"w"]
const DIRECTION_LABELS := ["Front / south", "Right / east", "Back / north", "Left / west"]
const BRIEFCASE_STATES := [&"idle", &"walk"]
const BRIEFCASE_STATE_LABELS := ["Idle", "Walk"]
const BRIEFCASE_FRAME_SIZE := Vector2(256.0, 256.0)

var sprites: Array[AnimatedSprite2D] = []
var state_index := 1
var direction_index := 0
var worker_state_picker: OptionButton
var worker_direction_picker: OptionButton
var worker_pause_button: Button
var paused := false
var briefcase_sprite: AnimatedSprite2D
var briefcase_state_picker: OptionButton
var briefcase_direction_picker: OptionButton
var briefcase_pause_button: Button
var briefcase_state_index := 1
var briefcase_direction_index := 0
var briefcase_paused := false
var gallery_tabs: TabContainer
var level_map_tabs: TabContainer
var music_player: AudioStreamPlayer
var office_player: AudioStreamPlayer
var audio_status: Label
var audio_progress: ProgressBar
var music_play_buttons: Array[Button] = []
var office_layer_toggle: CheckButton
var selected_music_index := -1
var office_only := false
var sfx_player: AudioStreamPlayer
var sfx_status: Label


func _ready() -> void:
	_configure_gallery_window()
	_build_ui()
	_refresh_animations()
	set_process(true)
	if not _level_map_capture_path().is_empty():
		_capture_level_map.call_deferred()


func _process(_delta: float) -> void:
	if not audio_progress:
		return
	if music_player and music_player.playing:
		audio_progress.value = music_player.get_playback_position()
	elif office_player and office_player.playing:
		audio_progress.value = office_player.get_playback_position()


func _configure_gallery_window() -> void:
	if DisplayServer.get_name() == "headless" or not _level_map_capture_path().is_empty():
		return
	get_window().mode = Window.MODE_MAXIMIZED


func _level_map_capture_path() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-level-map="):
			return argument.trim_prefix("--capture-level-map=")
	return ""


func _capture_level_map() -> void:
	for tab_index in gallery_tabs.get_tab_count():
		if gallery_tabs.get_tab_control(tab_index).name == &"Level Map":
			gallery_tabs.current_tab = tab_index
			break
	if level_map_tabs:
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--start-level="):
				level_map_tabs.current_tab = clampi(
					int(argument.trim_prefix("--start-level=")) - 1,
					0,
					level_map_tabs.get_tab_count() - 1
				)
				break

	# Wait for both the gallery and its embedded 3D viewport to finish drawing.
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var capture_path := _level_map_capture_path()
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(capture_path))
	if error == OK:
		print("Saved level map snapshot to %s" % capture_path)
	else:
		push_error("Could not save level map snapshot to %s (error %d)" % [capture_path, error])
	get_tree().quit(error)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_W:
			state_index = wrapi(state_index - 1, 0, STATES.size())
			_refresh_animations()
		KEY_S:
			state_index = wrapi(state_index + 1, 0, STATES.size())
			_refresh_animations()
		KEY_A:
			direction_index = wrapi(direction_index - 1, 0, DIRECTIONS.size())
			_refresh_animations()
		KEY_D:
			direction_index = wrapi(direction_index + 1, 0, DIRECTIONS.size())
			_refresh_animations()
		KEY_SPACE:
			paused = not paused
			_apply_worker_pause()


func _build_ui() -> void:
	var gallery_theme := Theme.new()
	gallery_theme.default_font_size = 20
	theme = gallery_theme

	var background := ColorRect.new()
	background.color = Color("#f3eadc")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var title := Label.new()
	title.text = "BRIEFCASE GAME ASSET GALLERY"
	title.position = Vector2(38.0, 18.0)
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("#2b2528"))
	add_child(title)

	var reload_button := Button.new()
	reload_button.text = "Reload assets"
	reload_button.position = Vector2(1030.0, 17.0)
	reload_button.size = Vector2(220.0, 44.0)
	reload_button.tooltip_text = "Restart the gallery and import changed assets"
	reload_button.pressed.connect(_on_reload_assets_pressed)
	add_child(reload_button)

	var tabs := TabContainer.new()
	gallery_tabs = tabs
	tabs.position = Vector2(28.0, 70.0)
	tabs.size = Vector2(1224.0, 630.0)
	tabs.add_theme_font_size_override("font_size", 22)
	add_child(tabs)

	var people_page := Control.new()
	people_page.name = "People"
	tabs.add_child(people_page)
	_build_people_page(people_page)

	var briefcase_page := Control.new()
	briefcase_page.name = "Briefcase"
	tabs.add_child(briefcase_page)
	_build_briefcase_page(briefcase_page)

	var scenery_page := Control.new()
	scenery_page.name = "Scenery"
	tabs.add_child(scenery_page)
	_build_scenery_page(scenery_page)

	var level_map_page := Control.new()
	level_map_page.name = "Level Map"
	tabs.add_child(level_map_page)
	_build_level_map_page(level_map_page)

	var audio_page := Control.new()
	audio_page.name = "Audio"
	tabs.add_child(audio_page)
	_build_audio_page(audio_page)
	_restore_selected_tab()


func _restore_selected_tab() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--gallery-tab="):
			gallery_tabs.current_tab = clampi(
				int(argument.trim_prefix("--gallery-tab=")),
				0,
				gallery_tabs.get_tab_count() - 1
			)
			return


func _on_reload_assets_pressed() -> void:
	var project_path := ProjectSettings.globalize_path("res://")
	var gallery_scene := ProjectSettings.globalize_path("res://asset_gallery.tscn")
	var arguments := PackedStringArray([
		"--path",
		project_path,
		gallery_scene,
		"--",
		"--gallery-tab=%d" % gallery_tabs.current_tab,
	])
	var process_id := OS.create_process(OS.get_executable_path(), arguments)
	if process_id > 0:
		get_tree().quit()
	else:
		get_tree().reload_current_scene()


func _build_people_page(page: Control) -> void:
	var animation_caption := Label.new()
	animation_caption.text = "Animation"
	animation_caption.position = Vector2(14.0, 12.0)
	animation_caption.add_theme_font_size_override("font_size", 21)
	animation_caption.add_theme_color_override("font_color", Color("#5f5356"))
	page.add_child(animation_caption)

	worker_state_picker = OptionButton.new()
	worker_state_picker.position = Vector2(104.0, 5.0)
	worker_state_picker.size = Vector2(260.0, 38.0)
	for label in STATE_LABELS:
		worker_state_picker.add_item(label)
	worker_state_picker.item_selected.connect(_on_worker_state_selected)
	page.add_child(worker_state_picker)

	var direction_caption := Label.new()
	direction_caption.text = "Direction"
	direction_caption.position = Vector2(390.0, 12.0)
	direction_caption.add_theme_font_size_override("font_size", 21)
	direction_caption.add_theme_color_override("font_color", Color("#5f5356"))
	page.add_child(direction_caption)

	worker_direction_picker = OptionButton.new()
	worker_direction_picker.position = Vector2(478.0, 5.0)
	worker_direction_picker.size = Vector2(215.0, 38.0)
	for label in DIRECTION_LABELS:
		worker_direction_picker.add_item(label)
	worker_direction_picker.item_selected.connect(_on_worker_direction_selected)
	page.add_child(worker_direction_picker)

	worker_pause_button = Button.new()
	worker_pause_button.position = Vector2(718.0, 5.0)
	worker_pause_button.size = Vector2(125.0, 38.0)
	worker_pause_button.pressed.connect(_on_worker_pause_pressed)
	page.add_child(worker_pause_button)

	var help := Label.new()
	help.text = "W/S: animation    A/D: direction    Space: pause"
	help.position = Vector2(865.0, 13.0)
	help.add_theme_font_size_override("font_size", 18)
	help.add_theme_color_override("font_color", Color("#786a6d"))
	page.add_child(help)

	for index in WORKER_ATLASES.size():
		var column := index % 4
		var row := index / 4
		var panel := Panel.new()
		panel.position = Vector2(6.0 + column * 301.0, 55.0 + row * 265.0)
		panel.size = Vector2(286.0, 240.0)
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color("#fffaf0")
		panel_style.border_color = Color("#dfd1be")
		panel_style.set_border_width_all(2)
		panel_style.set_corner_radius_all(18)
		panel.add_theme_stylebox_override("panel", panel_style)
		page.add_child(panel)

		var name_label := Label.new()
		name_label.text = WORKER_NAMES[index]
		name_label.position = panel.position + Vector2(14.0, 10.0)
		name_label.size = Vector2(258.0, 30.0)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 24)
		name_label.add_theme_color_override("font_color", Color("#322a2b"))
		page.add_child(name_label)

		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = WorkerFrames.create(WORKER_ATLASES[index])
		sprite.position = panel.position + Vector2(143.0, 140.0)
		sprite.scale = Vector2(1.08, 1.08)
		page.add_child(sprite)
		sprites.append(sprite)


func _build_briefcase_page(page: Control) -> void:
	var animation_caption := Label.new()
	animation_caption.text = "Animation"
	animation_caption.position = Vector2(14.0, 12.0)
	animation_caption.add_theme_font_size_override("font_size", 21)
	animation_caption.add_theme_color_override("font_color", Color("#5f5356"))
	page.add_child(animation_caption)

	briefcase_state_picker = OptionButton.new()
	briefcase_state_picker.position = Vector2(104.0, 5.0)
	briefcase_state_picker.size = Vector2(180.0, 38.0)
	for label in BRIEFCASE_STATE_LABELS:
		briefcase_state_picker.add_item(label)
	briefcase_state_picker.item_selected.connect(_on_briefcase_state_selected)
	page.add_child(briefcase_state_picker)

	var direction_caption := Label.new()
	direction_caption.text = "Direction"
	direction_caption.position = Vector2(315.0, 12.0)
	direction_caption.add_theme_font_size_override("font_size", 21)
	direction_caption.add_theme_color_override("font_color", Color("#5f5356"))
	page.add_child(direction_caption)

	briefcase_direction_picker = OptionButton.new()
	briefcase_direction_picker.position = Vector2(403.0, 5.0)
	briefcase_direction_picker.size = Vector2(215.0, 38.0)
	for label in DIRECTION_LABELS:
		briefcase_direction_picker.add_item(label)
	briefcase_direction_picker.item_selected.connect(_on_briefcase_direction_selected)
	page.add_child(briefcase_direction_picker)

	briefcase_pause_button = Button.new()
	briefcase_pause_button.position = Vector2(643.0, 5.0)
	briefcase_pause_button.size = Vector2(125.0, 38.0)
	briefcase_pause_button.pressed.connect(_on_briefcase_pause_pressed)
	page.add_child(briefcase_pause_button)

	var help := Label.new()
	help.text = "Animated player and ordinary hidden form"
	help.position = Vector2(794.0, 13.0)
	help.add_theme_font_size_override("font_size", 18)
	help.add_theme_color_override("font_color", Color("#786a6d"))
	page.add_child(help)

	var animated_panel := _gallery_panel(Vector2(70.0, 70.0), Vector2(500.0, 475.0))
	page.add_child(animated_panel)
	var animated_label := _gallery_panel_label("PLAYABLE BRIEFCASE", animated_panel.position, animated_panel.size.x)
	page.add_child(animated_label)
	briefcase_sprite = AnimatedSprite2D.new()
	briefcase_sprite.sprite_frames = _create_briefcase_frames()
	briefcase_sprite.position = animated_panel.position + Vector2(250.0, 275.0)
	briefcase_sprite.scale = Vector2(1.45, 1.45)
	page.add_child(briefcase_sprite)

	var hidden_panel := _gallery_panel(Vector2(630.0, 70.0), Vector2(500.0, 475.0))
	page.add_child(hidden_panel)
	var hidden_label := _gallery_panel_label("ORDINARY DISGUISE", hidden_panel.position, hidden_panel.size.x)
	page.add_child(hidden_label)
	var hidden_preview := Sprite2D.new()
	hidden_preview.texture = HIDDEN_BRIEFCASE
	hidden_preview.position = hidden_panel.position + Vector2(250.0, 275.0)
	hidden_preview.scale = Vector2(1.45, 1.45)
	page.add_child(hidden_preview)

	_refresh_briefcase_animation()


func _gallery_panel(at: Vector2, panel_size: Vector2) -> Panel:
	var panel := Panel.new()
	panel.position = at
	panel.size = panel_size
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#fffaf0")
	panel_style.border_color = Color("#dfd1be")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", panel_style)
	return panel


func _gallery_panel_label(text: String, at: Vector2, width: float) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at + Vector2(15.0, 15.0)
	label.size = Vector2(width - 30.0, 35.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 27)
	label.add_theme_color_override("font_color", Color("#322a2b"))
	return label


func _create_briefcase_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for row in DIRECTIONS.size():
		var direction: StringName = DIRECTIONS[row]
		for state_index_value in BRIEFCASE_STATES.size():
			var state: StringName = BRIEFCASE_STATES[state_index_value]
			var animation_name := StringName("%s_%s" % [state, direction])
			frames.add_animation(animation_name)
			frames.set_animation_loop(animation_name, state == &"walk")
			frames.set_animation_speed(animation_name, 9.0)
			var first_column := 0 if state == &"idle" else 1
			var frame_count := 1 if state == &"idle" else 4
			for frame_index in frame_count:
				var atlas_frame := AtlasTexture.new()
				atlas_frame.atlas = BRIEFCASE_ATLAS
				atlas_frame.region = Rect2(
					Vector2(first_column + frame_index, row) * BRIEFCASE_FRAME_SIZE,
					BRIEFCASE_FRAME_SIZE
				)
				frames.add_frame(animation_name, atlas_frame)
	return frames


func _build_scenery_page(page: Control) -> void:
	var intro := Label.new()
	intro.text = "Generated scenery sprites — the same illustrated language as the people and briefcase"
	intro.position = Vector2(16.0, 12.0)
	intro.add_theme_font_size_override("font_size", 21)
	intro.add_theme_color_override("font_color", Color("#5f5356"))
	page.add_child(intro)

	for index in SCENERY_TEXTURES.size():
		var column := index % 6
		var row := index / 6
		var panel := _gallery_panel(
			Vector2(8.0 + column * 199.0, 55.0 + row * 265.0),
			Vector2(187.0, 240.0)
		)
		panel.clip_contents = true
		page.add_child(panel)

		var name_label := _gallery_panel_label(SCENERY_NAMES[index], Vector2.ZERO, panel.size.x)
		name_label.add_theme_font_size_override("font_size", 21)
		panel.add_child(name_label)

		var directional_textures := _gallery_directional_prop_textures(index)
		if directional_textures.size() == 4:
			for direction_index in directional_textures.size():
				var preview := Sprite2D.new()
				preview.texture = directional_textures[direction_index]
				preview.position = Vector2(
					50.0 + (direction_index % 2) * 87.0,
					94.0 + (direction_index / 2) * 92.0
				)
				var texture_size := preview.texture.get_size()
				var fit_scale: float = min(72.0 / texture_size.x, 68.0 / texture_size.y)
				preview.scale = Vector2.ONE * fit_scale
				panel.add_child(preview)

				var direction_label := _gallery_panel_label(
					PROP_DIRECTION_NAMES[direction_index],
					preview.position + Vector2(-36.0, 34.0),
					72.0
				)
				direction_label.add_theme_font_size_override("font_size", 13)
				panel.add_child(direction_label)
		else:
			var preview := Sprite2D.new()
			preview.texture = SCENERY_TEXTURES[index]
			preview.position = Vector2(panel.size.x * 0.5, 142.0)
			var texture_size := preview.texture.get_size()
			var preview_bounds := Vector2(161.0, 176.0)
			var fit_scale: float = min(
				preview_bounds.x / texture_size.x,
				preview_bounds.y / texture_size.y
			)
			preview.scale = Vector2.ONE * fit_scale
			panel.add_child(preview)


func _gallery_directional_prop_textures(index: int) -> Array[Texture2D]:
	if not DIRECTIONAL_SCENERY_ASSETS.has(index):
		return []
	var textures: Array[Texture2D] = [SCENERY_TEXTURES[index]]
	var asset_name: String = DIRECTIONAL_SCENERY_ASSETS[index]
	for direction in ["east", "north", "west"]:
		var path := "res://assets/scenery/generated/%s-%s.png" % [asset_name, direction]
		if not ResourceLoader.exists(path):
			return []
		var texture := load(path) as Texture2D
		if texture == null:
			return []
		textures.append(texture)
	return textures


func _build_level_map_page(page: Control) -> void:
	level_map_tabs = TabContainer.new()
	level_map_tabs.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	level_map_tabs.add_theme_font_size_override("font_size", 18)
	page.add_child(level_map_tabs)
	var level_names := ["FIRST STEPS", "BOARDROOM BUZZ", "THE FULL OFFICE"]
	for level_number in range(1, 4):
		var level_page := Control.new()
		level_page.name = "LEVEL %d  ·  %s" % [level_number, level_names[level_number - 1]]
		level_map_tabs.add_child(level_page)
		_build_single_level_map_page(level_page, level_number)


func _build_single_level_map_page(page: Control, level_number: int) -> void:
	var page_background := ColorRect.new()
	page_background.color = Color("#f3eadc")
	page_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(page_background)

	var intro := Label.new()
	intro.text = "WHOLE-FLOOR SNAPSHOT  ·  live layout from the gameplay scene"
	intro.position = Vector2(16.0, 10.0)
	intro.add_theme_font_size_override("font_size", 20)
	intro.add_theme_color_override("font_color", Color("#5f5356"))
	page.add_child(intro)

	var map_frame := _gallery_panel(Vector2(8.0, 46.0), Vector2(925.0, 532.0))
	map_frame.clip_contents = true
	page.add_child(map_frame)

	var viewport_container := SubViewportContainer.new()
	viewport_container.position = Vector2(6.0, 6.0)
	viewport_container.size = map_frame.size - Vector2(12.0, 12.0)
	viewport_container.stretch = true
	map_frame.add_child(viewport_container)

	var map_viewport := SubViewport.new()
	map_viewport.size = Vector2i(913, 520)
	map_viewport.own_world_3d = true
	map_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	map_viewport.msaa_3d = Viewport.MSAA_4X
	viewport_container.add_child(map_viewport)

	var level := MAIN_SCENE.instantiate()
	map_viewport.add_child(level)
	level.call("load_level_for_gallery", level_number)
	for child in level.get_children():
		if child is CanvasLayer:
			child.visible = false
	for player_name in [&"music_player", &"office_ambience_player", &"sfx_player"]:
		var embedded_player: AudioStreamPlayer = level.get(player_name)
		if embedded_player:
			embedded_player.stop()
	level.process_mode = Node.PROCESS_MODE_DISABLED

	var gameplay_camera: Camera3D = level.get("camera")
	if gameplay_camera:
		gameplay_camera.current = false
	var overview_camera := Camera3D.new()
	overview_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	overview_camera.size = 21.5
	overview_camera.position = Vector3(0.0, 25.0, 0.0)
	level.add_child(overview_camera)
	overview_camera.look_at(Vector3.ZERO, Vector3(0.0, 0.0, -1.0))
	overview_camera.current = true

	var workers_value: Variant = level.get("workers")
	for worker_value in workers_value:
		var worker: Dictionary = worker_value
		var cone: MeshInstance3D = worker["cone"]
		cone.visible = false

	var routes_value: Variant = level.get("worker_routes")
	for route_index in routes_value.size():
		_add_patrol_route_overlay(
			level,
			routes_value[route_index],
			ROUTE_COLORS[route_index % ROUTE_COLORS.size()],
			route_index + 1
		)

	var legend := VBoxContainer.new()
	legend.position = Vector2(955.0, 55.0)
	legend.size = Vector2(250.0, 500.0)
	legend.add_theme_constant_override("separation", 12)
	page.add_child(legend)

	var legend_title := Label.new()
	legend_title.text = "WORKER ROUTES"
	legend_title.add_theme_font_size_override("font_size", 22)
	legend_title.add_theme_color_override("font_color", Color("#322a2b"))
	legend.add_child(legend_title)
	for index in routes_value.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		legend.add_child(row)
		var swatch := ColorRect.new()
		swatch.color = ROUTE_COLORS[index]
		swatch.custom_minimum_size = Vector2(22.0, 22.0)
		row.add_child(swatch)
		var route_label := Label.new()
		route_label.text = "%d  %s" % [index + 1, WORKER_NAMES[index]]
		route_label.add_theme_font_size_override("font_size", 17)
		route_label.add_theme_color_override("font_color", Color("#453c3e"))
		row.add_child(route_label)

	var stationary_count: int = workers_value.size() - routes_value.size()
	if stationary_count > 0:
		var stationary_label := Label.new()
		stationary_label.text = "+ %d stationary coworkers" % stationary_count
		stationary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stationary_label.add_theme_font_size_override("font_size", 16)
		stationary_label.add_theme_color_override("font_color", Color("#453c3e"))
		legend.add_child(stationary_label)

	var note := Label.new()
	note.text = "Routes are drawn over the real office geometry. Coloured dots mark turning points; every path closes into a loop."
	note.custom_minimum_size = Vector2(235.0, 100.0)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 16)
	note.add_theme_color_override("font_color", Color("#786a6d"))
	legend.add_child(note)


func _add_patrol_route_overlay(
	level: Node3D,
	route: PackedVector3Array,
	color: Color,
	route_number: int
) -> void:
	var route_material := StandardMaterial3D.new()
	route_material.albedo_color = Color(color, 0.9)
	route_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	route_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	route_material.no_depth_test = true
	route_material.render_priority = 1

	for point_index in route.size():
		var from := route[point_index]
		var to := route[(point_index + 1) % route.size()]
		var delta := to - from
		var segment := MeshInstance3D.new()
		var segment_mesh := BoxMesh.new()
		segment_mesh.size = Vector3(0.14, 0.035, delta.length())
		segment.mesh = segment_mesh
		segment.material_override = route_material
		segment.position = (from + to) * 0.5 + Vector3(0.0, 0.08, 0.0)
		segment.rotation.y = atan2(delta.x, delta.z)
		segment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		level.add_child(segment)

	for point_index in route.size():
		var marker := MeshInstance3D.new()
		var marker_mesh := CylinderMesh.new()
		marker_mesh.top_radius = 0.25
		marker_mesh.bottom_radius = 0.25
		marker_mesh.height = 0.05
		marker.mesh = marker_mesh
		marker.material_override = route_material
		marker.position = route[point_index] + Vector3(0.0, 0.11, 0.0)
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		level.add_child(marker)

	var number_label := Label3D.new()
	number_label.text = str(route_number)
	number_label.font_size = 48
	number_label.pixel_size = 0.018
	number_label.modulate = Color("#17202e")
	number_label.outline_modulate = Color.WHITE
	number_label.outline_size = 8
	number_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	number_label.no_depth_test = true
	var first_segment := route[1] - route[0]
	var label_offset := Vector3(-first_segment.z, 0.0, first_segment.x).normalized() * 0.38
	number_label.position = (
		(route[0] + route[1]) * 0.5 + label_offset + Vector3(0.0, 0.16, 0.0)
	)
	level.add_child(number_label)


func _build_audio_page(page: Control) -> void:
	var audio_tabs := TabContainer.new()
	audio_tabs.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	audio_tabs.add_theme_font_size_override("font_size", 19)
	page.add_child(audio_tabs)

	var music_page := Control.new()
	music_page.name = "Music"
	audio_tabs.add_child(music_page)
	_build_music_page(music_page)

	var sfx_page := Control.new()
	sfx_page.name = "Sound FX — 3 options each"
	audio_tabs.add_child(sfx_page)
	_build_sfx_page(sfx_page)


func _build_music_page(page: Control) -> void:
	var intro := Label.new()
	intro.text = "CC0 soundtrack candidates — audition each track with or without the busy office layer"
	intro.position = Vector2(16.0, 12.0)
	intro.add_theme_font_size_override("font_size", 21)
	intro.add_theme_color_override("font_color", Color("#5f5356"))
	page.add_child(intro)

	office_layer_toggle = CheckButton.new()
	office_layer_toggle.text = "Layer busy office"
	office_layer_toggle.button_pressed = true
	office_layer_toggle.position = Vector2(945.0, 7.0)
	office_layer_toggle.size = Vector2(230.0, 38.0)
	office_layer_toggle.toggled.connect(_on_office_layer_toggled)
	page.add_child(office_layer_toggle)

	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -8.0
	page.add_child(music_player)
	office_player = AudioStreamPlayer.new()
	office_player.volume_db = 5.0
	office_player.stream = _make_looping_stream(BUSY_OFFICE)
	page.add_child(office_player)

	for index in MUSIC_TRACKS.size():
		var panel := _gallery_panel(Vector2(20.0, 54.0 + index * 97.0), Vector2(1160.0, 82.0))
		page.add_child(panel)

		var title_label := Label.new()
		title_label.text = MUSIC_NAMES[index]
		title_label.position = panel.position + Vector2(22.0, 9.0)
		title_label.size = Vector2(760.0, 28.0)
		title_label.add_theme_font_size_override("font_size", 23)
		title_label.add_theme_color_override("font_color", Color("#322a2b"))
		page.add_child(title_label)

		var description := Label.new()
		description.text = MUSIC_DESCRIPTIONS[index]
		description.position = panel.position + Vector2(22.0, 42.0)
		description.size = Vector2(850.0, 28.0)
		description.add_theme_font_size_override("font_size", 17)
		description.add_theme_color_override("font_color", Color("#786a6d"))
		page.add_child(description)

		var play_button := Button.new()
		play_button.text = "Play candidate"
		play_button.position = panel.position + Vector2(935.0, 17.0)
		play_button.size = Vector2(190.0, 48.0)
		play_button.pressed.connect(_play_music_track.bind(index))
		page.add_child(play_button)
		music_play_buttons.append(play_button)

	var office_panel := _gallery_panel(Vector2(20.0, 446.0), Vector2(1160.0, 68.0))
	page.add_child(office_panel)
	var office_label := Label.new()
	office_label.text = "Busy Office Ambience — real chatter, ringing phone, writing and typing"
	office_label.position = office_panel.position + Vector2(22.0, 19.0)
	office_label.size = Vector2(870.0, 30.0)
	office_label.add_theme_font_size_override("font_size", 20)
	page.add_child(office_label)
	var office_button := Button.new()
	office_button.text = "Play ambience only"
	office_button.position = office_panel.position + Vector2(935.0, 10.0)
	office_button.size = Vector2(190.0, 48.0)
	office_button.pressed.connect(_play_office_only)
	page.add_child(office_button)

	var controls_panel := _gallery_panel(Vector2(20.0, 527.0), Vector2(1160.0, 58.0))
	page.add_child(controls_panel)
	audio_status = Label.new()
	audio_status.text = "Ready — office layer is on"
	audio_status.position = controls_panel.position + Vector2(22.0, 9.0)
	audio_status.size = Vector2(520.0, 28.0)
	audio_status.add_theme_font_size_override("font_size", 19)
	page.add_child(audio_status)

	audio_progress = ProgressBar.new()
	audio_progress.position = controls_panel.position + Vector2(430.0, 19.0)
	audio_progress.size = Vector2(425.0, 20.0)
	audio_progress.max_value = 1.0
	audio_progress.show_percentage = false
	page.add_child(audio_progress)

	var stop_button := Button.new()
	stop_button.text = "Stop"
	stop_button.position = controls_panel.position + Vector2(1030.0, 7.0)
	stop_button.size = Vector2(105.0, 44.0)
	stop_button.pressed.connect(_stop_audio)
	page.add_child(stop_button)
	_refresh_audio_buttons()


func _build_sfx_page(page: Control) -> void:
	var intro := Label.new()
	intro.text = "Option 1 · Soft office is selected for gameplay — all candidates remain available for comparison"
	intro.position = Vector2(16.0, 10.0)
	intro.size = Vector2(1160.0, 28.0)
	intro.add_theme_font_size_override("font_size", 19)
	intro.add_theme_color_override("font_color", Color("#5f5356"))
	page.add_child(intro)

	var heading := HBoxContainer.new()
	heading.position = Vector2(22.0, 43.0)
	heading.size = Vector2(1140.0, 30.0)
	heading.add_theme_constant_override("separation", 10)
	page.add_child(heading)
	var action_heading := Label.new()
	action_heading.text = "GAME ACTION"
	action_heading.custom_minimum_size = Vector2(510.0, 28.0)
	action_heading.add_theme_color_override("font_color", Color("#786a6d"))
	heading.add_child(action_heading)
	for option_name in SFX_OPTION_NAMES:
		var option_heading := Label.new()
		option_heading.text = option_name.to_upper()
		option_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		option_heading.custom_minimum_size = Vector2(190.0, 28.0)
		option_heading.add_theme_font_size_override("font_size", 16)
		option_heading.add_theme_color_override("font_color", Color("#786a6d"))
		heading.add_child(option_heading)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(16.0, 76.0)
	scroll.size = Vector2(1175.0, 430.0)
	page.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.custom_minimum_size = Vector2(1145.0, SFX_ACTIONS.size() * 70.0)
	rows.add_theme_constant_override("separation", 6)
	scroll.add_child(rows)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.volume_db = -3.0
	sfx_player.finished.connect(_on_sfx_finished)
	page.add_child(sfx_player)

	for action_index in SFX_ACTIONS.size():
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(1135.0, 64.0)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#fffaf0") if action_index % 2 == 0 else Color("#eee4d5")
		style.set_corner_radius_all(7)
		style.content_margin_left = 14.0
		style.content_margin_right = 10.0
		style.content_margin_top = 5.0
		style.content_margin_bottom = 5.0
		panel.add_theme_stylebox_override("panel", style)
		rows.add_child(panel)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		panel.add_child(row)
		var copy := VBoxContainer.new()
		copy.custom_minimum_size = Vector2(486.0, 52.0)
		copy.add_theme_constant_override("separation", 0)
		row.add_child(copy)
		var action_label := Label.new()
		action_label.text = SFX_ACTION_NAMES[action_index]
		action_label.add_theme_font_size_override("font_size", 19)
		action_label.add_theme_color_override("font_color", Color("#322a2b"))
		copy.add_child(action_label)
		var description := Label.new()
		description.text = SFX_ACTION_DESCRIPTIONS[action_index]
		description.add_theme_font_size_override("font_size", 15)
		description.add_theme_color_override("font_color", Color("#786a6d"))
		copy.add_child(description)

		for option_index in 3:
			var play_button := Button.new()
			play_button.text = "%s Option %d" % [
				"✓" if option_index == SFX_SELECTED_OPTION else "▶", option_index + 1
			]
			play_button.custom_minimum_size = Vector2(190.0, 48.0)
			play_button.tooltip_text = "%s — %s" % [
				SFX_ACTION_NAMES[action_index], SFX_OPTION_NAMES[option_index]
			]
			play_button.pressed.connect(_play_sfx.bind(action_index, option_index))
			row.add_child(play_button)

	var status_panel := _gallery_panel(Vector2(16.0, 517.0), Vector2(1175.0, 52.0))
	page.add_child(status_panel)
	sfx_status = Label.new()
	sfx_status.text = "Ready — scroll to audition all 36 candidates"
	sfx_status.position = status_panel.position + Vector2(18.0, 10.0)
	sfx_status.size = Vector2(930.0, 30.0)
	sfx_status.add_theme_font_size_override("font_size", 18)
	page.add_child(sfx_status)
	var stop_button := Button.new()
	stop_button.text = "Stop"
	stop_button.position = status_panel.position + Vector2(1035.0, 5.0)
	stop_button.size = Vector2(120.0, 42.0)
	stop_button.pressed.connect(_stop_audio)
	page.add_child(stop_button)


func _play_sfx(action_index: int, option_index: int) -> void:
	music_player.stop()
	office_player.stop()
	var resource_path := "res://assets/audio/sfx/%s_%d.wav" % [
		SFX_ACTIONS[action_index], option_index + 1
	]
	sfx_player.stream = load(resource_path)
	sfx_player.play()
	sfx_status.text = "Playing: %s — %s (Option %d)" % [
		SFX_ACTION_NAMES[action_index], SFX_OPTION_NAMES[option_index], option_index + 1
	]
	_refresh_audio_buttons()


func _on_sfx_finished() -> void:
	sfx_status.text = "Ready — choose another candidate"


func _make_looping_stream(source: AudioStream) -> AudioStream:
	var looping_stream := source.duplicate() as AudioStream
	if looping_stream is AudioStreamOggVorbis:
		(looping_stream as AudioStreamOggVorbis).loop = true
	elif looping_stream is AudioStreamMP3:
		(looping_stream as AudioStreamMP3).loop = true
	return looping_stream


func _play_music_track(index: int) -> void:
	selected_music_index = index
	office_only = false
	music_player.stream = _make_looping_stream(MUSIC_TRACKS[index])
	music_player.play()
	if office_layer_toggle.button_pressed:
		office_player.play()
	else:
		office_player.stop()
	audio_progress.value = 0.0
	audio_progress.max_value = maxf(music_player.stream.get_length(), 1.0)
	audio_status.text = "Playing: %s%s" % [
		MUSIC_NAMES[index], " + busy office" if office_layer_toggle.button_pressed else ""
	]
	_refresh_audio_buttons()


func _play_office_only() -> void:
	office_only = true
	selected_music_index = -1
	music_player.stop()
	office_player.play()
	audio_progress.value = 0.0
	audio_progress.max_value = maxf(office_player.stream.get_length(), 1.0)
	audio_status.text = "Playing: Busy Office Ambience"
	_refresh_audio_buttons()


func _stop_audio() -> void:
	music_player.stop()
	office_player.stop()
	if sfx_player:
		sfx_player.stop()
	audio_progress.value = 0.0
	audio_status.text = "Stopped"
	if sfx_status:
		sfx_status.text = "Stopped"
	_refresh_audio_buttons()


func _on_office_layer_toggled(enabled: bool) -> void:
	if office_only:
		return
	if music_player.playing and enabled:
		office_player.play()
	elif not enabled:
		office_player.stop()
	if selected_music_index >= 0 and music_player.playing:
		audio_status.text = "Playing: %s%s" % [
			MUSIC_NAMES[selected_music_index], " + busy office" if enabled else ""
		]


func _refresh_audio_buttons() -> void:
	for index in music_play_buttons.size():
		music_play_buttons[index].text = (
			"Playing…" if music_player.playing and index == selected_music_index else "Play candidate"
		)


func _refresh_animations() -> void:
	var animation_name := StringName("%s_%s" % [STATES[state_index], DIRECTIONS[direction_index]])
	for sprite in sprites:
		sprite.play(animation_name)
		if paused:
			sprite.pause()
	worker_state_picker.select(state_index)
	worker_direction_picker.select(direction_index)
	worker_pause_button.text = "Resume" if paused else "Pause"


func _apply_worker_pause() -> void:
	for sprite in sprites:
		if paused:
			sprite.pause()
		else:
			sprite.play()
	worker_pause_button.text = "Resume" if paused else "Pause"


func _on_worker_state_selected(index: int) -> void:
	state_index = index
	_refresh_animations()


func _on_worker_direction_selected(index: int) -> void:
	direction_index = index
	_refresh_animations()


func _on_worker_pause_pressed() -> void:
	paused = not paused
	_apply_worker_pause()


func _refresh_briefcase_animation() -> void:
	if not briefcase_sprite:
		return
	var animation_name := StringName(
		"%s_%s" % [BRIEFCASE_STATES[briefcase_state_index], DIRECTIONS[briefcase_direction_index]]
	)
	briefcase_sprite.play(animation_name)
	if briefcase_paused:
		briefcase_sprite.pause()
	briefcase_state_picker.select(briefcase_state_index)
	briefcase_direction_picker.select(briefcase_direction_index)
	briefcase_pause_button.text = "Resume" if briefcase_paused else "Pause"


func _on_briefcase_state_selected(index: int) -> void:
	briefcase_state_index = index
	_refresh_briefcase_animation()


func _on_briefcase_direction_selected(index: int) -> void:
	briefcase_direction_index = index
	_refresh_briefcase_animation()


func _on_briefcase_pause_pressed() -> void:
	briefcase_paused = not briefcase_paused
	_refresh_briefcase_animation()
