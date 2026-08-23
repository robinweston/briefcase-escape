extends Node3D

const WORLD_X_HALF := 15.0
const WORLD_Z_HALF := 10.0
const MOVE_SPEED := 4.2
const WORKER_SPEED := 1.35
const VISION_RANGE := 3.8
const VISION_HALF_ANGLE := deg_to_rad(30.0)
const VISION_RAY_COUNT := 17
const START_POSITION := Vector3(-13.5, 0.0, 8.3)
const EXIT_POSITION := Vector3(13.5, 0.0, -8.3)
const CAMERA_OFFSET := Vector3(0.0, 12.0, 10.0)
const WorkerFrames = preload("res://scripts/worker_sprite_frames.gd")
const TitleScreen = preload("res://scripts/title_screen.gd")
const PauseController = preload("res://scripts/pause_controller.gd")
const BRIEFCASE_ATLAS := preload("res://assets/briefcase_walk.svg")
const HIDDEN_BRIEFCASE_TEXTURE := preload("res://assets/briefcase_hidden.svg")
const FLOOR_CARPET_BLUE_GREY := preload("res://assets/flooring/office-carpet-blue-grey.png")
const FLOOR_CARPET_TEAL := preload("res://assets/flooring/office-carpet-teal-accent.png")
const FLOOR_LINOLEUM := preload("res://assets/flooring/office-linoleum-terracotta.png")
const FLOOR_WOOD := preload("res://assets/flooring/office-wood-dark.png")
const FLOOR_TINT := Color("#929b9c")
const WORKSTATION_TEXTURE := preload("res://assets/scenery/generated/workstation.png")
const DIVIDER_TEXTURE := preload("res://assets/scenery/generated/divider.png")
const FILING_CABINET_TEXTURE := preload("res://assets/scenery/generated/filing-cabinet.png")
const OFFICE_PLANT_TEXTURE := preload("res://assets/scenery/generated/office-plant.png")
const START_ZONE_TEXTURE := preload("res://assets/scenery/generated/start-zone.png")
const EXIT_SIGN_TEXTURE := preload("res://assets/scenery/generated/exit-sign.png")
const DISGUISE_POTION_TEXTURE := preload("res://assets/scenery/generated/disguise-potion.png")
const LEVEL_MUSIC := preload("res://assets/audio/stealth_in_the_woods.mp3")
const OFFICE_AMBIENCE := preload("res://assets/audio/busy_office_ambience.mp3")
const SFX_GAME_START := preload("res://assets/audio/sfx/game_start_1.wav")
const SFX_DISGUISE_ON := preload("res://assets/audio/sfx/disguise_on_1.wav")
const SFX_DISGUISE_OFF := preload("res://assets/audio/sfx/disguise_off_1.wav")
const SFX_POTION_PICKUP := preload("res://assets/audio/sfx/potion_pickup_1.wav")
const SFX_WORKER_ALERT := preload("res://assets/audio/sfx/worker_alert_1.wav")
const SFX_BRIEFCASE_PICKUP := preload("res://assets/audio/sfx/briefcase_pickup_1.wav")
const SFX_BRIEFCASE_DROP := preload("res://assets/audio/sfx/briefcase_drop_1.wav")
const SFX_CAUGHT := preload("res://assets/audio/sfx/caught_1.wav")
const SFX_LEVEL_COMPLETE := preload("res://assets/audio/sfx/level_complete_1.wav")
const WORKER_ATLASES := [
	preload("res://assets/office_workers/animated/a-intern-atlas.svg"),
	preload("res://assets/office_workers/animated/b-anime-atlas.svg"),
	preload("res://assets/office_workers/animated/c-manager-atlas.svg"),
	preload("res://assets/office_workers/animated/d-analyst-atlas.svg"),
	preload("res://assets/office_workers/animated/e-supervisor-atlas.svg"),
	preload("res://assets/office_workers/animated/f-creative-atlas.svg"),
]
const BRIEFCASE_DIRECTIONS := [&"s", &"e", &"n", &"w"]
const BRIEFCASE_FRAME_SIZE := Vector2(256.0, 256.0)
const BRIEFCASE_WALK_FPS := 9.0
const HIDDEN_TIME_MAX := 5.0
const POTION_REFILL := 1.0
const CARRY_SPEED := 2.25
const TRANSFORM_TIME := 0.28
const PROP_INK := Color("#26344a")
const WORKER_SPRITE_PIXEL_SIZE := 0.0108
const POTION_POSITIONS := [
	Vector3(-12.8, 0.0, -7.2),
	Vector3(-11.0, 0.0, 0.2),
	Vector3(-6.0, 0.0, 4.8),
	Vector3(0.0, 0.0, 7.6),
	Vector3(0.0, 0.0, -7.6),
	Vector3(6.0, 0.0, 4.8),
	Vector3(11.0, 0.0, -0.2),
	Vector3(12.8, 0.0, 7.2),
]

var worker_routes: Array[PackedVector3Array] = [
	PackedVector3Array([Vector3(-11.5, 0.0, 7.8), Vector3(-3.6, 0.0, 7.8)]),
	PackedVector3Array([Vector3(-10.5, 0.0, 2.5), Vector3(1.5, 0.0, 2.5)]),
	PackedVector3Array([Vector3(-1.5, 0.0, -2.5), Vector3(10.5, 0.0, -2.5)]),
	PackedVector3Array([Vector3(3.8, 0.0, -7.8), Vector3(11.6, 0.0, -7.8)]),
	PackedVector3Array([Vector3(-6.0, 0.0, 6.8), Vector3(-6.0, 0.0, -1.7)]),
	PackedVector3Array([Vector3(6.0, 0.0, 1.8), Vector3(6.0, 0.0, -6.8)]),
]

