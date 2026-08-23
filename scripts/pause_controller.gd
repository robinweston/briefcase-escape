extends CanvasLayer

const SFX_PAUSE := preload("res://assets/audio/sfx/pause_1.wav")
const SFX_RESUME := preload("res://assets/audio/sfx/resume_1.wav")

var pause_overlay: PanelContainer
var sound_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	_build_overlay()
	sound_player = AudioStreamPlayer.new()
	sound_player.process_mode = Node.PROCESS_MODE_ALWAYS
	sound_player.volume_db = -3.0
	add_child(sound_player)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_pause"):
		var paused := not get_tree().paused
		get_tree().paused = paused
		pause_overlay.visible = paused
		sound_player.stream = SFX_PAUSE if paused else SFX_RESUME
		sound_player.play()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if get_tree():
		get_tree().paused = false


func _build_overlay() -> void:
	pause_overlay = PanelContainer.new()
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.visible = false
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := StyleBoxFlat.new()
	backdrop.bg_color = Color(0.02, 0.03, 0.06, 0.78)
	pause_overlay.add_theme_stylebox_override("panel", backdrop)
	add_child(pause_overlay)

	var message := Label.new()
	message.text = "PAUSED\nPress P to resume"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 38)
	message.add_theme_color_override("font_color", Color("#ffd166"))
	pause_overlay.add_child(message)
