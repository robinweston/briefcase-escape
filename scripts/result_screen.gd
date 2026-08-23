extends CanvasLayer

const OSWALD_FONT := preload("res://assets/fonts/oswald/Oswald-Variable.ttf")
const IBM_PLEX_MONO_FONT := preload("res://assets/fonts/ibm-plex-mono/IBMPlexMono-Regular.ttf")
const IBM_PLEX_MONO_MEDIUM_FONT := preload("res://assets/fonts/ibm-plex-mono/IBMPlexMono-Medium.ttf")

var backdrop: ColorRect
var report_card: PanelContainer
var report_heading: Label
var stamp_panel: PanelContainer
var stamp_label: Label
var prompt_label: Label
var pulse_tween: Tween


func _ready() -> void:
	layer = 30
	_build_screen()
	hide_report()


func show_report(succeeded: bool, floor_number: int) -> void:
	report_heading.text = "ESCAPE REPORT · FLOOR %02d" % floor_number
	stamp_label.text = "CLEARED" if succeeded else "CAUGHT"
	prompt_label.text = "PRESS START: NEXT LEVEL" if succeeded else "PRESS SPACE TO RETRY"

	var stamp_color := Color("#168568") if succeeded else Color("#bd2f35")
	stamp_label.add_theme_color_override("font_color", stamp_color)
	var stamp_style := stamp_panel.get_theme_stylebox("panel") as StyleBoxFlat
	stamp_style.border_color = stamp_color

	visible = true
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(prompt_label, "modulate:a", 0.42, 0.55)
	pulse_tween.tween_property(prompt_label, "modulate:a", 1.0, 0.55)


func hide_report() -> void:
	visible = false
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	pulse_tween = null


func is_report_visible() -> bool:
	return visible


func _build_screen() -> void:
	backdrop = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.025, 0.045, 0.075, 0.74)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	report_card = PanelContainer.new()
	report_card.set_anchors_preset(Control.PRESET_CENTER)
	report_card.position = Vector2(-260.0, -168.0)
	report_card.size = Vector2(520.0, 336.0)
	report_card.pivot_offset = report_card.size * 0.5
	report_card.rotation_degrees = -1.5
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#f5e6be")
	card_style.border_color = Color("#1f242d")
	card_style.set_border_width_all(7)
	card_style.set_corner_radius_all(8)
	card_style.shadow_color = Color(0.015, 0.02, 0.035, 0.75)
	card_style.shadow_size = 14
	card_style.shadow_offset = Vector2(0.0, 12.0)
	card_style.content_margin_left = 34.0
	card_style.content_margin_right = 34.0
	card_style.content_margin_top = 28.0
	card_style.content_margin_bottom = 28.0
	report_card.add_theme_stylebox_override("panel", card_style)
	backdrop.add_child(report_card)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 16)
	report_card.add_child(rows)

	report_heading = _make_mono_label("ESCAPE REPORT · FLOOR 01", 17, Color("#565044"), true)
	rows.add_child(report_heading)

	var top_rule := HSeparator.new()
	top_rule.modulate = Color(0.42, 0.37, 0.25, 0.48)
	rows.add_child(top_rule)

	stamp_panel = PanelContainer.new()
	stamp_panel.custom_minimum_size = Vector2(0.0, 128.0)
	var stamp_style := StyleBoxFlat.new()
	stamp_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	stamp_style.border_color = Color("#bd2f35")
	stamp_style.set_border_width_all(9)
	stamp_style.set_corner_radius_all(5)
	stamp_panel.add_theme_stylebox_override("panel", stamp_style)
	rows.add_child(stamp_panel)

	stamp_label = Label.new()
	stamp_label.text = "CAUGHT"
	stamp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stamp_label.add_theme_font_override("font", OSWALD_FONT)
	stamp_label.add_theme_font_size_override("font_size", 76)
	stamp_label.add_theme_color_override("font_color", Color("#bd2f35"))
	stamp_panel.add_child(stamp_label)

	var bottom_rule := HSeparator.new()
	bottom_rule.modulate = Color(0.42, 0.37, 0.25, 0.48)
	rows.add_child(bottom_rule)

	prompt_label = _make_mono_label("PRESS SPACE TO RETRY", 18, Color("#24262d"), true)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(prompt_label)


func _make_mono_label(text: String, font_size: int, color: Color, medium := false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", IBM_PLEX_MONO_MEDIUM_FONT if medium else IBM_PLEX_MONO_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