var player: CharacterBody3D
var player_sprite: AnimatedSprite3D
var hidden_sprite: Sprite3D
var player_collision: CollisionShape3D
var player_facing := &"s"
var camera: Camera3D
var workers: Array[Dictionary] = []
var cubicle_drop_points: Array[Vector3] = []
var potions: Array[Node3D] = []
var status_label: Label
var hidden_time_bar: ProgressBar
var hidden_time_label: Label
var resetting := false
var level_complete := false
var hidden_mode := false
var hidden_time := HIDDEN_TIME_MAX
var is_transforming := false
var pickup_worker: Dictionary = {}
var carrying_worker: Dictionary = {}
var carry_target := Vector3.ZERO
var pickup_route := PackedVector3Array()
var pickup_route_index := 0
var carry_route := PackedVector3Array()
var carry_route_index := 0
var pickup_cooldown := 0.0
var transformation_tween: Tween
var gameplay_hud: CanvasLayer
var title_screen: CanvasLayer
var title_screen_active := false
var music_player: AudioStreamPlayer
var office_ambience_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer


func _ready() -> void:
	_build_world()
	_build_player()
	_build_workers()
	_build_camera()
	_build_hud()
	_build_audio()
	_update_hidden_time_hud()
	if not _should_skip_title_screen():
		_show_title_screen()


func _unhandled_input(event: InputEvent) -> void:
	if title_screen_active:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
			_start_first_level()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_disguise") and not resetting and not level_complete:
		if carrying_worker.is_empty() and not is_transforming:
			_set_hidden_mode(not hidden_mode)


func _physics_process(delta: float) -> void:
	if title_screen_active:
		player.velocity = Vector3.ZERO
		_set_player_animation(Vector2.ZERO)
		return
	if resetting or level_complete:
		player.velocity = Vector3.ZERO
		_set_player_animation(Vector2.ZERO)
		return

	pickup_cooldown = maxf(0.0, pickup_cooldown - delta)
	_update_workers(delta)
	if carrying_worker.is_empty() and pickup_worker.is_empty():
		_update_player()
		_collect_nearby_potion()
	else:
		player.velocity = Vector3.ZERO
	_update_camera(delta)

	if not carrying_worker.is_empty():
		return
	if not pickup_worker.is_empty():
		if not hidden_mode:
			_caught(pickup_worker)
		else:
			_drain_hidden_time(delta)
		return

	var seeing_worker := _worker_that_sees_player()
	if not seeing_worker.is_empty():
		if hidden_mode and pickup_cooldown <= 0.0:
			_begin_carry(seeing_worker)
		elif not hidden_mode:
			_caught(seeing_worker)
		return

	if hidden_mode:
		_drain_hidden_time(delta)

	if player.global_position.distance_to(EXIT_POSITION) < 0.8:
		_complete_level()


func _drain_hidden_time(delta: float) -> void:
	hidden_time = maxf(0.0, hidden_time - delta)
	_update_hidden_time_hud()
	if hidden_time <= 0.0:
		_set_hidden_mode(false)


func _update_player() -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	input_vector = _cardinal_input(input_vector)
	_set_player_animation(input_vector)
	var desired := Vector3.ZERO
	if input_vector.length() > 0.05:
		# The camera is aligned to the world axes, so screen and world directions match.
		desired = Vector3(input_vector.x, 0.0, input_vector.y)

	player.velocity = desired * MOVE_SPEED
	player.move_and_slide()
	player.position.x = clampf(player.position.x, -WORLD_X_HALF, WORLD_X_HALF)
	player.position.z = clampf(player.position.z, -WORLD_Z_HALF, WORLD_Z_HALF)


func _cardinal_input(input_vector: Vector2) -> Vector2:
	if absf(input_vector.x) > absf(input_vector.y):
		return Vector2(signf(input_vector.x), 0.0)
	if absf(input_vector.y) > 0.05:
		return Vector2(0.0, signf(input_vector.y))
	return Vector2.ZERO


func _set_player_animation(input_vector: Vector2) -> void:
	var animation_name: StringName
	if input_vector.length() > 0.05:
		player_facing = _screen_direction_name(input_vector)
		animation_name = StringName("walk_%s" % player_facing)
	else:
		animation_name = StringName("idle_%s" % player_facing)

	if player_sprite.animation != animation_name or not player_sprite.is_playing():
		player_sprite.play(animation_name)


func _screen_direction_name(input_vector: Vector2) -> StringName:
	if absf(input_vector.x) > absf(input_vector.y):
		return &"e" if input_vector.x > 0.0 else &"w"
	return &"s" if input_vector.y > 0.0 else &"n"


func _update_workers(_delta: float) -> void:
	for worker in workers:
		var body: CharacterBody3D = worker["body"]
		if not carrying_worker.is_empty() and body == carrying_worker["body"]:
			_update_carrying_worker(worker)
			_update_vision_cone(worker)
			continue
		if not pickup_worker.is_empty() and body == pickup_worker["body"]:
			_update_pickup_worker(worker)
			_update_vision_cone(worker)
			continue
		var route: PackedVector3Array = worker["route"]
		var target: Vector3 = route[worker["index"]]
		var offset := target - body.position
		offset.y = 0.0

		if offset.length() < 0.12:
			worker["index"] = (worker["index"] + 1) % route.size()
			target = route[worker["index"]]
			offset = target - body.position
			offset.y = 0.0

		var direction := _cardinal_world_direction(offset)
		body.velocity = direction * WORKER_SPEED
		body.rotation.y = atan2(-direction.x, -direction.z)
		_set_worker_animation(worker, &"walk", direction)
		body.move_and_slide()
		_update_vision_cone(worker)


func _update_pickup_worker(worker: Dictionary) -> void:
	var body: CharacterBody3D = worker["body"]
	var target := pickup_route[pickup_route_index]
	var offset := target - body.position
	offset.y = 0.0
	var is_final_leg := pickup_route_index == pickup_route.size() - 1
	var arrival_distance := 0.68 if is_final_leg else 0.08
	if offset.length() < arrival_distance:
		if is_final_leg:
			_lift_player(worker)
			return
		body.position = target
		pickup_route_index += 1
		target = pickup_route[pickup_route_index]
		offset = target - body.position
		offset.y = 0.0

	var direction := _cardinal_world_direction(offset)
	body.velocity = direction * CARRY_SPEED
	body.rotation.y = atan2(-direction.x, -direction.z)
	_set_worker_animation(worker, &"carry_cross", direction)
	body.move_and_slide()


