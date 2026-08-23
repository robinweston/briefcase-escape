extends Node3D

const WORLD_HALF_SIZE := 7.5
const MOVE_SPEED := 4.2
const PEOPLE := [
	[Vector3(-3.3, 0.0, -2.2), Color("#ef8354"), Color("#283044")],
	[Vector3(0.0, 0.0, -3.2), Color("#7bdff2"), Color("#2d3142")],
	[Vector3(3.4, 0.0, -1.4), Color("#b8f2e6"), Color("#5e548e")],
	[Vector3(-2.2, 0.0, 2.5), Color("#f7aef8"), Color("#38405f")],
	[Vector3(2.1, 0.0, 2.8), Color("#fde74c"), Color("#404e4d")],
]

var player: CharacterBody3D
var camera: Camera3D


func _ready() -> void:
	_build_world()
	_build_player()
	_build_camera()
	_build_hud()


func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var desired := Vector3.ZERO

	if input_vector.length() > 0.05:
		# Screen-relative movement: up travels toward the top of the isometric view.
		desired = Vector3(input_vector.x + input_vector.y, 0.0, -input_vector.x + input_vector.y).normalized()

	player.velocity = desired * MOVE_SPEED
	player.move_and_slide()
	player.position.x = clampf(player.position.x, -WORLD_HALF_SIZE, WORLD_HALF_SIZE)
	player.position.z = clampf(player.position.z, -WORLD_HALF_SIZE, WORLD_HALF_SIZE)

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#182238")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#dce8ff")
	env.ambient_light_energy = 0.65
	environment.environment = env
	add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	sun.light_color = Color("#fff3d6")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(WORLD_HALF_SIZE * 2.25, WORLD_HALF_SIZE * 2.25)
	ground.mesh = ground_mesh
	ground.material_override = _material(Color("#446b58"), 0.92)
	add_child(ground)

	_add_grid()
	for person_data in PEOPLE:
		_add_person(person_data[0], person_data[1], person_data[2])


func _add_grid() -> void:
	var grid := ImmediateMesh.new()
	grid.surface_begin(Mesh.PRIMITIVE_LINES)
	var line_color := Color(0.75, 0.9, 0.8, 0.14)
	for i in range(-7, 8):
		grid.surface_set_color(line_color)
		grid.surface_add_vertex(Vector3(i, 0.012, -WORLD_HALF_SIZE))
		grid.surface_set_color(line_color)
		grid.surface_add_vertex(Vector3(i, 0.012, WORLD_HALF_SIZE))
		grid.surface_set_color(line_color)
		grid.surface_add_vertex(Vector3(-WORLD_HALF_SIZE, 0.012, i))
		grid.surface_set_color(line_color)
		grid.surface_add_vertex(Vector3(WORLD_HALF_SIZE, 0.012, i))
	grid.surface_end()
	var grid_instance := MeshInstance3D.new()
	grid_instance.mesh = grid
	grid_instance.material_override = _material(Color(0.75, 0.9, 0.8, 0.14), 1.0)
	add_child(grid_instance)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Briefcase"
	player.position = Vector3.ZERO
	add_child(player)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 0.82
	collision.shape = shape
	collision.position.y = 0.42
	player.add_child(collision)

	var sprite := Sprite3D.new()
	sprite.texture = load("res://assets/briefcase.svg")
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.position.y = 0.78
	sprite.pixel_size = 0.0033
	sprite.no_depth_test = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	player.add_child(sprite)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "IsometricCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.5
	camera.position = Vector3(10.0, 12.0, 10.0)
	add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.current = true


func _add_person(at: Vector3, shirt_color: Color, trouser_color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = at
	add_child(body)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.6
	collision.shape = shape
	collision.position.y = 0.82
	body.add_child(collision)

	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.36
	torso_mesh.height = 1.25
	torso.mesh = torso_mesh
	torso.position.y = 0.9
	torso.material_override = _material(shirt_color)
	body.add_child(torso)

	var legs := MeshInstance3D.new()
	var legs_mesh := BoxMesh.new()
	legs_mesh.size = Vector3(0.5, 0.55, 0.4)
	legs.mesh = legs_mesh
	legs.position.y = 0.3
	legs.material_override = _material(trouser_color)
	body.add_child(legs)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.28
	head_mesh.height = 0.56
	head.mesh = head_mesh
	head.position.y = 1.68
	head.material_override = _material(Color("#d6a77a"))
	body.add_child(head)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var panel := PanelContainer.new()
	panel.position = Vector2(20.0, 20.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.055, 0.09, 0.88)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.content_margin_left = 18.0
	panel_style.content_margin_right = 18.0
	panel_style.content_margin_top = 14.0
	panel_style.content_margin_bottom = 14.0
	panel.add_theme_stylebox_override("panel", panel_style)
	layer.add_child(panel)

	var copy := VBoxContainer.new()
	panel.add_child(copy)
	var title := Label.new()
	title.text = "BRIEFCASE"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#ffd166"))
	copy.add_child(title)
	var help := Label.new()
	help.text = "Move with WASD\nor the arrow keys"
	help.add_theme_font_size_override("font_size", 15)
	help.add_theme_color_override("font_color", Color("#e8eefc"))
	copy.add_child(help)


func _material(color: Color, roughness := 0.8) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material