func _update_carrying_worker(worker: Dictionary) -> void:
	var body: CharacterBody3D = worker["body"]
	var target := carry_route[carry_route_index]
	var offset := target - body.position
	offset.y = 0.0
	var is_final_leg := carry_route_index == carry_route.size() - 1
	var arrival_distance := 0.16 if is_final_leg else 0.08
	if offset.length() < arrival_distance:
		if is_final_leg:
			_finish_carry(worker)
			return
		body.position = target
		player.global_position = body.global_position + Vector3(0.0, 0.62, 0.0)
		carry_route_index += 1
		target = carry_route[carry_route_index]
		offset = target - body.position
		offset.y = 0.0

	var direction := _cardinal_world_direction(offset)
	body.velocity = direction * CARRY_SPEED
	body.rotation.y = atan2(-direction.x, -direction.z)
	_set_worker_animation(worker, &"carry_cross", direction)
	body.move_and_slide()
	player.global_position = body.global_position + Vector3(0.0, 0.62, 0.0)


func _cardinal_world_direction(offset: Vector3) -> Vector3:
	if absf(offset.x) > absf(offset.z):
		return Vector3(signf(offset.x), 0.0, 0.0)
	return Vector3(0.0, 0.0, signf(offset.z))


func _cardinal_route(from: Vector3, to: Vector3) -> PackedVector3Array:
	var route := PackedVector3Array()
	var offset := to - from
	# Finish the longer axis first. This gives the worker long, readable straight
	# runs instead of reconsidering the dominant axis on every physics frame.
	if absf(offset.x) > absf(offset.z):
		if not is_zero_approx(offset.z):
			route.append(Vector3(to.x, from.y, from.z))
	elif not is_zero_approx(offset.x):
		route.append(Vector3(from.x, from.y, to.z))
	route.append(to)
	return route


func _worker_that_sees_player() -> Dictionary:
	for worker in workers:
		var body: CharacterBody3D = worker["body"]
		var origin := body.global_position + Vector3(0.0, 0.52, 0.0)
		var target := player.global_position + Vector3(0.0, 0.45, 0.0)
		var to_player := target - origin
		var flat_to_player := Vector3(to_player.x, 0.0, to_player.z)

		if flat_to_player.length() > VISION_RANGE:
			continue

		var forward := -body.global_transform.basis.z
		forward.y = 0.0
		if forward.normalized().dot(flat_to_player.normalized()) < cos(VISION_HALF_ANGLE):
			continue

		# Layer 2 contains sight-blocking office furniture and walls.
		var query := PhysicsRayQueryParameters3D.create(origin, target, 2)
		if get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			return worker

	return {}


func _begin_carry(worker: Dictionary) -> void:
	_play_sfx(SFX_WORKER_ALERT)
	pickup_worker = worker
	var body: CharacterBody3D = worker["body"]
	body.collision_mask = 0
	pickup_route = _cardinal_route(body.position, player.position)
	pickup_route_index = 0
	player.velocity = Vector3.ZERO
	var approach_direction := pickup_route[0] - body.position
	_set_worker_animation(worker, &"carry_cross", approach_direction.normalized())
	status_label.text = "WORKER COMING"
	status_label.add_theme_color_override("font_color", Color("#ffd166"))


func _lift_player(worker: Dictionary) -> void:
	_play_sfx(SFX_BRIEFCASE_PICKUP)
	var body: CharacterBody3D = worker["body"]
	pickup_worker = {}
	carrying_worker = worker
	carry_target = _nearest_cubicle_drop_point(player.global_position)
	carry_route = _cardinal_route(body.position, carry_target)
	carry_route_index = 0
	player_collision.disabled = true
	player.global_position = body.global_position + Vector3(0.0, 0.62, 0.0)
	var carry_direction := carry_route[0] - body.position
	_set_worker_animation(worker, &"carry_cross", carry_direction.normalized())
	status_label.text = "PICKED UP"


func _finish_carry(worker: Dictionary) -> void:
	_play_sfx(SFX_BRIEFCASE_DROP)
	var body: CharacterBody3D = worker["body"]
	body.position = carry_target
	body.velocity = Vector3.ZERO
	body.collision_mask = 2
	player.position = carry_target
	player_collision.disabled = false
	var route: PackedVector3Array = worker["route"]
	worker["index"] = _nearest_route_point_index(route, body.position)
	var next_direction := route[worker["index"]] - body.position
	_set_worker_animation(worker, &"idle", next_direction.normalized())
	carrying_worker = {}
	pickup_route.clear()
	carry_route.clear()
	pickup_cooldown = 1.0
	status_label.text = ""


func _nearest_cubicle_drop_point(from: Vector3) -> Vector3:
	var nearest := cubicle_drop_points[0]
	var nearest_distance := from.distance_squared_to(nearest)
	for point in cubicle_drop_points:
		var distance := from.distance_squared_to(point)
		if distance < nearest_distance:
			nearest = point
			nearest_distance = distance
	return nearest


func _nearest_route_point_index(route: PackedVector3Array, from: Vector3) -> int:
	var nearest_index := 0
	var nearest_distance := INF
	for i in route.size():
		var distance := from.distance_squared_to(route[i])
		if distance < nearest_distance:
			nearest_index = i
			nearest_distance = distance
	return nearest_index


func _caught(catching_worker: Dictionary) -> void:
	if resetting:
		return
	_play_sfx(SFX_CAUGHT)
	resetting = true
	for worker in workers:
		var body: CharacterBody3D = worker["body"]
		body.velocity = Vector3.ZERO
		if not catching_worker.is_empty() and body == catching_worker["body"]:
			_set_worker_animation(worker, &"surprised")
		else:
			_set_worker_animation(worker, &"idle")
	status_label.text = "CAUGHT!"
	status_label.add_theme_color_override("font_color", Color("#ff5d73"))
	await get_tree().create_timer(0.9).timeout
	_reset_level()


func _reset_level() -> void:
	if transformation_tween and transformation_tween.is_valid():
		transformation_tween.kill()
	transformation_tween = null
	hidden_mode = false
	is_transforming = false
	hidden_time = HIDDEN_TIME_MAX
	pickup_worker = {}
	carrying_worker = {}
	pickup_route.clear()
	carry_route.clear()
	pickup_cooldown = 0.0
	player.position = START_POSITION
	player.velocity = Vector3.ZERO
	player_collision.disabled = false
	player_facing = &"s"
	player_sprite.visible = true
	player_sprite.modulate = Color.WHITE
	player_sprite.scale = Vector3.ONE
	hidden_sprite.visible = false
	hidden_sprite.modulate = Color.WHITE
	hidden_sprite.scale = Vector3.ONE
	_set_player_animation(Vector2.ZERO)
	for worker in workers:
		var body: CharacterBody3D = worker["body"]
		var route: PackedVector3Array = worker["route"]
		body.position = route[0]
		worker["index"] = 1
		var direction := (route[1] - route[0]).normalized()
		body.rotation.y = atan2(-direction.x, -direction.z)
		body.velocity = Vector3.ZERO
		body.collision_mask = 2
		_set_worker_animation(worker, &"walk", direction)
	for potion in potions:
		potion.visible = true
		potion.set_meta("collected", false)
	status_label.text = ""
	resetting = false
	_update_hidden_time_hud()
	_snap_camera_to_player()


func _complete_level() -> void:
	_play_sfx(SFX_LEVEL_COMPLETE)
	level_complete = true
	player.velocity = Vector3.ZERO
	status_label.text = "LEVEL COMPLETE"
	status_label.add_theme_color_override("font_color", Color("#7bf1a8"))


func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#152034")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#e5efff")
	env.ambient_light_energy = 0.72
	environment.environment = env
	add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58.0, -35.0, 0.0)
	sun.light_color = Color("#fff4dc")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(WORLD_X_HALF * 2.08, WORLD_Z_HALF * 2.08)
	ground.mesh = ground_mesh
	ground.material_override = _material(Color("#59666b"), 0.96)
	add_child(ground)

	_add_room_flooring()
	_add_room_partitions()
	_add_office_furniture()
	_add_start_and_exit()
	_build_potions()


func _add_room_flooring() -> void:
	# Narrow gaps expose the neutral base floor as thresholds between six office
	# rooms. The room partitions follow these same cubicle-aligned boundaries.
	var room_width := 14.93
	var outer_room_depth := 6.6
	var middle_room_depth := 6.52
	var left_x := -7.535
	var right_x := 7.535
	var outer_z := 6.7

	# Repeated materials sit diagonally rather than sharing an edge.
	_add_floor_zone(Vector3(left_x, 0.0, outer_z), Vector2(room_width, outer_room_depth), FLOOR_LINOLEUM)
	_add_floor_zone(Vector3(right_x, 0.0, outer_z), Vector2(room_width, outer_room_depth), FLOOR_CARPET_BLUE_GREY)
	_add_floor_zone(Vector3(left_x, 0.0, 0.0), Vector2(room_width, middle_room_depth), FLOOR_WOOD)
	_add_floor_zone(Vector3(right_x, 0.0, 0.0), Vector2(room_width, middle_room_depth), FLOOR_CARPET_TEAL)
	_add_floor_zone(Vector3(left_x, 0.0, -outer_z), Vector2(room_width, outer_room_depth), FLOOR_CARPET_BLUE_GREY)
	_add_floor_zone(Vector3(right_x, 0.0, -outer_z), Vector2(room_width, outer_room_depth), FLOOR_WOOD)


func _add_floor_zone(at: Vector3, size: Vector2, texture: Texture2D) -> void:
	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = size
	floor.mesh = floor_mesh
	floor.position = at + Vector3(0.0, 0.008, 0.0)

	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_texture = texture
	# Keep the illustrated flooring subordinate to characters and yellow sight
	# cones. The neutral tint also ties the different room materials together.
	floor_material.albedo_color = FLOOR_TINT
	floor_material.roughness = 0.95
	floor_material.uv1_scale = Vector3(size.x / 8.0, size.y / 8.0, 1.0)
	floor.material_override = floor_material
	add_child(floor)


func _add_room_partitions() -> void:
	# Low top-down walls keep the scene visually flat. Their plain openings line
	# up with the workers' patrol lanes so every route remains unobstructed.
	_add_room_wall_along_z(0.0, 3.4, 10.0, [7.8])
	_add_room_wall_along_z(0.0, -3.26, 3.26, [-2.5, 2.5])
	_add_room_wall_along_z(0.0, -10.0, -3.4, [-7.8])
	_add_room_wall_along_x(3.33, -15.0, 0.0, [-6.0])
	_add_room_wall_along_x(3.33, 0.0, 15.0, [6.0])
	_add_room_wall_along_x(-3.33, -15.0, 0.0, [-6.0])
	_add_room_wall_along_x(-3.33, 0.0, 15.0, [6.0])


func _add_room_wall_along_x(z: float, from_x: float, to_x: float, door_centers: Array) -> void:
	var segment_start := from_x
	for door_center_value in door_centers:
		var door_center := float(door_center_value)
		var opening_start := maxf(segment_start, door_center - 0.9)
		_add_room_wall_segment_x(z, segment_start, opening_start)
		segment_start = minf(to_x, door_center + 0.9)
	_add_room_wall_segment_x(z, segment_start, to_x)


func _add_room_wall_along_z(x: float, from_z: float, to_z: float, door_centers: Array) -> void:
	var segment_start := from_z
	for door_center_value in door_centers:
		var door_center := float(door_center_value)
		var opening_start := maxf(segment_start, door_center - 0.9)
		_add_room_wall_segment_z(x, segment_start, opening_start)
		segment_start = minf(to_z, door_center + 0.9)
	_add_room_wall_segment_z(x, segment_start, to_z)


func _add_room_wall_segment_x(z: float, from_x: float, to_x: float) -> void:
	var length := to_x - from_x
	if length > 0.08:
		_add_low_room_wall(Vector3((from_x + to_x) * 0.5, 0.0, z), Vector3(length, 0.5, 0.18))


func _add_room_wall_segment_z(x: float, from_z: float, to_z: float) -> void:
	var length := to_z - from_z
	if length > 0.08:
		_add_low_room_wall(Vector3(x, 0.0, (from_z + to_z) * 0.5), Vector3(0.18, 0.5, length))


func _add_low_room_wall(at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = at
	body.collision_layer = 2
	body.collision_mask = 0
	add_child(body)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position.y = size.y * 0.5
	body.add_child(collision)

	# A dark shallow side and slim warm cap provide depth without introducing a
	# front-facing wall sprite or changing the established near-2D viewpoint.
	_add_box_mesh(body, size, Vector3(0.0, size.y * 0.5, 0.0), Color("#6f514d"))
	var cap_size := Vector3(size.x + 0.04, 0.06, size.z + 0.04)
	_add_box_mesh(body, cap_size, Vector3(0.0, size.y + 0.01, 0.0), Color("#d6a47e"))


func _add_office_furniture() -> void:
	# Alternating U-shaped cubicles create corridors, blind corners, and cover.
	var columns := [-9.0, -3.0, 3.0, 9.0]
	var rows := [5.0, 0.0, -5.0]
	for row_index in rows.size():
		for column_index in columns.size():
			var opens_positive_z := (row_index + column_index) % 2 == 0
			_add_cubicle(Vector3(columns[column_index], 0.0, rows[row_index]), opens_positive_z)

	_add_partition(Vector3(-12.1, 0.0, 3.8), Vector3(0.18, 1.4, 4.2))
	_add_partition(Vector3(12.1, 0.0, -3.8), Vector3(0.18, 1.4, 4.2))
	_add_partition(Vector3(-8.4, 0.0, -8.7), Vector3(3.2, 1.4, 0.18))
	_add_partition(Vector3(9.0, 0.0, 8.7), Vector3(4.0, 1.4, 0.18))

	# Keep storage against room boundaries so it reads as intentional office
	# furniture rather than as an obstacle abandoned in an open walkway.
	_add_cabinet(Vector3(-13.7, 0.0, -2.35))
	_add_cabinet(Vector3(13.7, 0.0, 2.35))
	_add_plant(Vector3(-13.5, 0.0, -8.6))
	_add_plant(Vector3(13.1, 0.0, 8.5))
	_add_plant(Vector3(-0.8, 0.0, -9.0))

	_add_partition(Vector3(0.0, 0.0, -10.05), Vector3(30.2, 0.45, 0.16), Color("#d7e0e8"))
	_add_partition(Vector3(0.0, 0.0, 10.05), Vector3(30.2, 0.45, 0.16), Color("#d7e0e8"))
	_add_partition(Vector3(-15.05, 0.0, 0.0), Vector3(0.16, 0.45, 20.2), Color("#d7e0e8"))
	_add_partition(Vector3(15.05, 0.0, 0.0), Vector3(0.16, 0.45, 20.2), Color("#d7e0e8"))


func _add_cubicle(at: Vector3, opens_positive_z: bool) -> void:
	var opening_sign := 1.0 if opens_positive_z else -1.0
	var back_z := at.z - opening_sign * 1.3
	_add_partition(Vector3(at.x, 0.0, back_z), Vector3(2.8, 1.35, 0.14), Color("#78909c"))
	_add_partition(Vector3(at.x - 1.33, 0.0, at.z), Vector3(0.14, 1.35, 2.7), Color("#78909c"))
	_add_partition(Vector3(at.x + 1.33, 0.0, at.z), Vector3(0.14, 1.35, 2.7), Color("#78909c"))
	_add_desk(Vector3(at.x, 0.0, at.z - opening_sign * 0.62))
	cubicle_drop_points.append(at + Vector3(0.0, 0.0, opening_sign * 0.72))


func _build_potions() -> void:
	for potion_position in POTION_POSITIONS:
		var potion := Node3D.new()
		potion.position = potion_position
		potion.set_meta("collected", false)
		add_child(potion)

		var glow := MeshInstance3D.new()
		var glow_mesh := CylinderMesh.new()
		glow_mesh.top_radius = 0.36
		glow_mesh.bottom_radius = 0.36
		glow_mesh.height = 0.025
		glow.mesh = glow_mesh
		glow.position.y = 0.025
		glow.material_override = _material(Color(0.35, 0.95, 1.0, 0.38), 1.0)
		potion.add_child(glow)

		_add_prop_sprite(
			potion,
			DISGUISE_POTION_TEXTURE,
			Vector3(0.0, 0.43, 0.0),
			Vector2(0.72, 0.86)
		)
		potions.append(potion)


func _collect_nearby_potion() -> void:
	for potion in potions:
		if not potion.get_meta("collected", false) \
				and player.global_position.distance_to(potion.global_position) < 0.7:
			potion.visible = false
			potion.set_meta("collected", true)
			hidden_time = minf(HIDDEN_TIME_MAX, hidden_time + POTION_REFILL)
			_play_sfx(SFX_POTION_PICKUP)
			_update_hidden_time_hud()
			return


func _add_desk(at: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = at
	body.collision_layer = 2
	body.collision_mask = 0
	add_child(body)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.15, 0.9, 1.05)
	collision.shape = shape
	collision.position.y = 0.45
	body.add_child(collision)

	_add_prop_sprite(
		# The source image has generous transparent padding below the desk.
		# Centre it lower so the illustrated feet meet the floor instead of
		# making the workstation appear to perch on top of the divider.
		body, WORKSTATION_TEXTURE, Vector3(0.0, 0.5, 0.0), Vector2(2.5, 1.55)
	)


func _add_partition(at: Vector3, size: Vector3, color := Color("#607d8b")) -> void:
	var body := StaticBody3D.new()
	body.position = at
	body.collision_layer = 2
	body.collision_mask = 0
	add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position.y = size.y * 0.5
	body.add_child(collision)
	var long_on_x := size.x > size.z
	if size.y > 0.75:
		# Preserve the original axis-aware cubicle geometry. A billboarded divider
		# makes every wall face the camera and visually destroys north/south runs.
		_add_box_mesh(body, size, Vector3(0.0, size.y * 0.5, 0.0), color)
		if long_on_x:
			_add_divider_face(body, size)
	else:
		_add_box_mesh(body, size, Vector3(0.0, size.y * 0.5, 0.0), color)


func _add_divider_face(body: StaticBody3D, size: Vector3) -> void:
	var face := Sprite3D.new()
	face.texture = DIVIDER_TEXTURE
	face.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	face.double_sided = true
	face.position = Vector3(0.0, size.y * 0.5, size.z * 0.5 + 0.006)
	face.pixel_size = 0.001
	face.scale = Vector3(
		size.x / (float(DIVIDER_TEXTURE.get_width()) * face.pixel_size),
		size.y / (float(DIVIDER_TEXTURE.get_height()) * face.pixel_size),
		1.0
	)
	body.add_child(face)


func _add_cabinet(at: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = at
	body.collision_layer = 2
	body.collision_mask = 0
	add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.75, 1.65, 1.6)
	collision.shape = shape
	collision.position.y = 0.825
	body.add_child(collision)

	_add_prop_sprite(
		body, FILING_CABINET_TEXTURE, Vector3(0.0, 0.9, 0.0), Vector2(1.35, 1.85)
	)


func _add_plant(at: Vector3) -> void:
	var plant := Node3D.new()
	plant.position = at
	add_child(plant)
	_add_prop_sprite(
		plant, OFFICE_PLANT_TEXTURE, Vector3(0.0, 0.72, 0.0), Vector2(1.35, 1.45)
	)


func _add_start_and_exit() -> void:
	_add_floor_marker(START_POSITION, Color(0.25, 0.55, 1.0, 0.42))
	_add_floor_marker(EXIT_POSITION, Color(0.2, 1.0, 0.48, 0.48))
	_add_exit_sign(EXIT_POSITION)


func _add_exit_sign(at: Vector3) -> void:
	var exit_post := Node3D.new()
	exit_post.position = at + Vector3(0.0, 0.0, -0.35)
	add_child(exit_post)
	_add_prop_sprite(
		exit_post, EXIT_SIGN_TEXTURE, Vector3(0.0, 0.82, 0.0), Vector2(1.8, 1.65)
	)


func _add_floor_marker(at: Vector3, color: Color) -> void:
	if color.b > color.g:
		_add_prop_sprite(
			self, START_ZONE_TEXTURE, at + Vector3(0.0, 0.22, 0.0), Vector2(1.35, 1.35)
		)
		return
	var outline := MeshInstance3D.new()
	var outline_mesh := CylinderMesh.new()
	outline_mesh.top_radius = 0.79
	outline_mesh.bottom_radius = 0.79
	outline_mesh.height = 0.018
	outline_mesh.radial_segments = 20
	outline.mesh = outline_mesh
	outline.position = at + Vector3(0.0, 0.015, 0.0)
	outline.material_override = _material(PROP_INK, 1.0)
	add_child(outline)
	var marker := MeshInstance3D.new()
	var marker_mesh := CylinderMesh.new()
	marker_mesh.top_radius = 0.72
	marker_mesh.bottom_radius = 0.72
	marker_mesh.height = 0.025
	marker_mesh.radial_segments = 20
	marker.mesh = marker_mesh
	marker.position = at + Vector3(0.0, 0.02, 0.0)
	marker.material_override = _material(color, 1.0)
	add_child(marker)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Briefcase"
	player.position = START_POSITION
	player.collision_layer = 1
	player.collision_mask = 3
	add_child(player)

	player_collision = CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 0.82
	player_collision.shape = shape
	player_collision.position.y = 0.42
	player.add_child(player_collision)

	player_sprite = AnimatedSprite3D.new()
	player_sprite.name = "AnimatedBriefcase"
	player_sprite.sprite_frames = _create_briefcase_sprite_frames()
	player_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	player_sprite.position.y = 0.78
	player_sprite.pixel_size = 0.0048
	player_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	player.add_child(player_sprite)
	player_sprite.play(&"idle_s")

	hidden_sprite = Sprite3D.new()
	hidden_sprite.name = "HiddenBriefcase"
	hidden_sprite.texture = HIDDEN_BRIEFCASE_TEXTURE
	hidden_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hidden_sprite.position.y = 0.78
	hidden_sprite.pixel_size = 0.0048
	hidden_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	hidden_sprite.visible = false
	player.add_child(hidden_sprite)


func _set_hidden_mode(to_hidden: bool) -> void:
	if to_hidden and hidden_time <= 0.0:
		return
	if hidden_mode == to_hidden:
		return

	_play_sfx(SFX_DISGUISE_ON if to_hidden else SFX_DISGUISE_OFF)
	hidden_mode = to_hidden
	is_transforming = true
	if transformation_tween and transformation_tween.is_valid():
		transformation_tween.kill()

	player_sprite.visible = true
	hidden_sprite.visible = true
	if to_hidden:
		hidden_sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)
		hidden_sprite.scale = Vector3(1.15, 0.72, 1.0)
	else:
		player_sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)
		player_sprite.scale = Vector3(1.15, 0.72, 1.0)

	transformation_tween = create_tween().set_parallel(true)
	transformation_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	transformation_tween.tween_property(player_sprite, "modulate:a", 0.0 if to_hidden else 1.0, TRANSFORM_TIME)
	transformation_tween.tween_property(player_sprite, "scale", Vector3.ONE, TRANSFORM_TIME)
	transformation_tween.tween_property(hidden_sprite, "modulate:a", 1.0 if to_hidden else 0.0, TRANSFORM_TIME)
	transformation_tween.tween_property(hidden_sprite, "scale", Vector3.ONE, TRANSFORM_TIME)
	transformation_tween.finished.connect(_finish_transform_animation.bind(to_hidden))


func _finish_transform_animation(to_hidden: bool) -> void:
	player_sprite.visible = not to_hidden
	hidden_sprite.visible = to_hidden
	player_sprite.modulate = Color.WHITE
	hidden_sprite.modulate = Color.WHITE
	player_sprite.scale = Vector3.ONE
	hidden_sprite.scale = Vector3.ONE
	is_transforming = false


func _create_briefcase_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")

	for row in BRIEFCASE_DIRECTIONS.size():
		var direction: StringName = BRIEFCASE_DIRECTIONS[row]
		var idle_name := StringName("idle_%s" % direction)
		var walk_name := StringName("walk_%s" % direction)
		frames.add_animation(idle_name)
		frames.set_animation_loop(idle_name, false)
		frames.add_animation(walk_name)
		frames.set_animation_loop(walk_name, true)
		frames.set_animation_speed(walk_name, BRIEFCASE_WALK_FPS)

		for column in 5:
			var atlas_frame := AtlasTexture.new()
			atlas_frame.atlas = BRIEFCASE_ATLAS
			atlas_frame.region = Rect2(
				Vector2(column, row) * BRIEFCASE_FRAME_SIZE,
				BRIEFCASE_FRAME_SIZE
			)
			if column == 0:
				frames.add_frame(idle_name, atlas_frame)
			else:
				frames.add_frame(walk_name, atlas_frame)

	return frames


func _build_workers() -> void:
	for i in worker_routes.size():
		_add_worker(worker_routes[i], WORKER_ATLASES[i])


func _add_worker(route: PackedVector3Array, atlas: Texture2D) -> void:
	var body := CharacterBody3D.new()
	body.position = route[0]
	body.collision_layer = 1
	body.collision_mask = 2
	add_child(body)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.36
	shape.height = 1.55
	collision.shape = shape
	collision.position.y = 0.8
	body.add_child(collision)

	var sprite := AnimatedSprite3D.new()
	sprite.name = "AnimatedWorker"
	sprite.sprite_frames = WorkerFrames.create(atlas)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Keep the illustrated worker consistent with the 1.55-unit collision body
	# and a little taller than the nearby 0.9-unit desks. The source frames are
	# almost fully occupied, so this offset leaves their ground shadow at y=0.
	sprite.position.y = 0.82
	sprite.pixel_size = WORKER_SPRITE_PIXEL_SIZE
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	body.add_child(sprite)

	var cone := _create_vision_cone()
	body.add_child(cone)
	var direction := (route[1] - route[0]).normalized()
	body.rotation.y = atan2(-direction.x, -direction.z)
	var worker := {
		"body": body,
		"route": route,
		"index": 1,
		"cone": cone,
		"sprite": sprite,
		"facing": _worker_direction_name(direction),
		"state": &"walk",
	}
	workers.append(worker)
	_set_worker_animation(worker, &"walk", direction)


func _set_worker_animation(worker: Dictionary, state: StringName, direction := Vector3.ZERO) -> void:
	if direction.length_squared() > 0.001:
		worker["facing"] = _worker_direction_name(direction)
	worker["state"] = state
	var sprite: AnimatedSprite3D = worker["sprite"]
	var animation_name := StringName("%s_%s" % [state, worker["facing"]])
	if sprite.animation != animation_name or not sprite.is_playing():
		sprite.play(animation_name)


func _worker_direction_name(direction: Vector3) -> StringName:
	if absf(direction.x) > absf(direction.z):
		return &"e" if direction.x > 0.0 else &"w"
	return &"s" if direction.z > 0.0 else &"n"


func _create_vision_cone() -> MeshInstance3D:
	var cone := MeshInstance3D.new()
	cone.mesh = ArrayMesh.new()
	cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cone_material := _material(Color(1.0, 0.78, 0.18, 0.27), 1.0)
	cone_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cone_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	cone.material_override = cone_material
	var distances := PackedFloat32Array()
	distances.resize(VISION_RAY_COUNT)
	distances.fill(VISION_RANGE)
	_write_vision_cone_mesh(cone, distances)
	return cone


func _update_vision_cone(worker: Dictionary) -> void:
	var body: CharacterBody3D = worker["body"]
	var cone: MeshInstance3D = worker["cone"]
	var origin := body.global_position + Vector3(0.0, 0.45, 0.0)
	var distances := PackedFloat32Array()
	distances.resize(VISION_RAY_COUNT)

	for i in VISION_RAY_COUNT:
		var ratio := float(i) / float(VISION_RAY_COUNT - 1)
		var angle := lerpf(-VISION_HALF_ANGLE, VISION_HALF_ANGLE, ratio)
		var local_direction := Vector3(sin(angle), 0.0, -cos(angle))
		var world_direction := body.global_transform.basis * local_direction
		var query := PhysicsRayQueryParameters3D.create(origin, origin + world_direction * VISION_RANGE, 2)
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		distances[i] = VISION_RANGE if hit.is_empty() else origin.distance_to(hit["position"])

	_write_vision_cone_mesh(cone, distances)


func _write_vision_cone_mesh(cone: MeshInstance3D, distances: PackedFloat32Array) -> void:
	var vertices := PackedVector3Array([Vector3(0.0, 0.035, -0.16)])
	for i in VISION_RAY_COUNT:
		var ratio := float(i) / float(VISION_RAY_COUNT - 1)
		var angle := lerpf(-VISION_HALF_ANGLE, VISION_HALF_ANGLE, ratio)
		vertices.append(Vector3(sin(angle) * distances[i], 0.035, -cos(angle) * distances[i]))

	var indices := PackedInt32Array()
	for i in range(1, VISION_RAY_COUNT):
		indices.append_array(PackedInt32Array([0, i, i + 1]))

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var cone_mesh: ArrayMesh = cone.mesh
	cone_mesh.clear_surfaces()
	cone_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "TopDownCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.5
	add_child(camera)
	camera.current = true
	_snap_camera_to_player()


func _update_camera(delta: float) -> void:
	var desired_focus := _camera_focus()
	var current_focus := camera.position - CAMERA_OFFSET
	var focus_offset := desired_focus - current_focus
	var smoothing := 1.0 - exp(-6.0 * delta)
	if focus_offset.length_squared() > 0.0001:
		# Smooth the complete offset so the camera eases cleanly through turns.
		current_focus += focus_offset * smoothing
	else:
		current_focus = desired_focus

	camera.position = current_focus + CAMERA_OFFSET
	# Always look along CAMERA_OFFSET. Looking directly at the unsmoothed player
	# focus while the camera position was still easing caused the view to wobble.
	camera.look_at(current_focus, Vector3.UP)


func _snap_camera_to_player() -> void:
	var focus := _camera_focus()
	camera.position = focus + CAMERA_OFFSET
	camera.look_at(focus, Vector3.UP)


func _camera_focus() -> Vector3:
	var focus := player.position
	# Carrying raises the briefcase visually, but the camera should continue to
	# track its floor position so pickup and drop-off do not bump the view.
	focus.y = 0.0
	# Keep the camera inside the floor near the outer walls while allowing the
	# briefcase to move toward the edge of the viewport at the start and exit.
	focus.x = clampf(focus.x, -3.9, 3.9)
	focus.z = clampf(focus.z, -1.85, 1.85)
	return focus


func _build_hud() -> void:
	gameplay_hud = CanvasLayer.new()
	add_child(gameplay_hud)
	add_child(PauseController.new())

	var panel := PanelContainer.new()
	panel.position = Vector2(20.0, 20.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.055, 0.09, 0.9)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.content_margin_left = 18.0
	panel_style.content_margin_right = 18.0
	panel_style.content_margin_top = 14.0
	panel_style.content_margin_bottom = 14.0
	panel.add_theme_stylebox_override("panel", panel_style)
	gameplay_hud.add_child(panel)

	var copy := VBoxContainer.new()
	panel.add_child(copy)
	var title := Label.new()
	title.text = "BRIEFCASE: OFFICE ESCAPE"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#ffd166"))
	copy.add_child(title)
	var objective := Label.new()
	objective.text = "Reach EXIT without entering a vision cone\nWASD / arrows: move    Space: disguise    P: pause"
	objective.add_theme_font_size_override("font_size", 15)
	objective.add_theme_color_override("font_color", Color("#e8eefc"))
	copy.add_child(objective)

	var disguise_panel := PanelContainer.new()
	disguise_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	disguise_panel.position = Vector2(-190.0, 18.0)
	disguise_panel.size = Vector2(380.0, 58.0)
	var disguise_style := StyleBoxFlat.new()
	disguise_style.bg_color = Color(0.04, 0.055, 0.09, 0.9)
	disguise_style.corner_radius_top_left = 10
	disguise_style.corner_radius_top_right = 10
	disguise_style.corner_radius_bottom_left = 10
	disguise_style.corner_radius_bottom_right = 10
	disguise_style.content_margin_left = 12.0
	disguise_style.content_margin_right = 12.0
	disguise_style.content_margin_top = 7.0
	disguise_style.content_margin_bottom = 7.0
	disguise_panel.add_theme_stylebox_override("panel", disguise_style)
	gameplay_hud.add_child(disguise_panel)

	var disguise_copy := VBoxContainer.new()
	disguise_copy.add_theme_constant_override("separation", 2)
	disguise_panel.add_child(disguise_copy)
	hidden_time_label = Label.new()
	hidden_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hidden_time_label.add_theme_font_size_override("font_size", 14)
	hidden_time_label.add_theme_color_override("font_color", Color("#bdf8ff"))
	disguise_copy.add_child(hidden_time_label)
	hidden_time_bar = ProgressBar.new()
	hidden_time_bar.min_value = 0.0
	hidden_time_bar.max_value = HIDDEN_TIME_MAX
	hidden_time_bar.show_percentage = false
	hidden_time_bar.custom_minimum_size = Vector2(356.0, 16.0)
	var bar_background := StyleBoxFlat.new()
	bar_background.bg_color = Color("#26364d")
	bar_background.corner_radius_top_left = 7
	bar_background.corner_radius_top_right = 7
	bar_background.corner_radius_bottom_left = 7
	bar_background.corner_radius_bottom_right = 7
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color("#41d9e8")
	bar_fill.corner_radius_top_left = 7
	bar_fill.corner_radius_top_right = 7
	bar_fill.corner_radius_bottom_left = 7
	bar_fill.corner_radius_bottom_right = 7
	hidden_time_bar.add_theme_stylebox_override("background", bar_background)
	hidden_time_bar.add_theme_stylebox_override("fill", bar_fill)
	disguise_copy.add_child(hidden_time_bar)

	status_label = Label.new()
	status_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	status_label.position = Vector2(-150.0, 82.0)
	status_label.size = Vector2(300.0, 55.0)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 34)
	gameplay_hud.add_child(status_label)


func _build_audio() -> void:
	var looping_music := LEVEL_MUSIC.duplicate() as AudioStreamMP3
	looping_music.loop = true
	music_player = AudioStreamPlayer.new()
	music_player.name = "LevelMusic"
	music_player.stream = looping_music
	music_player.volume_db = -8.0
	add_child(music_player)

	var looping_office := OFFICE_AMBIENCE.duplicate() as AudioStreamMP3
	looping_office.loop = true
	office_ambience_player = AudioStreamPlayer.new()
	office_ambience_player.name = "OfficeAmbience"
	office_ambience_player.stream = looping_office
	# The field recording has substantially more headroom than the mastered
	# music. This boost keeps chatter, phones and typing present in the mix.
	office_ambience_player.volume_db = 5.0
	add_child(office_ambience_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "GameSoundEffect"
	sfx_player.volume_db = -3.0
	sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sfx_player)

	music_player.play()
	office_ambience_player.play()


func _play_sfx(stream: AudioStream) -> void:
	sfx_player.stream = stream
	sfx_player.play()


func _should_skip_title_screen() -> bool:
	if "--skip-title" in OS.get_cmdline_user_args():
		return true
	return OS.get_environment("BRIEFCASE_SKIP_TITLE").to_lower() in ["1", "true", "yes"]


func _show_title_screen() -> void:
	title_screen_active = true
	gameplay_hud.visible = false
	title_screen = TitleScreen.new()
	add_child(title_screen)


func _start_first_level() -> void:
	title_screen_active = false
	gameplay_hud.visible = true
	if is_instance_valid(title_screen):
		title_screen.queue_free()
	title_screen = null
	_reset_level()
	_play_sfx(SFX_GAME_START)


func _update_hidden_time_hud() -> void:
	if not hidden_time_bar:
		return
	hidden_time_bar.value = hidden_time
	hidden_time_label.text = "DISGUISE  %.1f s" % hidden_time
	if hidden_time <= 1.0:
		hidden_time_bar.modulate = Color("#ff758f")
	else:
		hidden_time_bar.modulate = Color.WHITE


func _add_box_mesh(parent: Node, size: Vector3, at: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = at
	instance.material_override = _material(color)
	parent.add_child(instance)


func _add_prop_sprite(
	parent: Node,
	texture: Texture2D,
	at: Vector3,
	visible_size: Vector2
) -> void:
	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.position = at
	sprite.pixel_size = 0.001
	sprite.scale = Vector3(
		visible_size.x / (float(texture.get_width()) * sprite.pixel_size),
		visible_size.y / (float(texture.get_height()) * sprite.pixel_size),
		1.0
	)
	parent.add_child(sprite)


func _material(color: Color, roughness := 0.8) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material
